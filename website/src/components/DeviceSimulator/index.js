import React, { useState, useEffect, useRef } from "react";
import clsx from "clsx";
import styles from "../../pages/index.module.css";
import {
  menuItems,
  projectsData,
  timesheetsData,
  tasksData,
  allTasksData,
  projectUpdatesData,
  activitiesData
} from "./mockData";

export function DeviceSimulator() {
  const [orientation, setOrientation] = useState("portrait");
  const [menuOpen, setMenuOpen] = useState(false);
  const [activeScreen, setActiveScreen] = useState("Dashboard");
  const [searchQuery, setSearchQuery] = useState("");
  const [filterType, setFilterType] = useState("most-time");
  const [themeMode, setThemeMode] = useState("light"); // Forced light mode by default
  const [portraitWidth, setPortraitWidth] = useState(360);
  const [portraitHeight, setPortraitHeight] = useState(720);
  const [landscapeWidth, setLandscapeWidth] = useState(900);
  const [landscapeHeight, setLandscapeHeight] = useState(520);

  const containerRef = useRef(null);
  const [scale, setScale] = useState(1);

  useEffect(() => {
    if (typeof window === "undefined" || !containerRef.current) return;

    const handleResize = () => {
      if (!containerRef.current) return;
      const containerWidth = containerRef.current.getBoundingClientRect().width;
      const frameWidth = (orientation === "portrait" ? portraitWidth : landscapeWidth) + 28;
      const buffer = 16; // breathing room gutter (8px on each side)
      const targetWidth = frameWidth + buffer;

      if (containerWidth < targetWidth) {
        setScale(containerWidth / targetWidth);
      } else {
        setScale(1);
      }
    };

    handleResize();

    const observer = new ResizeObserver(() => {
      handleResize();
    });

    observer.observe(containerRef.current);

    return () => {
      observer.disconnect();
    };
  }, [orientation, portraitWidth, landscapeWidth, portraitHeight, landscapeHeight]);

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
        <span className={styles.formValueMain}>{themeMode === "dark" ? "demo" : "demo_db"}</span>
      </div>

      <div className={styles.formRowInput}>
        <span className={styles.formLabelSmall}>Project</span>
        <span className={styles.formValueMain}>
          {themeMode === "dark" ? "Project Alpha - Phase 1..." : "Project Alpha - Phase 1"}
        </span>
      </div>

      <div className={styles.formRowInput}>
        <span className={styles.formLabelSmall}>Subproject</span>
        <span className={styles.formValueMain} style={{ fontWeight: 400, color: "#888" }}>Tap to select</span>
      </div>

      <div className={styles.formRowInput}>
        <span className={styles.formLabelSmall}>Task</span>
        <span className={styles.formValueMain}>{themeMode === "dark" ? "Database Migration" : "sub task1"}</span>
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
    <div style={{ display: "flex", flexDirection: "column", height: "100%", overflow: "hidden" }}>
      {/* Tab Bar sticky */}
      <div className={styles.utTabBar}>
        <div className={clsx(styles.utTabBtn, styles.utTabBtnActive)}>
          All
          <div className={styles.utTabIndicator} />
        </div>
        <div className={styles.utTabBtn}>On Track</div>
        <div className={styles.utTabBtn}>At Risk</div>
        <div className={styles.utTabBtn}>Off Track</div>
      </div>

      {/* Project Updates Card list */}
      <div className={clsx(styles.logListContainer, styles.utScrollContainer)}>
        {projectUpdatesData.map((log, idx) => (
          <div key={idx} className={styles.utUpdateCard}>
            
            {/* Left description col */}
            <div className={styles.utUpdateMainContent}>
              <h4 className={styles.utUpdateTitle}>{log.title}</h4>
              <p className={styles.utUpdateMeta}>By: {log.author} | {log.date}</p>
              <p className={styles.utUpdateProject}>{log.project}</p>
              
              {/* Progress Bar representing Project Completion */}
              <div className={styles.utProgressBarTrack}>
                <div 
                  className={styles.utProgressBarFill} 
                  style={{ width: `${log.completion}%` }}
                />
              </div>
            </div>

            {/* Right status details col */}
            <div className={styles.utUpdateRightCol}>
              <span 
                className={styles.utUpdateStatusBadge}
                style={{ 
                  backgroundColor: 
                    log.status === "on_track" ? "#4cae80" : 
                    log.status === "at_risk" ? "#e68a45" : "#757575" 
                }}
              >
                {log.status}
              </span>
              <button className={styles.utUpdateDetailsBtn}>Details</button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );

  // Render Activities
  const renderActivitiesList = () => (
    <div style={{ display: "flex", flexDirection: "column", height: "100%", overflow: "hidden" }}>
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
      <div className={clsx(styles.logListContainer, styles.utScrollContainer)}>
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
    <div className={styles.utAboutPage}>
      <h4 className={styles.utAboutHeaderBlue}>Time Management - Alpha Draft</h4>
      
      <div className={styles.utAboutVersionLarge}>Version 1.2.9</div>

      <p className={styles.utAboutText}>
        <strong>Time Management</strong> is a native time-tracking and productivity application built exclusively for Ubuntu Touch phones. It empowers users to manage projects, tasks, timesheets, and activities—both offline and online—through seamless integration with CURQ and Odoo servers.
      </p>

      <h4 className={styles.utAboutSectionTitle}>What Does This App Do?</h4>
      <p className={styles.utAboutText}>
        This app is your all-in-one productivity companion on Ubuntu Touch. Whether you're a freelancer tracking billable hours, a project manager overseeing team tasks, or simply someone who wants to stay organized, Time Management has you covered.
      </p>

      <h4 className={styles.utAboutSectionTitle}>Key Features</h4>
      <ul className={styles.utAboutList}>
        <li className={styles.utAboutListItem}>
          <span className={styles.utAboutListItemBold}>Project Management:</span> Create and organize projects with full hierarchy support (Projects → Subprojects → Tasks → Subtasks)
        </li>
        <li className={styles.utAboutListItem}>
          <span className={styles.utAboutListItemBold}>Task Tracking:</span> Manage tasks with deadlines, priorities, stages, and assignees
        </li>
        <li className={styles.utAboutListItem}>
          <span className={styles.utAboutListItemBold}>Timesheet Logging:</span> Track your work hours with built-in timers and sync to your server
        </li>
        <li className={styles.utAboutListItem}>
          <span className={styles.utAboutListItemBold}>Activity Management:</span> Log and schedule activities linked to projects and tasks
        </li>
        <li className={styles.utAboutListItem}>
          <span className={styles.utAboutListItemBold}>Project Updates:</span> Create and share project status updates with rich text support
        </li>
        <li className={styles.utAboutListItem}>
          <span className={styles.utAboutListItemBold}>Push Notifications:</span> Stay informed with real-time notifications for assignments and updates
        </li>
        <li className={styles.utAboutListItem}>
          <span className={styles.utAboutListItemBold}>Auto-Sync:</span> Automatic bidirectional synchronization with your CURQ/Odoo server
        </li>
        <li className={styles.utAboutListItem}>
          <span className={styles.utAboutListItemBold}>Offline Support:</span> Work offline and sync when connected
        </li>
        <li className={styles.utAboutListItem}>
          <span className={styles.utAboutListItemBold}>Visual Dashboard:</span> See where your time goes with charts and analytics
        </li>
        <li className={styles.utAboutListItem}>
          <span className={styles.utAboutListItemBold}>Multi-Account:</span> Connect to multiple server instances simultaneously
        </li>
        <li className={styles.utAboutListItem}>
          <span className={styles.utAboutListItemBold}>Dark Mode:</span> Full dark theme support for comfortable viewing
        </li>
      </ul>

      <div className={styles.utAboutServerBand}>
        Recommended Server: CURQ
      </div>
      <p className={styles.utAboutText}>
        <a 
          href="https://curq.nl" 
          target="_blank" 
          rel="noopener noreferrer" 
          className={styles.utAboutLink}
        >
          CURQ
        </a> is the all-in-one platform for your business, fully Open Source and tailored to your needs.
      </p>
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

            <div style={{ marginTop: "16px", paddingTop: "16px", borderTop: "1px dashed rgba(255, 255, 255, 0.15)" }}>
              <span className={styles.controlLabel}>Resize Simulator</span>
              
              {orientation === "portrait" ? (
                <div style={{ display: "flex", flexDirection: "column", gap: "10px", marginTop: "8px" }}>
                  <div>
                    <div style={{ display: "flex", justifyContent: "space-between", fontSize: "0.78rem", marginBottom: "4px" }}>
                      <span>Width: <strong>{portraitWidth}px</strong></span>
                      <span style={{ opacity: 0.5 }}>300 - 480px</span>
                    </div>
                    <input 
                      type="range" 
                      min="300" 
                      max="480" 
                      value={portraitWidth} 
                      onChange={(e) => setPortraitWidth(Number(e.target.value))}
                      style={{ width: "100%", accentColor: "#e05a2b", cursor: "ew-resize" }}
                    />
                  </div>
                  <div>
                    <div style={{ display: "flex", justifyContent: "space-between", fontSize: "0.78rem", marginBottom: "4px" }}>
                      <span>Height: <strong>{portraitHeight}px</strong></span>
                      <span style={{ opacity: 0.5 }}>550 - 850px</span>
                    </div>
                    <input 
                      type="range" 
                      min="550" 
                      max="850" 
                      value={portraitHeight} 
                      onChange={(e) => setPortraitHeight(Number(e.target.value))}
                      style={{ width: "100%", accentColor: "#e05a2b", cursor: "ew-resize" }}
                    />
                  </div>
                </div>
              ) : (
                <div style={{ display: "flex", flexDirection: "column", gap: "10px", marginTop: "8px" }}>
                  <div>
                    <div style={{ display: "flex", justifyContent: "space-between", fontSize: "0.78rem", marginBottom: "4px" }}>
                      <span>Width: <strong>{landscapeWidth}px</strong></span>
                      <span style={{ opacity: 0.5 }}>750 - 1100px</span>
                    </div>
                    <input 
                      type="range" 
                      min="750" 
                      max="1100" 
                      value={landscapeWidth} 
                      onChange={(e) => setLandscapeWidth(Number(e.target.value))}
                      style={{ width: "100%", accentColor: "#e05a2b", cursor: "ew-resize" }}
                    />
                  </div>
                  <div>
                    <div style={{ display: "flex", justifyContent: "space-between", fontSize: "0.78rem", marginBottom: "4px" }}>
                      <span>Height: <strong>{landscapeHeight}px</strong></span>
                      <span style={{ opacity: 0.5 }}>450 - 700px</span>
                    </div>
                    <input 
                      type="range" 
                      min="450" 
                      max="700" 
                      value={landscapeHeight} 
                      onChange={(e) => setLandscapeHeight(Number(e.target.value))}
                      style={{ width: "100%", accentColor: "#e05a2b", cursor: "ew-resize" }}
                    />
                  </div>
                </div>
              )}
              
              <button 
                className={styles.toggleBtn}
                onClick={() => {
                  setPortraitWidth(360);
                  setPortraitHeight(720);
                  setLandscapeWidth(900);
                  setLandscapeHeight(520);
                }}
                style={{ marginTop: "12px", width: "100%", display: "block", textAlign: "center", fontSize: "0.75rem", padding: "6px" }}
              >
                🔄 Reset Dimensions
              </button>
            </div>

            <div className={styles.gestureHint}>
              <span>💡</span>
              <p>Ubuntu Touch gesture: Hover or swipe from the <strong>left screen border</strong> to toggle the menu drawer, or tap the blue Floating Action Button (FAB).</p>
            </div>
          </div>

          <div 
            ref={containerRef}
            className={styles.deviceCanvas} 
            data-reveal 
            style={{ 
              "--reveal-delay": 1,
              height: `${((orientation === "portrait" ? portraitHeight : landscapeHeight) + 28) * scale}px`,
              minHeight: "auto",
              alignItems: "flex-start",
              overflow: "hidden"
            }}
          >
            <div 
              className={styles.deviceTurntable}
              style={{
                transform: `scale(${scale})`,
                transformOrigin: "top center",
                width: `${(orientation === "portrait" ? portraitWidth : landscapeWidth) + 28}px`,
                height: `${(orientation === "portrait" ? portraitHeight : landscapeHeight) + 28}px`,
                maxWidth: "none"
              }}
            >
              <div 
                className={clsx(styles.deviceFrame, styles[orientation])}
                style={orientation === "portrait" ? { width: `${portraitWidth}px`, height: `${portraitHeight}px` } : { width: `${landscapeWidth}px`, height: `${landscapeHeight}px` }}
              >
                
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
                            {activeScreen === "Dashboard" && `Account [${themeMode === "dark" ? "demo" : "demo_db"}]`}
                            {activeScreen === "Timesheets" && "Timesheets"}
                            {activeScreen === "My Tasks" && "My Tasks"}
                            {activeScreen === "About Us" && "About"}
                            {activeScreen !== "Dashboard" && activeScreen !== "Timesheets" && activeScreen !== "My Tasks" && activeScreen !== "About Us" && activeScreen}
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
                            ) : activeScreen === "Project Updates" ? (
                              <>
                                <button className={styles.headerIconBtn} title="Add Update">+</button>
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
                        <div className={styles.utScrollContainer}>
                          {renderDashboardMatrix()}
                          {renderProjectOverview()}
                        </div>
                      )}
                      {activeScreen === "Timesheets" && (
                        <div className={styles.utScrollContainer}>
                          {renderTimesheetsList()}
                        </div>
                      )}
                      {activeScreen === "Timesheet" && (
                        <div className={styles.utScrollContainer}>
                          {renderTimesheetEntryForm()}
                        </div>
                      )}
                      {activeScreen === "My Tasks" && (
                        <div className={styles.utScrollContainer}>
                          {renderMyTasksList()}
                        </div>
                      )}
                      {activeScreen === "All Tasks" && (
                        <div className={styles.utScrollContainer}>
                          {renderAllTasksList()}
                        </div>
                      )}
                      {activeScreen === "Projects" && (
                        <div className={styles.utScrollContainer}>
                          {renderProjectsList()}
                        </div>
                      )}
                      {activeScreen === "Project Updates" && renderProjectUpdates()}
                      {activeScreen === "Activities" && renderActivitiesList()}
                      {activeScreen === "Settings" && (
                        <div className={styles.utScrollContainer}>
                          {renderSettingsScreen()}
                        </div>
                      )}
                      {activeScreen === "About Us" && (
                        <div className={styles.utScrollContainer}>
                          {renderAboutScreen()}
                        </div>
                      )}
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
                            <span style={{ fontSize: "1rem" }}>👤</span>
                          </div>
                        </div>
                        {renderMenuList()}
                      </aside>

                      {/* Column 2: Dashboard/Account Main View */}
                      <main className={styles.convergedCenter} style={{ background: "transparent" }}>
                        <header className={styles.appHeaderActual}>
                          <h3 className={styles.headerTitle}>
                            {activeScreen === "Dashboard" && `Account [${themeMode === "dark" ? "demo" : "demo_db"}]`}
                            {activeScreen === "Timesheets" && "Timesheets"}
                            {activeScreen === "Timesheet" && "Timesheet"}
                            {activeScreen === "My Tasks" && "My Tasks"}
                            {activeScreen === "About Us" && "About"}
                            {activeScreen !== "Dashboard" && activeScreen !== "Timesheets" && activeScreen !== "Timesheet" && activeScreen !== "My Tasks" && activeScreen !== "About Us" && activeScreen}
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
                            ) : activeScreen === "Project Updates" ? (
                              <>
                                <button className={styles.headerIconBtn} title="Add Update">+</button>
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
                            <div className={styles.utScrollContainer}>
                              {renderDashboardMatrix()}
                              {renderProjectOverview()}
                            </div>
                          )}
                          {activeScreen === "Timesheets" && (
                            <div className={styles.utScrollContainer}>
                              {renderTimesheetsList()}
                            </div>
                          )}
                          {activeScreen === "Timesheet" && (
                            <div className={styles.utScrollContainer}>
                              {renderTimesheetEntryForm()}
                            </div>
                          )}
                          {activeScreen === "My Tasks" && (
                            <div className={styles.utScrollContainer}>
                              {renderMyTasksList()}
                            </div>
                          )}
                          {activeScreen === "All Tasks" && (
                            <div className={styles.utScrollContainer}>
                              {renderAllTasksList()}
                            </div>
                          )}
                          {activeScreen === "Projects" && (
                            <div className={styles.utScrollContainer}>
                              {renderProjectsList()}
                            </div>
                          )}
                          {activeScreen === "Project Updates" && renderProjectUpdates()}
                          {activeScreen === "Activities" && renderActivitiesList()}
                          {activeScreen === "Settings" && (
                            <div className={styles.utScrollContainer}>
                              {renderSettingsScreen()}
                            </div>
                          )}
                          {activeScreen === "About Us" && (
                            <div className={styles.utScrollContainer}>
                              {renderAboutScreen()}
                            </div>
                          )}
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

export default DeviceSimulator;
