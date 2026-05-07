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

Item {
    id: root
    width: parent ? parent.width : units.gu(48)
    
    // Dynamic height based on number of categories to prevent the chart from becoming too small
    property int categoryCount: 1
    implicitHeight: Math.max(units.gu(40), categoryCount * units.gu(5) + units.gu(12))
    height: implicitHeight
    
    property bool autoRefreshOnAccountChange: true
    property int selectedAccountId: typeof accountPicker !== "undefined" ? accountPicker.selectedAccountId : -1

    function reloadData() {
        var t_proj = [];
        var t_cat = [];
        var maxVal = 0;
        var data = Model.get_projects_spent_hours(root.selectedAccountId);

        for (var key in data) {
            t_proj.push(key);
            t_cat.push(data[key]);
            if (data[key] > maxVal) maxVal = data[key];
        }

        root.categoryCount = Math.max(1, t_cat.length);
        mySeries.clear();

        if (t_cat && t_cat.length > 0) {
            var barSet = mySeries.append(i18n.dtr("ubtms", "Time"), t_cat);
            if (barSet) {
                // Use a nice accent color
                barSet.color = LomiriColors.blue;
                barSet.borderColor = "transparent";
            }
            mySeries.axisY.categories = t_proj;
            mySeries.axisX.max = maxVal > 0 ? Math.ceil(maxVal * 1.1) : 50;
        } else {
            mySeries.axisY.categories = [""];
            mySeries.axisX.max = 50;
        }
    }

    Component.onCompleted: reloadData()

    Connections {
        target: root.autoRefreshOnAccountChange && typeof accountPicker !== "undefined" ? accountPicker : null
        onAccepted: function (accountId, accountName) {
            reloadData();
        }
    }

    // Glassmorphism Card Background
    Rectangle {
        id: cardBg
        anchors.fill: parent
        anchors.margins: units.gu(1)
        radius: units.gu(1.5)
        color: Theme.name === "Ubuntu.Components.Themes.SuruDark" ? Qt.rgba(1, 1, 1, 0.05) : Qt.rgba(0, 0, 0, 0.03)
        border.color: Theme.name === "Ubuntu.Components.Themes.SuruDark" ? Qt.rgba(1, 1, 1, 0.1) : Qt.rgba(0, 0, 0, 0.1)
        border.width: units.dp(1)
        
        // Top accent strip
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: units.gu(1.5)
            anchors.rightMargin: units.gu(1.5)
            height: units.dp(3)
            color: LomiriColors.blue
        }

        ChartView {
            id: chart3
            title: i18n.dtr("ubtms", "Projectwise Time Spent")
            titleColor: Theme.name === "Ubuntu.Components.Themes.SuruDark" ? "White" : "#444"
            titleFont.pixelSize: units.dp(15)
            titleFont.bold: true

            anchors.fill: parent
            margins {
                top: units.gu(4)
                bottom: units.gu(2)
                left: units.gu(2)
                right: units.gu(2)
            }
            legend.alignment: Qt.AlignBottom
            antialiasing: true

            backgroundColor: "transparent"
            legend.labelColor: Theme.name === "Ubuntu.Components.Themes.SuruDark" ? "White" : "#444"
            legend.font.pixelSize: units.dp(12)

            HorizontalBarSeries {
                id: mySeries
                onHovered: function(status, index, barset) {
                    if (status) {
                        var cat = mySeries.axisY.categories[index];
                        var val = barset.at(index);
                        hoverText.text = cat + " — " + Number(val).toFixed(1) + i18n.dtr("ubtms", " hrs");

                        var barCount = Math.max(1, mySeries.axisY.categories.length);
                        var barHeight = chart3.plotArea.height / barCount;
                        
                        // Calculate intended position relative to the plot area
                        // QtCharts plots categories from bottom to top usually, but index 0 might be at the bottom or top depending on the axis.
                        // We map it such that the hover info tracks the mouse roughly or is just placed correctly.
                        // Assuming index 0 is at bottom, then index is offset from bottom.
                        // But to be safe, just place it near the bar center.
                        var intendedY = chart3.plotArea.y + chart3.plotArea.height - (index + 0.5) * barHeight - hoverInfo.height / 2;
                        
                        if (intendedY < chart3.plotArea.y) intendedY = chart3.plotArea.y + units.gu(1);
                        if (intendedY + hoverInfo.height > chart3.plotArea.y + chart3.plotArea.height) intendedY = chart3.plotArea.y + chart3.plotArea.height - hoverInfo.height - units.gu(1);
                        
                        var intendedX = chart3.plotArea.x + chart3.plotArea.width - hoverInfo.width - units.gu(1);
                        
                        hoverInfo.x = intendedX;
                        hoverInfo.y = intendedY;
                    } else {
                        hoverText.text = "";
                    }
                }
                
                axisX: ValueAxis {
                    min: 0
                    max: 50
                    tickCount: 5
                    labelsColor: Theme.name === "Ubuntu.Components.Themes.SuruDark" ? "White" : "#444"
                    gridLineColor: Theme.name === "Ubuntu.Components.Themes.SuruDark" ? Qt.rgba(1, 1, 1, 0.1) : Qt.rgba(0, 0, 0, 0.1)
                    labelFormat: "%.0f"
                }
                
                axisY: BarCategoryAxis {
                    labelsColor: Theme.name === "Ubuntu.Components.Themes.SuruDark" ? "White" : "#444"
                    gridLineColor: "transparent"
                }
            }
        }
    }

    Rectangle {
        id: hoverInfo
        width: Math.min(hoverText.implicitWidth + units.gu(3), parent.width - units.gu(4))
        height: hoverText.implicitHeight + units.gu(1.5)
        color: Theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#333" : "#FFF"
        border.color: LomiriColors.blue
        border.width: units.dp(1)
        radius: units.gu(0.8)
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
            font.weight: Font.DemiBold
            font.pixelSize: units.dp(13)
        }
    }
}
