import QtQuick 2.7
import QtTest 1.0
import Lomiri.Components 1.3
import "../../qml/components/base"

Item {
    id: testRoot
    width: units.gu(40)
    height: units.gu(70)

    TSProgressbar {
        id: testProgressBar
        width: testRoot.width
    }

    TestCase {
        name: "TSProgressbarTests"
        when: windowShown

        // Helper to retrieve the background Rectangle
        function findBackgroundRect() {
            if (testProgressBar.children && testProgressBar.children.length > 0) {
                return testProgressBar.children[0];
            }
            return null;
        }

        // Helper to retrieve the inner progress fill Rectangle
        function findFillRect() {
            var bg = findBackgroundRect();
            if (bg && bg.children && bg.children.length > 0) {
                return bg.children[0];
            }
            return null;
        }

        function init() {
            testProgressBar.width = testRoot.width;
            testProgressBar.height = units.gu(1);
            testProgressBar.minimumValue = 0;
            testProgressBar.maximumValue = 100;
            testProgressBar.value = 40;
        }

        // ── Initial State & Property Defaults ──

        function test_initialProperties() {
            compare(testProgressBar.minimumValue, 0);
            compare(testProgressBar.maximumValue, 100);
            compare(testProgressBar.value, 40);
            compare(testProgressBar.visible, true);
            compare(testProgressBar.height, units.gu(1));
            compare(testProgressBar.width, testRoot.width);
        }

        function test_initialVisualHierarchy() {
            var bgRect = findBackgroundRect();
            verify(bgRect !== null, "Background Rectangle should exist");
            compare(bgRect.radius, testProgressBar.height / 2);

            var fillRect = findFillRect();
            verify(fillRect !== null, "Fill Rectangle should exist");
            compare(fillRect.color, LomiriColors.orange);
            compare(fillRect.height, testProgressBar.height);
            compare(fillRect.radius, testProgressBar.height / 2);

            // Initial width: (40 - 0) / (100 - 0) * testProgressBar.width = 0.4 * width
            verify(Math.abs(fillRect.width - 0.4 * testProgressBar.width) < 0.001,
                   "Initial fill width should be 40% of parent width");
        }

        // ── Progress Value Bounds (0 - 100) ──

        function test_progressValueAtLowerBoundZero() {
            testProgressBar.value = 0;
            compare(testProgressBar.value, 0);

            var fillRect = findFillRect();
            verify(fillRect !== null);
            compare(fillRect.width, 0);
        }

        function test_progressValueAtUpperBoundHundred() {
            testProgressBar.value = 100;
            compare(testProgressBar.value, 100);

            var fillRect = findFillRect();
            verify(fillRect !== null);
            compare(fillRect.width, testProgressBar.width);
        }

        function test_progressValueMidRange() {
            var fillRect = findFillRect();
            verify(fillRect !== null);

            testProgressBar.value = 25;
            compare(testProgressBar.value, 25);
            verify(Math.abs(fillRect.width - 0.25 * testProgressBar.width) < 0.001);

            testProgressBar.value = 50;
            compare(testProgressBar.value, 50);
            verify(Math.abs(fillRect.width - 0.5 * testProgressBar.width) < 0.001);

            testProgressBar.value = 75;
            compare(testProgressBar.value, 75);
            verify(Math.abs(fillRect.width - 0.75 * testProgressBar.width) < 0.001);
        }

        function test_progressValueBelowLowerBoundClamped() {
            // Negative values below minimumValue (0) must clamp to width 0 via Math.max(0, ...)
            testProgressBar.value = -10;
            compare(testProgressBar.value, -10);

            var fillRect = findFillRect();
            verify(fillRect !== null);
            compare(fillRect.width, 0);

            testProgressBar.value = -100;
            compare(fillRect.width, 0);
        }

        function test_progressValueDecimalPoints() {
            var fillRect = findFillRect();
            verify(fillRect !== null);

            testProgressBar.value = 12.5;
            compare(testProgressBar.value, 12.5);
            verify(Math.abs(fillRect.width - 0.125 * testProgressBar.width) < 0.001);

            testProgressBar.value = 99.5;
            compare(testProgressBar.value, 99.5);
            verify(Math.abs(fillRect.width - 0.995 * testProgressBar.width) < 0.001);
        }

        // ── setValue() Method & Bound Enforcement ──

        function test_setValueNormalRange() {
            var fillRect = findFillRect();
            verify(fillRect !== null);

            testProgressBar.setValue(50, 100);
            compare(testProgressBar.value, 50);
            compare(testProgressBar.maximumValue, 100);
            verify(Math.abs(fillRect.width - 0.5 * testProgressBar.width) < 0.001);

            testProgressBar.setValue(20, 100);
            compare(testProgressBar.value, 20);
            compare(testProgressBar.maximumValue, 100);
            verify(Math.abs(fillRect.width - 0.2 * testProgressBar.width) < 0.001);
        }

        function test_setValueAtLowerBoundZero() {
            testProgressBar.setValue(0, 100);
            compare(testProgressBar.value, 0);
            compare(testProgressBar.maximumValue, 100);

            var fillRect = findFillRect();
            verify(fillRect !== null);
            compare(fillRect.width, 0);
        }

        function test_setValueAtUpperBoundHundred() {
            testProgressBar.setValue(100, 100);
            compare(testProgressBar.value, 100);
            compare(testProgressBar.maximumValue, 100);

            var fillRect = findFillRect();
            verify(fillRect !== null);
            compare(fillRect.width, testProgressBar.width);
        }

        function test_setValueCapsAtMaximumWhenExceeded() {
            // setValue uses Math.min(newValue, maximumValue), capping values > max
            testProgressBar.setValue(150, 100);
            compare(testProgressBar.value, 100);
            compare(testProgressBar.maximumValue, 100);

            var fillRect = findFillRect();
            verify(fillRect !== null);
            compare(fillRect.width, testProgressBar.width);

            testProgressBar.setValue(500, 100);
            compare(testProgressBar.value, 100);
            compare(fillRect.width, testProgressBar.width);
        }

        function test_setValueWithCustomMax() {
            var fillRect = findFillRect();
            verify(fillRect !== null);

            testProgressBar.setValue(25, 50);
            compare(testProgressBar.value, 25);
            compare(testProgressBar.maximumValue, 50);
            verify(Math.abs(fillRect.width - 0.5 * testProgressBar.width) < 0.001);

            testProgressBar.setValue(50, 50);
            compare(testProgressBar.value, 50);
            compare(testProgressBar.maximumValue, 50);
            compare(fillRect.width, testProgressBar.width);

            // Exceeding custom max is capped
            testProgressBar.setValue(80, 50);
            compare(testProgressBar.value, 50);
            compare(testProgressBar.maximumValue, 50);
            compare(fillRect.width, testProgressBar.width);
        }

        function test_setValueWithInvalidNewValueNaN() {
            testProgressBar.value = 75;
            testProgressBar.maximumValue = 100;

            testProgressBar.setValue(NaN, 100);
            compare(testProgressBar.value, 0);
            compare(testProgressBar.maximumValue, 100);

            var fillRect = findFillRect();
            verify(fillRect !== null);
            compare(fillRect.width, 0);
        }

        function test_setValueWithInvalidNewMaxNaN() {
            testProgressBar.value = 75;
            testProgressBar.maximumValue = 100;

            testProgressBar.setValue(50, NaN);
            compare(testProgressBar.value, 0);
            compare(testProgressBar.maximumValue, 100);

            var fillRect = findFillRect();
            verify(fillRect !== null);
            compare(fillRect.width, 0);
        }

        function test_setValueWithZeroOrNegativeMax() {
            testProgressBar.value = 75;
            testProgressBar.maximumValue = 100;

            // newMax <= 0 should reset value to 0 and maximumValue to 100
            testProgressBar.setValue(50, 0);
            compare(testProgressBar.value, 0);
            compare(testProgressBar.maximumValue, 100);

            testProgressBar.setValue(50, -20);
            compare(testProgressBar.value, 0);
            compare(testProgressBar.maximumValue, 100);
        }

        // ── Visibility Logic (maximumValue > 0) ──

        function test_visibilityWhenMaxPositive() {
            testProgressBar.maximumValue = 100;
            compare(testProgressBar.visible, true);

            testProgressBar.maximumValue = 1;
            compare(testProgressBar.visible, true);

            testProgressBar.maximumValue = 50;
            compare(testProgressBar.visible, true);
        }

        function test_visibilityWhenMaxZeroOrNegative() {
            testProgressBar.maximumValue = 0;
            compare(testProgressBar.visible, false);

            testProgressBar.maximumValue = -10;
            compare(testProgressBar.visible, false);

            // Re-enabling with positive max restores visibility
            testProgressBar.maximumValue = 100;
            compare(testProgressBar.visible, true);
        }

        // ── Custom Minimum and Maximum Range ──

        function test_customMinMaxRange() {
            testProgressBar.minimumValue = 50;
            testProgressBar.maximumValue = 150;

            var fillRect = findFillRect();
            verify(fillRect !== null);

            // Value at custom minimum (50) -> 0% fill
            testProgressBar.value = 50;
            compare(fillRect.width, 0);

            // Value midway (100) -> 50% fill: (100 - 50) / (150 - 50) = 50 / 100 = 0.5
            testProgressBar.value = 100;
            verify(Math.abs(fillRect.width - 0.5 * testProgressBar.width) < 0.001);

            // Value at custom maximum (150) -> 100% fill
            testProgressBar.value = 150;
            compare(fillRect.width, testProgressBar.width);
        }

        // ── Responsive Dimensions & Scaling ──

        function test_responsiveWidthScaling() {
            var fillRect = findFillRect();
            verify(fillRect !== null);

            testProgressBar.value = 50;

            testProgressBar.width = units.gu(20);
            verify(Math.abs(fillRect.width - units.gu(10)) < 0.001);

            testProgressBar.width = units.gu(30);
            verify(Math.abs(fillRect.width - units.gu(15)) < 0.001);
        }

        function test_heightAndRadiusChanges() {
            var bgRect = findBackgroundRect();
            var fillRect = findFillRect();
            verify(bgRect !== null);
            verify(fillRect !== null);

            testProgressBar.height = units.gu(2);
            compare(bgRect.radius, units.gu(1));
            compare(fillRect.height, units.gu(2));
            compare(fillRect.radius, units.gu(1));
        }
    }
}
