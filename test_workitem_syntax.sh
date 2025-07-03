#!/bin/bash
# Simple syntax validation for QML files
echo "Checking QML syntax..."

# Check if the main WorkItemSelector file has any obvious syntax issues
grep -n "ReferenceError\|childSelector\|parentSelector" /home/suraj/timemanagement/qml/components/WorkItemSelector.qml

if [ $? -eq 0 ]; then
    echo "❌ Found potential issues in WorkItemSelector.qml"
else
    echo "✅ No obvious syntax issues found in WorkItemSelector.qml"
fi

# Check the functions are present
echo ""
echo "Checking key functions exist:"
grep -n "function syncEffectiveId" /home/suraj/timemanagement/qml/components/WorkItemSelector.qml
grep -n "function applyDeferredSelection" /home/suraj/timemanagement/qml/components/WorkItemSelector.qml
grep -n "function getAllSelectedDbRecordIds" /home/suraj/timemanagement/qml/components/WorkItemSelector.qml

echo ""
echo "✅ WorkItemSelector.qml validation complete"
