/*
 * MIT License
 *
 * Copyright (c) 2025 CIT-Services
 */

import QtQuick 2.12
import QtQuick.Controls 2.2
import Lomiri.Components 1.3
import QtQuick.Layouts 1.1
import "../../models/utils.js" as Utils
import "../../models/constants.js" as AppConst
import "../../models/project.js" as Project
import "../../models/accounts.js" as Accounts

ListItem {
    id: updateItem
    clip: true

    property string name: ""
    property string project_id: ""
    property string status: ""
    property int progress: 0
    property string description: ""
    property string user: ""
    property string date: ""
    property int recordId: -1
    property int account_id: 0
    property int colorPallet: 0
    property bool hasDraft: false // Indicates if this task has unsaved draft changes
    signal showDescription(string description)
    signal editRequested(int accountId, int recordId)
    signal viewRequested(int accountId, int recordId)
    signal deleteRequested(int recordId)

    height: contentLayout.implicitHeight + units.gu(1)

    leadingActions: ListItemActions {
        actions: [
            Action {
                iconName: "delete"
                onTriggered: deleteRequested(recordId)
            }
        ]
    }

    trailingActions: ListItemActions {
        actions: [
            Action {
                iconName: "edit"
                text: i18n.dtr("ubtms", "Edit")
                onTriggered: editRequested(account_id, recordId)
            }
            // View action disabled for now as Click Action is There , in Project Updates we do not Follow Parent Child Hierarchy
            // Action {
            //     iconName: "info"
            //     text: i18n.dtr("ubtms", "View")
            //     onTriggered: viewRequested(account_id, recordId)
            // }
        ]
    }

    onClicked: {
        viewRequested(account_id, recordId)
    }

    ListItemLayout {
        anchors.fill: parent
        //anchors.leftMargin: units.gu(2)
        anchors.rightMargin: units.gu(3)

        ColumnLayout {
            id: contentLayout
            width: parent.width

            // Title + Status Badge
            RowLayout {
                width: parent.width

                Text {
                    Layout.fillWidth: true
                    text: (name && name.trim() !== "") ? Utils.truncateText(name, 35) : i18n.dtr("ubtms", "Untitled Update")
                    font.pixelSize: units.gu(AppConst.FontSizes.ListHeading)
                    elide: Text.ElideRight
                    color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "White" : "#222"
                  
                }

                Rectangle {
                    height: units.gu(3.5)
                    width: details_button.width 
                    
                
                    color: status === "on_track" ? "#52b788" : status === "at_risk" ? '#e98b49' : status === "off_track" ? '#d65d5d' : "grey"
                    radius: units.gu(0.8)
                    Layout.alignment: Qt.AlignRight

                    Text {
                        id: statusText
                        text: status
                        anchors.centerIn: parent
                        font.pixelSize: units.gu(AppConst.FontSizes.ListHeading)
                        color: "white"
                    }
                }
            }

            // User + Date + Details Button
            RowLayout {
                width: parent.width
                //spacing: units.gu(1)

                Text {
                    Layout.fillWidth: true
                    text: i18n.dtr("ubtms", "By: ") + (user ? Accounts.getUserNameByOdooId(user, account_id) : i18n.dtr("ubtms", "Unknown User")) + " | " + (date ? date : i18n.dtr("ubtms", "No Date"))
                    font.pixelSize: units.gu(AppConst.FontSizes.ListSubHeading)
                    color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "White" : "#666"
                    elide: Text.ElideRight
                }

                TSButton {
                    id: details_button
                    text: i18n.dtr("ubtms", "Details")
                    Layout.preferredWidth: units.gu(12)
                    height: units.gu(4)
                    // borderColor: "#f97316"
                      bgColor: "#fef1e7"
                fgColor: "#f97316"
                hoverColor: '#f3e0d1'
                    onClicked: updateItem.showDescription("<h1>" + name + "</h1>" + description)
                }
            }
            

            RowLayout {
                width: parent.width
          
            // Project Name
            Text {
                text: Utils.truncateText(Project.getProjectName(project_id, account_id), 40) || i18n.dtr("ubtms", "Unknown Project")
                font.pixelSize: units.gu(AppConst.FontSizes.ListSubHeading)
                color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "White" : "#666"
                elide: Text.ElideRight
            }

           Rectangle {
    id: draftIndicator
    visible: hasDraft
    width: draftLabel.width + units.gu(1.2)
    height: units.gu(2)
    radius: height / 2
    color: "#FFF3E0"
    border.color: "#FF9800"
    border.width: units.gu(0.15)
    Layout.alignment: Qt.AlignRight

    
    Text {
        id: draftLabel
        text: i18n.dtr("ubtms", "DRAFT")
        font.pixelSize: units.gu(1.1)
        font.bold: true
        color: "#F57C00"
        anchors.centerIn: parent
    }
}

            }
  

            // Progress Bar
            ProgressBar {
                Layout.fillWidth: true
                height: units.gu(3)
                value: progress
                minimumValue: 0
                maximumValue: 100
            }
        }
    }
}
