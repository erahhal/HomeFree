{ config, pkgs, lib, ... }:

## @TODO: Convert to work with nftables
## @TODO: Test with ethernet cable using the following: https://www.waveform.com/tools/bufferbloat

let
  wan-interface = config.homefree.network.wan-interface;
  wan-bitrate-mbps-down = config.homefree.network.wan-bitrate-mbps-down;
  wan-bitrate-mbps-down-95-percent = builtins.floor (builtins.mul wan-bitrate-mbps-down 0.95);
  wan-bitrate-mbps-down-20-percent = builtins.floor (builtins.mul wan-bitrate-mbps-down 0.20);
in
{
  ## OPNSense Config
  ## ---------------
  ## Pipe
  ##   Name: Downstream Pipe
  ##   Bandwidth: 950 Mbit/s
  ##   Scheduler: FlowQueue-CoDel
  ##   CoDel enabled
  ## Pipe
  ##   Name: Upstream Pipe
  ##   Bandwidth: 950 Mbit/s
  ##   Scheduler: FlowQueue-CoDel
  ##   CoDel enabled
  ## Queue
  ##   Name: Upstream Queue
  ##   Pipe: Upstream Pipe
  ##   Weight: 1
  ## Queue
  ##   Name: Downstream Queue
  ##   Pipe: Downstream Pipe
  ##   Weight: 1
  ## Queue
  ##   Name: High Priority Queue
  ##   Pipe: Upstream Pipe
  ##   Weight: 10
  ## Rule
  ##   Name: DNS High Priority
  ##   Sequence: 11
  ##   Interface: WAN
  ##   Protocol: UDP
  ##   Source: 10.0.0.1 (lan gateway)
  ##   Src-port: any
  ##   Destination: any
  ##   Dst-port: 53
  ##   Target: High Priority Queue
  ## Rule
  ##   Name: Upstream traffic
  ##   Sequence: 12
  ##   Interface: WAN
  ##   Protocol: IP
  ##   Source: 10.0.0.0/24 (lan)
  ##   Src-port: any
  ##   Destination: any
  ##   Dst-port: any
  ##   Target: Upstream queue
  ## Rule
  ##   Name: ACK High Priority
  ##   Sequence: 13
  ##   Interface: WAN
  ##   Protocol: tcp (ACK packets only)
  ##   Source: 10.0.0.0/24 (lan)
  ##   Src-port: any
  ##   Destination: any
  ##   Dst-port: any
  ##   Target: High Priority Queue
  ## Rule
  ##   Name: Downstream traffic
  ##   Sequence: 14
  ##   Interface: WAN
  ##   Protocol: ip
  ##   Source: any
  ##   Src-port: any
  ##   Destination: 10.0.0.0/24 (lan)
  ##   Dst-port: any
  ##   Target: Downstream queue

  ## Disable TCP offload engine, which bypasses traffic shaper to save on CPU
  systemd.services.disable-transmit-segment-offload = {
    wantedBy = [ "multi-user.target" ];
    enable = true;
    serviceConfig = {
      User = "root";
      Group = "root";
    };
    # script = builtins.readFile ../scripts/tune_router_performance.sh;
    script = ''
      ETHTOOL=${pkgs.ethtool}/bin/ethtool

      $ETHTOOL -K ${wan-interface} tso off
      $ETHTOOL -K ${wan-interface} gso off
    '';
  };

  systemd.services.traffic-shaper = {
    wantedBy = [ "multi-user.target" ];
    enable = true;
    serviceConfig = {
      User = "root";
      Group = "root";
    };
    # script = builtins.readFile ../scripts/tune_router_performance.sh;
    script = ''
      TC=${pkgs.iproute2}/bin/tc
      IPTABLES=${pkgs.iptables}/bin/iptables

      # CoDel Active Queue Management (AQM) algorithm
      # https://www.bufferbloat.net/projects/codel/wiki/

      # fq_codel only supported by certain network drivers
      # https://www.bufferbloat.net/projects/bloat/wiki/BQL_enabled_drivers/

      # Reference for rules below
      # https://wiki.archlinux.org/title/Advanced_traffic_control
      # https://www.linuxquestions.org/questions/linux-networking-3/traffic-shaping-with-tc-on-a-server-4175690429-print/

      # Remove existing queues
      # redirect errors to /dev/null in case the qdisc doesn't exist
      $TC qdisc del dev ${wan-interface} ingress 2>/dev/null || true
      $TC qdisc del dev ${wan-interface} root 2>/dev/null || true

      # 1) Add/Replace root qdisc of eth0 with an HTB instance,
      #    specify handle so it can be referred to by other rules,
      #    set default class for all unclassified traffic

      $TC qdisc replace dev ${wan-interface} root handle 1: htb default 30

      # 2) Create single top level class with handle 1:1 which limits
      #    total traffic to slightly less than the path max
      #    Limit to 95% of maximum bandwidth

      $TC class add dev ${wan-interface} parent 1: classid 1:1 htb rate ${toString wan-bitrate-mbps-down-95-percent}mbit

      # 3) Create child classes for different uses:
      #    Class 1:10 is our outgoing highest priority path, outgoing SSH/SFTP in this example
      #    Class 1:20 is our next highest priority path, web admin traffic for example
      #    Class 1:30 is default and has lowest priority but highest total bandwidth - bulk web traffic for example

      $TC class add dev ${wan-interface} parent 1:1 classid 1:10 htb rate 1mbit ceil ${toString wan-bitrate-mbps-down-20-percent}mbit prio 1
      $TC class add dev ${wan-interface} parent 1:1 classid 1:20 htb rate 1mbit ceil ${toString wan-bitrate-mbps-down-20-percent}mbit prio 2
      $TC class add dev ${wan-interface} parent 1:1 classid 1:30 htb rate 1mbit ceil ${toString wan-bitrate-mbps-down-95-percent}mbit prio 3

      # 4) Attach a leaf qdisc to each child class
      #    HTB by default attaches pfifo as leaf so this is optional.
      #    fq_codel is said to be worth the effort.

      $TC qdisc add dev ${wan-interface} parent 1:10 fq_codel
      $TC qdisc add dev ${wan-interface} parent 1:20 fq_codel
      $TC qdisc add dev ${wan-interface} parent 1:30 fq_codel

      # 5) Add filters for priority traffic
      $TC filter add dev ${wan-interface} parent 1: handle 100 fw classid 1:10
      $TC filter add dev ${wan-interface} parent 1: handle 200 fw classid 1:20

      # Shape traffic
      ## -t mangle          mangle table, used for modifying packet headers
      ## -A OUTPUT          Append to OUTPUT chain (OUTPUT being packets leaving the system)
      ## -p tcp             TCP protocol
      ## --match multiport  Match multiple ports
      ## --dports 53        Match destination port of 53 (DNS)
      ## -j MARK            What to do on match. Jump to MARK (to set the netfilter mark value associated with the packet. It is only valid in the mangle table)
      ## --set-mark 200     Set connection mark of 200, which matches the tc filter above

      ## DNS High Priority
      $IPTABLES -t mangle -A OUTPUT -p tcp --match multiport --dports 53 -j MARK --set-mark 100
      ## ACK High Priority
      $IPTABLES -t mangle -A OUTPUT -p tcp --match tcp --tcp-flags ACK ACK -j MARK --set-mark 100
    '';
  };
}
