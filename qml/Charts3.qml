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
* Projectwise graph       *
**************************/
Rectangle {
    id: rect4
    width: parent.width
    height: units.gu(40)
    color: "transparent"
    //anchors.fill: parent

    //   Text {
    //     id: chartTitle
    //     text: "Projectwise Time Spent"
    //     anchors.top: parent.top
    //     anchors.horizontalCenter: parent.horizontalCenter
    //     font.pixelSize: units.gu(2)
    //     color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "White" : "#444"
    //     padding: units.gu(1.5)
    // }

    ChartView {
        id: chart3
        title: "Projectwise Time Spent"
        titleColor: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "White" : "#444"

        anchors.fill: parent
        legend.alignment: Qt.AlignBottom
        antialiasing: true

        backgroundColor: "transparent"
        legend.labelColor: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "White" : "#444"
        legend.font.pixelSize: units.gu(3)

        // theme: ChartView.ChartThemeHighContrast

        BarSeries {
            id: mySeries
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
            get_project_chart_data();

            var count = 0;
            var count2 = Object.keys(project_data).length;
            //  console.log("Count2 is: " + count2);
            /*                    for (count = 0; count < count2; count++)
                        {
                            console.log("Project Timecat: " + project_timecat[count]);
                    }*/
            mySeries.append("Time", project_timecat);
            mySeries.axisX.categories = project;
        }
    }
}

/************************/
