import QtQuick 2.7

QtObject {
    id: slice

    enum LabelPosition {
        LabelOutside,
        LabelInsideHorizontal,
        LabelInsideTangential,
        LabelInsideNormal,
        LabelArm
    }

    property string label: ""
    property real value: 0
    property bool exploded: false
    property int labelPosition: 0
    property bool labelVisible: false
    property color color: "blue"
    property real startAngle: 0
    property real angleSpan: 0
}
