/*
 * MIT License
 * Copyright (c) 2025 CIT-Services
 */
import QtQuick 2.7
import QtQuick.Controls 2.2
import Lomiri.Components 1.3
import "../../../components"

Row {
    id: root

    property alias currentIndex: stageComboBox.currentIndex
    property alias model: stageListModel
    property bool isReadOnly: false

    signal stageSelected(int odooRecordId)

    width: parent ? parent.width : 0
    height: units.gu(6)
    spacing: units.gu(2)
    topPadding: units.gu(1)

    TSLabel {
        text: i18n.dtr("ubtms", "Initial Stage")
        width: parent.width * 0.25
        anchors.verticalCenter: parent.verticalCenter
    }

    ComboBox {
        id: stageComboBox
        width: parent.width * 0.65
        height: units.gu(5)
        anchors.verticalCenter: parent.verticalCenter
        enabled: !root.isReadOnly
        displayText: currentIndex >= 0 ? stageListModel.get(currentIndex).name : "Select Stage"

        model: ListModel {
            id: stageListModel
        }

        delegate: ItemDelegate {
            width: stageComboBox.width
            contentItem: Text {
                text: model.name
                color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "white" : "black"
                font: stageComboBox.font
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
            }
            highlighted: stageComboBox.highlightedIndex === index
        }

        onCurrentIndexChanged: {
            if (currentIndex >= 0) {
                var stage = stageListModel.get(currentIndex);
                root.stageSelected(stage.odoo_record_id);
            }
        }
    }
}
