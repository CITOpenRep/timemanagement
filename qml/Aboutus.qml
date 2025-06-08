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
import "../models/constants.js" as AppConst

Page {
    id: aboutPage
    title: "About"
    anchors.fill: parent
    property string releaseNotesHtml: ""

    Component.onCompleted: {
        var xhr = new XMLHttpRequest();
        xhr.open("GET", Qt.resolvedUrl("release_notes.txt"));
        xhr.onreadystatechange = function () {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                releaseNotesHtml = (xhr.status === 200) ? xhr.responseText : "<p><i>Release notes could not be loaded.</i></p>";
            }
        };
        xhr.send();
    }

    header: PageHeader {
        title: "About"
    }

    Flickable {
        id: flick
        anchors.top: header.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        contentWidth: parent.width
        contentHeight: contentContainer.height
        clip: true

        Column {
            id: contentContainer
            width: flick.width
            spacing: units.gu(1)
            Label {
                text: "Time Management App"
                font.bold: true
                font.pixelSize: units.gu(2.5)
            }

            Label {
                text: "Version: " + AppConst.version
                font.pixelSize: units.gu(2)
            }

            Label {
                text: "Release Notes:"
                font.bold: true
                font.pixelSize: units.gu(2.2)
            }

            Text {
                text: releaseNotesHtml
                textFormat: Text.RichText
                wrapMode: Text.Wrap
                width: parent.width - units.gu(4)
                font.pixelSize: units.gu(1.8)
            }
        }
    }
}
