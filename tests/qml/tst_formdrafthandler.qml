import QtQuick 2.7
import QtTest 1.0
import Lomiri.Components 1.3
import "../../qml/components/workflow"
import "../../models/dbinit.js" as DbInit

Item {
    id: testRoot
    width: units.gu(40)
    height: units.gu(50)

    FormDraftHandler {
        id: testHandler
        draftType: "task"
        recordId: 101
        accountId: 1
        pageIdentifier: "test_page"
    }

    SignalSpy {
        id: draftLoadedSpy
        target: testHandler
        signalName: "draftLoaded"
    }

    SignalSpy {
        id: draftSavedSpy
        target: testHandler
        signalName: "draftSaved"
    }

    SignalSpy {
        id: unsavedChangesWarningSpy
        target: testHandler
        signalName: "unsavedChangesWarning"
    }

    SignalSpy {
        id: draftClearedSpy
        target: testHandler
        signalName: "draftCleared"
    }

    TestCase {
        name: "FormDraftHandlerTests"
        when: windowShown

        function initTestCase() {
            DbInit.initializeDatabase();
        }

        function init() {
            testHandler.reset();
            testHandler.enabled = true;
            testHandler.trackingSuspended = false;
            testHandler.autoSaveInterval = 30000;
            draftLoadedSpy.clear();
            draftSavedSpy.clear();
            unsavedChangesWarningSpy.clear();
            draftClearedSpy.clear();
        }

        function cleanup() {
            testHandler.reset();
            draftLoadedSpy.clear();
            draftSavedSpy.clear();
            unsavedChangesWarningSpy.clear();
            draftClearedSpy.clear();
        }

        function test_initialProperties() {
            compare(testHandler.enabled, true);
            compare(testHandler.draftType, "task");
            compare(testHandler.recordId, 101);
            compare(testHandler.accountId, 1);
            compare(testHandler.hasUnsavedChanges, false);
            compare(testHandler.changedFields.length, 0);
            compare(testHandler.autoSaveInterval, 30000);
            compare(testHandler.trackingSuspended, false);
        }

        function test_initializeSetsOriginalDataAndClearsChanges() {
            var original = {
                name: "Initial Task",
                priority: "1",
                description: "Initial description"
            };

            testHandler.initialize(original);

            compare(testHandler._initialized, true);
            compare(testHandler.hasUnsavedChanges, false);
            compare(testHandler.changedFields.length, 0);
            compare(testHandler.currentFormData.name, "Initial Task");
            compare(testHandler.originalData.name, "Initial Task");
        }

        function test_markFieldChangedTracksChanges() {
            testHandler.initialize({ name: "Clean Name", description: "Clean Desc" });

            testHandler.markFieldChanged("name", "Modified Name");

            compare(testHandler.hasUnsavedChanges, true);
            compare(testHandler.changedFields.length, 1);
            compare(testHandler.changedFields[0], "name");
            compare(testHandler.currentFormData.name, "Modified Name");
        }

        function test_markFieldChangedRevertRestoresCleanState() {
            testHandler.initialize({ name: "Clean Name", description: "Clean Desc" });

            testHandler.markFieldChanged("name", "Modified Name");
            compare(testHandler.hasUnsavedChanges, true);

            // Revert back to original value
            testHandler.markFieldChanged("name", "Clean Name");
            compare(testHandler.hasUnsavedChanges, false);
            compare(testHandler.changedFields.length, 0);
        }

        function test_multipleFieldsChanged() {
            testHandler.initialize({ name: "Task 1", priority: "low", status: "open" });

            testHandler.markFieldChanged("name", "Task 1 Renamed");
            testHandler.markFieldChanged("priority", "high");

            compare(testHandler.hasUnsavedChanges, true);
            compare(testHandler.changedFields.length, 2);
            verify(testHandler.changedFields.indexOf("name") !== -1);
            verify(testHandler.changedFields.indexOf("priority") !== -1);
        }

        function test_trackingSuspendedIgnoresModifications() {
            testHandler.initialize({ name: "Base" });

            testHandler.trackingSuspended = true;
            testHandler.markFieldChanged("name", "Changed while suspended");

            compare(testHandler.hasUnsavedChanges, false);
            compare(testHandler.changedFields.length, 0);

            testHandler.trackingSuspended = false;
            testHandler.markFieldChanged("name", "Changed when resumed");
            compare(testHandler.hasUnsavedChanges, true);
        }

        function test_canLeavePageWarningSignal() {
            testHandler.initialize({ name: "Base" });

            // No changes -> can leave page without warning
            var canLeave = testHandler.canLeavePage();
            compare(canLeave, true);
            compare(unsavedChangesWarningSpy.count, 0);

            // Modify field -> cannot leave and emits warning signal
            testHandler.markFieldChanged("name", "Unsaved edit");
            canLeave = testHandler.canLeavePage();
            compare(canLeave, false);
            compare(unsavedChangesWarningSpy.count, 1);
        }

        function test_clearDraftResetsChangesAndEmitsSignal() {
            testHandler.initialize({ name: "Base" });
            testHandler.markFieldChanged("name", "Changed");
            compare(testHandler.hasUnsavedChanges, true);

            testHandler.clearDraft();

            compare(testHandler.hasUnsavedChanges, false);
            compare(testHandler.changedFields.length, 0);
            compare(draftClearedSpy.count, 1);
        }

        function test_updateOriginalDataEstablishesNewBaseline() {
            testHandler.initialize({ name: "Initial" });
            testHandler.markFieldChanged("name", "Updated Once");
            compare(testHandler.hasUnsavedChanges, true);

            testHandler.updateOriginalData({ name: "Updated Once" });

            compare(testHandler.hasUnsavedChanges, false);
            compare(testHandler.changedFields.length, 0);
            compare(testHandler.originalData.name, "Updated Once");
        }

        function test_saveAndLeaveDisablesUnsavedChanges() {
            testHandler.initialize({ name: "Initial" });
            testHandler.markFieldChanged("name", "Unsaved");
            compare(testHandler.hasUnsavedChanges, true);

            testHandler.saveAndLeave();
            compare(testHandler.hasUnsavedChanges, false);
        }

        function test_discardAndLeaveClearsDraft() {
            testHandler.initialize({ name: "Initial" });
            testHandler.markFieldChanged("name", "To Discard");
            compare(testHandler.hasUnsavedChanges, true);

            testHandler.discardAndLeave();
            compare(testHandler.hasUnsavedChanges, false);
            compare(draftClearedSpy.count, 1);
        }

        function test_disabledHandlerIgnoresChanges() {
            testHandler.enabled = false;
            testHandler.initialize({ name: "Disabled Mode" });
            testHandler.markFieldChanged("name", "Should not be tracked");

            compare(testHandler.hasUnsavedChanges, false);
        }
    }
}
