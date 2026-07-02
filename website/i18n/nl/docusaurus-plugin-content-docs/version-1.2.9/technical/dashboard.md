---
title: Technische referentie dashboardmodule
sidebar_label: Dashboardmodule
---

# Technische referentie dashboardmodule

De Dashboard Module biedt geconsolideerde, op zoekopdrachten gebaseerde analytische inzichten met betrekking tot productiviteit, geregistreerde werkuren, actieve taken en prioriteringsstatistieken.

## Codebase-kaart

| Laag | Pad | Doel |
|---|---|---|
| **Frontend-UI** | `qml/features/dashboard/` | Analysepanelen, grafieken en prioriteitswidgets |
| **State & Logica** | `models/Main.js` | Projecties, aggregaties en diagrambindingen voor databasequery's |

## Metrics & SQL Projections

Het dashboard geeft visuele statistieken weer met behulp van analytische SQLite-query's (met behulp van standaard QML LocalStorage-bindingen) in plaats van deze op een backend te berekenen.

### 1. Categorisering van de Eisenhower-matrix
Classificeert actieve taken en activiteiten op basis van urgentie en belang:
```sql
SELECT id, summary, res_model, res_id, date_deadline
FROM mail_activity_app
WHERE done = 0 AND eisenhower_priority = ?;
```

### 2. Projectgewijs geregistreerde tijd (Top 10 projecten)
Verzamelt het totale aantal gelogde uren van `account_analytic_line_app`, gegroepeerd op projectnaam:
```sql
SELECT p.name AS project_name, SUM(t.unit_amount) AS total_hours
FROM account_analytic_line_app t
JOIN project_project_app p ON t.project_id = p.id
GROUP BY t.project_id
ORDER BY total_hours DESC
LIMIT 10;
```

### 3. Voortgang van voltooiing van taken
Berekent de algehele voortgang van taken die aan een project zijn gekoppeld:
```sql
SELECT 
    COUNT(CASE WHEN stage_id = ? THEN 1 END) AS completed_tasks,
    COUNT(id) AS total_tasks
FROM project_task_app
WHERE project_id = ?;
```

---

## Synchronisatiemechanisme en netwerkprotocol

Het dashboard draait volledig client-side op de lokale SQLite-replicadatabase. Het initieert zelf geen externe HTTP/XML-RPC-verzoeken. Gegevensupdates worden op natuurlijke wijze doorgegeven aan het dashboard wanneer synchronisatietaken op de achtergrond de onderliggende SQL-tabellen bijwerken.
