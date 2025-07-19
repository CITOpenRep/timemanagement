import QtQuick 2.7
import QtQuick.Controls 2.2
import Lomiri.Components 1.3

Item {
    id: card
    width: parent.width
    height: units.gu(12)

    property string name
    property string mimetype
    property string datas

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
            elide: Text.ElideRight
            wrapMode: Text.Wrap
            maximumLineCount: 2
            width: parent.width
            font.pixelSize: units.gu(1.6)
            anchors.horizontalCenter: parent.horizontalCenter
             horizontalAlignment: Text.AlignHCenter
        }
    }

    Component {
        id: imageIcon
        MouseArea {
            anchors.fill: parent
            onClicked: imageClicked(mimetype, datas)

            Image {
                anchors.fill: parent
                fillMode: Image.PreserveAspectFit
                source: "data:" + mimetype + ";base64," + datas
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
                text: mimetype ? mimetype.split("/")[1].toUpperCase() : "FILE"
                anchors.centerIn: parent
                font.pixelSize: units.gu(1.5)
            }
        }
    }
}
