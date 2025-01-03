import XElement from '@x-element';
import ready from '@x-element-ready';

export default class HFView extends XElement {
  static get properties() {
    return {
      model: {
        type: Object,
      },

      services: {
        type: Array,
        internal: true,
        input: ['model'],
        compute: model => model?.services,
        default: () => [],
      },
      systemStatus: {
        type: Object,
        internal: true,
        input: ['model'],
        compute: model => model?.systemStatus,
        default: () => ({}),
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
      services,
      systemStatus,
    }) => html`
      <span>HomeFree Admin</span>
      <p>
        WAN IP (v4): ${systemStatus.wanIpV4}
      </p>
      <p>
        WAN IP (v6): ${systemStatus.wanIpV6}
      </p>
      <p>
        LAN IP (v4): ${systemStatus.lanIpV4}
      </p>
      <p>
        LAN IP (v6): ${systemStatus.lanIpV6}
      </p>
      <p>
        Disk Total: ${systemStatus.diskTotalKB} KB
      </p>
      <p>
        Disk Available: ${systemStatus.diskAvailableKB} KB
      </p>
      <p>
        Memory Total: ${systemStatus.memTotalKB} KB
      </p>
      <p>
        Memory Free: ${systemStatus.memFreeKB} KB
      </p>
      <p>
        Memory Available: ${systemStatus.memAvailableKB} KB
      </p>
      <p>
        Uptime: ${systemStatus.uptime}
      </p>
      <p>
        Services
        <ul>
        ${services.map(service => html`
          <li>${service.label}</li>
        `)}
        </ul>
      </p>
    `;
  }
}

customElements.define('hf-view', HFView);
