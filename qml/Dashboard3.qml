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
import "../models/Main.js" as Model

Page {
    id: dashboard2
    title: "Task"
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
            title: "Taskwise Time Spent"
            anchors.fill: parent
            theme: ChartView.ChartThemeHighContrast
            legend.alignment: Qt.AlignBottom
            antialiasing: true

            backgroundColor: "transparent"
            legend.labelColor: "red"

            BarSeries {
                id: mySeries2
                axisY: ValueAxis {
                    min: 0
                    max: 50
                    tickCount: 5
                }
            }

            property variant othersSlice: 0
            property variant task: []

            Component.onCompleted: {
                var quadrant_data = Model.get_tasks_spent_hours();
                var count = 0;
                var timeval;
                var timecat = [];
                for (var key in quadrant_data) {
                    task[count] = key;
                    timeval = quadrant_data[key];
                    count = count + 1;
                }
                var count2 = Object.keys(quadrant_data).length;
                for (count = 0; count < count2; count++) {
                    timecat[count] = quadrant_data[task[count]];
                    // console.log("Dashboard 3 Timecat in task: " + timecat[count]);
                }
                mySeries2.append("Time", timecat);
                mySeries2.axisX.categories = task;
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
