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
import Lomiri.Components.ListItems 1.3 as ListItem

import "../models/project.js" as Project
import "../models/utils.js" as Utils

import "components"

Page {
    id: project
    title: "Projects"
    header: PageHeader {
        id: projectheader
        StyleHints {
            foregroundColor: "white"

            backgroundColor: LomiriColors.orange
            dividerColor: LomiriColors.slate
        }
        title: project.title

        trailingActionBar.actions: [
            Action {
                iconName: "add"
                text: "New"
                onTriggered: {
                    // console.log("Create Project clicked");
                    apLayout.addPageToNextColumn(project, Qt.resolvedUrl("Projects.qml"), {
                        "isReadOnly": false
                    });
                }
            }
        ]
    }

    LomiriShape {
        anchors.top: projectheader.bottom
        height: parent.height - projectheader.height
        width: parent.width

        ProjectList {
            id: projectlist
            anchors.fill: parent
            onProjectSelected: {
                //  console.log("Viewing Project");
                apLayout.addPageToNextColumn(project, Qt.resolvedUrl("Projects.qml"), {
                    "recordid": recordId,
                    "isReadOnly": true
                });
            }
        }
    }

    onVisibleChanged: {
        if (visible) {
            projectlist.refresh();
        }
    }
    Component.onCompleted: {
        projectlist.refresh();
    }
}
