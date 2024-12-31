import gql from 'gql-tag';

export default gql`
  query HFSystemStatus {
    systemStatus {
      wanIpV4
      wanIpV6
      lanIpV4
      lanIpV6
      memTotalKB
      memFreeKB
      memAvailableKB
      diskTotalKB
      diskAvailableKB
      cpuLoad
      uptime
    }
  }
`;
