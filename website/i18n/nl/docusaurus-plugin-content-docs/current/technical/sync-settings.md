---
title: Technische referentie voor synchronisatie en accounts
sidebar_label: Synchronisatie en accounts
---

# Technische referentie voor synchronisatie en accounts

Deze module houdt toezicht op de Odoo-configuratie met meerdere exemplaren, handmatige en plannergestuurde achtergrondsynchronisatie, berichten over de succes-/mislukkingsstatus en beperkingen op de schema-integriteit.

## Codebase-kaart

| Laag | Pad | Doel |
|---|---|---|
| **Frontend-UI** | `qml/features/settings/` | Accountconfiguratie, statusindicatoren voor synchronisatiestatus en logboeken |
| **State & Logica** | `models/accounts.js` | Account aanmaken, verifiëren en inloggegevens controleren |
| **Synchronisatiebeheer** | `src/daemon.py` | Synchronisatie van hoofdgebeurtenislussen plannen |
| **Pull-synchronisatie-engine** | `src/sync_from_odoo.py` | Synchronisatiewerker die Odoo XML-RPC-eindpunten opvraagt ​​|
| **Push-synchronisatie-engine** | `src/sync_to_odoo.py` | Synchronisatiewerker duwt vuile records terug |
| **Netwerkclient** | `src/odoo_client.py` | XML-RPC-clientverbindingswrapper |

## Databaseschema

Lokale accountconfiguraties en synchronisatielogboeken worden opgeslagen in:

### `users`
* `id` (INTEGER, Primaire sleutel): Volgorde van lokale gebruikersaccounts.
* `name` (TEXT): Unieke instantienaam-ID.
* `url` (TEKST): Server-URL.
* `db` (TEXT): Odoo-database-ID.
* `username` (TEKST): Gebruikersnaam / E-mailadres.
* `password` (TEXT): Gecodeerd gebruikerstoken/wachtwoord.

### `sync_report`
* `id` (INTEGER, primaire sleutel): log-ID.
* `sync_time` (TEXT): Tijdstempel van de uitvoering van de synchronisatie.
* `status` (TEKST): Statusbericht (`SUCCESS`, `FAILED`).
* `details` (TEXT): Uitzonderingstracering of samenvattingsgegevens van synchronisatie.

---

## Gedetailleerd synchronisatiemechanisme

De synchronisatie-engine implementeert een robuust tijdlijnbewust conflictoplossingspatroon.

```mermaid
sequenceDiagram
    participant DB as Local SQLite
    participant SY as Sync Engine
    participant OD as Odoo Server

    Note over SY: Trigger (Manual / Scheduler)
    SY->>DB: Fetch last successful sync timestamp
    SY->>OD: XML-RPC search_read (records updated > last_sync)
    OD-->>SY: Return modified records
    SY->>DB: Resolve conflicts using write_date comparison
    SY->>DB: Scan local tables for sync_dirty = 1
    SY->>OD: XML-RPC push (create / write)
    OD-->>SY: Return success status
    SY->>DB: Mark local records clean
```

### Strategie voor conflictoplossing
* Als een record zowel lokaal als op de server is gewijzigd sinds de laatste synchronisatie, worden tijdstempels (`write_date` van Odoo versus lokaal `update_time`) geëvalueerd.
* De nieuwere tijdstempel wint standaard. Als tijdstempels identiek of dubbelzinnig zijn, wordt de gebruiker via een dialoogvenster voor conflictoplossing gevraagd te kiezen welke versie hij wil behouden.

---

## D-Bus-oproepinterface

* `TriggerSync()`: Activeert handmatig de achtergrondsynchronisatiewerker.
* `GetSyncStatus()`: Retourneert JSON met de tijdstempel, status en logboeken van de laatste uitvoering.
* `VerifyConnection(url, username, password)`: Vraagt ​​Odoo via XML-RPC om DB-parameters te valideren vóór registratie.
