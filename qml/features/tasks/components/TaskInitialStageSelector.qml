/*
 * MIT License
 * Copyright (c) 2025 CIT-Services
 */
import QtQuick 2.7
import QtQuick.Controls 2.2
import Lomiri.Components 1.3
import "../../../components"

Item {
    id: root

    property int currentIndex: -1
    property alias model: stageListModel
    property bool isReadOnly: false

    signal stageSelected(int odooRecordId)

    width: parent ? parent.width : 0
    height: inlineSelector.height

    InlineOptionSelector {
        id: inlineSelector
        anchors.left: parent.left
        anchors.right: parent.right
        
        labelText: i18n.dtr("ubtms", "Initial Stage")
        enabledState: !root.isReadOnly
        readOnly: root.isReadOnly

        onSelectionMade: {
            for (var i = 0; i < stageListModel.count; i++) {
                if (stageListModel.get(i).odoo_record_id === id) {
                    currentIndex = i;
                    break;
                }
            }
        }
    }

    ListModel {
        id: stageListModel
        onCountChanged: {
            updateModelData();
        }
    }

    function updateModelData() {
        var arr = [];
        for (var i = 0; i < stageListModel.count; i++) {
            var item = stageListModel.get(i);
            arr.push({
                id: item.odoo_record_id,
                name: item.name
            });
        }
        inlineSelector.modelData = arr;
    }

    onCurrentIndexChanged: {
        if (currentIndex >= 0 && currentIndex < stageListModel.count) {
            var stage = stageListModel.get(currentIndex);
            inlineSelector.selectedId = stage.odoo_record_id;
            root.stageSelected(stage.odoo_record_id);
        } else {
            inlineSelector.selectedId = -1;
        }
    }
}
