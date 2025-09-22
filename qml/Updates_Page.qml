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
import Ubuntu.Components 1.3 as Ubuntu
import QtQuick.LocalStorage 2.7
import "../models/project.js" as Project
import "../models/accounts.js" as Account
import "../models/global.js" as Global
import "components"
import "../models/timer_service.js" as TimerService

Page {
    id: updates
    title: "Project Updates"

    // Properties for filtering by project
    property bool filterByProject: false
    property string projectOdooRecordId: ""
    property int projectAccountId: -1
    property string projectName: ""

    header: PageHeader {
        id: updatesheader
        title: filterByProject ? "Updates - " + projectName : updates.title
        StyleHints {
            foregroundColor: "white"
            backgroundColor: LomiriColors.orange
            dividerColor: LomiriColors.slate
        }
    }

    NotificationPopup {
        id: notifPopup
        width: units.gu(80)
        height: units.gu(80)
    }

    ListModel {
        id: updatesModel
    }

    function fetchupdates() {
        var updates_list;
        if (filterByProject && projectOdooRecordId && projectAccountId >= 0) {
            updates_list = Project.getProjectUpdatesByProject(projectOdooRecordId, projectAccountId);
        } else {
            updates_list = Project.getAllProjectUpdates();
        }
        updatesModel.clear();
        for (var index = 0; index < updates_list.length; index++) {
            updatesModel.append({
                'name': updates_list[index].name,
                'id': updates_list[index].id,
                'date': updates_list[index].date,
                'account_id': updates_list[index].account_id,
                'status': updates_list[index].project_status,
                'progress': updates_list[index].progress,
                'description': updates_list[index].description,
                'project_id': updates_list[index].project_id,
                'user': updates_list[index].user_id
            });
        }
    }

    ListView {
        id: timesheetlist
        anchors.top: updatesheader.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: units.gu(1)
        model: updatesModel
        clip: true
        delegate: UpdatesDetailsCard {
            width: parent.width
            name: model.name
            account_id: model.account_id
            project_id: model.project_id
            user: model.user
            status: model.status
            description: model.description
            date: model.date
            progress: model.progress

            onShowDescription: {
                Global.description_temporary_holder = description;
                Global.description_context = "update_description";
                apLayout.addPageToNextColumn(updates, Qt.resolvedUrl("ReadMorePage.qml"), {
                    "isReadOnly": true
                });
            }

            onDeleteRequested: {
                var result = Project.markProjectUpdateAsDeleted(model.id);
                if (!result.success) {
                    notifPopup.open("Error", result.message, "error");
                } else {
                    notifPopup.open("Deleted", result.message, "success");
                    fetchupdates();
                }
            }
        }

        Component.onCompleted: fetchupdates()
    }
    onVisibleChanged: {
        if (visible) {
            fetchupdates();
        }
    }
}
