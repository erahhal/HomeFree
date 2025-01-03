export default class Config {
  static async getConfig(file: string, attribute: string) {
    try {
      const cmd = new Deno.Command('nix-editor', { args: [file, attribute] });
      const { stdout } = await cmd.output();
      return (new TextDecoder().decode(stdout)).trim();
    } catch (error) {
      console.error('Error executing setConfig mutation:', error);
      return null;
    }
  }

  static async setConfig(file: string, attribute: string, value: string) {
    try {
      const cmd = new Deno.Command('nix-editor', { args: ['-i', file, attribute, '-v', value] });
      await cmd.output();
      return true;
    } catch (error) {
      console.error('Error executing setConfig mutation:', error);
      return false;
    }
  }

  static async getWanInterface(file:string) {
    const wanInterface = await this.getConfig(file, 'homefree.network.wan-interface');
    return wanInterface;
  }

  static async getLanInterface(file:string) {
    const lanInterface = await this.getConfig(file, 'homefree.network.lan-interface');
    return lanInterface;
  }
}
