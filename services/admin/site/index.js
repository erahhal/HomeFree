import XElement from '/node_modules/@netflix/x-element/x-element.js';

class HomeFreeAdmin extends XElement {
  static template(html) {
    return () => html`<span>HomeFree Admin</span>`;
  }
}

customElements.define('homefree-admin', HomeFreeAdmin);
