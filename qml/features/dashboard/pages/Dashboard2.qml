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
import "../../../../models/Main.js" as Model

Page {
    id: dashboard
    title: i18n.dtr("ubtms", "Charts")
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

    function refreshData() {
        console.log("Refreshing Dashboard2 charts for account: " + (typeof accountPicker !== 'undefined' ? accountPicker.selectedAccountId : "unknown"));
        get_project_chart_data();
        get_task_chart_data();
        
        // Re-construct the Loaders directly to forcefully update the inner Charts3 and Charts4 bindings
        var prev3 = load3.source;
        var prev4 = load4.source;
        load3.source = "";
        load4.source = "";
        load3.source = prev3;
        load4.source = prev4;
    }

    Connections {
        target: typeof accountPicker !== "undefined" ? accountPicker : null
        onAccepted: function (accountId, accountName) {
            refreshData();
        }
    }

    function get_project_chart_data() {
        //  console.log("get_project_chart_data called");
        var accountId = typeof accountPicker !== 'undefined' ? accountPicker.selectedAccountId : -1;
        project_data = Model.get_projects_spent_hours(accountId);
        var count = 0;
        var temp_project = [];
        var timeval;
        for (var key in project_data) {
            temp_project[count] = key;
            timeval = project_data[key];
            count = count + 1;
        }
        var count2 = Object.keys(project_data).length;
        var temp_timecat = [];
        for (count = 0; count < count2; count++) {
            temp_timecat[count] = project_data[temp_project[count]];
        }
        project = temp_project;
        project_timecat = temp_timecat;
    }

    function get_task_chart_data() {
        //  console.log("get_task_chart_data called");
        var accountId = typeof accountPicker !== 'undefined' ? accountPicker.selectedAccountId : -1;
        task_data = Model.get_tasks_spent_hours(accountId);
        var count = 0;
        var temp_task = [];
        var timeval;
        for (var key in task_data) {
            temp_task[count] = key;
            timeval = task_data[key];
            count = count + 1;
        }
        var count2 = Object.keys(task_data).length;
        var temp_timecat = [];
        for (count = 0; count < count2; count++) {
            temp_timecat[count] = task_data[temp_task[count]];
        }
        task = temp_task;
        task_timecat = temp_timecat;
    }

    Flickable {
        id: flick1
        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Qt.inputMethod.visible ? Qt.inputMethod.keyboardRectangle.height : 0
        contentWidth: parent.width
        contentHeight: contentColumn.height + units.gu(4)
        flickableDirection: Flickable.VerticalFlick
        clip: true

        rebound: Transition {
            NumberAnimation {
                properties: "x,y"
                duration: 1000
                easing.type: Easing.OutBounce
            }
        }

        Column {
            id: contentColumn
            width: flick1.width
            spacing: units.gu(2)

            Item {
                width: parent.width
                height: units.gu(1)
            }

            Rectangle {
                width: parent.width - units.gu(2)
                height: load3.item ? load3.item.height : units.gu(40)
                anchors.horizontalCenter: parent.horizontalCenter
                color: "transparent"

                Loader {
                    id: load3
                    anchors.fill: parent
                    source: "../../../Charts3.qml"
                }
            }

            Rectangle {
                width: parent.width - units.gu(2)
                height: load4.item ? load4.item.implicitHeight : units.gu(80)
                anchors.horizontalCenter: parent.horizontalCenter
                color: "transparent"

                Loader {
                    id: load4
                    anchors.fill: parent
                    source: "../../../Charts4.qml"
                }
            }

            Item {
                width: parent.width
                height: units.gu(2)
            }
        }


    }

    Scrollbar {
        flickableItem: flick1
        align: Qt.AlignTrailing
    }
}
