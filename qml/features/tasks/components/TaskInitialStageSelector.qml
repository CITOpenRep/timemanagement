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

    property int currentIndex: -1
    property alias model: stageListModel
    property bool isReadOnly: false
    property string currentStageName: ""

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

    // Trigger button for opening the OptionSelectorPopover
    Rectangle {
        id: selectorTrigger
        width: parent.width * 0.65
        height: units.gu(5)
        anchors.verticalCenter: parent.verticalCenter
        radius: units.gu(0.8)
        
        color: !enabled ? (theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#2c2c2c" : "#e0e0e0")
                        : (mouseArea.containsPress ? (theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#383838" : "#d6d6d6")
                                                   : (theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#202020" : "#f5f5f5"))
        border.color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#3d3d3d" : "#cccccc"
        border.width: 1
        enabled: !root.isReadOnly

        Row {
            anchors.fill: parent
            anchors.leftMargin: units.gu(1.5)
            anchors.rightMargin: units.gu(1.5)
            spacing: units.gu(1)

            Text {
                id: displayText
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - units.gu(3)
                text: currentStageName || i18n.dtr("ubtms", "Select Stage")
                color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#ffffff" : "#000000"
                font.pixelSize: units.gu(1.6)
                elide: Text.ElideRight
            }

            Icon {
                id: dropdownIcon
                name: "go-down"
                width: units.gu(2)
                height: units.gu(2)
                anchors.verticalCenter: parent.verticalCenter
                color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#888888" : "#555555"
            }
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            enabled: selectorTrigger.enabled
            onClicked: {
                openStagesPopover();
            }
        }
    }

    ListModel {
        id: stageListModel
        onCountChanged: {
            updateCurrentStageName();
        }
    }

    OptionSelectorPopover {
        id: stagePopover
        onSelectionMade: {
            // Find index matching the selected id
            for (var i = 0; i < stageListModel.count; i++) {
                if (stageListModel.get(i).odoo_record_id === id) {
                    currentIndex = i;
                    break;
                }
            }
        }
    }

    function updateCurrentStageName() {
        if (currentIndex >= 0 && currentIndex < stageListModel.count) {
            var item = stageListModel.get(currentIndex);
            if (item) {
                currentStageName = item.name;
                return;
            }
        }
        currentStageName = "";
    }

    function openStagesPopover() {
        var popoverData = [];
        for (var i = 0; i < stageListModel.count; i++) {
            var item = stageListModel.get(i);
            popoverData.push({
                id: item.odoo_record_id,
                name: item.name
            });
        }
        stagePopover.open(i18n.dtr("ubtms", "Select Initial Stage"), popoverData, root);
    }

    onCurrentIndexChanged: {
        updateCurrentStageName();
        if (currentIndex >= 0 && currentIndex < stageListModel.count) {
            var stage = stageListModel.get(currentIndex);
            root.stageSelected(stage.odoo_record_id);
        }
    }
}
