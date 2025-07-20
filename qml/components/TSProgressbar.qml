import QtQuick 2.7

Item {
    id: customProgressBar
    width: parent.width
    height: units.gu(1)

    property real minimumValue: 0
    property real maximumValue: 100
    property real value: 40
    visible: (maximumValue > 0) ? true : false

    function setValue(newValue, newMax) {
        if (isNaN(newValue) || isNaN(newMax) || newMax <= 0) {
            value = 0;
            maximumValue = 100; // reset to default if needed
        } else {
            maximumValue = newMax;
            value = Math.min(newValue, maximumValue);
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "#ddd"  // background color
        radius: height / 2

        Rectangle {
            width: Math.max(0, (value - minimumValue) / (maximumValue - minimumValue)) * parent.width
            height: parent.height
            color: "#ff4c4c"  // progress fill color
            radius: height / 2
        }
    }
}
