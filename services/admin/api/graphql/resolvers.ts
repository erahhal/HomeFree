import SystemStatus from '../lib/system.ts';

interface SetConfigInput {
  file: string;
  attribute: string;
  value: string;
}

const resolvers = {
  Mutation: {
    // @TODO: don't take a file. Ready from config.json
    setConfig: async (_, setConfigInput: SetConfigInput) => {
      try {
        const setConfigCmd = new Deno.Command('nix-editor', { args: ['-i', setConfigInput.file, setConfigInput.attribute, '-v', setConfigInput.value] });
        await setConfigCmd.output();
        return true;
      } catch (error) {
        console.error('Error executing setConfig mutation:', error);
        return false;
      }
    },
  },
  Query: {
    // @TODO: don't take a file. Ready from config.json
    getConfig: async (file: string, attribute: string) => {
      try {
        const setConfigCmd = new Deno.Command('nix-editor', { args: [file, attribute] });
        const { stdout } = await setConfigCmd.output();
        const setConfigOut = (new TextDecoder().decode(stdout)).trim();
        return setConfigOut;
      } catch (error) {
        console.error('Error executing setConfig mutation:', error);
        return false;
      }
    },
    systemStatus: async () => {
      const systemStatus = SystemStatus.getSystemStatus('eno1', 'enp112s0');
      return systemStatus;
    }
  }
};

export default resolvers;
