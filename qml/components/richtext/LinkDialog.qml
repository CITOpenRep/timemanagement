/* Copyright (C) 2025 Dekko Project
   Adapted for timemanagement project

   This file is part of Dekko email client for Ubuntu devices

   This program is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation; either version 2 of
   the License or (at your option) version 3

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/
import QtQuick 2.7
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3

Dialog {
    id: linkDialog
    title: i18n.tr("Insert Link")
    
    property string linkUrl: ""
    property string linkText: ""
    
    signal linkInserted(string url, string text)
    
    Column {
        width: parent.width
        spacing: units.gu(1)
        
        TextField {
            id: urlField
            width: parent.width
            placeholderText: i18n.tr("URL (e.g., https://example.com)")
            text: linkDialog.linkUrl
            inputMethodHints: Qt.ImhUrlCharactersOnly
            focus: true
        }
        
        TextField {
            id: textField
            width: parent.width
            placeholderText: i18n.tr("Link text (optional)")
            text: linkDialog.linkText
        }
    }
    
    Button {
        text: i18n.tr("Cancel")
        onClicked: PopupUtils.close(linkDialog)
    }
    
    Button {
        text: i18n.tr("Insert")
        color: LomiriColors.green
        enabled: urlField.text.trim().length > 0
        onClicked: {
            linkDialog.linkInserted(urlField.text.trim(), textField.text.trim())
            PopupUtils.close(linkDialog)
        }
    }
}
