import QtQuick 2.7
import QtTest 1.0
import QtGraphicalEffects 1.0
import Lomiri.Components 1.3
import "../../models/constants.js" as AppConst
import "../../qml/components/base"

Item {
    id: testRoot
    width: units.gu(40)
    height: units.gu(70)

    TSIconButton {
        id: testButton
    }

    SignalSpy {
        id: clickedSpy
        target: testButton
        signalName: "clicked"
    }

    TestCase {
        name: "TSIconButtonTests"
        when: windowShown

        // Helper to retrieve the button background Rectangle
        function findButtonRect() {
            if (testButton.children && testButton.children.length > 0) {
                return testButton.children[0];
            }
            return null;
        }

        // Helper to retrieve the Icon component
        function findIcon() {
            var btn = findButtonRect();
            if (btn) {
                for (var i = 0; i < btn.children.length; i++) {
                    if (btn.children[i] instanceof Icon) {
                        return btn.children[i];
                    }
                }
            }
            return null;
        }

        // Helper to retrieve the ColorOverlay component
        function findColorOverlay() {
            var btn = findButtonRect();
            if (btn) {
                for (var i = 0; i < btn.children.length; i++) {
                    if (btn.children[i] instanceof ColorOverlay) {
                        return btn.children[i];
                    }
                }
            }
            return null;
        }

        // Helper to retrieve the fallback Text component
        function findFallbackText() {
            var btn = findButtonRect();
            if (btn) {
                for (var i = 0; i < btn.children.length; i++) {
                    if (btn.children[i] instanceof Text) {
                        return btn.children[i];
                    }
                }
            }
            return null;
        }

        // Helper to retrieve the MouseArea
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

        function cleanup() {
            testButton.iconName = "";
            testButton.iconText = "+";
            testButton.buttonSize = units.gu(5);
            testButton.iconSize = units.gu(3);
            testButton.iconBold = true;
            testButton.radius = Qt.binding(function() { return testButton.width / 2; });
            testButton.width = Qt.binding(function() { return testButton.buttonSize; });
            testButton.height = Qt.binding(function() { return testButton.buttonSize; });
            testButton.bgColor = AppConst.Colors.Button.toLowerCase();
            testButton.fgColor = AppConst.Colors.ButtonText;
            clickedSpy.clear();
        }

        // ── Initial State & Property Defaults ──

        function test_initialProperties() {
            compare(testButton.buttonSize, units.gu(5));
            compare(testButton.width, units.gu(5));
            compare(testButton.height, units.gu(5));
            compare(testButton.iconName, "");
            compare(testButton.iconText, "+");
            compare(testButton.iconSize, units.gu(3));
            compare(testButton.iconBold, true);
            compare(testButton.radius, units.gu(2.5));
            compare(testButton.bgColor, AppConst.Colors.Button.toLowerCase());
        }

        function test_initialVisualHierarchy() {
            var btnRect = findButtonRect();
            verify(btnRect !== null, "Button Rectangle should exist");
            compare(btnRect.radius, units.gu(2.5));

            var icon = findIcon();
            verify(icon !== null, "Icon element should exist");
            compare(icon.visible, false);

            var overlay = findColorOverlay();
            verify(overlay !== null, "ColorOverlay should exist");
            compare(overlay.visible, false);

            var fallback = findFallbackText();
            verify(fallback !== null, "Fallback Text should exist");
            compare(fallback.visible, true);
            compare(fallback.text, "+");
            compare(fallback.font.pixelSize, units.gu(3));
            compare(fallback.font.bold, true);

            var mouseArea = findMouseArea();
            verify(mouseArea !== null, "MouseArea should exist");
            compare(mouseArea.cursorShape, Qt.PointingHandCursor);
        }

        // ── Dimensions & Sizing ──

        function test_buttonSizeScaling() {
            var btnRect = findButtonRect();
            verify(btnRect !== null);

            // Scale to 6 GU
            testButton.buttonSize = units.gu(6);
            compare(testButton.buttonSize, units.gu(6));
            compare(testButton.width, units.gu(6));
            compare(testButton.height, units.gu(6));
            compare(testButton.radius, units.gu(3));
            compare(btnRect.radius, units.gu(3));

            // Scale to 4 GU
            testButton.buttonSize = units.gu(4);
            compare(testButton.buttonSize, units.gu(4));
            compare(testButton.width, units.gu(4));
            compare(testButton.height, units.gu(4));
            compare(testButton.radius, units.gu(2));
            compare(btnRect.radius, units.gu(2));
        }

        function test_iconSizeAndBoldModifications() {
            var icon = findIcon();
            var fallback = findFallbackText();
            verify(icon !== null);
            verify(fallback !== null);

            testButton.iconSize = units.gu(2);
            compare(testButton.iconSize, units.gu(2));
            compare(icon.width, units.gu(2));
            compare(icon.height, units.gu(2));
            compare(fallback.font.pixelSize, units.gu(2));

            testButton.iconBold = false;
            compare(testButton.iconBold, false);
            compare(fallback.font.bold, false);

            testButton.iconBold = true;
            compare(testButton.iconBold, true);
            compare(fallback.font.bold, true);
        }

        // ── Icon Source & Fallback Text ──

        function test_symbolicIconSource() {
            var icon = findIcon();
            var fallback = findFallbackText();
            verify(icon !== null);
            verify(fallback !== null);

            // Setting iconName shows Icon and hides fallback Text
            testButton.iconName = "add";
            compare(testButton.iconName, "add");
            compare(icon.name, "add");
            compare(icon.visible, true);
            compare(fallback.visible, false);

            // Changing iconName updates the Icon
            testButton.iconName = "edit";
            compare(testButton.iconName, "edit");
            compare(icon.name, "edit");
            compare(icon.visible, true);
            compare(fallback.visible, false);
        }

        function test_fallbackTextWhenIconNameEmpty() {
            var icon = findIcon();
            var fallback = findFallbackText();
            verify(icon !== null);
            verify(fallback !== null);

            testButton.iconName = "";
            testButton.iconText = "×";
            compare(testButton.iconText, "×");
            compare(fallback.text, "×");
            compare(fallback.visible, true);
            compare(icon.visible, false);

            testButton.iconText = "✓";
            compare(fallback.text, "✓");
            compare(fallback.visible, true);
        }

        function test_colorOverlayVisibilityWithIcon() {
            var overlay = findColorOverlay();
            verify(overlay !== null);

            // Hidden when no iconName
            testButton.iconName = "";
            compare(overlay.visible, false);

            // Visible when iconName is set
            testButton.iconName = "delete";
            compare(overlay.visible, true);

            // Hidden when iconName reset to empty
            testButton.iconName = "";
            compare(overlay.visible, false);
        }

        // ── Click Handling ──

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

        // ── Custom Colors & Radius ──

        function test_customColorsAndRadius() {
            var btnRect = findButtonRect();
            var icon = findIcon();
            var fallback = findFallbackText();
            verify(btnRect !== null);
            verify(icon !== null);
            verify(fallback !== null);

            testButton.bgColor = "#2563eb";
            compare(testButton.bgColor, "#2563eb");

            testButton.fgColor = "#ffffff";
            compare(testButton.fgColor, "#ffffff");
            compare(icon.color, "#ffffff");
            compare(fallback.color, "#ffffff");

            // Custom radius override
            testButton.radius = units.gu(1);
            compare(testButton.radius, units.gu(1));
            compare(btnRect.radius, units.gu(1));
        }
    }
}
