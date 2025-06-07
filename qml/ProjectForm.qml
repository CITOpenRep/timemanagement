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
import QtQuick.Window 2.2
import QtQuick.Controls 2.2
import QtQuick.LocalStorage 2.7
import Ubuntu.Components 1.3 as Ubuntu
import Lomiri.Components.Themes 1.3

Item {
    width: parent.width
    height: parent.height

    property int selectedAccountUserId: 0
    property int selectedProjectId: 0
    property bool isProjectSaved: false
    property bool isProjectClicked: false
    property string selectedColor: ''

    property var color_indexes: ["#ffffff", "#111111", "#960334", "#FB3778", "#7C0396", "#D937FB", "#030396", "#3737FB", "#008585", "#33FFFF", "#038203", "#37FB37", "#787802", "#FBFB37", "#964D03", "#FB9937"]

    function createProject(data) {
        var db = LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
        db.transaction(function (tx) {
            var result = tx.executeSql('INSERT INTO project_project_app (name,parent_id,planned_start_date,planned_end_date,favorites,allocated_hours,description,color_pallet,last_modified) \
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)', [data.nameInput, data.selectedProjectId, data.startDateInput, data.endDateInput, data.img_star, data.initialInput, data.descriptionInput, data.color_pallet, new Date().toISOString()]);
            tx.executeSql('commit');
            isProjectSaved = true;
            isProjectClicked = true;
        });
    }

    Rectangle {
        id: newProject
        width: parent.width
        height: isDesktop() ? 60 : 120
        anchors.top: parent.top
        anchors.topMargin: isDesktop() ? 60 : 120
        color: "#FFFFFF"
        z: 1

        Rectangle {
            width: parent.width
            height: 2
            color: "#DDDDDD"
            anchors.bottom: parent.bottom
        }

        Row {
            id: row_id
            width: parent.width
            anchors.verticalCenter: parent.verticalCenter
            anchors.fill: parent
            spacing: isDesktop() ? 20 : 40
            anchors.left: parent.left
            anchors.leftMargin: isDesktop() ? 55 : -10
            anchors.right: parent.right
            anchors.rightMargin: isDesktop() ? 15 : 20

            Rectangle {
                color: "transparent"
                width: parent.width / 3
                anchors.verticalCenter: parent.verticalCenter
                height: parent.height

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    ToolButton {
                        width: isDesktop() ? 40 : 80
                        height: isDesktop() ? 35 : 80
                        background: Rectangle {
                            color: "transparent"
                        }
                        contentItem: Ubuntu.Icon {
                            name: "back"
                        }
                        onClicked: {
                            stackView.push(projectList);
                        }
                    }

                    Label {
                        text: "Project"
                        font.pixelSize: isDesktop() ? 20 : 40
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: ToolButton.right
                        font.bold: true
                        color: "#121944"
                    }
                }
            }

            Rectangle {
                color: "transparent"
                width: parent.width / 3
                height: parent.height
                anchors.horizontalCenter: parent.horizontalCenter

                Text {
                    id: projectSavedMessage
                    text: isProjectSaved ? "Project is Saved successfully!" : "Project could not be saved!"
                    color: isProjectSaved ? "green" : "red"
                    visible: isProjectClicked
                    font.pixelSize: isDesktop() ? 18 : phoneLarg() ? 30 : 40
                    horizontalAlignment: Text.AlignHCenter
                    anchors.centerIn: parent
                }
            }

            Rectangle {
                color: "transparent"
                width: parent.width / 3
                anchors.verticalCenter: parent.verticalCenter
                height: parent.height
                anchors.right: parent.right

                Button {
                    id: rightButton
                    width: isDesktop() ? 20 : 70
                    height: isDesktop() ? 20 : 70
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right

                    Image {
                        source: "images/right.svg"
                        width: isDesktop() ? 20 : 50
                        height: isDesktop() ? 20 : 50
                    }

                    background: Rectangle {
                        color: "transparent"
                        radius: 10
                        border.color: "transparent"
                    }
                    onClicked: {
                        if (nameInput.text.length > 1) {
                            var objectData = {
                                selectedAccountUserId: selectedAccountUserId,
                                nameInput: nameInput.text,
                                selectedProjectId: selectedProjectId,
                                startDateInput: startDateInput.text,
                                endDateInput: endDateInput.text,
                                img_star: img_star.selectedPriority,
                                initialInput: initialInput.text,
                                descriptionInput: descriptionInput.text,
                                color_pallet: selectedColor
                            };
                            createProject(objectData);
                            isProjectSaved = true;
                            isProjectClicked = true;
                            typingTimers.start();
                        } else {
                            isProjectSaved = false;
                            isProjectClicked = true;
                            typingTimers.start();
                        }
                    }
                }
                Timer {
                    id: typingTimers
                    interval: 1500
                    running: false
                    repeat: false
                    onTriggered: {
                        if (isProjectSaved) {
                            selectedAccountUserId = 0;
                            nameInput.text = "";
                            selectedProjectId = 0;
                            img_star.selectedPriority = 0;
                            initialInput.text = "";
                            descriptionInput.text = "";
                            projectInput.text = "";
                            isProjectSaved = false;
                            isProjectClicked = false;
                        } else {
                            isTimesheetClicked = false;
                            isProjectClicked = false;
                        }
                    }
                }
            }
        }
    }

    Flickable {
        id: flickableContainer
        width: parent.width

        height: parent.height
        contentHeight: projectForm.childrenRect.height + 350
        anchors.fill: parent
        flickableDirection: Flickable.VerticalFlick
        clip: true
        Rectangle {
            id: projectForm
            anchors.top: parent.top
            anchors.topMargin: isDesktop() ? 200 : phoneLarg() ? 270 : 300
            anchors.left: parent.left
            anchors.leftMargin: isDesktop() ? 70 : 20
            anchors.right: parent.right
            anchors.rightMargin: isDesktop() ? 10 : 20
            color: "#ffffff"
            height: childrenRect.height + 20

            Row {
                id: add_date_flow
                spacing: isDesktop() ? 100 : phoneLarg() ? 250 : 250
                anchors.verticalCenterOffset: -height * 1.5
                anchors.horizontalCenter: parent.horizontalCenter

                Column {
                    spacing: isDesktop() ? 20 : 40
                    width: 90
                    Label {
                        text: "Instance"
                        width: 150
                        visible: workpersonaSwitchState
                        height: isDesktop() ? 25 : 80
                        font.pixelSize: isDesktop() ? 18 : 40
                    }
                    Label {
                        text: "Project Title"
                        width: 150
                        height: isDesktop() ? 25 : 80
                        font.pixelSize: isDesktop() ? 18 : 40
                    }
                    Label {
                        text: "Planned Start Date"
                        width: 150
                        height: isDesktop() ? 25 : 80
                        font.pixelSize: isDesktop() ? 18 : 40
                    }
                    Label {
                        text: "Planned End Date"
                        width: 150
                        height: isDesktop() ? 25 : 80
                        font.pixelSize: isDesktop() ? 18 : 40
                    }

                    Label {
                        text: "Parent Project"
                        width: 150
                        height: isDesktop() ? 25 : 80
                        font.pixelSize: isDesktop() ? 18 : 40
                    }
                    Label {
                        text: "Allocated Hours"
                        width: 150
                        height: isDesktop() ? 25 : 80
                        font.pixelSize: isDesktop() ? 18 : 40
                    }

                    Label {
                        text: "Description"
                        width: 150
                        height: descriptionInput.height
                        font.pixelSize: isDesktop() ? 18 : 40
                    }
                    Label {
                        text: "Priority"
                        width: 150
                        height: isDesktop() ? 25 : 80
                        font.pixelSize: isDesktop() ? 18 : 40
                    }
                    Label {
                        text: "color"
                        width: 150
                        height: isDesktop() ? 25 : 80
                        font.pixelSize: isDesktop() ? 18 : 40
                    }
                }
                Column {
                    spacing: isDesktop() ? 20 : 40

                    Rectangle {
                        width: isDesktop() ? 500 : 750
                        height: isDesktop() ? 25 : 80
                        color: "transparent"
                        visible: workpersonaSwitchState

                        Rectangle {
                            width: parent.width
                            height: isDesktop() ? 1 : 2
                            color: "black"
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                        }

                        ListModel {
                            id: accountList
                        }

                        TextInput {
                            id: accountInput
                            width: parent.width
                            height: parent.height
                            font.pixelSize: isDesktop() ? 18 : 40
                            anchors.fill: parent
                            Text {
                                id: accountplaceholder
                                text: "Instance"
                                font.pixelSize: isDesktop() ? 18 : 40
                                color: "#aaa"
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    var result = accountlistDataGet();
                                    if (result) {
                                        accountList.clear();
                                        for (var i = 0; i < result.length; i++) {
                                            accountList.append(result[i]);
                                        }
                                        menuAccount.open();
                                    }
                                }
                            }

                            Menu {
                                id: menuAccount
                                x: accountInput.x
                                y: accountInput.y + accountInput.height
                                width: accountInput.width

                                Repeater {
                                    model: accountList

                                    MenuItem {
                                        width: parent.width
                                        height: isDesktop() ? 40 : 80
                                        property int accountId: model.id
                                        property string accuntName: model.name || ''
                                        Text {
                                            text: accuntName
                                            font.pixelSize: isDesktop() ? 18 : 40
                                            bottomPadding: 5
                                            topPadding: 5
                                            //anchors.centerIn: parent
                                            color: "#000"
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.left: parent.left
                                            anchors.leftMargin: 10
                                            wrapMode: Text.WordWrap
                                            elide: Text.ElideRight
                                            maximumLineCount: 2
                                        }

                                        onClicked: {
                                            hasSubTask = false;
                                            accountInput.text = accuntName;
                                            selectedAccountUserId = accountId;
                                            menuAccount.close();
                                        }
                                    }
                                }
                            }

                            onTextChanged: {
                                if (accountInput.text.length > 0) {
                                    accountplaceholder.visible = false;
                                } else {
                                    accountplaceholder.visible = true;
                                }
                            }
                        }
                    }

                    Rectangle {
                        width: isDesktop() ? 500 : 750
                        height: isDesktop() ? 25 : 80
                        color: "transparent"

                        Rectangle {
                            width: parent.width
                            height: isDesktop() ? 1 : 2
                            color: "black"
                            anchors.bottom: parent.bottom
                        }

                        TextInput {
                            id: nameInput
                            width: parent.width
                            height: parent.height
                            font.pixelSize: isDesktop() ? 18 : 40
                            anchors.fill: parent

                            Text {
                                id: namePlaceholder
                                text: "Name"
                                font.pixelSize: isDesktop() ? 18 : 40
                                color: "#aaa"
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                            }

                            onTextChanged: {
                                namePlaceholder.visible = nameInput.text.length === 0;
                            }
                        }
                    }

                    Rectangle {
                        width: isDesktop() ? 500 : 750
                        height: isDesktop() ? 25 : 80
                        color: "transparent"

                        Rectangle {
                            width: parent.width
                            height: isDesktop() ? 1 : 2
                            color: "black"
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                        }
                        TextInput {
                            id: startDateInput
                            width: parent.width
                            height: parent.height
                            font.pixelSize: isDesktop() ? 18 : phoneLarg() ? 35 : 50
                            anchors.fill: parent
                            Text {
                                id: startDateplaceholder
                                text: "Date"
                                font.pixelSize: isDesktop() ? 18 : 30
                                color: "#aaa"
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                            }

                            Dialog {
                                id: startDateDialog
                                width: isDesktop() ? 0 : phoneLarg() ? 550 : 700
                                height: isDesktop() ? 0 : phoneLarg() ? 450 : 650
                                padding: 0
                                margins: 0
                                bottomMargin: 500
                                visible: false

                                DatePicker {
                                    id: datePickerstartDate
                                    onClicked: {
                                        startDateInput.text = Qt.formatDate(date, 'M/d/yyyy').toString();
                                    }
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    var now = new Date();
                                    datePickerstartDate.selectedDate = now;
                                    datePickerstartDate.currentIndex = now.getMonth();
                                    datePickerstartDate.selectedYear = now.getFullYear();
                                    startDateDialog.visible = true;
                                }
                            }

                            onTextChanged: {
                                if (startDateInput.text.length > 0) {
                                    startDateplaceholder.visible = false;
                                } else {
                                    startDateplaceholder.visible = true;
                                }
                            }
                            function formatDate(date) {
                                var month = date.getMonth() + 1;
                                var day = date.getDate();
                                var year = date.getFullYear();
                                return month + '/' + day + '/' + year;
                            }

                            Component.onCompleted: {
                                var currentDate = new Date();
                                startDateInput.text = formatDate(currentDate);
                            }
                        }
                    }
                    Rectangle {
                        width: isDesktop() ? 500 : 750
                        height: isDesktop() ? 25 : 80
                        color: "transparent"

                        Rectangle {
                            width: parent.width
                            height: isDesktop() ? 1 : 2
                            color: "black"
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                        }
                        TextInput {
                            id: endDateInput
                            width: parent.width
                            height: parent.height
                            font.pixelSize: isDesktop() ? 18 : phoneLarg() ? 35 : 50
                            anchors.fill: parent
                            Text {
                                id: endDateplaceholder
                                text: "Date"
                                font.pixelSize: isDesktop() ? 18 : 30
                                color: "#aaa"
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                            }

                            Dialog {
                                id: endDateDialog
                                width: isDesktop() ? 0 : phoneLarg() ? 550 : 700
                                height: isDesktop() ? 0 : phoneLarg() ? 450 : 650
                                padding: 0
                                margins: 0
                                bottomMargin: 500
                                visible: false

                                DatePicker {
                                    id: datePickerendDate
                                    onClicked: {
                                        endDateInput.text = Qt.formatDate(date, 'M/d/yyyy').toString();
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    var now = new Date();
                                    datePickerendDate.selectedDate = now;
                                    datePickerendDate.currentIndex = now.getMonth();
                                    datePickerendDate.selectedYear = now.getFullYear();
                                    endDateDialog.visible = true;
                                }
                            }
                            onTextChanged: {
                                if (endDateInput.text.length > 0) {
                                    endDateplaceholder.visible = false;
                                } else {
                                    endDateplaceholder.visible = true;
                                }
                            }
                            function formatDate(date) {
                                var month = date.getMonth() + 1;
                                var day = date.getDate();
                                var year = date.getFullYear();
                                return month + '/' + day + '/' + year;
                            }

                            Component.onCompleted: {
                                var currentDate = new Date();
                                endDateInput.text = formatDate(currentDate);
                            }
                        }
                    }
                    Rectangle {
                        width: isDesktop() ? 500 : 750
                        height: isDesktop() ? 25 : 80
                        color: "transparent"

                        Rectangle {
                            width: parent.width
                            height: isDesktop() ? 1 : 2
                            color: "black"
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                        }

                        ListModel {
                            id: projectsListModel
                        }

                        TextInput {
                            id: projectInput
                            width: parent.width
                            height: parent.height
                            font.pixelSize: isDesktop() ? 18 : 40
                            anchors.fill: parent
                            Text {
                                id: projectplaceholder
                                text: "Project"
                                font.pixelSize: isDesktop() ? 18 : 40
                                color: "#aaa"
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    projectsListModel.clear();
                                    var result = fetch_projects(0);
                                    for (var i = 0; i < result.length; i++) {
                                        projectsListModel.append({
                                            'id': result[i].id,
                                            'name': result[i].name
                                        });
                                    }

                                    menu.open();
                                }
                            }

                            Menu {
                                id: menu
                                x: projectInput.x
                                y: projectInput.y + projectInput.height
                                width: projectInput.width

                                Repeater {
                                    model: projectsListModel

                                    MenuItem {
                                        width: parent.width
                                        height: isDesktop() ? 40 : 80
                                        property int projectId: model.id
                                        property string projectName: model.name || ''
                                        Text {
                                            text: projectName
                                            font.pixelSize: isDesktop() ? 18 : 40
                                            bottomPadding: 5
                                            topPadding: 5
                                            //anchors.centerIn: parent
                                            color: "#000"
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.left: parent.left
                                            anchors.leftMargin: 10
                                            wrapMode: Text.WordWrap
                                            elide: Text.ElideRight
                                            maximumLineCount: 2
                                        }

                                        onClicked: {
                                            projectInput.text = projectName;
                                            selectedProjectId = projectId;
                                            menu.close();
                                        }
                                    }
                                }
                            }

                            onTextChanged: {
                                if (projectInput.text.length > 0) {
                                    projectplaceholder.visible = false;
                                } else {
                                    projectplaceholder.visible = true;
                                }
                            }
                        }
                    }

                    Rectangle {
                        width: isDesktop() ? 500 : 750
                        height: isDesktop() ? 25 : 80

                        color: "transparent"

                        Rectangle {
                            width: parent.width
                            height: isDesktop() ? 1 : 2
                            color: "black"
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                        }
                        TextInput {
                            id: initialInput
                            width: parent.width
                            height: parent.height
                            font.pixelSize: isDesktop() ? 20 : 40
                            anchors.fill: parent

                            Text {
                                id: initialInputPlaceholder
                                text: "0.0"
                                color: "#aaa"
                                font.pixelSize: isDesktop() ? 20 : 50
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                            }

                            onTextChanged: {
                                if (initialInput.text.length > 0) {
                                    initialInputPlaceholder.visible = false;
                                } else {
                                    initialInputPlaceholder.visible = true;
                                }
                            }
                        }
                    }

                    Rectangle {
                        width: isDesktop() ? 500 : 750
                        height: descriptionInput.height
                        color: "transparent"

                        Rectangle {
                            width: parent.width
                            height: isDesktop() ? 1 : 2
                            color: "black"
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                        }
                        TextArea {
                            id: descriptionInput
                            width: parent.width
                            font.pixelSize: isDesktop() ? 18 : phoneLarg() ? 30 : 40
                            wrapMode: TextArea.Wrap
                            background: null
                            padding: 0
                            color: "black"
                            anchors.left: parent.left
                            anchors.leftMargin: (!descriptionplaceholder.visible && !isDesktop()) ? -30 : 0

                            Text {
                                id: descriptionplaceholder
                                text: "Description"
                                color: "#aaa"
                                font.pixelSize: isDesktop() ? 18 : 40
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                                visible: descriptionInput.text.length === 0
                            }

                            onFocusChanged: {
                                descriptionplaceholder.visible = !focus && descriptionInput.text.length === 0;
                            }
                        }
                    }

                    Row {
                        id: img_star
                        width: isDesktop() ? 500 : 750
                        height: isDesktop() ? 25 : 80
                        spacing: 5
                        property int selectedPriority: 0

                        Repeater {
                            model: 1
                            delegate: Item {
                                width: isDesktop() ? 30 : 60
                                height: isDesktop() ? 30 : 60

                                Image {
                                    id: starImage
                                    source: (index < img_star.selectedPriority) ? "images/star-active.svg" : "images/starinactive.svg"
                                    anchors.fill: parent
                                    smooth: true

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            if (index + 1 === img_star.selectedPriority) {
                                                img_star.selectedPriority = 0;
                                            } else {
                                                img_star.selectedPriority = index + 1;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        width: isDesktop() ? 500 : 750
                        height: isDesktop() ? 25 : 80
                        color: "transparent"

                        Rectangle {
                            width: parent.width
                            height: isDesktop() ? 1 : 2
                            color: "black"
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                        }

                        TextInput {
                            id: colorInput
                            width: parent.width
                            height: parent.height
                            font.pixelSize: isDesktop() ? 18 : 40
                            anchors.fill: parent
                            Item {
                                id: buttonHeaderAreaSelected
                                anchors {
                                    top: parent.top
                                    left: parent.left
                                    right: parent.right
                                }
                                height: parent.height
                                clip: true

                                Rectangle {
                                    anchors {
                                        fill: parent
                                        bottomMargin: -10
                                    }
                                    radius: 10
                                    color: selectedColor
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    colorListModel.clear();
                                    for (var i = 0; i < color_indexes.length; i++) {
                                        colorListModel.append({
                                            'name': color_indexes[i]
                                        });
                                    }
                                    menuColor.open();
                                }
                            }

                            ListModel {
                                id: colorListModel
                            }

                            Menu {
                                id: menuColor
                                x: colorInput.x
                                y: colorInput.y + colorInput.height
                                width: colorInput.width

                                Repeater {
                                    model: colorListModel

                                    MenuItem {
                                        width: parent.width
                                        height: isDesktop() ? 40 : 80

                                        property string sColor: model.name

                                        Item {
                                            id: buttonHeaderArea
                                            anchors {
                                                top: parent.top
                                                left: parent.left
                                                right: parent.right
                                            }
                                            height: parent.height
                                            clip: true

                                            Rectangle {
                                                anchors {
                                                    fill: parent
                                                    bottomMargin: -10
                                                }
                                                radius: 10
                                                color: sColor
                                            }
                                        }

                                        onClicked: {
                                            selectedColor = model.name;
                                            menuColor.close();
                                        }
                                    }
                                }
                            }

                            onTextChanged: {
                                if (colorInput.text.length > 0) {
                                    colorplaceholder.visible = false;
                                } else {
                                    colorplaceholder.visible = true;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    Component.onCompleted: {
        if (!workpersonaSwitchState) {
            var result = accountlistDataGet();
            selectedAccountUserId = result[0].id;
            accountInput.text = result[0].name;
        }
    }
}
