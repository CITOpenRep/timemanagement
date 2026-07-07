---
title: Opslagorganisatie
sidebar_label: Opslagorganisatie
---

# Opslagorganisatie

Deze pagina is de Docusaurus-migratie van de repositoryorganisatierichtlijnen.

## Principes van opslag

De repository is georganiseerd op basis van verantwoordelijkheid:

- `qml/` bevat de UI-laag
- `models/` bevat JavaScript-gegevens en statushelpers die door QML worden gebruikt
- `src/` bevat Python-backend, synchronisatie, daemon en hulpprogrammalogica
- `assets/` bevat merkitems op pakketniveau
- `docs/` bevat brondocumentatie
- `scripts/` bevat lokale onderhouds- en validatiescripts

Binnen elk gebied moeten bestanden eerst op kenmerk worden gegroepeerd en vervolgens op technische rol.

## QML UI-laag

De `qml/` boom is al opgesplitst in stabiele gebieden:

- `qml/app/` voor pagina's op shell-, opstart-, navigatie- en app-niveau
- `qml/components/` voor gedeelde UI-bouwstenen
- `qml/features/` voor bedrijfsdomeinfuncties met lokale pagina's en componenten
- `qml/images/` voor runtime UI-afbeeldingsitems

## JavaScript-modellaag

De map `models/` bevat herbruikbare JavaScript-modules die zijn geïmporteerd door QML.

Gebruik `models/` voor hulp bij meerdere functies en gedeelde app-status. Bewaar functiespecifiek JavaScript in functiemappen, tenzij het breed gedeeld wordt.

## Python-backendlaag

De map `src/` bevat runtime Python voor:

- backend-overbrugging
- daemon-logica
- gedrag van externe synchronisatie
- configuratie en loggen
- helper tools that ship with the app

## Documentatie notitie

De oorspronkelijke langere bron voor deze richtlijnen blijft tijdens de migratie in de opslagplaats:

- [Bron van technische bestandsorganisatie](https://github.com/CITOpenRep/timemanagement/blob/main/docs/TECHNICAL-FILE-ORGANIZATION.md)
