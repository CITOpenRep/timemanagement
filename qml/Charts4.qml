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

/**************************
* Taskwise graph          *
**************************/
Rectangle {
    id: rect5
    //        anchors.top: rect4.bottom
    width: parent.width
    height: units.gu(40)
    color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#222" : "transparent"

    ChartView {
        id: chart4
        title: "Taskwise Time Spent"
        titleColor: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "White" : "#444"
        anchors.fill: parent
        theme: ChartView.ChartThemeHighContrast
        legend.alignment: Qt.AlignBottom
        antialiasing: true

        backgroundColor: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#222" : "transparent"

        legend.labelColor: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "White" : "#444"
        legend.font.pixelSize: units.gu(3)

        BarSeries {
            id: mySeries2
            axisY: ValueAxis {
                min: 0
                max: 50
                tickCount: 5
                labelsColor: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "White" : "#444"
            }
            axisX: BarCategoryAxis {
                labelsColor: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "White" : "#444"
            }
        }

        Component.onCompleted: {
            get_task_chart_data();
            var count = 0;
            var count2 = Object.keys(task_data).length;
          //  console.log("Count2 is: " + count2);
            /*                    for (count = 0; count < count2; count++)
                        {
                            console.log("Task Timecat: " + task_timecat[count]);
                    }*/
            mySeries2.append("Time", task_timecat);
            mySeries2.axisX.categories = task;
        }
    }
}
