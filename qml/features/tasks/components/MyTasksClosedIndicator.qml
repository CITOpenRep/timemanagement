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

import QtQuick 2.9
import Lomiri.Components 1.3

Rectangle {
    id: root

    color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#2d5016" : "#dff0d8"
    border.color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#4caf50" : "#5cb85c"
    border.width: 1

    Row {
        anchors.centerIn: parent
        spacing: units.gu(1)

        Icon {
            name: "info"
            width: units.gu(2)
            height: units.gu(2)
            color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#4caf50" : "#3c763d"
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: i18n.dtr("ubtms", "Showing closed/completed tasks")
            color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#4caf50" : "#3c763d"
            font.pixelSize: units.gu(1.5)
            font.bold: true
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
