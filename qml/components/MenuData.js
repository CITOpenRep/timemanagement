.pragma library

function items() {
    return [
        { textKey: "Dashboard", iconName: "home", iconColor: "#3498db", pageUrl: "Dashboard.qml", pageNum: 0 },
        { textKey: "Timesheet", iconName: "alarm-clock", iconColor: "#e67e22", pageUrl: "Timesheet_Page.qml", pageNum: 1 },
        { textKey: "Activities", iconName: "calendar", iconColor: "#e74c3c", pageUrl: "Activity_Page.qml", pageNum: 2 },
        { textKey: "My Tasks", iconName: "scope-manager", iconColor: "#2ecc71", pageUrl: "MyTasks.qml", pageNum: 3 },
        { textKey: "All Tasks", iconName: "view-list-symbolic", iconColor: "#1abc9c", pageUrl: "Task_Page.qml", pageNum: 3 },
        { textKey: "Projects", iconName: "folder-symbolic", iconColor: "#9b59b6", pageUrl: "Project_Page.qml", pageNum: 4 },
        { textKey: "Project Updates", iconName: "history", iconColor: "#f39c12", pageUrl: "Updates_Page.qml", pageNum: 5 },
        { textKey: "About Us", iconName: "info", iconColor: "#2980b9", pageUrl: "Aboutus.qml", pageNum: 7 },
        { textKey: "Settings", iconName: "settings", iconColor: "#7f8c8d", pageUrl: "settings/Settings_Page.qml", pageNum: 6, showDivider: false }
    ];
}
