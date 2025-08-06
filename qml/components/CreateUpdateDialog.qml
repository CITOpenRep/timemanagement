/*
 * MIT License
 *
 * Copyright (c) 2025 CIT-Services
 */

import QtQuick 2.7
import QtQuick.Controls 2.2
import Lomiri.Components.Popups 1.3
import Lomiri.Components 1.3
import QtQuick.Layouts 1.3
import "../../models/accounts.js" as Accounts

Item {
    id: popupWrapper
    width: 0
    height: 0

    // Properties
    property int projectId: -1  // Passed in when calling open()
    property int accountId: -1

    // Signals
    signal updateCreated(var updateData)

    // Status list (now only keys shown directly)
    property var projectUpdateStatus: ["on_track", "at_risk", "off_track", "on_hold"]

    Component {
        id: dialogComponent

        Dialog {
            id: createUpdateDialog
            title: "New Project Update"
            modal: true

            Column {
                width: parent.width
                spacing: units.gu(1)
                anchors.margins: units.gu(1)

                // Update Title
                TextField {
                    id: titleField
                    width: parent.width
                    placeholderText: "Update Title"
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
                        text: "Progress:"
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
                TextArea {
                    id: descriptionField
                    width: parent.width
                    height: units.gu(8)
                    placeholderText: "Write your update description..."
                    wrapMode: TextEdit.Wrap
                }

                // Buttons
                RowLayout {
                    width: parent.width
                    spacing: units.gu(2)
                    Button {
                        text: "Cancel"
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
                                description: descriptionField.text.trim(),
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
    function open(accountIdArg, projectIdArg) {
        projectId = projectIdArg;
        accountId = accountIdArg;
        PopupUtils.open(dialogComponent);
    }
}
