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
    id: projectCard
    width: parent.width
    height: units.gu(20)

    property bool isFavorite: true
    property string projectName: ""
    property string accountName: ""
    property string allocatedHours: ""
    property string startDate: ""
    property string endDate: ""
    property string deadline: ""
    property string description: ""
    property int colorPallet: 0
    property int recordId: -1
    property int localId: -1
    property bool hasChildren: false
    property int childCount: 0
    signal editRequested(int recordId)
    signal viewRequested(int recordId)

    leadingActions: ListItemActions {
        actions: [
            Action {
                iconSource: "../images/show.png"
                onTriggered: {
                    console.log(localId);
                    viewRequested(localId);
                }
            }
        ]
    }

    Rectangle {
        anchors.fill: parent
        border.color: "#dcdcdc"
        radius: units.gu(0.2)
        anchors.leftMargin: units.gu(0.2)
        anchors.rightMargin: units.gu(0.2)

        Row {
            anchors.fill: parent
            spacing: 2

            Rectangle {
                width: units.gu(0.5)
                height: parent.height
                color: Utils.getColorFromOdooIndex(colorPallet)
            }

            Rectangle {
                width: parent.width - units.gu(17)
                height: parent.height
                color: "transparent" //add some color and see layout

                Row {
                    width: parent.width
                    height: parent.height
                    spacing: units.gu(1)

                    Column {
                        width: units.gu(4)
                        height: parent.height
                        spacing: 0

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

                    Column {
                        width: parent.width - units.gu(4)
                        height: parent.height - units.gu(2)
                        spacing: 0

                        Text {
                            text: projectName !== "" ? projectName : "Unnamed Project"
                            color: hasChildren ? AppConst.Colors.Orange : "black"
                            font.pixelSize: units.gu(2)
                            wrapMode: Text.WordWrap
                            maximumLineCount: 2
                            clip: true
                            width: parent.width - units.gu(2)
                            height: units.gu(5)
                        }

                        Text {
                            text: accountName !== "" ? accountName : "Local"
                            font.pixelSize: units.gu(1.6)
                            wrapMode: Text.Wrap
                            maximumLineCount: 2
                            width: parent.width - units.gu(2)
                            height: units.gu(2)
                        }
                        Label {
                            id: details
                            text: "Details"
                            width: parent.width - units.gu(2)
                            font.pixelSize: units.gu(1.6)
                            height: units.gu(3)
                            color: "blue"
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

            Rectangle {
                width: units.gu(15)
                height: parent.height
                color: 'transparent' //add some color and see layout

                Column {

                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: units.gu(0.4)
                    width: parent.width

                    Text {
                        text: "Planned (H): " + (allocatedHours !== "" ? allocatedHours : "N/A")
                        font.pixelSize: units.gu(1.5)
                        horizontalAlignment: Text.AlignRight
                        width: parent.width
                        color: "#555"
                    }

                    Text {
                        text: "Start Date: " + (startDate !== "" ? startDate : "Not set")
                        font.pixelSize: units.gu(1.5)
                        horizontalAlignment: Text.AlignRight
                        width: parent.width
                    }

                    Text {
                        text: getProjectTimeStatus(endDate)
                        font.pixelSize: units.gu(1.5)
                        horizontalAlignment: Text.AlignRight
                        width: parent.width
                        color: "#e53935"
                    }
                    Text {
                        text: (childCount > 0 ? " [+" + childCount + "] Projects " : "")
                        visible: childCount > 0
                        color: hasChildren ? AppConst.Colors.Orange : "black"
                        font.pixelSize: units.gu(1.5)
                        horizontalAlignment: Text.AlignRight
                        width: parent.width
                    }
                }
            }
        }
    }

    function getProjectTimeStatus(endDateString) {
        if (!endDateString)
            return "N/A";
        var end = new Date(endDateString);
        if (isNaN(end.getTime()))
            return "Invalid";
        var now = new Date();
        var diff = end - now;
        var days = Math.floor(diff / (1000 * 60 * 60 * 24));
        if (days < 0)
            return Math.abs(days) + " days overdue";
        if (days === 0)
            return "Due today";
        return days + " days";
    }
}
