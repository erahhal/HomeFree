export default class Router {
  constructor(routes) {
    this.routes = routes;

    // Set up history listener
    window.addEventListener('popstate', () => {
      const path = window.location.pathname;
      this.handleRoute(path);
    });
  }

  handleRoute(path) {
    const route = this.routes.find(r => {
      if (typeof r.path === 'string') {
        return r.path === path;
      }
      return r.path.test(path);
    });

    if (!route) {
      // Handle 404
      const notFoundRoute = this.routes.find(r => r.path === '*');
      if (notFoundRoute) {
        return notFoundRoute;
      } else {
        throw new Error('Must define "*" Not Found route.');
      }
    }

    // Extract route params if any
    let routeParams = {};
    if (typeof route.path === 'object') {
      const matches = path.match(route.path);
      if (matches && matches.groups) {
        routeParams = matches.groups;
      }
    }

    return {
      ...route,
      routeParams
    };
  }

  navigateTo(path) {
    window.history.pushState(null, '', path);
    return this.handleRoute(path);
  }
}
