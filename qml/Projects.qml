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
                    //  console.log("Account DB ID:", ids.accountDbId);

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
                    //  console.log(JSON.stringify(project_data, null, 4));
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
                        showSubProjectSelector: false
                        showProjectSelector: !isReadOnly  // Hide project selector in read-only mode
                        width: scrollview.width - units.gu(2)
                        height: units.gu(5)
                    }
                }
            }

            Row {
                id: myRow1
                anchors.top: myRow1a.bottom
                anchors.left: parent.left
                topPadding: units.gu(10)
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
            // console.log("Selected index:", index);
            // console.log("Selected color:", value);
            project_color_label.color = value;
            project_color = index;
        }
    }

    NotificationPopup {
        id: notifPopup
        width: units.gu(80)
        height: units.gu(100)
        // onClosed: console.log("Notification dismissed")
    }

    Timer {
        id: selectorSetupTimer
        interval: 500
        repeat: false
        property var projectParentId: -1
        property var currentProjectId: -1
        property var instanceId: -1
        onTriggered: {
            console.log("=== Setting up WorkItemSelector (after 500ms delay) ===");
            // When viewing a project, show it as the selected project in the selector
            // If it has a parent, the parent will be shown as the parent project, and this will be the subproject
            if (projectParentId !== -1) {
                // This project has a parent - show parent as project and this as subproject
                console.log("Configuring selector with parent:", projectParentId, "current:", currentProjectId);
                workItem.applyDeferredSelection(instanceId, projectParentId, currentProjectId, -1, -1, -1);
            } else {
                // This is a parent project - show it as the selected main project
                console.log("Configuring selector with main project:", currentProjectId);
                workItem.applyDeferredSelection(instanceId, currentProjectId, -1, -1, -1, -1);
            }
            
            console.log("=== WorkItemSelector configured ===");
            
            // Start final verification timer
            finalVerificationTimer.start();
        }
    }

    Timer {
        id: finalVerificationTimer
        interval: 1000
        repeat: false
        onTriggered: {
            console.log("Final field values verification (after 1000ms total delay):");
            console.log("  - project_name has text property:", typeof project_name.text);
            console.log("  - description_text has text property:", typeof description_text.text);
            console.log("  - hours_text has text property:", typeof hours_text.text);
            
            // Set view mode to read-only
            console.log("Setting isReadOnly to true for view mode");
            isReadOnly = true;
        }
    }

    Component.onCompleted: {
        console.log("Projects.qml Component.onCompleted - recordid:", recordid, "isReadOnly:", isReadOnly);
        
        if (recordid !== 0) {
            console.log("=== Loading Project Details for recordid:", recordid, "===");
            let project = Project.getProjectDetails(recordid);
            console.log("Raw project data returned:", JSON.stringify(project));
            
            if (project && Object.keys(project).length > 0) {
                console.log("Project loaded successfully - field details:");
                console.log("  - id:", project.id);
                console.log("  - name:", project.name);
                console.log("  - account_id:", project.account_id);
                console.log("  - parent_id:", project.parent_id);
                console.log("  - description:", project.description);
                console.log("  - allocated_hours:", project.allocated_hours);
                console.log("  - color_pallet:", project.color_pallet);
            } else {
                console.log("Failed to load project details - empty or null project object");
                notifPopup.open("Failed", "Unable to open the project details", "error");
                return;
            }
            // console.log("=== Project Details ===");
            // console.log("id:", project.id);
            // console.log("name:", project.name);
            // console.log("account_id:", project.account_id);
            // console.log("parent_id:", project.parent_id);
            // console.log("planned_start_date:", project.planned_start_date);
            // console.log("planned_end_date:", project.planned_end_date);
            // console.log("allocated_hours:", project.allocated_hours);
            // console.log("favorites:", project.favorites);
            // console.log("last_update_status:", project.last_update_status);
            // console.log("description:", project.description);
            // console.log("last_modified:", project.last_modified);
            // console.log("color_pallet:", project.color_pallet);
            // console.log("status:", project.status);
            // console.log("odoo_record_id:", project.odoo_record_id);

            let instanceId = (project.account_id !== undefined && project.account_id !== null) ? project.account_id : -1;
            let projectParentId = (project.parent_id !== undefined && project.parent_id !== null) ? project.parent_id : -1;
            let currentProjectId = (project.odoo_record_id !== undefined && project.odoo_record_id !== null) ? project.odoo_record_id : project.id;

            // Set the form fields with project details FIRST
            console.log("=== Setting form fields ===");
            console.log("Setting description_text.text to:", project.description || "");
            description_text.text = project.description || "";
            
            console.log("Setting project_name.text to:", project.name || "");
            project_name.text = project.name || "";
            
            console.log("Setting hours_text.text to:", project.allocated_hours || "1");
            // Convert HH:MM format back to hours if needed
            let hoursValue = project.allocated_hours || "1";
            if (typeof hoursValue === "string" && hoursValue.includes(":")) {
                // Convert HH:MM to decimal hours
                let parts = hoursValue.split(":");
                let hours = parseInt(parts[0] || 0);
                let minutes = parseInt(parts[1] || 0);
                hoursValue = hours + (minutes / 60.0);
                console.log("Converted time format", project.allocated_hours, "to decimal hours:", hoursValue);
            }
            hours_text.text = hoursValue.toString();
            
            console.log("Setting project_color to:", project.color_pallet || 0);
            // Handle color_pallet - it might be an index number or a color string
            let colorIndex = 0;
            if (project.color_pallet) {
                if (typeof project.color_pallet === "string" && project.color_pallet.startsWith("#")) {
                    // It's a hex color, we need to find the corresponding index
                    // For now, default to 0, but ideally we'd have a function to find the index
                    console.log("Color is hex format:", project.color_pallet, "defaulting to index 0");
                    colorIndex = 0;
                } else {
                    // It's likely an index number (as string or number)
                    colorIndex = parseInt(project.color_pallet) || 0;
                    console.log("Color parsed as index:", colorIndex);
                }
            }
            project_color = colorIndex;
            
            console.log("Setting project_color_label.color via colorpicker.getColorByIndex");
            project_color_label.color = colorpicker.getColorByIndex(colorIndex);
            
            console.log("Setting date_range_widget dates:", project.planned_start_date, project.planned_end_date);
            date_range_widget.setDateRange(project.planned_start_date, project.planned_end_date);
            
            console.log("=== Form fields set complete ===");
            
            // Store the IDs in the timer properties and start the deferred setup
            selectorSetupTimer.instanceId = instanceId;
            selectorSetupTimer.projectParentId = projectParentId;
            selectorSetupTimer.currentProjectId = currentProjectId;
            selectorSetupTimer.start();
        } else {
            //do nothing as we are creating project
            recordid = 0;
            workItem.applyDeferredSelection(Accounts.getDefaultAccountId(), -1, -1);
            //accountCombo.load()
        }
    }
}
