import QtQuick 2.7
import QtQuick.Controls 2.2
import QtGraphicalEffects 1.0

Item {
    id: topFilterBar
    width: parent ? parent.width : Screen.width
    height: showSearchBox ? units.gu(10) : units.gu(6) // Dynamic height based on search visibility

    //  anchors.margins: units.gu(0.5)
    //  anchors.leftMargin: units.gu(1)
    //  anchors.rightMargin: units.gu(1)

    // Exposed properties for external customization
    property string label1: "Today"
    property string label2: "Next Week"
    property string label3: "Next Month"
    property string label4: "Later"

    property string filter1: "today"
    property string filter2: "next_week"
    property string filter3: "next_month"
    property string filter4: "later"

    property bool showSearchBox: true
    property string currentFilter: filter1  // Track currently selected filter

    signal filterSelected(string filterKey)
    signal customSearch(string query)

    // Add function to toggle search visibility
    function toggleSearchVisibility() {
        showSearchBox = !showSearchBox;
    }

    Column {
        id: mainColumn
        anchors.fill: parent
        spacing: 0

        // Search field at the top
        TextField {
            id: searchField
            visible: topFilterBar.showSearchBox
            height: units.gu(4)
            width: parent.width
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: units.gu(0.5)
            placeholderText: "Search..."
            background: Rectangle {
                color: "#F5F5F5"
                border.color: searchField.activeFocus ? "#FF6B35" : "#CCCCCC"
                border.width: searchField.activeFocus ? 2 : 1
            }
            color: "#333333"
            placeholderTextColor: "#888888"
            selectByMouse: true
            onAccepted: topFilterBar.customSearch(text)
            onTextChanged: topFilterBar.customSearch(text)
        }

        // Filter buttons row below search
        Flickable {
            id: flickable
            width: parent.width
            height: units.gu(6)
            contentWidth: rowLayout.width
            contentHeight: rowLayout.height
            clip: true
            interactive: true
            flickableDirection: Flickable.HorizontalFlick

            Row {
                id: rowLayout
                spacing: 0 // Remove spacing between elements
                anchors.verticalCenter: parent.verticalCenter // Center vertically
                anchors.left: parent.left
               // anchors.leftMargin: units.gu(1)

                Button {
                    text: topFilterBar.label1
                    height: topFilterBar.height
                    width: units.gu(12) // Increased width
                    property bool isHighlighted: topFilterBar.currentFilter === topFilterBar.filter1
                    background: Rectangle {
                        color: parent.isHighlighted ? "#F2EDE8" : "#E0E0E0"
                        border.color: parent.isHighlighted ? "#F2EDE8" : "#CCCCCC"
                        border.width: 1
                    }
                    contentItem: Text {
                        text: parent.text
                        color: parent.isHighlighted ? "black" : "#8C7059"
                         font.bold: parent.isHighlighted
                       //  font.underline: parent.isHighlighted
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: {
                        topFilterBar.currentFilter = topFilterBar.filter1
                        topFilterBar.filterSelected(topFilterBar.filter1)
                    }
                }

                Button {
                    text: topFilterBar.label2
                    height: topFilterBar.height
                    width: units.gu(12) // Increased width
                    property bool isHighlighted: topFilterBar.currentFilter === topFilterBar.filter2
                      background: Rectangle {
                        color: parent.isHighlighted ? "#F2EDE8" : "#E0E0E0"
                        border.color: parent.isHighlighted ? "#F2EDE8" : "#CCCCCC"
                        border.width: 1
                    }
                    contentItem: Text {
                        text: parent.text
                        color: parent.isHighlighted ? "black" : "#8C7059"
                         font.bold: parent.isHighlighted
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: {
                        topFilterBar.currentFilter = topFilterBar.filter2
                        topFilterBar.filterSelected(topFilterBar.filter2)
                    }
                }

                Button {
                    text: topFilterBar.label3
                    height: topFilterBar.height
                    width: units.gu(12) // Increased width
                    property bool isHighlighted: topFilterBar.currentFilter === topFilterBar.filter3
                       background: Rectangle {
                        color: parent.isHighlighted ? "#F2EDE8" : "#E0E0E0"
                        border.color: parent.isHighlighted ? "#F2EDE8" : "#CCCCCC"
                        border.width: 1
                    }
                    contentItem: Text {
                        text: parent.text
                        color: parent.isHighlighted ? "black" : "#8C7059"
                         font.bold: parent.isHighlighted
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: {
                        topFilterBar.currentFilter = topFilterBar.filter3
                        topFilterBar.filterSelected(topFilterBar.filter3)
                    }
                }

                Button {
                    text: topFilterBar.label4
                    height: topFilterBar.height
                    width: units.gu(12) // Increased width
                    property bool isHighlighted: topFilterBar.currentFilter === topFilterBar.filter4
                      background: Rectangle {
                        color: parent.isHighlighted ? "#F2EDE8" : "#E0E0E0"
                        border.color: parent.isHighlighted ? "#F2EDE8" : "#CCCCCC"
                        border.width: 1
                    }
                    contentItem: Text {
                        text: parent.text
                       color: parent.isHighlighted ? "black" : "#8C7059"
                       // text.format: Text.PlainText
                        font.bold: parent.isHighlighted
                      //  font.pixelSize: units.gu(1.8)
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: {
                        topFilterBar.currentFilter = topFilterBar.filter4
                        topFilterBar.filterSelected(topFilterBar.filter4)
                    }
                }
            }
        }
    }
}
