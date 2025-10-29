/*
 * MIT License
 *
 * Copyright (c) 2025 CIT-Services
 */

import QtQuick 2.7
import QtQuick.Controls 2.2
import Lomiri.Components 1.3
import QtQuick.Layouts 1.3
import "../../models/accounts.js" as Accounts
import "../../models/global.js" as Global

Page {
    id: createUpdatePage
    title: i18n.dtr("ubtms", "New Project Update")

    // Properties
    property int projectId: -1
    property int accountId: -1
    property string lastKnownContent: ""
    property bool isInitialLoad: true

    // Status list
    property var projectUpdateStatus: ["on_track", "at_risk", "off_track", "on_hold"]

    header: PageHeader {
        title: createUpdatePage.title
        StyleHints {
            foregroundColor: "white"
            backgroundColor: LomiriColors.orange
            dividerColor: LomiriColors.slate
        }

        trailingActionBar.actions: [
            Action {
                iconName: "tick"
                text: "Create"
                onTriggered: {
                    if (titleField.text.trim() === "" || statusSelector.currentIndex < 0) {
                        return;
                    }

                    var updateData = {
                        project_id: createUpdatePage.projectId,
                        name: titleField.text.trim(),
                        project_status: createUpdatePage.projectUpdateStatus[statusSelector.currentIndex],
                        progress: Math.round(progressSlider.value),
                        description: descriptionField.getFormattedText(),
                        account_id: createUpdatePage.accountId,
                        user_id: Accounts.getCurrentUserOdooId(createUpdatePage.accountId)
                    };
                    
                    // Call global callback
                    if (Global.createUpdateCallback && typeof Global.createUpdateCallback === "function") {
                        Global.createUpdateCallback(updateData);
                    }
                    
                    // Clear temporary holder and go back
                    Global.description_temporary_holder = "";
                    pageStack.removePages(createUpdatePage);
                }
            }
        ]
    }

    // Monitor visibility to reload content from Global when returning from ReadMorePage
    onVisibleChanged: {
        if (visible) {
            // Skip loading on initial visibility (let Component.onCompleted handle it)
            if (isInitialLoad) {
                isInitialLoad = false;
                contentUpdateTimer.start();
                return;
            }
            
            // Check if content was updated in ReadMorePage
            if (Global.description_temporary_holder !== "" && 
                Global.description_temporary_holder !== lastKnownContent) {
                descriptionField.setContent(Global.description_temporary_holder);
                lastKnownContent = Global.description_temporary_holder;
            }
            contentUpdateTimer.start();
        } else {
            contentUpdateTimer.stop();
        }
    }

    // Timer to periodically check for content updates from ReadMorePage
    Timer {
        id: contentUpdateTimer
        interval: 500  // Check every 500ms
        repeat: true
        running: false
        onTriggered: {
            if (Global.description_temporary_holder !== "" && 
                Global.description_temporary_holder !== createUpdatePage.lastKnownContent) {
                descriptionField.setContent(Global.description_temporary_holder);
                createUpdatePage.lastKnownContent = Global.description_temporary_holder;
            }
        }
    }

    Flickable {
        anchors.fill: parent
        anchors.topMargin: units.gu(6)
        contentHeight: contentColumn.height + units.gu(4)
        flickableDirection: Flickable.VerticalFlick

        Column {
            id: contentColumn
            width: parent.width
            spacing: units.gu(1)
            anchors.margins: units.gu(2)
            anchors.left: parent.left
            anchors.right: parent.right
            topPadding: units.gu(2)
            leftPadding: units.gu(1)
            rightPadding: units.gu(2)

            // Update Title
            Label {
                text: i18n.dtr("ubtms", "Update Title")
                font.bold: true
            }

            TextField {
                id: titleField
                width: parent.width - units.gu(2)
                placeholderText: i18n.dtr("ubtms", "Enter update title...")

                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    radius: units.gu(0.5)
                    border.width: parent.activeFocus ? units.gu(0.2) : units.gu(0.1)
                    border.color: parent.activeFocus ? LomiriColors.orange : (theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#d3d1d1" : "#999")
                  //  z: -1
                }
            }

            // Status Selector
            Item { height: units.gu(1); width: 1 } // Spacer
            
            Label {
                text: i18n.dtr("ubtms", "Project Status")
                font.bold: true
            }

            ComboBox {
                id: statusSelector
                width: parent.width - units.gu(2)
                model: createUpdatePage.projectUpdateStatus
                currentIndex: 0
            }

            // Progress Slider
            Item { height: units.gu(1); width: 1 } // Spacer
            
            Label {
                text: i18n.dtr("ubtms", "Progress")
                font.bold: true
            }

            RowLayout {
                width: parent.width - units.gu(2)
                spacing: units.gu(2)

                Slider {
                    id: progressSlider
                    Layout.fillWidth: true
                    minimumValue: 0
                    maximumValue: 100
                    value: 0
                }
                Label {
                    text: Math.round(progressSlider.value) + "%"
                    font.bold: true
                    font.pixelSize: units.gu(2)
                    Layout.minimumWidth: units.gu(8)
                }
            }

            // Description
            Item { height: units.gu(1); width: 1 } // Spacer
            
            Label {
                text: i18n.dtr("ubtms", "Description")
                font.bold: true
            }

            RichTextPreview {
                id: descriptionField
                width: parent.width - units.gu(1)
                height: units.gu(20)
                title: ""  // No title since we have a label above
                is_read_only: false
                useRichText: true
                
                onClicked: {
                    Global.description_temporary_holder = descriptionField.getFormattedText();
                    
                    if (typeof apLayout !== "undefined" && apLayout) {
                        apLayout.addPageToNextColumn(createUpdatePage, Qt.resolvedUrl("../ReadMorePage.qml"), {
                            isReadOnly: false
                        });
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        // Clear form fields when page loads
        Global.description_temporary_holder = "";
        lastKnownContent = "";
        descriptionField.setContent("");
        titleField.text = "";
        statusSelector.currentIndex = 0;
        progressSlider.value = 0;
    }
}
