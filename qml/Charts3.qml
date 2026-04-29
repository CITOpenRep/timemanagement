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
* This is a Bar Chart for Projectwise Time Spent
* It is only visible in Convergence Mode
Todo : The Chart Files need to be revisited and Merged in a Single File with all the Different Charts.
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
        titleColor: Theme.name === "Ubuntu.Components.Themes.SuruDark" ? "White" : "#444"

        anchors.fill: parent
        legend.alignment: Qt.AlignBottom
        antialiasing: true

        backgroundColor: "transparent"
        legend.labelColor: Theme.name === "Ubuntu.Components.Themes.SuruDark" ? "White" : "#444"
        legend.font.pixelSize: units.gu(3)

        // No built-in theme so it doesn't override our custom transparent background
        // theme: Theme.name === "Ubuntu.Components.Themes.SuruDark" ? ChartView.ChartThemeDark : ChartView.ChartThemeLight

        BarSeries {
            id: mySeries
            onHovered: {
                if (status) {
                    var cat = mySeries.axisX.categories[index];
                    var val = barset.at(index);
                    hoverText.text = cat + " — " + Number(val).toFixed(1) + i18n.dtr("ubtms", " hrs");
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
                gridLineColor: Theme.name === "Ubuntu.Components.Themes.SuruDark" ? "transparent" : "transparent"
            }
        }

        function reloadData() {
            if (typeof parent.get_project_chart_data === 'function') parent.get_project_chart_data();
            else if (typeof get_project_chart_data === 'function') get_project_chart_data();

            mySeries.clear();
            var t_cat = typeof project_timecat !== 'undefined' ? project_timecat : [];
            var t_proj = typeof project !== 'undefined' ? project : [];
            
            if (t_cat && t_cat.length > 0) {
                var barSet = mySeries.append(i18n.dtr("ubtms", "Time"), t_cat);
                if (barSet) {
                    barSet.color = LomiriColors.blue;
                }
                mySeries.axisX.categories = t_proj;
            } else {
                mySeries.axisX.categories = [""];
            }
        }

        Component.onCompleted: reloadData()
        
        Rectangle {
            id: hoverInfo
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: units.gu(1)
            width: hoverText.width + units.gu(3)
            height: hoverText.height + units.gu(1.5)
            color: Theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#555" : "#FFF"
            border.color: Theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#888" : "#ccc"
            border.width: 1
            radius: units.gu(0.5)
            opacity: hoverText.text !== "" ? 0.95 : 0.0
            Behavior on opacity { NumberAnimation { duration: 150 } }
            z: 100

            Label {
                id: hoverText
                anchors.centerIn: parent
                text: ""
                color: Theme.name === "Ubuntu.Components.Themes.SuruDark" ? "White" : "Black"
                font.weight: Font.Light
                font.pixelSize: units.gu(2)
            }
        }
    }
}

/************************/
