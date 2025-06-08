/*
 * MIT License
 *
 * Copyright (c) 2025 CIT-Services
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.1
import QtQuick.Window 2.2
import QtGraphicalEffects 1.0
import "../../models/constants.js" as AppConst

Item {
    id: timesheetGrid
    width: parent.width
    height: parent.height

    property var timesheetModel
    signal cardClicked(var timesheet)

    Component.onCompleted: reloadModel()

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        Loader {
            active: timesheetModel.count === 0
            sourceComponent: emptyMessage
        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: 10
            contentWidth: gridView.contentWidth
            contentHeight: gridView.contentHeight
            clip: true

            GridView {
                id: gridView
                width: parent.width
                height: parent.height
                cellWidth: 180
                cellHeight: 150

                model: timesheetGrid.timesheetModel

                delegate: Item {
                    width: 170
                    height: 140
                    opacity: 1

                    Rectangle {
                        id: card
                        width: parent.width
                        height: parent.height
                        radius: 1
                        signal clicked

                        color: "#F5F5F5" // sticky note-like background
                        border.color: "#B0BEC5"
                        border.width: 1

                        layer.enabled: true
                        layer.effect: DropShadow {
                            anchors.fill: card
                            horizontalOffset: 2
                            verticalOffset: 2
                            radius: 6
                            samples: 16
                            color: "#55000000"
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: timesheetGrid.cardClicked({
                                id: model.id,
                                record_date: model.record_date,
                                project_id: model.project_id,
                                task_id: model.task_id,
                                name: model.name,
                                quadrant_id: model.quadrant_id,
                                unit_amount: model.unit_amount
                            })
                        }

                        Rectangle {
                            width: 10
                            height: 10
                            radius: 10
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.margins: 6
                            color: {
                                switch (model.quadrant_id) {
                                case 1:
                                    return AppConst.Colors.Quadrants.Q1;
                                case 2:
                                    return AppConst.Colors.Quadrants.Q2;
                                case 3:
                                    return AppConst.Colors.Quadrants.Q3;
                                case 4:
                                    return AppConst.Colors.Quadrants.Q4;
                                default:
                                    return AppConst.Colors.Quadrants.Default;
                                }
                            }
                        }

                        Column {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 4

                            Text {
                                text: Qt.formatDate(new Date(model.record_date), "dd MMM yyyy")
                                font.pixelSize: units.gu(1.5)
                                font.bold: true
                                wrapMode: Text.Wrap
                            }
                            Text {
                                text: model.task_id
                                font.pixelSize: units.gu(1.5)
                                font.bold: false
                                wrapMode: Text.Wrap
                            }
                            Text {
                                text: model.unit_amount + " hrs"
                                font.pixelSize: units.gu(1.5)
                            }
                            Text {
                                text: model.name
                                font.pixelSize: units.gu(1.5)
                                wrapMode: Text.Wrap
                                elide: Text.ElideRight
                            }
                            Text {
                                text: model.project_id
                                font.pixelSize: units.gu(1.5)
                                font.bold: false
                                wrapMode: Text.Wrap
                            }
                        }
                    }
                }

                onCountChanged: gridView.forceLayout()
            }
        }
    }

    function reloadModel() {
        if (timesheetModel && timesheetModel.clear) {
            const entries = Model.fetch_timesheets(true);
            timesheetModel.clear();
            for (let i = 0; i < entries.length; ++i) {
                timesheetModel.append(entries[i]);
            }
        }
    }

    Component {
        id: emptyMessage
        Item {
            anchors.centerIn: parent
            Text {
                text: "No timesheet entries available"
                font.pixelSize: units.gu(2)
                color: "#888"
            }
        }
    }
}
