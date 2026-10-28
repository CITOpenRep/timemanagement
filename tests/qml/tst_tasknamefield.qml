import QtQuick 2.7
import QtTest 1.0
import Lomiri.Components 1.3
import "../../qml/features/tasks/components"

MainView {
    id: testRoot
    width: units.gu(40)
    height: units.gu(70)

    TaskNameField {
        id: testField
        availableWidth: testRoot.width
    }

    SignalSpy {
        id: nameEditedSpy
        target: testField
        signalName: "nameEdited"
    }

    TestCase {
        name: "TaskNameFieldTests"
        when: windowShown

        function init() {
            testField.text = "";
            testField.isReadOnly = false;
            testField.availableWidth = testRoot.width;
            nameEditedSpy.clear();
        }

        function cleanup() {
            testField.text = "";
            testField.isReadOnly = false;
            nameEditedSpy.clear();
        }

        function test_initialProperties() {
            compare(testField.text, "");
            compare(testField.isReadOnly, false);
            compare(testField.height, units.gu(6));
            compare(testField.spacing, units.gu(1));
            compare(nameEditedSpy.count, 0);
        }

        function test_textPropertyChangeEmitsSignal() {
            compare(nameEditedSpy.count, 0);
            testField.text = "Write Unit Tests";
            compare(testField.text, "Write Unit Tests");
            compare(nameEditedSpy.count, 1);
            compare(nameEditedSpy.signalArguments[0][0], "Write Unit Tests");
        }

        function test_multipleTextEdits() {
            testField.text = "First Task";
            testField.text = "Updated Task";
            compare(testField.text, "Updated Task");
            compare(nameEditedSpy.count, 2);
            compare(nameEditedSpy.signalArguments[1][0], "Updated Task");
        }

        function test_emptyAndWhitespaceValidation() {
            testField.text = "   ";
            compare(testField.text, "   ");
            compare(nameEditedSpy.count, 1);
            compare(nameEditedSpy.signalArguments[0][0], "   ");

            testField.text = "";
            compare(testField.text, "");
            compare(nameEditedSpy.count, 2);
            compare(nameEditedSpy.signalArguments[1][0], "");
        }

        function test_specialCharactersInput() {
            var specialText = "!@#$%^&*()_+{}[]:;\"'|<>,.?/~`";
            testField.text = specialText;
            compare(testField.text, specialText);
            compare(nameEditedSpy.count, 1);
            compare(nameEditedSpy.signalArguments[0][0], specialText);
        }

        function test_readOnlyState() {
            testField.isReadOnly = true;
            compare(testField.isReadOnly, true);

            // Programmatic update still works, but readOnly flag reflects state
            testField.text = "Read Only Task";
            compare(testField.text, "Read Only Task");
        }

        function test_availableWidthScaling() {
            testField.availableWidth = units.gu(50);
            compare(testField.width, units.gu(50));

            testField.availableWidth = units.gu(30);
            compare(testField.width, units.gu(30));
        }
    }
}
