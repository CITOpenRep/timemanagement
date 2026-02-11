/*
 * MIT License
 *
 * Copyright (c) 2025 CIT-Services
 * 
 * DEPRECATED: This Dialog-based component has been replaced by CreateUpdatePage.qml
 * Please use CreateUpdatePage.qml instead for proper page navigation support.
 */

 // This component is deprecated , CreateUpdatePage.qml is Used instead.

import QtQuick 2.7
import QtQuick.Controls 2.2
import Lomiri.Components.Popups 1.3
import Lomiri.Components 1.3
import QtQuick.Layouts 1.3
import "../../models/accounts.js" as Accounts
import "../../models/global.js" as Global
import "../components" as Components
import "richtext"

Item {
    id: popupWrapper
    width: 0
    height: 0

    // Properties
    property int projectId: -1  // Passed in when calling open()
    property int accountId: -1
    property var parentPage: null  // Reference to parent page for navigation

    // Signals
    signal updateCreated(var updateData)

    // Status list (now only keys shown directly)
    property var projectUpdateStatus: ["on_track", "at_risk", "off_track", "on_hold"]

    Component {
        id: dialogComponent

        Dialog {
            id: createUpdateDialog
            title: i18n.dtr("ubtms", "New Project Update")
            modal: true

            property string lastKnownContent: ""

            // Monitor visibility to manage live sync with ReadMorePage
            onVisibleChanged: {
                if (visible) {
                    // Check if content was updated in ReadMorePage
                    if (Global.description_temporary_holder !== "" && 
                        Global.description_temporary_holder !== lastKnownContent) {
                        descriptionField.setContent(Global.description_temporary_holder);
                        lastKnownContent = Global.description_temporary_holder;
                    }
                    // Live sync timer is managed by descriptionField.liveSyncActive
                } else {
                    descriptionField.liveSyncActive = false;
                }
            }

            Column {
                width: parent.width
                spacing: units.gu(1)
                anchors.margins: units.gu(1)

                // Update Title
                TextField {
                    id: titleField
                    width: parent.width
                    placeholderText: i18n.dtr("ubtms", "Update Title")
                }

                // Status Selector (direct keys displayed)
                ComboBox {
                    id: statusSelector
                    width: parent.width
                    model: popupWrapper.projectUpdateStatus
                }

                // Progress Slider
                RowLayout {
                    width: parent.width
                    spacing: units.gu(1)
                    Label {
                        text: i18n.dtr("ubtms", "Progress:")
                    }
                    Slider {
                        id: progressSlider
                        Layout.fillWidth: true
                        minimumValue: 0
                        maximumValue: 100
                        value: 0
                    }
                    Label {
                        text: Math.round(progressSlider.value) + "%"
                    }
                }

                // Description
                RichTextPreview {
                    id: descriptionField
                    width: parent.width
                    height: units.gu(20)
                    title: i18n.dtr("ubtms", "Description")
                    is_read_only: false
                    useRichText: true
                    
                    onClicked: {
                        // Store current content in Global temporary holder
                        Global.description_temporary_holder = descriptionField.getFormattedText();
                        descriptionField.liveSyncActive = true;
                        
                        // Access apLayout (global AdaptivePageLayout) and add ReadMorePage
                        // apLayout is the global ID from TSApp.qml
                        if (typeof apLayout !== "undefined" && apLayout) {
                            apLayout.addPageToNextColumn(popupWrapper.parentPage || createUpdateDialog, Qt.resolvedUrl("../ReadMorePage.qml"), {
                                isReadOnly: false
                            });
                        } else {
                            console.warn("apLayout not available - cannot open ReadMorePage");
                        }
                    }
                }

                // Buttons
                RowLayout {
                    width: parent.width
                    spacing: units.gu(2)
                    Button {
                        text: i18n.dtr("ubtms", "Cancel")
                        onClicked: PopupUtils.close(createUpdateDialog)
                    }
                    Button {
                        text: "Create"
                        color: LomiriColors.orange
                        onClicked: {
                            if (titleField.text.trim() === "" || statusSelector.currentIndex < 0) {
                                notifPopup.open("Missing Fields", "Please fill all required fields.", "warning");
                                return;
                            }

                            var updateData = {
                                project_id: popupWrapper.projectId,
                                name: titleField.text.trim(),
                                project_status: popupWrapper.projectUpdateStatus[statusSelector.currentIndex],
                                progress: Math.round(progressSlider.value),
                                description: descriptionField.getFormattedText(),
                                account_id: popupWrapper.accountId,
                                user_id: Accounts.getCurrentUserOdooId(popupWrapper.accountId)
                            };
                            updateCreated(updateData);
                            PopupUtils.close(createUpdateDialog);
                        }
                    }
                }
            }
        }
    }

    // Function to open dialog and set project ID
    function open(accountIdArg, projectIdArg, parentPageArg) {
        projectId = projectIdArg;
        accountId = accountIdArg;
        parentPage = parentPageArg || null;
        
        // Clear the Global temporary holder for fresh start
        Global.description_temporary_holder = "";
        
        PopupUtils.open(dialogComponent);
    }
}
