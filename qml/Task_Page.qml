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

import QtQuick 2.9
import QtQuick.Controls 2.2
import Lomiri.Components 1.3
import QtQuick.Window 2.2
import QtQml.Models 2.3
import "../models/timesheet.js" as Model
import "../models/project.js" as Project
import "../models/task.js" as Task
import "../models/utils.js" as Utils
import "components"

Page {
    id: task
    title: "Tasks"

    header: PageHeader {
        id: taskheader
        StyleHints {
            foregroundColor: "white"
            backgroundColor: LomiriColors.orange
            dividerColor: LomiriColors.slate
        }
        title: task.title

        trailingActionBar.actions: [
            Action {
                iconName: "add"
                text: "New"
                onTriggered: {
                    apLayout.addPageToNextColumn(task, Qt.resolvedUrl("Tasks.qml"), {
                        "recordid": 0,
                        "isReadOnly": false
                    });
                }
            },
            Action {
                iconName: "search"
                text: "Search"
                onTriggered: {
                    console.log("Search clicked");
                    taskListHeader.toggleSearchVisibility();
                }
            }


        ]
    }
    ListModel {
        id: taskModel
    }

    
    // Add properties to track filter and search state
    property string currentFilter: "today"
    property string currentSearchQuery: ""

    // Add the ListHeader component outside LomiriShape
    ListHeader {
        id: taskListHeader
        anchors.top: taskheader.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        
        label1: "Today"
        label2: "This Week"
        label3: "Next Week"
        label4: "Later"
        label5: "Completed"
        
        filter1: "today"
        filter2: "this_week"
        filter3: "next_week"
        filter4: "later"
        filter5: "completed"
        
        showSearchBox: false
        currentFilter: task.currentFilter
        
        onFilterSelected: {
            console.log("Filter selected:", filterKey)
            task.currentFilter = filterKey
            tasklist.applyFilter(filterKey)
        }
        
        onCustomSearch: {
            console.log("Search query:", query)
            task.currentSearchQuery = query
            tasklist.applySearch(query)
        }
    }

    LomiriShape {
        anchors.top: taskListHeader.bottom
        height: parent.height - taskheader.height - taskListHeader.height
        width: parent.width

        TaskList {
            id: tasklist
            anchors.fill: parent
                
                onTaskEditRequested: {
                    console.log("Edit Requested");
                    apLayout.addPageToNextColumn(task, Qt.resolvedUrl("Tasks.qml"), {
                        "recordid": recordId,
                        "isReadOnly": false
                    });
                }
                onTaskSelected: {
                    console.log("Viewing Task");
                    apLayout.addPageToNextColumn(task, Qt.resolvedUrl("Tasks.qml"), {
                        "recordid": recordId,
                        "isReadOnly": true
                    });
                }
                onTaskDeleteRequested: {
                    console.log("Delete Requested");
                    var result = Task.markTaskAsDeleted(recordId);
                    if (!result.success) {
                        notifPopup.open("Error", result.message, "error");
                    } else {
                        notifPopup.open("Deleted", result.message, "success");
                    }
                    pageStack.removePages(task);
                    apLayout.addPageToCurrentColumn(task, Qt.resolvedUrl("Task_Page.qml"));
                }
            }

            Text {
                id: labelNoTask
                anchors.centerIn: parent
                font.pixelSize: units.gu(2)
                visible: false
                text: 'No Task Available'
            }
        }
    
    NotificationPopup {
        id: notifPopup
        width: units.gu(80)
        height: units.gu(80)
        onClosed: console.log("Notification dismissed")
    }

    DialerMenu {
        id: fabMenu
        anchors.fill: parent
        z: 9999
        //text:""
        menuModel: [
            {
                label: "Create"
            },
        ]
        onMenuItemSelected: {
            if (index === 0) {
                console.log("add task");
                apLayout.addPageToNextColumn(task, Qt.resolvedUrl("Tasks.qml"), {
                    "recordid": 0,
                    "isReadOnly": false
                });
            }
        }
    }
    onVisibleChanged: {
        if (visible) {
            tasklist.refresh();
        }
    }
    Component.onCompleted: {
        tasklist.refresh();
    }
}
