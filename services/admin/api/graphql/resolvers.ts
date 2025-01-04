import SystemStatus from '../lib/system.ts';
import Config from '../lib/config.ts';
import Services from '../lib/services.ts';

const NIX_CONFIG_FILE = '/home/erahhal/nixcfg/configuration.nix';
const JSON_CONFIG_FILE = '/run/homefree/admin/config.json';

interface SetConfigInput {
  attribute: string;
  value: string;
}

const resolvers = {
  Mutation: {
    // @TODO: don't take a file. Ready from config.json
    setConfig: async (_, setConfigInput: SetConfigInput) => {
      const result = await Config.setNixConfig(
        NIX_CONFIG_FILE,
        setConfigInput.attribute,
        setConfigInput.value,
      );
      return result;
    },
  },
  Query: {
    // @TODO: don't take a file. Ready from config.json
    getConfig: async (attribute: string) => {
      const value = await Config.getNixConfig(
        NIX_CONFIG_FILE,
        attribute,
      );
      return value;
    },
    getSystemStatus: async () => {
      const [wanInterface, lanInterface] = await Promise.all([
        Config.getWanInterface(NIX_CONFIG_FILE),
        Config.getLanInterface(NIX_CONFIG_FILE),
      ]);
      const systemStatus = SystemStatus.getSystemStatus(wanInterface, lanInterface);
      return systemStatus;
    },
    getServices: async () => {
      // @TODO: replace with Services.getServices
      const services = await Services.getServices(JSON_CONFIG_FILE);
      return services;
    },
  }
};

export default resolvers;
