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
import "../../../../models/Main.js" as Model

Page {
    id: dashboard2
    title: i18n.dtr("ubtms", "Task")
    header: PageHeader {
        title: dashboard2.title
    }

    LomiriShape {
        id: rect1
        anchors.centerIn: parent
        width: parent.width
        height: units.gu(40)

        ChartView {
            id: chart4
            title: i18n.dtr("ubtms", "Taskwise Time Spent")
            titleColor: Theme.name === "Ubuntu.Components.Themes.SuruDark" ? "White" : "#444"
            anchors.fill: parent
            
            // No built-in theme so it doesn't override our custom transparent background
            
            legend.alignment: Qt.AlignBottom
            antialiasing: true

            backgroundColor: "transparent"
            legend.labelColor: Theme.name === "Ubuntu.Components.Themes.SuruDark" ? "White" : "#444"

            BarSeries {
                id: mySeries2
                onHovered: {
                    if (status) {
                        var cat = mySeries2.axisX.categories[index];
                        var val = barset.at(index);
                        hoverText.text = cat + " — " + Number(val).toFixed(1) + i18n.dtr("ubtms", " hrs");
                        
                        var barCount = mySeries2.axisX.categories.length;
                        var intendedX = chart4.plotArea.x + (index + 0.5) * (chart4.plotArea.width / barCount) - hoverInfo.width / 2;
                        if (intendedX < 0) intendedX = units.gu(1);
                        if (intendedX + hoverInfo.width > chart4.width) intendedX = chart4.width - hoverInfo.width - units.gu(1);
                        hoverInfo.x = intendedX;
                        var intendedY = chart4.plotArea.y + units.gu(1);
                        hoverInfo.y = intendedY;
                    } else {
                        hoverText.text = "";
                    }
                }
                axisY: ValueAxis {
                    min: 0
                    max: 50
                    tickCount: 5
                    labelsColor: Theme.name === "Ubuntu.Components.Themes.SuruDark" ? "White" : "#444"
                    gridLineColor: Theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#444" : "#ddd"
                }
                axisX: BarCategoryAxis {
                    labelsColor: Theme.name === "Ubuntu.Components.Themes.SuruDark" ? "White" : "#444"
                    gridLineColor: "transparent"
                }
            }

            property variant othersSlice: 0
            property variant task: []

            function reloadData() {
                var accountId = typeof accountPicker !== 'undefined' ? accountPicker.selectedAccountId : -1;
                var quadrant_data = Model.get_tasks_spent_hours(accountId);
                var count = 0;
                var timeval;
                var timecat = [];
                var temp_task = [];
                for (var key in quadrant_data) {
                    temp_task[count] = key;
                    timeval = quadrant_data[key];
                    count = count + 1;
                }
                var count2 = Object.keys(quadrant_data).length;
                for (count = 0; count < count2; count++) {
                    timecat[count] = quadrant_data[temp_task[count]];
                }
                task = temp_task;
                
                mySeries2.clear();
                if (timecat && timecat.length > 0) {
                    var barSet = mySeries2.append(i18n.dtr("ubtms", "Time"), timecat);
                    if (barSet) {
                        // Assign a new color here to replace orange
                        barSet.color = LomiriColors.blue;
                    }
                    mySeries2.axisX.categories = task;
                } else {
                    mySeries2.axisX.categories = [""];
                }
            }

            Component.onCompleted: reloadData()

            Connections {
                target: typeof accountPicker !== "undefined" ? accountPicker : null
                onAccepted: function (accountId, accountName) {
                    reloadData();
                }
            }

            Rectangle {
                id: hoverInfo
                width: Math.min(hoverText.implicitWidth + units.gu(3), parent.width - units.gu(4))
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
    }

    /*    LomiriShape {
        id: rect3
        anchors.top: rect2.bottom
        width: parent.width
        height: units.gu(40)

            Column{
                    id: myCol1
                    spacing: 2
                    leftPadding: 10
                    Row{
                            spacing: 2
                            Rectangle { color: "lightskyblue"
                                        width: 20
                                        height: 20
                            }
                            Text {
                                    id: myLabel_1
                                    text: qsTr("Important, Urgent")
                                }
                        }
                    Row{
                            spacing: 2
                            Rectangle { color: "deepskyblue"
                                        width: 20
                                        height: 20
                            }
                            Text {
                                    id: myLabel_2
                                    text: qsTr("Important, Not Urgent")
                                }
                    }

            }
        Column{
                id: myCol2
                anchors.left: myCol1.right
                spacing: 2
                leftPadding: 10
                Row{
                        spacing: 2
                        Rectangle { color: "steelblue"
                                    width: 20
                                    height: 20
                        }
                        Text {
                                id: myLabel_3
                                text: qsTr("Not Important, Urgent")
                            }
                }
                Row{
                        spacing: 2
                        Rectangle { color: "#0e1a24"
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
*/

}
