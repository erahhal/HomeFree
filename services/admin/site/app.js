import HFController from './controller.js';
import HFModel from './model.js';
import HFRootView from './root-view.js';

class HFApp extends HTMLElement {
  async connectedCallback() {
    this.model = new HFModel();
    this.view = new HFRootView();
    this.attachShadow({ mode: "open" });
    this.shadowRoot.appendChild(this.view);
    this.controller = new HFController(this.model, this.view);
  }
}

customElements.define('hf-app', HFApp);
