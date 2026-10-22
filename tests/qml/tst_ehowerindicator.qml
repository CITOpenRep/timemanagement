import QtQuick 2.7
import QtTest 1.0
import Lomiri.Components 1.3
import "../../qml/components/visualization"
import "../../models/constants.js" as AppConst

Item {
    id: testRoot
    width: units.gu(40)
    height: units.gu(40)

    EHowerIndicator {
        id: testIndicator
    }

    TestCase {
        name: "EHowerIndicatorTests"
        when: windowShown

        function init() {
            testIndicator.quadrantKey = "Do First (Important & Urgent )";
        }

        function cleanup() {
            testIndicator.quadrantKey = "Do First (Important & Urgent )";
        }

        function test_initialDefaultQ1() {
            compare(testIndicator.quadrantKey, "Do First (Important & Urgent )");
            compare(testIndicator.normalizedKey, "Do");
            verify(Qt.colorEqual(testIndicator.quadrantColor, AppConst.Colors.Quadrants.Q1));
            compare(testIndicator.text, "Do First (Important & Urgent )");
            verify(Qt.colorEqual(testIndicator.color, AppConst.Colors.Quadrants.Q1));
        }

        function test_doNextNormalizesToPlanQ2() {
            testIndicator.quadrantKey = "Do Next (Important & Not Urgent)";

            compare(testIndicator.normalizedKey, "Plan");
            verify(Qt.colorEqual(testIndicator.quadrantColor, AppConst.Colors.Quadrants.Q2));
            verify(Qt.colorEqual(testIndicator.color, AppConst.Colors.Quadrants.Q2));
            compare(testIndicator.text, "Do Next (Important & Not Urgent)");
        }

        function test_doLaterNormalizesToDelegateQ3() {
            testIndicator.quadrantKey = "Do Later (Not Important & Urgent)";

            compare(testIndicator.normalizedKey, "Delegate");
            verify(Qt.colorEqual(testIndicator.quadrantColor, AppConst.Colors.Quadrants.Q3));
            verify(Qt.colorEqual(testIndicator.color, AppConst.Colors.Quadrants.Q3));
            compare(testIndicator.text, "Do Later (Not Important & Urgent)");
        }

        function test_dontDoNormalizesToDeleteQ4() {
            testIndicator.quadrantKey = "Don't do (Not Important & Not Urgent)";

            compare(testIndicator.normalizedKey, "Delete");
            verify(Qt.colorEqual(testIndicator.quadrantColor, AppConst.Colors.Quadrants.Q4));
            verify(Qt.colorEqual(testIndicator.color, AppConst.Colors.Quadrants.Q4));
            compare(testIndicator.text, "Don't do (Not Important & Not Urgent)");
        }

        function test_unrecognizedKeyFallbackToPlan() {
            testIndicator.quadrantKey = "Custom Category Without Prefix";

            compare(testIndicator.normalizedKey, "Plan");
            verify(Qt.colorEqual(testIndicator.quadrantColor, AppConst.Colors.Quadrants.Q2));
            verify(Qt.colorEqual(testIndicator.color, AppConst.Colors.Quadrants.Q2));
        }

        function test_textTracksQuadrantKeyChanges() {
            testIndicator.quadrantKey = "Do First Task";
            compare(testIndicator.text, "Do First Task");

            testIndicator.quadrantKey = "Don't do Task";
            compare(testIndicator.text, "Don't do Task");
        }
    }
}
