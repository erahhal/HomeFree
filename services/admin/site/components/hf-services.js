import XElement from '@x-element';

export default class HFServices extends XElement {
  static get properties() {
    return {
      model: {
        type: Object,
      },

      // Internal props
      services: {
        type: Array,
        internal: true,
        input: ['model'],
        compute: model => model?.services.data,
        default: () => [],
      },
    };
  }

  static template(html) {
    return ({
      services,
    }) => html`
      <style>
        td {
          border: 1px solid black;
        }
      </style>
      <p>
        Services
        <ul>
        ${services.map(service => html`
          <li><a href="${service.url}" target="_blank">${service.serviceConfig.name || service.url}</a></li>
        `)}
        </ul>
      </p>
    `;
  }
}

customElements.define('hf-services', HFServices);
