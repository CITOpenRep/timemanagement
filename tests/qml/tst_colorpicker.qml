import QtQuick 2.7
import QtTest 1.0
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import "../../qml/components/dialogs"

MainView {
    id: testRoot
    width: units.gu(40)
    height: units.gu(70)

    ColorPicker {
        id: testColorPicker
    }

    SignalSpy {
        id: colorPickedSpy
        target: testColorPicker
        signalName: "colorPicked"
    }

    TestCase {
        name: "ColorPickerTests"
        when: windowShown

        readonly property var defaultPalette: [
            "#FFFFFF", "#EB6E67", "#F39C5A", "#F6C342",
            "#6CC1E1", "#854D76", "#ED8888", "#2C8397",
            "#49597C", "#DE3F7C", "#45C486", "#9B6CC3"
        ]

        function init() {
            testColorPicker.selectedColorIndex = -1;
            testColorPicker.selectedColor = "";
            testColorPicker.odooColors = defaultPalette;
            colorPickedSpy.clear();
        }

        function cleanup() {
            testColorPicker.selectedColorIndex = -1;
            testColorPicker.selectedColor = "";
            testColorPicker.odooColors = defaultPalette;
            colorPickedSpy.clear();
        }

        function test_initialProperties() {
            compare(testColorPicker.selectedColorIndex, -1);
            compare(testColorPicker.selectedColor, "");
            compare(testColorPicker.odooColors.length, 12);
            compare(colorPickedSpy.count, 0);
        }

        function test_getColorByIndexValid() {
            compare(testColorPicker.getColorByIndex(0), "#FFFFFF");
            compare(testColorPicker.getColorByIndex(1), "#EB6E67");
            compare(testColorPicker.getColorByIndex(2), "#F39C5A");
            compare(testColorPicker.getColorByIndex(3), "#F6C342");
            compare(testColorPicker.getColorByIndex(4), "#6CC1E1");
            compare(testColorPicker.getColorByIndex(10), "#45C486");
            compare(testColorPicker.getColorByIndex(11), "#9B6CC3");
        }

        function test_getColorByIndexInvalidReturnsFallback() {
            compare(testColorPicker.getColorByIndex(-1), "#FFFFFF");
            compare(testColorPicker.getColorByIndex(-10), "#FFFFFF");
            compare(testColorPicker.getColorByIndex(12), "#FFFFFF");
            compare(testColorPicker.getColorByIndex(100), "#FFFFFF");
        }

        function test_palettePickUpdatesStateAndEmitsSignal() {
            var targetIndex = 4;
            var targetColor = testColorPicker.getColorByIndex(targetIndex);

            testColorPicker.selectedColorIndex = targetIndex;
            testColorPicker.selectedColor = targetColor;
            testColorPicker.colorPicked(targetIndex, targetColor);

            compare(testColorPicker.selectedColorIndex, 4);
            compare(testColorPicker.selectedColor, "#6CC1E1");
            compare(colorPickedSpy.count, 1);
            compare(colorPickedSpy.signalArguments[0][0], 4);
            compare(colorPickedSpy.signalArguments[0][1], "#6CC1E1");
        }

        function test_customColorValueAssignment() {
            var customHex = "#AABBCC";
            testColorPicker.selectedColorIndex = 99;
            testColorPicker.selectedColor = customHex;

            compare(testColorPicker.selectedColorIndex, 99);
            compare(testColorPicker.selectedColor, "#AABBCC");

            testColorPicker.colorPicked(99, customHex);
            compare(colorPickedSpy.count, 1);
            compare(colorPickedSpy.signalArguments[0][0], 99);
            compare(colorPickedSpy.signalArguments[0][1], "#AABBCC");
        }

        function test_customPaletteOverride() {
            var customPalette = ["#111111", "#222222", "#333333"];
            testColorPicker.odooColors = customPalette;

            compare(testColorPicker.odooColors.length, 3);
            compare(testColorPicker.getColorByIndex(0), "#111111");
            compare(testColorPicker.getColorByIndex(1), "#222222");
            compare(testColorPicker.getColorByIndex(2), "#333333");
            compare(testColorPicker.getColorByIndex(3), "#FFFFFF");
        }

        function test_multipleSequentialColorPicks() {
            testColorPicker.colorPicked(1, "#EB6E67");
            testColorPicker.colorPicked(5, "#854D76");
            testColorPicker.colorPicked(9, "#DE3F7C");

            compare(colorPickedSpy.count, 3);
            compare(colorPickedSpy.signalArguments[0][0], 1);
            compare(colorPickedSpy.signalArguments[0][1], "#EB6E67");
            compare(colorPickedSpy.signalArguments[1][0], 5);
            compare(colorPickedSpy.signalArguments[1][1], "#854D76");
            compare(colorPickedSpy.signalArguments[2][0], 9);
            compare(colorPickedSpy.signalArguments[2][1], "#DE3F7C");
        }

        function test_openMethodExecution() {
            testColorPicker.open();
            testColorPicker.open(2);
            verify(testColorPicker !== null);
        }
    }
}
