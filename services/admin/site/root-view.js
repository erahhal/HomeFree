import XElement from '@x-element';
import ready from '@x-element-ready';

export default class HFRootView extends XElement {
  #contentElem;

  static get properties() {
    return {
      model: {
        type: Object,
      },

      // Internal props
      route: {
        type: Object,
        internal: true,
        input: ['model'],
        compute: model => model?.route,
        observe: async (host, route, oldRoute) => {
          if (oldRoute) {
            host.shadowRoot.querySelector(oldRoute.componentName).remove();
          }
          await import(route.componentPath);
          host.#contentElem = document.createElement(route.componentName);
          if (route.title) {
            document.title = route.title;
          }
          host.shadowRoot.getElementById('content').appendChild(host.#contentElem);
        },
      },
    };
  }

  async connectedCallback() {
    super.connectedCallback();
    await ready(document);
    this.ownerDocument.body.removeAttribute('unresolved');
  }

  static template(html) {
    return ({ model }) => html`
      <style>
        :host {
          --primary-color: #2563eb;
          --secondary-color: #1e40af;
          --background-color: #f8fafc;
          --text-color: #1e293b;
          --border-color: #e2e8f0;
        }

        :host * {
          margin: 0;
          padding: 0;
          box-sizing: border-box;
        }

        :host {
          font-family: system-ui, -apple-system, sans-serif;
          background-color: var(--background-color);
          color: var(--text-color);
          line-height: 1.5;
        }

        .header {
          background-color: white;
          border-bottom: 1px solid var(--border-color);
          padding: 1rem;
          position: fixed;
          top: 0;
          width: 100%;
          z-index: 100;
        }

        .nav-container {
          max-width: 1200px;
          margin: 0 auto;
          display: flex;
          justify-content: space-between;
          align-items: center;
        }

        .logo {
          font-size: 1.5rem;
          font-weight: bold;
          color: var(--primary-color);
        }

        .nav-menu {
          display: flex;
          gap: 2rem;
          list-style: none;
        }

        .nav-link {
          color: var(--text-color);
          text-decoration: none;
          font-weight: 500;
          padding: 0.5rem;
          border-radius: 0.375rem;
          transition: background-color 0.2s;
        }

        .nav-link:hover {
          background-color: var(--border-color);
        }

        .nav-link.active {
          color: var(--primary-color);
        }

        .main-content {
          max-width: 1200px;
          margin: 5rem auto 4rem;
          padding: 2rem;
          min-height: calc(100vh - 9rem);
        }

        .footer {
          background-color: white;
          border-top: 1px solid var(--border-color);
          padding: 1rem;
          position: fixed;
          bottom: 0;
          width: 100%;
        }

        .status-container {
          max-width: 1200px;
          margin: 0 auto;
          display: flex;
          justify-content: space-between;
          align-items: center;
          font-size: 0.875rem;
        }

        .status-indicator {
          display: flex;
          align-items: center;
          gap: 0.5rem;
        }

        .status-dot {
          width: 8px;
          height: 8px;
          border-radius: 50%;
          background-color: #22c55e;
        }

        @media (max-width: 768px) {
          .nav-menu {
            display: none;
          }
        }
      </style>
      <header class="header">
        <nav class="nav-container">
          <div class="logo">HomeFree Admin</div>
          <ul class="nav-menu">
            <li><a href="/" class="nav-link active">Dashboard</a></li>
            <li><a href="/services" class="nav-link">Services</a></li>
            <li><a href="/vulnerabilities" class="nav-link">Security</a></li>
            <li><a href="/settings" class="nav-link">Settings</a></li>
          </ul>
        </nav>
      </header>

      <main class="main-content">
        <div id="content">
          <!-- Content will be dynamically loaded here -->
        </div>
      </main>

      <footer class="footer">
        <div class="status-container">
          <div class="status-indicator">
            <div class="status-dot"></div>
            <span>System Status: Online</span>
          </div>
          <div class="connection-info">
            <span>Connected Devices: <span id="deviceCount">0</span></span>
          </div>
        </div>
      </footer>

      <script>
        // Navigation handling
        const navLinks = document.querySelectorAll('.nav-link');
        const content = document.getElementById('content');
        const deviceCount = document.getElementById('deviceCount');

        // Simulated connected devices count
        let connectedDevices = 0;

        // Update connected devices periodically
        function updateDeviceCount() {
          connectedDevices = Math.floor(Math.random() * 10) + 1;
          deviceCount.textContent = connectedDevices;
        }

        // Initialize and update device count every 5 seconds
        updateDeviceCount();
        setInterval(updateDeviceCount, 5000);

        // Handle navigation
        navLinks.forEach(link => {
          link.addEventListener('click', (e) => {
            e.preventDefault();

            // Remove active class from all links
            navLinks.forEach(l => l.classList.remove('active'));

            // Add active class to clicked link
            link.classList.add('active');

            // Get the route from href
            const route = link.getAttribute('href').substring(1);

            // Update content based on route
            updateContent(route);
          });
        });

        // Simple content updates based on route
        function updateContent(route) {
          const contentMap = {
            dashboard: '<h1>Dashboard</h1><p>Welcome to your router dashboard.</p>',
            network: '<h1>Network Settings</h1><p>Configure your network settings here.</p>',
            security: '<h1>Security</h1><p>Manage your router security settings.</p>',
            settings: '<h1>System Settings</h1><p>Adjust your router system settings.</p>'
          };

          content.innerHTML = contentMap[route] || '<h1>Page Not Found</h1>';
        }
      </script>
    `;
  }

  render() {
    super.render();
    if (this.#contentElem) {
      this.#contentElem.model = this.model;
    }
  }
}

customElements.define('hf-root-view', HFRootView);
