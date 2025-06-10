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
import "../../models/constants.js" as AppConst
import "../../models/utils.js" as Utils
import Lomiri.Components 1.3
import QtQuick.Layouts 1.1

ListItem {
    id: taskCard
    width: parent.width
    height: units.gu(20)
    //     onWidthChanged: {
    //         shapeWidth = parent.width

    //         if (screenWidth < units.gu(361))
    //         {
    //             projectTitleText.text = truncateText("rtrtretertreterterterterterteterterterterterterterter", 20)
    //         }else
    //     {
    //         projectTitleText.text = truncateText("2356577867878547874768678576876857567789578957897899795878795", 25)
    //     }
    // }
    property int screenWidth: parent.width
    property bool isFavorite: true
    property string taskName: ""
    property string projectName: ""
    property string allocatedHours: ""
    property string deadline: ""
    property string startDate: ""
    property string endDate: ""
    property string description: ""
    property int colorPallet: 0
    property int localId: -1
    property int recordId: -1
    property bool hasChildren: false
    property int childCount: 0

    signal editRequested(int localId)
    signal deleteRequested(int localId)
    signal viewRequested(int localId)

    trailingActions: ListItemActions {
        actions: [
            Action {
                iconName: "edit"
                onTriggered: editRequested(localId)
            },
            Action {
                iconName: "delete"
                onTriggered: deleteRequested(localId)
            }
        ]
    }
    leadingActions: ListItemActions {
        actions: [
            Action {
                iconName: "document-preview"
                onTriggered: viewRequested(localId)
            }
        ]
    }

    Rectangle {
        anchors.fill: parent
        border.color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#444" : "#dcdcdc"
        radius: units.gu(0.2)
        anchors.leftMargin: units.gu(0.2)
        anchors.rightMargin: units.gu(0.2)
        color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#111" : "#fff"

        Row {
            anchors.fill: parent
            spacing: 2

            // side bar on left
            Rectangle {
                width: units.gu(0.5)
                height: parent.height
                color: Utils.getColorFromOdooIndex(colorPallet)
            }

            Rectangle {
                width: parent.width - units.gu(20)
                height: parent.height
                color: "transparent"

                Row {
                    width: parent.width
                    height: parent.height
                    spacing: units.gu(0.4)

                    // 🟫 Wrap gray block in a Column to align it to the bottom
                    Column {
                        width: units.gu(4)
                        height: parent.height
                        spacing: 0

                        // Filler pushes gray to the bottom
                        Item {
                            Layout.fillHeight: true
                        }

                        Image {
                            id: starIcon
                            source: isFavorite ? "../images/star-active.svg" : "../images/starinactive.svg"
                            fillMode: Image.PreserveAspectFit
                            width: units.gu(4)
                            height: units.gu(4)
                        }
                    }

                    // 🟨 Yellow + 🟩 Green
                    Column {
                        width: parent.width - units.gu(4)
                        height: parent.height - units.gu(2)
                        spacing: 0

                        Text {
                            id: projectTitleText
                            text: (taskName !== "" ? truncateText(taskName, 300) : "Unnamed Task")
                            color: hasChildren ? AppConst.Colors.Orange : (theme.name === "Ubuntu.Components.Themes.SuruDark" ? "white" : "black")
                            font.pixelSize: units.gu(2)
                            wrapMode: Text.WordWrap
                            maximumLineCount: 2
                            clip: true
                            width: parent.width - units.gu(2)
                        }

                        Text {
                            id: yellowBlock
                            text: projectName
                            font.pixelSize: units.gu(1.6)
                            wrapMode: Text.NoWrap
                            elide: Text.ElideRight
                            width: parent.width - units.gu(2)
                            height: units.gu(2)
                            color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#bbb" : "#222"
                        }

                        Label {
                            id: details
                            text: "Details"
                            width: parent.width - units.gu(2)
                            font.pixelSize: units.gu(1.6)
                            height: units.gu(3)
                            color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#80bfff" : "blue"
                            font.underline: true
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    console.log("Showing Task Details");
                                    viewRequested(localId);
                                }
                            }
                        }
                    }
                }
            }

            // space for date and time
            Rectangle {
                width: units.gu(19)
                height: parent.height
                color: 'transparent'
                Column {
                    anchors.right: parent.right
                    anchors.rightMargin: units.gu(2)
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: units.gu(0.4)
                    width: parent.width
                    Text {
                        text: "Planned (H): " + (allocatedHours !== "" ? allocatedHours : "N/A")
                        font.pixelSize: units.gu(1.5)
                        horizontalAlignment: Text.AlignRight
                        width: parent.width
                        color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#bbb" : "#555"
                    }
                    Text {
                        text: "Start Date: " + (startDate !== "" ? toDateOnly(startDate) : "Not set")
                        font.pixelSize: units.gu(1.5)
                        horizontalAlignment: Text.AlignRight
                        width: parent.width
                        color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#bbb" : "#222"
                    }

                    Text {
                        text: getTaskTimeStatus(endDate)
                        font.pixelSize: units.gu(1.5)
                        horizontalAlignment: Text.AlignRight
                        width: parent.width
                        color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#ff6666" : "#e53935"
                    }
                    Text {
                        text: (childCount > 0 ? " [+" + childCount + "] Tasks" : "")
                        visible: childCount > 0
                        color: hasChildren ? AppConst.Colors.Orange : (theme.name === "Ubuntu.Components.Themes.SuruDark" ? "white" : "black")
                        font.pixelSize: units.gu(1.5)
                        horizontalAlignment: Text.AlignRight
                        width: parent.width
                    }
                }
            }
        }
    }
    function truncateText(text, maxLength) {
        if (text.length > maxLength) {
            return text.slice(0, maxLength) + '...';
        }
        return text;
    }
    function toDateOnly(datetimeStr) {
        // Assumes input like "2025-06-06 15:30:00"
        if (!datetimeStr || typeof datetimeStr !== "string")
            return "";

        // Split by space to remove time
        return datetimeStr.split(" ")[0];
    }
    function getTaskTimeStatus(endDateString) {
        if (!endDateString)
            return "No Date";

        var end = new Date(endDateString);
        if (isNaN(end.getTime()))
            return "";

        var now = new Date();
        var diff = end - now;
        var days = Math.floor(diff / (1000 * 60 * 60 * 24));

        if (days < 0) {
            return Math.abs(days) + " days overdue";
        } else if (days === 0) {
            return "Due today";
        } else {
            return days + " days left";
        }
    }
}
