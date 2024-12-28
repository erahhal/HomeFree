export default class HFController {
  constructor(model, view) {
    this.model = model;
    this.view = view;
    this.model.subscribe(data => {
      view.model = data;;
    })
    this.model.apiUrl = 'https://api.homefree.host';
    this.getSystemStatus();
  }

  async getSystemStatus() {
    const systemStatus = await this.model.getSystemStatus();
    console.log(systemStatus);
  }
}
