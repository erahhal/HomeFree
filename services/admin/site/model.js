import {
  proxy,
  snapshot,
  subscribe as valtioSubscribe,
} from '@valtio-vanilla';
import QUERY_SYSTEM_STATUS from './graphql/queries/system-status.js';

export default class HFModel {
  constructor() {
    this.state = proxy({
      apiUrl: '',
    });
  }

  get apiUrl() {
    return this.state.apiUrl;
  };

  set apiUrl(apiUrl) {
    this.state.apiUrl = apiUrl;
  };

  get systemStatus() {
    return this.state.systemStatus;
  };

  set systemStatus(systemStatus) {
    this.state.systemStatus = systemStatus;
  };

  subscribe(fn) {
    valtioSubscribe(this.state, () => {
      fn(snapshot(this.state));
    });
  }

  async queryGraphQL(query, variables = {}) {
    const response = await fetch(`${this.apiUrl}/graphql`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        // Add auth headers
        // 'Authorization': 'Bearer YOUR_TOKEN'
      },
      body: JSON.stringify({
        query,
        variables
      })
    });

    return response.json();
  }

  async fetchSystemStatus() {
    const { data, errors } = await this.queryGraphQL(QUERY_SYSTEM_STATUS);
    return data?.systemStatus;
  }

  async setConfig(attribute, value) {
    variables = {
      // @TODO: load from config
      file: '/home/erahhal/nixcfg/configuration.nix',
      attribute,
      value,
    };
    const { data, errors } = await this.queryGraphQL(MUTATION_SET_CONFIG, variables);
    return data?.setConfig;
  }
}
