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
import QtQuick.Window 2.2
import Qt.labs.settings 1.0
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import Lomiri.Components.Pickers 1.3
import QtCharts 2.0
import "../models/task.js" as Task
import "../models/utils.js" as Utils
import "../models/global.js" as Global
import "components"

Page {
    id: taskCreate
    title: "New Task 123"
    header: PageHeader {
        title: taskCreate.title
        StyleHints {
            foregroundColor: "white"

            backgroundColor: LomiriColors.orange
            dividerColor: LomiriColors.slate
        }

        //    enable: true
        trailingActionBar.actions: [
            Action {
                iconSource: "images/save.svg"
                text: "Save"
                onTriggered: {
                    isReadOnly = !isReadOnly;
                    console.log("Save Task clicked");
                    save_task_data();
                }
            }
        ]
    }

    property string currentEditingField: ""
        property bool workpersonaSwitchState: true
            property bool isReadOnly: false
                property int selectedProjectId: 0
                    property int selectedparentId: 0
                        property int selectedTaskId: 0
                            property int favorites: 0
                                property int subProjectId: 0
                                    property var prevtask: ""

                                        function save_task_data()
                                        {
                                            //this shit has to be updated
                                            console.log("Account ID: " + Global.selectedInstanceId);
                                            if (task_text.text != "")
                                            {
                                                const saveData = {
                                                    accountId: accountCombo.selectedInstanceId,
                                                    name: task_text.text,
                                                    projectId: (projectCombo.selectedProjectId < 0) ? 0 : projectCombo.selectedProjectId,
                                                    subProjectId: 0,
                                                    parentId: taskselector_combo.selectedTaskId > 0 ? taskselector_combo.selectedTaskId : null,
                                                    startDate: start_date_widget.date,
                                                    endDate: end_date_widget.date,
                                                    deadline: deadline_widget.date,
                                                    favorites: favorites,
                                                    plannedHours: hours_text.text,
                                                    description: description_text.text,
                                                    assigneeUserId: assigneecombo.selectedUserId,
                                                    status: "updated"
                                                };

                                                const result = Task.saveOrUpdateTask(saveData);
                                                if (!result.success)
                                                {
                                                    notifPopup.open("Error", "Unable to Save the Task", "error");
                                                } else {
                                                notifPopup.open("Saved", "Task has been saved successfully", "success");
                                            }
                                        } else {
                                        notifPopup.open("Error", "Unable to Save the Data", "error");
                                    }
                                }

                                function incdecHrs(value)
                                {
                                    if (value === 1)
                                    {
                                        var hrs = Number(hours_text.text);
                                        hrs++;
                                        hours_text.text = hrs;
                                    } else {
                                    var hrs = Number(hours_text.text);
                                    if (hrs > 0)
                                        hrs--;
                                    hours_text.text = hrs;
                                }
                            }

                            NotificationPopup {
                                id: notifPopup
                                width: units.gu(80)
                                height: units.gu(80)
                                onClosed: console.log("Notification dismissed")
                            }
                            Flickable {
                                id: tasksDetailsPageFlickable
                                anchors.topMargin: units.gu(6)
                                anchors.fill: parent
                                contentHeight: parent.height
                                // + 1000
                                flickableDirection: Flickable.VerticalFlick

                                width: parent.width

                                Row {
                                    id: myRow1a
                                    anchors.left: parent.left
                                    topPadding: units.gu(5)

                                    Column {
                                        leftPadding: units.gu(1)

                                        WorkItemSelector {
                                            id: workItem
                                            readOnly: isReadOnly
                                            width: tasksDetailsPageFlickable.width - units.gu(2)
                                            // height: units.gu(29) // Uncomment if you need fixed height
                                        }
                                    }
                                }
                                Row {
                                    id: myRow9
                                    anchors.top: myRow1a.bottom
                                    anchors.left: parent.left
                                    topPadding: units.gu(5)
                                    Column {
                                        id: myCol8
                                        leftPadding: units.gu(1)
                                        LomiriShape {
                                            width: units.gu(10)
                                            height: units.gu(5)
                                            aspect: LomiriShape.Flat
                                            Label {
                                                id: description_label
                                                text: "Description"
                                                // font.bold: true
                                                anchors.left: parent.left
                                                anchors.verticalCenter: parent.verticalCenter
                                                //textSize: Label.Large
                                            }
                                        }
                                    }
                                    Column {
                                        id: myCol9
                                        leftPadding: units.gu(3)
                                        TextArea {
                                            id: description_text
                                            readOnly: isReadOnly
                                            autoSize: true
                                            maximumLineCount: 0
                                            width: tasksDetailsPageFlickable.width < units.gu(361) ? tasksDetailsPageFlickable.width - units.gu(15) : tasksDetailsPageFlickable.width - units.gu(10)
                                            anchors.centerIn: parent.centerIn
                                            text: tasksDetailsPageFlickable.width
                                        }
                                    }
                                }

                                Row {
                                    id: myRow4
                                    anchors.top: myRow9.bottom
                                    anchors.left: parent.left
                                    height: units.gu(5)
                                    topPadding: units.gu(2)
                                    Column {
                                        leftPadding: units.gu(1)
                                        LomiriShape {
                                            width: units.gu(10)
                                            height: units.gu(5)
                                            aspect: LomiriShape.Flat
                                            Label {
                                                id: hours_label
                                                text: "Planned Hours"
                                                //font.bold: true
                                                anchors.left: parent.left

                                                anchors.verticalCenter: parent.verticalCenter
                                                //textSize: Label.Large
                                            }
                                        }
                                    }
                                    Column {
                                        leftPadding: units.gu(3)
                                        TSButton {
                                            id: minusbutton
                                            anchors.left: plusbutton.right
                                            height: units.gu(4)
                                            width: units.gu(4)
                                            text: "-"
                                            onClicked: {
                                                incdecHrs(2);
                                            }
                                        }
                                    }
                                    Column {
                                        id: planColumn
                                        leftPadding: units.gu(1)
                                        TextField {
                                            id: hours_text
                                            readOnly: isReadOnly
                                            width: units.gu(20)
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: "1"
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                        }
                                    }
                                    Column {
                                        leftPadding: units.gu(1)
                                        TSButton {
                                            id: plusbutton
                                            height: units.gu(4)
                                            width: units.gu(4)
                                            text: "+"
                                            onClicked: {
                                                incdecHrs(1);
                                            }
                                        }
                                    }
                                }
                                Row {
                                    id: myRow5
                                    anchors.top: myRow4.bottom
                                    anchors.left: parent.left
                                    topPadding: units.gu(2)
                                    Column {
                                        leftPadding: units.gu(1)
                                        LomiriShape {
                                            width: units.gu(10)
                                            height: units.gu(5)
                                            aspect: LomiriShape.Flat
                                            Label {
                                                id: start_label
                                                text: "Start Date"
                                                //font.bold: true
                                                anchors.left: parent.left
                                                anchors.verticalCenter: parent.verticalCenter
                                                //textSize: Label.Large
                                            }
                                        }
                                    }
                                    Column {
                                        leftPadding: units.gu(3)
                                        QuickDateSelector {
                                            id: start_date_widget
                                            width: tasksDetailsPageFlickable.width < units.gu(361) ? tasksDetailsPageFlickable.width - units.gu(15) : tasksDetailsPageFlickable.width - units.gu(10)

                                            height: units.gu(4)
                                            anchors.centerIn: parent.centerIn
                                        }
                                    }
                                }

                                Row {
                                    id: myRow6
                                    anchors.top: myRow5.bottom
                                    anchors.left: parent.left
                                    topPadding: units.gu(2)
                                    Column {
                                        leftPadding: units.gu(1)
                                        LomiriShape {
                                            width: units.gu(10)
                                            height: units.gu(5)
                                            aspect: LomiriShape.Flat
                                            Label {
                                                id: end_label
                                                text: "End Date"
                                                //font.bold: true
                                                anchors.left: parent.left
                                                anchors.verticalCenter: parent.verticalCenter
                                                //textSize: Label.Large
                                            }
                                        }
                                    }
                                    Column {
                                        leftPadding: units.gu(3)
                                        QuickDateSelector {
                                            id: end_date_widget
                                            width: tasksDetailsPageFlickable.width < units.gu(361) ? tasksDetailsPageFlickable.width - units.gu(15) : tasksDetailsPageFlickable.width - units.gu(10)
                                            height: units.gu(4)
                                            anchors.centerIn: parent.centerIn
                                        }
                                    }
                                }

                                Row {
                                    id: myRow7
                                    anchors.top: myRow6.bottom
                                    anchors.left: parent.left
                                    topPadding: units.gu(2)
                                    Column {
                                        leftPadding: units.gu(1)
                                        LomiriShape {
                                            width: units.gu(10)
                                            height: units.gu(5)
                                            aspect: LomiriShape.Flat
                                            Label {
                                                id: deadline_label
                                                text: "Deadline"
                                                //font.bold: true
                                                anchors.left: parent.left
                                                anchors.verticalCenter: parent.verticalCenter
                                                //textSize: Label.Large
                                            }
                                        }
                                    }
                                    Column {
                                        leftPadding: units.gu(3)
                                        QuickDateSelector {
                                            id: deadline_widget
                                            width: tasksDetailsPageFlickable.width < units.gu(361) ? tasksDetailsPageFlickable.width - units.gu(15) : tasksDetailsPageFlickable.width - units.gu(10)
                                            height: units.gu(4)
                                            anchors.centerIn: parent.centerIn
                                        }
                                    }
                                }

                            }
                            Component.onCompleted: {
                                Utils.updateOdooUsers(assigneeModel);
                            }
                        }
