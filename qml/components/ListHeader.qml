import QtQuick 2.7
import QtQuick.Controls 2.2
import QtGraphicalEffects 1.0

Rectangle {
    id: topFilterBar
    width: parent ? parent.width : Screen.width
    height: showSearchBox ? units.gu(11) : units.gu(6) // Dynamic height based on search visibility
    color: "#E0E0E0"

    //  anchors.margins: units.gu(0.5)
    //  anchors.leftMargin: units.gu(1)
    //  anchors.rightMargin: units.gu(1)

    // Exposed properties for external customization
    property string label1: "Today"
    property string label2: "Next Week"
    property string label3: "Next Month"
    property string label4: "OverDue"
    property string label5: "All"

    property string filter1: "today"
    property string filter2: "next_week"
    property string filter3: "next_month"
    property string filter4: "overdue"
    property string filter5: "all"

    property bool showSearchBox: true
    property string currentFilter: filter1  // Track currently selected filter

    signal filterSelected(string filterKey)
    signal customSearch(string query)

    // Add function to toggle search visibility
    function toggleSearchVisibility() {
        showSearchBox = !showSearchBox;
    }

    // Add function to clear search and reset filters
    function clearSearch() {
        searchField.text = "";
        customSearch("");
    }

    Column {
        id: mainColumn
        anchors.fill: parent
        spacing: 0

        // Search field at the top
        Rectangle {
            visible: topFilterBar.showSearchBox
            height: units.gu(5)
            width: parent.width
            anchors.left: parent.left
            anchors.right: parent.right
            //  anchors.margins: units.gu(0.5)
            color: "#F5F5F5"
            border.color: searchField.activeFocus ? "#FF6B35" : "#CCCCCC"
            border.width: searchField.activeFocus ? 2 : 1

            TextField {
                id: searchField
                anchors.fill: parent
                anchors.rightMargin: units.gu(4) // Space for clear button
                placeholderText: "Search..."
                background: Rectangle {
                    color: "transparent"
                }
                color: "#333333"
                placeholderTextColor: "#888888"
                selectByMouse: true
                onAccepted: topFilterBar.customSearch(text)
                onTextChanged: topFilterBar.customSearch(text)
            }

            Button {
                id: clearButton
                visible: searchField.text.length > 0
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.rightMargin: units.gu(0.5)
                width: units.gu(3)
                height: units.gu(3)
                text: "x"
                background: Rectangle {
                    color: "transparent"
                }
                contentItem: Text {
                    text: parent.text
                    color: "#888888"
                    font.pixelSize: units.gu(2)
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: topFilterBar.clearSearch()
            }
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
                    visible: (topFilterBar.label1) ? true : false
                    enabled: (topFilterBar.label1) ? true : false
                    height: units.gu(6) // Adjusted height
                    width: units.gu(12) // Increased width
                    property bool isHighlighted: topFilterBar.currentFilter === topFilterBar.filter1
                    background: Rectangle {
                        color: parent.isHighlighted ? "#F2EDE8" : "#E0E0E0"
                        border.color: parent.isHighlighted ? "#F2EDE8" : "#CCCCCC"
                        border.width: 1
                    }
                    contentItem: Text {
                        text: parent.text
                        color: parent.isHighlighted ? "#FF6B35" : "#8C7059"
                        font.bold: parent.isHighlighted
                        //  font.underline: parent.isHighlighted
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: {
                        topFilterBar.currentFilter = topFilterBar.filter1;
                        topFilterBar.filterSelected(topFilterBar.filter1);
                    }
                }

                Button {
                    text: topFilterBar.label2
                    visible: (topFilterBar.label2) ? true : false
                    enabled: (topFilterBar.label2) ? true : false
                    height: units.gu(6)
                    width: units.gu(12) // Increased width
                    property bool isHighlighted: topFilterBar.currentFilter === topFilterBar.filter2
                    background: Rectangle {
                        color: parent.isHighlighted ? "#F2EDE8" : "#E0E0E0"
                        border.color: parent.isHighlighted ? "#F2EDE8" : "#CCCCCC"
                        border.width: 1
                    }
                    contentItem: Text {
                        text: parent.text
                        color: parent.isHighlighted ? "#FF6B35" : "#8C7059"
                        font.bold: parent.isHighlighted
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: {
                        topFilterBar.currentFilter = topFilterBar.filter2;
                        topFilterBar.filterSelected(topFilterBar.filter2);
                    }
                }

                Button {
                    text: topFilterBar.label3
                    visible: (topFilterBar.label3) ? true : false
                    enabled: (topFilterBar.label3) ? true : false
                    height: units.gu(6)
                    width: units.gu(12) // Increased width
                    property bool isHighlighted: topFilterBar.currentFilter === topFilterBar.filter3
                    background: Rectangle {
                        color: parent.isHighlighted ? "#F2EDE8" : "#E0E0E0"
                        border.color: parent.isHighlighted ? "#F2EDE8" : "#CCCCCC"
                        border.width: 1
                    }
                    contentItem: Text {
                        text: parent.text
                        color: parent.isHighlighted ? "#FF6B35" : "#8C7059"
                        font.bold: parent.isHighlighted
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: {
                        topFilterBar.currentFilter = topFilterBar.filter3;
                        topFilterBar.filterSelected(topFilterBar.filter3);
                    }
                }

                Button {
                    text: topFilterBar.label4
                    visible: (topFilterBar.label4) ? true : false
                    enabled: (topFilterBar.label4) ? true : false
                    height: units.gu(6)
                    width: units.gu(12) // Increased width
                    property bool isHighlighted: topFilterBar.currentFilter === topFilterBar.filter4
                    background: Rectangle {
                        color: parent.isHighlighted ? "#F2EDE8" : "#E0E0E0"
                        border.color: parent.isHighlighted ? "#F2EDE8" : "#CCCCCC"
                        border.width: 1
                    }
                    contentItem: Text {
                        text: parent.text
                        color: parent.isHighlighted ? "#FF6B35" : "#8C7059"
                        // text.format: Text.PlainText
                        font.bold: parent.isHighlighted
                        //  font.pixelSize: units.gu(1.8)
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: {
                        topFilterBar.currentFilter = topFilterBar.filter4;
                        topFilterBar.filterSelected(topFilterBar.filter4);
                    }
                }

                Button {
                    text: topFilterBar.label5
                    visible: (topFilterBar.label5) ? true : false
                    enabled: (topFilterBar.label5) ? true : false
                    height: units.gu(6)
                    width: units.gu(12) // Increased width
                    property bool isHighlighted: topFilterBar.currentFilter === topFilterBar.filter5
                    background: Rectangle {
                        color: parent.isHighlighted ? "#F2EDE8" : "#E0E0E0"
                        border.color: parent.isHighlighted ? "#F2EDE8" : "#CCCCCC"
                        border.width: 1
                    }
                    contentItem: Text {
                        text: parent.text
                        color: parent.isHighlighted ? "#FF6B35" : "#8C7059"
                        // text.format: Text.PlainText
                        font.bold: parent.isHighlighted
                        //  font.pixelSize: units.gu(1.8)
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: {
                        topFilterBar.currentFilter = topFilterBar.filter5;
                        topFilterBar.filterSelected(topFilterBar.filter5);
                    }
                }
            }
        }
    }
}
