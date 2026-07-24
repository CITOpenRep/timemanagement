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
    
    Flickable {
        width: parent.width
        height: Math.min(units.gu(40), sizeColumn.implicitHeight)
        contentHeight: sizeColumn.implicitHeight
        clip: true
        
        Column {
            id: sizeColumn
            width: parent.width
            spacing: units.gu(0.5)
            
            Repeater {
                model: [
                    { label: "8px", value: "8px" },
                    { label: "9px", value: "9px" },
                    { label: "10px", value: "10px" },
                    { label: "11px", value: "11px" },
                    { label: "12px", value: "12px" },
                    { label: "13px", value: "13px" },
                    { label: "14px", value: "14px" },
                    { label: "16px", value: "16px" },
                    { label: "18px", value: "18px" },
                    { label: "20px", value: "20px" },
                    { label: "24px", value: "24px" },
                    { label: "28px", value: "28px" },
                    { label: "32px", value: "32px" },
                    { label: "36px", value: "36px" },
                    { label: "48px", value: "48px" },
                    { label: "56px", value: "56px" },
                    { label: "64px", value: "64px" },
                    { label: "72px", value: "72px" },
                    { label: "80px", value: "80px" },
                    { label: "96px", value: "96px" }
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
    }
    
    Button {
        text: i18n.tr("Cancel")
        onClicked: PopupUtils.close(sizeDialog)
    }
}
