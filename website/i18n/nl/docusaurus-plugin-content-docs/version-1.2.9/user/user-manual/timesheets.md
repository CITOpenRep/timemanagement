# Rooster

De module **Urenstaat** wordt gebruikt om de tijd besteed aan projecten, taken en dagelijkse werkzaamheden binnen de Time Management App vast te leggen, te beheren en te monitoren.

Deze module helpt gebruikers:
* Houd de dagelijkse werktijden bij.
* Registreer de inspanningen die zijn besteed aan taken en projecten.
* Houd nauwkeurige werklogboeken bij om het volgen van de productiviteit te verbeteren.
* Ondersteuning van rapportage- en facturatieprocessen.
* Houd toezicht op de tijdsbesteding van teams en projecten.

---

## Accessing the Timesheet Module
To open the **Timesheet** section:
1. Click the **Menu (☰)** icon from the top-left corner.
2. Select **Timesheet** from the sidebar navigation.

---

## Overzicht urenstaatscherm
Het scherm is verdeeld in de volgende secties:
1. Koptekstsectie (pictogram toevoegen, terugnavigatie, zoekpictogram).
2. Filtertabbladen urenstaat.
3. Overzichtspaneel urenstaat.
4. Paneel met urenstaatdetails.
5. Veeg acties.
6. Zwevende actieknop (FAB).

### Filtertabbladen urenstaat
* **Alles**: toont alle urenstaatgegevens.
* **Actief**: Geeft momenteel actieve of lopende urenstaten weer.
* **Concept**: Toont opgeslagen concept-urenstaten die in afwachting zijn van voltooiing.

### Overzichtspaneel urenstaat
Displays records in a list format, summarizing: Timesheet Title, Project Name, Task Info, Logged Hours, Entry Date, Assigned User, and Priority.

---

## Een nieuwe urenstaatboeking maken
Klik op **➕ Pictogram toevoegen** of tik op de **Zwevende actieknop (FAB)** en selecteer **Maken**. Vul de gegevens in en klik op de knop **✔ Opslaan**.

### Velden voor het maken van urenstaten
* **Account, Project, Subproject, Taak, Subtaak**: Koppel de invoer aan specifieke organisatie- en werkitems om nauwkeurige rapportage te ondersteunen.
* **Prioriteit**: belangrijkheidsniveau (belangrijk/dringend (1), belangrijk/niet urgent (2), urgent/niet belangrijk (3), niet urgent/niet belangrijk (4)).
* **Tijdregistratiemodus**:
    * **Handmatig**: Gebruikers voeren handmatig werkuren in.
    * **Geautomatiseerd**: de systeemtimer houdt automatisch de tijd bij.
* **Timer**: beschikt over de knoppen Start, Pauze en Stop. Wordt automatisch bijgewerkt tijdens het hardlopen en voegt duur toe aan de invoer.
* **Datum**: Werkdatum voor chronologische tracking.
* **Beschrijving**: Gedetailleerde informatie over voltooid werk, updates, opgeloste problemen en bijgewoonde vergaderingen.

---

## Urenstaten bekijken en bewerken
Selecteer een urenstaat uit de overzichtslijst om volledige informatie weer te geven in het detailpaneel. Om te bewerken opent u het item in de bewerkingsmodus, werkt u de velden bij en klikt u op Opslaan.

---

## Beheer van urenstaatstatus
* **Actief**: momenteel aan de gang of onlangs bijgewerkt.
* **Concept**: tijdelijk opgeslagen vóór definitieve indiening.
* **Voltooid**: voltooide en definitieve vermeldingen klaar voor synchronisatie.

---

## Geautomatiseerde timer Opslaan als conceptproces
Wanneer u **Geautomatiseerde** tracking gebruikt, wordt door het klikken op de **Stopknop** automatisch het dialoogvenster **Beschrijving toevoegen aan urenstaat** geopend.

**Dialoogvensteracties:**
* Geeft de totale bijgehouden tijd weer en stelt gebruikers in staat werkgegevens in te voeren.
* **Opslaan als conceptknop**: slaat de bijgehouden duur en beschrijving op in de status **Concept**. Het is nog niet definitief, maar wordt zichtbaar onder het tabblad Concept voor toekomstige bewerking.
* **Knop Annuleren**: Sluit het dialoogvenster zonder op te slaan en verwijdert de timergegevens.

### Completing a Draft Timesheet
Conceptinzendingen kunnen direct vanuit het overzichtsscherm worden afgerond:
1. Open het tabblad **Concept**.
2. Veeg de gewenste invoer naar links.
3. Tik op het pictogram **✔ Markeren als gereed**.

Er verschijnt een succesbericht: *"Urenstaat is nu klaar om te worden gesynchroniseerd met Odoo."* De invoer gaat van het tabblad Concept naar het tabblad Alles, verandert naar de status **Voltooid** en wordt beschikbaar voor Odoo-synchronisatie.

---

## Swipe-acties voor urenstaat

**Swipe-actie naar rechts (verwijderen):**
* Onthult de optie **Verwijderen** om snel ongewenste of onjuiste invoer te verwijderen.

**Veegacties naar links (snelle bediening):**
* **Bewerken**: Opent de urenstaat in de bewerkingsmodus.
* **Start Timer**: Start automatische tijdregistratie rechtstreeks vanuit de lijst; het item kan tijdens het hardlopen op het tabblad Actief verschijnen.
* **Markeren als gereed**: voltooit een concept-urenstaat voor synchronisatie.