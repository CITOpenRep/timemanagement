const sidebars = {
  docs: [
    {
      type: "category",
      label: "Functional",
      items: [
        "user/overview",
        "user/install-and-run",
        "user/setup-and-sync",
        // "user/features",
        // "user/all-features",
        "user/troubleshooting",
        {
          type: "category",
          label: "User Manual",
          // Uncomment the line below if 'user/user-manual' is an actual Markdown file you want to link to when clicking the category title
          // link: { type: 'doc', id: 'user/user-manual' }, 
          items: [
            "user/user-manual/introduction",
            "user/user-manual/dashboard",
            "user/user-manual/kebab-menu",
            "user/user-manual/about-us",
            "user/user-manual/settings",
            "user/user-manual/projects",
            "user/user-manual/all-tasks",
            "user/user-manual/my-tasks",
            "user/user-manual/project-updates",
            "user/user-manual/activities",
            "user/user-manual/timesheets"
          ],
        }
      ]
    },
  

    {
      type: "category",
      label: "Technical",
      items: [
        "technical/architecture",
        "technical/repository-organization",
        {
          type: "category",
          label: "Module Implementations",
          items: [
            "technical/activities",
            "technical/projects",
            "technical/tasks",
            "technical/timesheets",
            "technical/dashboard",
            "technical/sync-settings",
            "technical/ui-ux-navigation",
            "technical/notifications",
            "technical/onboarding",
            "technical/profiles"
          ]
        },
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
        "contributing/documentation-governance",
        "contributing/documentation-guide",
        "contributing/translation-guide"
      ]
    }
  ]
};

module.exports = sidebars;
