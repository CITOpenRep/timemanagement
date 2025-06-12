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
import "../models/Main.js" as Model

Page {
    id: dashboard
    title: "Charts"
    header: PageHeader {
        title: dashboard.title
        StyleHints {
            foregroundColor: "white"

            backgroundColor: LomiriColors.orange
            dividerColor: LomiriColors.slate
        }
    }

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
        id: flick1
        width: parent.width
        height: 80
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

        Loader {
            id: load3
            anchors.left: parent.left
            anchors.right: parent.right
            //            anchors.top: header.bottom
            source: "Charts3.qml"
        }

        Loader {
            id: load4
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: load3.bottom
            source: "Charts4.qml"
        }

        onFlickEnded: {
            load3.active = false;
            load4.active = false;
            console.log("Flickable flick ended");
            load3.active = true;
            load4.active = true;
        }
    }

    Scrollbar {
        flickableItem: flick1
        align: Qt.AlignTrailing
    }
}
