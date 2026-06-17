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

  const menuItems = [
    { name: "Dashboard", icon: "🏠" },
    { name: "Timesheet", icon: "⏱" },
    { name: "Activities", icon: "📅" },
    { name: "My Tasks", icon: "⭐" },
    { name: "All Tasks", icon: "☑" },
    { name: "Projects", icon: "📁" },
    { name: "Project Updates", icon: "🕒" },
    { name: "About Us", icon: "ℹ" },
    { name: "Settings", icon: "⚙" }
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
            activeScreen === item.name && styles.menuItemActiveActual
          )}
          onClick={() => {
            setActiveScreen(item.name);
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
            <div className={styles.matrixCardValue}>9521H</div>
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
            <div className={styles.matrixCardValue}>13H</div>
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
                  
          <circle cx="50" cy="50" r="22" fill="#ffffff" />
        </svg>
      </div>
      
      <div style={{ textAlign: "center", paddingBottom: "16px" }}>
        <button style={{ background: "transparent", border: "none", fontSize: "0.85rem", cursor: "pointer", color: "#666" }}>
          ▲
        </button>
      </div>
    </>
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
                <span className={styles.controlLabel}>Quick Navigate</span>
                <div className={styles.toggleRow}>
                  <button 
                    className={clsx(styles.toggleBtn, activeScreen === "Dashboard" && styles.toggleBtnActive)}
                    onClick={() => setActiveScreen("Dashboard")}
                  >
                    🏠 Dashboard
                  </button>
                  <button 
                    className={clsx(styles.toggleBtn, activeScreen === "Projects" && styles.toggleBtnActive)}
                    onClick={() => setActiveScreen("Projects")}
                  >
                    📁 Projects
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
                  <div className={styles.deviceScreen}>
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
                        <span>12:00 PM</span>
                      </div>
                    </div>

                    {/* App Header */}
                    <header className={styles.appHeaderActual}>
                      <button 
                        className={styles.headerIconBtn}
                        onClick={() => setMenuOpen(!menuOpen)}
                      >
                        ☰
                      </button>
                      <h3 className={styles.headerTitle}>
                        {activeScreen === "Dashboard" ? "Account [TestCIT]" : activeScreen}
                      </h3>
                      <div className={styles.headerIcons}>
                        <button className={styles.headerIconBtn} title="Add Entry">⏱⁺</button>
                        <button className={styles.headerIconBtn} title="Notifications">🔔</button>
                        <button className={styles.headerIconBtn} title="Info">ⓘ</button>
                      </div>
                    </header>

                    {/* Screen Scrollable Body */}
                    <div className={styles.pageScrollContent}>
                      {activeScreen === "Dashboard" ? (
                        <>
                          {renderDashboardMatrix()}
                          {renderProjectOverview()}
                        </>
                      ) : (
                        <div style={{ padding: "30px 16px", textAlign: "center", color: "#666" }}>
                          <h3>{activeScreen} View</h3>
                          <p>Simulating the active Ubuntu Touch component. Switch back to Dashboard to view the Eisenhower priority matrix.</p>
                        </div>
                      )}
                    </div>

                    {/* Floating Action Button (FAB) */}
                    <button 
                      className={styles.fabButtonActual}
                      onClick={() => setMenuOpen(!menuOpen)}
                    >
                      ☰
                    </button>

                    {/* Ubuntu Left Menu Drawer */}
                    <div className={clsx(styles.menuPanelActual, menuOpen && styles.menuPanelOpen)}>
                      <div className={styles.menuHeaderActual}>
                        <h4 className={styles.menuHeaderTitle}>Menu</h4>
                        <div className={styles.menuHeaderControls}>
                          <span style={{ fontSize: "1.1rem", cursor: "pointer" }}>👤</span>
                          <span style={{ fontSize: "1.1rem", cursor: "pointer" }}>🌙</span>
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
                  <div className={styles.deviceScreen}>
                    {/* Top Status Bar */}
                    <div className={styles.statusBarActual}>
                      <span>Ubuntu Touch converged workspace</span>
                      <div style={{ display: "flex", gap: "6px" }}>
                        <span>📶</span>
                        <span>🔋 88%</span>
                        <span>12:00 PM</span>
                      </div>
                    </div>

                    <div className={styles.convergedGrid}>
                      {/* Column 1: Permanent Sidebar Menu */}
                      <aside className={styles.convergedSidebar}>
                        <div className={styles.menuHeaderActual}>
                          <h4 className={styles.menuHeaderTitle}>Menu</h4>
                          <div className={styles.menuHeaderControls}>
                            <span style={{ fontSize: "1rem" }}>🌙</span>
                            <span style={{ fontSize: "1rem" }}>👤</span>
                          </div>
                        </div>
                        {renderMenuList()}
                      </aside>

                      {/* Column 2: Dashboard/Account Main View */}
                      <main className={styles.convergedCenter}>
                        <header className={styles.appHeaderActual}>
                          <h3 className={styles.headerTitle}>Account [TestCIT]</h3>
                          <div className={styles.headerIcons}>
                            <button className={styles.headerIconBtn}>⏱⁺</button>
                            <button className={styles.headerIconBtn}>🔔</button>
                            <button className={styles.headerIconBtn}>ⓘ</button>
                          </div>
                        </header>
                        <div className={styles.pageScrollContent}>
                          {renderDashboardMatrix()}
                          {renderProjectOverview()}
                        </div>
                        
                        <button className={styles.fabButtonActual}>
                          ☰
                        </button>
                      </main>

                      {/* Column 3: Charts / Projects View */}
                      <section className={styles.convergedRight}>
                        <header className={styles.rightHeader}>
                          Charts
                        </header>
                        
                        <div className={styles.rightContent}>
                          <div className={styles.barChartTitle}>Projectwise Time Spent</div>
                          
                          <div className={styles.barChartContainer}>
                            {projectsData.map((p) => (
                              <div key={p.name} className={styles.barChartRow}>
                                <span className={styles.barChartLabel} title={p.name}>
                                  {p.name}
                                </span>
                                <div className={styles.barChartValueWrapper}>
                                  <div className={styles.barChartBarBg}>
                                    <div 
                                      className={styles.barChartBarFill} 
                                      style={{ width: `${p.percent}%`, backgroundColor: p.color }}
                                    />
                                  </div>
                                  <span className={styles.barChartValText}>{p.time.split(" ")[0]}</span>
                                </div>
                              </div>
                            ))}
                          </div>

                          <button className={styles.showNextBtn}>
                            Show next 10 ↓
                          </button>

                          <div className={styles.projectsSectionHeader}>
                            <h4 className={styles.projectsSectionTitle}>Projects</h4>
                            <span className={styles.projectsTotalBadge}>9490.0 h</span>
                          </div>

                          <input 
                            type="text" 
                            className={styles.projectSearchBox} 
                            placeholder="Search projects..." 
                            value={searchQuery}
                            onChange={(e) => setSearchQuery(e.target.value)}
                          />

                          <div className={styles.projectFilterTabs}>
                            <button 
                              className={clsx(styles.projectFilterBtn, filterType === "most-time" && styles.projectFilterBtnActive)}
                              onClick={() => setFilterType("most-time")}
                            >
                              Most time
                            </button>
                            <button 
                              className={clsx(styles.projectFilterBtn, filterType === "tasks" && styles.projectFilterBtnActive)}
                              onClick={() => setFilterType("tasks")}
                            >
                              Tasks
                            </button>
                            <button 
                              className={clsx(styles.projectFilterBtn, filterType === "a-z" && styles.projectFilterBtnActive)}
                              onClick={() => setFilterType("a-z")}
                            >
                              A-Z
                            </button>
                          </div>

                          <div className={styles.projectListLandscape}>
                            {filteredProjects.map((p) => (
                              <div key={p.name} className={styles.projectListItemCard}>
                                <div className={styles.projectListItemHeader}>
                                  <h4 className={styles.projectListItemName}>{p.name}</h4>
                                  <span className={styles.projectListItemTime}>{p.time}</span>
                                </div>
                                <div className={styles.projectListItemTasks}>
                                  {p.tasks} tasks
                                </div>
                                <div className={styles.projectProgressBg}>
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
