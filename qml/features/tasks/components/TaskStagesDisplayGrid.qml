import QtQuick 2.7
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import "../../../components"
import "../../../../models/task.js" as Task
import "../../../../models/accounts.js" as Accounts

Grid {
    id: currentStageRow
    
    property var currentTask: null
    property int recordid: 0
    
    signal changeStageClicked(var taskId, var accountId, var currentStageId)
    signal changePersonalStageClicked(var taskId, var accountId, var userId, var currentPersonalStageId)
    
    visible: recordid !== 0
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.leftMargin: units.gu(1)
    anchors.rightMargin: units.gu(1)
    anchors.topMargin: units.gu(1)
    columns: 3
    rows: 3
    spacing: units.gu(1)
    rowSpacing: units.gu(1)
    columnSpacing: units.gu(1)

    // Row 1: Current Stage
    TSLabel {
        text: i18n.dtr("ubtms", "Current Stage:")
        width: (parent.width - (2 * parent.columnSpacing)) / 3
        height: units.gu(6)
        horizontalAlignment: Text.AlignHLeft
        verticalAlignment: Text.AlignVCenter
        fontBold: true
        color: "#f97316"
    }

    TSLabel {
        text: currentTask && currentTask.state ? Task.getTaskStageName(currentTask.state, currentTask.account_id) : i18n.dtr("ubtms", "Not set")
        width: (parent.width - (2 * parent.columnSpacing)) / 3
        height: units.gu(6)
        fontBold: true
        color: {
            if (!currentTask || !currentTask.state) {
                return theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#888" : "#666";
            }
            var stageName = Task.getTaskStageName(currentTask.state, currentTask.account_id).toLowerCase();
            if (stageName === "completed" || stageName === "finished" || stageName === "closed" || stageName === "verified" || stageName === "done") {
                return "green";
            }
            return "#f97316";
        }
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
    }

    TSButton {
        visible: recordid !== 0
        bgColor: "#f3f4f6"
        fgColor: "#1f2937"
        hoverColor: '#d1d5db'
        width: (parent.width - (2 * parent.columnSpacing)) / 3
        height: units.gu(6)
        text: i18n.dtr("ubtms", "Change Stage")
        onClicked: {
            if (!currentTask || !currentTask.id) {
                return;
            }
            changeStageClicked(currentTask.id, currentTask.account_id, currentTask.state || -1);
        }
    }

    // Row 2: Separator Line
    Rectangle {
        width: parent.width
        height: units.dp(1)
        color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#333" : "#e5e7eb"
    }
    Item { width: 1; height: 1 }
    Item { width: 1; height: 1 }

    // Row 3: Current Personal Stage
    TSLabel {
        text: i18n.dtr("ubtms", "Current Personal Stage:")
        width: (parent.width - (2 * parent.columnSpacing)) / 3
        height: units.gu(6)
        horizontalAlignment: Text.AlignHLeft
        verticalAlignment: Text.AlignVCenter
        fontBold: true
        color: "#f97316"
    }

    TSLabel {
        text: {
            if (!currentTask || !currentTask.personal_stage || currentTask.personal_stage === -1) {
                return i18n.dtr("ubtms", "Not set");
            }
            return Task.getTaskStageName(currentTask.personal_stage, currentTask.account_id);
        }
        width: (parent.width - (2 * parent.columnSpacing)) / 3
        height: units.gu(6)
        fontBold: true
        color: {
            if (!currentTask || !currentTask.personal_stage || currentTask.personal_stage === -1) {
                return theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#888" : "#666";
            }
            var pStageName = Task.getTaskStageName(currentTask.personal_stage, currentTask.account_id).toLowerCase();
            if (pStageName === "completed" || pStageName === "finished" || pStageName === "closed" || pStageName === "verified" || pStageName === "done") {
                return "green";
            }
            return "#f97316";
        }
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
    }

    TSButton {
        visible: recordid !== 0
        bgColor: "#f3f4f6"
        fgColor: "#1f2937"
        hoverColor: '#d1d5db'
        width: (parent.width - (2 * parent.columnSpacing)) / 3
        height: units.gu(6)
        text: i18n.dtr("ubtms", "Change Personal Stage")
        onClicked: {
            if (!currentTask || !currentTask.id) {
                return;
            }
            var userId = Accounts.getCurrentUserOdooId(currentTask.account_id);
            if (userId <= 0) {
                return;
            }
            changePersonalStageClicked(currentTask.id, currentTask.account_id, userId, currentTask.personal_stage || -1);
        }
    }
}
