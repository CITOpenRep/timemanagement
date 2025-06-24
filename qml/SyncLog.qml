import QtQuick 2.7
import Lomiri.Components 1.3
import "../models/accounts.js" as Accounts

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
        var allLogs = Accounts.fetchParsedSyncLog(recordid);
        syncLogs = allLogs.filter(function (log) {
            return log.level === "ERROR" || log.level === "WARNING";
        });
    }

    ListView {
        id: logListView
        anchors.fill: parent
        anchors.margins: units.gu(1)
        anchors.topMargin: pageHeader.height + units.gu(1)

        // anchors.top: pageHeader.bottom + units.gu(4)

        model: syncLogs
        delegate: Item {
            width: logListView.width
            height: textItem.implicitHeight

            Rectangle {
                anchors.fill: parent
                anchors.margins: units.gu(0.8)

                color: getColorByLevel(modelData.level)

                Text {
                    id: textItem
                    text: modelData.timestamp + modelData.message
                    font.pixelSize: units.gu(1.5)
                    wrapMode: Text.Wrap
                    width: parent.width
                    color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "grey" : "black"
                }
            }
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
            return "#90f790";
        default:
            return "#f5f5f5";
        }
    }
}
