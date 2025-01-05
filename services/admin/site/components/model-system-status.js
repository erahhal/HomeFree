import HFModelBase from "../model-base.js";
import QUERY_GET_SYSTEM_STATUS from '../graphql/queries/get-system-status.js';

export default class HFModelSystemStatus extends HFModelBase {
  async load() {
    const { data, errors } = await this.queryGraphQL(QUERY_GET_SYSTEM_STATUS);
    if (data?.getSystemStatus) {
      this.data = data.getSystemStatus;
    }
  }
}
