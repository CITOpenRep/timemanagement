import QtQuick 2.7
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3

Dialog {
    id: chartInfoPopup
    title: i18n.dtr("ubtms", "Dashboard Charts Guide")
    
    Flickable {
        width: parent.width
        height: Math.min(units.gu(40), contentHeight)
        contentWidth: width
        contentHeight: contentCol.implicitHeight
        clip: true
        
        Column {
            id: contentCol
            width: parent.width
            spacing: units.gu(2)
            
            Label {
                width: parent.width
                wrapMode: Text.WordWrap
                text: i18n.dtr("ubtms", "Welcome to the Dashboard! Here is a quick guide to help you understand your data:")
                font.weight: Font.DemiBold
            }
            
            // Priority Matrix
            Item { width: 1; height: units.gu(1) }
            Label {
                width: parent.width
                wrapMode: Text.WordWrap
                text: "📌 " + i18n.dtr("ubtms", "Priority Matrix (Chart 1 & 2)")
                font.weight: Font.DemiBold
                color: LomiriColors.blue
            }
            Label {
                width: parent.width
                wrapMode: Text.WordWrap
                text: i18n.dtr("ubtms", "These charts give you an overview of where your time goes. Check if you are spending time on high-priority tasks or getting bogged down by low-priority ones.")
                font.pixelSize: units.dp(14)
            }

            // Projectwise Time Spent
            Item { width: 1; height: units.gu(1) }
            Label {
                width: parent.width
                wrapMode: Text.WordWrap
                text: "📊 " + i18n.dtr("ubtms", "Projectwise Time Spent (Chart 3)")
                font.weight: Font.DemiBold
                color: LomiriColors.blue
            }
            Label {
                width: parent.width
                wrapMode: Text.WordWrap
                text: i18n.dtr("ubtms", "This horizontal bar chart compares the total hours spent across different projects. You can incrementally load more projects using the buttons at the bottom. Hover over any bar to see the exact hours.")
                font.pixelSize: units.dp(14)
            }

            // Taskwise Time Spent
            Item { width: 1; height: units.gu(1) }
            Label {
                width: parent.width
                wrapMode: Text.WordWrap
                text: "📋 " + i18n.dtr("ubtms", "Task Drilldown (Chart 4)")
                font.weight: Font.DemiBold
                color: LomiriColors.blue
            }
            Label {
                width: parent.width
                wrapMode: Text.WordWrap
                text: i18n.dtr("ubtms", "Tap on any project to drill down into its tasks. You can further tap on a task to view the detailed timesheet logs. This is highly useful for auditing exactly where your time was spent.")
                font.pixelSize: units.dp(14)
            }

            // Status Colors
            Item { width: 1; height: units.gu(1) }
            Label {
                width: parent.width
                wrapMode: Text.WordWrap
                text: "🎨 " + i18n.dtr("ubtms", "What Do The Colors Mean?")
                font.weight: Font.DemiBold
                color: LomiriColors.blue
            }
            Label {
                width: parent.width
                wrapMode: Text.WordWrap
                text: i18n.dtr("ubtms", "Projects and tasks are color-coded based on their current stage to give you immediate visual feedback:")
                font.pixelSize: units.dp(14)
            }
            
            Row {
                spacing: units.gu(1)
                Rectangle { width: units.gu(2); height: units.gu(2); radius: width/2; color: "#388E3C" }
                Label { text: i18n.dtr("ubtms", "Green: Done / Completed") }
            }
            Row {
                spacing: units.gu(1)
                Rectangle { width: units.gu(2); height: units.gu(2); radius: width/2; color: "#D32F2F" }
                Label { text: i18n.dtr("ubtms", "Red: Cancelled") }
            }
            Row {
                spacing: units.gu(1)
                Rectangle { width: units.gu(2); height: units.gu(2); radius: width/2; color: "#F57C00" }
                Label { text: i18n.dtr("ubtms", "Orange: On Hold / Paused") }
            }
            Row {
                spacing: units.gu(1)
                Rectangle { width: units.gu(2); height: units.gu(2); radius: width/2; color: LomiriColors.blue }
                Label { text: i18n.dtr("ubtms", "Blue / Other: In Progress") }
            }
            
            Item { width: 1; height: units.gu(2) }
        }
    }
    
    Button {
        text: i18n.dtr("ubtms", "Got it!")
        color: LomiriColors.blue
        onClicked: PopupUtils.close(chartInfoPopup)
    }
}
