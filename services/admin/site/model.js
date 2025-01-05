import HFModelBase from './model-base.js';

export default class HFModel extends HFModelBase {
  async setConfig(attribute, value) {
    variables = {
      // @TODO: load from config
      file: '/home/erahhal/nixcfg/configuration.nix',
      attribute,
      value,
    };
    const { data, errors } = await this.queryGraphQL(MUTATION_SET_CONFIG, variables);
    return data?.setConfig;
  }
}
