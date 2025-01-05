import XElement from '@x-element';
import ready from '@x-element-ready';

export default class HFRootView extends XElement {
  static get properties() {
    return {
      model: {
        type: Object,
      },

      // Internal props
      componentName: {
        type: String,
        internal: true,
        input: ['model'],
        compute: model => model?.componentName,
      },
    };
  }

  async connectedCallback() {
    super.connectedCallback();
    await ready(document);
    this.ownerDocument.body.removeAttribute('unresolved');
  }

  render() {
    if (this.shadowRoot.lastElementChild) {
      this.shadowRoot.lastElementChild.model = this.model;
    }
  }
}

customElements.define('hf-root-view', HFRootView);
