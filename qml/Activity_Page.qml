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
import "../models/task.js" as Task
import "../models/activity.js" as Activity
import "../models/utils.js" as Utils
import "../models/accounts.js" as Accounts
import "components"

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
            /*actions: [
                Action {
                    iconName: "add"
                    text: "New"
                    onTriggered: {
                        console.log("Create Activity clicked");
                        apLayout.addPageToNextColumn(activity, Qt.resolvedUrl("Activities.qml"), {
                            "recordid": recordid,
                            "isReadOnly": false
                        });
                    }
                }
            ]*/
        }
    }

    function get_activity_list() {
        activityListModel.clear();

        try {
            var allActivities = Activity.getAllActivities();

            for (var i = 0; i < allActivities.length; i++) {
                var item = allActivities[i];

                var projectDetails = item.project_id ? getProjectDetails(item.project_id) : null;
                var projectName = projectDetails && projectDetails.name ? projectDetails.name : "No Project";
                var taskName = item.task_id ? getTaskDetails(item.task_id).name : "No Task";  // Assuming you have getTaskDetails()
                var user = Accounts.getUserNameByOdooId(item.user_id);
                console.log("Username is " + user);

                activityListModel.append({
                    id: item.id,
                    summary: item.summary,
                    due_date: item.due_date,
                    notes: item.notes,
                    activity_type_name: Activity.getActivityTypeName(item.activity_type_id),
                    state: item.state,
                    task_id: item.task_id,
                    task_name: taskName,
                    project_name: projectName,
                    odoo_record_id: item.odoo_record_id,
                    user: user,
                    state: item.state,
                    account_id: item.account_id,
                    resId: item.resId,
                    resModel: item.resModel,
                    last_modified: item.last_modified
                });
            }
        } catch (e) {
            console.error("❌ Error in get_activity_list():", e);
        }
    }

    ListModel {
        id: activityListModel
    }

    LomiriShape {
        anchors.top: taskheader.bottom
        height: parent.height
        width: parent.width

        LomiriListView {
            id: activitylist
            anchors.fill: parent
            model: activityListModel
            delegate: ActivityDetailsCard {
                id: activityCard
                odoo_record_id: model.odoo_record_id
                notes: model.notes
                activity_type_name: model.activity_type_name
                summary: model.summary
                user: model.user
                due_date: model.due_date
                state: model.state
                onCardClicked: function (recordid) {
                    console.log("Loading record " + recordid);
                    apLayout.addPageToNextColumn(activity, Qt.resolvedUrl("Activities.qml"), {
                        "recordid": recordid,
                        "isReadOnly": true
                    });
                }
            }
            currentIndex: 0
            onCurrentIndexChanged: {
                console.log("currentIndex changed");
            }

            Component.onCompleted: {
                get_activity_list();
            }
        }
    }
}
