import QtQuick 2.7
import QtTest 1.0
import Lomiri.Components 1.3
import "../../qml/features/tasks/components"

MainView {
    id: testRoot
    width: units.gu(40)
    height: units.gu(20)

    MyTasksClosedIndicator {
        id: testIndicator
        width: testRoot.width
        height: units.gu(6)
    }

    TestCase {
        name: "MyTasksClosedIndicatorTests"
        when: windowShown

        function findChildByProperty(parentItem, propName, propValue) {
            if (!parentItem) return null;
            if (parentItem[propName] === propValue) return parentItem;
            for (var i = 0; i < (parentItem.children ? parentItem.children.length : 0); i++) {
                var found = findChildByProperty(parentItem.children[i], propName, propValue);
                if (found) return found;
            }
            return null;
        }

        function findTextItem(parentItem) {
            if (!parentItem) return null;
            if (parentItem.text !== undefined && parentItem.text.indexOf("closed/completed") !== -1) return parentItem;
            for (var i = 0; i < (parentItem.children ? parentItem.children.length : 0); i++) {
                var found = findTextItem(parentItem.children[i]);
                if (found) return found;
            }
            return null;
        }

        function test_initialVisualStructure() {
            verify(testIndicator !== null);
            compare(testIndicator.border.width, 1);
            verify(testIndicator.visible, true);
        }

        function test_textBadgeContent() {
            var textItem = findTextItem(testIndicator);
            verify(textItem !== null, "Badge label should be present");
            compare(textItem.text, "Showing closed/completed tasks");
            compare(textItem.font.bold, true);
            compare(textItem.font.pixelSize, units.gu(1.5));
        }

        function test_infoIconPresence() {
            var iconItem = findChildByProperty(testIndicator, "name", "info");
            verify(iconItem !== null, "Info icon should be present");
            compare(iconItem.width, units.gu(2));
            compare(iconItem.height, units.gu(2));
        }

        function test_dimensions() {
            testIndicator.width = units.gu(30);
            testIndicator.height = units.gu(5);
            compare(testIndicator.width, units.gu(30));
            compare(testIndicator.height, units.gu(5));
        }
    }
}
