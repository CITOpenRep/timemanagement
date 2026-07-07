# Instellingen

In het gedeelte **Instellingen** kunnen gebruikers de applicatie configureren volgens hun voorkeuren en functies op systeemniveau beheren, zoals verbonden accounts, meldingen, synchronisatie en uiterlijk.

Dit gedeelte is vooral handig voor nieuwe gebruikers om hun ervaring te personaliseren en ervoor te zorgen dat de app naadloos samenwerkt met externe systemen.

---

## Accessing Settings
To open **Settings**:
1. Click on the **Menu (☰)** icon in the top-left corner.
2. Select **Settings** from the sidebar navigation.

The Settings screen is divided into multiple configurable sections.

---

## Overzicht instellingen
De module Instellingen bevat de volgende opties:
1. Verbonden accounts
2. Meldingen
3. Achtergrondsynchronisatie
4. Thema-instellingen

Elke optie wordt hieronder in detail uitgelegd.

---

## Verbonden accounts
In het gedeelte **Verbonden accounts** kunnen gebruikers meerdere omgevingen of instanties (zoals lokale, test- of productiesystemen) koppelen en beheren.

### Doel:
* Maak integratie met verschillende servers of omgevingen mogelijk.
* Schakelen tussen meerdere accounts toestaan.
* Beheer de synchronisatie tussen systemen.

### Sleutelelementen:
* **Accountlijst**: toont alle geconfigureerde accounts.
* **Accounttype-indicator**: geeft aan of het een lokaal of serverexemplaar is.
* **Instance-URL**: geeft de verbonden serverlink weer.
* **Statusindicator**:
    * *In uitvoering*: synchronisatie of verbinding is gaande.
    * *Succesvol*: Verbinding is actief en werkt.
* **Synchronisatiepictogram (🔄)**: vernieuw of synchroniseer het account handmatig.
* **Checkbox Selector**: Activeer of selecteer een specifiek account.
* **Knop Toevoegen (➕)**: Voeg een nieuw account toe.

---

## Een nieuw account toevoegen
Klik op het **(➕)**-pictogram om een ​​nieuw account toe te voegen.

### Secties in het scherm “Account aanmaken”:
1. Accountgegevens
2. Serververbinding
3. Referenties
4. Synchronisatievoorkeuren

Elke sectie moet zorgvuldig worden ingevuld om een ​​succesvolle verbinding te garanderen.

### Accountgegevens
In deze sectie wordt gedefinieerd hoe het account in de applicatie zal verschijnen.

**Velden:**
* **Accountnaam**: Voer een herkenbare naam in (bijvoorbeeld *Werkaccount*, *Testserver*). Deze naam helpt bij het identificeren van het account bij het schakelen tussen meerdere accounts.

### Serververbinding
Deze sectie wordt gebruikt om de app met uw server te verbinden.

**Velden:**
* **URL**: Voer de server-URL in. Voorbeeld: `https://tma.onestein.eu/`.

Nadat u de URL heeft ingevoerd, klikt u op **Databases ophalen**.

### Databases ophalen
Als u op **Databases ophalen** klikt, wordt een proces gestart om beschikbare databases van de opgegeven server op te halen.

**Systeemgedrag:**
* De app maakt verbinding met de server.
* Er wordt een nieuw scherm of dialoogvenster geopend.
* Er wordt een lijst met beschikbare databases weergegeven.

**Gebruikersacties vereist:**
Op het databaseselectiescherm:
* Bekijk de lijst met beschikbare databases.
* Selecteer de juiste databank.
* Voer indien nodig handmatig de **Databasenaam** in.

**Opmerkingen:**
* Als er geen databases verschijnen: Controleer de server-URL, controleer de internetverbinding en zorg ervoor dat de server toegankelijk is.
* Als er meerdere databases worden vermeld: Kies de juiste op basis van uw omgeving.

Eenmaal geselecteerd, bevestigt u en keert u terug naar het accountconfiguratiescherm.

### Databasenaam
Na het ophalen van databases:
* De geselecteerde databasenaam wordt automatisch ingevuld of handmatig ingevoerd.
* Zorg ervoor dat de juiste database is geselecteerd voordat u doorgaat.

### Referenties
Dit gedeelte wordt gebruikt om uw account te verifiëren.

**Velden:**
* **Gebruikersnaam**: Voer uw login-gebruikersnaam in.
* **Verbinden met**: Verbinden met wachtwoord of API-sleutel.
* **Wachtwoord**: Voer uw accountwachtwoord in. Gebruik de zichtbaarheidsschakelaar (👁) om het wachtwoord te bekijken of te verbergen.

### Synchronisatievoorkeuren
In dit gedeelte kunt u bepalen hoe gegevenssynchronisatie werkt.

**Opties:**
* **Aangepaste synchronisatie-instellingen (tuimelschakelaar)**
    * Indien ingeschakeld: u kunt aangepast synchronisatiegedrag definiëren.
    * Indien uitgeschakeld: het systeem gebruikt standaardinstellingen (Sync-interval: ~15 minuten; Richting: tweerichtingssynchronisatie waarbij gegevens zowel worden verzonden als ontvangen).

### Accountconfiguratie voltooien
Na het invullen van alle verplichte velden:
1. Klik op de knop **✔ (Opslaan/bevestigen)** in de rechterbovenhoek.
2. Het systeem zal: de inloggegevens valideren, de verbinding tot stand brengen en het account toevoegen aan de lijst met verbonden accounts.

### Gedrag na installatie
Zodra het account succesvol is aangemaakt:
* Het verschijnt onder **Verbonden accounts**.
* Je kunt het activeren via het selectievakje en het handmatig synchroniseren met het 🔄-pictogram.
* De initiële synchronisatie kan automatisch beginnen.

---

## Accounts beheren en synchroniseren

### Schakelen tussen accounts
* Gebruik het **selectievakje** naast een account om deze te activeren.
* Er mag slechts één account tegelijk actief zijn.
* Het actieve account bepaalt waar uw gegevens worden gesynchroniseerd en opgeslagen.

### Een account synchroniseren
* Klik op het pictogram **Synchroniseren (🔄)** naast een account.
* Het systeem haalt de nieuwste gegevens op en werkt taken, projecten, urenstaten, enz. bij.
* De status wordt automatisch bijgewerkt (bijvoorbeeld *In uitvoering → Succesvol*).

### Accounts beheren (veegacties)
De lijst **Verbonden accounts** ondersteunt snelle acties met behulp van veegbewegingen, waardoor gebruikers accounts efficiënt kunnen beheren zonder extra schermen te openen.

**Doel:** Bied snellere toegang tot veelvoorkomende acties, verbeter de bruikbaarheid (vooral op aanraakapparaten) en verminder de navigatiestappen.

**Beschikbare acties:**
* **Veeg naar rechts (→): Account bewerken**
    * Veeg een accountitem naar **rechts** om de optie **Bewerken** weer te geven.
    * Gebruik dit om de exemplaar-URL bij te werken, inloggegevens te wijzigen en de accountconfiguratie te wijzigen.
* **Veeg naar links (←): Opties bekijken en verwijderen**
    * Veeg een accountitem naar **links** om twee actiepictogrammen weer te geven:
        1. **Bekijken**: Opent accountgegevens en geeft configuratie- en verbindingsinformatie weer.
        2. **Verwijderen**: Verwijdert het account uit de app.

---

## Meldingen
In het gedeelte **Meldingen** bepaalt u hoe en wanneer de toepassing u waarschuwt.

### Pushmeldingen
Hiermee kunt u bepalen of de applicatie waarschuwingen rechtstreeks naar uw apparaat kan sturen.

**Sleuteloptie:**
* **Meldingen inschakelen (tuimelschakelaar)**
    * **AAN**: de app verzendt realtime meldingen voor updates zoals taakwijzigingen, projectupdates en activiteitenlogboeken.
    * **UIT**: Alle pushmeldingen worden uitgeschakeld.

**Wanneer inschakelen:** Als u direct op de hoogte wilt blijven van updates, of als u afhankelijk bent van herinneringen voor taak-/projectupdates en activiteiten.
**Wanneer uitschakelen:** Als u minder onderbrekingen wenst of als u updates alleen handmatig in de app controleert.

### Meldingsschema
Hiermee kunt u bepalen *wanneer* meldingen worden afgeleverd, zodat u er zeker van bent dat ze alleen binnenkomen tijdens de door u gewenste werkuren. Dit is vooral handig om de balans tussen werk en privéleven te behouden en meldingen buiten kantooruren te vermijden.

**Schema inschakelen:**
* **AAN**: Meldingen worden alleen verzonden tijdens geconfigureerde dagen en uren.
* **UIT**: Meldingen kunnen op elk moment worden verzonden.

**Tijdzone:**
* Selecteer uw **Tijdzone** om ervoor te zorgen dat meldingen overeenkomen met uw lokale tijd. De standaardwaarde is doorgaans ingesteld op **Systeemstandaard**.

**Werkdagen:**
* Opties zijn van maandag tot en met zondag.
* Alleen geselecteerde dagen staan ​​meldingen toe, terwijl niet-geselecteerde dagen alle meldingen blokkeren.

**Werktijden:**
* **Vanaf**: starttijd (bijvoorbeeld 09:00 uur).
* **Tot**: eindtijd (bijvoorbeeld 18:00 uur).
* Meldingen worden alleen binnen het geselecteerde tijdsbereik verzonden.

**Voorbeeldconfiguratie (standaardwerkschema):**
* Meldingen inschakelen: AAN
* Schema inschakelen: AAN
* Werkdagen: maandag tot en met vrijdag
* Werktijden: 09:00 tot 18:00 uur
* *Resultaat:* U ontvangt meldingen alleen tijdens kantooruren op weekdagen.

---

## Achtergrondsynchronisatie
De functie **Achtergrondsynchronisatie** zorgt ervoor dat uw gegevens automatisch bijgewerkt blijven.

**Functies:**
* Schakel automatische synchronisatie in.
* Synchronisatiefrequentie instellen.
* Synchroniseer taken, urenstaten, projecten, projectupdates, enz. op de achtergrond.

**Voordelen:** Vermindert handmatige inspanningen, houdt gegevens consistent op alle apparaten en accounts en zorgt voor realtime updates.

### Overzicht instellingen voor achtergrondsynchronisatie
In dit scherm kunt u configureren hoe en wanneer uw gegevens worden gesynchroniseerd met de server. Deze functie werkt op de achtergrond zonder handmatige tussenkomst.

**Belangrijke configuratieopties:**
1. **Enable AutoSync (Toggle Switch)**
    * **AAN**: Automatische synchronisatie is ingeschakeld en de app synchroniseert gegevens met gedefinieerde intervallen.
    * **UIT**: Achtergrondsynchronisatie is uitgeschakeld en gegevens moeten handmatig worden gesynchroniseerd.
2. **Synchronisatie-interval**
    * Definieert hoe vaak de toepassing automatische synchronisatie uitvoert.
    * Voorbeeldopties: 5 minuten, 15 minuten, 30 minuten of meer.
    * Aanbeveling: gebruik **5–15 minuten** voor actieve gebruikers; gebruik langere intervallen om batterij- en datagebruik te besparen.
3. **Synchronisatierichting**
    * **Beide (omhoog en omlaag)** *(standaard)*: uploadt lokale wijzigingen naar de server en downloadt updates van de server.
    * **Alleen uploaden (omhoog)**: verzendt lokale gegevens naar de server, maar haalt geen updates op.
    * **Alleen downloaden (down)**: haalt updates op van de server, maar uploadt geen lokale wijzigingen.
4. **Herstart achtergronddaemon**
    * Hiermee kunt u de achtergrondsynchronisatieservice opnieuw starten. Gebruik dit als de synchronisatie vast lijkt te lopen, na het wijzigen van de synchronisatie-instellingen of nadat u opnieuw verbinding heeft gemaakt met een account.

### Hoe achtergrondsynchronisatie werkt
Wanneer AutoSync is ingeschakeld:
1. De app voert een achtergrondservice uit.
2. Bij elk interval maakt het verbinding met de geconfigureerde account/server, uploadt nieuwe of gewijzigde gegevens (taken, urenstaten, enz.) en downloadt updates van de server.
3. Updates worden automatisch toegepast zonder actie van de gebruiker.

**Beste praktijken:**
* Houd AutoSync ingeschakeld voor een naadloze ervaring.
* Gebruik een interval van 15 minuten voor evenwichtige prestaties en batterijgebruik.
* Houd synchronisatierichting = beide, tenzij u een specifieke behoefte heeft.
* Start de daemon opnieuw als er synchronisatieproblemen optreden.

---

## Thema-instellingen
In het gedeelte **Thema-instellingen** kunnen gebruikers de visuele weergave van de applicatie aanpassen.

**Voordelen:** Verbetert de leesbaarheid, verbetert het gebruikerscomfort tijdens langdurig gebruik en ondersteunt toegankelijkheidsvoorkeuren.

### Beschikbare thema-opties
1. **Lichtthema**: heldere en overzichtelijke interface die lichte achtergronden met donkere tekst gebruikt. Geschikt voor goed verlichte omgevingen en gebruik overdag.
2. **Donker thema**: donkere achtergrond met lichtere tekst. Vermindert de helderheid en schittering van het scherm.

### Hoe u het thema kunt wijzigen
1. Selecteer **Thema-instellingen**.
2. Kies een van de beschikbare opties: Licht thema of Donker thema.
3. Het geselecteerde thema wordt onmiddellijk toegepast.

**Systeemgedrag:**
* Het momenteel geselecteerde thema is gemarkeerd met een **controle-indicator (✔)**.
* Er kan slechts één thema tegelijk actief zijn.
* Themawijzigingen worden **onmiddellijk** op alle schermen toegepast (herstarten of vernieuwen is niet vereist).
* Het geselecteerde thema wordt **automatisch opgeslagen** en blijft gedurende sessies bestaan.