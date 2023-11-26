TODOS
=====

* Make a flake that sets up host machine for dev
* Setup host so default network virbr0 starts at boot
  * currently need to us "sudo virsh net-start --network default"
* Does hardware-configuration.nix root disk device need to be updated with each build?
* Get VM starting from command line - export XML?
* Figure out way to setup SSH without needing to lookup IP in virt-manager
  * Use user network, map SSH to unused port
  * https://unix.stackexchange.com/questions/489891/qemu-access-guest-vm-from-the-host-machine
  * better though would be to add hostname, e.g. homefree-vm
* Figure out how to use host id_rsa.pub in build, rather than hard-coded key
* Disable wait for network to get rid of error
  * What are the ramifications?
* Share folder automatically setup by qemu xml?
  * https://www.debugpoint.com/share-folder-virt-manager/
