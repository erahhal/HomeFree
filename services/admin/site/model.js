import {
  proxy,
  snapshot,
  subscribe as valtioSubscribe,
} from '@valtio-vanilla';

export default class HFModel {
  constructor() {
    this.state = proxy({
      endpoint: '',
    });
  }

  get endpoint() {
    return this.state.endpoint;
  };

  set endpoint(endpoint) {
    this.state.endpoint = endpoint;
  };

  subscribe(fn) {
    valtioSubscribe(this.state, () => {
      fn(snapshot(this.state));
    });
  }
}
