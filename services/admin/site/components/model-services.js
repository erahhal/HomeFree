import HFModelBase from "../model-base.js";
import QUERY_GET_SERVICES from '../graphql/queries/get-services.js';

export default class HFModelServices extends HFModelBase {
  async load() {
    const { data, errors } = await this.queryGraphQL(QUERY_GET_SERVICES);
    if (data?.getServices) {
      this.data = data.getServices;
    }
  }
}
