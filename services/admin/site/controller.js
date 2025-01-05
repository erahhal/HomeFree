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

    // this.loadMainPage();
  }

  addEventListeners() {
    // Set up link interception
    this.view.addEventListener('click', (e) => {
      const link = e.target.closest('a');
      if (link && link.href.startsWith(window.location.origin)) {
        e.preventDefault();
        this.handleNavigation(link.pathname);
      }
    });
  }

  handleNavigation(path) {
    const route = this.router.navigateTo(path);
    this.loadView(route);
    this.loadModel(route);
  }

  async loadView(route) {
    // Clean up previous component if it exists
    if (this.currentComponent && this.currentComponent.disconnectedCallback) {
      this.currentComponent.disconnectedCallback();
      this.currentComponent.remove();
      this.currentComponent = undefined;
    }

    try {
      // Create and append new component
      await import(route.componentPath);
      this.currentComponent = document.createElement(route.componentName);

      if (route.routeParams) {
        // do something with params
      }

      this.view.shadowRoot.appendChild(this.currentComponent);

      // Update document title if provided
      if (route.title) {
        document.title = route.title;
      }
    } catch (error) {
      console.error('Error loading component:', error);
      const errorComponent = document.createElement('div');
      errorComponent.innerHTML = '<h1>Error loading page</h1>';
      this.view.shadowRoot.appendChild(errorComponent);
    }
  }

  async loadModel(route) {
    const { default: subModelClass } = await import(route.modelPath);
    const subModel = new subModelClass();
    // @TODO: Figure out how to have submodels access root model
    subModel.apiUrl = this.model.apiUrl;
    await subModel.load();
    this.model[route.modelName] = subModel;
  }
}
