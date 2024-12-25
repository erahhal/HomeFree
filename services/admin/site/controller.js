export default class HFController {
  constructor(model, view) {
    this.model = model;
    this.view = view;
    this.model.subscribe(data => {
      view.model = data;;
    })
    this.model.endpoint = 'api.homefree.host';
  }
}
