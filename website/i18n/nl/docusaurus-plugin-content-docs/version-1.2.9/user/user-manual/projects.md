# Projecten

De module **Projecten** wordt gebruikt om alle projectgerelateerde activiteiten binnen de Time Management App te creëren, organiseren, monitoren en beheren.

Projecten helpen gebruikers:
* Groepsgerelateerde taken en activiteiten.
* Houd projecttijdlijnen en toegewezen inspanningen bij.
* Bewaak de voortgang en status.
* Manage assignments and ownership.
* Organize work efficiently across teams or departments.

De sectie Projecten fungeert als een gecentraliseerde werkruimte voor alle lopende en voltooide projecten.

---

## Accessing the Projects Module
To open the **Projects** section:
1. Click the **Menu (☰)** icon from the top-left corner.
2. Select **Projects** from the sidebar navigation.

---

## Overzicht projectenscherm
Het scherm Projecten bevat de volgende onderdelen:
1. Kopsectie
2. Projectenlijst
3. Project Information Panel
4. Zoek- en filteropties
5. Snelle actieknoppen

---

### Kopsectie
Gelegen bovenaan het scherm Projecten.

**Functies:**
* **Zoekpictogram**: wordt gebruikt om snel naar projecten te zoeken.
* **Raster-/lijstweergavepictogram**: Schakel tussen beschikbare projectweergave-indelingen.
* **Pictogram toevoegen**: Maak een nieuw project.
* **Opslaanpictogram**: sla nieuw gemaakte of bewerkte projectdetails op.

---

### Projects List Panel
In het linkerpaneel worden alle beschikbare projecten weergegeven.

Elk projectitem biedt een snel overzicht, inclusief: projectnaam, exemplaarnaam, huidige status, geplande uren, startdatum, einddatum en indicator voor achterstallige betalingen (indien van toepassing).

**Voorbeeldstatussen:** Nog te doen, In uitvoering, Voltooid, In de wacht.

**Aanvullende indicatoren:**
* **Sterpictogram**: Markeert favoriete of belangrijke projecten.
* **Label achterstallig**: Markeert projecten die de geplande voltooiingsdatum hebben overschreden.

---

### Projectinformatiepaneel
Als u op een project uit de projectoverzichtlijst klikt, wordt gedetailleerde informatie over het geselecteerde project weergegeven.

---

## Een nieuw project creëren
Een project maken:
1. Open de module **Projecten**.
2. Klik op **➕ Pictogram toevoegen**.
3. Vul de benodigde projectgegevens in.
4. Klik op de knop **✔ Opslaan**.

Het project verschijnt dan in de projectenlijst.

### Velden voor het maken van projecten
* **Account**: Definieert tot welke verbonden account of omgeving het project behoort, zodat gegevens op de juiste server worden opgeslagen. Toont het momenteel actieve account en kan via een vervolgkeuzelijst worden gewijzigd.
* **Hoofdproject**: wordt gebruikt om subprojecten onder een groter project te maken om de hiërarchie en structuur te verbeteren (bijvoorbeeld websitemigratie -> UI-ontwerp).
* **Toegewezene**: Definieert de gebruiker die verantwoordelijk is voor het project, waarbij het eigendom wordt verduidelijkt.
* **Projectnaam**: de primaire titel van het project (bijvoorbeeld ontwikkeling van mobiele apps, herontwerp van website).
* **Beschrijving**: Gedetailleerde informatie, inclusief doelstellingen, reikwijdte van het werk en verwachte resultaten.
* **Toegewezen uren**: geschatte geplande tijd voor het project (bijvoorbeeld `01:00` = 1 uur) om te helpen bij de planning van de werklast.
* **Kleurindicator**: Maakt het mogelijk een kleur toe te wijzen, zodat projecten gemakkelijker te identificeren zijn.

### Sectie Geplande Data
Defines the expected project timeline.
* **Datumbereik**: Biedt snelle voorinstellingen voor datumselectie (Vandaag, Deze week, Deze maand, Aangepast bereik).
* **Startdatum**: definieert wanneer het project naar verwachting zal beginnen.
* **Einddatum**: definieert de geplande voltooiingsdatum. *Opmerking: Als de huidige datum de einddatum overschrijdt en het project onvolledig is, kan het systeem een ​​indicator **Te laat** weergeven.*

### Bijlagen sectie
Hiermee kunnen gebruikers projectgerelateerde bestanden uploaden en beheren.

**Hoe te uploaden:** Klik op het **Uploadpictogram**, selecteer een bestand en wacht tot het voltooid is.
**Voordelen:** Houdt bestanden gecentraliseerd, verbetert de samenwerking en synchroniseert automatisch met de server en vice versa.

---

## Projectdetails bekijken en bewerken
Als u een project uit de projectenlijst selecteert, worden de details ervan weergegeven in het rechterpaneel. Gebruikers kunnen de projectstatus, tijdlijn, toegewezen uren, beschrijving, toegewezen gebruiker en bijlagen bekijken.

Een bestaand project bewerken:
1. Selecteer het project uit de lijst.
2. Klik rechtsboven op het bewerkingspictogram.
3. Werk de verplichte velden bij.
4. Klik op de knop **✔ Opslaan**.

---

## Projectstatusbeheer
Projecten doorlopen tijdens hun levenscyclus verschillende statussen.

| Staat | Beschrijving |
| --- | --- |
| Te doen | Project is nog niet gestart |
| In uitvoering | Er wordt momenteel gewerkt |
| Voltooid | Projectwerk is voltooid |
| In de wacht | Tijdelijk onderbroken |

---

## Projecten zoeken en favoriet maken
* **Zoeken**: klik op het **Zoekpictogram** en voer de projectnaam in. Bijpassende projecten worden direct weergegeven.
* **Favorieten**: projecten kunnen als favoriet worden gemarkeerd met behulp van het **sterpictogram** voor snellere toegang en eenvoudiger navigatie.

---

## Projectoverzicht Veegacties
Veeg vanuit het overzicht van de projectenlijst een projectitem naar **links** om drie actiepictogrammen weer te geven:
1. **Bekijken**: Opent de detailpagina van het geselecteerde project.
2. **Start**: Start de projecttimer, registreert automatisch de tijd en maakt een urenstaatinvoer.
3. **Pauze**: Stopt de actieve timer en pauzeert de tijdregistratie.

---

## Filter projecten op fase
Met de functie **Filteren op fase** kunnen gebruikers snel projecten bekijken op basis van hun huidige status.

**Toegang tot het filter:**
1. Navigeer naar de module **Projecten**.
2. Klik op de **Zwevende actieknop (FAB)** in de rechterbenedenhoek.
3. Er verschijnt een filterpaneel met de titel **“Filteren op Fase”** met de beschikbare opties (Open projecten, Alle fasen, Taken, In uitvoering, Klaar, Geannuleerd).

**Hoe het werkt:**
Wanneer een fase wordt geselecteerd, wordt de projectenlijst automatisch vernieuwd om alleen overeenkomende projecten weer te geven (als u bijvoorbeeld **In uitvoering** selecteert, worden alleen projecten weergegeven die momenteel in actieve ontwikkeling zijn). Standaard worden bij het openen van een projectlijstoverzicht alle fasen getoond. Gebruikers kunnen het filter wijzigen of wissen door het paneel opnieuw te openen en **Alle fasen** te selecteren.