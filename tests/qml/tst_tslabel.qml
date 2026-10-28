import QtQuick 2.7
import QtTest 1.0
import Lomiri.Components 1.3
import "../../qml/components/base"

Item {
    id: testRoot
    width: units.gu(40)
    height: units.gu(70)

    TSLabel {
        id: testLabel
    }

    property int defaultFontSize: testLabel.fontSize

    TestCase {
        name: "TSLabelTests"
        when: windowShown

        // Helper to retrieve the inner Label component
        function findInnerLabel() {
            if (testLabel.children && testLabel.children.length > 0) {
                return testLabel.children[0];
            }
            return null;
        }

        function cleanup() {
            testLabel.text = "";
            testLabel.wrapMode = Text.WordWrap;
            testLabel.elide = Text.ElideRight;
            testLabel.maximumLineCount = 2;
            testLabel.color = "#000000";
            testLabel.fontBold = false;
            testLabel.horizontalAlignment = Text.AlignLeft;
            testLabel.verticalAlignment = Text.AlignVCenter;
            testLabel.width = undefined;
            if (defaultFontSize > 0) {
                testLabel.fontSize = defaultFontSize;
            }
        }

        //Initial State & Property Defaults

        function test_initialProperties() {
            compare(testLabel.text, "");
            compare(testLabel.wrapMode, Text.WordWrap);
            compare(testLabel.elide, Text.ElideRight);
            compare(testLabel.maximumLineCount, 2);
            compare(testLabel.horizontalAlignment, Text.AlignLeft);
            compare(testLabel.verticalAlignment, Text.AlignVCenter);
            compare(testLabel.fontBold, false);
            compare(testLabel.aspect, LomiriShape.Flat);

            var innerLabel = findInnerLabel();
            verify(innerLabel !== null, "Inner Label should exist");
            compare(innerLabel.wrapMode, Text.WordWrap);
            compare(innerLabel.elide, Text.ElideRight);
            compare(innerLabel.maximumLineCount, 2);
        }

        //Text Wrapping Behavior

        function test_wrapModeWordWrap() {
            testLabel.wrapMode = Text.WordWrap;
            compare(testLabel.wrapMode, Text.WordWrap);

            var innerLabel = findInnerLabel();
            verify(innerLabel !== null);
            compare(innerLabel.wrapMode, Text.WordWrap);
        }

        function test_wrapModeNoWrap() {
            testLabel.wrapMode = Text.NoWrap;
            compare(testLabel.wrapMode, Text.NoWrap);

            var innerLabel = findInnerLabel();
            verify(innerLabel !== null);
            compare(innerLabel.wrapMode, Text.NoWrap);
        }

        function test_wrapModeWrapAnywhere() {
            testLabel.wrapMode = Text.WrapAnywhere;
            compare(testLabel.wrapMode, Text.WrapAnywhere);

            var innerLabel = findInnerLabel();
            verify(innerLabel !== null);
            compare(innerLabel.wrapMode, Text.WrapAnywhere);
        }

        function test_wrapModeWrap() {
            testLabel.wrapMode = Text.Wrap;
            compare(testLabel.wrapMode, Text.Wrap);

            var innerLabel = findInnerLabel();
            verify(innerLabel !== null);
            compare(innerLabel.wrapMode, Text.Wrap);
        }

        function test_maximumLineCount() {
            compare(testLabel.maximumLineCount, 2);

            testLabel.maximumLineCount = 1;
            compare(testLabel.maximumLineCount, 1);

            testLabel.maximumLineCount = 3;
            compare(testLabel.maximumLineCount, 3);

            testLabel.maximumLineCount = 5;
            compare(testLabel.maximumLineCount, 5);

            testLabel.maximumLineCount = 0;
            compare(testLabel.maximumLineCount, 0);

            var innerLabel = findInnerLabel();
            verify(innerLabel !== null);
            compare(innerLabel.maximumLineCount, 0);
        }

        function test_elideModes() {
            compare(testLabel.elide, Text.ElideRight);

            testLabel.elide = Text.ElideNone;
            compare(testLabel.elide, Text.ElideNone);

            testLabel.elide = Text.ElideLeft;
            compare(testLabel.elide, Text.ElideLeft);

            testLabel.elide = Text.ElideMiddle;
            compare(testLabel.elide, Text.ElideMiddle);

            testLabel.elide = Text.ElideRight;
            compare(testLabel.elide, Text.ElideRight);

            var innerLabel = findInnerLabel();
            verify(innerLabel !== null);
            compare(innerLabel.elide, Text.ElideRight);
        }

        function test_wrappingWithLongMultilineText() {
            testLabel.width = units.gu(15);
            testLabel.wrapMode = Text.WordWrap;
            testLabel.maximumLineCount = 3;
            testLabel.elide = Text.ElideRight;
            testLabel.text = "First long line of text that needs to wrap properly across multiple boundaries in the UI";

            compare(testLabel.wrapMode, Text.WordWrap);
            compare(testLabel.maximumLineCount, 3);
            compare(testLabel.elide, Text.ElideRight);
            compare(testLabel.text, "First long line of text that needs to wrap properly across multiple boundaries in the UI");
        }

        //Text Color

        function test_textColorHex() {
            testLabel.color = "#ff5722";
            compare(testLabel.color, "#ff5722");

            testLabel.color = "#00ff00";
            compare(testLabel.color, "#00ff00");

            testLabel.color = "#1e293b";
            compare(testLabel.color, "#1e293b");

            var innerLabel = findInnerLabel();
            verify(innerLabel !== null);
            compare(innerLabel.color, "#1e293b");
        }

        function test_textColorNamed() {
            testLabel.color = "red";
            compare(testLabel.color, "#ff0000");

            testLabel.color = "blue";
            compare(testLabel.color, "#0000ff");

            testLabel.color = "white";
            compare(testLabel.color, "#ffffff");

            testLabel.color = "transparent";
            compare(testLabel.color, "#00000000");
        }

        function test_textColorRgba() {
            testLabel.color = Qt.rgba(0.5, 0.2, 0.8, 1.0);
            compare(testLabel.color, "#8033cc");

            testLabel.color = Qt.rgba(1.0, 0.0, 0.0, 0.5);
            compare(testLabel.color, "#80ff0000");
        }

        //Text Content and Font Styling

        function test_textContent() {
            testLabel.text = "Task Summary";
            compare(testLabel.text, "Task Summary");

            testLabel.text = "";
            compare(testLabel.text, "");
        }

        function test_fontSize() {
            testLabel.fontSize = units.gu(2.4);
            compare(testLabel.fontSize, units.gu(2.4));

            testLabel.fontSize = units.gu(1.6);
            compare(testLabel.fontSize, units.gu(1.6));
        }

        function test_fontBold() {
            compare(testLabel.fontBold, false);

            testLabel.fontBold = true;
            compare(testLabel.fontBold, true);

            testLabel.fontBold = false;
            compare(testLabel.fontBold, false);
        }

        //Text Alignment

        function test_horizontalAlignment() {
            compare(testLabel.horizontalAlignment, Text.AlignLeft);

            testLabel.horizontalAlignment = Text.AlignHCenter;
            compare(testLabel.horizontalAlignment, Text.AlignHCenter);

            testLabel.horizontalAlignment = Text.AlignRight;
            compare(testLabel.horizontalAlignment, Text.AlignRight);

            testLabel.horizontalAlignment = Text.AlignJustify;
            compare(testLabel.horizontalAlignment, Text.AlignJustify);
        }

        function test_verticalAlignment() {
            compare(testLabel.verticalAlignment, Text.AlignVCenter);

            testLabel.verticalAlignment = Text.AlignTop;
            compare(testLabel.verticalAlignment, Text.AlignTop);

            testLabel.verticalAlignment = Text.AlignBottom;
            compare(testLabel.verticalAlignment, Text.AlignBottom);
        }
    }
}
