// import EleventyI18nPlugin from '@11ty/eleventy';
// import pluginRss from '@11ty/eleventy-plugin-rss';
// import syntaxHighlight from '@11ty/eleventy-plugin-syntaxhighlight';

export default async function (eleventyConfig) {
  // eleventyConfig.addPlugin(EleventyI18nPlugin, {
  //   defaultLanguage: 'en',
  //   errorMode: 'allow-fallback',
  // });
  //
  // eleventyConfig.addPlugin(pluginRss);
  //
  // eleventyConfig.addPlugin(syntaxHighlight, {
  //   preAttributes: {
  //     tabindex: 0,
  //   },
  // });

  eleventyConfig.addPassthroughCopy("src/css");
  eleventyConfig.addPassthroughCopy("src/images");

  return {
    htmlTemplateEngine: 'njk',
    markdownTemplateEngine: 'njk',
    dir: {
      input: 'src',
      data: 'data',
      includes: 'includes',
      layouts: 'layouts',
      output: "public",
    },
    pathPrefix: '',
  };
}
