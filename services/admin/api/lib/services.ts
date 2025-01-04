import Config from '../lib/config.ts';

export default class Services {
  static async getServices(jsonFile: string) {
    const services = await Config.getStaticServiceData(jsonFile);
    return services;
  }
}
