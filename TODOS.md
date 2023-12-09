TODOS
=====

* setup VLANs
  * https://wiki.nftables.org/wiki-nftables/index.php/Main_Page
  * https://serverfault.com/questions/858556/transparent-firewall-with-nftables-and-vlans
  * https://serverfault.com/questions/1057819/route-untagged-vlan-to-a-tagged-vlan-with-nftables
* setup ipv6
* Make a flake that sets up host machine for dev
* Figure out how to use host id_rsa.pub in build, rather than hard-coded key
* Determine if there are any problems with disabling "wait for network" to get rid of error
* Look into microvm instead of qemu, which has been difficult to work with
  * https://github.com/astro/microvm.nix
* setup DNSSEC for dnsmasq
  * https://blog.josefsson.org/2015/10/26/combining-dnsmasq-and-unbound/

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
