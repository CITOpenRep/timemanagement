import QtQuick 2.7
import QtTest 1.0
import Lomiri.Components 1.3
import "../../models/constants.js" as AppConst
import "../../qml/components/base"

Item {
    id: testRoot
    width: units.gu(40)
    height: units.gu(70)

    TSButton {
        id: testButton
        width: testRoot.width
    }

    SignalSpy {
        id: clickedSpy
        target: testButton
        signalName: "clicked"
    }

    TestCase {
        name: "TSButtonTests"
        when: windowShown

        // Helper to retrieve the button background Rectangle
        function findButtonRect() {
            if (testButton.children && testButton.children.length > 0) {
                return testButton.children[0];
            }
            return null;
        }

        // Helper to retrieve the content Row inside buttonRect
        function findContentRow() {
            var btn = findButtonRect();
            if (btn) {
                for (var i = 0; i < btn.children.length; i++) {
                    if (btn.children[i] instanceof Row) {
                        return btn.children[i];
                    }
                }
            }
            return null;
        }

        // Helper to retrieve the MouseArea inside buttonRect
        function findMouseArea() {
            var btn = findButtonRect();
            if (btn) {
                for (var i = 0; i < btn.children.length; i++) {
                    if (btn.children[i] instanceof MouseArea) {
                        return btn.children[i];
                    }
                }
            }
            return null;
        }

        // Helper to retrieve the built-in Icon inside contentRow
        function findBuiltinIcon() {
            var row = findContentRow();
            if (row) {
                for (var i = 0; i < row.children.length; i++) {
                    if (row.children[i] instanceof Icon) {
                        return row.children[i];
                    }
                }
            }
            return null;
        }

        // Helper to retrieve the custom Image icon inside contentRow
        function findCustomIcon() {
            var row = findContentRow();
            if (row) {
                for (var i = 0; i < row.children.length; i++) {
                    if (row.children[i] instanceof Image) {
                        return row.children[i];
                    }
                }
            }
            return null;
        }

        // Helper to retrieve the Text label inside contentRow
        function findLabel() {
            var row = findContentRow();
            if (row) {
                for (var i = 0; i < row.children.length; i++) {
                    if (row.children[i] instanceof Text) {
                        return row.children[i];
                    }
                }
            }
            return null;
        }

        function cleanup() {
            testButton.text = "";
            testButton.fontSize = units.gu(1.5);
            testButton.fontBold = false;
            testButton.enabled = true;
            testButton.width = testRoot.width;
            testButton.height = units.gu(5);
            testButton.iconName = "";
            testButton.iconSource = "";
            testButton.iconSize = units.gu(1.5);
            testButton.iconBold = false;
            testButton.spacing = units.gu(1);
            testButton.radius = units.gu(0.8);
            testButton.borderColor = "transparent";
            testButton.fgColor = AppConst.Colors.ButtonText;
            testButton.hoverColor = AppConst.Colors.ButtonHover;
            testButton.bgColor = Qt.binding(function() {
                return (testButton.enabled) ? AppConst.Colors.Button : AppConst.Colors.ButtonDisabled;
            });
            testButton.iconColor = Qt.binding(function() {
                return testButton.fgColor;
            });
            clickedSpy.clear();
        }

        // ── Initial State & Property Defaults ──

        function test_initialProperties() {
            compare(testButton.text, "");
            compare(testButton.fontSize, units.gu(1.5));
            compare(testButton.fontBold, false);
            compare(testButton.enabled, true);
            compare(testButton.height, units.gu(5));
            compare(testButton.width, testRoot.width);
            compare(testButton.iconName, "");
            compare(testButton.iconSource, "");
            compare(testButton.iconSize, units.gu(1.5));
            compare(testButton.iconBold, false);
            compare(testButton.spacing, units.gu(1));
            compare(testButton.radius, units.gu(0.8));
            compare(testButton.bgColor, AppConst.Colors.Button.toLowerCase());
            compare(testButton.fgColor, "#ffffff");
            compare(testButton.hoverColor, AppConst.Colors.ButtonHover.toLowerCase());
            compare(testButton.borderColor, "#00000000");
        }

        function test_initialVisualHierarchy() {
            var btnRect = findButtonRect();
            verify(btnRect !== null, "Button Rectangle should exist");
            compare(btnRect.radius, units.gu(0.8));

            var contentRow = findContentRow();
            verify(contentRow !== null, "Content Row should exist");
            compare(contentRow.spacing, units.gu(1));

            var builtinIcon = findBuiltinIcon();
            verify(builtinIcon !== null, "Builtin Icon should exist");
            compare(builtinIcon.visible, false);

            var customIcon = findCustomIcon();
            verify(customIcon !== null, "Custom Image icon should exist");
            compare(customIcon.visible, false);

            var label = findLabel();
            verify(label !== null, "Label Text should exist");
            compare(label.visible, false);
            compare(label.text, "");

            var mouseArea = findMouseArea();
            verify(mouseArea !== null, "MouseArea should exist");
            compare(mouseArea.hoverEnabled, true);
        }

        // ── Click Interactions & Signal Emissions ──

        function test_clickSignalEmission() {
            var mouseArea = findMouseArea();
            verify(mouseArea !== null);

            clickedSpy.clear();
            mouseClick(mouseArea);
            compare(clickedSpy.count, 1);
        }

        function test_multipleClicks() {
            var mouseArea = findMouseArea();
            verify(mouseArea !== null);

            clickedSpy.clear();
            mouseClick(mouseArea);
            mouseClick(mouseArea);
            mouseClick(mouseArea);
            compare(clickedSpy.count, 3);
        }

        // ── Disabled State Styling ──

        function test_disabledStateBgColor() {
            compare(testButton.enabled, true);
            compare(testButton.bgColor, AppConst.Colors.Button.toLowerCase());

            testButton.enabled = false;
            compare(testButton.enabled, false);
            compare(testButton.bgColor, "#808080");

            testButton.enabled = true;
            compare(testButton.enabled, true);
            compare(testButton.bgColor, AppConst.Colors.Button.toLowerCase());
        }

        // ── Text & Typography ──

        function test_textPropertyAndVisibility() {
            var label = findLabel();
            verify(label !== null);

            compare(label.visible, false);

            testButton.text = "Confirm Action";
            compare(testButton.text, "Confirm Action");
            compare(label.text, "Confirm Action");
            compare(label.visible, true);

            testButton.text = "Cancel";
            compare(label.text, "Cancel");
            compare(label.visible, true);

            testButton.text = "";
            compare(label.visible, false);
        }

        function test_fontPropertiesAliases() {
            var label = findLabel();
            verify(label !== null);

            testButton.fontSize = units.gu(2.5);
            compare(testButton.fontSize, units.gu(2.5));
            compare(label.font.pixelSize, units.gu(2.5));

            testButton.fontBold = true;
            compare(testButton.fontBold, true);
            compare(label.font.bold, true);

            testButton.fontBold = false;
            compare(testButton.fontBold, false);
            compare(label.font.bold, false);
        }

        // ── Icon Handling (Built-in vs Custom) ──

        function test_builtinIconName() {
            var builtinIcon = findBuiltinIcon();
            var customIcon = findCustomIcon();
            verify(builtinIcon !== null);
            verify(customIcon !== null);

            testButton.iconName = "add";
            compare(testButton.iconName, "add");
            compare(builtinIcon.name, "add");
            compare(builtinIcon.visible, true);
            compare(customIcon.visible, false);

            testButton.iconName = "delete";
            compare(builtinIcon.name, "delete");
            compare(builtinIcon.visible, true);

            testButton.iconName = "";
            compare(builtinIcon.visible, false);
        }

        function test_customIconSource() {
            var builtinIcon = findBuiltinIcon();
            var customIcon = findCustomIcon();
            verify(builtinIcon !== null);
            verify(customIcon !== null);

            testButton.iconName = "";
            testButton.iconSource = "qrc:///images/custom_icon.png";
            compare(testButton.iconSource, "qrc:///images/custom_icon.png");
            compare(customIcon.source, "qrc:///images/custom_icon.png");
            compare(customIcon.visible, true);
            compare(builtinIcon.visible, false);

            testButton.iconSource = "";
            compare(customIcon.visible, false);
        }

        function test_iconPrecedenceBuiltinOverCustom() {
            var builtinIcon = findBuiltinIcon();
            var customIcon = findCustomIcon();
            verify(builtinIcon !== null);
            verify(customIcon !== null);

            testButton.iconName = "edit";
            testButton.iconSource = "qrc:///images/edit.png";

            // Built-in icon takes precedence over custom icon
            compare(builtinIcon.visible, true);
            compare(customIcon.visible, false);

            // Removing iconName allows custom icon to show
            testButton.iconName = "";
            compare(builtinIcon.visible, false);
            compare(customIcon.visible, true);
        }

        function test_iconSizeAndBold() {
            var builtinIcon = findBuiltinIcon();
            var customIcon = findCustomIcon();
            verify(builtinIcon !== null);
            verify(customIcon !== null);

            testButton.iconName = "search";
            compare(builtinIcon.width, units.gu(1.5));
            compare(builtinIcon.height, units.gu(1.5));

            // Custom size
            testButton.iconSize = units.gu(2);
            compare(builtinIcon.width, units.gu(2));
            compare(builtinIcon.height, units.gu(2));

            // Bold increases size by 1.2
            testButton.iconBold = true;
            compare(builtinIcon.width, units.gu(2) * 1.2);
            compare(builtinIcon.height, units.gu(2) * 1.2);

            // Switching to custom icon
            testButton.iconName = "";
            testButton.iconSource = "qrc:///images/search.png";
            compare(customIcon.width, units.gu(2) * 1.2);
            compare(customIcon.opacity, 1.0);

            testButton.iconBold = false;
            compare(customIcon.width, units.gu(2));
            compare(customIcon.opacity, 0.9);
        }

        // ── Custom Colors & Styling ──

        function test_customColorsAndStyling() {
            var btnRect = findButtonRect();
            var label = findLabel();
            var contentRow = findContentRow();
            verify(btnRect !== null);
            verify(label !== null);
            verify(contentRow !== null);

            testButton.text = "Styled Button";
            testButton.bgColor = "#2563eb";
            testButton.fgColor = "#f8fafc";
            testButton.borderColor = "#1d4ed8";
            testButton.radius = units.gu(1.2);
            testButton.spacing = units.gu(2);

            compare(testButton.bgColor, "#2563eb");
            compare(testButton.fgColor, "#f8fafc");
            compare(label.color, "#f8fafc");
            compare(testButton.borderColor, "#1d4ed8");
            compare(btnRect.border.color, "#1d4ed8");
            compare(testButton.radius, units.gu(1.2));
            compare(btnRect.radius, units.gu(1.2));
            compare(testButton.spacing, units.gu(2));
            compare(contentRow.spacing, units.gu(2));
        }
    }
}
