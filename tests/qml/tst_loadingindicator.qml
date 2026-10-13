import QtQuick 2.7
import QtTest 1.0
import Lomiri.Components 1.3
import "../../qml/components/feedback"

Item {
    id: testRoot
    width: units.gu(40)
    height: units.gu(70)

    LoadingIndicator {
        id: testIndicator
        anchors.fill: parent
        visible: false
    }

    TestCase {
        name: "LoadingIndicatorTests"
        when: windowShown

        function findActivityIndicator(rootItem) {
            for (var i = 0; i < rootItem.children.length; i++) {
                var child = rootItem.children[i];
                if (child.running !== undefined) {
                    return child;
                }
                var sub = findActivityIndicator(child);
                if (sub) return sub;
            }
            return null;
        }

        function findMessageLabel(rootItem) {
            for (var i = 0; i < rootItem.children.length; i++) {
                var child = rootItem.children[i];
                if (child.text !== undefined && child.fontSize !== undefined) {
                    return child;
                }
                var sub = findMessageLabel(child);
                if (sub) return sub;
            }
            return null;
        }

        function findOverlay(rootItem) {
            for (var i = 0; i < rootItem.children.length; i++) {
                var child = rootItem.children[i];
                if (child.color !== undefined && child.children && child.children.length > 0) {
                    for (var j = 0; j < child.children.length; j++) {
                        if (child.children[j].enabled !== undefined && child.children[j].onClicked !== undefined) {
                            return child;
                        }
                    }
                }
            }
            return null;
        }

        function init() {
            testIndicator.visible = false;
            testIndicator.message = "";
            testIndicator.overlayMode = true;
        }

        function cleanup() {
            testIndicator.visible = false;
            testIndicator.message = "";
            testIndicator.overlayMode = true;
        }

        function test_initialProperties() {
            compare(testIndicator.visible, false);
            compare(testIndicator.message, "");
            compare(testIndicator.overlayMode, true);
            compare(testIndicator.z, 999);
        }

        function test_visibilityAndRunningStateToggle() {
            var spinner = findActivityIndicator(testIndicator);
            verify(spinner !== null, "ActivityIndicator spinner must exist in component");

            // When visible is false, spinner is not running
            testIndicator.visible = false;
            compare(spinner.running, false);

            // When visible is true, spinner is running
            testIndicator.visible = true;
            compare(spinner.running, true);

            // Toggle back to false
            testIndicator.visible = false;
            compare(spinner.running, false);
        }

        function test_messagePropertyAndLabelVisibility() {
            testIndicator.visible = true;
            var label = findMessageLabel(testIndicator);
            verify(label !== null, "Message Label must exist in component");

            // Empty message hides label
            testIndicator.message = "";
            compare(label.visible, false);

            // Non-empty message shows label with correct text
            testIndicator.message = "Loading project data...";
            compare(label.visible, true);
            compare(label.text, "Loading project data...");

            // Clearing message hides label again
            testIndicator.message = "";
            compare(label.visible, false);
        }

        function test_overlayModeVisibility() {
            testIndicator.visible = true;
            var overlay = findOverlay(testIndicator);
            verify(overlay !== null, "Overlay Rectangle must exist in component");

            testIndicator.overlayMode = true;
            compare(overlay.visible, true);

            testIndicator.overlayMode = false;
            compare(overlay.visible, false);

            testIndicator.overlayMode = true;
            compare(overlay.visible, true);
        }

        function test_mouseAreaEnabledTracksVisibility() {
            var overlay = findOverlay(testIndicator);
            verify(overlay !== null);
            var mouseArea = overlay.children[0];
            verify(mouseArea !== null && mouseArea.enabled !== undefined);

            testIndicator.visible = false;
            compare(mouseArea.enabled, false);

            testIndicator.visible = true;
            compare(mouseArea.enabled, true);

            testIndicator.visible = false;
            compare(mouseArea.enabled, false);
        }
    }
}
