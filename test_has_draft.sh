#!/bin/bash

# Script to test has_draft flag functionality

echo "=== Testing has_draft Flag ==="
echo ""

# Find the database file
DB_PATH="$HOME/.clickable/home/.local/share/ubtms/Databases/myDatabase.sqlite"

if [ ! -f "$DB_PATH" ]; then
    echo "❌ Database not found at: $DB_PATH"
    echo "Looking for database..."
    find ~/.clickable -name "myDatabase.sqlite" 2>/dev/null
    exit 1
fi

echo "✅ Database found: $DB_PATH"
echo ""

# Check if has_draft column exists
echo "1. Checking if has_draft column exists..."
sqlite3 "$DB_PATH" "PRAGMA table_info(project_task_app);" | grep has_draft

if [ $? -eq 0 ]; then
    echo "✅ has_draft column exists"
else
    echo "❌ has_draft column does NOT exist - database migration didn't run!"
    exit 1
fi

echo ""

# Show current has_draft values
echo "2. Current has_draft values in database:"
sqlite3 "$DB_PATH" "SELECT id, name, has_draft FROM project_task_app LIMIT 10;"

echo ""

# Set has_draft = 1 for first task
echo "3. Setting has_draft = 1 for first task..."
FIRST_TASK_ID=$(sqlite3 "$DB_PATH" "SELECT id FROM project_task_app LIMIT 1;")
echo "First task ID: $FIRST_TASK_ID"

sqlite3 "$DB_PATH" "UPDATE project_task_app SET has_draft = 1 WHERE id = $FIRST_TASK_ID;"

echo "✅ Updated task $FIRST_TASK_ID"

echo ""

# Verify the change
echo "4. Verifying the change:"
sqlite3 "$DB_PATH" "SELECT id, name, has_draft FROM project_task_app WHERE id = $FIRST_TASK_ID;"

echo ""

# Show all tasks with has_draft = 1
echo "5. All tasks with has_draft = 1:"
sqlite3 "$DB_PATH" "SELECT id, name, has_draft FROM project_task_app WHERE has_draft = 1;"

echo ""
echo "=== Test Complete ==="
echo "Now run the app and check if the bullet '•' appears next to the task name!"
