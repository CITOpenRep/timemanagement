const sidebars = {
  docs: [
    {
      type: "category",
      label: "Functional",
      items: [
        {
          type: "category",
          label: "User Manual",
          // Uncomment the line below if 'functional/user-manual' is an actual Markdown file you want to link to when clicking the category title
          // link: { type: 'doc', id: 'functional/user-manual' }, 
          items: [
            "functional/user-manual/introduction",
            "functional/user-manual/dashboard",
            "functional/user-manual/kebab-menu",
            "functional/user-manual/about-us",
            "functional/user-manual/settings",
            "functional/user-manual/projects",
            "functional/user-manual/all-tasks",
            "functional/user-manual/my-tasks",
            "functional/user-manual/project-updates",
            "functional/user-manual/activities",
            "functional/user-manual/timesheets"
          ],
        },
        "user/overview",
        "user/install-and-run",
        "user/setup-and-sync",
        "user/features",
        "user/troubleshooting"
      ]
    },
  

    {
      type: "category",
      label: "Technical",
      items: [
        "technical/architecture",
        "technical/repository-organization",
        "technical/build-and-packaging",
        "technical/release-process"
      ]
    },
    {
      type: "category",
      label: "Contributor",
      items: [
        "contributing/getting-started",
        "contributing/pull-request-guidelines",
        "contributing/documentation-governance"
      ]
    }
  ]
};

module.exports = sidebars;
