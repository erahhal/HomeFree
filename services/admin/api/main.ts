import { Hono } from "hono";
import { createYoga } from 'graphql-yoga';
import { createSchema } from 'graphql-yoga';

// Define the GraphQL schema
const schema = createSchema({
  typeDefs: `
    type SystemStatus {
      wanIpV4: String
      wanIpV6: String
      lanIpV4: String
      lanIpV6: String
      memTotalKB: Int
      memFreeKB: Int
      memAvailableKB: Int
      diskTotalKB: Int
      diskAvailableKB: Int
      cpuLoad: String
      uptime: String
    }

    type Mutation {
      setConfig(
        file: String,
        attribute: String
        value: String
      ): Boolean
    }

    type Query {
      systemStatus: SystemStatus

      getConfig(
        file: String,
        attribute: String
      ): String
    }
  `,
  resolvers: {
    Mutation: {
      // @TODO: don't take a file. Ready from config.json
      setConfig: async (_, { file, attribute, value }) => {
        try {
          const setConfigCmd = new Deno.Command('nix-editor', { args: ['-i', file, attribute, '-v', value] });
          const { stdout } = await setConfigCmd.output();
          const setConfigOut = (new TextDecoder().decode(stdout)).trim();
          return true;
        } catch (error) {
          console.error('Error executing setConfig mutation:', error);
          return false;
        }
      },
    },
    Query: {
      // @TODO: don't take a file. Ready from config.json
      getConfig: async (file, attribute) => {
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
        try {
          const wanIpV4Cmd = new Deno.Command('bash', { args: ['-c', 'ip -f inet addr show eno1 | grep \'scope global\'  | sed -En -e \'s/.*inet ([0-9.]+).*/\\1/p\''] });
          const { stdout: wanIpV4Out } = await wanIpV4Cmd.output();
          const wanIpV4 = (new TextDecoder().decode(wanIpV4Out)).trim();

          const wanIpV6Cmd = new Deno.Command('bash', { args: ['-c', 'ip -6 addr show eno1 | grep \'scope global\' | grep -v \'temporary\\|deprecated\' | grep -o \'2[0-9a-f:]*/[0-9]*\' | head -n1'] });
          const { stdout: wanIpV6Out } = await wanIpV6Cmd.output();
          const wanIpV6 = (new TextDecoder().decode(wanIpV6Out)).trim();

          const lanIpV4Cmd = new Deno.Command('bash', { args: ['-c', 'ip -f inet addr show enp112s0 | grep \'scope global\'  | sed -En -e \'s/.*inet ([0-9.]+).*/\\1/p\''] });
          const { stdout: lanIpV4Out } = await lanIpV4Cmd.output();
          const lanIpV4 = (new TextDecoder().decode(lanIpV4Out)).trim();

          const lanIpV6Cmd = new Deno.Command('bash', { args: ['-c', 'ip -6 addr show enp112s0 | grep \'scope global\' | grep -v \'temporary\\|deprecated\' | grep -o \'2[0-9a-f:]*/[0-9]*\' | head -n1'] });
          const { stdout: lanIpV6Out } = await lanIpV6Cmd.output();
          const lanIpV6 = (new TextDecoder().decode(lanIpV6Out)).trim();

          const memTotalKBCmd = new Deno.Command('awk', { args: ['/MemTotal/ { printf "%.3d", $2 }', '/proc/meminfo'] });
          const { stdout: memTotalKBOut } = await memTotalKBCmd.output();
          const memTotalKB = parseInt(new TextDecoder().decode(memTotalKBOut));

          const memFreeKBCmd = new Deno.Command('awk', { args: ['/MemFree/ { printf "%.3d", $2 }', '/proc/meminfo'] });
          const { stdout: memFreeKBOut } = await memFreeKBCmd.output();
          const memFreeKB = parseInt(new TextDecoder().decode(memFreeKBOut));

          const memAvailableKBCmd = new Deno.Command('awk', { args: ['/MemAvailable/ { printf "%.3d", $2 }', '/proc/meminfo'] });
          const { stdout: memAvailableKBOut } = await memAvailableKBCmd.output();
          const memAvailableKB = parseInt(new TextDecoder().decode(memAvailableKBOut));

          const diskTotalKBCmd = new Deno.Command('bash', { args: ['-c' , 'df -P / | grep -v Filesystem | awk \'{print $2}\''] });
          const { stdout: diskTotalKBOut } = await diskTotalKBCmd.output();
          const diskTotalKB = parseInt(new TextDecoder().decode(diskTotalKBOut));

          const diskAvailableKBCmd = new Deno.Command('bash', { args: ['-c' , 'df -P / | grep -v Filesystem | awk \'{print $4}\''] });
          const { stdout: diskAvailableKBOut } = await diskAvailableKBCmd.output();
          const diskAvailableKB = parseInt(new TextDecoder().decode(diskAvailableKBOut));

          const loadCmd = new Deno.Command('cat', { args: ['/proc/loadavg'] });
          const { stdout: loadOut } = await loadCmd.output();
          const cpuLoad = (new TextDecoder().decode(loadOut)).trim();

          const uptimeCmd = new Deno.Command('uptime', { args: [] });
          const { stdout: uptimeOut } = await uptimeCmd.output();
          const uptime = (new TextDecoder().decode(uptimeOut)).trim();

          return {
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
        } catch (error) {
          console.error('Error executing system commands:', error);
          return {
            wanIpV4: null,
            wanIpV6: null,
            lanIpV4: null,
            lanIpV6: null,
            memTotalKB: null,
            memFreeKB: null,
            memAvailableKB: null,
            diskTotalKB: null,
            diskAvailableKB: null,
            cpuLoad: null,
            uptime: null
          };
        }
      }
    }
  }
});

const app = new Hono();

// Create the yoga instance
const yoga = createYoga({ schema });

// Add yoga middleware to Hono
app.use('/graphql', async (c) => {
  const response = await yoga.handle(c.req.raw);
  return response;
});

// Keep the REST endpoint as a fallback
app.get("/api/system-status", async (c) => {
  const response = await yoga.handle(c.req.raw);
  return c.json(response);
});

const options: Object = Deno.args.reduce((acc: object, arg: string, index: number, arr: string[]) => {
  if (index > 0 && arr[index - 1].startsWith('--')) {
    const name = arr[index - 1].slice(2);
    acc[name] = arg;
  }
  return acc;
}, {});

const port = options['port'] || 4000;

Deno.serve({ port }, app.fetch);
