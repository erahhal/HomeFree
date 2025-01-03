import SystemStatus from '../lib/system.ts';
import Config from '../lib/config.ts';

const CONFIG_FILE = '/home/erahhal/nixcfg/configuration.nix';

interface SetConfigInput {
  attribute: string;
  value: string;
}

const resolvers = {
  Mutation: {
    // @TODO: don't take a file. Ready from config.json
    setConfig: async (_, setConfigInput: SetConfigInput) => {
      const result = await Config.setConfig(
        CONFIG_FILE,
        setConfigInput.attribute,
        setConfigInput.value,
      );
      return result;
    },
  },
  Query: {
    // @TODO: don't take a file. Ready from config.json
    getConfig: async (attribute: string) => {
      const value = await Config.getConfig(
        CONFIG_FILE,
        attribute,
      );
      return value;
    },
    systemStatus: async () => {
      const [wanInterface, lanInterface] = await Promise.all([
        Config.getWanInterface(CONFIG_FILE),
        Config.getLanInterface(CONFIG_FILE),
      ]);
      const systemStatus = SystemStatus.getSystemStatus(wanInterface, lanInterface);
      return systemStatus;
    }
  }
};

export default resolvers;
