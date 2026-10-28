import QtQuick 2.7
import QtTest 1.0
import Lomiri.Components 1.3
import "../../qml/components/base"

Item {
    id: testRoot
    width: units.gu(40)
    height: units.gu(70)

    OutlinedTextField {
        id: testField
        width: testRoot.width
    }

    SignalSpy {
        id: acceptedSpy
        target: testField
        signalName: "accepted"
    }

    TestCase {
        name: "OutlinedTextFieldTests"
        when: windowShown

        // Helper to retrieve the borderRect (first Rectangle child)
        function findBorderRect() {
            if (testField.children && testField.children.length > 0) {
                return testField.children[0];
            }
            return null;
        }

        // Helper to retrieve inputField (TextInput inside borderRect)
        function findInputField() {
            var border = findBorderRect();
            if (border) {
                for (var i = 0; i < border.children.length; i++) {
                    if (border.children[i] instanceof TextInput) {
                        return border.children[i];
                    }
                }
            }
            return null;
        }

        // Helper to retrieve placeholder Text element inside borderRect
        function findPlaceholderText() {
            var border = findBorderRect();
            if (border) {
                for (var i = 0; i < border.children.length; i++) {
                    if (border.children[i] instanceof Text) {
                        return border.children[i];
                    }
                }
            }
            return null;
        }

        // Helper to retrieve the floating label container (second Rectangle child)
        function findLabelContainer() {
            if (testField.children && testField.children.length > 1) {
                return testField.children[1];
            }
            return null;
        }

        // Helper to retrieve the inner label Text element
        function findLabelText() {
            var container = findLabelContainer();
            if (container && container.children && container.children.length > 0) {
                return container.children[0];
            }
            return null;
        }

        function cleanup() {
            testRoot.forceActiveFocus();
            testField.text = "";
            testField.placeholderText = "";
            testField.labelText = "";
            testField.echoMode = TextInput.Normal;
            testField.enabled = true;
            testField.readOnly = false;
            testField.maximumLength = 32767;
            acceptedSpy.clear();
        }

        // ── Initial State & Property Defaults ──

        function test_initialProperties() {
            compare(testField.text, "");
            compare(testField.placeholderText, "");
            compare(testField.labelText, "");
            compare(testField.echoMode, TextInput.Normal);
            compare(testField.enabled, true);
            compare(testField.readOnly, false);
            compare(testField.height, units.gu(6.5));
            compare(testField.width, testRoot.width);
        }

        function test_initialVisualHierarchy() {
            var borderRect = findBorderRect();
            verify(borderRect !== null, "Border Rectangle should exist");
            compare(borderRect.radius, units.gu(0.8));
            compare(borderRect.border.width, 1);
            compare(borderRect.clip, true);

            var field = findInputField();
            verify(field !== null, "TextInput should exist inside borderRect");
            compare(field.text, "");
            compare(field.activeFocus, false);
            compare(field.selectByMouse, true);

            var placeholder = findPlaceholderText();
            verify(placeholder !== null, "Placeholder Text should exist");
            compare(placeholder.text, "");
            compare(placeholder.visible, true);

            var labelContainer = findLabelContainer();
            verify(labelContainer !== null, "Label container should exist");
            compare(labelContainer.visible, false);
        }

        // ── Focus State Management ──

        function test_focusStateTogglesBorderWidthAndColor() {
            var borderRect = findBorderRect();
            var field = findInputField();
            verify(borderRect !== null);
            verify(field !== null);

            // Unfocused initial state
            compare(field.activeFocus, false);
            compare(borderRect.border.width, 1);
            verify(borderRect.border.color !== LomiriColors.blue,
                   "Unfocused border color should not be blue");

            // Acquire focus
            field.forceActiveFocus();
            tryCompare(field, "activeFocus", true, 500);
            compare(borderRect.border.width, 2);
            compare(borderRect.border.color, LomiriColors.blue);

            // Lose focus
            testRoot.forceActiveFocus();
            tryCompare(field, "activeFocus", false, 500);
            compare(borderRect.border.width, 1);
            verify(borderRect.border.color !== LomiriColors.blue);
        }

        function test_labelColorUpdatesOnFocus() {
            testField.labelText = "Account Name";
            var labelText = findLabelText();
            var field = findInputField();
            verify(labelText !== null);
            verify(field !== null);

            // Unfocused label color
            verify(labelText.color !== LomiriColors.blue);

            // Focused label color switches to blue
            field.forceActiveFocus();
            tryCompare(field, "activeFocus", true, 500);
            compare(labelText.color, LomiriColors.blue);

            // Unfocusing restores muted label color
            testRoot.forceActiveFocus();
            tryCompare(field, "activeFocus", false, 500);
            verify(labelText.color !== LomiriColors.blue);
        }

        // ── Placeholder Visibility Dynamics ──

        function test_placeholderTextBinding() {
            testField.placeholderText = "Enter server URL...";
            var placeholder = findPlaceholderText();
            verify(placeholder !== null);
            compare(placeholder.text, "Enter server URL...");

            testField.placeholderText = "https://example.com/caldav";
            compare(placeholder.text, "https://example.com/caldav");
        }

        function test_placeholderVisibilityWhenFocusChanges() {
            testField.placeholderText = "Username";
            var placeholder = findPlaceholderText();
            var field = findInputField();
            verify(placeholder !== null);
            verify(field !== null);

            // 1. Empty & unfocused -> visible
            compare(placeholder.visible, true);

            // 2. Empty & focused -> hidden
            field.forceActiveFocus();
            tryCompare(field, "activeFocus", true, 500);
            compare(placeholder.visible, false);

            // 3. Empty & blur -> visible again
            testRoot.forceActiveFocus();
            tryCompare(field, "activeFocus", false, 500);
            compare(placeholder.visible, true);
        }

        function test_placeholderVisibilityWhenTextEntered() {
            testField.placeholderText = "Username";
            var placeholder = findPlaceholderText();
            var field = findInputField();
            verify(placeholder !== null);
            verify(field !== null);

            // 1. Text entered without focus -> hidden
            testField.text = "john_doe";
            compare(placeholder.visible, false);

            // 2. Text entered with focus -> hidden
            field.forceActiveFocus();
            tryCompare(field, "activeFocus", true, 500);
            compare(placeholder.visible, false);

            // 3. Clear text with focus -> hidden (still has focus)
            testField.text = "";
            compare(placeholder.visible, false);

            // 4. Blur while empty -> visible again
            testRoot.forceActiveFocus();
            tryCompare(field, "activeFocus", false, 500);
            compare(placeholder.visible, true);
        }

        // ── Input Changes & Text Manipulation ──

        function test_textInputChanges() {
            var field = findInputField();
            verify(field !== null);

            testField.text = "admin@company.com";
            compare(testField.text, "admin@company.com");
            compare(field.text, "admin@company.com");

            testField.text = "user@domain.org";
            compare(testField.text, "user@domain.org");
            compare(field.text, "user@domain.org");

            testField.text = "";
            compare(testField.text, "");
            compare(field.text, "");
        }

        function test_keyClickTyping() {
            var field = findInputField();
            verify(field !== null);

            field.forceActiveFocus();
            tryCompare(field, "activeFocus", true, 500);

            testField.text = "";
            keyClick(Qt.Key_P);
            keyClick(Qt.Key_A);
            keyClick(Qt.Key_S);
            keyClick(Qt.Key_S);
            compare(testField.text, "pass");
            compare(field.text, "pass");
        }

        function test_maximumLengthRestriction() {
            testField.maximumLength = 5;
            compare(testField.maximumLength, 5);

            testField.text = "123456789";
            compare(testField.text.length, 5);
            compare(testField.text, "12345");

            testField.maximumLength = 32767;
        }

        function test_echoModeChanges() {
            var field = findInputField();
            verify(field !== null);

            testField.echoMode = TextInput.Password;
            compare(testField.echoMode, TextInput.Password);
            compare(field.echoMode, TextInput.Password);

            testField.echoMode = TextInput.NoEcho;
            compare(testField.echoMode, TextInput.NoEcho);
            compare(field.echoMode, TextInput.NoEcho);

            testField.echoMode = TextInput.Normal;
            compare(testField.echoMode, TextInput.Normal);
            compare(field.echoMode, TextInput.Normal);
        }

        function test_readOnlyStateAndStyling() {
            var borderRect = findBorderRect();
            var field = findInputField();
            verify(borderRect !== null);
            verify(field !== null);

            compare(testField.readOnly, false);
            compare(borderRect.color, "#00000000");

            testField.readOnly = true;
            compare(testField.readOnly, true);
            compare(field.readOnly, true);
            verify(borderRect.color !== "#00000000",
                   "ReadOnly should apply a tinted background color");

            testField.readOnly = false;
            compare(testField.readOnly, false);
            compare(field.readOnly, false);
            compare(borderRect.color, "#00000000");
        }

        function test_enabledState() {
            var field = findInputField();
            verify(field !== null);

            testField.enabled = false;
            compare(testField.enabled, false);
            compare(field.enabled, false);

            testField.enabled = true;
            compare(testField.enabled, true);
            compare(field.enabled, true);
        }

        // ── Accepted Signal & Submission ──

        function test_acceptedSignalOnReturnKey() {
            var field = findInputField();
            verify(field !== null);

            field.forceActiveFocus();
            tryCompare(field, "activeFocus", true, 500);

            testField.text = "Submitted via Return";
            acceptedSpy.clear();

            keyClick(Qt.Key_Return);
            compare(acceptedSpy.count, 1);
        }

        function test_acceptedSignalOnEnterKey() {
            var field = findInputField();
            verify(field !== null);

            field.forceActiveFocus();
            tryCompare(field, "activeFocus", true, 500);

            testField.text = "Submitted via Enter";
            acceptedSpy.clear();

            keyClick(Qt.Key_Enter);
            compare(acceptedSpy.count, 1);
        }

        // ── Floating Label Behavior ──

        function test_floatingLabelVisibilityAndText() {
            var labelContainer = findLabelContainer();
            var labelText = findLabelText();
            verify(labelContainer !== null);
            verify(labelText !== null);

            // Empty labelText -> hidden container
            compare(testField.labelText, "");
            compare(labelContainer.visible, false);

            // Set labelText -> visible container with matching text
            testField.labelText = "Server Hostname";
            compare(testField.labelText, "Server Hostname");
            compare(labelContainer.visible, true);
            compare(labelText.text, "Server Hostname");

            // Clear labelText -> hidden again
            testField.labelText = "";
            compare(labelContainer.visible, false);
        }
    }
}
