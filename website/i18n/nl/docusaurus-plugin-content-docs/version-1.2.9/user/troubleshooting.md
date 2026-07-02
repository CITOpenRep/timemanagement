---
title: Problemen oplossen
sidebar_label: Problemen oplossen
---

# Problemen oplossen

Gebruik deze pagina als eerste stop voor veelvoorkomende problemen totdat speciale ondersteuningsrunbooks worden toegevoegd.

## Bouwen en opstarten

Controleer deze eerst:

- `clickable --version` keert succesvol terug
- Docker is beschikbaar wanneer uw bouwstroom ervan afhankelijk is
- `clickable desktop` wordt uitgevoerd vanuit de hoofdmap van de repository

## Synchronisatiegerelateerde problemen

Als het synchronisatiegedrag mislukt:

- controleer de account- en eindpuntinstellingen
- inspecteer Python-synchronisatiemodules onder `src/`
- bekijk daemon-gerelateerde codepaden zoals `src/daemon.py` en `src/daemon_bootstrap.py`

## Database-aantekeningen

De repository verwijst naar een lokaal applicatiedatabasepad onder:

```text
~/.clickable/home/.local/share/ubtms/Databases
```

## Wanneer moet je escaleren?

Open een GitHub-probleem wanneer:

- de app start niet meer op het bureaublad
- apparaatinstallatie mislukt consequent
- Het synchronisatiegedrag neemt af na een upgrade
- een functiespecifiek scherm breekt in een van de bekende QML-functiegebieden
