---
title: Profielen en accountisolatie Technische referentie
sidebar_label: Profielen en accountisolatie
---

# Profielen en accountisolatie Technische referentie

De module Profielen regelt de instellingen van gebruikersprofielen en biedt lokale gegevensisolatie over meerdere Odoo-instanties.

## Codebase-kaart

| Laag | Pad | Doel |
|---|---|---|
| **UI-componenten** | `qml/features/settings/Profiles.qml` | Profielselectie en interface voor het wisselen van instanties |
| **Logica en status** | `models/accounts.js` | Sessievalidatie en schakelen tussen actieve exemplaartokens |

## Isolatie van meerdere databases

De SQLite-schema-isolatie gebruikt een relationele sleutel `user_id` die is toegewezen aan de actieve rij in de tabel `users` (accounts).

### SQL-filterstrategie
Elke query voor het ophalen van gegevens die door JavaScript-modellen wordt uitgevoerd, controleert de huidige actieve gebruikerscontext op basis van de algemene instellingen:

```sql
SELECT * FROM project_task_app 
WHERE user_id = (SELECT value FROM app_settings WHERE key = 'active_user_id');
```

Deze structuur zorgt ervoor dat gegevens uit afzonderlijke accounts/instanties (bijvoorbeeld Werk versus Persoonlijk) worden gescheiden, waardoor gegevenslekken tussen omgevingen worden vermeden.
