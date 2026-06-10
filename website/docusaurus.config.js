const config = {
  title: "TimeManagement",
  tagline: "A practical time, task, and sync workspace for Ubuntu Touch and desktop users",
  favicon: "img/logo.png",
  url: "https://citopenrep.github.io",
  baseUrl: "/timemanagement/",
  organizationName: "CITOpenRep",
  projectName: "timemanagement",
  trailingSlash: false,
  onBrokenLinks: "throw",
  stylesheets: [
    {
      href: "https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@400;500;600;700&display=swap",
      type: "text/css"
    }
  ],
  markdown: {
    mermaid: true,
    hooks: {
      onBrokenMarkdownLinks: "warn"
    }
  },
  i18n: {
    defaultLocale: "en",
    locales: ["en"]
  },
  presets: [
    [
      "classic",
      {
        docs: {
          path: "docs",
          routeBasePath: "docs",
          sidebarPath: require.resolve("./sidebars.js"),
          editUrl: "https://github.com/CITOpenRep/timemanagement/tree/main/website/"
        },
        blog: false,
        theme: {
          customCss: require.resolve("./src/css/custom.css")
        }
      }
    ]
  ],
  themeConfig: {
    image: "img/social-card.png",
    navbar: {
      title: "TimeManagement",
      logo: {
        alt: "TimeManagement logo",
        src: "img/logo.png"
      },
      items: [
        {
          to: "/docs/user/overview",
          label: "Docs",
          position: "left"
        },
        {
          to: "/docs/technical/architecture",
          label: "Technical",
          position: "left"
        },
        {
          to: "/docs/contributing/getting-started",
          label: "Contributing",
          position: "left"
        },
        {
          href: "https://github.com/CITOpenRep/timemanagement",
          label: "GitHub",
          position: "right"
        }
      ]
    },
    footer: {
      style: "dark",
      links: [
        {
          title: "Docs",
          items: [
            {
              label: "User Docs",
              to: "/docs/user/overview"
            },
            {
              label: "Technical Docs",
              to: "/docs/technical/architecture"
            },
            {
              label: "Contributing",
              to: "/docs/contributing/getting-started"
            }
          ]
        },
        {
          title: "Project",
          items: [
            {
              label: "Repository",
              href: "https://github.com/CITOpenRep/timemanagement"
            },
            {
              label: "Issues",
              href: "https://github.com/CITOpenRep/timemanagement/issues"
            }
          ]
        }
      ],
      copyright: `Made with ❤️ by CIT Services · Copyright ${new Date().getFullYear()} CIT-Services`
    },
    prism: {
      theme: require("prism-react-renderer").themes.github,
      darkTheme: require("prism-react-renderer").themes.vsDark
    }
  },
  themes: [
    "@docusaurus/theme-mermaid",
    [
      require.resolve("@easyops-cn/docusaurus-search-local"),
      /** @type {import("@easyops-cn/docusaurus-search-local").Options} */
      ({
        hashed: true,
        language: ["en"],
        docsRouteBasePath: "docs",
        docsDir: "docs",
        indexBlog: false,
        indexDocs: true,
        indexPages: true,
        highlightSearchTermsOnTargetPage: true,
        searchResultLimits: 8,
        searchResultContextMaxLength: 50
      })
    ]
  ]
};

module.exports = config;
