---
title: Dashboard Module Technical Reference
sidebar_label: Dashboard Module
---

# Dashboard Module Technical Reference

The Dashboard Module provides consolidated, query-based analytical insights regarding productivity, logged work hours, active tasks, and prioritization metrics.

## Codebase Map

| Layer | Path | Purpose |
|---|---|---|
| **Frontend UI** | `qml/features/dashboard/` | Analytics panels, charts, and priority widgets |
| **State & Logic** | `models/Main.js` | Database query projections, aggregations, and charts bindings |

## Metrics & SQL Projections

The dashboard renders visual stats using SQLite analytical queries (using standard QML LocalStorage bindings) rather than computing them on a backend.

### 1. Eisenhower Matrix Categorization
Classifies active tasks and activities based on urgency and importance:
```sql
SELECT id, summary, res_model, res_id, date_deadline
FROM mail_activity_app
WHERE done = 0 AND eisenhower_priority = ?;
```

### 2. Project-Wise Logged Time (Top 10 Projects)
Aggregates total logged hours from `account_analytic_line_app` grouped by project name:
```sql
SELECT p.name AS project_name, SUM(t.unit_amount) AS total_hours
FROM account_analytic_line_app t
JOIN project_project_app p ON t.project_id = p.id
GROUP BY t.project_id
ORDER BY total_hours DESC
LIMIT 10;
```

### 3. Task Completion Progress
Computes overall progress of tasks associated with a project:
```sql
SELECT 
    COUNT(CASE WHEN stage_id = ? THEN 1 END) AS completed_tasks,
    COUNT(id) AS total_tasks
FROM project_task_app
WHERE project_id = ?;
```

---

## Sync Mechanism & Network Protocol

The dashboard runs entirely client-side on the local SQLite replica database. It does not initiate external HTTP/XML-RPC requests itself. Data updates naturally propagate to the dashboard when background sync tasks update the underlying SQL tables.
