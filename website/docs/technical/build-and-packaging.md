---
title: Build and Packaging
sidebar_label: Build and Packaging
---

# Build and Packaging

The app build and the Docusaurus site build are intentionally separate.

## Application build

The current app build is driven by project files such as:

- `clickable.yaml`
- `CMakeLists.txt`
- `manifest.json.in`
- desktop and device launcher metadata at the repository root

For application testing, the contributor workflow still centers on:

```bash
clickable desktop
clickable build
clickable review
```

## Website build

The documentation site lives in `website/` and uses Docusaurus.

Typical local workflow:

```bash
cd website
npm install
npm run start
```

Production build:

```bash
cd website
npm run build
```

## Separation of concerns

This separation keeps:

- documentation deployment independent from app packaging
- website dependencies out of the runtime app stack
- docs iteration fast without affecting Clickable or CMake behavior
