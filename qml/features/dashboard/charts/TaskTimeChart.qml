// Lightweight time tracking drilldown with direct project, task, and log views.
import QtQuick 2.12
import Lomiri.Components 1.3
import QtQuick.Layouts 1.12
import "../components" as DashboardComponents
import "../js/chartUtils.js" as ChartUtils

Item {
    id: root

    property var projectsModel: []
    property var projectTasksProvider: null
    property var taskLogsProvider: null

    property string currentView: "projects"
    property var selectedProject: null
    property var selectedTask: null
    property var selectedProjectTasks: []
    property var selectedTaskLogs: []
    property string portfolioSearchText: ""
    property string portfolioSortMode: "time"
    property bool showAllTasks: false

    signal projectOpened(string projectId)
    signal taskOpened(string projectId, string taskId)
    signal backNavigated()

    readonly property bool isDark: Theme.name === "Ubuntu.Components.Themes.SuruDark"
    readonly property var visibleProjects: ChartUtils.prepareProjects(projectsModel, portfolioSortMode, portfolioSearchText)
    readonly property real portfolioTotalHours: ChartUtils.sumProjectHours(projectsModel)
    readonly property real portfolioMaxHours: ChartUtils.maxProjectHours(projectsModel)
    readonly property var topProjectTasks: ChartUtils.topTasks(selectedProjectTasks, 10)
    readonly property real currentContentHeight: contentLoader.item ? contentLoader.item.implicitHeight : units.gu(40)
    implicitHeight: headerBar.height + currentContentHeight
    readonly property color summaryAccentTextColor: root.isDark ? root.activeAccent : Qt.darker(root.activeAccent, 1.8)
    readonly property color summaryPrimaryTextColor: root.isDark ? Theme.palette.normal.baseText : Qt.darker(Theme.palette.normal.baseText, 1.35)

    // Accent color from the selected project, or fallback to the orange theme.
    // Guard against white / near-white colours that become invisible in light mode.
    readonly property color activeAccent: {
        if (selectedProject && selectedProject.colour) {
            var c = Qt.darker(selectedProject.colour, 1.0);
            if (c.r > 0.85 && c.g > 0.85 && c.b > 0.85)
                return "#E95420";
            return selectedProject.colour;
        }
        return "#E95420";
    }

    function openProject(projectData) {
        if (!projectData) return;
        selectedProject = projectData;
        selectedTask = null;
        selectedTaskLogs = [];
        showAllTasks = false;
        selectedProjectTasks = projectTasksProvider ? ChartUtils.prepareTasks(projectTasksProvider(projectData.id) || []) : [];
        currentView = "project";
        projectOpened(projectData.id);
    }

    function openTask(taskData) {
        if (!selectedProject || !taskData) return;
        selectedTask = taskData;
        selectedTask.projectTotalHours = Number(selectedProject.totalHours || 0);
        selectedTaskLogs = taskLogsProvider ? (taskLogsProvider(selectedProject.id, taskData.id) || []) : [];
        selectedTask.logs = selectedTaskLogs;
        currentView = "task";
        taskOpened(selectedProject.id, taskData.id);
    }

    function goBack() {
        if (currentView === "task") {
            currentView = "project";
        } else if (currentView === "project") {
            currentView = "projects";
            selectedProject = null;
            selectedProjectTasks = [];
        }
        backNavigated();
    }

    function ensureVisibleInAncestorFlickable(item) {
        if (!item) return;

        var parentItem = root.parent;
        while (parentItem) {
            if (parentItem.contentY !== undefined && parentItem.height !== undefined && parentItem.contentItem !== undefined) {
                var point = item.mapToItem(parentItem.contentItem, 0, 0);
                var topPadding = units.gu(2);
                var bottomPadding = units.gu(8);
                var itemTop = point.y;
                var itemBottom = itemTop + item.height;
                var viewportTop = parentItem.contentY;
                var viewportBottom = viewportTop + parentItem.height;

                if (itemTop < viewportTop + topPadding) {
                    parentItem.contentY = Math.max(0, itemTop - topPadding);
                } else if (itemBottom > viewportBottom - bottomPadding) {
                    parentItem.contentY = Math.min(parentItem.contentHeight - parentItem.height,
                                                   itemBottom - parentItem.height + bottomPadding);
                }
                return;
            }
            parentItem = parentItem.parent;
        }
    }

    // ── Background ──
    Rectangle {
        anchors.fill: parent
        color: "transparent"
    }

    Column {
        anchors.fill: parent
        spacing: 0

        // ── Header Bar ──
        Rectangle {
            id: headerBar
            width: parent.width
            height: units.gu(7)
            color: "transparent"

            // Bottom border accent
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: units.dp(2)
                color: root.currentView === "projects" ? "#E95420" : root.activeAccent
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: units.gu(2)
                anchors.rightMargin: units.gu(2)
                spacing: units.gu(1.5)

                // Back button
                Rectangle {
                    visible: root.currentView !== "projects"
                    Layout.preferredWidth: units.gu(8)
                    Layout.preferredHeight: units.gu(4)
                    radius: units.gu(2)
                    color: root.isDark ? Qt.rgba(root.activeAccent.r, root.activeAccent.g, root.activeAccent.b, 0.2)
                                       : Qt.rgba(root.activeAccent.r, root.activeAccent.g, root.activeAccent.b, 0.12)
                    Label {
                        anchors.centerIn: parent
                        text: "← Back"
                        color: root.activeAccent
                        font.pixelSize: units.dp(13)
                        font.bold: true
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.goBack()
                    }
                }

                Column {
                    Layout.fillWidth: true
                    spacing: units.dp(2)

                    Label {
                        width: parent.width
                        text: root.currentView === "projects" ? i18n.dtr("ubtms", "Projects")
                             : root.currentView === "project" ? (root.selectedProject ? root.selectedProject.name : "")
                             : (root.selectedTask ? root.selectedTask.name : "")
                        color: Theme.palette.normal.baseText
                        font.bold: true
                        font.pixelSize: units.dp(16)
                        elide: Text.ElideRight
                    }

                    Label {
                        width: parent.width
                        text: root.currentView === "projects" ? ChartUtils.formatHours(root.portfolioTotalHours)
                             : root.currentView === "project" ? ChartUtils.projectSubtitle(root.selectedProject, root.selectedProjectTasks.length)
                             : (root.selectedProject ? root.selectedProject.name : "")
                        color: Theme.palette.normal.backgroundText
                        font.pixelSize: units.dp(12)
                        elide: Text.ElideRight
                    }
                }

                // Total hours pill (projects view only)
                Rectangle {
                    visible: root.currentView === "projects"
                    Layout.preferredWidth: totalLabel.implicitWidth + units.gu(2)
                    Layout.preferredHeight: units.gu(3.5)
                    radius: height / 2
                    color: "#E95420"

                    Label {
                        id: totalLabel
                        anchors.centerIn: parent
                        text: ChartUtils.formatHours(root.portfolioTotalHours)
                        color: "white"
                        font.bold: true
                        font.pixelSize: units.dp(12)
                    }
                }
            }
        }

        // ── Content Area ──
        Loader {
            id: contentLoader
            width: parent.width
            height: item ? item.implicitHeight : 0
            sourceComponent: root.currentView === "projects" ? projectsView
                            : root.currentView === "project" ? projectView
                            : taskView
        }
    }

    // ═══════════════════════════════════════════════════
    // ── PROJECTS LIST VIEW ──
    // ═══════════════════════════════════════════════════
    Component {
        id: projectsView

        Item {
            width: root.width
            implicitHeight: projectContent.implicitHeight + units.gu(4)

            Column {
                id: projectContent
                width: parent.width
                spacing: units.gu(2)

                // Top padding
                Item { width: 1; height: units.gu(1.5) }

                // Search bar
                Rectangle {
                    width: parent.width - units.gu(4)
                    height: units.gu(5)
                    anchors.horizontalCenter: parent.horizontalCenter
                    radius: units.gu(1.2)
                    color: "transparent"
                    border.color: root.isDark ? Qt.rgba(1,1,1,0.1) : Qt.rgba(0,0,0,0.1)
                    border.width: units.dp(1)

                    TextField {
                        anchors.fill: parent
                        anchors.margins: units.dp(2)
                        placeholderText: i18n.dtr("ubtms", "Search projects...")
                        text: root.portfolioSearchText
                        onTextChanged: root.portfolioSearchText = text
                        onActiveFocusChanged: {
                            if (activeFocus) {
                                root.ensureVisibleInAncestorFlickable(parent);
                            }
                        }
                        color: Theme.palette.normal.baseText
                        font.pixelSize: units.dp(13)
                    }
                }

                // Sort tabs
                Rectangle {
                    width: parent.width - units.gu(4)
                    height: units.gu(5)
                    anchors.horizontalCenter: parent.horizontalCenter
                    radius: units.gu(1.2)
                    color: root.isDark ? Qt.rgba(1,1,1,0.05) : Qt.rgba(0,0,0,0.05)

                    Row {
                        anchors.fill: parent
                        anchors.margins: units.dp(3)
                        spacing: units.dp(3)

                        Repeater {
                            model: [
                                { label: i18n.dtr("ubtms", "Most time"), value: "time", icon: "🕐" },
                                { label: i18n.dtr("ubtms", "Tasks"), value: "tasks", icon: "📋" },
                                { label: i18n.dtr("ubtms", "A-Z"), value: "name", icon: "🔤" }
                            ]

                            delegate: Rectangle {
                                width: (parent.width - units.dp(6)) / 3
                                height: parent.height
                                radius: units.gu(1)
                                color: root.portfolioSortMode === modelData.value
                                       ? "#E95420" : "transparent"

                                Label {
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    color: root.portfolioSortMode === modelData.value
                                           ? "white"
                                           : (Theme.palette.normal.backgroundText)
                                    font.pixelSize: units.dp(13)
                                    font.bold: root.portfolioSortMode === modelData.value
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: root.portfolioSortMode = modelData.value
                                }

                                Behavior on color { ColorAnimation { duration: 200 } }
                            }
                        }
                    }
                }

                // Project list
                ListView {
                    width: parent.width
                    height: contentHeight
                    interactive: false
                    spacing: units.gu(1.2)
                    model: root.visibleProjects

                    delegate: DashboardComponents.ProjectCard {
                        width: ListView.view.width
                        projectData: modelData.projectData
                        maxHours: Math.max(root.portfolioMaxHours, 0.1)
                        onClicked: root.openProject(modelData.projectData)
                    }
                }

                Label {
                    visible: root.visibleProjects.length === 0
                    width: parent.width - units.gu(4)
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: i18n.dtr("ubtms", "No projects found")
                    color: Theme.palette.normal.backgroundText
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: units.dp(14)
                }

                // Bottom padding
                Item { width: 1; height: units.gu(2) }
            }
        }
    }

    // ═══════════════════════════════════════════════════
    // ── PROJECT DETAIL VIEW ──
    // ═══════════════════════════════════════════════════
    Component {
        id: projectView

        Item {
            width: root.width
            implicitHeight: taskContent.implicitHeight + units.gu(4)

            Column {
                id: taskContent
                width: parent.width
                spacing: units.gu(2.5)

                // Top padding
                Item { width: 1; height: units.gu(1) }

                // ── Summary Card ──
                Rectangle {
                    width: parent.width - units.gu(4)
                    anchors.horizontalCenter: parent.horizontalCenter
                    implicitHeight: summaryGrid.implicitHeight + units.gu(5)
                    radius: units.gu(1.5)
                    color: root.isDark ? Qt.rgba(1,1,1,0.05) : Qt.rgba(0,0,0,0.03)
                    border.color: root.isDark ? Qt.rgba(root.activeAccent.r, root.activeAccent.g, root.activeAccent.b, 0.3) : Qt.rgba(0,0,0,0.1)
                    border.width: units.dp(1)

                    // Top accent strip
                    Rectangle {
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: units.gu(1.5)
                        anchors.rightMargin: units.gu(1.5)
                        height: units.dp(3)
                        color: root.activeAccent
                    }

                    Grid {
                        id: summaryGrid
                        width: parent.width - units.gu(5)
                        anchors.centerIn: parent
                        columns: 2
                        rowSpacing: units.gu(2.5)
                        columnSpacing: units.gu(3)

                        Repeater {
                            model: [
                                { label: i18n.dtr("ubtms", "TOTAL"), value: ChartUtils.formatHours(root.selectedProject ? root.selectedProject.totalHours : 0), accent: true },
                                { label: i18n.dtr("ubtms", "TASKS"), value: String(root.selectedProjectTasks.length), accent: false },
                                { label: i18n.dtr("ubtms", "AVERAGE"), value: ChartUtils.averageLabel(root.selectedProject ? root.selectedProject.totalHours : 0, root.selectedProjectTasks.length), accent: false },
                                { label: i18n.dtr("ubtms", "TOP TASK"), value: ChartUtils.topTaskName(root.selectedProjectTasks), accent: false }
                            ]

                            delegate: Column {
                                width: (summaryGrid.width - units.gu(3)) / 2
                                spacing: units.gu(0.6)

                                Label {
                                    text: modelData.label
                                    color: Theme.palette.normal.backgroundText
                                    font.pixelSize: units.dp(11)
                                    font.letterSpacing: 1.0
                                }

                                Label {
                                    width: parent.width
                                    text: modelData.value
                                    color: modelData.accent ? root.summaryAccentTextColor
                                           : (Theme.palette.normal.baseText)
                                    font.bold: true
                                    font.pixelSize: modelData.accent ? units.dp(18) : units.dp(15)
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                }

                // ── Task Bars ──
                Rectangle {
                    width: parent.width - units.gu(4)
                    anchors.horizontalCenter: parent.horizontalCenter
                    implicitHeight: taskChart.implicitHeight + units.gu(4)
                    radius: units.gu(1.5)
                    color: root.isDark ? Qt.rgba(1,1,1,0.05) : Qt.rgba(0,0,0,0.03)
                    border.color: root.isDark ? Qt.rgba(1,1,1,0.1) : Qt.rgba(0,0,0,0.1)
                    border.width: units.dp(1)

                    DashboardComponents.TaskChartCanvas {
                        id: taskChart
                        anchors.fill: parent
                        anchors.margins: units.gu(2)
                        tasksData: root.topProjectTasks
                        accentColour: root.activeAccent
                        onTaskSelected: {
                            var task = ChartUtils.findTaskById(root.selectedProjectTasks, taskId)
                            if (task) root.openTask(task)
                        }
                    }
                }

                // ── Full Task List ──
                ListView {
                    width: parent.width
                    height: contentHeight
                    interactive: false
                    spacing: units.gu(1)
                    model: root.showAllTasks ? root.selectedProjectTasks : root.selectedProjectTasks.slice(0, 8)

                    delegate: DashboardComponents.TaskRow {
                        width: ListView.view.width
                        taskData: modelData
                        projectTotalHours: root.selectedProject ? root.selectedProject.totalHours : 0
                        accentColour: root.activeAccent
                        onClicked: root.openTask(modelData)
                    }
                }

                // Show more button
                Rectangle {
                    visible: root.selectedProjectTasks.length > 8 && !root.showAllTasks
                    width: parent.width - units.gu(6)
                    height: units.gu(5)
                    anchors.horizontalCenter: parent.horizontalCenter
                    radius: units.gu(1.2)
                    color: root.isDark ? Qt.rgba(1,1,1,0.05) : Qt.rgba(0,0,0,0.05)

                    Label {
                        anchors.centerIn: parent
                        text: i18n.dtr("ubtms", "Show all %1 tasks ↓").arg(root.selectedProjectTasks.length)
                        color: root.activeAccent
                        font.bold: true
                        font.pixelSize: units.dp(13)
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.showAllTasks = true
                    }
                }

                Label {
                    visible: root.selectedProjectTasks.length === 0
                    width: parent.width - units.gu(4)
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: i18n.dtr("ubtms", "No tasks with tracked time")
                    color: Theme.palette.normal.backgroundText
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: units.dp(14)
                }

                // Bottom padding
                Item { width: 1; height: units.gu(3) }
            }
        }
    }

    // ═══════════════════════════════════════════════════
    // ── TASK DETAIL VIEW ──
    // ═══════════════════════════════════════════════════
    Component {
        id: taskView

        Item {
            width: root.width
            implicitHeight: detailsContent.implicitHeight + units.gu(4)

            Column {
                id: detailsContent
                width: parent.width
                spacing: units.gu(2.5)

                // Top padding
                Item { width: 1; height: units.gu(1) }

                    // ── Time Summary Card ──
                    Rectangle {
                        width: parent.width - units.gu(4)
                        height: units.gu(12)
                        anchors.horizontalCenter: parent.horizontalCenter
                        radius: units.gu(1.5)
                        color: root.isDark ? Qt.rgba(1,1,1,0.05) : Qt.rgba(0,0,0,0.03)
                        border.color: root.isDark ? Qt.rgba(root.activeAccent.r, root.activeAccent.g, root.activeAccent.b, 0.3) : Qt.rgba(0,0,0,0.1)
                        border.width: units.dp(1)

                        // Top accent strip
                        Rectangle {
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.leftMargin: units.gu(1.5)
                            anchors.rightMargin: units.gu(1.5)
                            height: units.dp(3)
                            color: root.activeAccent
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: units.gu(2.5)
                            spacing: units.gu(3)

                            Column {
                                Layout.fillWidth: true
                                spacing: units.gu(0.6)

                                Label {
                                    text: i18n.dtr("ubtms", "TIME SPENT")
                                    color: Theme.palette.normal.backgroundText
                                    font.pixelSize: units.dp(11)
                                    font.letterSpacing: 1.0
                                }

                                Label {
                                    text: ChartUtils.formatHours(root.selectedTask ? root.selectedTask.totalHours : 0)
                                    color: root.summaryAccentTextColor
                                    font.bold: true
                                    font.pixelSize: units.dp(20)
                                }
                            }

                            // Divider
                            Rectangle {
                                Layout.preferredWidth: units.dp(1)
                                Layout.fillHeight: true
                                color: root.isDark ? Qt.rgba(1,1,1,0.1) : Qt.rgba(0,0,0,0.1)
                            }

                            Column {
                                Layout.fillWidth: true
                                spacing: units.gu(0.6)

                                Label {
                                    text: i18n.dtr("ubtms", "% OF PROJECT")
                                    color: Theme.palette.normal.backgroundText
                                    font.pixelSize: units.dp(11)
                                    font.letterSpacing: 1.0
                                }

                                Label {
                                    text: ChartUtils.percentLabel(root.selectedTask ? root.selectedTask.totalHours : 0, root.selectedProject ? root.selectedProject.totalHours : 0)
                                    color: root.summaryPrimaryTextColor
                                    font.bold: true
                                    font.pixelSize: units.dp(20)
                                }
                            }
                        }
                    }

                    // ── Task Metadata Card ──
                    Rectangle {
                        width: parent.width - units.gu(4)
                        implicitHeight: detailMeta.implicitHeight + units.gu(4)
                        anchors.horizontalCenter: parent.horizontalCenter
                        radius: units.gu(1.5)
                        color: root.isDark ? Qt.rgba(1,1,1,0.05) : Qt.rgba(0,0,0,0.03)
                        border.color: root.isDark ? Qt.rgba(1,1,1,0.1) : Qt.rgba(0,0,0,0.1)
                        border.width: units.dp(1)

                        Column {
                            id: detailMeta
                            width: parent.width - units.gu(4)
                            anchors.centerIn: parent
                            spacing: units.gu(1.5)

                            Repeater {
                                model: [
                                    { label: i18n.dtr("ubtms", "Assignee"), value: root.selectedTask ? root.selectedTask.assignee : i18n.dtr("ubtms", "Unassigned") },
                                    { label: i18n.dtr("ubtms", "Status"), value: root.selectedTask ? root.selectedTask.status : i18n.dtr("ubtms", "Unknown") },
                                    { label: i18n.dtr("ubtms", "Project"), value: root.selectedProject ? root.selectedProject.name : "" },
                                    { label: i18n.dtr("ubtms", "Log entries"), value: String(root.selectedTaskLogs.length) }
                                ]

                                delegate: RowLayout {
                                    width: parent.width

                                    Label {
                                        Layout.preferredWidth: units.gu(12)
                                        text: modelData.label
                                        color: Theme.palette.normal.backgroundText
                                        font.pixelSize: units.dp(13)
                                    }

                                    Label {
                                        Layout.fillWidth: true
                                        text: modelData.value
                                        color: Theme.palette.normal.baseText
                                        font.pixelSize: units.dp(13)
                                        font.bold: true
                                        horizontalAlignment: Text.AlignRight
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                        }
                    }

                    // ── Time Log Header ──
                    RowLayout {
                        width: parent.width - units.gu(4)
                        anchors.horizontalCenter: parent.horizontalCenter

                        Label {
                            Layout.fillWidth: true
                            text: i18n.dtr("ubtms", "Time log")
                            color: Theme.palette.normal.baseText
                            font.bold: true
                            font.pixelSize: units.dp(15)
                        }

                        Label {
                            text: root.selectedTaskLogs.length + " entries"
                            color: root.isDark ? "#8888AA" : "#999999"
                            font.pixelSize: units.dp(12)
                        }
                    }

                    // ── Time Log List ──
                    ListView {
                        width: parent.width
                        height: contentHeight
                        interactive: false
                        spacing: units.gu(1)
                        model: root.selectedTaskLogs

                        delegate: Rectangle {
                            width: ListView.view.width - units.gu(4)
                            implicitHeight: Math.max(units.gu(8), logRowLayout.implicitHeight + units.gu(3))
                            x: units.gu(2)
                            radius: units.gu(1.2)
                            color: root.isDark ? Qt.rgba(1,1,1,0.05) : Qt.rgba(0,0,0,0.03)
                            border.color: root.isDark ? Qt.rgba(1,1,1,0.1) : Qt.rgba(0,0,0,0.1)
                            border.width: units.dp(1)

                            // Left accent bar
                            Rectangle {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                anchors.leftMargin: units.dp(0)
                                width: units.gu(0.5)
                                radius: width / 2
                                color: root.activeAccent
                            }

                            RowLayout {
                                id: logRowLayout
                                anchors.fill: parent
                                anchors.leftMargin: units.gu(2.5)
                                anchors.rightMargin: units.gu(2)
                                anchors.topMargin: units.gu(1.5)
                                anchors.bottomMargin: units.gu(1.5)
                                spacing: units.gu(2)

                                Column {
                                    Layout.preferredWidth: units.gu(10)
                                    spacing: units.gu(0.3)

                                    Label {
                                        text: modelData.date || ""
                                        color: Theme.palette.normal.baseText
                                        font.pixelSize: units.dp(13)
                                        font.bold: true
                                        elide: Text.ElideRight
                                    }
                                }

                                Label {
                                    Layout.fillWidth: true
                                    text: modelData.note || i18n.dtr("ubtms", "No note")
                                    color: Theme.palette.normal.backgroundText
                                    font.pixelSize: units.dp(13)
                                    wrapMode: Text.WordWrap
                                }

                                Label {
                                    text: ChartUtils.formatHours(modelData.hours || 0)
                                    color: root.activeAccent
                                    font.bold: true
                                    font.pixelSize: units.dp(15)
                                }
                            }
                        }
                    }

                    Label {
                        visible: root.selectedTaskLogs.length === 0
                        width: parent.width - units.gu(4)
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: i18n.dtr("ubtms", "No log entries")
                        color: Theme.palette.normal.backgroundText
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: units.dp(14)
                    }

                    // Bottom padding
                    Item { width: 1; height: units.gu(3) }
                }
            }
        }
    }
