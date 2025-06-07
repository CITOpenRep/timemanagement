import QtQuick 2.7
import Lomiri.Components 1.3
import "../models/database.js" as Database

Page {
    id: syncLogPage
    title: "Sync Log"
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
                onTriggered: {
                    onClicked: {
                        var combined = "";
                        for (var i = 0; i < syncLogs.length; i++) {
                            var log = syncLogs[i];
                            combined += "[" + log.level + "] " + log.timestamp + ": " + log.message + " (" + log.filename + ":" + log.lineno + ")\n";
                        }
                        Clipboard.push(combined);
                    }
                }
            }
        ]
    }

    Component.onCompleted: {
        syncLogs = Database.fetchParsedSyncLog(recordid);
        console.log("Logs loaded:", syncLogs.length);
    }

    ListView {
        id: logListView
        anchors.fill: parent
        model: syncLogs
        delegate: Item {
            width: logListView.width
            height: textItem.implicitHeight

            Rectangle {
                anchors.fill: parent
                anchors.margins: 6
                radius: 6
                color: getColorByLevel(modelData.level)

                Text {
                    id: textItem
                    text: modelData.timestamp + modelData.message
                    font.pixelSize: units.gu(1)
                    wrapMode: Text.Wrap
                    width: parent.width
                }
            }
        }
    }

    function getColorByLevel(level) {
        switch (level) {
        case "ERROR":
            return "#ffe6e6";
        case "WARNING":
            return "#fff9cc";
        case "DEBUG":
            return "#eef6ff";
        case "INFO":
            return "#e6ffe6";
        default:
            return "#f5f5f5";
        }
    }
}
