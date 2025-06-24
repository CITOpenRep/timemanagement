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

Rectangle {
    id: rect1
    width: parent.width
    height: units.gu(40)

    ChartView {
        id: chart
        z: 100
        title: "Time Spent this week"
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
            id: pieSeries
            size: 0.5
            PieSlice {
                label: "Important, Urgent"
                value: chart.timecat[0]
            } //  Data from Js
            PieSlice {
                label: "Important, Not Urgent"
                value: chart.timecat[1]
            }
            PieSlice {
                label: "Not Important, Urgent"
                value: chart.timecat[2]
            }
            PieSlice {
                label: "Not Important, Not Urgent"
                value: chart.timecat[3]
            }
        }
        Component.onCompleted: {
            // You can also manipulate slices dynamically, like append a slice or set a slice exploded
            //othersSlice = pieSeries.append("Others", 42.0);
            //Any animation or labels to be added here
            //                        DbInit.initializeDatabase();
            //                        DemoData.record_demo_data();
            var quadrant_data = Model.get_quadrant_difference();
            // console.log('\n\n quadrant_data', quadrant_data[0]);
            chart.timecat = quadrant_data;

            pieSeries.find("Important, Urgent").exploded = true;
        }
    }
}

/****************
    * Chart 2 comes below
    *****************/

/*        Rectangle {
            id: rect2
//            anchors.top: rect1.bottom
            width: parent.width
            height: units.gu(40)

                ChartView {
                    id: chart2
                    z: 100
                    title: "Time Spent this month"
    //                            x: -10
    //                            y: -10
                    margins { top: 50; bottom: 0; left: 0; right: 0 }
                    backgroundRoundness: 0
                    anchors { fill: parent; margins: 0; top: header.bottom }
                    antialiasing: true
                    legend.visible: false

                    property variant othersSlice: 0
                    property variant timecat: []


                    PieSeries {
                        id: pieSeries2
                        size: 0.5
                        PieSlice { label: "Important, Urgent"; value: chart2.timecat[0] } //  Data from Js
                        PieSlice { label: "Important, Not Urgent"; value: chart2.timecat[1] }
                        PieSlice { label: "Not Important, Urgent"; value: chart2.timecat[2]}
                        PieSlice { label: "Not Important, Not Urgent"; value: chart2.timecat[3]}
                    }
                    Component.onCompleted: {
                        var quadrant_data = Model.get_quadrant_current_month();
                        console.log('\n\n quadrant_data', quadrant_data)
                        chart2.timecat = quadrant_data;
                    }




                }

        }*/

/********************************
    * The manually added Legend box *
    ********************************/

/*        LomiriShape {
            id: rect3
            anchors.top: rect2.bottom
            width: parent.width
            height: units.gu(10)

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

        }   */
/**************************
* Projectwise graph       *
**************************/
/*        LomiriShape {
            id: rect4
            anchors.top: rect3.bottom
            width: parent.width
            height: units.gu(40)

                ChartView {
                    id: chart3
                    title: "Projectwise Time Spent"
                    anchors.fill: parent
                    legend.alignment: Qt.AlignBottom
                    antialiasing: true

                    BarSeries {
                        id: mySeries
                        axisY: ValueAxis {
                                min: 0
                                max: 50
                                tickCount: 5
                             }
                    }

                    property variant othersSlice: 0
                    property variant timecat: []
                    property variant project: []



                Component.onCompleted: {
                    var quadrant_data = Model.get_projects_spent_hours();
                    chart.timecat = quadrant_data;
                    var count = 0;
                    var timeval;
                    for (var key in quadrant_data) {
                        project[count] = key;
                        timeval = quadrant_data[key];
                        count = count+1;
                    }
                    var count2 = Object.keys(quadrant_data).length;
                    for (count = 0; count < count2; count++)
                        {
                            timecat[count] = quadrant_data[project[count]];
                            console.log("Timecat: " + timecat[count]);
                    }
                    mySeries.append("Time", timecat);
                    mySeries.axisX.categories =  project;

                }
            }

        }*/

/************************/

/**************************
* Taskwise graph          *
**************************/
/*    LomiriShape {
        id: rect5
        anchors.top: rect4.bottom
        width: parent.width
        height: units.gu(40)

            ChartView {
                id: chart4
                title: "Taskwise Time Spent"
                anchors.fill: parent
                theme: ChartView.ChartThemeHighContrast
                legend.alignment: Qt.AlignBottom
                antialiasing: true

                BarSeries {
                    id: mySeries2
                    axisY: ValueAxis {
                            min: 0
                            max: 50
                            tickCount: 5
                            }
                }

                Component.onCompleted: {
                    get_task_chart_data();
                    var count = 0;
                    var count2 = Object.keys(task_data).length;
                    console.log("Count2 is: " + count2)
                    for (count = 0; count < count2; count++)
                        {
                            console.log("Task Timecat: " + task_timecat[count]);
                    }
                    mySeries2.append("Time", task_timecat);
                    mySeries2.axisX.categories =  task;
                }

            }
        }*/

