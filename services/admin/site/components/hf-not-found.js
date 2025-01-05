import XElement from '@x-element';

export default class HFNotFound extends XElement {
  static get properties() {
    return {
    };
  }

  static template(html) {
    return () => html`
      <h1>404 - Page Not Found</h1>
    `;
  }
}

customElements.define('hf-not-found', HFNotFound);
