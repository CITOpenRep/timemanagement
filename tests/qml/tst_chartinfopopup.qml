import QtQuick 2.7
import QtTest 1.0
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import "../../qml/features/dashboard/components"

MainView {
    id: testRoot
    width: units.gu(50)
    height: units.gu(70)

    ChartInfoPopup {
        id: testPopup
    }

    TestCase {
        name: "ChartInfoPopupTests"
        when: windowShown

        function findLabels(item) {
            var labels = [];
            function traverse(current) {
                if (!current) return;
                if (current.text !== undefined && current.text !== "") {
                    labels.push(current.text);
                }
                for (var i = 0; i < (current.children ? current.children.length : 0); i++) {
                    traverse(current.children[i]);
                }
            }
            traverse(item);
            return labels;
        }

        function findButtonByText(root, text) {
            if (!root) return null;
            if (root.text && root.text.indexOf(text) !== -1) return root;
            for (var i = 0; i < (root.children ? root.children.length : 0); i++) {
                var found = findButtonByText(root.children[i], text);
                if (found) return found;
            }
            return null;
        }

        function test_initialProperties() {
            compare(testPopup.title, "Dashboard Charts Guide");
        }

        function test_guideSectionsContent() {
            var allTexts = findLabels(testPopup);
            verify(allTexts.length > 0, "Popup should contain guide text labels");

            var joined = allTexts.join(" ");
            verify(joined.indexOf("Welcome to the Dashboard") !== -1, "Should have welcome message");
            verify(joined.indexOf("Priority Matrix") !== -1, "Should have Priority Matrix guide");
            verify(joined.indexOf("Projectwise Time Spent") !== -1, "Should have Projectwise guide");
            verify(joined.indexOf("Task Drilldown") !== -1, "Should have Task Drilldown guide");
        }

        function test_gotItButton() {
            var btn = findButtonByText(testPopup, "Got it!");
            verify(btn !== null, "Got it! button should be present");
        }
    }
}
