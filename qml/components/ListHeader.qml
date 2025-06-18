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
                onClicked: topFilterBar.filterSelected(topFilterBar.filter1)
            }

            Button {
                text: topFilterBar.label2
                onClicked: topFilterBar.filterSelected(topFilterBar.filter2)
            }

            Button {
                text: topFilterBar.label3
                onClicked: topFilterBar.filterSelected(topFilterBar.filter3)
            }

            Button {
                text: topFilterBar.label4
                onClicked: topFilterBar.filterSelected(topFilterBar.filter4)
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
