const sidebars = {
  docs: [
    {
      type: "category",
      label: "Functional",
      items: [
        "user/overview",
        "user/install-and-run",
        "user/setup-and-sync",
        "user/features",
        "user/all-features",
        "user/troubleshooting"
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
        "contributing/documentation-governance"
      ]
    }
  ]
};

module.exports = sidebars;
