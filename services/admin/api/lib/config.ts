export const toCamelCase = (obj: object) => {
  if (typeof obj !== "object" || obj === null) {
    return obj;
  }

  if (Array.isArray(obj)) {
    return obj.map(toCamelCase);
  }

  const newObj = {};
  for (const key in obj) {
    const camelKey = key.replace(/[_-]([a-z])/g, (match, p1) => p1.toUpperCase());
    newObj[camelKey] = toCamelCase(obj[key]);
  }
  return newObj;
};

export default class Config {
  static async getNixConfig(file: string, attribute: string) {
    try {
      const cmd = new Deno.Command('nix-editor', { args: [file, attribute] });
      const { stdout } = await cmd.output();
      return (new TextDecoder().decode(stdout)).trim();
    } catch (error) {
      console.error('Error executing setConfig mutation:', error);
      return null;
    }
  }

  static async setNixConfig(file: string, attribute: string, value: string) {
    try {
      const cmd = new Deno.Command('nix-editor', { args: ['-i', file, attribute, '-v', value] });
      await cmd.output();
      return true;
    } catch (error) {
      console.error('Error executing setConfig mutation:', error);
      return false;
    }
  }

  static async getJson(filePath: string) {
    return JSON.parse(await Deno.readTextFile(filePath));
  }

  static kebabToCamel(str: string) {
    return str.replace(/-([a-z])/g, match => match[1].toUpperCase());
  }

  static async getWanInterface(nixFile: string) {
    const wanInterface = await this.getNixConfig(nixFile, 'homefree.network.wan-interface');
    return wanInterface;
  }

  static async getLanInterface(nixFile: string) {
    const lanInterface = await this.getNixConfig(nixFile, 'homefree.network.lan-interface');
    return lanInterface;
  }

  static async getStaticServiceData(jsonFile: string) {
    const config = await this.getJson(jsonFile);
    const serviceData = toCamelCase(config.services);
    return serviceData;
  }
}
