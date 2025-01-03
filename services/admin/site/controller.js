export default class HFController {
  constructor(model, view) {
    this.model = model;
    this.view = view;
    this.model.subscribe(data => {
      view.model = data;;
    })
    if (location.hostname === '10.0.0.1') {
      this.model.apiUrl = 'http://10.0.0.1:4001';
    } else {
      this.model.apiUrl = 'https://api.homefree.host';
    }
    this.loadMainPage();
  }

  async loadMainPage() {
    this.model.systemStatus = await this.model.fetchSystemStatus();
  }
}
