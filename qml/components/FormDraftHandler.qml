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
import "../../models/draft_manager.js" as DraftManager

/**
 * FormDraftHandler - Reusable component for form draft management
 * 
 * Provides auto-save, crash recovery, and unsaved changes tracking.
 * Usage:
 *   FormDraftHandler {
 *       id: draftHandler
 *       draftType: "task"
 *       recordId: taskId
 *       accountId: accountId
 *       enabled: !isReadOnly
 *       onDraftLoaded: { restoreFormFromDraft(draftData) }
 *   }
 */
Item {
    id: root
    
    // ==================== PROPERTIES ====================
    
    /**
     * Type of form (task, timesheet, project, activity)
     */
    property string draftType: ""
    
    /**
     * Record ID being edited (null for new records)
     */
    property var recordId: null
    
    /**
     * Account ID
     */
    property int accountId: 0
    
    /**
     * Enable/disable draft functionality
     */
    property bool enabled: true
    
    /**
     * Auto-save interval in milliseconds (default: 30 seconds)
     */
    property int autoSaveInterval: 300000
    
    /**
     * Whether there are unsaved changes
     */
    property bool hasUnsavedChanges: false
    
    /**
     * Current form data (set by markFieldChanged)
     */
    property var currentFormData: ({})
    
    /**
     * Original data on load (set by initialize)
     */
    property var originalData: ({})
    
    /**
     * List of changed field names
     */
    property var changedFields: []
    
    /**
     * Unique page identifier (optional, for multiple instances)
     */
    property string pageIdentifier: "default"
    
    /**
     * Current draft ID (if exists)
     */
    property var currentDraftId: null
    
    /**
     * Internal flag to track initialization
     */
    property bool _initialized: false
    
    /**
     * Internal flag to prevent saving draft on destruction after explicit save/discard
     */
    property bool _preventAutoSave: false
    
    // Make this invisible - it's just for logic
    visible: false
    width: 0
    height: 0
    
    // ==================== SIGNALS ====================
    
    /**
     * Emitted when a draft is loaded from database
     * @param draftData - The draft data object
     * @param changedFields - Array of changed field names
     */
    signal draftLoaded(var draftData, var changedFields)
    
    /**
     * Emitted when a draft is saved
     * @param draftId - The draft ID
     */
    signal draftSaved(var draftId)
    
    /**
     * Emitted when trying to leave page with unsaved changes
     */
    signal unsavedChangesWarning()
    
    /**
     * Emitted when draft is cleared/deleted
     */
    signal draftCleared()
    
    // ==================== AUTO-SAVE TIMER ====================
    
    Timer {
        id: autoSaveTimer
        interval: root.autoSaveInterval
        running: root.enabled && root._initialized && root.hasUnsavedChanges && !root._preventAutoSave
        repeat: true
        
        onTriggered: {
            if (root.hasUnsavedChanges && !root._preventAutoSave) {
                console.log("🔄 Auto-saving draft for " + root.draftType + "...");
                root.saveDraft();
            }
        }
    }
    
    // ==================== METHODS ====================
    
    /**
     * Initialize draft handler with original data
     * Call this in Component.onCompleted after loading form data
     * @param originalDataObj - Original form data as object
     */
    function initialize(originalDataObj) {
        if (!enabled) {
            console.log("📝 Draft handler disabled for " + draftType);
            return;
        }
        
        console.log("🚀 Initializing draft handler for " + draftType);
        
        originalData = originalDataObj || {};
        currentFormData = JSON.parse(JSON.stringify(originalData)); // Deep copy
        hasUnsavedChanges = false;
        changedFields = [];
        _initialized = true;
        
        // Try to load existing draft
        tryLoadDraft();
    }
    
    /**
     * Try to load existing draft from database
     */
    function tryLoadDraft() {
        if (!enabled || !_initialized) return;
        
        var result = DraftManager.loadDraft({
            draftType: draftType,
            recordId: recordId,
            accountId: accountId,
            pageIdentifier: pageIdentifier
        });
        
        if (result.success && result.draft) {
            console.log("📂 Found existing draft for " + draftType);
            
            currentDraftId = result.draft.id;
            currentFormData = result.draft.formData;
            changedFields = result.draft.changedFields;
            hasUnsavedChanges = changedFields.length > 0;
            
            // Emit signal to restore form UI
            draftLoaded(result.draft.formData, changedFields);
        } else {
            console.log("📭 No existing draft for " + draftType);
        }
    }
    
    /**
     * Mark a field as changed
     * Call this whenever a form field changes
     * @param fieldName - Name of the field
     * @param value - New value
     */
    function markFieldChanged(fieldName, value) {
        if (!enabled || !_initialized || _preventAutoSave) return;
        
        // Update current form data
        currentFormData[fieldName] = value;
        
        // Recalculate changed fields
        changedFields = DraftManager.getChangedFields(currentFormData, originalData);
        hasUnsavedChanges = changedFields.length > 0;
        
        // console.log("✏️ Field changed: " + fieldName + " (" + changedFields.length + " total changes)");
    }
    
    /**
     * Manually save draft to database
     * @returns Success status
     */
    function saveDraft() {
        if (!enabled || !_initialized || _preventAutoSave) {
            if (_preventAutoSave) {
                console.log("🚫 Prevented draft save after explicit save/discard");
            }
            return { success: false, error: "Not initialized or prevented" };
        }
        
        if (!hasUnsavedChanges) {
            console.log("📝 No changes to save");
            return { success: true, hasChanges: false };
        }
        
        var result = DraftManager.saveDraft({
            draftType: draftType,
            recordId: recordId,
            accountId: accountId,
            formData: currentFormData,
            originalData: originalData,
            pageIdentifier: pageIdentifier
        });
        
        if (result.success && result.draftId) {
            currentDraftId = result.draftId;
            draftSaved(result.draftId);
        }
        
        return result;
    }
    
    /**
     * Clear/delete draft from database
     * Call this after successful form save
     */
    function clearDraft() {
        if (!enabled) return;
        
        console.log("🗑️ Clearing draft for " + draftType + " (recordId: " + recordId + ", accountId: " + accountId + ", pageId: " + pageIdentifier + ")");
        
        // CRITICAL: Stop the timer IMMEDIATELY to prevent any pending auto-saves
        autoSaveTimer.stop();
        
        // Set flag FIRST to prevent any race conditions
        _preventAutoSave = true;
        
        // Delete from database if exists
        if (currentDraftId) {
            var result = DraftManager.deleteDraft(currentDraftId);
            if (result.success) {
                console.log("✅ Draft #" + currentDraftId + " cleared successfully");
            }
        }
        
        // Also delete by criteria (in case currentDraftId is not set or multiple drafts exist)
        console.log("🔍 Searching for additional drafts to clean up...");
        var deleteAllResult = DraftManager.deleteDrafts({
            draftType: draftType,
            recordId: recordId,
            accountId: accountId,
            pageIdentifier: pageIdentifier
        });
        
        if (deleteAllResult.deletedCount > 0) {
            console.log("🧹 Cleaned up " + deleteAllResult.deletedCount + " additional draft(s)");
        }
        
        // Reset state
        currentDraftId = null;
        hasUnsavedChanges = false;
        changedFields = [];
        currentFormData = JSON.parse(JSON.stringify(originalData)); // Reset to original
        
        draftCleared();
    }
    
    /**
     * Check if user can leave page
     * Shows warning if there are unsaved changes
     * @returns True if can leave, false if should warn
     */
    function canLeavePage() {
        if (!enabled || !_initialized) return true;
        
        if (hasUnsavedChanges) {
            console.log("⚠️ Unsaved changes detected when trying to leave page");
            unsavedChangesWarning();
            return false;
        }
        
        return true;
    }
    
    /**
     * Get human-readable summary of changes
     * @returns String describing changes
     */
    function getChangesSummary() {
        return DraftManager.getChangesSummary(changedFields);
    }
    
    /**
     * Save draft and allow navigation
     * Used in unsaved changes dialog
     */
    function saveAndLeave() {
        saveDraft();
        hasUnsavedChanges = false; // Allow navigation
    }
    
    /**
     * Discard changes and allow navigation
     * Used in unsaved changes dialog
     */
    function discardAndLeave() {
        clearDraft();
        hasUnsavedChanges = false; // Allow navigation
    }
    
    /**
     * Update original data after successful save
     * This resets the "changes" baseline
     */
    function updateOriginalData() {
        originalData = JSON.parse(JSON.stringify(currentFormData));
        hasUnsavedChanges = false;
        changedFields = [];
        console.log("✅ Original data updated, no unsaved changes");
    }
    
    /**
     * Reset handler (useful for "new record" scenario)
     */
    function reset() {
        clearDraft();
        originalData = {};
        currentFormData = {};
        hasUnsavedChanges = false;
        changedFields = [];
        _initialized = false;
        console.log("🔄 Draft handler reset");
    }
    
    // ==================== CLEANUP ====================
    
    Component.onDestruction: {
        // Save draft one last time before component is destroyed
        // But NOT if we just cleared the draft (after save or discard)
        if (enabled && _initialized && hasUnsavedChanges && !_preventAutoSave) {
            console.log("💾 Saving draft before page destruction...");
            saveDraft();
        } else if (_preventAutoSave) {
            console.log("⏭️ Skipping auto-save on destruction (draft was cleared)");
        }
    }
}
