import QtQuick 2.7
import QtQuick.Controls 2.2
import Lomiri.Components 1.3
import QtQuick.Layouts 1.1

Item {
    id: parentChildSelector

    property bool enabled: true
    property int accountId: 0
    property string parentLabel: "Parent"
    property string childLabel: "Child"
    property var getRecords // function(accountId) to fetch records
    property int projectFilterId: -1 // New property for project filtering  
    property bool useProjectFilter: false // Enable/disable project filtering

    signal finalItemSelected(int id)

    function setProjectFilter(projId) {
        projectFilterId = projId;
    }


    function reloadSelector(options) {
        let {
            selector,
            records,
            selectedId,
            defaultLabel,
            filterFn = () => true
        } = options;

        let filteredRecords = records.filter(filterFn);
        let flatModel = [{ id: -1, name: defaultLabel, parent_id: null }];

        let selectedText = defaultLabel;
        let selectedFound = (selectedId === -1);

        for (let i = 0; i < filteredRecords.length; i++) {
            let record = filteredRecords[i];
            let id = (record.odoo_record_id !== undefined) ? record.odoo_record_id : record.id;
            let name = record.name;
            flatModel.push({ id: id, name: name, parent_id: null });

            if (selectedId === id) {
                selectedText = name;
                selectedFound = true;
            }
        }

        selector.dataList = flatModel;
        selector.reload();
        selector.selectedId = selectedFound ? selectedId : -1;
        selector.currentText = selectedFound ? selectedText : "Select " + defaultLabel;
    }

    function loadParentSelector(selectedId) {
        let records = getRecords(accountId);
        
        // Apply project filter if enabled and set
        let projectFilterFn;
        let displayLabel = parentLabel;
        
        if (useProjectFilter && projectFilterId === -1) {
            // If project filtering is enabled but no project is selected, show no tasks
            projectFilterFn = record => false;
            displayLabel = "Select Project First";
        } else if (useProjectFilter && projectFilterId !== -1) {
            // If project filtering is enabled and project is selected, show only tasks for that project
            projectFilterFn = record => (!record.parent_id || record.parent_id === 0) && record.project_id === projectFilterId;
        } else {
            // If project filtering is disabled, show all parent records
            projectFilterFn = record => !record.parent_id || record.parent_id === 0;
        }
        
        reloadSelector({
            selector: parentSelector,
            records: records,
            selectedId: selectedId,
            defaultLabel: displayLabel,
            filterFn: projectFilterFn
        });
    }

    function loadChildSelector(parentId, selectedId) {
        let records = getRecords(accountId);
        let children = records.filter(record => record.parent_id === parentId);

        if (children.length > 0) {
            // Apply project filter for children as well if enabled
            let childFilterFn;
            if (useProjectFilter && projectFilterId === -1) {
                // If project filtering is enabled but no project is selected, show no child tasks
                childFilterFn = record => false;
            } else if (useProjectFilter && projectFilterId !== -1) {
                // If project filtering is enabled and project is selected, show only child tasks for that project
                childFilterFn = record => record.parent_id === parentId && record.project_id === projectFilterId;
            } else {
                // If project filtering is disabled, show all child records for the parent
                childFilterFn = record => record.parent_id === parentId;
            }
            
            reloadSelector({
                selector: childSelector,
                records: records,
                selectedId: selectedId,
                defaultLabel: childLabel,
                filterFn: childFilterFn
            });
        } else {
            // Show child selector but disable it with "No [Child]"
            reloadSelector({
                selector: childSelector,
                records: [],
                selectedId: -1,
                defaultLabel: "No " + childLabel,
                filterFn: () => false
            });
            finalItemSelected(parentId);
        }
    }

    Column {
        anchors.fill: parent
       spacing: units.gu(1)

        TreeSelector {
            id: parentSelector
            labelText: parentLabel
            width: parent.width
            height: parent.height/4
            enabled: parentChildSelector.enabled && (!parentChildSelector.useProjectFilter || parentChildSelector.projectFilterId !== -1)

            onItemSelected: {
                let selectedId = parentSelector.selectedId;
                console.log(parentLabel + " Selected ID: " + selectedId);
                loadChildSelector(selectedId, -1);
            }
        }

       Rectangle {
            width: parentSelector.width
            height: units.gu(1)
           // anchors.top: parentSelector.bottom
            color: "transparent"
        }

        TreeSelector {
            id: childSelector
            labelText: childLabel
          //  anchors.top: parentSelector.bottom
            anchors.topMargin: units.gu(1)
            width: parent.width
            height: parent.height/4
            enabled: parentChildSelector.enabled && parentSelector.selectedId !== -1
             currentText: "Select " + childLabel

            onItemSelected: {
                if (!childSelector.enabled) return; // ignore clicks when disabled
                let selectedId = childSelector.selectedId;
                console.log(childLabel + " Selected ID: " + selectedId);
                finalItemSelected(selectedId);
            }
        }
    }

}
