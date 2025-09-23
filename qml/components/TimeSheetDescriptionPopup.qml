/*
 * MIT License
 *
 * Copyright (c) 2025 CIT-Services
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

import QtQuick 2.7
import QtQuick.Controls 2.2
import Lomiri.Components.Popups 1.3
import Lomiri.Components 1.3
import "../../models/timesheet.js" as Model
import "../../models/utils.js" as Utils

Item {
    id: popupWrapper
    width: 0
    height: 0

    // Public properties
    property int timesheetId: 0
    property string timesheetName: ""
    property string elapsedTime: ""

    // Signals
    signal saved(string description, string status)
    signal cancelled

    Component {
        id: dialogComponent

        Dialog {
            id: popupDialog
            title: "Add Description to Timesheet"

            // Dark mode friendly styling
            StyleHints {
                backgroundColor: theme.palette.normal.background
                foregroundColor: theme.palette.normal.backgroundText
            }

            // Content
            Column {
                width: units.gu(50)
                spacing: units.gu(2)

                // Show elapsed time
                Row {
                    spacing: units.gu(1)
                    Label {
                        text: "Time Recorded:"
                        font.bold: true
                    }
                    Label {
                        text: popupWrapper.elapsedTime
                        color: LomiriColors.orange
                        font.bold: true
                    }
                }

                // Description label
                Label {
                    text: "Description/Notes:"
                    font.bold: true
                }

                // Description text area
                ScrollView {
                    width: parent.width
                    height: units.gu(15)

                    TextArea {
                        id: descriptionText
                        placeholderText: "Enter a description for this timesheet entry..."
                        text: popupWrapper.timesheetName
                        wrapMode: TextArea.Wrap
                        selectByMouse: true

                        // Style for better visibility
                        color: theme.palette.normal.backgroundText

                        Component.onCompleted: {
                            // Focus and select all text for easy editing
                            forceActiveFocus();
                            selectAll();
                        }
                    }
                }

                // Help text
                Label {
                    text: "• Save: Keeps timesheet as draft for later editing\n• Finalize: Marks timesheet as ready for sync"
                    color: theme.palette.normal.backgroundText
                    opacity: 0.7
                    font.pixelSize: units.gu(1.8)
                    wrapMode: Text.WordWrap
                    width: parent.width
                }
            }

            // Buttons
            Button {
                id: saveButton
                text: "Save as Draft"
                color: LomiriColors.blue
                onClicked: {
                    var description = descriptionText.text.trim();
                    var result = updateTimesheetDescription(description, "draft");
                    if (result.success) {
                        popupWrapper.saved(description, "draft");
                        PopupUtils.close(popupDialog);
                    } else {
                        console.error("Failed to save timesheet:", result.error);
                        // Could show an error notification here
                    }
                }
            }

            Button {
                id: finalizeButton
                text: "Finalize"
                color: LomiriColors.green
                onClicked: {
                    var description = descriptionText.text.trim();
                    var result = updateTimesheetDescription(description, "updated");
                    if (result.success) {
                        popupWrapper.saved(description, "updated");
                        PopupUtils.close(popupDialog);
                    } else {
                        console.error("Failed to finalize timesheet:", result.error);
                        // Could show an error notification here
                    }
                }
            }

            Button {
                text: "Cancel"
                color: LomiriColors.warmGrey
                onClicked: {
                    popupWrapper.cancelled();
                    PopupUtils.close(popupDialog);
                }
            }
        }
    }

    // Function to update timesheet description and status
    function updateTimesheetDescription(description, status) {
        if (!popupWrapper.timesheetId || popupWrapper.timesheetId <= 0) {
            return {
                success: false,
                error: "Invalid timesheet ID"
            };
        }

        try {
            // Get current timesheet details (without account filter for now)
            var currentDetails = Model.getTimeSheetDetails(popupWrapper.timesheetId);

            if (!currentDetails || !currentDetails.instance_id) {
                return {
                    success: false,
                    error: "Could not retrieve timesheet details"
                };
            }

            // Update the timesheet with new description
            var timesheet_data = {
                'id': popupWrapper.timesheetId,
                'instance_id': currentDetails.instance_id,
                'record_date': currentDetails.record_date,
                'project': currentDetails.project_id,
                'task': currentDetails.task_id,
                'subprojectId': currentDetails.sub_project_id,
                'subTask': currentDetails.sub_task_id,
                'description': description || currentDetails.name,
                'unit_amount': Utils.convertHHMMtoDecimalHours(popupWrapper.elapsedTime),
                'quadrant': currentDetails.quadrant_id || 1,
                'status': status,
                'user_id': currentDetails.user_id
            };

            // Use the appropriate function based on status
            if (status === "updated") {
                // First save the description, then mark as ready
                var saveResult = Model.saveTimesheet(timesheet_data);
                if (saveResult.success) {
                    return Model.markTimesheetAsReadyById(popupWrapper.timesheetId);
                } else {
                    return saveResult;
                }
            } else {
                // For draft status, just save
                var result = Model.saveTimesheet(timesheet_data);
                return result;
            }
        } catch (e) {
            console.error("Error updating timesheet description:", e);
            return {
                success: false,
                error: e.toString()
            };
        }
    }

    // Public function to open the popup
    function open(timesheetId, timesheetName, elapsedTime) {
        popupWrapper.timesheetId = timesheetId || 0;
        popupWrapper.timesheetName = timesheetName || "";
        popupWrapper.elapsedTime = elapsedTime || "00:00";

        PopupUtils.open(dialogComponent);
    }
}
