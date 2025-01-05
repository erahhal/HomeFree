import XElement from '@x-element';

export default class HFSystemStatus extends XElement {
  static get properties() {
    return {
      model: {
        type: Object,
      },

      // Internal props
      systemStatus: {
        type: Object,
        internal: true,
        input: ['model'],
        compute: model => model?.systemStatus.data,
        default: () => ({}),
      },
    };
  }

  static template(html) {
    return ({
      systemStatus,
    }) => html`
      <style>
        td {
          border: 1px solid black;
        }
      </style>
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
    `;
  }
}

customElements.define('hf-system-status', HFSystemStatus);

