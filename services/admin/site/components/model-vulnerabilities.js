import HFModelBase from "../model-base.js";
import QUERY_GET_VULNERABILITIES from '../graphql/queries/get-vulnerabilities.js';

export default class HFModelVulnerabilities extends HFModelBase {
  async load() {
    const { data, errors } = await this.queryGraphQL(QUERY_GET_VULNERABILITIES);
    if (data?.getVulnerabilities) {
      this.data = data.getVulnerabilities;
    }
  }
}
