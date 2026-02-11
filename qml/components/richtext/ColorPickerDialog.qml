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
    id: colorDialog

    property bool isHighlight: false

    signal colorSelected(string color)

    title: i18n.tr("Choose Color")
    
    // Predefined color palette
    Grid {
        columns: 5
        spacing: units.gu(1)
        
        Repeater {
            model: [
                "#000000", "#333333", "#666666", "#999999", "#CCCCCC", "#FFFFFF",
                "#FF0000", "#FF6600", "#FFCC00", "#00FF00", "#0000FF", "#6600FF",
                "#CC0000", "#CC6600", "#CCCC00", "#00CC00", "#0000CC", "#6600CC",
                "#990000", "#996600", "#999900", "#009900", "#000099", "#660099", "#ce9be7"
            ]
            
            Rectangle {
                width: units.gu(5)
                height: units.gu(5)
                color: modelData
                border.width: units.dp(1)
                border.color: "#999999"
                radius: units.gu(0.5)
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        colorDialog.colorSelected(modelData)
                        PopupUtils.close(colorDialog)
                    }
                }
            }
        }
    }
    
    Button {
        text: i18n.tr("Cancel")
        onClicked: PopupUtils.close(colorDialog)
    }
}
