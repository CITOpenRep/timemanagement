import QtQuick 2.7
import QtTest 1.0
import Lomiri.Components 1.3
import "../../qml/features/dashboard/components"

MainView {
    id: testRoot
    width: units.gu(50)
    height: units.gu(30)

    ProjectCard {
        id: testCard
        width: testRoot.width
    }

    SignalSpy {
        id: clickedSpy
        target: testCard
        signalName: "clicked"
    }

    TestCase {
        name: "ProjectCardTests"
        when: windowShown

        function init() {
            testCard.projectData = {};
            testCard.maxHours = 1;
            clickedSpy.clear();
        }

        function cleanup() {
            clickedSpy.clear();
        }

        function test_initialProperties() {
            compare(testCard.maxHours, 1);
            compare(testCard.implicitHeight, units.gu(11));
            compare(clickedSpy.count, 0);
        }

        function test_projectDataBinding() {
            testCard.projectData = {
                name: "Mobile App Port",
                taskCount: 8,
                totalHours: 24.0,
                colour: "#3498DB"
            };
            testCard.maxHours = 30.0;

            compare(testCard.projectData.name, "Mobile App Port");
            compare(testCard.projectData.taskCount, 8);
            compare(testCard.projectData.totalHours, 24.0);
            compare(testCard.projectColor, "#3498db");
        }

        function test_projectColorNearWhiteFallback() {
            testCard.projectData = {
                name: "White Theme Project",
                colour: "#FFFFFF"
            };
            compare(testCard.projectColor, "#e95420");
        }

        function test_clickedSignalEmission() {
            compare(clickedSpy.count, 0);
            mouseClick(testCard);
            compare(clickedSpy.count, 1);
        }
    }
}
