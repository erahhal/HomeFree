const queries = `
  type Query {
    getSystemStatus: SystemStatus

    getConfig(
      file: String,
      attribute: String
    ): String

    getWanInterface: String

    getLanInterface: String

    getServices: [Service]
  }
`;

export default queries;
