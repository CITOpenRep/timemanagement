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
import QtGraphicalEffects 1.0

Item {
    id: bubbleMap
    width: parent.width
    height: parent.height
    property var bubbleData: []  // you’ll set this from outside
    property color bubbleColor: "#0cc0df"
    property int maxBubbleSize: 100
    property int minBubbleSize: 30
    property int padding: 12

    Text {
        id: headlabel
        text: "Time spent per Project"
        font.pixelSize: units.gu(2.5)
        font.bold: true
        color: "#444"
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 10
        anchors.bottomMargin: 5
    }

    // Show this only if bubbleData is empty
    Text {
        id: noDataText
        visible: bubbleData.length === 0
        text: "No data found"
        anchors.centerIn: parent
        font.pixelSize: units.gu(2.5)
        color: "#888"
        z: 1
    }

    Flickable {
        anchors.top: headlabel.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        contentWidth: parent.width
        contentHeight: layoutCanvas.height
        clip: true

        Rectangle {
            id: layoutCanvas
            width: parent.width
            height: 1  // will grow
            /*gradient: Gradient {
                GradientStop { position: 0.0; color: "#cceeff" }  // Gentle blue-tint
                GradientStop { position: 1.0; color: "#e6fffa" }  // Mint hint
            }*/

            property var placedBubbles: []

            Component {
                id: bubbleComponent
                Rectangle {
                    property string projectName
                    property real spent
                    property int percentage
                    property real scaleFactor

                    width: maxBubbleSize * scaleFactor
                    height: width
                    radius: width / 2
                    color: bubbleColor
                    border.color: "#444"
                    border.width: 1

                    layer.enabled: true
                    layer.effect: DropShadow {
                        color: "#444"
                        radius: 8
                        samples: 16
                        spread: 0.2
                        transparentBorder: true
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: 2
                        width: parent.width * 0.9

                        Text {
                            text: projectName
                            width: parent.width
                            font.bold: true
                            wrapMode: Text.WordWrap
                            font.pixelSize: Math.max(10, parent.width / 8)
                            color: "white"
                            horizontalAlignment: Text.AlignHCenter
                        }

                        Text {
                            text: percentage + "%"
                            font.pixelSize: Math.max(9, parent.width / 8)
                            color: "white"
                            anchors.horizontalCenter: parent.horizontalCenter
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }
            }

            Component.onCompleted: {
                var totalSpent = 0;
                for (var i = 0; i < bubbleData.length; i++) {
                    totalSpent += bubbleData[i].spentHours || 0;
                }

                var columns = Math.floor(layoutCanvas.width / (maxBubbleSize + padding));
                if (columns < 1)
                    columns = 1;

                var rowHeight = maxBubbleSize + padding;
                var maxBottom = 0;

                for (var i = 0; i < bubbleData.length; i++) {
                    var name = bubbleData[i].name;
                    var spent = bubbleData[i].spentHours || 0;
                    var percent = totalSpent > 0 ? Math.round((spent / totalSpent) * 100) : 0;
                    var scaleFactor = totalSpent > 0 ? Math.max(minBubbleSize / maxBubbleSize, spent / Math.max.apply(null, bubbleData.map(b => b.spentHours))) : 1;

                    var col = i % columns;
                    var row = Math.floor(i / columns);

                    var x = col * (maxBubbleSize + padding) + padding;
                    var y = row * rowHeight + padding;

                    var bubble = bubbleComponent.createObject(layoutCanvas, {
                        projectName: name,
                        spent: spent,
                        percentage: percent,
                        scaleFactor: scaleFactor,
                        x: x,
                        y: y
                    });

                    maxBottom = Math.max(maxBottom, y + maxBubbleSize);
                }

                layoutCanvas.height = maxBottom + padding;
            }
        }
    }
}
