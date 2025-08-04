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

import QtQuick 2.12
import QtQuick.Controls 2.2
import Lomiri.Components 1.3
import QtQuick.Layouts 1.1
import "../../models/utils.js" as Utils
import "../../models/constants.js" as AppConst
import "../../models/project.js" as Project
import "../../models/accounts.js" as Accounts
ListItem {
    id: updateItem
    clip: true

    property string name: ""
    property string project_id: ""
    property string status: ""
    property int progress: 0
    property string description: ""
    property string user: ""
    property int recordId: -1
    property int account_id: 0
    property int colorPallet: 0
    signal showDescription(string description);

    // Dynamically bind height to the content height (no fixed height)
    height: contentColumn.height + units.gu(3)  // Base padding for spacing

    ListItemLayout {
        anchors.fill: parent
        anchors.leftMargin: units.gu(1)

        Column {
            id: contentColumn
            width: parent.width
            spacing: units.gu(0.4)

            // Title Row
            Row {
                width: parent.width
                spacing: units.gu(1)
                Text {
                    text: (name && name.trim() !== "") ? Utils.truncateText(name, 35) : "Untitled Update"
                    font.pixelSize: units.gu(AppConst.FontSizes.ListHeading)
                    elide: Text.ElideRight
                    color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "White" : "#222"
                    width: parent.width * 0.7
                }
                Column
                {
                    Rectangle {
                        width: showDescription.width
                        height: units.gu(2.5)
                        color: Utils.getColorFromOdooIndex(colorPallet)
                        Text {
                            anchors.centerIn: parent
                            text: status
                            font.pixelSize: units.gu(1.5)
                            color: "white"
                        }
                    }
                    Rectangle {
                        width: units.gu(1)
                        height: units.gu(1)
                    }
                    Button {
                        id: showDescription
                        text: "Details"
                        //width: parent.width
                        color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "White" : "#999"
                        onClicked:{
                            updateItem.showDescription(description)
                        }
                    }
                }
            }
            Row
            {
                spacing: units.gu(4)
                Text {
                    text: Project.getProjectName(project_id, account_id) || "Unknown Project"
                    font.pixelSize: units.gu(AppConst.FontSizes.ListSubHeading)
                    elide: Text.ElideRight
                    color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "White" : "#666"
                }
                Text {
                    text: "By : " + (user ? Accounts.getUserNameByOdooId(user, account_id) : "Unknown User")
                    font.pixelSize: units.gu(AppConst.FontSizes.ListSubHeading)
                    elide: Text.ElideRight
                    color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "White" : "#666"
                }
            }

            // Progress Bar
            ProgressBar {
                id: progressBar
                width:parent.width*0.9
                height: units.gu(1.2)
                value: progress
                minimumValue: 0
                maximumValue: 100
            }
        }
    }
}
