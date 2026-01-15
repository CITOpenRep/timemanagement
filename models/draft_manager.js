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

/**
 * Form Draft Management System
 * 
 * Provides auto-save, crash recovery, and unsaved changes tracking for forms.
 * Prevents data loss from crashes and provides seamless user experience.
 */

.import QtQuick.LocalStorage 2.7 as Sql
.import "database.js" as DBCommon
.import "utils.js" as Utils

/**
 * Saves current form state as a draft
 * @param {Object} params - Parameters object
 * @param {string} params.draftType - Type of form (task, timesheet, project, activity)
 * @param {number} params.recordId - ID of record being edited (null for new records)
 * @param {number} params.accountId - Account ID
 * @param {Object} params.formData - Current form data as object
 * @param {Object} params.originalData - Original data on load (for comparison)
 * @param {string} params.pageIdentifier - Unique page identifier (optional)
 * @returns {Object} {success: boolean, draftId: number, hasChanges: boolean, changedFields: array, error: string}
 */
function saveDraft(params) {
    var draftType = params.draftType;
    var recordId = params.recordId || null;
    var accountId = params.accountId || 0;
    var formData = params.formData || {};
    var originalData = params.originalData || {};
    var pageIdentifier = params.pageIdentifier || "default";
    
    var result = {
        success: false,
        draftId: null,
        hasChanges: false,
        changedFields: [],
        error: ""
    };
    
    // Validate required parameters
    if (!draftType) {
        result.error = "draftType is required";
        console.error("❌ Draft save failed:", result.error);
        return result;
    }
    
    try {
        // Calculate changed fields
        var changedFields = getChangedFields(formData, originalData);
        result.changedFields = changedFields;
        result.hasChanges = changedFields.length > 0;
        
        // Don't save if no changes
        if (!result.hasChanges) {
           // console.log("📝 No changes detected, skipping draft save");
            result.success = true;
            return result;
        }
        
        var db = Sql.LocalStorage.openDatabaseSync(
            DBCommon.NAME,
            DBCommon.VERSION,
            DBCommon.DISPLAY_NAME,
            DBCommon.SIZE
        );
        
        var timestamp = Utils.getFormattedTimestampUTC();
        var isNewRecord = (recordId === null || recordId === 0 || recordId === undefined) ? 1 : 0;
        
        db.transaction(function(tx) {
            // Check if draft already exists
            var checkQuery = "SELECT id FROM form_drafts WHERE draft_type = ? AND account_id = ? AND page_identifier = ?";
            var checkParams = [draftType, accountId, pageIdentifier];
            
            if (!isNewRecord) {
                checkQuery += " AND record_id = ?";
                checkParams.push(recordId);
            } else {
                checkQuery += " AND is_new_record = 1";
            }
            
            var existingDraft = tx.executeSql(checkQuery, checkParams);
            
            var formDataJson = JSON.stringify(formData);
            var originalDataJson = JSON.stringify(originalData);
            var changedFieldsJson = JSON.stringify(changedFields);
            
            if (existingDraft.rows.length > 0) {
                // Update existing draft
                result.draftId = existingDraft.rows.item(0).id;
                
                tx.executeSql(
                    "UPDATE form_drafts SET " +
                    "draft_data = ?, " +
                    "original_data = ?, " +
                    "updated_at = ?, " +
                    "field_changes = ? " +
                    "WHERE id = ?",
                    [formDataJson, originalDataJson, timestamp, changedFieldsJson, result.draftId]
                );
                
                console.log("🔄 Updated draft #" + result.draftId + " for " + draftType + " (" + changedFields.length + " changes)");
            } else {
                // Insert new draft
                var insertResult = tx.executeSql(
                    "INSERT INTO form_drafts " +
                    "(draft_type, record_id, account_id, draft_data, original_data, created_at, updated_at, field_changes, is_new_record, page_identifier) " +
                    "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                    [draftType, recordId, accountId, formDataJson, originalDataJson, timestamp, timestamp, changedFieldsJson, isNewRecord, pageIdentifier]
                );
                
                result.draftId = insertResult.insertId;
                console.log("💾 Created draft #" + result.draftId + " for " + draftType + " (" + changedFields.length + " changes)");
            }
            
            // Set has_draft flag on parent record (if not a new record)
            if (recordId && recordId > 0) {
                var tableName = null;
                if (draftType === "task") {
                    tableName = "project_task_app";
                } else if (draftType === "project") {
                    tableName = "project_project_app";
                } else if (draftType === "timesheet") {
                    tableName = "account_analytic_line_app";
                } else if (draftType === "project_update") {
                    tableName = "project_update_app";
                } else if (draftType === "activity") {
                    tableName = "mail_activity_app";
                }
                
                if (tableName) {
                    tx.executeSql(
                        "UPDATE " + tableName + " SET has_draft = 1 WHERE id = ?",
                        [recordId]
                    );
                    console.log("✅ Set has_draft=1 for " + draftType + " #" + recordId);
                }
            }
        });
        
        result.success = true;
        
    } catch (e) {
        result.error = e.toString();
        console.error("❌ Error saving draft:", result.error);
        DBCommon.logException("saveDraft", e);
    }
    
    return result;
}

/**
 * Loads an existing draft for a form
 * @param {Object} params - Parameters object
 * @param {string} params.draftType - Type of form
 * @param {number} params.recordId - ID of record (null for new records)
 * @param {number} params.accountId - Account ID
 * @param {string} params.pageIdentifier - Unique page identifier (optional)
 * @returns {Object} {success: boolean, draft: object, message: string}
 */
function loadDraft(params) {
    var draftType = params.draftType;
    var recordId = params.recordId || null;
    var accountId = params.accountId || 0;
    var pageIdentifier = params.pageIdentifier || "default";
    
    var result = {
        success: false,
        draft: null,
        message: ""
    };
    
    if (!draftType) {
        result.message = "draftType is required";
        console.error("❌ Draft load failed:", result.message);
        return result;
    }
    
    try {
        var db = Sql.LocalStorage.openDatabaseSync(
            DBCommon.NAME,
            DBCommon.VERSION,
            DBCommon.DISPLAY_NAME,
            DBCommon.SIZE
        );
        
        db.transaction(function(tx) {
            var query = "SELECT * FROM form_drafts WHERE draft_type = ? AND account_id = ? AND page_identifier = ?";
            var queryParams = [draftType, accountId, pageIdentifier];
            
            if (recordId !== null && recordId !== 0 && recordId !== undefined) {
                query += " AND record_id = ?";
                queryParams.push(recordId);
            } else {
                query += " AND is_new_record = 1";
            }
            
            query += " ORDER BY updated_at DESC LIMIT 1";
            
            var queryResult = tx.executeSql(query, queryParams);
            
            if (queryResult.rows.length > 0) {
                var row = queryResult.rows.item(0);
                
                result.draft = {
                    id: row.id,
                    draftType: row.draft_type,
                    recordId: row.record_id,
                    accountId: row.account_id,
                    formData: JSON.parse(row.draft_data),
                    originalData: row.original_data ? JSON.parse(row.original_data) : {},
                    createdAt: row.created_at,
                    updatedAt: row.updated_at,
                    changedFields: row.field_changes ? JSON.parse(row.field_changes) : [],
                    isNewRecord: row.is_new_record === 1,
                    pageIdentifier: row.page_identifier
                };
                
                result.success = true;
                result.message = "Draft loaded successfully";
                console.log("📂 Loaded draft #" + result.draft.id + " for " + draftType);
            } else {
                result.message = "No draft found";
                console.log("📭 No draft found for " + draftType);
            }
        });
        
    } catch (e) {
        result.message = e.toString();
        console.error("❌ Error loading draft:", result.message);
        DBCommon.logException("loadDraft", e);
    }
    
    return result;
}

/**
 * Deletes a draft by ID (typically after successful save)
 * @param {number} draftId - Draft ID to delete
 * @returns {Object} {success: boolean, message: string}
 */
function deleteDraft(draftId) {
    var result = {
        success: false,
        message: ""
    };
    
    if (!draftId || draftId <= 0) {
        result.message = "Invalid draftId";
        return result;
    }
    
    try {
        var db = Sql.LocalStorage.openDatabaseSync(
            DBCommon.NAME,
            DBCommon.VERSION,
            DBCommon.DISPLAY_NAME,
            DBCommon.SIZE
        );
        
        db.transaction(function(tx) {
            // Get draft info before deleting
            var draftInfo = tx.executeSql(
                "SELECT draft_type, record_id FROM form_drafts WHERE id = ?",
                [draftId]
            );
            
            // Delete the draft
            tx.executeSql("DELETE FROM form_drafts WHERE id = ?", [draftId]);
            
            // Clear has_draft flag on parent record
            if (draftInfo.rows.length > 0) {
                var row = draftInfo.rows.item(0);
                var recordId = row.record_id;
                var draftType = row.draft_type;
                
                if (recordId && recordId > 0) {
                    var tableName = null;
                    if (draftType === "task") {
                        tableName = "project_task_app";
                    } else if (draftType === "project") {
                        tableName = "project_project_app";
                    } else if (draftType === "timesheet") {
                        tableName = "account_analytic_line_app";
                    } else if (draftType === "project_update") {
                        tableName = "project_update_app";
                    } else if (draftType === "activity") {
                        tableName = "mail_activity_app";
                    }
                    
                    if (tableName) {
                        tx.executeSql(
                            "UPDATE " + tableName + " SET has_draft = 0 WHERE id = ?",
                            [recordId]
                        );
                        console.log("✅ Cleared has_draft=0 for " + draftType + " #" + recordId);
                    }
                }
            }
        });
        
        result.success = true;
        result.message = "Draft deleted successfully";
        console.log("🗑️ Deleted draft #" + draftId);
        
    } catch (e) {
        result.message = e.toString();
        console.error("❌ Error deleting draft:", result.message);
        DBCommon.logException("deleteDraft", e);
    }
    
    return result;
}

/**
 * Deletes all drafts matching criteria
 * @param {Object} params - Parameters object
 * @param {string} params.draftType - Type of form (optional)
 * @param {number} params.recordId - Record ID (optional)
 * @param {number} params.accountId - Account ID (optional)
 * @param {string} params.pageIdentifier - Page identifier (optional)
 * @returns {Object} {success: boolean, deletedCount: number, message: string}
 */
function deleteDrafts(params) {
    params = params || {};
    var result = {
        success: false,
        deletedCount: 0,
        message: ""
    };
    
    try {
        var db = Sql.LocalStorage.openDatabaseSync(
            DBCommon.NAME,
            DBCommon.VERSION,
            DBCommon.DISPLAY_NAME,
            DBCommon.SIZE
        );
        
        db.transaction(function(tx) {
            var query = "DELETE FROM form_drafts WHERE 1=1";
            var queryParams = [];
            
            if (params.draftType) {
                query += " AND draft_type = ?";
                queryParams.push(params.draftType);
            }
            
            if (params.recordId !== undefined && params.recordId !== null) {
                query += " AND record_id = ?";
                queryParams.push(params.recordId);
            }
            
            if (params.accountId !== undefined) {
                query += " AND account_id = ?";
                queryParams.push(params.accountId);
            }
            
            if (params.pageIdentifier) {
                query += " AND page_identifier = ?";
                queryParams.push(params.pageIdentifier);
            }
            
            // First, get the drafts we're about to delete so we can clear their has_draft flags
            var selectQuery = "SELECT draft_type, record_id FROM form_drafts WHERE 1=1";
            var selectParams = [];
            
            if (params.draftType) {
                selectQuery += " AND draft_type = ?";
                selectParams.push(params.draftType);
            }
            
            if (params.recordId !== undefined && params.recordId !== null) {
                selectQuery += " AND record_id = ?";
                selectParams.push(params.recordId);
            }
            
            if (params.accountId !== undefined) {
                selectQuery += " AND account_id = ?";
                selectParams.push(params.accountId);
            }
            
            if (params.pageIdentifier) {
                selectQuery += " AND page_identifier = ?";
                selectParams.push(params.pageIdentifier);
            }
            
            var draftsToDelete = tx.executeSql(selectQuery, selectParams);
            
            // Clear has_draft flags for affected records
            for (var i = 0; i < draftsToDelete.rows.length; i++) {
                var draft = draftsToDelete.rows.item(i);
                var recordId = draft.record_id;
                var draftType = draft.draft_type;
                
                if (recordId && recordId > 0) {
                    var tableName = null;
                    if (draftType === "task") {
                        tableName = "project_task_app";
                    } else if (draftType === "project") {
                        tableName = "project_project_app";
                    } else if (draftType === "timesheet") {
                        tableName = "account_analytic_line_app";
                    } else if (draftType === "project_update") {
                        tableName = "project_update_app";
                    } else if (draftType === "activity") {
                        tableName = "mail_activity_app";
                    }
                    
                    if (tableName) {
                        tx.executeSql(
                            "UPDATE " + tableName + " SET has_draft = 0 WHERE id = ?",
                            [recordId]
                        );
                    }
                }
            }
            
            // Now delete the drafts
            var deleteResult = tx.executeSql(query, queryParams);
            result.deletedCount = deleteResult.rowsAffected;
            
            if (result.deletedCount > 0) {
                console.log("✅ Cleared has_draft=0 for " + result.deletedCount + " record(s)");
            }
        });
        
        result.success = true;
        result.message = "Deleted " + result.deletedCount + " draft(s)";
        console.log("🗑️ " + result.message);
        
    } catch (e) {
        result.message = e.toString();
        console.error("❌ Error deleting drafts:", result.message);
        DBCommon.logException("deleteDrafts", e);
    }
    
    return result;
}

/**
 * Compares two data objects and returns list of changed field names
 * @param {Object} currentData - Current form data
 * @param {Object} originalData - Original data on load
 * @returns {Array} Array of changed field names
 */
function getChangedFields(currentData, originalData) {
    var changedFields = [];
    
    if (!currentData || !originalData) {
        return changedFields;
    }
    
    try {
        // Check all fields in current data
        for (var key in currentData) {
            if (currentData.hasOwnProperty(key)) {
                var currentValue = currentData[key];
                var originalValue = originalData[key];
                
                // Compare values
                if (!valuesAreEqual(currentValue, originalValue)) {
                    changedFields.push(key);
                }
            }
        }
        
        // Check for removed fields (in original but not in current)
        for (var key in originalData) {
            if (originalData.hasOwnProperty(key) && !currentData.hasOwnProperty(key)) {
                changedFields.push(key);
            }
        }
        
    } catch (e) {
        console.error("❌ Error comparing fields:", e.toString());
    }
    
    return changedFields;
}

/**
 * Helper function to compare two values for equality
 * @param {*} val1 - First value
 * @param {*} val2 - Second value
 * @returns {boolean} True if values are equal
 */
function valuesAreEqual(val1, val2) {
    // Handle null/undefined
    if (val1 === val2) return true;
    if (val1 == null && val2 == null) return true;
    if (val1 == null || val2 == null) return false;
    
    // Handle different types
    if (typeof val1 !== typeof val2) return false;
    
    // Handle arrays
    if (Array.isArray(val1) && Array.isArray(val2)) {
        if (val1.length !== val2.length) return false;
        for (var i = 0; i < val1.length; i++) {
            if (!valuesAreEqual(val1[i], val2[i])) return false;
        }
        return true;
    }
    
    // Handle objects
    if (typeof val1 === 'object' && typeof val2 === 'object') {
        var keys1 = Object.keys(val1);
        var keys2 = Object.keys(val2);
        if (keys1.length !== keys2.length) return false;
        for (var i = 0; i < keys1.length; i++) {
            var key = keys1[i];
            if (!valuesAreEqual(val1[key], val2[key])) return false;
        }
        return true;
    }
    
    // Handle primitive values
    return val1 === val2;
}

/**
 * Checks if there are unsaved changes
 * @param {Object} currentData - Current form data
 * @param {Object} originalData - Original data on load
 * @returns {boolean} True if there are unsaved changes
 */
function hasUnsavedChanges(currentData, originalData) {
    var changedFields = getChangedFields(currentData, originalData);
    return changedFields.length > 0;
}

/**
 * Gets all drafts for a specific account (used for crash recovery)
 * @param {number} accountId - Account ID (-1 for all accounts)
 * @returns {Array} Array of draft objects
 */
function getAllDrafts(accountId) {
    var draftList = [];
    
    try {
        var db = Sql.LocalStorage.openDatabaseSync(
            DBCommon.NAME,
            DBCommon.VERSION,
            DBCommon.DISPLAY_NAME,
            DBCommon.SIZE
        );
        
        db.transaction(function(tx) {
            var query = "SELECT * FROM form_drafts";
            var queryParams = [];
            
            if (accountId !== undefined && accountId !== -1) {
                query += " WHERE account_id = ?";
                queryParams.push(accountId);
            }
            
            query += " ORDER BY updated_at DESC";
            
            var queryResult = tx.executeSql(query, queryParams);
            
            for (var i = 0; i < queryResult.rows.length; i++) {
                var row = queryResult.rows.item(i);
                
                draftList.push({
                    id: row.id,
                    draftType: row.draft_type,
                    recordId: row.record_id,
                    accountId: row.account_id,
                    formData: JSON.parse(row.draft_data),
                    originalData: row.original_data ? JSON.parse(row.original_data) : {},
                    createdAt: row.created_at,
                    updatedAt: row.updated_at,
                    changedFields: row.field_changes ? JSON.parse(row.field_changes) : [],
                    isNewRecord: row.is_new_record === 1,
                    pageIdentifier: row.page_identifier
                });
            }
        });
        
        console.log("📋 Found " + draftList.length + " draft(s)");
        
    } catch (e) {
        console.error("❌ Error getting all drafts:", e.toString());
        DBCommon.logException("getAllDrafts", e);
    }
    
    return draftList;
}

/**
 * Cleans up old drafts (older than specified days)
 * @param {number} daysOld - Number of days (default: 7)
 * @returns {Object} {success: boolean, deletedCount: number, message: string}
 */
function cleanupOldDrafts(daysOld) {
    daysOld = daysOld || 7;
    
    var result = {
        success: false,
        deletedCount: 0,
        message: ""
    };
    
    try {
        var db = Sql.LocalStorage.openDatabaseSync(
            DBCommon.NAME,
            DBCommon.VERSION,
            DBCommon.DISPLAY_NAME,
            DBCommon.SIZE
        );
        
        // Calculate cutoff date
        var cutoffDate = new Date();
        cutoffDate.setDate(cutoffDate.getDate() - daysOld);
        var cutoffDateStr = cutoffDate.toISOString();
        
        db.transaction(function(tx) {
            var deleteResult = tx.executeSql(
                "DELETE FROM form_drafts WHERE updated_at < ?",
                [cutoffDateStr]
            );
            result.deletedCount = deleteResult.rowsAffected;
        });
        
        result.success = true;
        result.message = "Cleaned up " + result.deletedCount + " old draft(s) (older than " + daysOld + " days)";
        console.log("🧹 " + result.message);
        
    } catch (e) {
        result.message = e.toString();
        console.error("❌ Error cleaning up old drafts:", result.message);
        DBCommon.logException("cleanupOldDrafts", e);
    }
    
    return result;
}

/**
 * Gets a human-readable summary of changes
 * @param {Array} changedFields - Array of changed field names
 * @returns {string} Human-readable summary
 */
function getChangesSummary(changedFields) {
    if (!changedFields || changedFields.length === 0) {
        return "No changes";
    }
    
    if (changedFields.length === 1) {
        return "1 field changed: " + changedFields[0];
    }
    
    return changedFields.length + " fields changed: " + changedFields.join(", ");
}

/**
 * Cleans up drafts for deleted records
 * This removes drafts associated with tasks/timesheets that have been marked as deleted
 * @param {string} draftType - Type of draft (task, timesheet, etc.)
 * @param {Array} recordIds - Array of record IDs that were deleted (optional, if not provided cleans all deleted)
 * @returns {Object} {success: boolean, deletedCount: number, message: string}
 */
function cleanupDraftsForDeletedRecords(draftType, recordIds) {
    var result = {
        success: false,
        deletedCount: 0,
        message: ""
    };
    
    if (!draftType) {
        result.message = "draftType is required";
        return result;
    }
    
    try {
        var db = Sql.LocalStorage.openDatabaseSync(
            DBCommon.NAME,
            DBCommon.VERSION,
            DBCommon.DISPLAY_NAME,
            DBCommon.SIZE
        );
        
        var tableName = null;
        if (draftType === "task") {
            tableName = "project_task_app";
        } else if (draftType === "timesheet") {
            tableName = "account_analytic_line_app";
        }
        
        if (!tableName) {
            result.message = "Unsupported draft type: " + draftType;
            return result;
        }
        
        db.transaction(function(tx) {
            var query = "";
            var params = [];
            
            if (recordIds && recordIds.length > 0) {
                // Delete drafts for specific deleted record IDs
                var placeholders = recordIds.map(function() { return "?"; }).join(",");
                query = "DELETE FROM form_drafts WHERE draft_type = ? AND record_id IN (" + placeholders + ")";
                params = [draftType].concat(recordIds);
            } else {
                // Delete all drafts for records marked as deleted in the main table
                query = "DELETE FROM form_drafts WHERE draft_type = ? AND record_id IN " +
                       "(SELECT id FROM " + tableName + " WHERE status = 'deleted')";
                params = [draftType];
            }
            
            var deleteResult = tx.executeSql(query, params);
            result.deletedCount = deleteResult.rowsAffected;
        });
        
        result.success = true;
        result.message = "Cleaned up " + result.deletedCount + " draft(s) for deleted " + draftType + "(s)";
        
        if (result.deletedCount > 0) {
            console.log("🗑️ " + result.message);
        }
        
    } catch (e) {
        result.message = e.toString();
        console.error("❌ Error cleaning up drafts for deleted records:", result.message);
        DBCommon.logException("cleanupDraftsForDeletedRecords", e);
    }
    
    return result;
}

/**
 * Gets a summary of drafts grouped by type with human-readable labels
 * @param {number} accountId - Account ID (-1 for all accounts)
 * @returns {Object} Summary object with counts and formatted message
 */
function getDraftsSummary(accountId) {
    var summary = {
        total: 0,
        byType: {},
        formattedMessage: "",
        detailedList: []
    };
    
    try {
        var drafts = getAllDrafts(accountId);
        summary.total = drafts.length;
        
        if (drafts.length === 0) {
            summary.formattedMessage = "No unsaved drafts";
            return summary;
        }
        
        // Count drafts by type
        var typeCounts = {};
        var typeLabels = {
            "task": "Task",
            "timesheet": "Timesheet",
            "project": "Project",
            "activity": "Activity"
        };
        
        for (var i = 0; i < drafts.length; i++) {
            var draft = drafts[i];
            var draftType = draft.draftType;
            
            if (!typeCounts[draftType]) {
                typeCounts[draftType] = 0;
            }
            typeCounts[draftType]++;
            
            // Add to detailed list
            var label = typeLabels[draftType] || draftType;
            var recordInfo = draft.isNewRecord ? "New" : "#" + draft.recordId;
            summary.detailedList.push({
                type: draftType,
                label: label,
                recordId: draft.recordId,
                isNewRecord: draft.isNewRecord,
                recordInfo: recordInfo,
                changedFields: draft.changedFields,
                updatedAt: draft.updatedAt
            });
        }
        
        summary.byType = typeCounts;
        
        // Create formatted message
        var parts = [];
        for (var type in typeCounts) {
            var label = typeLabels[type] || type;
            var count = typeCounts[type];
            parts.push(count + " " + label + (count > 1 ? "s" : ""));
        }
        
        if (parts.length === 1) {
            summary.formattedMessage = parts[0];
        } else if (parts.length === 2) {
            summary.formattedMessage = parts[0] + " and " + parts[1];
        } else {
            var last = parts.pop();
            summary.formattedMessage = parts.join(", ") + ", and " + last;
        }
        
    } catch (e) {
        console.error("❌ Error getting drafts summary:", e.toString());
        summary.formattedMessage = "Error loading drafts";
    }
    
    return summary;
}

/**
 * Synchronizes has_draft flags for all records that have drafts
 * This is a migration/maintenance function to ensure consistency
 * @returns {Object} {success: boolean, updatedCount: number, message: string}
 */
function syncHasDraftFlags() {
    var result = {
        success: false,
        updatedCount: 0,
        message: ""
    };
    
    try {
        var db = Sql.LocalStorage.openDatabaseSync(
            DBCommon.NAME,
            DBCommon.VERSION,
            DBCommon.DISPLAY_NAME,
            DBCommon.SIZE
        );
        
        db.transaction(function(tx) {
            // Get all drafts with record IDs
            var drafts = tx.executeSql(
                "SELECT DISTINCT draft_type, record_id FROM form_drafts WHERE record_id IS NOT NULL AND record_id > 0"
            );
            
            console.log("🔄 Syncing has_draft flags for " + drafts.rows.length + " records...");
            
            // Set has_draft=1 for all records that have drafts
            for (var i = 0; i < drafts.rows.length; i++) {
                var draft = drafts.rows.item(i);
                var recordId = draft.record_id;
                var draftType = draft.draft_type;
                
                var tableName = null;
                if (draftType === "task") {
                    tableName = "project_task_app";
                } else if (draftType === "timesheet") {
                    tableName = "account_analytic_line_app";
                } else if (draftType === "project_update") {
                    tableName = "project_update_app";
                } else if (draftType === "activity") {
                    tableName = "mail_activity_app";
                }
                
                if (tableName) {
                    tx.executeSql(
                        "UPDATE " + tableName + " SET has_draft = 1 WHERE id = ?",
                        [recordId]
                    );
                    result.updatedCount++;
                }
            }
            
            // Clear has_draft=0 for records that don't have drafts
            // (This handles cases where drafts were deleted but flag wasn't cleared)
            
            // For tasks
            var taskIds = tx.executeSql(
                "SELECT id FROM project_task_app WHERE has_draft = 1 AND id NOT IN (SELECT record_id FROM form_drafts WHERE draft_type = 'task' AND record_id IS NOT NULL)"
            );
            for (var j = 0; j < taskIds.rows.length; j++) {
                tx.executeSql(
                    "UPDATE project_task_app SET has_draft = 0 WHERE id = ?",
                    [taskIds.rows.item(j).id]
                );
                result.updatedCount++;
            }
            
            // For timesheets
            var timesheetIds = tx.executeSql(
                "SELECT id FROM account_analytic_line_app WHERE has_draft = 1 AND id NOT IN (SELECT record_id FROM form_drafts WHERE draft_type = 'timesheet' AND record_id IS NOT NULL)"
            );
            for (var k = 0; k < timesheetIds.rows.length; k++) {
                tx.executeSql(
                    "UPDATE account_analytic_line_app SET has_draft = 0 WHERE id = ?",
                    [timesheetIds.rows.item(k).id]
                );
                result.updatedCount++;
            }
            
            // For project updates
            var updateIds = tx.executeSql(
                "SELECT id FROM project_update_app WHERE has_draft = 1 AND id NOT IN (SELECT record_id FROM form_drafts WHERE draft_type = 'project_update' AND record_id IS NOT NULL)"
            );
            for (var l = 0; l < updateIds.rows.length; l++) {
                tx.executeSql(
                    "UPDATE project_update_app SET has_draft = 0 WHERE id = ?",
                    [updateIds.rows.item(l).id]
                );
                result.updatedCount++;
            }
            
            // For activities
            var activityIds = tx.executeSql(
                "SELECT id FROM mail_activity_app WHERE has_draft = 1 AND id NOT IN (SELECT record_id FROM form_drafts WHERE draft_type = 'activity' AND record_id IS NOT NULL)"
            );
            for (var m = 0; m < activityIds.rows.length; m++) {
                tx.executeSql(
                    "UPDATE mail_activity_app SET has_draft = 0 WHERE id = ?",
                    [activityIds.rows.item(m).id]
                );
                result.updatedCount++;
            }
        });
        
        result.success = true;
        result.message = "Synchronized " + result.updatedCount + " has_draft flag(s)";
        console.log("✅ " + result.message);
        
    } catch (e) {
        result.message = e.toString();
        console.error("❌ Error syncing has_draft flags:", result.message);
        DBCommon.logException("syncHasDraftFlags", e);
    }
    
    return result;
}

