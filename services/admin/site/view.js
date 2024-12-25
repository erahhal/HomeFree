import XElement from '@x-element';
import ready from '@x-element-ready';

export default class HFView extends XElement {
  static get properties() {
    return {
      model: {
        type: Object,
      },
    };
  }

  async connectedCallback() {
    super.connectedCallback();
    await ready(document);
    this.ownerDocument.body.removeAttribute('unresolved');
  }

  static template(html) {
    return ({
      model,
    }) => html`
      <span>HomeFree Admin</span>
      <p>
        ${model?.endpoint}
      </p>
    `;
  }
}

customElements.define('hf-view', HFView);
