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
    property string accountLabelText: "Account"
    property string projectLabelText: "Project"
    property string subprojectLabelText: "Subproject"
    property string taskLabelText: "Task"
    property string subtaskLabelText: "Subtask"

    signal datachanged
    signal accountChanged(int accountId)

    function getDbRecordId(localId, odooId) {
        return accountSelector.selectedInstanceId === 0 ? localId : odooId;
    }

    function applyDeferredSelection(accountId, projectOdooId, subProjectOdooId, taskOdooId, subTaskOdooId) {
        console.log("🧩 applyDeferredSelection →", accountId, projectOdooId, subProjectOdooId, taskOdooId, subTaskOdooId);

        if (accountSelector.model.count === 0) {
            console.log("⏳ AccountSelector model not loaded yet → retrying via timer...");
            deferredApplyTimer.deferredPayload = {
                accountId,
                projectOdooId,
                subProjectOdooId,
                taskOdooId,
                subTaskOdooId
            };
            deferredApplyTimer.start();
            return;
        }

        deferredApplyTimer.stop(); // Just in case
        accountSelector.selectAccountById(accountId);
        projectSelector.loadDeferred(accountId, projectOdooId);
        subProjectSelector.loadDeferred(accountId, subProjectOdooId);
        taskSelector.loadDeferred(accountId, taskOdooId);
        subTaskSelector.loadDeferred(accountId, subTaskOdooId);
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
            TSLabel {
                width: parent.width * 0.25
                anchors.verticalCenter: parent.verticalCenter

                text: accountLabelText
                verticalAlignment: Text.AlignVCenter
            }

            Item {
                width: parent.width * 0.75
                height: units.gu(5)
                // color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "grey" : "transparent"
                anchors.verticalCenter: parent.verticalCenter
                AccountSelector {
                    id: accountSelector
                    anchors.centerIn: parent
                    anchors.verticalCenter: parent.verticalCenter
                    enabled: !readOnly
                    editable: false
                    onAccountSelected: {
                        console.log("✅ [WorkItemSelector] Account selected:", accountSelector.selectedInstanceId);
                        console.log("→ loading projectSelector...");
                        projectSelector.load(accountSelector.selectedInstanceId, 0);
                        accountChanged(accountSelector.selectedInstanceId); //give to the extenral world
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

            TSLabel {
                width: parent.width * 0.25
                anchors.verticalCenter: parent.verticalCenter
                text: projectLabelText
                verticalAlignment: Text.AlignVCenter
            }

            Item {
                width: parent.width * 0.75
                height: units.gu(5)

                anchors.verticalCenter: parent.verticalCenter
                ProjectSelector {
                    id: projectSelector
                    enabled: !readOnly
                    anchors.centerIn: parent

                    editable: false
                    onProjectSelected: {
                        console.log("➡️ [ProjectSelector] Defer Load → accountId:", accountSelector.selectedInstanceId, "projectId:", projectSelector.selectedProjectId);
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

            TSLabel {
                width: parent.width * 0.25
                anchors.verticalCenter: parent.verticalCenter
                aspect: LomiriShape.Flat
                text: subprojectLabelText
                verticalAlignment: Text.AlignVCenter
            }

            Item {
                width: parent.width * 0.75
                height: units.gu(5)
                //   color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "grey" : "transparent"
                anchors.verticalCenter: parent.verticalCenter
                ProjectSelector {
                    id: subProjectSelector
                    mode: "subproject"
                    anchors.centerIn: parent
                    enabled: !readOnly
                    editable: false
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

            TSLabel {
                width: parent.width * 0.25
                anchors.verticalCenter: parent.verticalCenter
                text: taskLabelText
                verticalAlignment: Text.AlignVCenter
            }

            Item {
                width: parent.width * 0.75
                height: units.gu(5)
                //  color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "grey" : "transparent"
                anchors.verticalCenter: parent.verticalCenter
                TaskSelector {
                    id: taskSelector
                    anchors.centerIn: parent
                    enabled: !readOnly
                    editable: false
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

            TSLabel {
                width: parent.width * 0.25
                anchors.verticalCenter: parent.verticalCenter
                text: subtaskLabelText
                verticalAlignment: Text.AlignVCenter
            }

            Item {
                width: parent.width * 0.75
                height: units.gu(5)
                //   color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "grey" : "transparent"
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
        Timer {
            id: deferredApplyTimer
            interval: 100   // 100ms retry interval
            repeat: true
            running: false
            property var deferredPayload: null

            onTriggered: {
                if (!deferredPayload || accountSelector.model.count === 0) {
                    console.log("⏳ Timer: Waiting for model to load...");
                    return;
                }

                console.log("⏱ Timer: Retrying deferred apply...");
                deferredApplyTimer.stop();
                let p = deferredApplyTimer.deferredPayload;
                deferredPayload = null;

                accountSelector.selectAccountById(p.accountId);
                projectSelector.loadDeferred(p.accountId, p.projectOdooId);
                subProjectSelector.loadDeferred(p.accountId, p.subProjectOdooId);
                taskSelector.loadDeferred(p.accountId, p.taskOdooId);
                subTaskSelector.loadDeferred(p.accountId, p.subTaskOdooId);
            }
        }
    }
}
