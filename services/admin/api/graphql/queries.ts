const queries = `
  type Query {
    systemStatus: SystemStatus

    getConfig(
      file: String,
      attribute: String
    ): String

    getWanInterface: String

    getLanInterface: String
  }
`;

export default queries;
