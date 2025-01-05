import {
  proxy,
  snapshot,
  subscribe as valtioSubscribe,
} from '@valtio-vanilla';

export default class HFModelBase {
  constructor() {
    return proxy(this);
  }

  get apiUrl() {
    return this._apiUrl;
  };

  set apiUrl(apiUrl) {
    this._apiUrl = apiUrl;
  };

  subscribe(fn) {
    valtioSubscribe(this, () => {
      fn(snapshot(this));
    });
  }

  async queryGraphQL(query, variables = {}) {
    const response = await fetch(`${this._apiUrl}/graphql`, {
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
}
