import QtQuick 2.7
import QtTest 1.0
import Lomiri.Components 1.3
import "../../qml/components/base"

Item {
    id: testRoot
    width: units.gu(40)
    height: units.gu(70)

    TSSearchBar {
        id: testSearchBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
    }

    SignalSpy {
        id: acceptedSpy
        target: testSearchBar
        signalName: "accepted"
    }

    SignalSpy {
        id: clearedSpy
        target: testSearchBar
        signalName: "cleared"
    }

    TestCase {
        name: "TSSearchBarTests"
        when: windowShown

        // Helper to find clear button Item inside testSearchBar
        function findClearButton() {
            var box = testSearchBar.children[0];
            for (var i = 0; i < box.children.length; ++i) {
                var child = box.children[i];
                if (child.hasOwnProperty("cursorShape")) continue; // top MouseArea
                // clearSearchButton has width 3.2gu and height 3.2gu
                if (child.width === units.gu(3.2) && child.height === units.gu(3.2)) {
                    return child;
                }
            }
            return null;
        }

        // Helper to find clear MouseArea inside clearSearchButton
        function findClearMouseArea() {
            var clearBtn = findClearButton();
            if (!clearBtn) return null;
            for (var i = 0; i < clearBtn.children.length; ++i) {
                var child = clearBtn.children[i];
                if (child.cursorShape === Qt.PointingHandCursor) {
                    return child;
                }
            }
            return null;
        }

        // Helper to find TextInput searchField
        function findSearchField() {
            var box = testSearchBar.children[0];
            for (var i = 0; i < box.children.length; ++i) {
                var child = box.children[i];
                if (child.hasOwnProperty("inputMethodHints")) {
                    return child;
                }
            }
            return null;
        }

        // Helper to find background MouseArea inside searchBarBox
        function findBackgroundMouseArea() {
            var box = testSearchBar.children[0];
            for (var i = 0; i < box.children.length; ++i) {
                var child = box.children[i];
                if (child.cursorShape === Qt.IBeamCursor) {
                    return child;
                }
            }
            return null;
        }

        // Helper to find placeholder Text element
        function findPlaceholderText() {
            var box = testSearchBar.children[0];
            for (var i = 0; i < box.children.length; ++i) {
                var child = box.children[i];
                if (child.hasOwnProperty("elide") && child.hasOwnProperty("text")) {
                    return child;
                }
            }
            return null;
        }

        function init() {
            testRoot.forceActiveFocus();
            testSearchBar.clear();
            testSearchBar.text = "";
            testSearchBar.placeholderText = "Search...";
            testSearchBar.activeFocusOnPress = true;
            testSearchBar.topPadding = units.gu(1.2);
            testSearchBar.bottomPadding = units.gu(1.2);
            testSearchBar.horizontalPadding = units.gu(1.5);
            testSearchBar.capsuleRadius = units.gu(1.2);
            acceptedSpy.clear();
            clearedSpy.clear();
        }

        //Initial State & Property Defaults

        function test_initialProperties() {
            compare(testSearchBar.text, "");
            compare(testSearchBar.placeholderText, "Search...");
            compare(testSearchBar.clip, true);
            compare(testSearchBar.isInputActive, false);
            compare(testSearchBar.capsuleRadius, units.gu(1.2));
            compare(testSearchBar.topPadding, units.gu(1.2));
            compare(testSearchBar.bottomPadding, units.gu(1.2));
            compare(testSearchBar.horizontalPadding, units.gu(1.5));
            compare(testSearchBar.implicitWidth, units.gu(30));
            compare(testSearchBar.implicitHeight, testSearchBar.topPadding + units.gu(4.6) + testSearchBar.bottomPadding);

            var clearBtn = findClearButton();
            verify(clearBtn !== null, "Clear button should exist in component hierarchy");
            compare(clearBtn.visible, false);
        }

        //Text Input Changes

        function test_textInputChanges() {
            testSearchBar.text = "Sprint planning";
            compare(testSearchBar.text, "Sprint planning");

            testSearchBar.text = "Bug fix #42";
            compare(testSearchBar.text, "Bug fix #42");

            testSearchBar.placeholderText = "Filter by project name...";
            compare(testSearchBar.placeholderText, "Filter by project name...");
        }

        function test_textChangeToNonEmptyDoesNotEmitClearedSignal() {
            clearedSpy.clear();
            testSearchBar.text = "Initial";
            compare(clearedSpy.count, 0);

            testSearchBar.text = "Updated";
            compare(clearedSpy.count, 0);
        }

        function test_directTextClearTriggersClearedSignal() {
            testSearchBar.text = "Temporary query";
            clearedSpy.clear();

            testSearchBar.text = "";
            compare(testSearchBar.text, "");
            compare(clearedSpy.count, 1);
        }

        function test_textInputFocus() {
            var field = findSearchField();
            verify(field !== null, "TextInput field should exist");

            field.forceActiveFocus();
            tryCompare(testSearchBar, "isInputActive", true, 500);

            compare(testSearchBar.activeFocusOnPress, true);
            testSearchBar.activeFocusOnPress = false;
            compare(testSearchBar.activeFocusOnPress, false);
            testSearchBar.activeFocusOnPress = true;
        }

        function test_forceActiveFocusFunction() {
            testSearchBar.forceActiveFocus();
            tryCompare(testSearchBar, "isInputActive", true, 500);
        }

        function test_clickBackgroundGivesFocus() {
            var bgArea = findBackgroundMouseArea();
            verify(bgArea !== null, "Background MouseArea should exist");

            mouseClick(bgArea);
            tryCompare(testSearchBar, "isInputActive", true, 500);
        }

        function test_placeholderVisibility() {
            var placeholder = findPlaceholderText();
            verify(placeholder !== null, "Placeholder text element should exist");

            // Empty text and no focus -> placeholder is visible
            compare(placeholder.visible, true);

            // Active focus -> placeholder hides
            testSearchBar.forceActiveFocus();
            tryCompare(testSearchBar, "isInputActive", true, 500);
            compare(placeholder.visible, false);

            // Remove focus -> placeholder is visible again
            testRoot.forceActiveFocus();
            tryCompare(testSearchBar, "isInputActive", false, 500);
            compare(placeholder.visible, true);

            // Text entered without focus -> placeholder hides
            testSearchBar.text = "Filter keyword";
            compare(placeholder.visible, false);

            // Text cleared -> placeholder is visible again
            testSearchBar.clear();
            compare(placeholder.visible, true);
        }

        //Search Trigger Signal (accepted)

        function test_searchTriggerSignalViaAccepted() {
            testSearchBar.text = "Documentation update";
            var field = findSearchField();
            verify(field !== null);

            field.accepted();
            compare(acceptedSpy.count, 1);
            compare(acceptedSpy.signalArguments[0][0], "Documentation update");
        }

        function test_searchTriggerSignalMultipleQueries() {
            var field = findSearchField();
            verify(field !== null, "TextInput field should exist");

            field.forceActiveFocus();
            tryCompare(field, "activeFocus", true, 500);

            testSearchBar.text = "First Query";
            keyClick(Qt.Key_Return);
            compare(acceptedSpy.count, 1);
            compare(acceptedSpy.signalArguments[0][0], "First Query");

            testSearchBar.text = "Second Query";
            keyClick(Qt.Key_Return);
            compare(acceptedSpy.count, 2);
            compare(acceptedSpy.signalArguments[1][0], "Second Query");
        }

        function test_searchTriggerSignalEmptyQuery() {
            testSearchBar.text = "";
            var field = findSearchField();
            verify(field !== null);

            field.accepted();
            compare(acceptedSpy.count, 1);
            compare(acceptedSpy.signalArguments[0][0], "");
        }

        function test_keyClickEnterTriggersAccepted() {
            var field = findSearchField();
            verify(field !== null);

            field.forceActiveFocus();
            tryCompare(field, "activeFocus", true, 500);

            testSearchBar.text = "Keyboard query";
            keyClick(Qt.Key_Return);

            compare(acceptedSpy.count, 1);
            compare(acceptedSpy.signalArguments[0][0], "Keyboard query");
        }

        //Clear Button Behavior

        function test_clearButtonVisibilityTrackingText() {
            var clearBtn = findClearButton();
            verify(clearBtn !== null);

            compare(clearBtn.visible, false);

            testSearchBar.text = "Active search";
            compare(clearBtn.visible, true);

            testSearchBar.text = "";
            compare(clearBtn.visible, false);
        }

        function test_clearFunctionResetsTextAndEmitsSignal() {
            testSearchBar.text = "Query to reset";
            clearedSpy.clear();

            var clearBtn = findClearButton();
            verify(clearBtn !== null);
            compare(clearBtn.visible, true);

            testSearchBar.clear();
            compare(testSearchBar.text, "");
            compare(clearBtn.visible, false);
            compare(clearedSpy.count, 1);
        }

        function test_clearWhenAlreadyEmptyDoesNothing() {
            testSearchBar.text = "";
            clearedSpy.clear();

            testSearchBar.clear();
            compare(testSearchBar.text, "");
            compare(clearedSpy.count, 0);
        }

        function test_clearButtonClickResetsTextAndEmitsSignal() {
            testSearchBar.text = "Click to clear";
            clearedSpy.clear();

            var clearBtn = findClearButton();
            verify(clearBtn !== null);
            compare(clearBtn.visible, true);

            var clearArea = findClearMouseArea();
            verify(clearArea !== null);

            mouseClick(clearArea);

            compare(testSearchBar.text, "");
            compare(clearBtn.visible, false);
            compare(clearedSpy.count, 1);
        }

        //Dimensions & Padding Responsiveness

        function test_customDimensionsAndPadding() {
            testSearchBar.topPadding = units.gu(2.0);
            testSearchBar.bottomPadding = units.gu(2.5);
            compare(testSearchBar.implicitHeight, units.gu(2.0) + units.gu(4.6) + units.gu(2.5));

            testSearchBar.horizontalPadding = units.gu(3.0);
            compare(testSearchBar.horizontalPadding, units.gu(3.0));

            testSearchBar.capsuleRadius = units.gu(2.0);
            compare(testSearchBar.capsuleRadius, units.gu(2.0));
        }
    }
}
