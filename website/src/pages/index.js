import clsx from "clsx";
import Layout from "@theme/Layout";
import Link from "@docusaurus/Link";
import { useEffect, useRef, useState } from "react";
import styles from "./index.module.css";

const features = [
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

const techStack = [
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

const docPaths = [
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

function useScrollReveal() {
  const ref = useRef(null);

  useEffect(() => {
    const prefersReduced = window.matchMedia(
      "(prefers-reduced-motion: reduce)"
    ).matches;
    if (prefersReduced) {
      ref.current
        ?.querySelectorAll("[data-reveal]")
        .forEach((el) => el.setAttribute("data-visible", "true"));
      return;
    }

    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            entry.target.setAttribute("data-visible", "true");
            observer.unobserve(entry.target);
          }
        });
      },
      { threshold: 0.08, rootMargin: "0px 0px -40px 0px" }
    );

    ref.current
      ?.querySelectorAll("[data-reveal]")
      .forEach((el) => observer.observe(el));

    return () => observer.disconnect();
  }, []);

  return ref;
}

function TerminalPreview() {
  const [copied, setCopied] = useState(false);

  const handleCopy = () => {
    const textToCopy = "git clone https://github.com/CITOpenRep/timemanagement.git\ncd timemanagement\nclickable build && clickable install";
    navigator.clipboard.writeText(textToCopy).then(() => {
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    });
  };

  return (
    <div className={styles.terminal}>
      <div className={styles.terminalBar}>
        <div className={styles.terminalDots}>
          <span className={styles.terminalDot} />
          <span className={styles.terminalDot} />
          <span className={styles.terminalDot} />
        </div>
        <button 
          className={styles.copyButton}
          onClick={handleCopy}
          aria-label="Copy code to clipboard"
        >
          {copied ? "Copied!" : "Copy"}
        </button>
      </div>
      <pre className={styles.terminalCode}>
        <span className={styles.terminalPrompt}>$ </span>
        <span className={styles.terminalCmd}>git clone https://github.com/CITOpenRep/timemanagement.git</span>
        {"\n"}
        <span className={styles.terminalPrompt}>$ </span>
        <span className={styles.terminalCmd}>cd timemanagement</span>
        {"\n"}
        <span className={styles.terminalPrompt}>$ </span>
        <span className={styles.terminalCmd}>clickable build && clickable install</span>
      </pre>
    </div>
  );
}

function DeviceSimulator() {
  const [orientation, setOrientation] = useState("portrait");
  const [menuOpen, setMenuOpen] = useState(false);
  const [activeScreen, setActiveScreen] = useState("Dashboard");
  const [searchQuery, setSearchQuery] = useState("");
  const [filterType, setFilterType] = useState("most-time");
  const [themeMode, setThemeMode] = useState("dark"); // Default dark mode to match the visual screenshots

  const menuItems = [
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

  const projectsData = [
    { name: "Child project of main instance nnmhbbnnn kkkk", time: "4507.0 h", percent: 92, color: "#e07a24", tasks: 6 },
    { name: "UT time management", time: "2187.6 h", percent: 75, color: "#e53935", tasks: 124 },
    { name: "CURQ migration v18", time: "1240.0 h", percent: 55, color: "#1e88e5", tasks: 28 },
    { name: "UT App Development", time: "680.0 h", percent: 40, color: "#43a047", tasks: 15 },
    { name: "Notes App Development", time: "420.0 h", percent: 28, color: "#ffb300", tasks: 10 },
    { name: "Ubuntu Touch Development- Level 1", time: "280.0 h", percent: 18, color: "#00acc1", tasks: 8 },
    { name: "CURQ- Support", time: "230.0 h", percent: 12, color: "#8e24aa", tasks: 5 },
    { name: "CURQ documentation", time: "150.0 h", percent: 8, color: "#d81b60", tasks: 2 }
  ];

  const timesheetsData = [
    {
      title: "test timesheet this thing this...",
      project: "Main Parent Project / Child pr... (testCit)",
      task: "User manual",
      author: "Suraj Yadav",
      hours: "5:00 H",
      date: "2026-04-24",
      action: "Do",
      borderColor: "#e07a24"
    },
    {
      title: "Test",
      project: "Main Parent Project / Child pr... (testCit)",
      task: "This is a Notification Test.",
      author: "Parvathy",
      hours: "4500:00 H",
      date: "2026-05-05",
      action: "Unknown",
      borderColor: "#999999"
    },
    {
      title: "sub taSK 2 TIMESHEETY",
      project: "Main Parent Project / Child pr... (testCit)",
      task: "HR Bundle",
      author: "Parvathy",
      hours: "2:00 H",
      date: "2026-04-24",
      action: "Unknown",
      borderColor: "#e07a24"
    },
    {
      title: "test",
      project: "UT App Development / Dekko App... (testCit)",
      task: "Coordination",
      author: "Parvathy",
      hours: "3:00 H",
      date: "2026-04-24",
      action: "Unknown",
      borderColor: "#e07a24"
    },
    {
      title: "Time Off (1/1)",
      project: "Internal (testCit)",
      task: "Time Off",
      author: "Suraj Yadav",
      hours: "8:00 H",
      date: "2026-05-01",
      action: "Unknown",
      borderColor: "#999999"
    },
    {
      title: "Time Off (1/1)",
      project: "Internal (testCit)",
      task: "Time Off",
      author: "Anusha PP",
      hours: "8:00 H",
      date: "2026-05-01",
      action: "Unknown",
      borderColor: "#999999"
    }
  ];

  const tasksData = [
    {
      title: "[Req] Content hub",
      project: "UT time management",
      stage: "Analysis",
      stars: [false, false, false],
      planned: "N/A",
      start: "2025-08-08",
      end: "2025-08-22",
      overdue: "299 days overdue"
    },
    {
      title: "[IMP - Weblates improvements]",
      project: "UT time management",
      stage: "Analysis",
      stars: [true, false, false],
      planned: "N/A",
      start: "2025-11-17",
      end: "2026-01-16",
      overdue: "152 days overdue"
    },
    {
      title: "Activity Retention",
      project: "UT time management",
      stage: "Design",
      stars: [false, false, false],
      planned: "N/A",
      start: "2026-01-20",
      end: "Not set",
      overdue: null
    },
    {
      title: "Parent task",
      project: "Child project of",
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
      project: "UT time management",
      stage: "Development",
      stars: [false, false, false],
      planned: "N/A",
      start: "2026-01-21",
      end: "Not set",
      overdue: null,
      borderColor: "#999999"
    }
  ];

  const allTasksData = [
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

  const projectUpdatesData = [
    {
      log: "Suraj Yadav logged 3:30 H on 'QML Layout Refactoring' (Task: Fix layout spacing)",
      time: "2 hours ago"
    },
    {
      log: "Parvathy Yadav updated status of 'Website Redesign' to Active",
      time: "5 hours ago"
    },
    {
      log: "Automated Sync completed: 42 tasks synchronized with server",
      time: "Yesterday"
    },
    {
      log: "Anisha PP created new task 'Add search filter' in 'Mobile App Core'",
      time: "2 days ago"
    },
    {
      log: "System database backup successfully created: 1.24 MB",
      time: "3 days ago"
    }
  ];

  const activitiesData = [
    {
      title: "Activity test for sU...",
      notes: "No Notes",
      assigned: "Assigned to: Suraj Yadav",
      type: "To Do",
      date: "08 May",
      status: "overdue",
      iconType: "ellipsis",
      hasDraft: true
    },
    {
      title: "This is a Activity- ...",
      notes: "Hello World.",
      assigned: "Assigned to: Suraj Yadav",
      type: "Meeting",
      date: "14 May",
      status: "overdue",
      iconType: "meeting",
      hasDraft: false
    },
    {
      title: "Activity assigned to...",
      notes: "No Notes",
      assigned: "Assigned to: Suraj Yadav",
      type: "Call",
      date: "17 May",
      status: "overdue",
      iconType: "call",
      hasDraft: false
    },
    {
      title: "New Activity",
      notes: "Hello World.",
      assigned: "Assigned to: Suraj Yadav",
      type: "Call",
      date: "18 Jun",
      status: "today",
      iconType: "call",
      hasDraft: false
    }
  ];

  const filteredProjects = projectsData.filter(p => 
    p.name.toLowerCase().includes(searchQuery.toLowerCase())
  );

  // Reusable Left Menu Content
  const renderMenuList = () => (
    <ul className={styles.menuListActual}>
      {menuItems.map((item) => (
        <li
          key={item.name}
          className={clsx(
            styles.menuItemActual,
            activeScreen === item.target && styles.menuItemActiveActual
          )}
          onClick={() => {
            setActiveScreen(item.target);
            setMenuOpen(false);
          }}
        >
          <span className={styles.menuItemIcon}>{item.icon}</span>
          <span>{item.name}</span>
        </li>
      ))}
    </ul>
  );

  // Reusable Eisenhower Matrix Content
  const renderDashboardMatrix = () => (
    <div className={styles.matrixSection}>
      <div className={styles.matrixTitle}>Time spent based on priorities</div>
      
      <div className={styles.matrixWrapper}>
        <div className={styles.matrixHeaderRow}>
          <div style={{ width: "24px" }} />
          <div className={styles.matrixColHeader}>URGENT</div>
          <div className={styles.matrixColHeader}>NOT URGENT</div>
        </div>

        <div className={styles.matrixBodyRow}>
          <div className={styles.matrixRowHeader}>
            <span>IMPORTANT</span>
          </div>
          
          <div className={clsx(styles.matrixCard, styles.matrixCardUrgentImportant)}>
            <div className={styles.matrixCardIcon}>✓</div>
            <div className={styles.matrixCardLabel}>Do First</div>
            <div className={styles.matrixCardValue}>{themeMode === "dark" ? "100H" : "9521H"}</div>
          </div>

          <div className={clsx(styles.matrixCard, styles.matrixCardNoturgentImportant)}>
            <div className={styles.matrixCardIcon}>🕒</div>
            <div className={styles.matrixCardLabel}>Do Next</div>
            <div className={styles.matrixCardValue}>0H</div>
          </div>
        </div>

        <div className={styles.matrixBodyRow}>
          <div className={styles.matrixRowHeader}>
            <span>NOT IMPORTANT</span>
          </div>
          
          <div className={clsx(styles.matrixCard, styles.matrixCardUrgentNotimportant)}>
            <div className={styles.matrixCardIcon}>⏱</div>
            <div className={styles.matrixCardLabel}>Do Later</div>
            <div className={styles.matrixCardValue}>0H</div>
          </div>

          <div className={clsx(styles.matrixCard, styles.matrixCardNoturgentNotimportant)}>
            <div className={styles.matrixCardIcon}>🗑</div>
            <div className={styles.matrixCardLabel}>Don't do</div>
            <div className={styles.matrixCardValue}>{themeMode === "dark" ? "0H" : "13H"}</div>
          </div>
        </div>
      </div>
    </div>
  );

  // Reusable Project Overview Pie & Bar Chart Content
  const renderProjectOverview = () => (
    <>
      <div className={styles.tabBarActual}>
        <button className={clsx(styles.tabBtnActual, styles.tabBtnActiveActual)}>
          Overview
        </button>
        <button className={styles.tabBtnActual}>
          Projects
        </button>
        <button className={styles.tabBtnActual}>
          Tasks
        </button>
      </div>

      <div className={styles.chartHeading}>Most Time-Consuming Projects</div>
      
      <div className={styles.pieChartContainer}>
        <svg className={styles.pieChartSvg} viewBox="0 0 100 100">
          <circle cx="50" cy="50" r="35" fill="none" stroke="#eeeeee" strokeWidth="12" />
          
          {/* Segment 1: Orange (Child Project) */}
          <circle cx="50" cy="50" r="35" fill="none" className={styles.pieSlice} 
                  stroke="#e07a24" strokeWidth="12"
                  strokeDasharray="105.6 220" strokeDashoffset="0" />
          
          {/* Segment 2: Red (UT TimeManagement) */}
          <circle cx="50" cy="50" r="35" fill="none" className={styles.pieSlice} 
                  stroke="#e53935" strokeWidth="12"
                  strokeDasharray="50.6 220" strokeDashoffset="-105.6" />
          
          {/* Segment 3: Blue (CURQ Migration) */}
          <circle cx="50" cy="50" r="35" fill="none" className={styles.pieSlice} 
                  stroke="#1e88e5" strokeWidth="12"
                  strokeDasharray="28.6 220" strokeDashoffset="-156.2" />
          
          {/* Segment 4: Green (UT App Dev) */}
          <circle cx="50" cy="50" r="35" fill="none" className={styles.pieSlice} 
                  stroke="#43a047" strokeWidth="12"
                  strokeDasharray="15.4 220" strokeDashoffset="-184.8" />

          {/* Segment 5: Cyan (Notes App Dev) */}
          <circle cx="50" cy="50" r="35" fill="none" className={styles.pieSlice} 
                  stroke="#00acc1" strokeWidth="12"
                  strokeDasharray="19.8 220" strokeDashoffset="-200.2" />
                  
          <circle cx="50" cy="50" r="22" fill={themeMode === "dark" ? "#151515" : "#ffffff"} />
        </svg>
      </div>
      
      <div style={{ textAlign: "center", paddingBottom: "16px" }}>
        <button style={{ background: "transparent", border: "none", fontSize: "0.85rem", cursor: "pointer", color: "#666" }}>
          ▲
        </button>
      </div>
    </>
  );

  // Render Timesheets List Screen
  const renderTimesheetsList = () => (
    <div className={styles.timesheetListContainer}>
      <div className={styles.tabBarActual}>
        <button className={clsx(styles.tabBtnActual, styles.tabBtnActiveActual)}>All</button>
        <button className={styles.tabBtnActual}>Active</button>
        <button className={styles.tabBtnActual}>Draft</button>
      </div>

      {timesheetsData.map((t, idx) => (
        <div key={idx} className={styles.timesheetListItem}>
          <div className={styles.timesheetLeftBorder} style={{ backgroundColor: t.borderColor }} />
          <div className={styles.timesheetMainInfo}>
            <h4 className={styles.timesheetTitleText}>{t.title}</h4>
            <span className={styles.timesheetSubtext}>{t.project}</span>
            <span className={styles.timesheetSubtext}>{t.task}</span>
            <span className={styles.timesheetSubtext} style={{ fontSize: "0.62rem" }}>{t.author}</span>
          </div>
          <div className={styles.timesheetRightInfo}>
            <span className={styles.timesheetHours}>{t.hours}</span>
            <span className={styles.timesheetDate}>{t.date}</span>
            <span className={styles.timesheetActionLink}>{t.action}</span>
          </div>
        </div>
      ))}
    </div>
  );

  // Render My Tasks Screen
  const renderMyTasksList = () => (
    <div className={styles.timesheetListContainer}>
      <div className={styles.tabBarActual}>
        <button className={clsx(styles.tabBtnActual, styles.tabBtnActiveActual)}>Inbox</button>
        <button className={styles.tabBtnActual}>Today</button>
        <button className={styles.tabBtnActual}>This Week</button>
        <button className={styles.tabBtnActual}>This Month</button>
      </div>

      <div className={styles.taskListContainer}>
        {tasksData.map((task, idx) => (
          <div key={idx} className={styles.taskListItemCardActual}>
            {task.borderColor && (
              <div className={styles.timesheetLeftBorder} style={{ backgroundColor: task.borderColor }} />
            )}
            <div className={styles.taskItemLeftCol}>
              <h4 className={styles.taskItemTitleActual}>{task.title}</h4>
              <span className={styles.taskItemSubProjectText}>
                {task.project} {task.locked && "🔒"}
              </span>
              <div className={styles.taskCardStarRowActual}>
                {task.stars.map((filled, sIdx) => (
                  <span key={sIdx} style={{ color: filled ? "#ffb300" : "#bbb" }}>
                    ★
                  </span>
                ))}
              </div>
              {task.hasTasks && (
                <span style={{ fontSize: "0.65rem", color: "#e07a24", fontWeight: 600 }}>[+1] Tasks</span>
              )}
              <span className={styles.taskItemStageBadge}>{task.stage}</span>
            </div>
            <div className={styles.taskItemRightCol}>
              <span>Planned (H): {task.planned}</span>
              <span>Start Date: {task.start}</span>
              <span>End Date: {task.end}</span>
              {task.overdue && (
                <span className={styles.taskOverdueBadgeActual}>{task.overdue}</span>
              )}
            </div>
          </div>
        ))}
      </div>
    </div>
  );

  // Render Timesheet Entry Form
  const renderTimesheetEntryForm = () => (
    <div className={styles.formContainerActual}>
      <div className={styles.formRowInput}>
        <span className={styles.formLabelSmall}>Account</span>
        <span className={styles.formValueMain}>{themeMode === "dark" ? "dem" : "testCit"}</span>
      </div>

      <div className={styles.formRowInput}>
        <span className={styles.formLabelSmall}>Project</span>
        <span className={styles.formValueMain}>
          {themeMode === "dark" ? '"Task-wise Time Allocation an...' : "Child project of"}
        </span>
      </div>

      <div className={styles.formRowInput}>
        <span className={styles.formLabelSmall}>Subproject</span>
        <span className={styles.formValueMain} style={{ fontWeight: 400, color: "#888" }}>Tap to select</span>
      </div>

      <div className={styles.formRowInput}>
        <span className={styles.formLabelSmall}>Task</span>
        <span className={styles.formValueMain}>{themeMode === "dark" ? "111Ojne" : "sub task1"}</span>
      </div>

      <div className={styles.formRowInput}>
        <span className={styles.formLabelSmall}>Subtask</span>
        <span className={styles.formValueMain} style={{ fontWeight: 400, color: "#888" }}>Tap to select</span>
      </div>

      <div className={styles.prioritySectionTitle}>
        <span>Priority</span>
        <span style={{ fontSize: "0.8rem", color: "#888", cursor: "pointer" }}>ⓘ</span>
      </div>

      <div className={styles.priorityRadioGrid}>
        <div className={styles.radioOption}>
          <div className={clsx(styles.radioCircle, styles.radioCircleActive)}>
            <div className={styles.radioCircleActiveInner} />
          </div>
          <span>Important, Urgent (1)</span>
        </div>
        <div className={styles.radioOption}>
          <div className={styles.radioCircle} />
          <span>Important, Not Urgent (2)</span>
        </div>
        <div className={styles.radioOption}>
          <div className={styles.radioCircle} />
          <span>Urgent, Not Important (3)</span>
        </div>
        <div className={styles.radioOption}>
          <div className={styles.radioCircle} />
          <span>Not Urgent, Not Important (4)</span>
        </div>
      </div>

      <div className={styles.prioritySectionTitle} style={{ marginTop: 4 }}>
        <span>Time Tracking</span>
      </div>

      <div style={{ display: "flex", gap: "20px", fontSize: "0.78rem" }}>
        <div className={styles.radioOption}>
          <div className={clsx(styles.radioCircle, styles.radioCircleActive)}>
            <div className={styles.radioCircleActiveInner} />
          </div>
          <span>Manual</span>
        </div>
        <div className={styles.radioOption}>
          <div className={styles.radioCircle} />
          <span>Automated</span>
        </div>
      </div>

      <div className={styles.trackingRowActual}>
        <button className={styles.cyanDurationBtn}>
          {themeMode === "dark" ? "5:04" : "5:00"}
        </button>
      </div>

      <div className={styles.dateRowActual}>
        <span>Date</span>
        {themeMode === "dark" ? (
          <span style={{ fontWeight: 600 }}>10-03-2026</span>
        ) : (
          <select className={styles.dateSelectBox} defaultValue="24-04-2026">
            <option value="Today">Today</option>
            <option value="24-04-2026">24-04-2026</option>
          </select>
        )}
      </div>

      <div className={styles.descContainerActual}>
        <span style={{ fontSize: "0.8rem", fontWeight: 600 }}>Description</span>
        <div className={styles.descTextareaWrapper}>
          <textarea 
            className={styles.descTextareaActual} 
            readOnly
            value={themeMode === "dark" 
              ? "hello world, The background sybc works."
              : "test timesheet this thing this new version of voice to text feature moments voice to text feature is working as expected"
            }
          />
          <div className={styles.descTextareaButtons}>
            <button className={styles.descMicroBtn} title="Voice Input">🎤</button>
            <button className={styles.descMicroBtn} title="Expand">⤢</button>
          </div>
        </div>
      </div>
    </div>
  );

  // Render Projects List
  const renderProjectsList = () => (
    <div className={styles.timesheetListContainer}>
      <div style={{ padding: "12px 14px", display: "flex", flexDirection: "column", gap: "10px" }}>
        {projectsData.map((project, idx) => (
          <div key={idx} style={{ 
            padding: "12px", 
            background: themeMode === "dark" ? "#222222" : "#ffffff", 
            borderRadius: "6px",
            border: themeMode === "dark" ? "1px solid #333333" : "1px solid #e0e0e0",
            display: "flex",
            flexDirection: "column",
            gap: "8px"
          }}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", gap: "8px" }}>
              <h4 style={{ margin: 0, fontSize: "0.82rem", fontWeight: "700" }}>{project.name}</h4>
              <span className={styles.taskItemStageBadge} style={{ background: project.color, color: "#ffffff", padding: "2px 6px" }}>
                {project.tasks} Tasks
              </span>
            </div>
            
            <div style={{ display: "flex", justifyContent: "space-between", fontSize: "0.68rem", color: "#888888" }}>
              <span>Total Logged: <strong>{project.time}</strong></span>
              <span>{project.percent}%</span>
            </div>

            {/* Simulated Progress Bar */}
            <div style={{ height: "4px", background: themeMode === "dark" ? "#151515" : "#f0f0f0", borderRadius: "2px", overflow: "hidden" }}>
              <div style={{ height: "100%", width: `${project.percent}%`, background: project.color }} />
            </div>
          </div>
        ))}
      </div>
    </div>
  );

  // Render Project Updates
  const renderProjectUpdates = () => (
    <div className={styles.logListContainer}>
      {projectUpdatesData.map((log, idx) => (
        <div key={idx} className={styles.logItem}>
          <div className={styles.logDot} />
          <div className={styles.logContent}>
            <p className={styles.logTitle}>{log.log}</p>
            <span className={styles.logTime}>{log.time}</span>
          </div>
        </div>
      ))}
    </div>
  );

  // Render Activities
  const renderActivitiesList = () => (
    <div style={{ display: "flex", flexDirection: "column", height: "100%" }}>
      {/* Tab Bar sticky */}
      <div className={styles.utTabBar}>
        <div className={clsx(styles.utTabBtn, styles.utTabBtnActive)}>
          Today
          <div className={styles.utTabIndicator} />
        </div>
        <div className={styles.utTabBtn}>This Week</div>
        <div className={styles.utTabBtn}>This Month</div>
        <div className={styles.utTabBtn}>Later</div>
      </div>

      {/* Activity Card list */}
      <div className={styles.logListContainer}>
        {activitiesData.map((act, idx) => (
          <div key={idx} className={styles.utActivityCard}>
            {/* Left border strip */}
            <div className={styles.utActivityAccentStrip} />

            {/* Left circular icon */}
            <div className={styles.utActivityIconCircle}>
              {act.iconType === "ellipsis" && (
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#ffffff" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round">
                  <circle cx="12" cy="12" r="1" />
                  <circle cx="19" cy="12" r="1" />
                  <circle cx="5" cy="12" r="1" />
                </svg>
              )}
              {act.iconType === "meeting" && (
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#ffffff" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                  <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" />
                  <circle cx="9" cy="7" r="4" />
                  <path d="M23 21v-2a4 4 0 0 0-3-3.87" />
                  <path d="M16 3.13a4 4 0 0 1 0 7.75" />
                </svg>
              )}
              {act.iconType === "call" && (
                <svg width="18" height="18" viewBox="0 0 24 24" fill="#ffffff" stroke="none">
                  <path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 22 16.92z" />
                </svg>
              )}
            </div>

            {/* Middle description col */}
            <div className={styles.utActivityMainContent}>
              <h4 className={styles.utActivityTitle}>{act.title}</h4>
              <p className={styles.utActivityNotes}>{act.notes}</p>
              <p className={styles.utActivityAssigned}>{act.assigned}</p>
              {act.hasDraft && (
                <span className={styles.utActivityDraftBadge}>Draft</span>
              )}
            </div>

            {/* Right meta details col */}
            <div className={styles.utActivityRightCol}>
              <span className={styles.utActivityType}>{act.type}</span>
              <span className={styles.utActivityDate}>{act.date}</span>
              <span 
                className={styles.utActivityStatusBadge}
                style={{ backgroundColor: act.status === "overdue" ? "#ff5e5b" : "#ffa726" }}
              >
                {act.status}
              </span>
            </div>
          </div>
        ))}
      </div>
    </div>
  );

  // Render All Tasks List
  const renderAllTasksList = () => (
    <div className={styles.timesheetListContainer}>
      <div className={styles.tabBarActual}>
        <button className={clsx(styles.tabBtnActual, styles.tabBtnActiveActual)}>All</button>
        <button className={styles.tabBtnActual}>Active</button>
        <button className={styles.tabBtnActual}>Completed</button>
      </div>

      <div className={styles.taskListContainer}>
        {allTasksData.map((task, idx) => (
          <div key={idx} className={styles.taskListItemCardActual}>
            <div className={styles.timesheetLeftBorder} style={{ backgroundColor: task.borderColor }} />
            <div className={styles.taskItemLeftCol}>
              <div style={{ display: "flex", gap: "6px", alignItems: "center" }}>
                <span style={{ 
                  color: task.status === "complete" ? "#43a047" : "#888888", 
                  fontSize: "0.85rem",
                  fontWeight: "bold"
                }}>
                  {task.status === "complete" ? "☑" : "☐"}
                </span>
                <h4 className={styles.taskItemTitleActual} style={{
                  textDecoration: task.status === "complete" ? "line-through" : "none",
                  opacity: task.status === "complete" ? 0.6 : 1
                }}>
                  {task.title}
                </h4>
              </div>
              <span className={styles.taskItemSubProjectText}>
                {task.project}
              </span>
              <div className={styles.taskCardStarRowActual}>
                {task.stars.map((filled, sIdx) => (
                  <span key={sIdx} style={{ color: filled ? "#ffb300" : "#bbb" }}>
                    ★
                  </span>
                ))}
              </div>
              <span className={styles.taskItemStageBadge}>{task.stage}</span>
            </div>
            <div className={styles.taskItemRightCol}>
              <span>Planned: {task.planned}</span>
              <span>Start: {task.start}</span>
              <span>End: {task.end}</span>
              {task.overdue && (
                <span className={styles.taskOverdueBadgeActual}>{task.overdue}</span>
              )}
            </div>
          </div>
        ))}
      </div>
    </div>
  );

  // Render Settings Screen
  const renderSettingsScreen = () => (
    <div className={styles.utSettingsList}>
      <div className={styles.utSettingsRow}>
        <div className={styles.utSettingsIconWrapper}>
          <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#4a90e2" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
            <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" />
            <circle cx="9" cy="7" r="4" />
            <path d="M23 21v-2a4 4 0 0 0-3-3.87" />
            <path d="M16 3.13a4 4 0 0 1 0 7.75" />
          </svg>
        </div>
        <span className={styles.utSettingsLabel}>Connected Accounts</span>
        <span className={styles.utSettingsChevron}>›</span>
      </div>
      <div className={styles.utSettingsDivider} />

      <div className={styles.utSettingsRow}>
        <div className={styles.utSettingsIconWrapper}>
          <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#ff5e5b" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
            <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9" />
            <path d="M13.73 21a2 2 0 0 1-3.46 0" />
          </svg>
        </div>
        <span className={styles.utSettingsLabel}>Notifications</span>
        <span className={styles.utSettingsChevron}>›</span>
      </div>
      <div className={styles.utSettingsDivider} />

      <div className={styles.utSettingsRow}>
        <div className={styles.utSettingsIconWrapper}>
          <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#3cb371" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
            <path d="M18 10h-.01M17 10a5 5 0 0 0-9.13-2.58A6.5 6.5 0 0 0 8 20h10a5 5 0 0 0 0-10z" />
          </svg>
        </div>
        <span className={styles.utSettingsLabel}>Background Sync</span>
        <span className={styles.utSettingsChevron}>›</span>
      </div>
      <div className={styles.utSettingsDivider} />

      <div className={styles.utSettingsRow}>
        <div className={styles.utSettingsIconWrapper}>
          <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#666" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
            <rect x="3" y="3" width="18" height="18" rx="2" stroke="#cccccc" strokeWidth="1" />
            <path d="M3 5l8 9v7h2v-7l8-9" />
            <path d="M9 3l3 4 3-4" />
            <path d="M12 5.5l-1 1.5h2l-1-1.5z" fill="#e05a2b" stroke="#e05a2b" />
            <path d="M12 7l-1.5 3 1.5 2 1.5-2-1.5-3z" fill="#e05a2b" stroke="#e05a2b" />
          </svg>
        </div>
        <span className={styles.utSettingsLabel}>Theme Settings</span>
        <span className={styles.utSettingsChevron}>›</span>
      </div>
      <div className={styles.utSettingsDivider} />

      <div className={styles.utSettingsRow}>
        <div className={styles.utSettingsIconWrapper}>
          <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#9b5de5" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
            <path d="M12 1a3 3 0 0 0-3 3v8a3 3 0 0 0 6 0V4a3 3 0 0 0-3-3z" />
            <path d="M19 10v2a7 7 0 0 1-14 0v-2M12 19v4M8 23h8" />
          </svg>
        </div>
        <span className={styles.utSettingsLabel}>Voice Model Settings</span>
        <span className={styles.utSettingsChevron}>›</span>
      </div>
    </div>
  );

  // Render About Screen
  const renderAboutScreen = () => (
    <div className={styles.aboutContainer}>
      <div className={styles.aboutLogo}>⏱</div>
      <h3 className={styles.aboutAppName}>TimeManagement</h3>
      <div className={styles.aboutAppVersion}>Version 2.4.1 (GPL-3.0)</div>
      
      <div className={styles.aboutDivider} />
      
      <p className={styles.aboutText}>
        A convergent time tracking and task management application designed for Ubuntu Touch and Debian-based systems.
      </p>

      <div className={styles.aboutDivider} />

      <div className={styles.aboutSectionTitle}>Project Team</div>
      <div className={styles.aboutContributorList}>
        <div className={styles.aboutContributor}>• Suraj Yadav (Lead Developer)</div>
        <div className={styles.aboutContributor}>• Parvathy (Core Architect)</div>
        <div className={styles.aboutContributor}>• Anisha PP (UI/UX Designer)</div>
      </div>

      <div className={styles.aboutDivider} />

      <button className={styles.settingsButton} style={{ backgroundColor: "#43a047" }}>
        Check for Updates
      </button>
    </div>
  );

  return (
    <section className={styles.workbenchSection}>
      <div className="container">
        <div className={styles.workbenchGrid}>
          {/* Controls Panel */}
          <div className={styles.workbenchPanel} data-reveal>
            <p className={styles.sectionLabel}>Live Preview</p>
            <h2 className={styles.panelTitle}>Interactive Device Simulator</h2>
            <p className={styles.panelDesc}>
              Experience the actual TimeManagement user interface directly on an interactive Ubuntu Touch emulator.
            </p>
            
            <div className={styles.controlGroup}>
              <div>
                <span className={styles.controlLabel}>Device Form Factor</span>
                <div className={styles.toggleRow}>
                  <button 
                    className={clsx(styles.toggleBtn, orientation === "portrait" && styles.toggleBtnActive)}
                    onClick={() => setOrientation("portrait")}
                  >
                    📱 Mobile (Portrait)
                  </button>
                  <button 
                    className={clsx(styles.toggleBtn, orientation === "landscape" && styles.toggleBtnActive)}
                    onClick={() => setOrientation("landscape")}
                  >
                    💻 Convergent (Tablet/Desktop)
                  </button>
                </div>
              </div>

              <div>
                <span className={styles.controlLabel}>App Color Theme</span>
                <div className={styles.toggleRow}>
                  <button 
                    className={clsx(styles.toggleBtn, themeMode === "dark" && styles.toggleBtnActive)}
                    onClick={() => setThemeMode("dark")}
                  >
                    🌙 Dark Mode
                  </button>
                  <button 
                    className={clsx(styles.toggleBtn, themeMode === "light" && styles.toggleBtnActive)}
                    onClick={() => setThemeMode("light")}
                  >
                    ☀️ Light Mode
                  </button>
                </div>
              </div>

              <div>
                <span className={styles.controlLabel}>Quick Navigate</span>
                <div className={styles.toggleRow}>
                  <button 
                    className={clsx(styles.toggleBtn, activeScreen === "Dashboard" && styles.toggleBtnActive)}
                    onClick={() => setActiveScreen("Dashboard")}
                  >
                    🏠 Dashboard
                  </button>
                  <button 
                    className={clsx(styles.toggleBtn, activeScreen === "Timesheets" && styles.toggleBtnActive)}
                    onClick={() => setActiveScreen("Timesheets")}
                  >
                    ⏱ Timesheets
                  </button>
                </div>
                <div className={styles.toggleRow}>
                  <button 
                    className={clsx(styles.toggleBtn, activeScreen === "Timesheet" && styles.toggleBtnActive)}
                    onClick={() => setActiveScreen("Timesheet")}
                  >
                    📝 Entry Form
                  </button>
                  <button 
                    className={clsx(styles.toggleBtn, activeScreen === "My Tasks" && styles.toggleBtnActive)}
                    onClick={() => setActiveScreen("My Tasks")}
                  >
                    ⭐ Tasks
                  </button>
                </div>
                <div className={styles.toggleRow}>
                  <button 
                    className={clsx(styles.toggleBtn, activeScreen === "Projects" && styles.toggleBtnActive)}
                    onClick={() => setActiveScreen("Projects")}
                  >
                    📁 Projects
                  </button>
                  <button 
                    className={clsx(styles.toggleBtn, activeScreen === "Project Updates" && styles.toggleBtnActive)}
                    onClick={() => setActiveScreen("Project Updates")}
                  >
                    🕒 Updates
                  </button>
                </div>
                <div className={styles.toggleRow}>
                  <button 
                    className={clsx(styles.toggleBtn, activeScreen === "Settings" && styles.toggleBtnActive)}
                    onClick={() => setActiveScreen("Settings")}
                  >
                    ⚙ Settings
                  </button>
                  <button 
                    className={clsx(styles.toggleBtn, activeScreen === "About Us" && styles.toggleBtnActive)}
                    onClick={() => setActiveScreen("About Us")}
                  >
                    ℹ About Us
                  </button>
                </div>
              </div>
            </div>

            <div className={styles.gestureHint}>
              <span>💡</span>
              <p>Ubuntu Touch gesture: Hover or swipe from the <strong>left screen border</strong> to toggle the menu drawer, or tap the blue Floating Action Button (FAB).</p>
            </div>
          </div>

          {/* Interactive Phone */}
          <div className={styles.deviceCanvas} data-reveal style={{ "--reveal-delay": 1 }}>
            <div className={styles.deviceTurntable}>
              <div className={clsx(styles.deviceFrame, styles[orientation])}>
                
                {orientation === "portrait" ? (
                  /* ── PORTRAIT MOBILE VIEW ── */
                  <div className={clsx(styles.deviceScreen, themeMode === "dark" ? styles.themeDark : styles.themeLight)}>
                    {/* Swipe Hotspot */}
                    <div 
                      className={styles.leftEdgeSwipeBoundary} 
                      onMouseEnter={() => setMenuOpen(true)}
                    />

                    {/* Top Status Bar */}
                    <div className={styles.statusBarActual}>
                      <span>Ubuntu Touch</span>
                      <div style={{ display: "flex", gap: "6px" }}>
                        <span>📶</span>
                        <span>🔋 88%</span>
                        <span>{themeMode === "dark" ? "12:15 PM" : "5:31 PM"}</span>
                      </div>
                    </div>

                    {/* App Header */}
                    <header className={styles.appHeaderActual}>
                      {activeScreen === "Timesheet" ? (
                        <>
                          <button 
                            className={styles.headerIconBtn}
                            onClick={() => setActiveScreen("Timesheets")}
                          >
                            ⟨
                          </button>
                          <h3 className={styles.headerTitle}>Timesheet</h3>
                          <div className={styles.headerIcons}>
                            <button className={styles.headerIconBtn} title="Save">
                              {themeMode === "dark" ? "📝" : "✓"}
                            </button>
                          </div>
                        </>
                      ) : (
                        <>
                          <button 
                            className={styles.headerIconBtn}
                            onClick={() => setMenuOpen(!menuOpen)}
                          >
                            ☰
                          </button>
                          <h3 className={styles.headerTitle}>
                            {activeScreen === "Dashboard" && `Account [${themeMode === "dark" ? "dem" : "testCit"}]`}
                            {activeScreen === "Timesheets" && "Timesheets"}
                            {activeScreen === "My Tasks" && "My Tasks"}
                            {activeScreen !== "Dashboard" && activeScreen !== "Timesheets" && activeScreen !== "My Tasks" && activeScreen}
                          </h3>
                          <div className={styles.headerIcons}>
                            {activeScreen === "My Tasks" ? (
                              <>
                                <button className={styles.headerIconBtn} title="Sort">🎚</button>
                                <button className={styles.headerIconBtn} title="Help">ⓘ</button>
                                <button className={styles.headerIconBtn} title="Search">🔍</button>
                                <button className={styles.headerIconBtn} title="Grid">⚃</button>
                                <button 
                                  className={styles.headerIconBtn} 
                                  title="Add Task"
                                  onClick={() => setActiveScreen("Timesheet")}
                                >
                                  +
                                </button>
                              </>
                            ) : activeScreen === "Activities" ? (
                              <>
                                <button className={styles.headerIconBtn} title="Accounts">👥</button>
                                <button className={styles.headerIconBtn} title="Add Activity">+</button>
                                <button className={styles.headerIconBtn} title="Search">🔍</button>
                              </>
                            ) : (
                              <>
                                <button 
                                  className={styles.headerIconBtn} 
                                  title="Add Entry"
                                  onClick={() => setActiveScreen("Timesheet")}
                                >
                                  ⏱⁺
                                </button>
                                <button className={styles.headerIconBtn} title="Notifications">🔔</button>
                                <button className={styles.headerIconBtn} title="Info">ⓘ</button>
                              </>
                            )}
                          </div>
                        </>
                      )}
                    </header>

                    {/* Screen Scrollable Body */}
                    <div className={styles.pageScrollContent}>
                      {activeScreen === "Dashboard" && (
                        <>
                          {renderDashboardMatrix()}
                          {renderProjectOverview()}
                        </>
                      )}
                      {activeScreen === "Timesheets" && renderTimesheetsList()}
                      {activeScreen === "Timesheet" && renderTimesheetEntryForm()}
                      {activeScreen === "My Tasks" && renderMyTasksList()}
                      {activeScreen === "All Tasks" && renderAllTasksList()}
                      {activeScreen === "Projects" && renderProjectsList()}
                      {activeScreen === "Project Updates" && renderProjectUpdates()}
                      {activeScreen === "Activities" && renderActivitiesList()}
                      {activeScreen === "Settings" && renderSettingsScreen()}
                      {activeScreen === "About Us" && renderAboutScreen()}
                    </div>

                    {/* Floating Action Button (FAB) */}
                    <button 
                      className={styles.fabButtonActual}
                      onClick={() => {
                        if (activeScreen === "Timesheet") {
                          setActiveScreen("Timesheets");
                        } else {
                          setMenuOpen(!menuOpen);
                        }
                      }}
                    >
                      {activeScreen === "Timesheet" ? "⟨" : "☰"}
                    </button>

                    {/* Ubuntu Left Menu Drawer */}
                    <div className={clsx(styles.menuPanelActual, menuOpen && styles.menuPanelOpen)}>
                      <div className={styles.menuHeaderActual}>
                        <h4 className={styles.menuHeaderTitle}>Menu</h4>
                        <div className={styles.menuHeaderControls}>
                          <span style={{ fontSize: "1.1rem", cursor: "pointer" }}>👤</span>
                          <span 
                            style={{ fontSize: "1.1rem", cursor: "pointer" }}
                            onClick={() => setThemeMode(themeMode === "dark" ? "light" : "dark")}
                          >
                            {themeMode === "dark" ? "☀️" : "🌙"}
                          </span>
                        </div>
                      </div>
                      {renderMenuList()}
                    </div>

                    {/* Dimmed backdrop when Menu is open */}
                    <div 
                      className={clsx(styles.menuBackdrop, menuOpen && styles.menuBackdropVisible)}
                      onClick={() => setMenuOpen(false)}
                    />

                    {/* Bottom Home Indicator Gesture bar */}
                    <div 
                      className={styles.indicatorBarActual}
                      onClick={() => setActiveScreen("Dashboard")}
                    />
                  </div>
                ) : (
                  /* ── LANDSCAPE CONVERGENT VIEW ── */
                  <div className={clsx(styles.deviceScreen, themeMode === "dark" ? styles.themeDark : styles.themeLight)}>
                    {/* Top Status Bar */}
                    <div className={styles.statusBarActual}>
                      <span>Ubuntu Touch converged workspace</span>
                      <div style={{ display: "flex", gap: "6px" }}>
                        <span>📶</span>
                        <span>🔋 88%</span>
                        <span>{themeMode === "dark" ? "12:15 PM" : "5:31 PM"}</span>
                      </div>
                    </div>

                    <div className={styles.convergedGrid}>
                      {/* Column 1: Permanent Sidebar Menu */}
                      <aside className={styles.convergedSidebar}>
                        <div className={styles.menuHeaderActual}>
                          <h4 className={styles.menuHeaderTitle}>Menu</h4>
                          <div className={styles.menuHeaderControls}>
                            <span 
                              style={{ fontSize: "1rem", cursor: "pointer" }}
                              onClick={() => setThemeMode(themeMode === "dark" ? "light" : "dark")}
                            >
                              {themeMode === "dark" ? "☀️" : "🌙"}
                            </span>
                            <span style={{ fontSize: "1rem" }}>👤</span>
                          </div>
                        </div>
                        {renderMenuList()}
                      </aside>

                      {/* Column 2: Dashboard/Account Main View */}
                      <main className={styles.convergedCenter} style={{ background: "transparent" }}>
                        <header className={styles.appHeaderActual}>
                          <h3 className={styles.headerTitle}>
                            {activeScreen === "Dashboard" && `Account [${themeMode === "dark" ? "dem" : "testCit"}]`}
                            {activeScreen === "Timesheets" && "Timesheets"}
                            {activeScreen === "Timesheet" && "Timesheet"}
                            {activeScreen === "My Tasks" && "My Tasks"}
                            {activeScreen !== "Dashboard" && activeScreen !== "Timesheets" && activeScreen !== "Timesheet" && activeScreen !== "My Tasks" && activeScreen}
                          </h3>
                          <div className={styles.headerIcons}>
                            {activeScreen === "Timesheet" ? (
                              <button className={styles.headerIconBtn}>
                                {themeMode === "dark" ? "📝" : "✓"}
                              </button>
                            ) : activeScreen === "Activities" ? (
                              <>
                                <button className={styles.headerIconBtn} title="Accounts">👥</button>
                                <button className={styles.headerIconBtn} title="Add Activity">+</button>
                                <button className={styles.headerIconBtn} title="Search">🔍</button>
                              </>
                            ) : (
                              <>
                                <button 
                                  className={styles.headerIconBtn}
                                  onClick={() => setActiveScreen("Timesheet")}
                                >
                                  ⏱⁺
                                </button>
                                <button className={styles.headerIconBtn}>🔔</button>
                                <button className={styles.headerIconBtn}>ⓘ</button>
                              </>
                            )}
                          </div>
                        </header>
                        
                        <div className={styles.pageScrollContent}>
                          {activeScreen === "Dashboard" && (
                            <>
                              {renderDashboardMatrix()}
                              {renderProjectOverview()}
                            </>
                          )}
                          {activeScreen === "Timesheets" && renderTimesheetsList()}
                          {activeScreen === "Timesheet" && renderTimesheetEntryForm()}
                          {activeScreen === "My Tasks" && renderMyTasksList()}
                          {activeScreen === "All Tasks" && renderAllTasksList()}
                          {activeScreen === "Projects" && renderProjectsList()}
                          {activeScreen === "Project Updates" && renderProjectUpdates()}
                          {activeScreen === "Activities" && renderActivitiesList()}
                          {activeScreen === "Settings" && renderSettingsScreen()}
                          {activeScreen === "About Us" && renderAboutScreen()}
                        </div>
                        
                        <button 
                          className={styles.fabButtonActual}
                          onClick={() => setActiveScreen("Timesheet")}
                        >
                          ⏱⁺
                        </button>
                      </main>

                      {/* Column 3: Charts / Projects View */}
                      <section className={styles.convergedRight} style={{ background: themeMode === "dark" ? "#1e1e1e" : "#ffffff" }}>
                        <header className={styles.rightHeader}>
                          Charts
                        </header>
                        
                        <div className={styles.rightContent}>
                          <div className={styles.barChartTitle} style={{ color: themeMode === "dark" ? "#f0ebe0" : "#333333" }}>
                            Projectwise Time Spent
                          </div>
                          
                          <div className={styles.barChartContainer}>
                            {projectsData.map((p) => (
                              <div key={p.name} className={styles.barChartRow}>
                                <span 
                                  className={styles.barChartLabel} 
                                  title={p.name}
                                  style={{ color: themeMode === "dark" ? "#aaaaaa" : "#555555" }}
                                >
                                  {p.name}
                                </span>
                                <div className={styles.barChartValueWrapper}>
                                  <div className={styles.barChartBarBg} style={{ background: themeMode === "dark" ? "#333" : "#eee" }}>
                                    <div 
                                      className={styles.barChartBarFill} 
                                      style={{ width: `${p.percent}%`, backgroundColor: p.color }}
                                    />
                                  </div>
                                  <span 
                                    className={styles.barChartValText}
                                    style={{ color: themeMode === "dark" ? "#f0ebe0" : "#333333" }}
                                  >
                                    {p.time.split(" ")[0]}
                                  </span>
                                </div>
                              </div>
                            ))}
                          </div>

                          <button 
                            className={styles.showNextBtn}
                            style={{
                              background: themeMode === "dark" ? "#2a2a2a" : "#f5f5f5",
                              borderColor: themeMode === "dark" ? "#444" : "#e0e0e0",
                              color: themeMode === "dark" ? "#ccc" : "#666"
                            }}
                          >
                            Show next 10 ↓
                          </button>

                          <div className={styles.projectsSectionHeader} style={{ borderBottomColor: themeMode === "dark" ? "#444" : "#e0e0e0" }}>
                            <h4 
                              className={styles.projectsSectionTitle}
                              style={{ color: themeMode === "dark" ? "#f0ebe0" : "#333333" }}
                            >
                              Projects
                            </h4>
                            <span className={styles.projectsTotalBadge}>9490.0 h</span>
                          </div>

                          <input 
                            type="text" 
                            className={styles.projectSearchBox} 
                            placeholder="Search projects..." 
                            value={searchQuery}
                            onChange={(e) => setSearchQuery(e.target.value)}
                            style={{
                              background: themeMode === "dark" ? "#222" : "#fff",
                              borderColor: themeMode === "dark" ? "#444" : "#ccc",
                              color: themeMode === "dark" ? "#fff" : "#333"
                            }}
                          />

                          <div 
                            className={styles.projectFilterTabs}
                            style={{ background: themeMode === "dark" ? "#2a2a2a" : "#eeeeee" }}
                          >
                            <button 
                              className={clsx(styles.projectFilterBtn, filterType === "most-time" && styles.projectFilterBtnActive)}
                              onClick={() => setFilterType("most-time")}
                              style={{ color: themeMode === "dark" ? "#aaa" : "#666" }}
                            >
                              Most time
                            </button>
                            <button 
                              className={clsx(styles.projectFilterBtn, filterType === "tasks" && styles.projectFilterBtnActive)}
                              onClick={() => setFilterType("tasks")}
                              style={{ color: themeMode === "dark" ? "#aaa" : "#666" }}
                            >
                              Tasks
                            </button>
                            <button 
                              className={clsx(styles.projectFilterBtn, filterType === "a-z" && styles.projectFilterBtnActive)}
                              onClick={() => setFilterType("a-z")}
                              style={{ color: themeMode === "dark" ? "#aaa" : "#666" }}
                            >
                              A-Z
                            </button>
                          </div>

                          <div className={styles.projectListLandscape}>
                            {filteredProjects.map((p) => (
                              <div 
                                key={p.name} 
                                className={styles.projectListItemCard}
                                style={{
                                  background: themeMode === "dark" ? "#222" : "#fff",
                                  borderLeftColor: p.color
                                }}
                              >
                                <div className={styles.projectListItemHeader}>
                                  <h4 
                                    className={styles.projectListItemName}
                                    style={{ color: themeMode === "dark" ? "#f0ebe0" : "#333" }}
                                  >
                                    {p.name}
                                  </h4>
                                  <span className={styles.projectListItemTime} style={{ color: p.color }}>
                                    {p.time}
                                  </span>
                                </div>
                                <div className={styles.projectListItemTasks} style={{ color: themeMode === "dark" ? "#aaa" : "#777" }}>
                                  {p.tasks} tasks
                                </div>
                                <div className={styles.projectProgressBg} style={{ background: themeMode === "dark" ? "#333" : "#eee" }}>
                                  <div 
                                    className={styles.projectProgressBar}
                                    style={{ width: `${p.percent}%`, backgroundColor: p.color }}
                                  />
                                </div>
                              </div>
                            ))}
                          </div>
                        </div>
                      </section>
                    </div>

                    {/* Bottom indicator gesture bar */}
                    <div 
                      className={styles.indicatorBarActual}
                      onClick={() => setActiveScreen("Dashboard")}
                    />
                  </div>
                )}

              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}

export default function Home() {
  const mainRef = useScrollReveal();

  return (
    <Layout
      title="Product & Documentation Hub"
      description="TimeManagement — a practical time, task, and sync workspace for Ubuntu Touch and desktop. Open source, three-layer architecture, community-driven."
    >
      {/* ── HERO ── */}
      <header className={styles.hero}>
        <div className={styles.heroGlow} />
        <div className="container">
          <div className={styles.heroBadge}>
            Open Source · QML + JS + Python
          </div>

          <h1 className={styles.heroTitle}>
            Time
            <span className={styles.heroTitleAccent}>Management</span>
          </h1>

          <p className={styles.heroTagline}>
            A practical workspace for tracking time, managing tasks, and
            syncing with Odoo — built for Ubuntu Touch and desktop.
          </p>

          <div className={styles.heroCtas}>
            <Link className={styles.ctaPrimary} to="/docs/user/overview">
              Get Started
            </Link>
            <Link
              className={styles.ctaSecondary}
              href="https://github.com/CITOpenRep/timemanagement"
            >
              View on GitHub →
            </Link>
          </div>

          <TerminalPreview />
        </div>
      </header>

      {/* ── MAIN CONTENT ── */}
      <main ref={mainRef}>
        {/* ── FEATURES ── */}
        <section className={clsx(styles.section, styles.sectionLight)}>
          <div className="container">
            <div data-reveal>
              <p className={styles.sectionLabel}>Capabilities</p>
              <h2
                className={clsx(styles.sectionTitle, styles.sectionTitleLight)}
              >
                Everything you need to track work and stay organized
              </h2>
            </div>
            <div className={styles.featureGrid} data-reveal style={{ "--reveal-delay": 1 }}>
              {features.map((f) => (
                <article key={f.title} className={styles.featureCard}>
                  <div className={styles.featureCardHeader}>
                    <span className={styles.featureIcon}>{f.icon}</span>
                    <span className={styles.featureTag}>{f.tag}</span>
                  </div>
                  <h3>{f.title}</h3>
                  <p>{f.description}</p>
                </article>
              ))}
            </div>
          </div>
        </section>

        {/* ── INTERACTIVE MOBILE MODEL ── */}
        <DeviceSimulator />

        {/* ── ARCHITECTURE ── */}
        <section className={clsx(styles.section, styles.sectionDark)}>
          <div className="container">
            <div data-reveal>
              <p className={styles.sectionLabel}>Architecture</p>
              <h2
                className={clsx(styles.sectionTitle, styles.sectionTitleDark)}
              >
                Three layers, one coherent system
              </h2>
            </div>
            <div className={styles.stackDiagram}>
              {techStack.map((layer, i) => (
                <div
                  key={layer.tech}
                  className={styles.stackLayer}
                  data-reveal
                  style={{ "--reveal-delay": i + 1 }}
                >
                  <div className={styles.layerHeader}>
                    <span className={styles.layerLabel}>{layer.layer}</span>
                    <span className={styles.layerTech}>{layer.tech}</span>
                  </div>
                  <p>{layer.description}</p>
                  <code className={styles.layerPath}>{layer.path}</code>
                </div>
              ))}
            </div>
          </div>
        </section>

        {/* ── DOCUMENTATION ── */}
        <section className={clsx(styles.section, styles.sectionLight)}>
          <div className="container">
            <div data-reveal>
              <p className={styles.sectionLabel}>Documentation</p>
              <h2
                className={clsx(styles.sectionTitle, styles.sectionTitleLight)}
              >
                Start from the track that matches your role
              </h2>
            </div>
            <div className={styles.docGrid}>
              {docPaths.map((doc, i) => (
                <article
                  key={doc.audience}
                  className={styles.docCard}
                  data-reveal
                  style={{ "--reveal-delay": i + 1 }}
                >
                  <h3>{doc.audience}</h3>
                  <p>{doc.description}</p>
                  <ul className={styles.docPageList}>
                    {doc.pages.map((page) => (
                      <li key={page}>{page}</li>
                    ))}
                  </ul>
                  <Link className={styles.docLink} to={doc.link}>
                    {doc.cta} <span aria-hidden="true">→</span>
                  </Link>
                </article>
              ))}
            </div>
          </div>
        </section>

        {/* ── OPEN SOURCE CTA ── */}
        <section className={clsx(styles.section, styles.sectionDark)}>
          <div className="container">
            <div className={styles.ossCta} data-reveal>
              <h2>Built in the open</h2>
              <p>
                TimeManagement is open source. Browse the code, report issues,
                or contribute directly on GitHub.
              </p>
              <div className={styles.ossLinks}>
                <Link
                  className={styles.ctaPrimary}
                  href="https://github.com/CITOpenRep/timemanagement"
                >
                  View Repository
                </Link>
                <Link
                  className={styles.ctaSecondary}
                  href="https://github.com/CITOpenRep/timemanagement/issues"
                >
                  Report an Issue →
                </Link>
              </div>
            </div>
          </div>
        </section>
      </main>
    </Layout>
  );
}
