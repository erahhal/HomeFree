{ config, lib, pkgs, ... }:
{
  #-----------------------------------------------------------------------------------------------------
  # Ad blocking
  #-----------------------------------------------------------------------------------------------------

  services.adguardhome = {
    enable = true;
    openFirewall = true;
    port = 3000;
    settings = {
      http = {
        address = "0.0.0.0:3000";
        session_ttl = "720h";
      };
      users = [
        {
          name = config.homefree.system.adminUsername;
          password = "$2a$10$Tt4QvbLQxnspv2TbcLMP7ug8eJ0NqMsGyVPbpEqtmkyCVrFpvh4GS";
          # password = config.homefree.system.adminHashedPassword;
        }
      ];
      auth_attempts = 5;
      block_auth_min = 15;
      theme = "auto";
      dns = {
        bind_hosts = [ "0.0.0.0" ];
        port = 53;
        anonymize_client_ip = false;
        ratelimit = 20;
        ratelimit_subnet_len_ipv4 = 24;
        ratelimit_subnet_len_ipv6 = 56;
        ratelimit_whitelist = [];
        refuse_any = true;
        upstream_dns = [
          "10.0.0.1"
          "https://dns10.quad9.net/dns-query"
        ];
        bootstrap_dns = [
          "9.9.9.10"
          "149.112.112.10"
          "2620:fe::10"
          "2620:fe::fe:10"
        ];
        upstream_mode = "load_balance";
        fastest_timeout = "1s";
        blocked_hosts = [
          "version.bind"
          "id.server"
          "hostname.bind"
        ];
        trusted_proxies = [
          "127.0.0.0/8"
          "::1/128"
        ];
        cache_size = 4194304;
        cache_ttl_min = 0;
        cache_ttl_max = 0;
        cache_optimistic = false;
        aaaa_disabled = false;
        enable_dnssec = false;
        edns_client_subnet = {
          custom_ip = "";
          enabled = false;
          use_custom = false;
        };
        max_goroutines = 300;
        handle_ddr = true;
        ipset = [];
        ipset_file = "";
        bootstrap_prefer_ipv6 = false;
        upstream_timeout = "10s";
        private_networks = [];
        use_private_ptr_resolvers = true;
        local_ptr_upstreams = [];
        use_dns64 = false;
        dns64_prefixes = [];
        serve_http3 = false;
        use_http3_upstreams = false;
        serve_plain_dns = true;
        hostsfile_enabled = true;
      };
      filters = [
        {
          enabled = true;
          url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt";
          name = "AdGuard DNS filter";
          id = 1;
        }
        {
          enabled = false;
          url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_2.txt";
          name = "AdAway Default Blocklist";
          id = 2;
        }
      ];
      whitelist_filters = [];
      user_rules = [];
      dhcp = {
        enabled = false;
      };
      filtering = {
        blocking_ipv4 = "";
        blocking_ipv6 = "";
        blocked_services = {
          schedule = {
            time_zone = "Local";
          };
          ids = [];
        };
        protection_disabled_until = null;
        safe_search = {
          enabled = false;
          bing = true;
          duckduckgo = true;
          google = true;
          pixabay = true;
          yandex = true;
          youtube = true;
        };
        blocking_mode = "default";
        parental_block_host = "family-block.dns.adguard.com";
        safebrowsing_block_host = "standard-block.dns.adguard.com";
        rewrites = [];
        safebrowsing_cache_size = 1048576;
        safesearch_cache_size = 1048576;
        parental_cache_size = 1048576;
        cache_time = 30;
        filters_update_interval = 24;
        blocked_response_ttl = 10;
        filtering_enabled = true;
        parental_enabled = false;
        safebrowsing_enabled = false;
        protection_enabled = true;
      };
      clients = {
        runtime_sources = {
          whois = true;
          arp = true;
          rdns = true;
          dhcp = true;
          hosts = true;
        };
        persistent = [];
      };
      log = {
        file = "";
        max_backups = 0;
        max_size = 100;
        max_age = 3;
        compress = false;
        local_time = false;
        verbose = false;
      };
      schema_version = 28;
    };
  };
}
