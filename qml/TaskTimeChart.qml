// Lightweight time tracking drilldown with direct project, task, and log views.
import QtQuick 2.12
import Lomiri.Components 1.3
import QtQuick.Layouts 1.12
import "chartUtils.js" as ChartUtils

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

    readonly property var visibleProjects: ChartUtils.prepareProjects(projectsModel, portfolioSortMode, portfolioSearchText)
    readonly property real portfolioTotalHours: ChartUtils.sumProjectHours(projectsModel)
    readonly property real portfolioMaxHours: ChartUtils.maxProjectHours(projectsModel)
    readonly property var topProjectTasks: ChartUtils.topTasks(selectedProjectTasks, 10)

    function openProject(projectData) {
        if (!projectData) {
            return;
        }

        selectedProject = projectData;
        selectedTask = null;
        selectedTaskLogs = [];
        showAllTasks = false;
        selectedProjectTasks = projectTasksProvider ? ChartUtils.prepareTasks(projectTasksProvider(projectData.id) || []) : [];
        currentView = "project";
        projectOpened(projectData.id);
    }

    function openTask(taskData) {
        if (!selectedProject || !taskData) {
            return;
        }

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

    Rectangle {
        anchors.fill: parent
        color: Theme.palette.normal.background
    }

    Column {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            id: headerBar
            width: parent.width
            height: units.gu(8)
            color: Theme.palette.normal.base

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: units.gu(1.5)
                anchors.rightMargin: units.gu(1.5)
                spacing: units.gu(1)

                Button {
                    visible: root.currentView !== "projects"
                    text: i18n.dtr("ubtms", "Back")
                    Layout.preferredWidth: units.gu(9)
                    onClicked: root.goBack()
                }

                Column {
                    Layout.fillWidth: true
                    spacing: 0

                    Label {
                        width: parent.width
                        text: root.currentView === "projects" ? i18n.dtr("ubtms", "Projects")
                             : root.currentView === "project" ? (root.selectedProject ? root.selectedProject.name : "")
                             : (root.selectedTask ? root.selectedTask.name : "")
                        color: Theme.palette.normal.baseText
                        font.bold: true
                        font.pixelSize: units.dp(15)
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

                Label {
                    visible: root.currentView === "projects"
                    text: ChartUtils.formatHours(root.portfolioTotalHours)
                    color: Theme.palette.normal.baseText
                    font.bold: true
                    font.pixelSize: units.dp(13)
                }
            }
        }

        Loader {
            id: contentLoader
            width: parent.width
            height: parent.height - headerBar.height
            sourceComponent: root.currentView === "projects" ? projectsView
                            : root.currentView === "project" ? projectView
                            : taskView
        }
    }

    Component {
        id: projectsView

        Item {
            Flickable {
                id: projectFlick
                anchors.fill: parent
                contentWidth: width
                contentHeight: projectContent.height + units.gu(2)
                clip: true

                Column {
                    id: projectContent
                    width: projectFlick.width
                    spacing: units.gu(1.2)

                    Rectangle {
                        width: parent.width
                        height: units.gu(11)
                        color: Theme.palette.normal.background

                        Column {
                            anchors.fill: parent
                            anchors.margins: units.gu(1.5)
                            spacing: units.gu(1)

                            TextField {
                                width: parent.width
                                placeholderText: i18n.dtr("ubtms", "Search projects...")
                                text: root.portfolioSearchText
                                onTextChanged: root.portfolioSearchText = text
                                // Sleek rounded search styling (assumes TextField supports this or we just use default with padding)
                                color: Theme.palette.normal.baseText
                            }

                            Row {
                                width: parent.width
                                spacing: units.gu(1)

                                Repeater {
                                    model: [
                                        { label: i18n.dtr("ubtms", "Most time"), value: "time" },
                                        { label: i18n.dtr("ubtms", "Tasks"), value: "tasks" },
                                        { label: i18n.dtr("ubtms", "A-Z"), value: "name" }
                                    ]

                                    delegate: Rectangle {
                                        width: (parent.width - (units.gu(1) * 2)) / 3
                                        height: units.gu(4.5)
                                        radius: height / 2
                                        color: root.portfolioSortMode === modelData.value ? Theme.palette.selected.background : Theme.palette.normal.base
                                        border.color: root.portfolioSortMode === modelData.value ? "transparent" : Theme.palette.normal.backgroundText
                                        border.width: root.portfolioSortMode === modelData.value ? 0 : 1

                                        Label {
                                            anchors.centerIn: parent
                                            text: modelData.label
                                            color: root.portfolioSortMode === modelData.value ? "white" : Theme.palette.normal.baseText
                                            font.pixelSize: units.dp(13)
                                            font.bold: root.portfolioSortMode === modelData.value
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: root.portfolioSortMode = modelData.value
                                        }
                                    }
                                }
                            }
                        }
                    }

                    ListView {
                        width: parent.width
                        height: contentHeight
                        interactive: false
                        spacing: units.gu(0.8)
                        model: root.visibleProjects

                        delegate: ProjectCard {
                            width: ListView.view.width
                            projectData: modelData.projectData
                            maxHours: Math.max(root.portfolioMaxHours, 0.1)
                            onClicked: root.openProject(modelData.projectData)
                        }
                    }

                    Label {
                        visible: root.visibleProjects.length === 0
                        width: parent.width - units.gu(3)
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: i18n.dtr("ubtms", "No projects found")
                        color: Theme.palette.normal.backgroundText
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }
        }
    }

    Component {
        id: projectView

        Item {
            Flickable {
                id: taskFlick
                anchors.fill: parent
                contentWidth: width
                contentHeight: taskContent.height + units.gu(2)
                clip: true

                Column {
                    id: taskContent
                    width: taskFlick.width
                    spacing: units.gu(1.2)

                    Rectangle {
                        width: parent.width - units.gu(3)
                        height: units.gu(12)
                        anchors.horizontalCenter: parent.horizontalCenter
                        radius: units.gu(1.5)
                        color: Theme.palette.normal.base

                        // Subtle inner background to make it look like a dashboard widget
                        Rectangle {
                            anchors.fill: parent
                            radius: parent.radius
                            color: Theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#1AFFFFFF" : "#0A000000"
                        }

                        Grid {
                            anchors.fill: parent
                            anchors.margins: units.gu(2)
                            columns: 2
                            spacing: units.gu(1.5)

                            Repeater {
                                model: [
                                    { label: i18n.dtr("ubtms", "Total"), value: ChartUtils.formatHours(root.selectedProject ? root.selectedProject.totalHours : 0) },
                                    { label: i18n.dtr("ubtms", "Tasks"), value: String(root.selectedProjectTasks.length) },
                                    { label: i18n.dtr("ubtms", "Average"), value: ChartUtils.averageLabel(root.selectedProject ? root.selectedProject.totalHours : 0, root.selectedProjectTasks.length) },
                                    { label: i18n.dtr("ubtms", "Top task"), value: ChartUtils.topTaskName(root.selectedProjectTasks) }
                                ]

                                delegate: Column {
                                    width: (parent.width - units.gu(1.5)) / 2
                                    spacing: units.gu(0.4)

                                    Label {
                                        text: modelData.label
                                        color: Theme.palette.normal.backgroundText
                                        font.pixelSize: units.dp(11)
                                        font.capitalization: Font.AllUppercase
                                        font.letterSpacing: 0.5
                                    }

                                    Label {
                                        width: parent.width
                                        text: modelData.value
                                        color: Theme.palette.normal.baseText
                                        font.bold: true
                                        font.pixelSize: units.dp(14)
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                        }
                    }

                    TaskChartCanvas {
                        width: parent.width - units.gu(3)
                        anchors.horizontalCenter: parent.horizontalCenter
                        tasksData: root.topProjectTasks
                        accentColour: root.selectedProject ? root.selectedProject.colour : Theme.palette.selected.background
                        onTaskSelected: {
                            var task = ChartUtils.findTaskById(root.selectedProjectTasks, taskId)
                            if (task) {
                                root.openTask(task)
                            }
                        }
                    }

                    ListView {
                        width: parent.width
                        height: contentHeight
                        interactive: false
                        spacing: units.gu(0.6)
                        model: root.showAllTasks ? root.selectedProjectTasks : root.selectedProjectTasks.slice(0, 8)

                        delegate: TaskRow {
                            width: ListView.view.width
                            taskData: modelData
                            projectTotalHours: root.selectedProject ? root.selectedProject.totalHours : 0
                            accentColour: root.selectedProject ? root.selectedProject.colour : Theme.palette.selected.background
                            onClicked: root.openTask(modelData)
                        }
                    }

                    Button {
                        visible: root.selectedProjectTasks.length > 8 && !root.showAllTasks
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: i18n.dtr("ubtms", "Show all %1 tasks").arg(root.selectedProjectTasks.length)
                        onClicked: root.showAllTasks = true
                    }

                    Label {
                        visible: root.selectedProjectTasks.length === 0
                        width: parent.width - units.gu(3)
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: i18n.dtr("ubtms", "No tasks with tracked time")
                        color: Theme.palette.normal.backgroundText
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }
        }
    }

    Component {
        id: taskView

        Item {
            Flickable {
                id: detailsFlick
                anchors.fill: parent
                contentWidth: width
                contentHeight: detailsContent.height + units.gu(2)
                clip: true

                Column {
                    id: detailsContent
                    width: detailsFlick.width
                    spacing: units.gu(1.2)

                    Rectangle {
                        width: parent.width - units.gu(3)
                        height: units.gu(10)
                        anchors.horizontalCenter: parent.horizontalCenter
                        radius: units.gu(1.5)
                        color: Theme.palette.normal.base

                        Rectangle {
                            anchors.fill: parent
                            radius: parent.radius
                            color: Theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#1AFFFFFF" : "#0A000000"
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: units.gu(2)
                            spacing: units.gu(2)

                            Column {
                                Layout.fillWidth: true
                                spacing: units.gu(0.4)

                                Label {
                                    text: i18n.dtr("ubtms", "Time spent")
                                    color: Theme.palette.normal.backgroundText
                                    font.pixelSize: units.dp(12)
                                    font.capitalization: Font.AllUppercase
                                    font.letterSpacing: 0.5
                                }

                                Label {
                                    text: ChartUtils.formatHours(root.selectedTask ? root.selectedTask.totalHours : 0)
                                    color: Theme.palette.normal.baseText
                                    font.bold: true
                                    font.pixelSize: units.dp(16)
                                }
                            }

                            Column {
                                Layout.fillWidth: true
                                spacing: units.gu(0.4)

                                Label {
                                    text: i18n.dtr("ubtms", "% of project")
                                    color: Theme.palette.normal.backgroundText
                                    font.pixelSize: units.dp(12)
                                    font.capitalization: Font.AllUppercase
                                    font.letterSpacing: 0.5
                                }

                                Label {
                                    text: ChartUtils.percentLabel(root.selectedTask ? root.selectedTask.totalHours : 0, root.selectedProject ? root.selectedProject.totalHours : 0)
                                    color: Theme.palette.normal.baseText
                                    font.bold: true
                                    font.pixelSize: units.dp(16)
                                }
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width - units.gu(3)
                        height: detailMeta.implicitHeight + units.gu(3)
                        anchors.horizontalCenter: parent.horizontalCenter
                        radius: units.gu(1)
                        color: Theme.palette.normal.base

                        Column {
                            id: detailMeta
                            anchors.fill: parent
                            anchors.margins: units.gu(1.5)
                            spacing: units.gu(1)

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
                                        font.pixelSize: units.dp(12)
                                    }

                                    Label {
                                        Layout.fillWidth: true
                                        text: modelData.value
                                        color: Theme.palette.normal.baseText
                                        font.pixelSize: units.dp(12)
                                        horizontalAlignment: Text.AlignRight
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                        }
                    }

                    Label {
                        width: parent.width - units.gu(3)
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: i18n.dtr("ubtms", "Time log")
                        color: Theme.palette.normal.baseText
                        font.bold: true
                        font.pixelSize: units.dp(14)
                    }

                    ListView {
                        width: parent.width
                        height: contentHeight
                        interactive: false
                        spacing: units.gu(0.5)
                        model: root.selectedTaskLogs

                        delegate: Rectangle {
                            width: ListView.view.width - units.gu(3)
                            implicitHeight: Math.max(units.gu(8), rowLayout.implicitHeight + units.gu(2))
                            x: units.gu(1.5)
                            radius: units.gu(1)
                            color: Theme.palette.normal.base

                            // Left accent line
                            Rectangle {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: units.gu(0.5)
                                color: Theme.palette.selected.background
                                // Use a mask or simply let it overlap (often safe if corner radius is small, but let's avoid clipping issues by using layer if needed, or just let it be)
                            }

                            RowLayout {
                                id: rowLayout
                                anchors.fill: parent
                                anchors.leftMargin: units.gu(2)
                                anchors.rightMargin: units.gu(1.5)
                                anchors.topMargin: units.gu(1)
                                anchors.bottomMargin: units.gu(1)
                                spacing: units.gu(1.5)

                                Column {
                                    Layout.preferredWidth: units.gu(10)
                                    spacing: units.gu(0.3)
                                    
                                    Label {
                                        text: modelData.date || ""
                                        color: Theme.name === "Ubuntu.Components.Themes.SuruDark" ? "white" : Theme.palette.normal.baseText
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
                                    color: Theme.palette.selected.background
                                    font.bold: true
                                    font.pixelSize: units.dp(15)
                                }
                            }
                        }
                    }

                    Label {
                        visible: root.selectedTaskLogs.length === 0
                        width: parent.width - units.gu(3)
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: i18n.dtr("ubtms", "No log entries")
                        color: Theme.palette.normal.backgroundText
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }
        }
    }
}
