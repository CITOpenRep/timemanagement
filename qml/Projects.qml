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
import "../models/accounts.js" as Accounts
import "../models/project.js" as Project
import "../models/global.js" as Global
import "components"

Page {
    id: projectCreate
    title: "Project"
    header: PageHeader {
        id: header
        title: projectCreate.title
        StyleHints {
            foregroundColor: "white"
            backgroundColor: LomiriColors.orange
            dividerColor: LomiriColors.slate
        }
        trailingActionBar.actions: [
            Action {
                iconSource: "images/save.svg" // New Save Icon
                text: "Save"
                visible: !isReadOnly
                onTriggered: {
                    const ids = workItem.getAllSelectedDbRecordIds();
                    console.log("Account DB ID:", ids.accountDbId);

                    // isReadOnly = !isReadOnly
                    var project_data = {
                        'account_id': ids.accountDbId >= 0 ? ids.accountDbId : 0,
                        'name': project_name.text,
                        'planned_start_date': date_range_widget.formattedStartDate(),
                        'planned_end_date': date_range_widget.formattedEndDate(),
                        'parent_id': (ids.projectDbId !== undefined && ids.projectDbId >= 0) ? ids.projectDbId : 0,
                        'allocated_hours': hours_text.text,
                        'description': description_text.text,
                        'favorites': 0,
                        'color': project_color,
                        'status': "updated"
                    };
                    console.log(JSON.stringify(project_data, null, 4));
                    var recordid = 0; //project creation
                    var response = Project.createUpdateProject(project_data, recordid);
                    if (response) {
                        if (response.is_success) {
                            notifPopup.open("Saved", response.message, "success");
                        } else {
                            notifPopup.open("Failed", response.message, "error");
                        }
                    } else {
                        notifPopup.open("Failed", "Unable to save project", "error");
                    }
                }
            }
        ]
    }

    property bool isReadOnly: false
    property var recordid: 0
    property int project_color: 0
    property var project: {}

    ScrollView {
        id: scrollview
        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: parent.height
        anchors.bottom: parent.bottom
        LomiriShape {
            id: rect1
            anchors.top: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            radius: "large"
            width: parent.width
            height: parent.height

            Row {
                id: myRow1a
                anchors.left: parent.left
                topPadding: 10
                Column {
                    leftPadding: units.gu(3)
                    WorkItemSelector {
                        id: workItem
                        readOnly: isReadOnly
                        taskLabelText: "Parent Task"
                        showTaskSelector: false
                        width: scrollview.width - units.gu(2)
                        height: units.gu(10)
                    }
                }
            }

            Row {
                id: myRow1
                anchors.top: myRow1a.bottom
                anchors.left: parent.left
                topPadding: units.gu(2)
                Column {
                    leftPadding: units.gu(2)
                    TSLabel {
                        id: project_label
                        width: units.gu(10)
                        height: units.gu(5)
                        text: "Project Name"
                    }
                }
                Column {
                    leftPadding: units.gu(3)
                    TextField {
                        id: project_name
                        readOnly: isReadOnly
                        width: Screen.desktopAvailableWidth < units.gu(250) ? units.gu(30) : units.gu(60)
                        text: ""
                    }
                }
            }

            Row {
                id: myRow9
                anchors.top: myRow1.bottom
                anchors.left: parent.left
                topPadding: units.gu(2)
                Column {
                    id: myCol8
                    leftPadding: units.gu(2)
                    LomiriShape {
                        width: units.gu(10)
                        height: units.gu(5)
                        aspect: LomiriShape.Flat
                        Label {
                            id: description_label
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
                        textFormat: Text.RichText
                        autoSize: false
                        maximumLineCount: 0
                        width: Screen.desktopAvailableWidth < units.gu(250) ? units.gu(30) : units.gu(60)
                        anchors.centerIn: parent.centerIn
                        text: ""
                    }
                }
            }

            Row {
                id: myRow4
                anchors.top: myRow9.bottom
                anchors.left: parent.left
                anchors.rightMargin: 10
                height: units.gu(5)
                topPadding: units.gu(2)
                spacing: units.gu(2) // Spacing between columns
                Column {
                    leftPadding: units.gu(2)
                    LomiriShape {
                        width: units.gu(10)
                        height: units.gu(5)
                        aspect: LomiriShape.Flat
                        Label {
                            id: hours_label
                            text: "Allocated Hours"
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            //textSize: Label.Large
                        }
                    }
                }
                Column {
                    id: planColumn
                    leftPadding: units.gu(5)
                    TextField {
                        id: hours_text
                        readOnly: isReadOnly
                        width: units.gu(20)
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "1"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        validator: IntValidator {
                            bottom: 0
                        }
                    }
                }
            }

            Row {
                id: colorRow
                anchors.top: myRow4.bottom
                anchors.left: parent.left
                topPadding: units.gu(4)
                Column {
                    leftPadding: units.gu(2)
                    LomiriShape {
                        width: units.gu(10)
                        height: units.gu(5)
                        aspect: LomiriShape.Flat
                        Label {
                            id: color_Label
                            text: "Color"
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            //textSize: Label.Large
                        }
                    }
                }
                Column {
                    leftPadding: units.gu(3)
                    Rectangle {
                        id: project_color_label
                        width: units.gu(4)
                        height: units.gu(4)
                        color: "red"
                        enabled: !isReadOnly
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                colorpicker.open();
                            }
                        }
                    }
                }
            }

            Row {
                id: myRow6
                anchors.top: colorRow.bottom
                anchors.left: parent.left
                topPadding: units.gu(1)
                Column {
                    leftPadding: units.gu(1)
                    DateRangeSelector {
                        id: date_range_widget
                        readOnly: isReadOnly
                        width: scrollview.width < units.gu(361) ? scrollview.width - units.gu(15) : scrollview.width - units.gu(10)
                        height: units.gu(4)
                        anchors.centerIn: parent.centerIn
                    }
                }
            }
        }
    }
    ColorPicker {
        id: colorpicker
        width: units.gu(80)
        height: units.gu(80)
        onColorPicked: function (index, value) {
            console.log("Selected index:", index);
            console.log("Selected color:", value);
            project_color_label.color = value;
            project_color = index;
        }
    }

    NotificationPopup {
        id: notifPopup
        width: units.gu(80)
        height: units.gu(100)
        onClosed: console.log("Notification dismissed")
    }

    Component.onCompleted: {
        if (recordid !== 0) {
            let project = Project.getProjectDetails(recordid);
            if (project && Object.keys(project).length > 0) {} else {
                notifPopup.open("Failed", "Unable to open the project details", "error");
            }
            console.log("=== Project Details ===");
            console.log("id:", project.id);
            console.log("name:", project.name);
            console.log("account_id:", project.account_id);
            console.log("parent_id:", project.parent_id);
            console.log("planned_start_date:", project.planned_start_date);
            console.log("planned_end_date:", project.planned_end_date);
            console.log("allocated_hours:", project.allocated_hours);
            console.log("favorites:", project.favorites);
            console.log("last_update_status:", project.last_update_status);
            console.log("description:", project.description);
            console.log("last_modified:", project.last_modified);
            console.log("color_pallet:", project.color_pallet);
            console.log("status:", project.status);
            console.log("odoo_record_id:", project.odoo_record_id);

            let instanceId = (project.account_id !== undefined && project.account_id !== null) ? project.account_id : -1;
            let ppid = (project.parent_id !== undefined && project.parent_id !== null) ? project.parent_id : -1;

            //dont integrate the parnet projct
            workItem.applyDeferredSelection(instanceId, project.parent_id, -1);

            description_text.text = project.description || "";

            project_name.text = project.name;
            project_color = project.color_pallet;
            project_color_label.color = colorpicker.getColorByIndex(project.color_pallet);
            date_range_widget.setDateRange(project.planned_start_date, project.planned_end_date);
        } else {
            //do nothing as we are creating project
            recordid = 0;
            workItem.applyDeferredSelection(Accounts.getDefaultAccountId(), -1, -1);
            //accountCombo.load()
        }
    }
}
