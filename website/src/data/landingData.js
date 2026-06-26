export const features = [
  {
    icon: "⏱",
    title: "Timesheet Recording",
    description:
      "Log hours, track work entries, and maintain clear records across projects and activities.",
    tag: "Core"
  },
  {
    icon: "☑",
    title: "Task Management",
    description:
      "Organize tasks by project, track progress through stages, and manage work from a single view.",
    tag: "Core"
  },
  {
    icon: "📊",
    title: "Dashboard & Charts",
    description:
      "Visual summaries, project timelines, and charts that show where time is actually going.",
    tag: "Analytics"
  },
  {
    icon: "🔄",
    title: "Odoo Sync",
    description:
      "Background daemon syncs with Odoo instances — local data and remote systems stay aligned.",
    tag: "Integration"
  },
  {
    icon: "📱",
    title: "Ubuntu Touch & Desktop",
    description:
      "Convergent design for phones and desktops. One codebase, two form factors.",
    tag: "Platform"
  },
  {
    icon: "🔔",
    title: "Live Notifications",
    description:
      "System-level alerts for project updates, task changes, and sync events.",
    tag: "UX"
  }
];

export const techStack = [
  {
    layer: "Interface",
    tech: "QML",
    description:
      "Application UI, pages, shared components, and user interaction layer.",
    path: "qml/"
  },
  {
    layer: "Logic",
    tech: "JavaScript",
    description:
      "Shared state, data models, and cross-feature helper modules.",
    path: "models/"
  },
  {
    layer: "Services",
    tech: "Python",
    description:
      "Backend bridging, daemon process, sync routines, and system integration.",
    path: "src/"
  }
];

export const docPaths = [
  {
    audience: "Users",
    description:
      "Installation, setup, sync configuration, and troubleshooting guides.",
    link: "/docs/user/overview",
    cta: "User Docs",
    pages: ["Overview", "Install & Run", "Setup & Sync", "Features", "Troubleshooting"]
  },
  {
    audience: "Contributors",
    description:
      "PR workflow, local development setup, and documentation governance.",
    link: "/docs/contributing/getting-started",
    cta: "Contributing Guide",
    pages: ["Getting Started", "PR Guidelines", "Doc Governance"]
  },
  {
    audience: "Maintainers",
    description:
      "Architecture decisions, repository layout, build system, and release process.",
    link: "/docs/technical/architecture",
    cta: "Technical Docs",
    pages: ["Architecture", "Repo Organization", "Build & Packaging", "Release Process"]
  }
];
