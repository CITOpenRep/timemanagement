import QtQuick 2.7
import Lomiri.Components 1.3
import "../models/accounts.js" as Accounts

Page {
    id: syncLogPage
    title: i18n.dtr("ubtms", "Sync Log")
    property var syncLogs: []
    property var recordid: -1

    header: PageHeader {
        id: pageHeader
        StyleHints {
            foregroundColor: "white"
            backgroundColor: LomiriColors.orange
            dividerColor: LomiriColors.slate
        }
        title: syncLogPage.title
        trailingActionBar.actions: [
            Action {
                iconName: "edit-copy"
                text: i18n.dtr("ubtms", "Copy Logs")
                onTriggered: {
                    var combined = "Sync Logs for Account ID: " + recordid + "\n";
                    combined += "=====================================\n\n";
                    for (var i = 0; i < syncLogs.length; i++) {
                        var log = syncLogs[i];
                        combined += "[" + log.level + "] ";
                        if (log.timestamp) combined += log.timestamp + " ";
                        combined += log.message;
                        if (log.filename || log.lineno) {
                            combined += " (" + (log.filename || "") + (log.lineno ? ":" + log.lineno : "") + ")";
                        }
                        combined += "\n\n";
                    }
                    Clipboard.push(combined);
                }
            }
        ]
    }

    Component.onCompleted: {
        console.log("SyncLog.qml: Loading logs for account_id:", recordid);
        var allLogs = Accounts.fetchParsedSyncLog(recordid);
        console.log("SyncLog.qml: Total logs fetched:", allLogs.length);
        syncLogs = allLogs.filter(function (log) {
            return log.level === "ERROR" || log.level === "WARNING";
        });
        console.log("SyncLog.qml: Filtered logs (ERROR/WARNING):", syncLogs.length);
        
        // If no logs found, show debug info
        if (syncLogs.length === 0) {
            console.log("SyncLog.qml: No ERROR/WARNING logs found for account_id:", recordid);
        }
    }

    ListView {
        id: logListView
        anchors.fill: parent
        anchors.margins: units.gu(1)
        anchors.topMargin: pageHeader.height + units.gu(1)
        clip: true
        spacing: units.gu(1)

        model: syncLogs
        delegate: Item {
            width: logListView.width
            height: contentColumn.height + units.gu(2)

            Rectangle {
                id: logEntryRect
                anchors.fill: parent
                anchors.leftMargin: units.gu(0.5)
                anchors.rightMargin: units.gu(0.5)

                color: getColorByLevel(modelData.level)
                border.color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#444" : "#ccc"
                border.width: 1
                radius: units.gu(0.5)

                Column {
                    id: contentColumn
                    width: parent.width - units.gu(2)
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: units.gu(1)
                    spacing: units.gu(0.5)
                    
                    // Header row with level and timestamp
                    Row {
                        width: parent.width
                        spacing: units.gu(1)
                        
                        Rectangle {
                            width: units.gu(8)
                            height: units.gu(2.5)
                            color: modelData.level === "ERROR" ? "#d32f2f" : "#f57c00"
                            radius: units.gu(0.3)
                            
                            Text {
                                anchors.centerIn: parent
                                text: modelData.level
                                font.pixelSize: units.gu(1.3)
                                font.bold: true
                                color: "white"
                            }
                        }
                        
                        Text {
                            width: parent.width - units.gu(9)
                            text: modelData.timestamp || ""
                            font.pixelSize: units.gu(1.2)
                            color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#888" : "#666"
                            anchors.verticalCenter: parent.verticalCenter
                            wrapMode: Text.Wrap
                        }
                    }
                    
                    // Message text
                    Text {
                        id: textItem
                        width: parent.width
                        text: modelData.message || ""
                        font.pixelSize: units.gu(1.5)
                        wrapMode: Text.Wrap
                        color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#e0e0e0" : "#000"
                    }
                    
                    // Source info (filename and line number)
                    Text {
                        width: parent.width
                        text: (modelData.filename || "") + (modelData.lineno ? ":" + modelData.lineno : "")
                        font.pixelSize: units.gu(1.1)
                        font.italic: true
                        color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#666" : "#999"
                        visible: modelData.filename || modelData.lineno
                        wrapMode: Text.Wrap
                    }
                }
            }
        }
        
        // Empty state message
        Text {
            anchors.centerIn: parent
            visible: syncLogs.length === 0
            text: i18n.dtr("ubtms", "No errors or warnings found for this account.\nSync logs will appear here when issues occur.")
            font.pixelSize: units.gu(2)
            color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#888" : "#666"
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            width: parent.width - units.gu(4)
        }
    }

    function getColorByLevel(level) {
        switch (level) {
        case "ERROR":
            return "#ec9f9f";
        case "WARNING":
            return "#c9ba4a";
        case "DEBUG":
            return "#eef6ff";
        case "INFO":
            return "#00fa00";
        default:
            return "#f5f5f5";
        }
    }
}
