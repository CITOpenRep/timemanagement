import QtQuick 2.7
import QtTest 1.0
import "../../models/constants.js" as Constants

Item {
    width: 200
    height: 200

    TestCase {
        name: "ConstantsTests"
        when: windowShown

        function test_version() {
            verify(Constants.version !== undefined);
            compare(typeof Constants.version, "string");
            verify(Constants.version.length > 0);
            compare(Constants.version, "1.3.3");
        }

        function test_fontSizesStructure() {
            verify(Constants.FontSizes !== undefined);
            compare(typeof Constants.FontSizes, "object");
            compare(Constants.FontSizes.ListHeading, 1.7);
            compare(Constants.FontSizes.ListSubHeading, 1.5);
            compare(Constants.FontSizes.ListSubSubHeading, 1.7);
        }

        function test_colorsBasePalette() {
            verify(Constants.Colors !== undefined);
            compare(Constants.Colors.StickyNote, "#F5F5F5");
            compare(Constants.Colors.Border, "#B0BEC5");
            compare(Constants.Colors.Shadow, "#55000000");
            compare(Constants.Colors.Button, "#E95420");
            compare(Constants.Colors.ButtonText, "white");
            compare(Constants.Colors.ButtonHover, "#d3481b");
            compare(Constants.Colors.Orange, "#E95420");
            compare(Constants.Colors.ButtonDisabled, "grey");
        }

        function test_quadrantColors() {
            verify(Constants.Colors.Quadrants !== undefined);
            compare(Constants.Colors.Quadrants.Q1, "#E53935");
            compare(Constants.Colors.Quadrants.Q2, "#1E88E5");
            compare(Constants.Colors.Quadrants.Q3, "#43A047");
            compare(Constants.Colors.Quadrants.Q4, "#757575");
            compare(Constants.Colors.Quadrants.Default, "transparent");
        }
    }
}
