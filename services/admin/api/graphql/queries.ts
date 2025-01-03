const queries = `
  type Query {
    systemStatus: SystemStatus

    getConfig(
      file: String,
      attribute: String
    ): String
  }
`;

export default queries;
