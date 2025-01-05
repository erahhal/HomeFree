import XElement from '@x-element';

export default class HFVulnerabilities extends XElement {
  static get properties() {
    return {
      model: {
        type: Object,
      },

      vulnerabilities: {
        type: Array,
        internal: true,
        input: ['model'],
        compute: model => model?.vulnerabilities?.data.map(vuln => ({
          ...vuln,
          cves: vuln.cves.map(cve => ({
            ...cve,
            url: `https://nvd.nist.gov/vuln/detail/${cve.cveId}`,
          })),
        })),
        default: () => [],
      },
    };
  }

  static template(html) {
    return ({
      vulnerabilities
    }) => html`
      <style>
        td {
          border: 1px solid black;
        }
      </style>
      <p>
        Vulnerabilities
        <table>
        ${vulnerabilities.map(vuln => html`
          <tr>
            <td>
              ${vuln.name}
            </td>
            <td>
              ${vuln.pname}
            </td>
            <td>
              ${vuln.version}
            </td>
            <td>
              <table>
                ${vuln.cves.map(cve => html`
                  <tr>
                    <td>
                      <a href="${cve.url}" target="_blank">${cve.cveId}</a>
                    </td>
                    <td>
                      ${cve.cvssv3BaseScore}
                    </td>
                    <td>
                      ${cve.severity}
                    </td>
                    <td>
                      ${cve.description}
                    </td>
                  </tr>
                `)}
              </table>
            </td>
          </tr>
        `)}
        </ul>
      </p>
    `;
  }
}

customElements.define('hf-vulnerabilities', HFVulnerabilities);

