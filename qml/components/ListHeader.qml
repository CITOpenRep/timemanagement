import QtQuick 2.7
import QtQuick.Controls 2.2
import QtGraphicalEffects 1.0

Item {
    id: topFilterBar
    width: parent ? parent.width : Screen.width
    height: flickable.height

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

    Flickable {
        id: flickable
        width: parent.width
        height: rowLayout.implicitHeight
        contentWidth: rowLayout.width
        contentHeight: rowLayout.height
        clip: true
        interactive: true
        flickableDirection: Flickable.HorizontalFlick

        Row {
            id: rowLayout
            spacing: units.gu(1)

            Button {
                text: topFilterBar.label1
                property bool isHighlighted: topFilterBar.currentFilter === topFilterBar.filter1
                background: Rectangle {
                    color: parent.isHighlighted ? "#FF6B35" : "#E0E0E0"
                    radius: units.gu(0.5)
                }
                contentItem: Text {
                    text: parent.text
                    color: parent.isHighlighted ? "white" : "black"
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
                property bool isHighlighted: topFilterBar.currentFilter === topFilterBar.filter2
                background: Rectangle {
                    color: parent.isHighlighted ? "#FF6B35" : "#E0E0E0"
                    radius: 5
                }
                contentItem: Text {
                    text: parent.text
                    color: parent.isHighlighted ? "white" : "black"
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
                property bool isHighlighted: topFilterBar.currentFilter === topFilterBar.filter3
                background: Rectangle {
                    color: parent.isHighlighted ? "#FF6B35" : "#E0E0E0"
                    radius: 5
                }
                contentItem: Text {
                    text: parent.text
                    color: parent.isHighlighted ? "white" : "black"
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
                property bool isHighlighted: topFilterBar.currentFilter === topFilterBar.filter4
                background: Rectangle {
                    color: parent.isHighlighted ? "#FF6B35" : "#E0E0E0"
                    radius: 5
                }
                contentItem: Text {
                    text: parent.text
                    color: parent.isHighlighted ? "white" : "black"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: {
                    topFilterBar.currentFilter = topFilterBar.filter4
                    topFilterBar.filterSelected(topFilterBar.filter4)
                }
            }

            TextField {
                id: searchField
                visible: topFilterBar.showSearchBox
                placeholderText: "Search..."
                onAccepted: topFilterBar.customSearch(text)
            }
        }
    }
}
