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
import QtQuick.Layouts 1.1
import "../../models/utils.js" as Utils
import "../../models/constants.js" as AppConst

ListItem {
    id: timesheetItem
    height: units.gu(12)

    property string name: ""
    property string project: ""
    property string task: ""
    property string user: ""
    property string date: ""
    property string instance: ""
    property string spentHours: "0"
    property string quadrant: "Do"
    property int recordId: -1
    property bool isFavorite: false

    signal editRequested(int recordId)
    signal viewRequested(int recordId)
    signal deleteRequested(int recordId)
    signal toggleFavorite(int recordId, bool currentState)

    /* leadingActions: ListItemActions {
        actions: Action {
            iconSource: isFavorite ? "images/star-active.svg" : "images/starinactive.svg"
            onTriggered: toggleFavorite(recordId, isFavorite)
        }
    }*/

    leadingActions: ListItemActions {
        actions: [
            Action {
                iconName: "delete"
                onTriggered: deleteRequested(recordId)
            }
        ]
    }

    trailingActions: ListItemActions {
        actions: [
            Action {
                iconName: "edit"
                onTriggered: editRequested(recordId)
            }
        ]
    }

    clip: true

    ListItemLayout {
        anchors.fill: parent

        Row {
            anchors.fill: parent
            spacing: units.gu(2)

            // Left Column
            Column {
                width: parent.width * 0.65
                spacing: units.gu(0.5)

                Text {
                    text: Utils.truncateText(name, 40)
                    font.pixelSize: units.gu(AppConst.FontSizes.ListHeading)
                    elide: Text.ElideRight
                    width: parent.width
                    color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "White" : "#222"
                }

                Text {
                    text: (project ? project : "No Project")
                    font.pixelSize: units.gu(AppConst.FontSizes.ListSubHeading)
                    elide: Text.ElideRight
                    color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "White" : "#222"
                }
                Text {
                    text: task
                    font.pixelSize: units.gu(AppConst.FontSizes.ListSubHeading)
                    elide: Text.ElideRight
                    color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "White" : "#222"
                }
                Text {
                    text: (user ? user : "Unknown User")
                    font.pixelSize: units.gu(AppConst.FontSizes.ListSubHeading)
                    elide: Text.ElideRight
                    color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "White" : "#222"
                }
            }

            // Right Column
            Column {
                width: parent.width * 0.25
                spacing: units.gu(0.5)
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    text: spentHours + " H"
                    font.pixelSize: units.gu(AppConst.FontSizes.ListSubSubHeading)
                    horizontalAlignment: Text.AlignRight
                    width: parent.width
                    color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "White" : "#222"
                }

                Text {
                    text: date
                    font.pixelSize: units.gu(AppConst.FontSizes.ListSubSubHeading)
                    horizontalAlignment: Text.AlignRight
                    width: parent.width
                    color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "White" : "#222"
                }

                EHowerIndicator {
                    quadrantKey: quadrant
                    horizontalAlignment: Text.AlignRight
                    width: parent.width
                }
            }
        }
    }

    onClicked: viewRequested(recordId)
}
