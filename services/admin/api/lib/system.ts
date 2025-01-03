export default class SystemStatus {
  static async getIpV4(interfaceName: string) {
    const cmd = new Deno.Command('bash', { args: ['-c', `ip -f inet addr show ${interfaceName} | grep 'scope global'  | sed -En -e 's/.*inet ([0-9.]+).*/\\1/p'`] });
    const { stdout } = await cmd.output();
    return (new TextDecoder().decode(stdout)).trim();
  }

  static async getIpV6(interfaceName: string) {
    const cmd = new Deno.Command('bash', { args: ['-c', `ip -6 addr show ${interfaceName} | grep 'scope global' | grep -v 'temporary\\|deprecated' | grep -o '2[0-9a-f:]*/[0-9]*' | head -n1`] });
    const { stdout } = await cmd.output();
    return (new TextDecoder().decode(stdout)).trim();
  }

  static async getMemTotalKB() {
    const cmd = new Deno.Command('awk', { args: ['/MemTotal/ { printf "%.3d", $2 }', '/proc/meminfo'] });
    const { stdout } = await cmd.output();
    return parseInt(new TextDecoder().decode(stdout));
  }

  static async getMemFreeKB() {
    const cmd = new Deno.Command('awk', { args: ['/MemFree/ { printf "%.3d", $2 }', '/proc/meminfo'] });
    const { stdout } = await cmd.output();
    return parseInt(new TextDecoder().decode(stdout));
  }

  static async getMemAvailableKB() {
    const cmd = new Deno.Command('awk', { args: ['/MemAvailable/ { printf "%.3d", $2 }', '/proc/meminfo'] });
    const { stdout } = await cmd.output();
    return parseInt(new TextDecoder().decode(stdout));
  }

  static async getDiskTotalKB() {
    const cmd = new Deno.Command('bash', { args: ['-c' , 'df -P / | grep -v Filesystem | awk \'{print $2}\''] });
    const { stdout } = await cmd.output();
    return parseInt(new TextDecoder().decode(stdout));
  }

  static async getDiskAvailableKB() {
    const cmd = new Deno.Command('bash', { args: ['-c' , 'df -P / | grep -v Filesystem | awk \'{print $4}\''] });
    const { stdout } = await cmd.output();
    return parseInt(new TextDecoder().decode(stdout));
  }

  static async getCpuLoad() {
    const cmd = new Deno.Command('cat', { args: ['/proc/loadavg'] });
    const { stdout } = await cmd.output();
    return (new TextDecoder().decode(stdout)).trim();
  }

  static async getUptime() {
    const cmd = new Deno.Command('uptime', { args: [] });
    const { stdout } = await cmd.output();
    return (new TextDecoder().decode(stdout)).trim();
  }

  static async getSystemStatus(
    wanInterfaceName: string,
    lanInterfaceName: string,
  ) {
    const promises = [
      this.getIpV4(wanInterfaceName),
      this.getIpV6(wanInterfaceName),
      this.getIpV4(lanInterfaceName),
      this.getIpV6(lanInterfaceName),
      this.getMemTotalKB(),
      this.getMemFreeKB(),
      this.getMemAvailableKB(),
      this.getDiskTotalKB(),
      this.getDiskAvailableKB(),
      this.getCpuLoad(),
      this.getUptime(),
    ];

    const [
      wanIpV4,
      wanIpV6,
      lanIpV4,
      lanIpV6,
      memTotalKB,
      memFreeKB,
      memAvailableKB,
      diskTotalKB,
      diskAvailableKB,
      cpuLoad,
      uptime,
    ] = await Promise.all(promises);

    const result = {
      wanIpV4,
      wanIpV6,
      lanIpV4,
      lanIpV6,
      memTotalKB,
      memFreeKB,
      memAvailableKB,
      diskTotalKB,
      diskAvailableKB,
      cpuLoad,
      uptime,
    };

    return result;
  }
}
