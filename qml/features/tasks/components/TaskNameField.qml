/*
 * MIT License
 * Copyright (c) 2025 CIT-Services
 */
import QtQuick 2.7
import Lomiri.Components 1.3
import "../../../components"

Row {
    id: root

    property alias text: nameTextField.text
    property bool isReadOnly: false
    property real availableWidth: parent.width
    signal nameEdited(string newText)

    width: root.availableWidth
    height: units.gu(6)
    spacing: units.gu(1)

    Item {
        width: units.gu(11)
        height: parent.height

        Label {
            text: i18n.dtr("ubtms", "Name")
            anchors.left: parent.left
            anchors.leftMargin: units.gu(1)
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    TextField {
        id: nameTextField
        readOnly: root.isReadOnly
        width: root.availableWidth - units.gu(15)
        anchors.verticalCenter: parent.verticalCenter
        text: ""

        onTextChanged: root.nameEdited(text)

        Rectangle {
            anchors.fill: parent
            color: "transparent"
            radius: units.gu(0.5)
            border.width: parent.activeFocus ? units.gu(0.2) : units.gu(0.1)
            border.color: parent.activeFocus ? LomiriColors.orange : (theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#d3d1d1" : "#999")
        }
    }
}
