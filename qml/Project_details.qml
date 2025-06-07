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
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import Lomiri.Components.Pickers 1.3
import QtCharts 2.0
import QtQuick.Window 2.2
import Qt.labs.settings 1.0
import "../models/Project.js" as Project
import "../models/Timesheet.js" as Timesheet
import "../models/Utils.js" as Utils
import "components"

Page {
    id: taskDetails
    title: "Project Details"

    property var recordid: 0
    property bool workpersonaSwitchState: true
    property bool isReadOnly: true
    property var project
    property var startdatestr: ""
    property var enddatestr: ""
    property var deadlinestr: ""
    /*    property var project: ""
    property var parentname: ""
    property var account: ""
    property var user: "" */
    property int selectedAccountUserId: 0
    property int selectedProjectId: 0
    property int selectedassigneesUserId: 0
    property int selectedparentId: 0
    property int selectedInstanceId: 0
    property int selectedTaskId: 0
    property int favorites: 0
    property var prevproject: ""
    property var prevInstanceId: 0
    property var prevassignee: ""
    property var prevtask: ""

    header: PageHeader {
        StyleHints {
            foregroundColor: LomiriColors.orange
            backgroundColor: LomiriColors.background
            dividerColor: LomiriColors.slate
        }

        title: taskDetails.title
        ActionBar {
            numberOfSlots: 1
            anchors.right: parent.right
        }
    }

    Flickable {
        id: rect1
        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        //radius: "large"
        width: parent.width
        height: parent.height

        Row {
            id: myRow1a
            anchors.left: parent.left
            topPadding: 10
            Column {
                leftPadding: units.gu(2)
                LomiriShape {
                    width: units.gu(10)
                    height: units.gu(5)
                    aspect: LomiriShape.Flat
                    Label {
                        id: instance_label
                        font.bold: true
                        text: "Instance"
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        //textSize: Label.Large
                    }
                }
            }
            Column {
                leftPadding: units.gu(3)
                AccountSelector {
                    id: accountCombo
                    editable: true
                    width: Screen.desktopAvailableWidth < units.gu(250) ? units.gu(30) : units.gu(60)
                    height: units.gu(6)
                    anchors.centerIn: parent.centerIn
                    enabled: !taskDetails.isReadOnly
                    flat: true
                }
            }
        }

        Row {
            id: myRow1
            anchors.top: myRow1a.bottom
            anchors.left: parent.left
            topPadding: 10
            Column {
                leftPadding: units.gu(2)
                LomiriShape {
                    width: units.gu(10)
                    height: units.gu(5)
                    aspect: LomiriShape.Flat
                    Label {
                        id: task_label
                        font.bold: true
                        text: "Project Name"
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        //textSize: Label.Large
                    }
                }
            }
            Column {
                leftPadding: units.gu(3)
                TextField {
                    id: task_text
                    readOnly: isReadOnly
                    width: Screen.desktopAvailableWidth < units.gu(250) ? units.gu(30) : units.gu(60)
                    text: project.name
                }
            }
        }

        Row {
            id: myRow9
            anchors.top: myRow1.bottom
            anchors.left: parent.left
            topPadding: 10
            Column {
                id: myCol8
                leftPadding: units.gu(2)
                LomiriShape {
                    width: units.gu(10)
                    height: units.gu(5)
                    aspect: LomiriShape.Flat
                    Label {
                        id: description_label
                        font.bold: true
                        text: "Description"
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
                    maximumLineCount: 1
                    width: Screen.desktopAvailableWidth < units.gu(250) ? units.gu(30) : units.gu(60)
                    anchors.centerIn: parent.centerIn
                    text: Utils.stripHtmlTags(project.description)
                }
            }
        }
        Row {
            id: myRow5
            anchors.top: myRow9.bottom
            anchors.left: parent.left
            topPadding: 10
            Column {
                leftPadding: units.gu(2)
                LomiriShape {
                    width: units.gu(10)
                    height: units.gu(5)
                    aspect: LomiriShape.Flat
                    Label {
                        id: start_label
                        text: "Start Date"
                        font.bold: true
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        //textSize: Label.Large
                    }
                }
            }
            Column {
                leftPadding: units.gu(3)
                TextField {
                    id: start_text
                    readOnly: isReadOnly
                    width: Screen.desktopAvailableWidth < units.gu(250) ? units.gu(30) : units.gu(60)
                    anchors.centerIn: parent.centerIn
                    text: project.start_date
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (date_field.visible === false) {
                                if (!isReadOnly) {
                                    date_field.visible = !date_field.visible;
                                    start_text.text = "";
                                }
                            } else {
                                date_field.visible = !date_field.visible;
                                start_text.text = Utils.formatOdooDateTime(date_field.date);
                                startdatestr = Utils.formatOdooDateTime(date_field.date);
                            }
                        }
                    }
                }
                DatePicker {
                    id: date_field
                    visible: false
                    z: 1
                    minimum: {
                        var d = new Date();
                        d.setFullYear(d.getFullYear() - 1);
                        return d;
                    }
                    maximum: Date.prototype.getInvalidDate.call()
                }
            }
        }

        Row {
            id: myRow6
            anchors.top: myRow5.bottom
            anchors.left: parent.left
            topPadding: 10
            Column {
                leftPadding: units.gu(2)
                LomiriShape {
                    width: units.gu(10)
                    height: units.gu(5)
                    aspect: LomiriShape.Flat
                    Label {
                        id: end_label
                        text: "End Date"
                        font.bold: true
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        //textSize: Label.Large
                    }
                }
            }
            Column {
                leftPadding: units.gu(3)
                TextField {
                    id: end_text
                    readOnly: isReadOnly
                    width: Screen.desktopAvailableWidth < units.gu(250) ? units.gu(30) : units.gu(60)
                    anchors.centerIn: parent.centerIn
                    text: project.end_date
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (date_field2.visible === false) {
                                if (!isReadOnly) {
                                    date_field2.visible = !date_field2.visible;
                                    end_text.text = "";
                                }
                            } else {
                                date_field2.visible = !date_field2.visible;
                                end_text.text = Utils.formatOdooDateTime(date_field2.date);
                                enddatestr = Utils.formatOdooDateTime(date_field2.date);
                            }
                        }
                    }
                }
                DatePicker {
                    id: date_field2
                    visible: false
                    z: 1
                    minimum: {
                        var d = new Date();
                        d.setFullYear(d.getFullYear() - 1);
                        return d;
                    }
                    maximum: Date.prototype.getInvalidDate.call()
                }
            }
        }

        NotificationPopup {
            id: notifPopup
            width: units.gu(80)
            height: units.gu(80)
            onClosed: console.log("Notification dismissed")
        }

        Component.onCompleted: {
            project = Project.get_project_detail(recordid, true);
            //console.log("Project Name:", project.name);
            //console.log("Start Date:", project.start_date);
            //console.log("End Date:", project.end_date);
            //console.log("Account Name:", project.account_name);
            //console.log("Description:", project.description);
            // console.log("ID:", project.account_id);
            // console.log("From Project Page  Account ID: " + project.account_id + " Account Name: " + project.account_name);
            //  console.log("Description is: " + project.description);
            selectedInstanceId = project.account_id;
            accountCombo.selectAccountById(project.account_id);
        }
    }
}
