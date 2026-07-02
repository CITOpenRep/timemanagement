---
title: Functiecatalogus
sidebar_label: Alle functies
---

# Functiecatalogus

Deze pagina biedt een uitgebreide catalogus van alle functies van de TimeManagement-applicatie. Gebruik de links onder elke module om naar hun respectievelijke functionele handleidingen of technische implementatiedetails te navigeren.

---

## 1. Activiteitenmodule

Met de module Activiteiten kunnen gebruikers vervolgtaken en -acties plannen, beheren en volgen.

### Functies
*   Zoek activiteiten.
*   Sorteer activiteiten op laatst bijgewerkt (aflopend).
*   Markeer activiteiten of taken als Voltooid.
*   Resterende dagen weergeven (toont de status "Over tijd" als de vervaldatum is verstreken).
*   "Lees meer"-afkapping voor lange notities.
*   Tabbladen om te filteren op Open / Gesloten / Alles.
*   Voeg een opmerking toe voordat u een activiteit voltooit [Aankomend].
*   Voeg bestanden/documenten toe aan Activiteiten [Aankomend].
*   Creëer vervolgactiviteiten rechtstreeks vanuit hetzelfde scherm.
*   Snelkoppeling om rechtstreeks vanaf een project- of taakdetailpagina een activiteit aan te maken.
*   Veeg naar links om de bewerkingsmodus te openen.
*   Veeg naar links om een ​​activiteit te annuleren/verwijderen.
*   Annuleer de bevestigingsvraag voordat u [Aankomend] verwijdert.
*   **Weergavefilters met tabbladen:** Filter activiteiten snel op planning/status: **Vandaag**, **Deze week**, **Deze maand**, **Later**, **Te laat**, **Alles** en **Gereed**.
*   **Activiteit opnieuw plannen:** Wijzig eenvoudig vervaldatums via veegacties of de gedetailleerde weergavedatumkiezer.

### Formuliervelden
*   **Verplichte velden:** Instantie, Activiteitstype, Toegewezen persoon, Samenvatting (enkele regel), Notities (meerdere regels), Vervaldatum, Gelinkte entiteit (Project/Taak/Contact).
*   **Default Values:** Date defaults to Today.

### Technische architectuurkaart (voor bijdragers)

| Laag | Pad / Bestanden | Implementatiedetails |
| :--- | :--- | :--- |
| **Frontend-UI** | `qml/features/activities/pages/Activity_Page.qml`<br/>`qml/components/cards/ActivityDetailsCard.qml` | Geeft lijstweergaven weer, verwerkt klikken op tabbladen (Vandaag/Week/Maand/etc.), activeert datumkiezers en koppelt veeginteracties. |
| **Logica en status** | `models/activity.js` | JavaScript-backend-model met `getFilteredActivities()`, `updateActivityDate()`, `markAsDone()` en `createFollowupActivity()`. |
| **Databaseschema** | SQLite-tabel: `mail_activity_app` | Slaat activiteitseigenschappen op: `summary`, `due_date`, `notes`, `state` (gepland/klaar), `user_id` en `resModel`/`resId` (koppeling aan taken of projecten). |
| **Backend en synchronisatie** | `src/daemon.py` | Synchroniseert lokale activiteitsstatussen bidirectioneel met Odoo's `mail.activity` via XML-RPC. |

:::tip Functionele Gids
Leer hoe u activiteiten kunt gebruiken in de [Gebruikershandleiding activiteiten](./user-manual/activities.md).
:::

:::info Technische referentie
Voor schemadefinities en synchronisatiereeksstromen raadpleegt u de [Activiteiten Module Technische Referentie](../technical/activities.md).
:::

---

## 2. Projectenmodule

De module Projecten organiseert werkitems op hoog niveau en koppelt deze aan exemplaren.

### Functies
*   Bekijk subprojecten met inklapbare/volgende deelvensterweergave.
*   Zoekactie met verbeterde zoekfunctie (inclusief subprojecten).
*   Sorteer projecten op laatst bijgewerkt.
*   Swipe right to add to Favorites.
*   Filter projecten op basis van hun respectievelijke fasen in Odoo (Kanban-toewijzing).
*   Filter project list to exclude the "Done" stage.
*   Bekijk alle projectupdates op één plek (gesorteerd op datum).
*   Link vanuit het projectscherm naar een gefilterde lijst met updates gerelateerd aan dat specifieke project.
*   Op rollen gebaseerde toegangscontroles voor het maken van projecten.
*   Geef de uren weer die aan projecten zijn besteed.
*   Indicatorbalk voor projectvoortgang.
*   Toon alleen relevante onderliggende projecten op basis van de huidige context van de gebruiker.
*   Snelle "+ knop" voor nieuwe invoer.
*   Creëer een taak rechtstreeks vanuit de gedetailleerde projectweergave.
*   Knop Taak maken voor snellere taakcreatie.
*   Logische indeling van huidige opties (Taken bekijken, Activiteit aanmaken).

### Formuliervelden
*   **Verplichte velden:** Instantie, Hoofdproject, Van/tot-datum, Beschrijving (Rich text), Gebruiker ingevoerd door, Toegewezen uren, Kleurkiezer, Favoriete ster.
*   **Verplichte velden:** Ontvanger.
*   **Standaardwaarden:** Instantie (gebaseerd op instellingen), Datumbereik (deze week).

### Overzichtspaginavelden
*   Favoriete indicator, exemplaar, begin- en einddatum, aantal subprojecten, link naar details bekijken, resterende dagen en nabijheid van deadlines.
*   Projectvoortgangsbalk.

### Technische architectuurkaart (voor bijdragers)

| Laag | Pad / Bestanden | Implementatiedetails |
| :--- | :--- | :--- |
| **Frontend-UI** | `qml/features/projects/` | Projectmappagina's, subprojectpanelen, voortgangsbalken en detailkaarten. |
| **Logica en status** | `models/project.js` | Geeft SQLite-query's weer voor het weergeven, laden van details en het schakelen tussen favorieten. |
| **Databaseschema** | SQLite-tabel: `project_project_app` | Slaat projectmetagegevens, ouder-kindprojectrelaties en kleurenpaletindicatoren op. |
| **Backend en synchronisatie** | `src/sync_to_odoo.py` | Haalt externe projecten op en publiceert lokaal gemaakte projectinzendingen. |

:::tip Functionele Gids
Voor details over updates en lijsten, lees de [Gebruikershandleiding voor projecten](./user-manual/projects.md) en de [Gids voor projectupdates](./user-manual/project-updates.md).
:::

:::info Technische referentie
Begrijp de querytoewijzingen in de [Projecten Module Technische Referentie](../technical/projects.md).
:::

---

## 3. Takenmodule

De module Taken beheert de taakuitvoering, het volgen en de ouder-kind-hiërarchieën.

### Functies
*   View sub-tasks with expand/collapse hierarchy.
*   Zoekknop.
*   Sorteer op laatst bijgewerkt.
*   Tabbladen om te ordenen op tijdsbestek: Vandaag / Week / Maand / Later.
*   Filter op openstaande taken (standaard) en filter op toegewezen persoon.
*   Veeg naar Favoriet, Veeg om te verwijderen, Veeg om te bekijken/bewerken.
*   Contextmenu voor snelle taakcreatie.
*   Slimme afspeelknop om de timer voor de taak te starten.
*   Voortgangsregistratiebalk.
*   Showdagen Resterende en berekende nabijheid van deadlines.
*   Task color inherited from the parent project.
*   Beschrijving Knop "Lees meer".
*   Meerdere verantwoordelijken voor taken.
*   Bekijk "Mijn Taken" via persoonlijke fasen.
*   Beheer van taakfasen op basis van status (in uitvoering of voltooid) – UI en backend.
*   Geef alleen relevante subtaken weer om rommel te verminderen.
*   Bevestigingsprompt verwijderen.
*   Knop voor het opnieuw plannen van taken en activiteiten.
*   **Datumfilters met tabbladen:** Segmenteer takenlijsten met behulp van tabbladen: **Vandaag**, **Week**, **Maand** en **Later**.
*   **Taak opnieuw plannen:** Met een knop voor snel opnieuw plannen worden de deadlines voor taken in de database bijgewerkt.
*   **Tweevoudig fasesysteem:**
    *   *Global Kanban Stages:* Standaard workflowfases (bijv. To Do, In Progress, Done) gesynchroniseerd met de globale projectconfiguratie van Odoo.
    *   *Personal Stages ("My Tasks"):* Custom, user-specific stages to organize personal work progress independently.
*   **Priority Stars:** High-priority tasks display visual star badges (0 to 3 levels) mapped to the Odoo priority schema.

### Formuliervelden
*   **Verplichte velden:** Instantie, bovenliggend project/subproject/bovenliggende taak, periode (vandaag/deze week/volgende week/deze maand/volgende maand), datum (automatisch invullen), beschrijving (meerdere regels), toegewezen persoon, uren (HH), favoriete ster.
*   **Verplichte velden:** Taaknaam.
*   **Default Values:** Instance, Date range (This week), Time (1 hour or configurable from settings).
*   **Limieten:** 24-uurslimiet voor dagelijkse tijdregistratie (urenstaten); grenzen inschatten.

### Overzicht Lijstvelden
*   Taaknaam, Fase, Instance, Project, Subproject, Bovenliggende taak, Deadline, Toegewezen persoon, Favoriet, Uren, Datums (begin en einde), Aantal subtaken, Details link.

### Technische architectuurkaart (voor bijdragers)

| Laag | Pad / Bestanden | Implementatiedetails |
| :--- | :--- | :--- |
| **Frontend-UI** | `qml/features/tasks/pages/Tasks.qml`<br/>`qml/features/tasks/pages/MyTasksPage.qml`<br/>`qml/features/tasks/components/TaskDetailsCard.qml`<br/>`qml/features/tasks/components/TaskDateRangeDialog.qml` | Beheert lijstlay-outs, veegmenu's, pop-uptriggers voor persoonlijke fases en selectors voor het opnieuw plannen van datums. |
| **Logica en status** | `models/task.js` | Implementeert database CRUD-functies, waaronder `saveOrUpdateTask()`, `updateTaskPersonalStage()` en `setTaskPriority()`. Verwerkt meerdere toegewezen arrays. |
| **Databaseschema** | SQLite-tabellen: `project_task_app`<br/>`project_task_type_app` | `project_task_app` houdt velden bij zoals `stage_id` en `personal_stage`. `project_task_type_app` slaat globale fasen en persoonlijke fasen op (waarbij `is_global = '[]'`). |
| **Backend en synchronisatie** | `src/sync_to_odoo.py` / `src/backend.py` | Daemon-handlers voor het verleggen van taakdeadlines en D-Bus-interfaces voor taakmutaties. |

:::tip Functionele Gids
Ontdek gedetailleerde taakhandleidingen in de [Handleiding voor alle taken](./user-manual/all-tasks.md) en [Mijn takengids](./user-manual/my-tasks.md).
:::

:::info Technische referentie
Zie sequentiediagrammen en DBUS-interfaces in de [Taken Module Technische Referentie](../technical/tasks.md).
:::

---

## 4. Module urenstaten

De module Urenstaten verzorgt de registratie van werkuren, geautomatiseerde timers en logboekregistratie.

### Volgen en loggen
*   Veeg omhoog vanaf het startscherm om een ​​urenstaat te maken.
*   Voeg toe via de knop "+" in de urenstaatlijst.
*   Slimme afspeelknop om de timer te starten (beschikbaar in takenlijst, projectlijst en formulierweergaven).
*   De timer blijft op de achtergrond lopen.
*   Er kan slechts één timer tegelijk actief zijn.
*   Invoer van tijdsbesteding (handmatig of automatisch via timer).
*   Tijdformaat: 00:00 UU:MM.
*   Pop-up om beschrijving/notities toe te voegen onmiddellijk na de opnametijd.
*   Zoekmogelijkheid voor urenstaten.
*   Optionele standaard projectselectie.
*   **Eisenhower Prioriteitsmatrix:** Classificeer urenstaattaken ter ondersteuning van urgente versus belangrijke sortering op dashboardkwadranten.
*   **Decimale formaten:** De bestede tijd wordt opgeslagen in het standaard decimale formaat (bijvoorbeeld 1,5 is gelijk aan 1 uur en 30 minuten).

### Formuliervelden
*   **Verplichte velden:** Instantie (Odoo of lokaal), Project, Subproject, Taak, Subtaken, Datum, Beschrijving (meerdere regels), Prioriteit (Eisenhower-matrix).
*   **Verplichte velden:** Project.
*   **Standaardwaarden:** Datum (vandaag), Gebruiker, Tijd.
*   **Bewerk velden:** Gebruiker (ingevoerd door), Eisenhower Prioriteit, Projectkleur.

### Overzicht velden
*   Beschrijving, Datum, Bestede uren, Gebruiker, Project, Taak, Instance, Eisenhower-prioriteit.

### Gebaren
*   Leading swipe (left to right) for Delete.
*   Sleepbeweging voor bewerken/verwijderen.
*   Bevestigingsprompt verwijderen.

### Technische architectuurkaart (voor bijdragers)

| Laag | Pad / Bestanden | Implementatiedetails |
| :--- | :--- | :--- |
| **Frontend-UI** | `qml/features/timesheets/` | Logboeken, invoerformulieren voor urenstaten en overlay-timers. |
| **Logica en status** | `models/timesheet.js`<br/>`models/timer_service.js` | Coördineert actieve timers, lokale opslagtimerpersistentie en stopwatchacties. |
| **Databaseschema** | SQLite-tabel: `account_analytic_line_app` | Slaat de geregistreerde duur `unit_amount`, datum, gekoppelde taak/project, beschrijving en synchronisatiestatus op. |
| **Backend en synchronisatie** | `src/sync_to_odoo.py` | Synchronisatiemedewerker die lokale urenstaten identificeert die zijn gemarkeerd als "vuil" om op afstand te synchroniseren via XML-RPC. |

:::tip Functionele Gids
Lees hoe u urenstaten registreert in de [Gebruikershandleiding urenstaten](./user-manual/timesheets.md).
:::

:::info Technische referentie
Bekijk de timerpersistentieregels in de [Urenstaten Module Technische Referentie](../technical/timesheets.md).
:::

---

## 5. Dashboard

Het Dashboard biedt visuele analyses, grafieken en prioriteitsbeheer.

### Functies
*   Eisenhower Matrix (met tooltip/info-pictogram).
*   Projectgewijze tijdsbestedingsgrafiek (Top 10 projecten).
*   Activiteitenmenu in de FAB (zwevende actieknop).
*   Keuzerondje voor selectie van Eisenhower Prioriteit.
*   Taakgewijze tijdsbestedingsgrafiek (Top 10 taken).
*   Filters: Deze week (standaard), Maand, Jaar.
*   Standaardfilter: Toon alleen Mijn urenstaten, Mijn taken.
*   Dashboardgegevens exporteren naar CSV.
*   Veeg naar links/rechts om tussen diagrammen te schakelen/pagineren.
*   Stel het standaarddiagram in in instellingen/gebruikersprofiel.
*   Samenvatting van voltooide activiteiten en taken op basis van gebruiker.

### Technische architectuurkaart (voor bijdragers)

| Laag | Pad / Bestanden | Implementatiedetails |
| :--- | :--- | :--- |
| **Frontend-UI** | `qml/features/dashboard/pages/Dashboard.qml` | Eisenhower-raster, diagramkiezers, paginering van veegcontainers. |
| **Logica en status** | `models/Main.js` | Voert LocalStorage SQLite-queryprojecties uit (bijvoorbeeld Top 10 project SUM-groeperingen en urgentiestatustellingen). |

:::tip Functionele Gids
Voor details over matrixitems en diagramrapporten, zie [Dashboard-gebruikershandleiding](./user-manual/dashboard.md).
:::

:::info Technische referentie
Controleer statistische zoekopdrachten in de [Technische referentie dashboardmodule](../technical/dashboard.md).
:::

---

## 6. Synchronisatie- en accountinstellingen

Deze module configureert Odoo/Lokale accounts, handmatige/automatische synchronisatie en conflictoplossing.

### Synchroniseren
*   Synchroniseren bij het aanmaken van een account.
*   Handmatige synchronisatieknop.
*   Integratie met Odoo met meerdere exemplaren.
*   Meldingspop-up en planner synchroniseren.
*   Waarschuw de gebruiker als automatische synchronisatie mislukt.
*   Foutlogboeken.
*   Bericht over succes/mislukt nadat de synchronisatie is gestart.
*   Statussynchronisatie met instanties, taken verplaatsen naar correcte Kanban-fasen.
*   Conflictoplossing op basis van tijdstempels met gebruikersprompts voor handmatige oplossing.
*   Integratie met niet-Odoo-instanties (bijv. Nextcloud).

### Accountbeheer
*   Accounts toevoegen/verwijderen.
*   Sta alleen unieke accountnamen toe voor verschillende instanties.
*   De interface voor het aanmaken van een account gaat na het opslaan over naar de weergavemodus.
*   Stel standaardproject in.
*   Stel de standaardrapport-/dashboardweergave in.

### Verplichte velden
*   Naam, URL, DB (automatisch opgehaald), gebruikersnaam, wachtwoord.

### Technische architectuurkaart (voor bijdragers)

| Laag | Pad / Bestanden | Implementatiedetails |
| :--- | :--- | :--- |
| **Frontend-UI** | `qml/features/settings/` | Accountlijsteditor, URL-invoer en indicatorbalken voor synchronisatiestatus. |
| **Logica en status** | `models/accounts.js`<br/>`models/dbinit.js` | Beheert inloggegevens, tokens, sessiecontroles en het maken van databasetabellen. |
| **Backend en synchronisatie** | `src/daemon.py`<br/>`src/backend.py` | Implementeert netwerksynchronisatieroutines, verbindingstests en multi-threaded synchronisatiemanagers. |

:::tip Functionele Gids
Lees hoe u Odoo-instanties configureert in de [Instellingen Gebruikershandleiding](./user-manual/settings.md).
:::

:::info Technische referentie
Bekijk de synchronisatieroutines in de [Synchronisatie-instellingen Technische referentie](../technical/sync-settings.md).
:::

---

## 7. Algemene UI/UX en navigatie

Lay-outrichtlijnen, themaconfiguratie en content hub-integraties.

### Navigatie en lay-out
*   UT Hamburgermenu (in de stijl van de Dekko-app met scheiding in het linkerdeelvenster).
*   Ondersteuning van veeg-/aanraakgebaren.
*   Volledig scherm op mobiel.
*   Contextmenu of swipe-acties voor het snel maken van urenstaten/taken/activiteiten.
*   Transactioneel menu duidelijk gescheiden van instellingen.
*   Doorkliknavigatie (drill-down) (bijvoorbeeld Projecten → Taken → Urenstaten).
*   Snellere, intuïtievere navigatie in detail.
*   Convergentieondersteuning (responsief ontwerp voor desktopmodus/ondersteuning voor meerdere panelen).
*   Schuifregelaar vanaf de linkerrand om het navigatiemenu te openen.
*   Menu onderverdeeld in hoofdactiviteiten en beheerdersgedeelte.

### Ontwerp en thema
*   Lomiri-stijliconen.
*   Donkere themaschakelaar in de applicatie.
*   Ondersteuning voor meerdere thema's in Ubuntu OS.
*   Implementatie van de Suru-ontwerpfilosofie.
*   Upgrade van Lomiri naar QQC2-Suru-stijl.
*   Intuïtieve gebruikersinterface met standaard UT-gebaren, leesbare lettertypen en consistente rasterindelingen.
*   Implementeer nieuw thema op basis van ontwerpconsulent.

### Inhoudshub en bijlagen
*   Voeg bestanden toe met Content Hub om ze beschikbaar te maken op de Odoo-server.
*   On-demand downloaden van bijlagen van server naar apparaat (UI & Backend).
*   Bijlagen toevoegen vanuit de app.
*   Verbeterd bijlagescherm: Lijstweergave, uitgeschakelde downloadknop indien lokaal, "Openen met"-integratie.
*   Download CSV's vanuit elke lijstweergave.

### Algemene app-functies
*   Lees meer afkapping voor lange beschrijvingen in de app.
*   Vouw de knop uit (+) om de beschrijvingsvakken te maximaliseren.
*   Waarschuwt wanneer de app wordt gesloten.
*   Aanraak- en toetsenbord-/muisinvoer ondersteund.
*   Tabblad Overzicht: "Taak voor vandaag".
*   Favorieten voor taken en projecten (gescheiden in lijstweergave).
*   Filter vermeldingen op basis van exemplaar voor projecten, taken, urenstaten en activiteiten.
*   Taalvertaling met Weblate.
*   Automatisch opslaan voor volledige formulierweergaven.
*   Motiverende projectactivering.
*   Maak lokale accountfasen voor projecten en taken.
*   App vastzetten op startscherm.
*   Ondersteuning voor snelle installatie.

### Technische architectuurkaart (voor bijdragers)

| Laag | Pad / Bestanden | Implementatiedetails |
| :--- | :--- | :--- |
| **Frontend-UI** | `qml/TSApp.qml`<br/>`qml/app/` | Vensterindeling van de root-app, paginarouting en context voor het schakelen tussen thema's. |
| **Logica en hulpprogramma's** | `models/utils.js`<br/>`models/global.js` | Gedeelde QML-helpers (datumopmaak, kleurgeneratie, navigatiegeschiedenis). |

:::tip Functionele Gids
Voor navigatierichtlijnen raadpleegt u de [Introductiegids](./user-manual/introduction.md) en de [Kebab-menunavigatiegids](./user-manual/kebab-menu.md).
:::

:::info Technische referentie
Voor details over lay-outconvergentie, controleer de [Technische referentie voor UI-UX-navigatie](../technical/ui-ux-navigation.md).
:::

---

## 8. Meldingen

Geautomatiseerde en slimme pushmeldingen voor tijd- en werkbeheer.

### Functies
*   Pushmeldingen voor nieuwe activiteiten, taaktoewijzingen, projectupdates en urenstaatconflicten.
*   Slimme meldingen: Taken/Activiteitenmeldingen worden alleen afgeleverd tijdens gedefinieerde werkuren.
*   Integratie met Ubuntu Touch Notification Server voor activiteiten.

### Technische architectuurkaart (voor bijdragers)

| Laag | Pad / Bestanden | Implementatiedetails |
| :--- | :--- | :--- |
| **Logica** | `models/notifications.js` | Organiseert plannertimers en triggerdrempels. |
| **Daemon** | `qml-notify-module/` | Interface-bindingen voor native meldingen. |

:::info Technische referentie
Zie details in de [Meldingen Technische referentie](../technical/notifications.md).
:::

---

## 9. Onboarding

Interactieve begeleiding bij de eerste lancering voor nieuwe gebruikers.

### Functies
*   Onboard nieuwe gebruikers om app-functies te introduceren.
*   Knop Overslaan om onboarding te omzeilen.
*   Voortgangsindicator (stippen of voortgangsbalk).
*   "Aan de slag" optie.
*   Onboarding-persistentie (voltooid/overgeslagen status).

### Technische architectuurkaart (voor bijdragers)

| Laag | Pad / Bestanden | Implementatiedetails |
| :--- | :--- | :--- |
| **Frontend-UI** | `qml/features/settings/Onboarding.qml` (of vergelijkbare instructiedia's) | Rendert onboarding-schermen en skip-selectors. |

:::tip Functionele Gids
Bekijk de instructies voor de eerste lancering in de [Introductiegids](./user-manual/introduction.md).
:::

:::info Technische referentie
Controleer de eigenschappen in de [Technische referentie voor onboarding](../technical/onboarding.md).
:::

---

## 10. Profielen

Gebruikersprofiel en werk-/persoonlijk bereik wisselen.

### Functies
*   Schakel tussen werk- en persoonlijke profielen.
*   Schakel of vervolgkeuzelijst om van modus te wisselen.
*   **Relationele accountisolatie:** Database-isolatie voor meerdere accounts voorkomt gegevenslekken tussen profielen.

### Technische architectuurkaart (voor bijdragers)

| Laag | Pad / Bestanden | Implementatiedetails |
| :--- | :--- | :--- |
| **Frontend-UI** | `qml/features/settings/Profiles.qml` | Rendert de gebruikerskiezerlijst en schakelt over naar actieve context. |
| **Logica en status** | `models/accounts.js` | Sessievalidatie en schakelen tussen actieve exemplaartokens. |
| **Databaseschema** | SQLite relationele mapping | Dwingt `user_id = (SELECT value FROM app_settings WHERE key = 'active_user_id')` af om replicatabellen van taken en urenstaten te filteren. |

:::tip Functionele Gids
Bekijk profielconfiguraties in de [Instellingen Gebruikershandleiding](./user-manual/settings.md).
:::

:::info Technische referentie
Voor meer informatie over contextisolatie leest u [Profielen Technische referentie](../technical/profiles.md).
:::
