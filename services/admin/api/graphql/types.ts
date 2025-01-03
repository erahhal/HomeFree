const types = `
  type SystemStatus {
    wanIpV4: String
    wanIpV6: String
    lanIpV4: String
    lanIpV6: String
    memTotalKB: Int
    memFreeKB: Int
    memAvailableKB: Int
    diskTotalKB: Int
    diskAvailableKB: Int
    cpuLoad: String
    uptime: String
  }
`;

export default types;
