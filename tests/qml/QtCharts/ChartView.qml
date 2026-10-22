import QtQuick 2.7

Item {
    id: chartView

    default property alias children: contentArea.data

    property color backgroundColor: "transparent"
    property bool antialiasing: true
    property string title: ""

    property Margins margins: Margins {}
    property Legend legend: Legend {}

    property QtObject plotArea: QtObject {
        property real x: 0
        property real y: 0
        property real width: chartView.width
        property real height: chartView.height
    }

    Item {
        id: contentArea
        anchors.fill: parent
    }
}
