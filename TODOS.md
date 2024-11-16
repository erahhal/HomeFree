TODOS
=====

* Go Live Checklist
  * P1
    * [ ] Landing Page
    * [ ] Blog
    * [ ] Mirror to Github
    * [ ] Caddy proxy to HP server, HA
      * [ ] HAProxy / Unbound override configuration migration
    * [ ] Wireguard
    * [ ] AdGuard
      * [ ] Copy exceptions
    * [ ] DHCP
      * [ ] Copy Static IPs
    * [ ] DNS (Dnsmasq or Unbound)
    * [ ] qemu setup
  * P2
    * [ ] SOPS fixes
      * [ ] consolidate to single script that works on host or on guest
      * [ ] If no user key on guest, complain and abort
      * [ ] Fix error messages that mess with getting fingerprit
      * [ ] Make sure uid matches <curruser>@localhost, as it tells sops where to look for keyring
    * [ ] Get nixos-anywhere disko config to work with LUKS with key file
    * [ ] Move hardware config to module config
      * [ ] DB of hardware, similar to nixos-hardware repo
    * [ ] Backups
    * [ ] Migration of services from HP server, HA
    * [ ] SSO/Authentik
    * [ ] GUI for setup, management
    * [ ] Roadmap
      * Problem statement
      * Goal
      * Top issues to solve
      * Schedule
      * Long term vision
    * [ ] NAS
    * [ ] SSO
    * [ ] Security (wazuh ?)
  * P3
    * [ ] Monitoring Dashboard
    * [ ] VLANs
    * [ ] Health / Alerts
    * [ ] Mirror to Gitlab
    * [ ] Mirror to Bitbucket
    * [ ] Mirror to Sourcehut
    * [ ] Mirror to Codeberg
    * [ ] Mirror to Gitea
    * [ ] Mirror to Gogs

* Firewall
  * Aliases
  * NAT
    * Port forwarding
    * 1:1 NAT
    * Outbound
    * NPTv6
  * Rules
  * Shaper
* Services
  * Captive Portal
  * Intrusion Detection

* losing and gaining carrier repeatedly on WAN interface
  * Could be due to modem being 2.5Gbps trying to negotiate with 1Gbps interface
  * https://bbs.archlinux.org/viewtopic.php?id=292987

* Browser Bookmarks
  * https://github.com/floccusaddon/floccus

* EMAIL
  * https://gitlab.com/simple-nixos-mailserver/nixos-mailserver/

* Make a flake that sets up host machine for dev
  * hosts file changes (networking.extraHosts)
      networking.extraHosts = ''
        127.0.0.1 homefree.lan
        127.0.0.1 radicale.homefree.lan
        127.0.0.1 auth.homefree.lan
        127.0.0.1 authentik.homefree.lan
        127.0.0.1 vaultwarden.homefree.lan
        127.0.0.1 homeassistant.homefree.lan
        127.0.0.1 ha.homefree.lan
      '';
  * qemu
  * OVMF.fd
  * virtiofsd
* HA Authentication
  * Use local network authentication, then use Authentik proxy auth in front
  * LDAP auth is annoying, and presents a different auth page
  * Look into auto-initialization for HA: https://github.com/home-assistant/core/issues/16554
    * Using auth_manager API to create user, or edit .storage/auth directly / deploy it
* Authentik
  * Auto LDAP deploy
  * https://docs.goauthentik.io/docs/providers/ldap/generic_setup
* Security
  * Wazuh
* setup VLANs
  * https://wiki.nftables.org/wiki-nftables/index.php/Main_Page
  * https://serverfault.com/questions/858556/transparent-firewall-with-nftables-and-vlans
  * https://serverfault.com/questions/1057819/route-untagged-vlan-to-a-tagged-vlan-with-nftables
* setup ipv6
* Figure out how to use host id_rsa.pub in build, rather than hard-coded key
  * maybe share ~/.ssh/ida_rsa.pub into machine? would cause problems if share failed
* Determine if there are any problems with disabling "wait for network" to get rid of error
* Look into microvm instead of qemu, which has been difficult to work with
  * https://github.com/astro/microvm.nix
* setup DNSSEC for dnsmasq, IPV6
  * https://blog.josefsson.org/2015/10/26/combining-dnsmasq-and-unbound/

### Solutions
* Firewall
  * https://www.jjpdev.com/posts/home-router-nixos/
* NAS
  * https://github.com/reckenrode/nixos-configs/tree/c556206df2611af2f9ea83954aae1b51461e44c5/hosts/x86_64-linux/meteion
  * https://www.reddit.com/r/NixOS/comments/yr21p1/offtheshelf_nas_supporting_nixos/
* reverse proxy
  * Traefik
  * HAProxy
  * nginx-proxy-manager
  * caddy
* ad block
  * Unbound
  * AdGuard
  * PiHole
* intrusion protection
  * https://www.redhat.com/sysadmin/security-intrusion-detection
  * fail2ban
  * Suricata
  * OSSEC-HIDS
  * Snort
  * Zeek
  * Tripwire
* certs
  * certbot
  * caddy
* SSO
  * https://github.com/greenpau/caddy-security
  * authentik
  * authelia
  * keycloak
* VPN
  * Tailscale/Headscale
    * https://tailscale.com/kb/1136/tailnet
    * https://github.com/tailscale/golink
    * https://github.com/tailscale-dev/tclip
  * wireguard
  * openvpn
* Backup
  * bacula
  * kopia
  * restic
* Hypervisor
  * https://vpsadminos.org/

### VyOS comparison

* Netfiter - does it use nftables? How does its config language map to Netfilter? Can it be extracted?
* FRR - high performance IP routing suite - any use for this in a home router?
* strongSwan - IPsec VPN. IPsec is slower than Wireguard but clients are built into OSes
* Acel-PPP - VPN/tunnel server for PPPoE, PPtP, L2TPv2, SSTP, IPoE
* FastNetMon - DDoS detection
* Squid - caching proxy
* PowerDNS - commercial grade DNS server

### DONE

* Setup host so default network virbr0 starts at boot
  * currently need to us "sudo virsh net-start --network default"
* Does hardware-configuration.nix root disk device need to be updated with each build?
* Get VM starting from command line
* Figure out way to setup SSH without needing to lookup IP in virt-manager
  * Use user network, map SSH to unused port
  * https://unix.stackexchange.com/questions/489891/qemu-access-guest-vm-from-the-host-machine
  * better though would be to add hostname, e.g. homefree-vm
* Share folder automatically setup by qemu xml?
  * https://www.debugpoint.com/share-folder-virt-manager/
