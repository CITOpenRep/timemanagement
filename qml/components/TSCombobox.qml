// TSCombo.qml
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.3

ComboBox {
    id: innerCombo

    // NOTE: Do NOT alias final properties like model/currentIndex/currentText

    background: Rectangle {
        //color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "grey" : "transparent"
        radius: units.gu(0.5)
        border.color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#d3d1d1" : "#636161"
        border.width: 1
        color: "transparent"
    }

    contentItem: Text {
        text: innerCombo.displayText
        color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "white" : "black"
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        anchors.verticalCenter: parent.verticalCenter
        leftPadding: units.gu(2)
    }

    delegate: ItemDelegate {
        width: innerCombo.width
        hoverEnabled: true
        contentItem: Text {
            text: modelData
            color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "white" : "#222"
            leftPadding: units.gu(1)
            elide: Text.ElideRight
        }
        background: Rectangle {
            color: hovered ? (theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#444" : "#e0e0e0") : (theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#222" : "white")
            radius: 4
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
