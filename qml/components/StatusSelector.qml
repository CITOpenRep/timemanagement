/*
 * MIT License
 *
 * Copyright (c) 2025 CIT-Services
 */

import QtQuick 2.7
import QtQuick.Controls 2.2
import Lomiri.Components 1.3

Item {
    id: root
    height: units.gu(5)
    
    property bool readOnly: false
    property string selectedStatus: ""
    
    signal statusChanged()
    
    Row {
        anchors.fill: parent
        spacing: units.gu(1)
        
        Button {
            text: i18n.dtr("ubtms", "On Track")
            width: parent.width / 3 - units.gu(0.67)
            height: parent.height
            enabled: !readOnly
            color: selectedStatus === "on_track" ? LomiriColors.green : LomiriColors.ash
            onClicked: {
                selectedStatus = "on_track";
                statusChanged();
            }
        }
        
        Button {
            text: i18n.dtr("ubtms", "At Risk")
            width: parent.width / 3 - units.gu(0.67)
            height: parent.height
            enabled: !readOnly
            color: selectedStatus === "at_risk" ? LomiriColors.orange : LomiriColors.ash
            onClicked: {
                selectedStatus = "at_risk";
                statusChanged();
            }
        }
        
        Button {
            text: i18n.dtr("ubtms", "Off Track")
            width: parent.width / 3 - units.gu(0.67)
            height: parent.height
            enabled: !readOnly
            color: selectedStatus === "off_track" ? LomiriColors.red : LomiriColors.ash
            onClicked: {
                selectedStatus = "off_track";
                statusChanged();
            }
        }
    }
}
