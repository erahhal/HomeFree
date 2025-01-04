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

  type ReverseProxyConfig {
    basicAuth: Boolean
    description: String
    enable: Boolean!
    extraCaddyConfig: String
    host: String
    httpDomains: [String]!
    httpsDomains: [String]!
    port: Int
    public: Boolean!
    rootDomain: Boolean!
    ssl: Boolean!
    sslNoVerify: Boolean!
    staticPath: String
    subdir: String
    subdomains: [String!]!
  }

  type BackupConfig {
    paths: [String]!
    postgresDatabases: [String]!
  }

  type ServiceConfig {
    name: String
    icon: String
    label: String
    projectName: String
    reverseProxyConfig: ReverseProxyConfig
    backupConfig: BackupConfig
    systemdServiceName: String
  }

  enum ServiceActiveState {
    ACTIVE
    RELOADING
    INACTIVE
    FAILED
    ACTIVATING
    DEACTIVATING
    MAINTENANCE
  }

  enum ServiceSubState {
    RUNNING
    DEAD
    FAILED
    EXITED
    RELOADING
    AUTO_RESTART
    START
    STOP
    FINAL_SIGTERM
    FINAL_SIGKILL
  }

  type Service {
    serviceConfig: ServiceConfig
    serviceActiveState: ServiceActiveState
    serviceSubState: ServiceSubState
    url: String
  }
`;

export default types;
