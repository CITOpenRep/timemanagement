---
title: Bouw en verpakking
sidebar_label: Bouw en verpakking
---

# Bouw en verpakking

De app-build en de Docusaurus-site-build zijn opzettelijk gescheiden.

## Applicatie bouwen

De huidige app-build wordt aangestuurd door projectbestanden zoals:

- `clickable.yaml`
- `CMakeLists.txt`
- `manifest.json.in`
- Metagegevens van het bureaublad en het apparaatstartprogramma in de hoofdmap van de repository

Voor het testen van applicaties concentreert de workflow van de bijdrager zich nog steeds op:

```bash
clickable desktop
clickable build
clickable review
```

## Website bouwen

De documentatiesite bevindt zich in `website/` en gebruikt Docusaurus.

Typische lokale workflow:

```bash
cd website
npm install
npm run start
```

Productieopbouw:

```bash
cd website
npm run build
```

## Scheiding van zorgen

Deze scheiding houdt in:

- documentatie-implementatie onafhankelijk van app-verpakking
- website-afhankelijkheden uit de runtime-app-stack
- docs-iteratie snel zonder het Clickable- of CMake-gedrag te beïnvloeden
