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
import QtCharts 2.0
import QtQuick.Controls 2.2
import "../../models/utils.js" as Utils
import "../../models/project.js" as Project
import "../../models/accounts.js" as Account

Item {
    width: parent.width
    height: parent.height

    // account used to fetch data; numeric -1 indicates "all accounts"
    property int selectedAccountId: -1

    // Custom styled title overlay
    Text {
        id: chartTitle
        text: "Most Time-Consuming Projects"
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        font.pixelSize: units.gu(2)
        color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "White" : "#444"
        padding: units.gu(1.5)
    }

    // Main ChartView below the title
    ChartView {
        id: pieChart
        anchors.top: chartTitle.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        backgroundColor: "transparent"

        antialiasing: true
        title: ""
        legend.visible: false
        legend.alignment: Qt.AlignBottom
        legend.labelColor: "black"
        legend.font.pixelSize: units.gu(1.3)

        margins.top: 1
        margins.bottom: 1
        margins.left: 1
        margins.right: 1

        PieSeries {
            id: pieSeries
            size: 0.6
            holeSize: 0.3
            horizontalPosition: 0.5
            verticalPosition: 0.45
        }
    }

    ListModel {
        id: legendModel
    }

    Column {
        id: customLegend
        anchors.top: pieChart.bottom
        width: parent.width
        spacing: units.gu(1)
        padding: units.gu(1.5)

        Repeater {
            model: legendModel
            delegate: legendDelegate
        }
    }

    Component {
        id: legendDelegate
        Rectangle {
            id: rect
            width: parent.width - units.gu(3) //2 times padding
            height: units.gu(6)
            color: "transparent"
            border.color: "#ccc"
            radius: units.gu(0.5)

            Row {
                anchors.fill: parent
                anchors.margins: units.gu(1.5)
                spacing: units.gu(1.5)

                Rectangle {
                    width: units.gu(2)
                    height: units.gu(2)
                    color: model.color
                }

                Text {
                    id: label
                    text: Utils.truncateText(model.label, 35)
                    font.pixelSize: units.gu(2)
                    color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "white" : "#333"
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    width: parent.width
                }
            }
        }
    }

    function load(data) {
        pieSeries.clear();
        legendModel.clear();

        if (!data || data.length === 0) {
            chartTitle.text = "Most Time-Consuming Projects(No Data)";
            return;
        }
        chartTitle.text = "Most Time-Consuming Projects";

        data.sort(function (a, b) {
            return b.spentHours - a.spentHours;
        });

        var topCount = 10;
        var topProjects = data.slice(0, topCount);
        var otherTotal = 0;

        for (var i = topCount; i < data.length; i++) {
            otherTotal += data[i].spentHours;
        }

        var total = topProjects.reduce(function (sum, p) {
            return sum + p.spentHours;
        }, 0) + otherTotal;

        // 🎨 Vibrant color palette
        var colors = ["#F94144", "#F3722C", "#F8961E", "#F9844A", "#F9C74F", "#90BE6D", "#43AA8B", "#577590", "#277DA1", "#8E44AD"];

        for (var i = 0; i < topProjects.length; i++) {
            var item = topProjects[i];
            var percent = ((item.spentHours / total) * 100).toFixed(1);
            var colorStr = colors[i % colors.length];  // Get the hex color as string

            var slice = pieSeries.append(item.name, item.spentHours);
            slice.label = item.name + " (" + percent + "%)";
            slice.labelPosition = PieSlice.LabelInsideHorizontal;
            slice.labelVisible = false;
            slice.color = colorStr;

            // ❗ Use the known color string here
            legendModel.append({
                label: slice.label,
                color: colorStr
            });
        }

        if (otherTotal > 0) {
            var percent = ((otherTotal / total) * 100).toFixed(1);
            var slice = pieSeries.append("Others", otherTotal);
            slice.label = "Others (" + percent + "%)";
            slice.labelPosition = PieSlice.LabelInsideHorizontal;
            slice.labelVisible = false;
            slice.color = "#BDC3C7";

            legendModel.append({
                label: slice.label,
                color: "#BDC3C7"
            });
        }
    }

    // Fetch-and-load helper using the new project API signature
    function refreshForAccount(accountId) {
        var acctNum = -1;
        try {
            if (typeof accountId !== "undefined" && accountId !== null) {
                var maybe = Number(accountId);
                acctNum = isNaN(maybe) ? -1 : maybe;
            } else {
                acctNum = -1;
            }
        } catch (e) {
            acctNum = -1;
        }

        selectedAccountId = acctNum;

        // call project API with account param
        try {
            var data = Project.getProjectSpentHoursList(true, selectedAccountId);
            // data should be an array; load chart
            load(data || []);
        } catch (e) {
            console.error("ProjectPieChart: error fetching project spent hours:", e);
            load([]);
        }
    }

    // Re-fetch when the account selector changes
    Connections {
        target: accountFilter
        onAccountChanged: function (accountId, accountName) {
            refreshForAccount(accountId);
        }
    }

    // Also respond to global account change / refresh events
    Connections {
        target: mainView
        onAccountDataRefreshRequested: function (accountId) {
            refreshForAccount(accountId);
        }
        onGlobalAccountChanged: function (accountId, accountName) {
            refreshForAccount(accountId);
        }
    }

    Component.onCompleted: {
        // Probe for initial account selection and refresh
        try {
            var initial = -1;
            if (typeof accountFilter !== "undefined" && accountFilter !== null) {
                if (typeof accountFilter.selectedAccountId !== "undefined" && accountFilter.selectedAccountId !== null) {
                    var maybe = Number(accountFilter.selectedAccountId);
                    initial = isNaN(maybe) ? -1 : maybe;
                } else if (typeof accountFilter.currentAccountId !== "undefined" && accountFilter.currentAccountId !== null) {
                    var maybe2 = Number(accountFilter.currentAccountId);
                    initial = isNaN(maybe2) ? -1 : maybe2;
                } else if (typeof accountFilter.currentIndex !== "undefined" && accountFilter.currentIndex >= 0) {
                    // mapping index -> id would be required; use -1 to be safe
                    initial = -1;
                } else {
                    initial = -1;
                }
            } else if (typeof Account !== "undefined" && typeof Account.getSelectedAccountId === "function") {
                var acct = Account.getSelectedAccountId();
                var maybe3 = Number(acct);
                initial = (acct !== null && typeof acct !== "undefined" && !isNaN(maybe3)) ? maybe3 : -1;
            } else {
                initial = -1;
            }

            refreshForAccount(initial);
        } catch (e) {
            console.error("ProjectPieChart: error determining initial account:", e);
            refreshForAccount(-1);
        }
    }
}
