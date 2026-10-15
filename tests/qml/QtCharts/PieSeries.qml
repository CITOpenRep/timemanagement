import QtQuick 2.7

Item {
    id: pieSeries
    property real size: 0.6
    property real holeSize: 0.3
    property real horizontalPosition: 0.5
    property real verticalPosition: 0.5
    property var slices: []
    readonly property int count: slices.length

    signal hovered(var slice, bool state)

    function clear() {
        slices = [];
    }

    function append(label, value) {
        var comp = Qt.createComponent("PieSlice.qml");
        var startA = 0;
        if (slices.length > 0) {
            var last = slices[slices.length - 1];
            startA = last.startAngle + last.angleSpan;
        }

        var sliceObj = comp.createObject(pieSeries, {
            label: label,
            value: value,
            startAngle: startA,
            angleSpan: 45
        });

        slices.push(sliceObj);
        return sliceObj;
    }

    function at(index) {
        if (index >= 0 && index < slices.length) return slices[index];
        return null;
    }

    function find(label) {
        for (var i = 0; i < slices.length; i++) {
            if (slices[i].label === label) return slices[i];
        }
        return null;
    }
}
