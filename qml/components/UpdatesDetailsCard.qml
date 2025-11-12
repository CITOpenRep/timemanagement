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
                    height: units.gu(3)
                    width: details_button.width
                    color: status === "on_track" ? "green" : status === "at_risk" ? "orange" : status === "off_track" ? "red" : "grey"
                    //Layout.preferredWidth: statusText.paintedWidth + units.gu(4)
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
                    Layout.preferredWidth: units.gu(14)
                    height: units.gu(5)
                    onClicked: updateItem.showDescription("<h1>" + name + "</h1>" + description)
                }
            }

            // Project Name
            Text {
                text: Utils.truncateText(Project.getProjectName(project_id, account_id), 40) || i18n.dtr("ubtms", "Unknown Project")
                font.pixelSize: units.gu(AppConst.FontSizes.ListSubHeading)
                color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "White" : "#666"
                elide: Text.ElideRight
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
