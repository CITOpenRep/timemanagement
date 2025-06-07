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
import "../models/DbInit.js" as DbInit
import "../models/DemoData.js" as DemoData

Page {
    id: splashPage
    title: "Timesheet"
    anchors.fill: parent

    header: PageHeader {
        id: header
        visible: false
        title: "Splash"
    }

    Rectangle {
        id: splashrect
        visible: true
        anchors.fill: parent
        width: units.gu(45)
        height: units.gu(75)
        color: "#ffffff"
        border.color: "black"
        border.width: 1

        Image {
            id: image
            anchors.centerIn: parent
            width: units.gu(30)
            height: units.gu(30)
            source: "logo.png"
            opacity: 0.3

            // Animate the opacity to fade in
            SequentialAnimation on opacity {
                running: true
                loops: 1
                NumberAnimation {
                    from: 0.3
                    to: 1.0
                    duration: 1000
                }
            }
        }

        Timer {
            interval: 2000
            running: true
            repeat: false
            onTriggered: {
                splashrect.visible = false;
                apLayout.setFirstScreen();
            }
        }
    }
}
