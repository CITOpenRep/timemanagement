/*
 * MIT License
 * Copyright (c) 2025 CIT-Services
 */
import QtQuick 2.7
import Lomiri.Components 1.3
import "../../../components"

Row {
    id: root

    property int priority: 0
    property bool isReadOnly: false

    width: parent ? parent.width : 0
    height: units.gu(6)
    spacing: units.gu(2)

    Column {
        width: units.gu(15)
        height: parent.height

        LomiriShape {
            width: units.gu(15)
            height: units.gu(5)
            aspect: LomiriShape.Flat
            Label {
                text: i18n.dtr("ubtms", "Priority")
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    Column {
        leftPadding: units.gu(3)
        height: parent.height

        Row {
            spacing: units.gu(2)
            height: units.gu(5)

            Repeater {
                model: 3

                Image {
                    property int starIndex: index
                    source: ((index + 1) <= root.priority) ? "../../../images/star.png" : "../../../images/star-inactive.png"
                    width: units.gu(3.5)
                    height: units.gu(3.5)
                    opacity: root.isReadOnly ? 0.7 : 1.0

                    MouseArea {
                        anchors.fill: parent
                        enabled: !root.isReadOnly
                        onClicked: {
                            var clickedPriority = index + 1;
                            root.priority = (clickedPriority === root.priority) ? 0 : clickedPriority;
                        }
                    }
                }
            }

            Label {
                text: "(Level: " + root.priority + ")"
                anchors.verticalCenter: parent.verticalCenter
                font.pixelSize: units.gu(1.5)
                visible: root.priority > 0
            }
        }
    }
}
