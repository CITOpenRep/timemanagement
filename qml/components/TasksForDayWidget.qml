/*
 * MIT License
 * Copyright (c) 2025 CIT-Services
 */

import QtQuick 2.7
import Lomiri.Components 1.3
import QtQuick.Layouts 1.3
import QtQuick.LocalStorage 2.7 as Sql
import "../../models/constants.js" as AppConst
import "../../models/task.js" as Task
import "../../models/utils.js" as Utils

Item {
    id: todayTasksWidget
    width: parent.width
    height: units.gu(30)

    property var tasksToday: []
    signal taskSelected(int odooId)

    Rectangle {
        anchors.fill: parent
        color: "white"
        radius: units.gu(1)
        border.color: "#ccc"
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            spacing: units.gu(1)

            Label {
                id: headerLabel
                text: i18n.dtr("ubtms", "Plan for Today")
                font.bold: true
                font.pixelSize: units.gu(2)
                horizontalAlignment: Text.AlignHCenter
                Layout.alignment: Qt.AlignHCenter
            }

            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: ListModel {
                    id: todayTaskModel
                }

                delegate: Rectangle {
                    width: parent.width
                    height: units.gu(5)
                    color: "#f9f9f9"
                    border.color: "#ddd"
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: units.gu(0.5)
                        spacing: units.gu(1)

                        Text {
                            text: model.name
                            font.pixelSize: units.gu(1.8)
                            color: "#333"
                            elide: Text.ElideRight
                            wrapMode: Text.NoWrap
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignLeft
                        }

                        Text {
                            text: model.statusText
                            font.pixelSize: units.gu(1.4)
                            color: "#666"
                            horizontalAlignment: Text.AlignRight
                            Layout.alignment: Qt.AlignRight
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            todayTasksWidget.taskSelected(model.odoo_record_id);
                        }
                    }
                }
            }
        }
    }
    function load() {
        todayTaskModel.clear();
        var allTasks = Task.getAllTasks();
        var today = new Date();
        today.setHours(0, 0, 0, 0); // Normalize

        function pickRelevantDate(task) {
            return task.end_date || task.deadline || task.start_date || null;
        }

        for (var i = 0; i < allTasks.length; i++) {
            var task = allTasks[i];
            var relevantDateStr = pickRelevantDate(task);
            if (!relevantDateStr)
                continue;

            var d = new Date(relevantDateStr);
            d.setHours(0, 0, 0, 0);

            if (isNaN(d.getTime()) || d > today)
                continue;

            todayTaskModel.append({
                name: task.name,
                identified_date: relevantDateStr,
                statusText: Utils.getTimeStatusInText(relevantDateStr),
                odoo_record_id: task.odoo_record_id
            });
        }
    }

    Component.onCompleted: {
        if (todayTasksWidget.visible)
            load();
    }

    onVisibleChanged: {
        if (visible) {
            load();
        }
    }
}
