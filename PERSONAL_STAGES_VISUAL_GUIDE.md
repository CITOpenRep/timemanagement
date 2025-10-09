# Personal Stages - Quick Visual Guide

## What You'll See in the UI

### Existing Task View (Read-Only Mode)

```
┌─────────────────────────────────────────────────────┐
│  Current Stage:        In Progress                  │  ← Orange (existing)
├─────────────────────────────────────────────────────┤
│  Personal Stage:       Working On It               │  ← Blue (NEW)
│                    OR                                │
│  Personal Stage:       (Not set)                    │  ← Gray italic if not set
├─────────────────────────────────────────────────────┤
│  [ Create Activity ]    [ Change Stage ]            │  ← Half-width buttons
├─────────────────────────────────────────────────────┤
│         [ Change Personal Stage ]                   │  ← NEW: Full-width blue button
└─────────────────────────────────────────────────────┘
```

## Personal Stage Selector Dialog

When you click "Change Personal Stage":

```
╔═══════════════════════════════════════════════════╗
║  Change Personal Stage                             ║
╠═══════════════════════════════════════════════════╣
║  Current Personal Stage: Working On It             ║
║                                                     ║
║  Select Personal Stage:                            ║
║  Personal stages are separate from project stages  ║
║  and help you track your own workflow.             ║
║                                                     ║
║  ┌─────────────────────────────────────────────┐  ║
║  │ (Clear Personal Stage)                      │  ║  ← Option to clear
║  ├─────────────────────────────────────────────┤  ║
║  │ ▌ Working On It                             │  ║  ← Current (blue bar)
║  ├─────────────────────────────────────────────┤  ║
║  │   Need to Review                            │  ║
║  ├─────────────────────────────────────────────┤  ║
║  │   Waiting on Others                         │  ║
║  ├─────────────────────────────────────────────┤  ║
║  │   Ready to Complete                         │  ║
║  └─────────────────────────────────────────────┘  ║
║                                                     ║
║                             [ Cancel ]              ║
╚═══════════════════════════════════════════════════╝
```

## Color Coding

- **🟠 Orange** = Project Stages (team-wide, managed by project)
- **🔵 Blue** = Personal Stages (your own, independent from project)

## Key Features

✅ View current personal stage on any task
✅ Change personal stage with one button click
✅ Clear personal stage to remove it
✅ Personal stages are separate from project stages
✅ Blue color distinguishes personal from project elements
✅ Works only for existing tasks (not during creation yet)

## What's Different from Project Stages?

| Feature              | Project Stage       | Personal Stage        |
|---------------------|---------------------|-----------------------|
| **Scope**           | Team-wide           | User-specific         |
| **Color**           | Orange              | Blue                  |
| **Managed By**      | Project/Admin       | Individual User       |
| **Purpose**         | Track team progress | Track personal work   |
| **Required**        | Usually yes         | Optional              |
| **Affects Others**  | Yes                 | No                    |
| **Button Width**    | Half-width          | Full-width            |

## Database Fields

- **state** (INTEGER) - Project stage odoo_record_id
- **personal_stage** (INTEGER) - Personal stage odoo_record_id (NULL if not set)

Both fields store odoo_record_id values that reference project_task_type_app table.

## How to Identify Personal Stages in Database

Personal stages have `is_global = '[]'` in the project_task_type_app table.
Regular (project) stages have other values like `'[1]'` or specific project IDs.

## Backend Functions Available

```javascript
// Get all personal stages for a user
Task.getPersonalStagesForUser(userId, accountId)

// Update a task's personal stage
Task.updateTaskPersonalStage(taskId, personalStageOdooRecordId, accountId)

// Get stage name (works for both project and personal stages)
Task.getTaskStageName(stageOdooRecordId)
```

## Example Usage Scenario

**Scenario**: You're working on a task that the team has in "In Progress" stage, but you personally need to track your own progress.

1. **Project Stage**: "In Progress" (orange) - This is what the team sees
2. **Personal Stage**: "Waiting on Others" (blue) - This is your personal tracking

The project stage shows the official team status, while your personal stage helps you remember this task is blocked waiting for someone else.

## Future Enhancements

Potential additions (not yet implemented):

1. **Task Creation**: Add personal stage selector when creating tasks
2. **MyTasks Page**: Filter tasks by personal stage
3. **Task List**: Show personal stage column in list views
4. **Bulk Update**: Change personal stage for multiple tasks at once
5. **Personal Stage Stats**: Dashboard widget showing your personal stage distribution
