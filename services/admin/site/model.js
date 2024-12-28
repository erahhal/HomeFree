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

    const data = await response.json();
    return data;
  }

  async getSystemStatus() {
    return this.queryGraphQL(QUERY_SYSTEM_STATUS);
  }
}
