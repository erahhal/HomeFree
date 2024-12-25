import HFController from './controller.js';
import HFModel from './model.js';
import HFView from './view.js';

class HFApp extends HTMLElement {
  constructor() {
    super();
    this.model = new HFModel();
    this.view = new HFView();
    this.attachShadow({ mode: 'open' });
    this.shadowRoot.appendChild(this.view);
    this.controller = new HFController(this.model, this.view);
  }
}

customElements.define('hf-app', HFApp);
