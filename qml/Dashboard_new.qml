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
import "../models/project.js" as Project

import "components"

Page {
    id: mainPage
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

    /*    function handle_convergence(){
            console.log(" In Dashboard convergence: " + apLayout.columns)
        if (apLayout.columns === 3){
            apLayout.addPageToNextColumn(mainPage, Qt.resolvedUrl("Dashboard2.qml"))
        }

    }*/

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

    DialerMenu {
        id: fabMenu
        anchors.fill: parent
        z: 9999
        menuModel: [
            {
                label: "Task"
            },
            {
                label: "Timehsheet"
            },
        ]
        onMenuItemSelected: {
            if (index === 0) {
                console.log("add task");
                apLayout.addPageToCurrentColumn(mainPage, Qt.resolvedUrl("Task_Create.qml"));
            }
            if (index === 1) {
                console.log("add time sheet");
                apLayout.addPageToCurrentColumn(mainPage, Qt.resolvedUrl("Timesheet.qml"));
            }
        }
    }

    Flickable {
        id: flick1
        width: parent.width
        height: parent.height
        anchors.top: header.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        contentWidth: parent.width
        contentHeight: 3500

        rebound: Transition {
            NumberAnimation {
                properties: "x,y"
                duration: 1000
                easing.type: Easing.OutBounce
            }
        }

        EHower {
            id: ehoverMatrix
            width: parent.width
            height: width
            anchors.top: parent.top
            onQuadrantClicked: {
                console.log("Quadrant clicked:", quadrant);
                // Navigate or filter as needed
            }
        }

        /*Bubblemap {
            id: bubblemap
            width: parent.width
            height: width
            anchors.top: ehoverMatrix.bottom
            anchors.margins: 10

            Component.onCompleted: {
                var data = Project.getProjectSpentHoursList(true);
                console.log("Bubble Data: ", JSON.stringify(data));
                bubblemap.bubbleData = data;
            }
        }*/

        ProjectPieChart {
            id: projectchart
            width: parent.width
            height: width
            anchors.top: ehoverMatrix.bottom
            anchors.margins: 10
            Component.onCompleted: {
                var data = Project.getProjectSpentHoursList(true);
                projectchart.load(data);
            }

            // barColor: "#4CAF50"
        }

        /* Loader{
            id:load
            anchors.left: parent.left
            anchors.right: parent.right
            source: "Charts1.qml"
        }

       Loader{
            id:load2
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: load.bottom
            source: "Charts2.qml"
        }

        Loader{
            id:load3
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: load2.bottom
            source: apLayout.columns === 1 ? "Charts3.qml": ""
        }

        Loader{
            id:load4
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: load3.bottom
            source: apLayout.columns === 1 ? "Charts4.qml": ""
        }*/
        /*        Button{
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: load4.bottom
            text: "Dashboard 2"
            onClicked:{
                console.log("Dashboard from button status is: " + mainPage.status)
                apLayout.addPageToNextColumn(mainPage, Qt.resolvedUrl("Dashboard2.qml"))
            }

        } */

        onFlickEnded: {
            load.active = false;
            load2.active = false;
            if (apLayout.columns === 1) {
                load3.active = false;
                load4.active = false;
            }
            console.log("Flickable flick ended");
            load.active = true;
            load2.active = true;
            if (apLayout.columns === 1) {
                load3.active = true;
                load4.active = true;
            } else
            //                    apLayout.addPageToNextColumn(mainPage, Qt.resolvedUrl("Dashboard2.qml"))
            {}
        }
    }

    Scrollbar {
        flickableItem: flick1
        align: Qt.AlignTrailing
    }
    Timer {
        interval: 100
        running: true
        repeat: false
        onTriggered: {
            if (apLayout.columns === 3) {
                console.log("In Dashboard timer columns: " + apLayout.columns);
                apLayout.addPageToNextColumn(mainPage, Qt.resolvedUrl("Dashboard2.qml"));
            }
        }
    }

    onVisibleChanged: {
        if (visible) {
            console.log("Dashboard status is: " + mainPage.status);
        }
    }
}
