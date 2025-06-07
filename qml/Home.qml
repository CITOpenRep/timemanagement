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
import Lomiri.Components 1.3
import QtCharts 2.0
import QtQuick.Layouts 1.11
import Qt.labs.settings 1.0
import "../models/Main.js" as Model
import "../models/DbInit.js" as DbInit
import "../models/DemoData.js" as DemoData
import "../models/Project.js" as Project

import "components"

Page {
    id: mainPage
    title: "Ubudoo- Time Management"
    anchors.fill: parent
    property bool isMultiColumn: apLayout.columns > 1
    property var page: 0
    onVisibleChanged: {
        if (visible) {
            //update graph etc
            var data = Project.getProjectSpentHoursList(true);
            projectchart.load(data);
        }
    }

    header: PageHeader {
        id: header
        title: ""
        visible: true
        ActionBar {
            id: actionbar
            visible: isMultiColumn ? false : true
            numberOfSlots: 1
            anchors.right: parent.right
            actions: [
                Action {
                    iconName: "settings"
                    text: "Settings"
                    onTriggered: {
                        apLayout.addPageToCurrentColumn(mainPage, Qt.resolvedUrl("Settings_Page.qml"));
                        page = 6;
                        apLayout.setCurrentPage(page);
                    }
                }
            ]
        }
    }

    //    function handle_convergence(){
    //         console.log(" In Dashboard convergence: " + apLayout.columns)
    //     if (apLayout.columns === 3){
    //         apLayout.addPageToNextColumn(mainPage, Qt.resolvedUrl("Dashboard2.qml"))
    //     }

    // }

    property variant project_timecat: []
    property variant project: []
    property variant project_data: []

    property variant task_timecat: []
    property variant task: []
    property variant task_data: []

    function get_project_chart_data() {
        console.log("get_project_chart_data called");
        project_data = Model.get_projects_spent_hours();
        var count = 0;
        var timeval;
        for (var key in project_data) {
            project[count] = key;
            timeval = project_data[key];
            count = count + 1;
        }
        var count2 = Object.keys(project_data).length;
        for (count = 0; count < count2; count++) {
            project_timecat[count] = project_data[project[count]];
        }
    }

    function get_task_chart_data() {
        console.log("get_task_chart_data called");
        task_data = Model.get_tasks_spent_hours();
        var count = 0;
        var timeval;
        for (var key in task_data) {
            task[count] = key;
            timeval = task_data[key];
            count = count + 1;
        }
        var count2 = Object.keys(task_data).length;
        for (count = 0; count < count2; count++) {
            task_timecat[count] = task_data[task[count]];
        }
    }
    Flickable {
        id: tabBar
        anchors.top: header.bottom
        width: parent.width
        height: units.gu(6)  // enough height to see the buttons
        contentWidth: tabBarRow.width
        clip: true

        Row {
            id: tabBarRow
            width: childrenRect.width
            height: parent.height
            spacing: units.gu(2)

            TSButton {
                text: "Overview"
                width: units.gu(20)
                height: parent.height
                onClicked: mainLoader.sourceComponent = overviewComponent
            }
            TSButton {
                text: "Projects"
                width: units.gu(20)
                height: parent.height
                onClicked: mainLoader.sourceComponent = projectComponent
            }
            TSButton {
                text: "Tasks"
                width: units.gu(20)
                height: parent.height
                onClicked: mainLoader.sourceComponent = taskComponent
            }
            TSButton {
                text: "Timesheets"
                width: units.gu(20)
                height: parent.height
                onClicked: mainLoader.sourceComponent = timesheetComponent
            }
        }
    }
    NotificationBell {
        id: notificationBell
        notificationCount: 4
        onClicked: {
            console.log("Notifications clicked");
        }
        z: 9999
    }
    Component {
        id: overviewComponent
        Dashboard {}
    }
    Component {
        id: projectComponent
        Project_Page {}
    }
    Component {
        id: taskComponent
        Task_Page {}
    }
    Component {
        id: timesheetComponent
        Timesheet_Page {}
    }
    Loader {
        id: mainLoader
        anchors.top: tabBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        sourceComponent: overviewComponent
    }
}
