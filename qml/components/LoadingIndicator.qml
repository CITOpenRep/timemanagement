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

/**
 * LoadingIndicator - A reusable loading indicator component
 *
 * Usage:
 *   LoadingIndicator {
 *       anchors.fill: parent
 *       visible: isLoading
 *       message: "Loading data..."  // optional
 *       overlayMode: true           // default: true
 *   }
 */
Item {
    id: loadingIndicator

    // Public properties
    property bool overlayMode: true
    property string message: ""
    property bool darkMode: theme.name === "Ubuntu.Components.Themes.SuruDark"

    // Make sure loading indicator is on top of other content
    z: 999

    // Semi-transparent overlay background (only in overlay mode)
    Rectangle {
        id: overlay
        anchors.fill: parent
        visible: loadingIndicator.overlayMode
        color: darkMode ? "#80000000" : "#80FFFFFF"

        // Block mouse events to prevent interaction with content below
        MouseArea {
            anchors.fill: parent
            enabled: loadingIndicator.visible
            onClicked: {
                // Consume click to prevent propagation
            }
        }
    }

    // Centered loading content
    Column {
        anchors.centerIn: parent
        spacing: units.gu(2)

        // Spinner
        ActivityIndicator {
            id: spinner
            anchors.horizontalCenter: parent.horizontalCenter
            running: loadingIndicator.visible
        }

        // Optional message label
        Label {
            id: messageLabel
            visible: loadingIndicator.message !== ""
            text: loadingIndicator.message
            anchors.horizontalCenter: parent.horizontalCenter
            color: darkMode ? "#FFFFFF" : "#333333"
            fontSize: "medium"
        }
    }
}
