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
import Lomiri.Components 1.3
import "components/settings"

Page {
    id: settings
    title: i18n.dtr("ubtms", "Settings")

    header: SettingsHeader {
        id: pageHeader
        title: settings.title
    }

    SettingsPageLayout {
        headerItem: pageHeader

        // Top spacer
        Item { width: parent.width; height: units.gu(1) }


         SettingsListItem {
            iconName: "contact-group"
            iconColor: "#2980b9"
            text: i18n.dtr("ubtms", "Connected Accounts")
            onClicked: {
                apLayout.addPageToNextColumn(settings, Qt.resolvedUrl('Settings_Accounts.qml'));
            }
        }

        SettingsListItem {
            iconName: "reminder"
            iconColor: "#e67e22"
            text: i18n.dtr("ubtms", "Notification Schedule")
            onClicked: {
                apLayout.addPageToNextColumn(settings, Qt.resolvedUrl('Settings_Notifications.qml'));
            }
        }

        SettingsListItem {
            iconName: "sync-idle"
            iconColor: "#27ae60"
            text: i18n.dtr("ubtms", "Background Sync")
            onClicked: {
                apLayout.addPageToNextColumn(settings, Qt.resolvedUrl('Settings_Sync.qml'));
            }
        }

       

        SettingsListItem {
            iconName: "preferences-desktop-theme"
            iconColor: "#8e44ad"
            text: i18n.dtr("ubtms", "Theme Settings")
            showDivider: false
            onClicked: {
                apLayout.addPageToNextColumn(settings, Qt.resolvedUrl('Settings_Theme.qml'));
            }
        }

        // Bottom spacer
        Item { width: parent.width; height: units.gu(1) }
    }
}
