import QtQuick 2.7
import QtQuick.Controls 2.2
import Lomiri.Components 1.3
import io.thp.pyotherside 1.4
import "../../models/project.js" as Project

Item {
    id: card
    width: parent.width
    height: units.gu(30)

    property string name
    property string mimetype
    property string datas
    property int odoo_record_id
    property int account_id
    property bool downloading: false

    Python {
        id: python

        Component.onCompleted: {
            addImportPath(Qt.resolvedUrl('../../src/'));
            importModule_sync("backend");
        }

        onError: function (errorName, errorMessage, traceback) {
            console.error("Python Error:", errorName);
            console.error("Message:", errorMessage);
            console.error("Traceback:\n" + traceback);
        }
    }

    function download_image() {
        if (downloading)
            return;
        if (odoo_record_id === 0) {
            console.error("Invalid record id=0, Unable to download attachment");
            return;
        }

        // 1) try cache first
        var cached = Project.getFromCache(odoo_record_id);
        if (cached) {
            datas = cached;                   // base64 string
            // mimetype should already be set on the card; keep it
            return;
        }

        downloading = true;
        python.call("backend.resolve_qml_db_path", ["ubtms"], function (path) {
            if (!path) {
                console.warn("DB not found.");
                downloading = false;
                return;
            }

            // 2) call backend with 3 args: path, account_id, odoo_record_id
            python.call("backend.attachment_ondemand_download", [path, account_id, odoo_record_id], function (res) {
                downloading = false;

                if (!res) {
                    console.warn("No response from ondemand_download");
                    return;
                }

                if (res.type === "binary" && res.data) {
                    // res.data is base64 (because we returned decode=False in Python)
                    datas = res.data;
                    if (res.mimetype)
                        mimetype = res.mimetype;
                    if (res.name)
                        name = res.name;

                    // 3) put into minimal cache
                    Project.putInCache(odoo_record_id, datas);
                } else if (res.type === "url" && res.url) {
                    // Non-binary attachment; you can open or download via HTTP if wanted
                    console.log("Attachment is a URL:", res.url);
                    // Example: openExternally(res.url) or set an icon state
                } else {
                    console.warn("Attachment has no usable data:", JSON.stringify(res));
                }
            });
        });
    }

    signal imageClicked(string mimetype, string datas)

    Column {
        anchors.fill: parent
        anchors.margins: units.gu(1)
        spacing: units.gu(1)

        Loader {
            id: iconLoader
            width: units.gu(8)
            height: units.gu(8)
            anchors.horizontalCenter: parent.horizontalCenter
            sourceComponent: mimetype && mimetype.startsWith("image/") ? imageIcon : fileIcon
        }
        Text {
            text: name
            //   color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "white" : "black"
            elide: Text.ElideRight
            wrapMode: Text.Wrap
            maximumLineCount: 2
            width: parent.width
            font.pixelSize: units.gu(1.6)
            anchors.horizontalCenter: parent.horizontalCenter
            horizontalAlignment: Text.AlignHCenter
        }
        Button {
            text: "Download"
            enabled: false
            visible: false
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    Component {
        id: imageIcon
        MouseArea {
            anchors.fill: parent
            onClicked: imageClicked(mimetype, datas)

            Image {
                id: pic
                anchors.fill: parent
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                cache: false
                source: "data:" + mimetype + ";base64," + datas

                // soft fade-in when ready
                opacity: status === Image.Ready ? 1 : 0
                Behavior on opacity {
                    NumberAnimation {
                        duration: 150
                    }
                }

                onStatusChanged: if (status === Image.Error)
                    console.warn("Image load error:")
            }

            // subtle dim while loading/downloading/empty
            Rectangle {
                anchors.fill: parent
                visible: card.downloading || pic.status === Image.Loading || !datas
                color: "#00000020"
            }

            // spinner while loading
            BusyIndicator {
                anchors.centerIn: parent
                running: card.downloading || pic.status === Image.Loading || !datas
                visible: running
            }
            // (If you prefer Lomiri's)
            // ActivityIndicator {
            //     anchors.centerIn: parent
            //     running: card.downloading || pic.status === Image.Loading || !datas
            //     visible: running
            // }

            // optional: show network load progress (0..1)
            ProgressBar {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: units.gu(0.8)
                width: Math.min(parent.width * 0.6, units.gu(28))
                visible: pic.status === Image.Loading
                minimumValue: 0
                maximumValue: 1
                value: pic.progress
            }
        }
    }

    Component {
        id: fileIcon
        Rectangle {
            width: units.gu(8)
            height: units.gu(8)
            radius: units.gu(0.3)
            color: "#dddddd"
            border.color: "#aaa"

            Text {
                text: "File"
                anchors.centerIn: parent
                font.pixelSize: units.gu(1.5)
            }
        }
    }
    Component.onCompleted: {
        download_image();
    }
}
