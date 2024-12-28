{
  const map = {
    'imports': {
      '@index': '/index.js',
      '@x-element': '/node_modules/@netflix/x-element/x-element.js',
      '@x-element-ready': '/node_modules/@netflix/x-element/etc/ready.js',
      '@valtio-vanilla': '/node_modules/valtio/esm/vanilla.mjs',
      'gql-tag': '/node_modules/gql-tag/dist/index.es.js',
      'proxy-compare': '/node_modules/proxy-compare/dist/index.js'
    },
  };
  const script = document.createElement('script');
  Object.assign(script, { type: 'importmap', textContent: JSON.stringify(map) });
  document.currentScript.after(script);
}
