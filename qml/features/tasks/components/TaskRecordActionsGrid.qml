import QtQuick 2.7
import Lomiri.Components 1.3
import "../../../components"
import "../../../../models/task.js" as Task

Grid {
    id: root

    property var currentTask: null
    property int recordid: 0

    signal changeStageRequested()
    signal createActivityRequested()
    signal viewActivitiesRequested()
    signal createTimesheetRequested()
    signal viewTimesheetsRequested()

    visible: recordid !== 0
    height: visible ? childrenRect.height : 0
    columns: 3
    rows: 3
    spacing: units.gu(1)
    rowSpacing: units.gu(1)
    columnSpacing: units.gu(1)

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
        text: root.currentTask && root.currentTask.state ? Task.getTaskStageName(root.currentTask.state, root.currentTask.account_id) : i18n.dtr("ubtms", "Not set")
        width: (parent.width - (2 * parent.columnSpacing)) / 3
        height: units.gu(6)
        fontBold: true
        color: {
            if (!root.currentTask || !root.currentTask.state)
                return theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#888" : "#666";

            var stageName = Task.getTaskStageName(root.currentTask.state, root.currentTask.account_id).toLowerCase();
            if (stageName === "completed" || stageName === "finished" || stageName === "closed" || stageName === "verified" || stageName === "done")
                return "green";

            return "#f97316";
        }
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
    }

    TSButton {
        visible: root.recordid !== 0
        bgColor: "#f3f4f6"
        fgColor: "#1f2937"
        hoverColor: "#d1d5db"
        borderColor: "#d1d5db"
        fontBold: true
        iconName: "filters"
        iconColor: "#1f2937"
        width: (parent.width - (2 * parent.columnSpacing)) / 3
        height: units.gu(6)
        text: i18n.dtr("ubtms", "Change")
        onClicked: root.changeStageRequested()
    }

    TSLabel {
        text: i18n.dtr("ubtms", "Activities")
        width: (parent.width - (2 * parent.columnSpacing)) / 3
        height: units.gu(6)
        horizontalAlignment: Text.AlignHLeft
        verticalAlignment: Text.AlignVCenter
        fontBold: true
        color: "#f97316"
    }

    TSButton {
        visible: root.recordid !== 0
        bgColor: "#fef1e7"
        fgColor: "#f97316"
        hoverColor: "#f3e0d1"
        iconName: "add"
        iconColor: "#f97316"
        fontBold: true
        width: (parent.width - (2 * parent.columnSpacing)) / 3
        height: units.gu(6)
        text: i18n.dtr("ubtms", "Create")
        onClicked: root.createActivityRequested()
    }

    TSButton {
        visible: root.recordid !== 0
        bgColor: "#f3f4f6"
        fgColor: "#1f2937"
        hoverColor: "#d1d5db"
        borderColor: "#d1d5db"
        fontBold: true
        iconName: "filters"
        iconColor: "#1f2937"
        width: (parent.width - (2 * parent.columnSpacing)) / 3
        height: units.gu(6)
        text: i18n.dtr("ubtms", "View")
        onClicked: root.viewActivitiesRequested()
    }

    TSLabel {
        text: i18n.dtr("ubtms", "Timesheets")
        width: (parent.width - (2 * parent.columnSpacing)) / 3
        height: units.gu(6)
        horizontalAlignment: Text.AlignHLeft
        verticalAlignment: Text.AlignVCenter
        fontBold: true
        color: "#f97316"
    }

    TSButton {
        visible: root.recordid !== 0
        bgColor: "#fef1e7"
        fgColor: "#f97316"
        hoverColor: "#f3e0d1"
        iconName: "add"
        iconColor: "#f97316"
        fontBold: true
        width: (parent.width - (2 * parent.columnSpacing)) / 3
        height: units.gu(6)
        text: i18n.dtr("ubtms", "Create")
        onClicked: root.createTimesheetRequested()
    }

    TSButton {
        visible: root.recordid !== 0
        bgColor: "#f3f4f6"
        fgColor: "#1f2937"
        hoverColor: "#d1d5db"
        borderColor: "#d1d5db"
        fontBold: true
        iconName: "filters"
        iconColor: "#1f2937"
        width: (parent.width - (2 * parent.columnSpacing)) / 3
        height: units.gu(6)
        text: i18n.dtr("ubtms", "View")
        onClicked: root.viewTimesheetsRequested()
    }
}
