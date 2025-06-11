// TSCombo.qml
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.3

ComboBox {
    id: innerCombo

    // NOTE: Do NOT alias final properties like model/currentIndex/currentText

    background: Rectangle {
        color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "grey" : "transparent"
        radius: units.gu(0.5)
        border.color: "black"
        border.width: 1
    }

    contentItem: Text {
        text: innerCombo.displayText
        color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "white" : "#000000"
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        anchors.verticalCenter: parent.verticalCenter
        leftPadding: units.gu(1)
        rightPadding: units.gu(2)
    }

    delegate: ItemDelegate {
        width: innerCombo.width
        contentItem: Text {
            text: modelData
            color: "#000000"
            leftPadding: units.gu(1)
            elide: Text.ElideRight
        }
    }

    /*indicator: Item {
        width: units.gu(2)
        height: units.gu(2)
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter

        Image {
            anchors.centerIn: parent
            source: "image://theme/arrow-down"
            width: units.gu(1.5)
            height: units.gu(1.5)
        }
    }*/

    Layout.preferredWidth: units.gu(20)
    Layout.preferredHeight: units.gu(4)
}
