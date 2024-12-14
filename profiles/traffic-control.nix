{ config, pkgs, ... }:

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

  systemd.services.traffic-control-rules = {
    after = [ "network.target" ];
    description = "Taffic Control Rules";
    enable = true;
    serviceConfig = {
      User = "root";
      Group = "root";
      Type = "oneshot";
      RemainAfterExit = "yes";
      ExecStart = pkgs.writeShellScript "tc-rules-start.sh" ''
        TC=${pkgs.iproute2}/bin/tc

        # Remove existing configurations
        $TC qdisc del dev ${wan-interface} root 2>/dev/null
        $TC qdisc del dev ${wan-interface} ingress 2>/dev/null

        sleep 1

        # Add root qdisc with adjusted r2q
        $TC qdisc add dev ${wan-interface} root handle 1: htb default 30 r2q 8000

        # Add root class
        $TC class add dev ${wan-interface} parent 1: classid 1:1 htb rate ${toString wan-bitrate-mbps-down-95-percent}mbit ceil 950mbit burst 50k cburst 50k

        # Add child classes with explicit quantum values
        $TC class add dev ${wan-interface} parent 1:1 classid 1:10 htb prio 1 rate 1mbit ceil ${toString wan-bitrate-mbps-down-20-percent}200mbit burst 15k cburst 15k quantum 1514
        $TC class add dev ${wan-interface} parent 1:1 classid 1:20 htb prio 2 rate 1mbit ceil ${toString wan-bitrate-mbps-down-20-percent}200mbit burst 15k cburst 15k quantum 1514
        $TC class add dev ${wan-interface} parent 1:1 classid 1:30 htb prio 3 rate 1mbit ceil ${toString wan-bitrate-mbps-down-95-percent}950mbit burst 15k cburst 15k quantum 1514

        # Add fq_codel to each class
        $TC qdisc add dev ${wan-interface} parent 1:10 handle 10: fq_codel
        $TC qdisc add dev ${wan-interface} parent 1:20 handle 20: fq_codel
        $TC qdisc add dev ${wan-interface} parent 1:30 handle 30: fq_codel
      '';
      ExecStop = pkgs.writeShellScript "tc-rules-stop.sh" ''
        TC=${pkgs.iproute2}/bin/tc

        $TC qdisc del dev ${wan-interface} root
        $TC qdisc del dev ${wan-interface} ingress
      '';
    };
  };
}
