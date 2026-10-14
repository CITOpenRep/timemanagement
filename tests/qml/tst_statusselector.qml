import QtQuick 2.7
import QtTest 1.0
import Lomiri.Components 1.3
import "../../qml/components/selectors"

MainView {
    id: testRoot
    width: units.gu(40)
    height: units.gu(70)

    StatusSelector {
        id: testStatusSelector
        width: testRoot.width
    }

    SignalSpy {
        id: statusChangedSpy
        target: testStatusSelector
        signalName: "statusChanged"
    }

    TestCase {
        name: "StatusSelectorTests"
        when: windowShown

        function findButtonByText(root, text) {
            if (!root) return null;
            if (root.text && root.text.indexOf(text) !== -1) return root;
            for (var i = 0; i < (root.children ? root.children.length : 0); i++) {
                var found = findButtonByText(root.children[i], text);
                if (found) return found;
            }
            return null;
        }

        function getButtons() {
            var btnOnTrack = findButtonByText(testStatusSelector, "On Track");
            var btnAtRisk = findButtonByText(testStatusSelector, "At Risk");
            var btnOffTrack = findButtonByText(testStatusSelector, "Off Track");
            verify(btnOnTrack !== null, "On Track button should be found");
            verify(btnAtRisk !== null, "At Risk button should be found");
            verify(btnOffTrack !== null, "Off Track button should be found");
            return {
                onTrack: btnOnTrack,
                atRisk: btnAtRisk,
                offTrack: btnOffTrack
            };
        }

        function init() {
            testStatusSelector.readOnly = false;
            testStatusSelector.selectedStatus = "";
            statusChangedSpy.clear();
        }

        function cleanup() {
            testStatusSelector.readOnly = false;
            testStatusSelector.selectedStatus = "";
            statusChangedSpy.clear();
        }

        function test_initialProperties() {
            compare(testStatusSelector.readOnly, false);
            compare(testStatusSelector.selectedStatus, "");
            compare(statusChangedSpy.count, 0);

            var btns = getButtons();
            compare(btns.onTrack.enabled, true);
            compare(btns.atRisk.enabled, true);
            compare(btns.offTrack.enabled, true);
            compare(btns.onTrack.color, LomiriColors.ash);
            compare(btns.atRisk.color, LomiriColors.ash);
            compare(btns.offTrack.color, LomiriColors.ash);
        }

        function test_selectOnTrackStatusAndColor() {
            var btns = getButtons();
            mouseClick(btns.onTrack);

            compare(testStatusSelector.selectedStatus, "on_track");
            compare(statusChangedSpy.count, 1);
            compare(btns.onTrack.color, LomiriColors.green);
            compare(btns.atRisk.color, LomiriColors.ash);
            compare(btns.offTrack.color, LomiriColors.ash);
        }

        function test_selectAtRiskStatusAndColor() {
            var btns = getButtons();
            mouseClick(btns.atRisk);

            compare(testStatusSelector.selectedStatus, "at_risk");
            compare(statusChangedSpy.count, 1);
            compare(btns.atRisk.color, LomiriColors.orange);
            compare(btns.onTrack.color, LomiriColors.ash);
            compare(btns.offTrack.color, LomiriColors.ash);
        }

        function test_selectOffTrackStatusAndColor() {
            var btns = getButtons();
            mouseClick(btns.offTrack);

            compare(testStatusSelector.selectedStatus, "off_track");
            compare(statusChangedSpy.count, 1);
            compare(btns.offTrack.color, LomiriColors.red);
            compare(btns.onTrack.color, LomiriColors.ash);
            compare(btns.atRisk.color, LomiriColors.ash);
        }

        function test_statusDirectAssignmentUpdatesBadgeColors() {
            testStatusSelector.selectedStatus = "on_track";
            var btns = getButtons();
            compare(btns.onTrack.color, LomiriColors.green);

            testStatusSelector.selectedStatus = "off_track";
            compare(btns.offTrack.color, LomiriColors.red);
            compare(btns.onTrack.color, LomiriColors.ash);
        }

        function test_readOnlyDisablesButtons() {
            testStatusSelector.readOnly = true;

            var btns = getButtons();
            compare(btns.onTrack.enabled, false);
            compare(btns.atRisk.enabled, false);
            compare(btns.offTrack.enabled, false);
        }
    }
}
