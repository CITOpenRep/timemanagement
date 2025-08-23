// components/ThemedLabel.qml
import QtQuick 2.7
import Lomiri.Components 1.3

LomiriShape {
    id: themedLabel
    width: implicitWidth
    height: implicitHeight
    aspect: LomiriShape.Flat

    property alias text: label.text
    property alias fontSize: label.font.pixelSize
    property alias horizontalAlignment: label.horizontalAlignment
    property alias verticalAlignment: label.verticalAlignment
    property alias fontBold: label.font.bold
    property alias wrapMode: label.wrapMode
    property alias elide: label.elide
    property alias maximumLineCount: label.maximumLineCount
    property alias color: label.color

    Label {
        id: label
        anchors.fill: parent
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignLeft
        wrapMode: Text.WordWrap
        elide: Text.ElideRight
        maximumLineCount: 2
    }
}
