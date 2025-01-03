const mutations = `
  type Mutation {
    setConfig(
      file: String,
      attribute: String
      value: String
    ): Boolean
  }
`;

export default mutations;
