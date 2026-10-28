import QtQuick 2.7
import QtTest 1.0
import Lomiri.Components 1.3
import "../../qml/components/base"

Item {
    id: testRoot
    width: units.gu(40)
    height: units.gu(70)

    TSSwitch {
        id: testSwitch
        width: units.gu(4.2)
        height: units.gu(2.1)
    }

    SignalSpy {
        id: clickedSpy
        target: testSwitch
        signalName: "clicked"
    }

    SignalSpy {
        id: toggledSpy
        target: testSwitch
        signalName: "toggled"
    }

    TestCase {
        name: "TSSwitchTests"
        when: windowShown

        // Helper to retrieve the track Rectangle
        function findTrack() {
            if (testSwitch.children && testSwitch.children.length > 0) {
                return testSwitch.children[0];
            }
            return null;
        }

        // Helper to retrieve the thumb Rectangle inside track
        function findThumb() {
            var trk = findTrack();
            if (trk && trk.children && trk.children.length > 0) {
                return trk.children[0];
            }
            return null;
        }

        // Helper to retrieve the MouseArea
        function findMouseArea() {
            if (testSwitch.children) {
                for (var i = 0; i < testSwitch.children.length; i++) {
                    if (testSwitch.children[i] instanceof MouseArea) {
                        return testSwitch.children[i];
                    }
                }
            }
            return null;
        }

        function cleanup() {
            testSwitch.checked = false;
            testSwitch.enabled = true;
            testSwitch.interactive = true;
            testSwitch.width = units.gu(4.2);
            testSwitch.height = units.gu(2.1);
            testSwitch.checkedColor = Qt.darker(LomiriColors.orange, 1.35);
            testSwitch.uncheckedColor = "#35ffffff";
            testSwitch.thumbColor = "white";
            testSwitch.checkedBorderColor = "transparent";
            testSwitch.uncheckedBorderColor = "#40ffffff";
            clickedSpy.clear();
            toggledSpy.clear();
            var thumb = findThumb();
            if (thumb) {
                tryCompare(thumb, "x", units.dp(2), 500);
            }
        }

        // ── Initial State & Property Defaults ──

        function test_initialProperties() {
            compare(testSwitch.checked, false);
            compare(testSwitch.enabled, true);
            compare(testSwitch.interactive, true);
            compare(testSwitch.implicitWidth, units.gu(4.2));
            compare(testSwitch.implicitHeight, units.gu(2.1));
            compare(testSwitch.opacity, 1.0);
            compare(testSwitch.checkedColor, Qt.darker(LomiriColors.orange, 1.35));
            compare(testSwitch.borderWidth, units.dp(1));
            compare(testSwitch.borderColor, testSwitch.uncheckedBorderColor);
        }

        function test_initialVisualHierarchy() {
            var track = findTrack();
            verify(track !== null, "Track Rectangle should exist");
            compare(track.radius, testSwitch.height / 2);
            compare(track.border.width, units.dp(1));
            compare(track.border.color, testSwitch.uncheckedBorderColor);

            var thumb = findThumb();
            verify(thumb !== null, "Thumb Rectangle should exist");
            compare(thumb.width, testSwitch.height - units.dp(4));
            compare(thumb.height, thumb.width);
            compare(thumb.radius, thumb.width / 2);
            compare(thumb.color, testSwitch.thumbColor);
            compare(thumb.x, units.dp(2));

            var mouseArea = findMouseArea();
            verify(mouseArea !== null, "MouseArea should exist");
            compare(mouseArea.enabled, true);
            compare(mouseArea.visible, true);
            compare(mouseArea.cursorShape, Qt.PointingHandCursor);
        }

        // ── Toggle State Changes ──

        function test_toggleCheckedChangesThumbPosition() {
            var thumb = findThumb();
            verify(thumb !== null);

            // Initial unchecked position (thumb at left offset 2dp)
            compare(testSwitch.checked, false);
            compare(thumb.x, units.dp(2));

            // Toggle checked to true -> thumb slides to the right
            testSwitch.checked = true;
            var expectedRightX = testSwitch.width - thumb.width - units.dp(2);
            tryCompare(thumb, "x", expectedRightX, 500);

            // Toggle checked back to false -> thumb slides back to left
            testSwitch.checked = false;
            tryCompare(thumb, "x", units.dp(2), 500);
        }

        function test_toggleCheckedChangesBorderAndColors() {
            var track = findTrack();
            verify(track !== null);

            // Unchecked initial state
            compare(testSwitch.checked, false);
            compare(testSwitch.borderWidth, units.dp(1));
            compare(track.border.width, units.dp(1));
            compare(testSwitch.borderColor, testSwitch.uncheckedBorderColor);

            // Switch to checked state
            testSwitch.checked = true;
            compare(testSwitch.borderWidth, 0);
            compare(track.border.width, 0);
            compare(testSwitch.borderColor, testSwitch.checkedBorderColor);
            tryCompare(track, "color", testSwitch.checkedColor, 500);

            // Switch back to unchecked state
            testSwitch.checked = false;
            compare(testSwitch.borderWidth, units.dp(1));
            compare(track.border.width, units.dp(1));
            compare(testSwitch.borderColor, testSwitch.uncheckedBorderColor);
            tryCompare(track, "color", testSwitch.uncheckedColor, 500);
        }

        // ── Click Interactions & Signal Emissions ──

        function test_mouseClickEmitsClickedAndToggledSignals() {
            var thumb = findThumb();
            var mouseArea = findMouseArea();
            verify(mouseArea !== null);

            clickedSpy.clear();
            toggledSpy.clear();

            // Click when unchecked -> emits clicked and toggled(true)
            compare(testSwitch.checked, false);
            mouseClick(mouseArea);
            compare(clickedSpy.count, 1);
            compare(toggledSpy.count, 1);
            compare(toggledSpy.signalArguments[0][0], true);

            // Click when checked -> emits clicked and toggled(false)
            testSwitch.checked = true;
            mouseClick(mouseArea);
            compare(clickedSpy.count, 2);
            compare(toggledSpy.count, 2);
            compare(toggledSpy.signalArguments[1][0], false);

            testSwitch.checked = false;
            if (thumb) {
                tryCompare(thumb, "x", units.dp(2), 500);
            }
        }

        function test_multipleConsecutiveClicks() {
            var mouseArea = findMouseArea();
            verify(mouseArea !== null);

            clickedSpy.clear();
            toggledSpy.clear();

            mouseClick(mouseArea);
            mouseClick(mouseArea);
            mouseClick(mouseArea);

            compare(clickedSpy.count, 3);
            compare(toggledSpy.count, 3);
        }

        // ── Disabled State ──

        function test_disabledStateOpacityAndCursor() {
            var mouseArea = findMouseArea();
            verify(mouseArea !== null);

            // Enabled default state
            compare(testSwitch.enabled, true);
            compare(testSwitch.opacity, 1.0);
            compare(mouseArea.cursorShape, Qt.PointingHandCursor);

            // Disabled state reduces opacity and changes cursor shape
            testSwitch.enabled = false;
            compare(testSwitch.enabled, false);
            compare(testSwitch.opacity, 0.6);
            compare(mouseArea.cursorShape, Qt.ArrowCursor);
            compare(mouseArea.enabled, false);

            // Restoring enabled state
            testSwitch.enabled = true;
            compare(testSwitch.enabled, true);
            compare(testSwitch.opacity, 1.0);
            compare(mouseArea.cursorShape, Qt.PointingHandCursor);
            compare(mouseArea.enabled, true);
        }

        function test_disabledStateBlocksClicks() {
            var mouseArea = findMouseArea();
            verify(mouseArea !== null);

            testSwitch.enabled = false;
            clickedSpy.clear();
            toggledSpy.clear();

            mouseClick(mouseArea);
            compare(clickedSpy.count, 0);
            compare(toggledSpy.count, 0);

            // Re-enable and verify clicks are accepted again
            testSwitch.enabled = true;
            mouseClick(mouseArea);
            compare(clickedSpy.count, 1);
            compare(toggledSpy.count, 1);
        }

        // ── Interactive Property ──

        function test_nonInteractiveStateBlocksInputAndHidesMouseArea() {
            var mouseArea = findMouseArea();
            verify(mouseArea !== null);

            testSwitch.interactive = false;
            compare(testSwitch.interactive, false);
            compare(mouseArea.enabled, false);
            compare(mouseArea.visible, false);
            compare(mouseArea.cursorShape, Qt.ArrowCursor);

            clickedSpy.clear();
            toggledSpy.clear();
            mouseClick(mouseArea);
            compare(clickedSpy.count, 0);
            compare(toggledSpy.count, 0);

            // Re-enable interactivity
            testSwitch.interactive = true;
            compare(mouseArea.enabled, true);
            compare(mouseArea.visible, true);
            compare(mouseArea.cursorShape, Qt.PointingHandCursor);
        }

        // ── Custom Dimensions & Scaling ──

        function test_customDimensionsAndScaling() {
            var track = findTrack();
            var thumb = findThumb();
            verify(track !== null);
            verify(thumb !== null);

            testSwitch.width = units.gu(6);
            testSwitch.height = units.gu(3);

            compare(track.radius, units.gu(1.5));
            compare(thumb.width, units.gu(3) - units.dp(4));
            compare(thumb.height, thumb.width);
            compare(thumb.radius, thumb.width / 2);

            // Unchecked thumb position
            compare(thumb.x, units.dp(2));

            // Checked thumb position with larger dimensions
            testSwitch.checked = true;
            var expectedX = units.gu(6) - (units.gu(3) - units.dp(4)) - units.dp(2);
            tryCompare(thumb, "x", expectedX, 500);

            testSwitch.checked = false;
            tryCompare(thumb, "x", units.dp(2), 500);
        }

        // ── Custom Colors ──

        function test_customColors() {
            var track = findTrack();
            var thumb = findThumb();
            verify(track !== null);
            verify(thumb !== null);

            testSwitch.checkedColor = "#2563eb";
            testSwitch.uncheckedColor = "#475569";
            testSwitch.thumbColor = "#f8fafc";
            testSwitch.checkedBorderColor = "#1d4ed8";
            testSwitch.uncheckedBorderColor = "#64748b";

            compare(testSwitch.checkedColor, "#2563eb");
            compare(testSwitch.uncheckedColor, "#475569");
            compare(testSwitch.thumbColor, "#f8fafc");
            compare(thumb.color, "#f8fafc");

            // Unchecked border and track color
            testSwitch.checked = false;
            compare(testSwitch.borderColor, "#64748b");
            tryCompare(track, "color", "#475569", 500);

            // Checked border and track color
            testSwitch.checked = true;
            compare(testSwitch.borderColor, "#1d4ed8");
            tryCompare(track, "color", "#2563eb", 500);

            // Restore unchecked
            testSwitch.checked = false;
            tryCompare(thumb, "x", units.dp(2), 500);
        }
    }
}
