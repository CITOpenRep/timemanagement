---
title: Richtlijnen voor pull-aanvragen
sidebar_label: Richtlijnen voor pull-aanvragen
---

# Richtlijnen voor pull-aanvragen

Deze pagina migreert de huidige PR-richtlijnen voor de repository naar de site.

## Branchestrategie

- filiaal van `main`
- gebruik bestandsnamen zoals `feature/add-timesheet-export`
- houd het werk waar mogelijk beperkt tot één logische verandering

## Voordat u een PR opent

### Codekwaliteit

- code moet de relevante stappen voor het bouwen en beoordelen van apps doorstaan
- geen hardgecodeerde inloggegevens, URL's of API-sleutels
- er is geen foutopsporingsregistratie meer in de productiecode
- volg de bestaande codestijl en conventies

### Testen

- testen op desktop met `clickable desktop`
- test indien mogelijk op apparaat met `clickable install`
- voor CLI-georiënteerde Python-wijzigingen verifieer je met `python3 -m py_compile <file>`

### Documentatie

- update relevante documenten bij het toevoegen van wijziging van functionaliteit
- voeg alleen inline-opmerkingen toe als de code niet voor de hand ligt
- update naamgeving architectuurcontracten indien van toepassing

## PR-beschrijving

Elke PR moet de volgende omvatten:

- samenvatting
- Soort wijzigen
- testnotities
- screenshots voor UI-wijzigingen

## Huidige bron

De oorspronkelijke projectbron blijft tijdens de migratie in de repository:

- [Bron van richtlijnen voor pull-aanvragen](https://github.com/CITOpenRep/timemanagement/blob/main/docs/PR-GUIDELINES.md)
