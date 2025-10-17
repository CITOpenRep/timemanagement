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

    // Dynamic filter model - array of {label, filterKey} objects
    property var filterModel: []

    // Legacy properties for backwards compatibility (deprecated)
    property string label1: ""
    property string label2: ""
    property string label3: ""
    property string label4: ""
    property string label5: ""
    property string label6: ""
    property string label7: ""

    property string filter1: ""
    property string filter2: ""
    property string filter3: ""
    property string filter4: ""
    property string filter5: ""
    property string filter6: ""
    property string filter7: ""

    property bool showSearchBox: true
    property string currentFilter: ""  // Track currently selected filter

    signal filterSelected(string filterKey)
    signal customSearch(string query)

    // Backward compatibility: Build filterModel from legacy properties
    Component.onCompleted: {
        buildFilterModelFromLegacyProperties();
    }

    // Watch for changes to legacy properties
    onLabel1Changed: Qt.callLater(buildFilterModelFromLegacyProperties)
    onLabel2Changed: Qt.callLater(buildFilterModelFromLegacyProperties)
    onLabel3Changed: Qt.callLater(buildFilterModelFromLegacyProperties)
    onLabel4Changed: Qt.callLater(buildFilterModelFromLegacyProperties)
    onLabel5Changed: Qt.callLater(buildFilterModelFromLegacyProperties)
    onLabel6Changed: Qt.callLater(buildFilterModelFromLegacyProperties)
    onLabel7Changed: Qt.callLater(buildFilterModelFromLegacyProperties)

    function buildFilterModelFromLegacyProperties() {
        // Only build from legacy properties if filterModel is empty or not explicitly set
        // This allows new API to take precedence
        if (filterModel.length > 0) {
            return; // New API is being used, don't override
        }

        var newModel = [];

        if (label1 !== "" && filter1 !== "") {
            newModel.push({
                label: label1,
                filterKey: filter1
            });
        }
        if (label2 !== "" && filter2 !== "") {
            newModel.push({
                label: label2,
                filterKey: filter2
            });
        }
        if (label3 !== "" && filter3 !== "") {
            newModel.push({
                label: label3,
                filterKey: filter3
            });
        }
        if (label4 !== "" && filter4 !== "") {
            newModel.push({
                label: label4,
                filterKey: filter4
            });
        }
        if (label5 !== "" && filter5 !== "") {
            newModel.push({
                label: label5,
                filterKey: filter5
            });
        }
        if (label6 !== "" && filter6 !== "") {
            newModel.push({
                label: label6,
                filterKey: filter6
            });
        }
        if (label7 !== "" && filter7 !== "") {
            newModel.push({
                label: label7,
                filterKey: filter7
            });
        }

        if (newModel.length > 0) {
            filterModel = newModel;
            if (currentFilter === "" && newModel.length > 0) {
                currentFilter = newModel[0].filterKey;
            }
        }
    }

    // Function to set filters dynamically
    function setFilters(filters) {
        filterModel = filters;
        if (filters.length > 0) {
            currentFilter = filters[0].filterKey;
        }
    }

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
                // onTextChanged: topFilterBar.customSearch(text)
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

                // Dynamic buttons using Repeater
                Repeater {
                    model: topFilterBar.filterModel.length > 0 ? topFilterBar.filterModel : []

                    Button {
                        text: modelData.label
                        height: units.gu(6)
                        width: units.gu(12)
                        property bool isHighlighted: topFilterBar.currentFilter === modelData.filterKey

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
                            elide: Text.ElideRight
                        }

                        onClicked: {
                            topFilterBar.currentFilter = modelData.filterKey;
                            topFilterBar.filterSelected(modelData.filterKey);
                        }
                    }
                }
            }
        }
    }
}
