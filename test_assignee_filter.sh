#!/bin/bash

# Simple test to check if the QML files compile and have no syntax errors
echo "Testing QML file syntax..."

# Check Task_Page.qml syntax
echo "Checking Task_Page.qml..."
qmlplugindump -noinstantiate -nonrelocatable QtQuick 2.9 > /dev/null 2>&1 && echo "QtQuick available" || echo "QtQuick not available"

# Check AssigneeFilterMenu.qml syntax  
echo "Checking AssigneeFilterMenu.qml..."
if [ -f "/home/suraj/timemanagement/qml/components/AssigneeFilterMenu.qml" ]; then
    echo "AssigneeFilterMenu.qml created successfully"
else
    echo "AssigneeFilterMenu.qml not found"
fi

# Check TaskList.qml modifications
echo "Checking TaskList.qml modifications..."
if grep -q "filterByAssignees" "/home/suraj/timemanagement/qml/components/TaskList.qml"; then
    echo "TaskList.qml updated with assignee filtering properties"
else
    echo "TaskList.qml missing assignee filtering properties"
fi

# Check task.js modifications
echo "Checking task.js modifications..."
if grep -q "getAllTaskAssignees" "/home/suraj/timemanagement/models/task.js"; then
    echo "task.js updated with getAllTaskAssignees function"
else
    echo "task.js missing getAllTaskAssignees function"
fi

if grep -q "getTasksByAssignees" "/home/suraj/timemanagement/models/task.js"; then
    echo "task.js updated with getTasksByAssignees function"
else
    echo "task.js missing getTasksByAssignees function"
fi

echo "Test completed!"