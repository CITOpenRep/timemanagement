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
import "../constants.js" as AppConst
import QtQuick.LocalStorage 2.7 as Sql

Item {
    id: ehoverMatrix
    width: parent.width
    height: parent.height
    signal quadrantClicked(int quadrant)

    property string quadrant1Hours: "0"
    property string quadrant2Hours: "0"
    property string quadrant3Hours: "0"
    property string quadrant4Hours: "0"

    // No need of external JS file , we can make it embed
    function getQuadrantHoursFromAllInstances() {
        var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
        var quadrantHours = {
            1: 0.0,
            2: 0.0,
            3: 0.0,
            4: 0.0
        };

        try {
            db.transaction(function (tx) {
                // console.log("-----> Fetching all instances from users");
                var users = tx.executeSql("SELECT id, name FROM users");
                // console.log("-----> Total instances found:", users.rows.length);

                for (var u = 0; u < users.rows.length; u++) {
                    var instance_id = users.rows.item(u).id;
                    var instance_name = users.rows.item(u).name;
                    //   console.log("-----> Processing instance:", instance_name, "(ID:", instance_id, ")");

                    var rs = tx.executeSql("SELECT quadrant_id, SUM(unit_amount) as total FROM account_analytic_line_app WHERE account_id = ? GROUP BY quadrant_id", [instance_id]);

                    //  console.log("  -----> Timesheets for this instance:", rs.rows.length);
                    for (var i = 0; i < rs.rows.length; i++) {
                        var qid = rs.rows.item(i).quadrant_id;
                        var total = rs.rows.item(i).total;
                        //console.log("     -> Q" + qid + ": " + total);
                        if (qid === null || qid < 1 || qid > 4) {
                            qid = 1;
                        }

                        if (qid >= 1 && qid <= 4 && total !== null) {
                            quadrantHours[qid] += parseFloat(total);
                        }
                    }
                }
            });
        } catch (err) {
            console.error("ERROR during quadrant aggregation:", err);
        }

        //console.log("-----> Aggregated quadrant totals:");
        //console.log("     Q1:", quadrantHours[1]);
        //console.log("     Q2:", quadrantHours[2]);
        //console.log("     Q3:", quadrantHours[3]);
        //console.log("     Q4:", quadrantHours[4]);

        return {
            1: Math.round(quadrantHours[1]).toString(),
            2: Math.round(quadrantHours[2]).toString(),
            3: Math.round(quadrantHours[3]).toString(),
            4: Math.round(quadrantHours[4]).toString()
        };
    }

    Text {
        id: headlabel
        text: "Time spent based on priorities"
        font.pixelSize: units.gu(2)
        color: "#444"
        anchors.topMargin: 5
        horizontalAlignment: Text.AlignHCenter
        anchors.horizontalCenter: parent.horizontalCenter
    }

    GridLayout {
        id: matrix
        anchors.top: headlabel.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 5
        columns: 2
        rowSpacing: 10
        columnSpacing: 10

        // Q1 - Urgent & Important
        Rectangle {
            id: q1Rect
            color: AppConst.Colors.Quadrants.Q1
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: units.gu(1)
            scale: 1.0
            transformOrigin: Item.Center

            Behavior on scale {
                NumberAnimation {
                    duration: 100
                    easing.type: Easing.InOutQuad
                }
            }

            MouseArea {
                anchors.fill: parent
                onPressed: q1Rect.scale = 0.97
                onReleased: {
                    q1Rect.scale = 1.0;
                    ehoverMatrix.quadrantClicked(1);
                }
                onCanceled: q1Rect.scale = 1.0
            }

            Column {
                anchors.centerIn: parent
                spacing: units.gu(0.5)

                Text {
                    text: "Do Now <br>(Important & Urgent)"
                    font.bold: true
                    font.pixelSize: units.gu(1.5)
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: quadrant1Hours
                    font.pixelSize: units.gu(8)
                    font.bold: true
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }

        // Q2 - Not Urgent & Important
        Rectangle {
            id: q2Rect
            color: AppConst.Colors.Quadrants.Q2
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: units.gu(1)
            scale: 1.0
            transformOrigin: Item.Center

            Behavior on scale {
                NumberAnimation {
                    duration: 100
                    easing.type: Easing.InOutQuad
                }
            }

            MouseArea {
                anchors.fill: parent
                onPressed: q2Rect.scale = 0.97
                onReleased: {
                    q2Rect.scale = 1.0;
                    ehoverMatrix.quadrantClicked(2);
                }
                onCanceled: q2Rect.scale = 1.0
            }

            Column {
                anchors.centerIn: parent
                spacing: units.gu(0.5)

                Text {
                    text: "Schedule<br>(Important / Not Urgent)"
                    font.bold: true
                    font.pixelSize: units.gu(1.5)
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: quadrant2Hours
                    font.pixelSize: units.gu(8)
                    font.bold: true
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }

        // Q3 - Urgent & Not Important
        Rectangle {
            id: q3Rect
            color: AppConst.Colors.Quadrants.Q3
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: units.gu(1)
            scale: 1.0
            transformOrigin: Item.Center

            Behavior on scale {
                NumberAnimation {
                    duration: 100
                    easing.type: Easing.InOutQuad
                }
            }

            MouseArea {
                anchors.fill: parent
                onPressed: q3Rect.scale = 0.97
                onReleased: {
                    q3Rect.scale = 1.0;
                    ehoverMatrix.quadrantClicked(3);
                }
                onCanceled: q3Rect.scale = 1.0
            }

            Column {
                anchors.centerIn: parent
                spacing: units.gu(0.5)

                Text {
                    text: "Delegate <br>(Urgent / Not Important)"
                    font.bold: true
                    font.pixelSize: units.gu(1.5)
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: quadrant3Hours
                    font.pixelSize: units.gu(8)
                    font.bold: true
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }

        // Q4 - Not Urgent & Not Important
        Rectangle {
            id: q4Rect
            color: AppConst.Colors.Quadrants.Q4
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: units.gu(1)
            scale: 1.0
            transformOrigin: Item.Center

            Behavior on scale {
                NumberAnimation {
                    duration: 100
                    easing.type: Easing.InOutQuad
                }
            }

            MouseArea {
                anchors.fill: parent
                onPressed: q4Rect.scale = 0.97
                onReleased: {
                    q4Rect.scale = 1.0;
                    ehoverMatrix.quadrantClicked(4);
                }
                onCanceled: q4Rect.scale = 1.0
            }

            Column {
                anchors.centerIn: parent
                spacing: units.gu(0.5)

                Text {
                    text: "Eliminate <br>(Not Urgent & Not Important)"
                    font.bold: true
                    font.pixelSize: units.gu(1.5)
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: quadrant4Hours
                    font.pixelSize: units.gu(8)
                    font.bold: true
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }
    }
    Component.onCompleted: {
        var result = getQuadrantHoursFromAllInstances();
        quadrant1Hours = result[1];
        quadrant2Hours = result[2];
        quadrant3Hours = result[3];
        quadrant4Hours = result[4];
    }
    onVisibleChanged: {
        var result = getQuadrantHoursFromAllInstances();
        quadrant1Hours = result[1];
        quadrant2Hours = result[2];
        quadrant3Hours = result[3];
        quadrant4Hours = result[4];
    }
}
