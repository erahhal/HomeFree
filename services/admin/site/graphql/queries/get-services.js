import gql from 'gql-tag';

export default gql`
  query HFGetServices {
    getServices {
      serviceConfig {
        name
        icon
        projectName
        systemdServiceName
      }
      url
    }
  }
`;
