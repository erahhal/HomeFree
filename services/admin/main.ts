import { Hono } from "hono";
import { handle } from "hono/middleware/graphql";
import { buildSchema } from "graphql";

// Define GraphQL schema
const schema = buildSchema(`
  type CommandResult {
    output: String
    error: String
  }

  type Query {
    runCommand(command: String!): CommandResult
  }
`);

// Create resolver using Deno.Command instead of node's exec
const resolvers = {
  runCommand: async ({ command }: { command: string }) => {
    try {
      // Split command into program and args
      const [cmd, ...args] = command.split(" ");
      const p = new Deno.Command(cmd, {
        args: args
      });
      const { stdout, stderr } = await p.output();

      return {
        output: new TextDecoder().decode(stdout),
        error: new TextDecoder().decode(stderr)
      };
    } catch (error) {
      return {
        output: null,
        error: error.message
      };
    }
  }
};

const app = new Hono();

app.use("/graphql", handle({
  schema,
  rootValue: resolvers
}));

Deno.serve(app.fetch);
