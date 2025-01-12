import Router from './router.js';

const routes = [
  {
    path: '*',
    componentPath: './components/hf-not-found.js',
    componentName: 'hf-not-found',
    title: 'Not Found',
  },
  {
    path: '/',
    componentPath: './components/hf-system-status.js',
    componentName: 'hf-system-status',
    title: 'System Status',
    modelPath: './components/model-system-status.js',
    modelName: 'systemStatus',
  },
  {
    path: '/system-status',
    componentPath: './components/hf-system-status.js',
    componentName: 'hf-system-status',
    title: 'System Status',
    modelPath: './components/model-system-status.js',
    modelName: 'systemStatus',
  },
  {
    path: '/services',
    componentPath: './components/hf-services.js',
    componentName: 'hf-services',
    title: 'Services',
    modelPath: './components/model-services.js',
    modelName: 'services',
  },
  {
    path: '/vulnerabilities',
    componentPath: './components/hf-vulnerabilities.js',
    componentName: 'hf-vulnerabilities',
    title: 'Vulnerabilities',
    modelPath: './components/model-vulnerabilities.js',
    modelName: 'vulnerabilities',
  },
];

export default class HFController {
  constructor(model, view) {
    this.model = model;
    this.view = view;
    this.router = new Router(routes);
    this.model.subscribe(data => {
      view.model = data;
    })
    if (location.hostname === '10.0.0.1') {
      this.model.apiUrl = 'http://10.0.0.1:4001';
    } else {
      this.model.apiUrl = 'https://api.homefree.host';
    }
    this.addEventListeners();

    const path = window.location.pathname;
    this.handleNavigation(path);
  }

  addEventListeners() {
    // Set up link interception
    this.view.addEventListener('click', evt => {
      const elem = evt.composedPath()?.[0];
      if (elem && elem.localName === 'a' && elem.href.startsWith(window.location.origin)) {
        evt.preventDefault();
        this.handleNavigation(elem.pathname);
      }
    });
  }

  async handleNavigation(path) {
    const route = this.router.navigateTo(path);
    this.loadModel(route);
  }

  async loadModel(route) {
    this.model.route = route;
    const { default: subModelClass } = await import(route.modelPath);
    const subModel = new subModelClass();
    // @TODO: Figure out how to have submodels access root model
    subModel.apiUrl = this.model.apiUrl;
    await subModel.load();
    this.model[route.modelName] = subModel;
  }
}
