import QtQuick 2.7
import QtQuick.Controls 2.2
import Lomiri.Components 1.3
import "../../models/constants.js" as AppConst

Rectangle {
    id: workItemSelector
    width: parent ? parent.width : Screen.width
    height: contentColumn.implicitHeight
    color: "transparent"

    // Visibility control properties
    property bool showAccountSelector: true
    property bool showProjectSelector: true
    property bool showSubprojectSelector: true
    property bool showTaskSelector: true
    property bool showSubtaskSelector: true
    property bool readOnly: false

    signal datachanged

    function getDbRecordId(localId, odooId) {
        return accountSelector.selectedInstanceId === 0 ? localId : odooId;
    }

    function applyDeferredSelection(accountId, projectOdooId, subProjectOdooId, taskOdooId, subTaskOdooId) {
        accountSelector.shouldDeferSelection = true;
        accountSelector.deferredAccountId = accountId;

        projectSelector.loadDeferred(accountId, projectOdooId);
        subProjectSelector.loadDeferred(accountId, subProjectOdooId);

        taskSelector.loadDeferred(accountId, taskOdooId, projectOdooId);
        subTaskSelector.loadDeferred(accountId, subTaskOdooId, projectOdooId);
    }

    function getAllSelectedDbRecordIds() {
        return {
            accountDbId: accountSelector.selectedInstanceId,
            projectDbId: getDbRecordId(projectSelector.selectedProjectId, projectSelector.getSelectedDbRecordId()),
            subprojectDbId: getDbRecordId(subProjectSelector.selectedProjectId, subProjectSelector.getSelectedDbRecordId()),
            taskDbId: getDbRecordId(taskSelector.selectedTaskId, taskSelector.getSelectedDbRecordId()),
            subtaskDbId: getDbRecordId(subTaskSelector.selectedTaskId, subTaskSelector.getSelectedDbRecordId())
        };
    }

    Column {
        id: contentColumn
        width: parent.width
        spacing: units.gu(1)

        // Account Row
        Row {
            width: parent.width
            //spacing: units.gu(1)
            visible: showAccountSelector
            height: units.gu(5)

            Label {
                text: "Account"
                width: parent.width * 0.25
                verticalAlignment: Text.AlignVCenter
                anchors.verticalCenter: parent.verticalCenter
            }

            Rectangle {
                width: parent.width * 0.75
                height: units.gu(5.5)
                color: "transparent"
                anchors.verticalCenter: parent.verticalCenter
                AccountSelector {
                    id: accountSelector
                    anchors.centerIn: parent
                    enabled: !readOnly
                    editable: true
                    onAccountSelected: {
                        projectSelector.load(accountSelector.selectedInstanceId, 0);
                    }
                }
            }
        }

        // 🔹 Project Row
        Row {
            width: parent.width
            // spacing: units.gu(1)
            visible: showProjectSelector
            height: units.gu(5)

            Label {
                text: "Project"
                width: parent.width * 0.25
                verticalAlignment: Text.AlignVCenter
                anchors.verticalCenter: parent.verticalCenter
            }

            Rectangle {
                width: parent.width * 0.75
                height: units.gu(5.5)
                color: "transparent"
                anchors.verticalCenter: parent.verticalCenter
                ProjectSelector {
                    id: projectSelector
                    enabled: !readOnly
                    anchors.centerIn: parent

                    editable: true
                    onProjectSelected: {
                        console.log("Selecting Project " + projectSelector.selectedProjectId);
                        subProjectSelector.load(accountSelector.selectedInstanceId, projectSelector.selectedProjectId);
                        taskSelector.load(accountSelector.selectedInstanceId, 0, projectSelector.selectedProjectId);
                    }
                }
            }
        }

        // 🔹 Subproject Row
        Row {
            width: parent.width
            // spacing: units.gu(1)
            visible: showSubprojectSelector
            height: units.gu(5)

            Label {
                text: "Subproject"
                width: parent.width * 0.25
                anchors.verticalCenter: parent.verticalCenter
                verticalAlignment: Text.AlignVCenter
            }

            Rectangle {
                width: parent.width * 0.75
                height: units.gu(5.5)
                color: "transparent"
                anchors.verticalCenter: parent.verticalCenter
                ProjectSelector {
                    id: subProjectSelector
                    mode: "subproject"
                    anchors.centerIn: parent
                    enabled: !readOnly
                    editable: true
                    onProjectSelected: {
                        console.log("Selecting Subproject " + subProjectSelector.selectedProjectId);
                        if (subProjectSelector.selectedProjectId != -1) {
                            taskSelector.load(accountSelector.selectedInstanceId, 0, subProjectSelector.selectedProjectId);
                        } else {
                            taskSelector.load(accountSelector.selectedInstanceId, 0, projectSelector.selectedProjectId);
                        }
                    }
                }
            }
        }

        // 🔹 Task Row
        Row {
            width: parent.width
            // spacing: units.gu(1)
            visible: showTaskSelector
            height: units.gu(5)

            Label {
                text: "Task"
                width: parent.width * 0.25
                verticalAlignment: Text.AlignVCenter
                anchors.verticalCenter: parent.verticalCenter
            }

            Rectangle {
                width: parent.width * 0.75
                height: units.gu(5.5)
                color: "transparent"
                anchors.verticalCenter: parent.verticalCenter
                TaskSelector {
                    id: taskSelector
                    anchors.centerIn: parent
                    enabled: !readOnly
                    editable: true
                    onTaskSelected: {
                        console.log("Selecting Task " + taskSelector.selectedTaskId);
                        if (subProjectSelector.selectedProjectId != -1) {
                            subTaskSelector.load(accountSelector.selectedInstanceId, taskSelector.selectedTaskId, subProjectSelector.selectedProjectId);
                        } else {
                            subTaskSelector.load(accountSelector.selectedInstanceId, taskSelector.selectedTaskId, projectSelector.selectedProjectId);
                        }
                    }
                }
            }
        }

        // 🔹 Subtask Row
        Row {
            width: parent.width
            // spacing: units.gu(1)
            visible: showSubtaskSelector
            height: units.gu(5)

            Label {
                text: "Subtask"
                width: parent.width * 0.25
                anchors.verticalCenter: parent.verticalCenter
                verticalAlignment: Text.AlignVCenter
            }

            Rectangle {
                width: parent.width * 0.75
                height: units.gu(5.5)
                color: "transparent"
                anchors.verticalCenter: parent.verticalCenter
                TaskSelector {
                    id: subTaskSelector
                    enabled: !readOnly
                    mode: "subtask"
                    anchors.centerIn: parent
                    onTaskSelected: {}
                }
            }
        }
    }
}
