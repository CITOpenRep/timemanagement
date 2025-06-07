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

import QtQuick 2.0
import QtQuick.Controls 2.2
import QtQuick.Window 2.2

ListView {
    id: root
    property int selectedYear: 2024

    signal clicked(date date)

    property date selectedDate: new Date()
    function isDesktop() {
        if (Screen.width > 1300) {
            return true;
        } else {
            return false;
        }
    }
    width: isDesktop() ? 450 : 600
    height: isDesktop() ? 450 : 600
    snapMode: ListView.SnapOneItem
    orientation: Qt.Horizontal
    clip: true
    anchors.margins: 0

    model: 500 * 12

    function set(year, month) {
        selectedYear = year;
        selectedDate = new Date(year, month, selectedDate.getDate());
        var index = year * 12 + month;
        listView.currentIndex = index;
    }

    Item {
        width: isDesktop() ? 400 : 600
        height: isDesktop() ? 345 : 600
        anchors.centerIn: parent
        Row {
            spacing: 10
            anchors {
                horizontalCenter: parent.horizontalCenter
                top: parent.top
                topMargin: isDesktop() ? 0 : 80
            }

            ComboBox {
                id: yearSelector
                width: isDesktop() ? 200 : 300
                height: isDesktop() ? 30 : 57
                textRole: "yearText"
                model: ListModel {
                    Component.onCompleted: {
                        var currentYear = new Date().getFullYear();
                        for (var i = currentYear; i < currentYear + 10; ++i) {
                            append({
                                "yearText": i.toString()
                            });
                        }
                    }
                }

                onCurrentTextChanged: {
                    selectedYear = parseInt(currentText);
                }
            }

            Button {
                width: isDesktop() ? 80 : 100
                height: isDesktop() ? 30 : 50

                background: Rectangle {
                    color: "#FB634E"
                    radius: 10
                    border.color: "#FB634E"
                    border.width: 2
                    anchors.fill: parent
                }
                contentItem: Text {
                    anchors.fill: parent
                    text: "Go"
                    color: "#fff"
                    font.pixelSize: isDesktop() ? 20 : 30
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                onClicked: {
                    var selectedYear = parseInt(yearSelector.currentText);
                    root.set(selectedYear, root.selectedDate.getMonth());
                }
            }
        }
    }

    delegate: Item {
        property int month: index % 12
        property int firstDay: new Date(selectedYear, month, 1).getDay()

        width: root.width
        height: root.height

        Rectangle {
            width: parent.width
            height: isDesktop() ? 390 : 600
            color: "#121944"
            border.color: "#121944"
        }

        y: 10

        Column {
            spacing: isDesktop() ? 40 : 60

            Item {
                width: root.width
                height: isDesktop() ? root.height - grid.height - 100 : root.height - grid.height - 70

                Text {
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        top: parent.top
                        centerIn: parent
                    }

                    color: "#fff"
                    text: ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'][month] + ' ' + selectedYear
                    font {
                        pixelSize: 0.5 * grid.cellHeight
                    }
                }
            }

            Grid {
                id: grid

                width: root.width
                height: (isDesktop() ? 0.675 : 0.745) * root.height
                property real cellWidth: width / columns
                property real cellHeight: height / rows

                columns: 7
                rows: 7

                Repeater {
                    model: grid.columns * grid.rows

                    delegate: Rectangle {
                        property int day: index - 7
                        property int date: day - firstDay + 1

                        width: grid.cellWidth
                        height: grid.cellHeight
                        border.width: 0.3 * radius
                        border.color: new Date(selectedYear, month, date).toDateString() == selectedDate.toDateString() && text.text && day >= 0 ? 'black' : 'transparent'
                        radius: 0.02 * root.height
                        opacity: !mouseArea.pressed ? 1 : 0.3

                        Text {
                            id: text

                            anchors.centerIn: parent
                            font.pixelSize: 0.5 * parent.height
                            font.bold: new Date(selectedYear, month, date).toDateString() == new Date().toDateString()
                            text: {
                                if (day < 0)
                                    ['S', 'M', 'T', 'W', 'T', 'F', 'S'][index];
                                else if (new Date(selectedYear, month, date).getMonth() == month)
                                    date;
                                else
                                    '';
                            }
                        }

                        MouseArea {
                            id: mouseArea

                            anchors.fill: parent
                            enabled: text.text && day >= 0

                            onClicked: {
                                selectedDate = new Date(selectedYear, month, date);
                                root.clicked(selectedDate);
                            }
                        }
                    }
                }
            }
        }
    }
}
