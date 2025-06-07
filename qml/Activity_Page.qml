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
import QtQuick.Window 2.2
import "../models/timesheet.js" as Model
import "../models/project.js" as Project
import "../models/Activity.js" as Activity
import "../models/utils.js" as Utils

Page {
    id: activity
    title: "Activities"
    header: PageHeader {
        id: taskheader
        title: activity.title
        ActionBar {
            numberOfSlots: 1
            anchors.right: parent.right
            //    enable: true
            actions: [
                Action {
                    iconName: "add"
                    text: "New"
                    onTriggered: {
                        console.log("Create Activity clicked");
                        apLayout.addPageToCurrentColumn(activity, Qt.resolvedUrl("Activity_Create.qml"));
                    }
                }
            ]
        }
    }

    function get_activity_list(recordid) {
        var activities = Activity.queryActivityData(recordid);
        activityListModel.clear();
        for (var activity = 0; activity < activities.length; activity++) {
            activityListModel.append({
                'id': activities[activity].id,
                'summary': activities[activity].summary,
                'due_date': activities[activity].due_date
            });
        }
    }

    function get_activityOn_Status(searchstr) {
        var activities = Activity.filterStatus(searchstr);
        activityListModel.clear();
        for (var activity = 0; activity < tasks.length; activity++) {
            activityListModel.append({
                'id': activities[activity].id,
                'summary': activities[activity].summary,
                'due_date': activities[activity].due_date
            });
        }
    }

    ListModel {
        id: activityListModel
    }

    LomiriShape {
        anchors.top: taskheader.bottom
        height: parent.height
        width: parent.width

        Component {
            id: activityDelegate
            LomiriShape {
                width: parent.width
                height: units.gu(10)
                Row {
                    height: units.gu(10)
                    leftPadding: units.gu(1)
                    spacing: 10
                    Column {
                        width: units.gu(35)
                        height: units.gu(10)
                        /*                        Label{
                        id: tasklabel
                            text: "Activity: "}*/
                        Text {
                            width: units.gu(20)
                            //                            anchors.left: tasklabel.left
                            text: summary
                            clip: true
                        }
                        /*                        Label{
                            id: idlabel
                            text: "ID: "}*/
                        Text {
                            //                            anchors.left:idlabel.left
                            text: id
                        }
                    }
                    Column {
                        width: units.gu(10)
                        height: units.gu(10)
                        //                        Label{ text: "Due Date: "}
                        Text {
                            text: due_date
                        }
                        /*                        Label{ text: "Planned: "}
                        Text { text: allocated_hours }*/
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        activitylist.currentIndex = index;
                        apLayout.addPageToNextColumn(activity, Qt.resolvedUrl("Activity_details.qml"), {
                            "recordid": id
                        });
                    }
                }
            }
        }

        LomiriListView {
            id: activitylist
            anchors.fill: parent
            //            anchors.top: taskheader.bottom
            model: activityListModel
            delegate: activityDelegate
            highlight: Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                color: "lightsteelblue"
                radius: 5
            }
            highlightFollowsCurrentItem: true
            currentIndex: 0
            onCurrentIndexChanged: {
                console.log("currentIndex changed");
            }

            Component.onCompleted: {
                get_activity_list(0);
            }
        }
    }
}
