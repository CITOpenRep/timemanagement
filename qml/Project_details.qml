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
import "../models/Utils.js" as Utils
import "components"

Page {
    id: projectDetails
    title: "Project Details"
    header: PageHeader {
        StyleHints {
            foregroundColor: LomiriColors.orange
            backgroundColor: LomiriColors.background
            dividerColor: LomiriColors.slate
        }

        title: projectDetails.title
        ActionBar {
            numberOfSlots: 2
            anchors.right: parent.right
            actions: [
                Action {
                    iconSource: enabled ? "images/save.png" : ""
                    text: "Edit"
                    visible: isReadOnly
                    onTriggered: {
                        isReadOnly = !isReadOnly;
                    }
                },
                Action {
                    iconName: "save"
                    text: "Save"
                    visible: !isReadOnly
                    onTriggered: {
                        console.log("color is" + projectDetails.projectcolor);
                        // isReadOnly = !isReadOnly
                        var project_data = {
                            'account_id': selectedInstanceId,
                            'name': project_text.text,
                            'planned_start_date': planned_start_date_text.text == 'mm/dd/yy' ? 0 : planned_start_date_text.text,
                            'planned_end_date': planned_end_date_text.text == 'mm/dd/yy' ? 0 : planned_end_date_text.text,
                            'parent_id': selectedParentId,
                            'allocated_hours': allocated_hours_text.text,
                            'description': description_text.text,
                            'favorites': favorites,
                            'color': project_color_index,
                            'status': "updated"
                        };
                        var response = Project.createUpdateProject(project_data, recordid);
                        if (response) {
                            isVisibleMessage = true;
                            isSaved = response.is_success;
                            saveMessage = response.message;
                            if (isSaved) {
                                isReadOnly = !isReadOnly;
                                notifPopup.open("Saved", "Project data has been saved successfully", "success");
                            }
                        }
                    }
                }
            ]
        }
    }

    property var recordid: 0
    property bool isSaved: true
    property int project_color_index: 0
    property string saveMessage: ''
    property bool isVisibleMessage: false
    property bool workpersonaSwitchState: true
    property bool isReadOnly: true
    property var currentProject: {}
    property int favorites: 0
    property int selectedInstanceId: 0
    property int selectedParentId: 0
    property var projectcolor: "grey"

    ListModel {
        id: instanceModel
    }

    ListModel {
        id: projectModel
    }

    function setInstanceList() {
        var instances = Utils.accountlistDataGet();
        instanceModel.clear();
        for (var instance = 0; instance < instances.length; instance++) {
            instanceModel.append({
                'id': instances[instance].id,
                'name': instances[instance].name
            });
        }
    }

    function setParentProjectList() {
        var parentProjects = Project.fetch_parent_project_list(selectedInstanceId, workpersonaSwitchState);
        projectModel.clear();
        for (var parent = 0; parent < parentProjects.length; parent++) {
            projectModel.append({
                'id': parentProjects[parent].id,
                'name': parentProjects[parent].name
            });
        }
    }

    Text {
        id: saveMessageText
        text: saveMessage
        color: isSaved ? "green" : "red"
        anchors.top: header.bottom
        anchors.topMargin: 10
        leftPadding: units.gu(2)
        visible: isVisibleMessage
    }

    Flickable {
        id: projectDetailPageFlickable
        anchors.fill: parent
        contentHeight: projectDetailLomiriShape.height + 1000
        flickableDirection: Flickable.VerticalFlick
        anchors.top: saveMessageText.bottom
        anchors.topMargin: header.height + units.gu(4)
        width: parent.width

        LomiriShape {
            id: projectDetailLomiriShape
            anchors.top: saveMessageText.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            radius: "large"
            width: parent.width
            height: parent.height

            Row {
                id: instanceRow
                anchors.left: parent.left
                topPadding: 10
                Column {
                    leftPadding: units.gu(2)
                    Rectangle {
                        width: units.gu(10)
                        height: units.gu(5)
                        Label {
                            id: instance_label
                            text: "Instance"
                            font.bold: true
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
                Column {
                    leftPadding: units.gu(3)
                    ComboBox {
                        id: instance_combo
                        width: Screen.desktopAvailableWidth < units.gu(250) ? units.gu(30) : units.gu(60)
                        height: units.gu(5)
                        anchors.centerIn: parent.centerIn
                        flat: true
                        clip: true
                        textRole: "name"
                        model: instanceModel
                        onAccepted: {
                            selectedInstanceId = instanceModel.get(currentIndex).id;
                            setParentProjectList();
                            parent_project_combo.currentIndex = -1;
                        }

                        onCurrentIndexChanged: {
                            if (currentIndex >= 0) {
                                selectedInstanceId = instanceModel.get(currentIndex).id;
                                setParentProjectList();
                                parent_project_combo.currentIndex = -1;
                            }
                        }
                    }
                }
            }

            Row {
                id: projectNameRow
                anchors.top: instanceRow.bottom
                anchors.left: parent.left
                topPadding: 10
                Column {
                    leftPadding: units.gu(2)
                    Rectangle {
                        width: units.gu(10)
                        height: units.gu(5)
                        Label {
                            id: project_label
                            text: "Name"
                            font.bold: true
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
                Column {
                    leftPadding: units.gu(3)
                    TextField {
                        id: project_text
                        readOnly: isReadOnly
                        width: Screen.desktopAvailableWidth < units.gu(250) ? units.gu(30) : units.gu(60)
                        text: currentProject.name
                    }
                }
            }

            Row {
                id: plannedStartDateRow
                anchors.top: projectNameRow.bottom
                anchors.left: parent.left
                topPadding: 10
                Column {
                    leftPadding: units.gu(2)
                    Rectangle {
                        width: units.gu(10)
                        height: units.gu(5)
                        Label {
                            id: plannedstartdate_label
                            text: "Start Date"
                            font.bold: true
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
                Column {
                    leftPadding: units.gu(3)
                    TextField {
                        id: planned_start_date_text
                        readOnly: isReadOnly
                        width: Screen.desktopAvailableWidth < units.gu(250) ? units.gu(30) : units.gu(60)
                        anchors.centerIn: parent.centerIn
                        text: currentProject.start_date
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (planned_start_date_field.visible === false) {
                                    if (!isReadOnly) {
                                        planned_start_date_field.visible = !planned_start_date_field.visible;
                                        planned_start_date_text.text = "";
                                    }
                                } else {
                                    planned_start_date_field.visible = !planned_start_date_field.visible;
                                    planned_start_date_text.text = Qt.formatDate(planned_start_date_field.date, "MM/dd/yyyy");
                                }
                            }
                        }
                    }
                    DatePicker {
                        id: planned_start_date_field
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
                id: plannedEndDateRow
                anchors.top: plannedStartDateRow.bottom
                anchors.left: parent.left
                topPadding: 10
                Column {
                    leftPadding: units.gu(2)
                    Rectangle {
                        width: units.gu(10)
                        height: units.gu(5)
                        Label {
                            id: plannedenddate_label
                            text: "End Date"
                            font.bold: true
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
                Column {
                    leftPadding: units.gu(3)
                    TextField {
                        id: planned_end_date_text
                        readOnly: isReadOnly
                        width: Screen.desktopAvailableWidth < units.gu(250) ? units.gu(30) : units.gu(60)
                        anchors.centerIn: parent.centerIn
                        text: currentProject.end_date
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (planned_end_date_field.visible === false) {
                                    if (!isReadOnly) {
                                        planned_end_date_field.visible = !planned_end_date_field.visible;
                                        planned_end_date_text.text = "";
                                    }
                                } else {
                                    planned_end_date_field.visible = !planned_end_date_field.visible;
                                    planned_end_date_text.text = Qt.formatDate(planned_end_date_field.date, "MM/dd/yyyy");
                                }
                            }
                        }
                    }
                    DatePicker {
                        id: planned_end_date_field
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
                id: parentProjectRow
                anchors.top: plannedEndDateRow.bottom
                anchors.left: parent.left
                topPadding: 10
                Column {
                    leftPadding: units.gu(2)
                    Rectangle {
                        width: units.gu(10)
                        height: units.gu(5)
                        Label {
                            id: projectparent_label
                            text: "Parent"
                            font.bold: true
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
                Column {
                    leftPadding: units.gu(3)
                    ComboBox {
                        id: parent_project_combo
                        editable: true
                        width: Screen.desktopAvailableWidth < units.gu(250) ? units.gu(30) : units.gu(60)
                        height: units.gu(5)
                        anchors.centerIn: parent.centerIn
                        flat: true
                        clip: true
                        textRole: "name"
                        model: projectModel
                        onCurrentIndexChanged: {
                            selectedParentId = 0;
                            if (currentIndex >= 0) {
                                selectedParentId = projectModel.get(currentIndex).id;
                            }
                        }

                        onDisplayTextChanged: {
                            inputDebounceTimer.restart();
                        }

                        Timer {
                            id: inputDebounceTimer
                            interval: 300
                            onTriggered: {
                                var enteredText = parent_project_combo.displayText;
                                var foundIndex = -1;
                                for (var i = 0; i < projectModel.count; i++) {
                                    if (projectModel.get(i).name === enteredText) {
                                        foundIndex = i;
                                        break;
                                    }
                                }

                                if (foundIndex !== -1) {
                                    parent_project_combo.currentIndex = foundIndex;
                                    selectedParentId = projectModel.get(foundIndex).id;
                                } else {
                                    parent_project_combo.currentIndex = -1;
                                    selectedParentId = 0;
                                }
                            }
                        }
                    }
                }
            }

            Row {
                id: allocatedHoursRow
                anchors.top: parentProjectRow.bottom
                anchors.left: parent.left
                topPadding: 10
                Column {
                    leftPadding: units.gu(2)
                    Rectangle {
                        width: units.gu(10)
                        height: units.gu(5)
                        Label {
                            id: allocatedhours_label
                            text: "Allocated Hours"
                            font.bold: true
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
                Column {
                    leftPadding: units.gu(3)
                    TextField {
                        id: allocated_hours_text
                        readOnly: isReadOnly
                        width: Screen.desktopAvailableWidth < units.gu(250) ? units.gu(30) : units.gu(60)
                        text: currentProject.allocated_hours
                    }
                }
            }

            Row {
                id: descriptionRow
                anchors.top: allocatedHoursRow.bottom
                anchors.left: parent.left
                topPadding: 10
                Column {
                    leftPadding: units.gu(2)
                    Rectangle {
                        width: units.gu(10)
                        height: units.gu(5)
                        Label {
                            id: description_label
                            text: "Description"
                            font.bold: true
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
                Column {
                    leftPadding: units.gu(3)
                    TextField {
                        id: description_text
                        readOnly: isReadOnly
                        width: Screen.desktopAvailableWidth < units.gu(250) ? units.gu(30) : units.gu(60)
                        text: currentProject.description
                    }
                }
            }
            ColorPicker {
                id: pickerDialog
                onColorPicked: {
                    console.log("User picked: " + colorIndex);
                    projectcolor = Utils.getColorFromOdooIndex(colorIndex);
                    project_color_index = colorIndex;
                }
            }
            Row {
                id: colorSelectionRow
                anchors.top: descriptionRow.bottom
                anchors.left: parent.left
                topPadding: 10
                leftPadding: units.gu(2)
                Row {
                    spacing: 6

                    TSButton {
                        id: selectColorBtn
                        text: "Select Color"
                        onClicked: pickerDialog.open()
                    }

                    Rectangle {
                        width: 16
                        height: 16
                        color: projectcolor  // Bind to selected color
                        radius: 3
                        border.color: "black"
                        border.width: 1
                        anchors.verticalCenter: selectColorBtn.verticalCenter
                    }
                }
            }

            Row {
                id: priorityRow
                anchors.top: colorSelectionRow.bottom
                anchors.left: parent.left
                topPadding: 10
                Column {
                    leftPadding: units.gu(2)
                    Rectangle {
                        width: units.gu(10)
                        height: units.gu(5)
                        Label {
                            id: priority_label
                            text: "Priority"
                            font.bold: true
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
                Column {
                    leftPadding: units.gu(3)
                    Row {
                        id: img_star
                        width: units.gu(20)
                        height: units.gu(20)
                        spacing: 5
                        property int selectedPriority: 0

                        Repeater {
                            model: 1
                            delegate: Item {
                                width: units.gu(5)
                                height: units.gu(5)

                                Image {
                                    id: starImage
                                    source: (index < favorites) ? "images/star-active.svg" : "images/starinactive.svg"
                                    anchors.fill: parent
                                    smooth: true

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            if (index + 1 === favorites) {
                                                favorites = !favorites;
                                            } else {
                                                favorites = !favorites;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
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
        if (recordid != 0) {
            currentProject = Project.get_project_detail(recordid, workpersonaSwitchState);
            favorites = currentProject.favorites;
            setInstanceList();
            selectedInstanceId = currentProject.account_id;
            setParentProjectList();
            selectedParentId = currentProject.parent_id || 0;
            for (var i = 0; i < instanceModel.count; i++) {
                if (instanceModel.get(i).id === selectedInstanceId) {
                    instance_combo.currentIndex = i;
                    instance_combo.editText = instanceModel.get(i).name;
                }
            }

            for (var i = 0; i < projectModel.count; i++) {
                if (projectModel.get(i).id === selectedParentId) {
                    parent_project_combo.currentIndex = i;
                    parent_project_combo.editText = projectModel.get(i).name;
                }
            }
            projectcolor = currentProject.selected_color;
            console.log("got the color from db" + currentProject.selected_color);
            currentProject.description = currentProject.description.replace(/<[^>]+>/g, " ").replace(/<p>;/g, "").replace(/&nbsp;/g, "").replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&amp;/g, "&").replace(/&quot;/g, "\"").replace(/&#39;/g, "'").trim() || "";
        } else {
            setInstanceList();
            selectedInstanceId = instanceModel.get(0).id;
            setParentProjectList();
            instance_combo.currentIndex = instanceModel.get(0).id;
            instance_combo.editText = instanceModel.get(0).id;
            isReadOnly = false;
            currentProject = {
                "allocated_hours": "00:00"
            };
        }
    }
}
