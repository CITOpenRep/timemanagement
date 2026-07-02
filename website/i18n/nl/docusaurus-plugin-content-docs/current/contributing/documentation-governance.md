---
title: Documentatiebeheer
sidebar_label: Documentatiebeheer
---

# Documentatiebeheer

De Docusaurus-site wordt het belangrijkste openbare documentatiemateriaal voor het project.

## Vuistregels

- update gebruikersdocumenten wanneer gedrag dat zichtbaar is voor gebruikers verandert
- update technische documenten wanneer code-eigendom, architectuur of build-stroom verandert
- update bijdragende documenten wanneer de workflow van beoordelingsverwachtingen verandert
- houd de startpagina gericht op het productverhaal, niet op diepgaande implementatiedetails

## Eigendomsmodel

Aanbevolen lichtgewicht eigendom:

- één beheerder is eigenaar van de informatiearchitectuur en de consistentie van de startpagina
- feature-auteurs eigen correctheid van feature-specifieke pagina's
- reviewers controleren de impact van de documentatie als onderdeel van PR-beoordeling

## Levenscyclus van inhoud

Tijdens de migratieperiode:

- de root `README.md` blijft kort en nuttig naar de site
- oudere bestanden onder `docs/` blijven als bronmateriaal
- samengestelde, doelgroepgerichte begeleiding leeft in `website/docs/`
