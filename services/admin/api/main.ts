import { Hono } from "hono";
import { createYoga } from 'graphql-yoga';
import { createSchema } from 'graphql-yoga';
import mutations from './graphql/mutations.ts';
import queries from './graphql/queries.ts';
import types from './graphql/types.ts';
import resolvers from './graphql/resolvers.ts';

// Define the GraphQL schema
const schema = createSchema({
  typeDefs: `
    ${types}
    ${mutations}
    ${queries}
  `,
  resolvers,
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

const options: {[key: string]: string} = Deno.args.reduce((acc: {[key: string]: string}, arg: string, index: number, arr: string[]) => {
  if (index > 0 && arr[index - 1].startsWith('--')) {
    const name = arr[index - 1].slice(2);
    acc[name] = arg;
  }
  return acc;
}, {});

const port: number = options['port'] ? parseInt(options['port']) : 4000;

Deno.serve({ port }, app.fetch);
