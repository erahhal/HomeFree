import { Hono } from "hono";
import { createYoga } from 'graphql-yoga';
import { createSchema } from 'graphql-yoga';

// Define the GraphQL schema
const schema = createSchema({
  typeDefs: `
    type SystemStatus {
      memoryUsage: String
      diskSpace: String
      cpuLoad: String
      uptime: String
    }

    type Query {
      systemStatus: SystemStatus
    }
  `,
  resolvers: {
    Query: {
      systemStatus: async () => {
        try {
          // Memory info
          const memCmd = new Deno.Command("free", { args: ["-h"] });
          const { stdout: memOut } = await memCmd.output();

          // Disk space
          const diskCmd = new Deno.Command("df", { args: ["-h", "/"] });
          const { stdout: diskOut } = await diskCmd.output();

          // CPU load
          const loadCmd = new Deno.Command("cat", { args: ["/proc/loadavg"] });
          const { stdout: loadOut } = await loadCmd.output();

          // System uptime
          const uptimeCmd = new Deno.Command("uptime", { args: ["-p"] });
          const { stdout: uptimeOut } = await uptimeCmd.output();

          return {
            memoryUsage: new TextDecoder().decode(memOut),
            diskSpace: new TextDecoder().decode(diskOut),
            cpuLoad: new TextDecoder().decode(loadOut),
            uptime: new TextDecoder().decode(uptimeOut)
          };
        } catch (error) {
          console.error('Error executing system commands:', error);
          return {
            memoryUsage: null,
            diskSpace: null,
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
  const result = await resolvers.Query.systemStatus();
  return c.json(result);
});

Deno.serve({ port: 4000 }, app.fetch);
