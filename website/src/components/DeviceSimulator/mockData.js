export const menuItems = [
  { name: "Dashboard", icon: "🏠", target: "Dashboard" },
  { name: "Timesheet", icon: "⏱", target: "Timesheets" },
  { name: "Activities", icon: "📅", target: "Activities" },
  { name: "My Tasks", icon: "⭐", target: "My Tasks" },
  { name: "All Tasks", icon: "☑", target: "All Tasks" },
  { name: "Projects", icon: "📁", target: "Projects" },
  { name: "Project Updates", icon: "🕒", target: "Project Updates" },
  { name: "About Us", icon: "ℹ", target: "About Us" },
  { name: "Settings", icon: "⚙", target: "Settings" }
];

export const projectsData = [
  { name: "Project Alpha - Phase 1", time: "4507.0 h", percent: 92, color: "#e07a24", tasks: 6 },
  { name: "Core Productivity Suite", time: "2187.6 h", percent: 75, color: "#e53935", tasks: 124 },
  { name: "Database Migration v18", time: "1240.0 h", percent: 55, color: "#1e88e5", tasks: 28 },
  { name: "Mobile Client App", time: "680.0 h", percent: 40, color: "#43a047", tasks: 15 },
  { name: "Collaborative Editor", time: "420.0 h", percent: 28, color: "#ffb300", tasks: 10 },
  { name: "OS Platform Layer", time: "280.0 h", percent: 18, color: "#00acc1", tasks: 8 },
  { name: "Technical Support Queue", time: "230.0 h", percent: 12, color: "#8e24aa", tasks: 5 },
  { name: "API Documentation", time: "150.0 h", percent: 8, color: "#d81b60", tasks: 2 }
];

export const timesheetsData = [
  {
    title: "test timesheet this thing this...",
    project: "Project Alpha / Child A (Demo)",
    task: "User manual",
    author: "Alex Mercer",
    hours: "5:00 H",
    date: "2026-04-24",
    action: "Do",
    borderColor: "#e07a24"
  },
  {
    title: "Test",
    project: "Project Alpha / Child A (Demo)",
    task: "This is a Notification Test.",
    author: "Sarah Connor",
    hours: "4500:00 H",
    date: "2026-05-05",
    action: "Unknown",
    borderColor: "#999999"
  },
  {
    title: "sub taSK 2 TIMESHEETY",
    project: "Project Alpha / Child A (Demo)",
    task: "HR Bundle",
    author: "Sarah Connor",
    hours: "2:00 H",
    date: "2026-04-24",
    action: "Unknown",
    borderColor: "#e07a24"
  },
  {
    title: "test",
    project: "Mobile Client App / Email module (Demo)",
    task: "Coordination",
    author: "Sarah Connor",
    hours: "3:00 H",
    date: "2026-04-24",
    action: "Unknown",
    borderColor: "#e07a24"
  },
  {
    title: "Time Off (1/1)",
    project: "Internal (Demo)",
    task: "Time Off",
    author: "Alex Mercer",
    hours: "8:00 H",
    date: "2026-05-01",
    action: "Unknown",
    borderColor: "#999999"
  },
  {
    title: "Time Off (1/1)",
    project: "Internal (Demo)",
    task: "Time Off",
    author: "David Miller",
    hours: "8:00 H",
    date: "2026-05-01",
    action: "Unknown",
    borderColor: "#999999"
  }
];

export const tasksData = [
  {
    title: "[Req] Content hub",
    project: "Core Productivity Suite",
    stage: "Analysis",
    stars: [false, false, false],
    planned: "N/A",
    start: "2025-08-08",
    end: "2025-08-22",
    overdue: "299 days overdue"
  },
  {
    title: "[IMP - Weblates improvements]",
    project: "Core Productivity Suite",
    stage: "Analysis",
    stars: [true, false, false],
    planned: "N/A",
    start: "2025-11-17",
    end: "2026-01-16",
    overdue: "152 days overdue"
  },
  {
    title: "Activity Retention",
    project: "Core Productivity Suite",
    stage: "Design",
    stars: [false, false, false],
    planned: "N/A",
    start: "2026-01-20",
    end: "Not set",
    overdue: null
  },
  {
    title: "Parent task",
    project: "Project Alpha - Phase 1",
    stage: "Analysis",
    stars: [false, false, false],
    planned: "N/A",
    start: "2026-04-24",
    end: "2026-06-08",
    overdue: "9 days overdue",
    locked: true,
    hasTasks: true,
    borderColor: "#e07a24"
  },
  {
    title: "UI Improvements And Bug Fixes",
    project: "Core Productivity Suite",
    stage: "Development",
    stars: [false, false, false],
    planned: "N/A",
    start: "2026-01-21",
    end: "Not set",
    overdue: null,
    borderColor: "#999999"
  }
];

export const allTasksData = [
  {
    title: "Design app launch icon",
    project: "Mobile App Core",
    stage: "Completed",
    stars: [true, true, true],
    planned: "8.0 H",
    start: "2026-06-01",
    end: "2026-06-03",
    overdue: null,
    status: "complete",
    borderColor: "#43a047"
  },
  {
    title: "Implement Docusaurus Search Option",
    project: "Docs Integration",
    stage: "Active",
    stars: [true, true, false],
    planned: "12.0 H",
    start: "2026-06-10",
    end: "2026-06-15",
    overdue: "2 days overdue",
    status: "active",
    borderColor: "#1e88e5"
  },
  {
    title: "Refactor navigation drawer layout",
    project: "QML Layout Refactoring",
    stage: "Draft",
    stars: [true, false, false],
    planned: "4.0 H",
    start: "2026-06-15",
    end: "Not set",
    overdue: null,
    status: "draft",
    borderColor: "#e07a24"
  },
  {
    title: "Write unit tests for Timesheet model",
    project: "Mobile App Core",
    stage: "Active",
    stars: [true, true, true],
    planned: "16.0 H",
    start: "2026-06-11",
    end: "2026-06-18",
    overdue: null,
    status: "active",
    borderColor: "#43a047"
  }
];

export const projectUpdatesData = [
  {
    title: "New Project Update.",
    author: "Alex Mercer",
    date: "2026-06-04",
    project: "25-00005 - Mobile Client App",
    status: "on_track",
    completion: 40
  },
  {
    title: "New Update.",
    author: "Alex Mercer",
    date: "2026-05-14",
    project: "25-00005 - Mobile Client App",
    status: "at_risk",
    completion: 90
  },
  {
    title: "project update edit after notificat...",
    author: "Alex Mercer",
    date: "2026-04-28",
    project: "Project Alpha - Phase 1...",
    status: "at_risk",
    completion: 15
  },
  {
    title: "project update edit after notificat...",
    author: "Alex Mercer",
    date: "2026-04-27",
    project: "Project Alpha - Phase 1...",
    status: "on_hold",
    completion: 30
  },
  {
    title: "New project Update",
    author: "Alex Mercer",
    date: "2026-04-27",
    project: "Project Alpha - Phase 1...",
    status: "on_track",
    completion: 10
  }
];

export const activitiesData = [
  {
    title: "Activity test for Al...",
    notes: "No Notes",
    assigned: "Assigned to: Alex Mercer",
    type: "To Do",
    date: "08 May",
    status: "overdue",
    iconType: "ellipsis",
    hasDraft: true
  },
  {
    title: "This is a Activity- ...",
    notes: "Hello World.",
    assigned: "Assigned to: Alex Mercer",
    type: "Meeting",
    date: "14 May",
    status: "overdue",
    iconType: "meeting",
    hasDraft: false
  },
  {
    title: "Activity assigned to...",
    notes: "No Notes",
    assigned: "Assigned to: Alex Mercer",
    type: "Call",
    date: "17 May",
    status: "overdue",
    iconType: "call",
    hasDraft: false
  },
  {
    title: "New Activity",
    notes: "Hello World.",
    assigned: "Assigned to: Alex Mercer",
    type: "Call",
    date: "18 Jun",
    status: "today",
    iconType: "call",
    hasDraft: false
  }
];
