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
import QtQuick.Layouts 1.11
import Qt.labs.settings 1.0
import "../models/Main.js" as Model

/****************
    * Chart 2 comes below
    * Pie Chart for Time Spent this month
    TODO : The Chart Files need to be revisited and Merged in a Single File with all the Different Charts
    *****************/

Rectangle {
    id: rect2
    width: parent.width
    height: units.gu(40)

    ChartView {
        id: chart2
        z: 100
        title: "Time Spent this month"
        margins {
            top: 50
            bottom: 0
            left: 0
            right: 0
        }
        backgroundRoundness: 0
        anchors {
            fill: parent
            margins: 0
        }
        antialiasing: true
        legend.visible: false

        property variant othersSlice: 0
        property variant timecat: []

        PieSeries {
            id: pieSeries2
            size: 0.5
            onHovered: {
                if (state) {
                    hoverText.text = slice.label + " — " + Number(slice.value).toFixed(1) + i18n.dtr("ubtms", " hrs");
                    slice.exploded = true;

                    // Compute dynamic tool-tip position based on slice radius, angles, and aspect ratio sizing
                    var w = chart2.plotArea.width;
                    var h = chart2.plotArea.height;
                    var r = (pieSeries2.size * Math.min(w, h)) / 2;
                    var angle = (slice.startAngle + slice.angleSpan / 2) * Math.PI / 180;
                    
                    var cx = chart2.plotArea.x + w * pieSeries2.horizontalPosition;
                    var cy = chart2.plotArea.y + h * (1.0 - pieSeries2.verticalPosition);

                    var intendedX = cx + (r * Math.cos(angle)) - hoverInfo.width / 2;
                    var intendedY = cy - (r * Math.sin(angle)) - hoverInfo.height;
                    
                    if (intendedX < 0) intendedX = units.gu(1);
                    if (intendedX + hoverInfo.width > chart2.width) intendedX = chart2.width - hoverInfo.width - units.gu(1);
                    if (intendedY < 0) intendedY = units.gu(1);
                    
                    hoverInfo.x = intendedX;
                    hoverInfo.y = intendedY;

                } else {
                    hoverText.text = "";
                    slice.exploded = false;
                }
            }
            PieSlice {
                label: "Important, Urgent"
                value: chart2.timecat[0]
            } //  Data from Js
            PieSlice {
                label: "Important, Not Urgent"
                value: chart2.timecat[1]
            }
            PieSlice {
                label: "Not Important, Urgent"
                value: chart2.timecat[2]
            }
            PieSlice {
                label: "Not Important, Not Urgent"
                value: chart2.timecat[3]
            }
        }
        Component.onCompleted: {
            var quadrant_data = Model.get_quadrant_current_month();
            chart2.timecat = quadrant_data;
        }


        Rectangle {
            id: hoverInfo
            x: chart2.width / 2 - width / 2
            y: units.gu(2)
            width: Math.min(hoverText.implicitWidth + units.gu(3), parent.width - units.gu(2))
            height: hoverText.implicitHeight + units.gu(1.5)
            color: Theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#555" : "#FFF"
            border.color: Theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#888" : "#ccc"
            border.width: 1
            radius: units.gu(0.5)
            opacity: hoverText.text !== "" ? 0.95 : 0.0
            Behavior on opacity { NumberAnimation { duration: 150 } }
            Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
            Behavior on y { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
            z: 100

            Label {
                id: hoverText
                anchors.centerIn: parent
                width: parent.width - units.gu(2)
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                text: ""
                color: Theme.name === "Ubuntu.Components.Themes.SuruDark" ? "White" : "Black"
                font.weight: Font.Light
                font.pixelSize: units.gu(2)
            }
        }
    }

    Rectangle {
        id: rect3
        anchors.top: rect2.bottom
        width: parent.width
        height: units.gu(10)

        Column {
            id: myCol1
            spacing: 2
            leftPadding: 10
            Row {
                spacing: 2
                Rectangle {
                    color: "lightskyblue"
                    width: 20
                    height: 20
                }
                Text {
                    id: myLabel_1
                    text: qsTr("Important, Urgent")
                }
            }
            Row {
                spacing: 2
                Rectangle {
                    color: "deepskyblue"
                    width: 20
                    height: 20
                }
                Text {
                    id: myLabel_2
                    text: qsTr("Important, Not Urgent")
                }
            }
        }
        Column {
            id: myCol2
            anchors.left: myCol1.right
            spacing: 2
            leftPadding: 10
            Row {
                spacing: 2
                Rectangle {
                    color: "steelblue"
                    width: 20
                    height: 20
                }
                Text {
                    id: myLabel_3
                    text: qsTr("Not Important, Urgent")
                }
            }
            Row {
                spacing: 2
                Rectangle {
                    color: "#0e1a24"
                    width: 20
                    height: 20
                }
                Text {
                    id: myLabel_4
                    text: qsTr("Not Important, Not Urgent")
                }
            }
        }
    }
}
