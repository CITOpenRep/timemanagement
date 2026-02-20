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
    id: sizeDialog
    title: i18n.tr("Font Size")
 
    signal sizeSelected(string size)
    
    Column {
        spacing: units.gu(0.5)
        
        Repeater {
            model: [
                { label: "8pt", value: "8pt" },
                { label: "9pt", value: "9pt" },
                { label: "10pt", value: "10pt" },
                { label: "11pt", value: "11pt" },
                { label: "12pt", value: "12pt" },
                { label: "14pt", value: "14pt" },
                { label: "16pt", value: "16pt" },
                { label: "18pt", value: "18pt" },
                { label: "20pt", value: "20pt" },
                { label: "24pt", value: "24pt" },
                { label: "36pt", value: "36pt" },
                { label: "48pt", value: "48pt" }
            ]
            
            AbstractButton {
                width: parent.width
                height: units.gu(4)
                
                Rectangle {
                    anchors.fill: parent
                    color: parent.pressed ? "#E0E0E0" : "transparent"
                }
                
                Label {
                    anchors.centerIn: parent
                    text: modelData.label
                    fontSize: "medium"
                }
                
                onClicked: {
                    sizeDialog.sizeSelected(modelData.value)
                    PopupUtils.close(sizeDialog)
                }
            }
        }
    }
    
    Button {
        text: i18n.tr("Cancel")
        onClicked: PopupUtils.close(sizeDialog)
    }
}
