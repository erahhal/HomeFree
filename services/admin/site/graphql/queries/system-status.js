import gql from 'gql-tag';

export default gql`
  query HFSystemStatus {
    systemStatus {
      memoryUsage
      diskSpace
      cpuLoad
      uptime
    }
  }
`;
