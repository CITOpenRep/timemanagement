---
title: Gids voor vertaling en lokalisatie
sidebar_label: Vertaling & Lokalisatie
description: Een handleiding voor bijdragers over het vertalen van documentatie, pagina's en UI-elementen voor de TimeManagement-website.
---

# Gids voor vertaling & lokalisatie

Deze gids beschrijft hoe u de TimeManagement-documentatiewebsite kunt vertalen. Het behandelt de volledige workflow voor het vertalen van zowel de core markdown-inhoud (documentatie en statische pagina's) als UI-strings (thema-code en zijbalkcategorieën).

---

## 1. Overzicht van de vertaalarchitectuur

Deze website is gebouwd met Docusaurus en ondersteunt meertalige inhoud. De momenteel geconfigureerde locales zijn:
* **Engels (`en`)**: De standaard brontaal.
* **Nederlands (`nl`)**: De doel-locale voor vertaling.

Alle vertaalactiva zijn opgeslagen in de map `website/i18n/`.

### Mapstructuur

```text
website/
├── docs/                                  # Bron Engelse documentatie (Volgende / Onuitgegeven)
├── versioned_docs/
│   └── version-1.2.9/                     # Bron Engelse documentatie (Versie 1.2.9)
└── i18n/
    └── nl/                                # Nederlandse Vertaalactiva
        ├── code.json                      # Vertaalde UI-strings (navigatiebalk, footer, themaknoppen)
        ├── docusaurus-plugin-content-docs/
        │   ├── current.json               # Vertaalde zijbalklabels (Volgende / Onuitgegeven)
        │   ├── version-1.2.9.json         # Vertaalde zijbalklabels (Versie 1.2.9)
        │   ├── current/                   # Vertaalde Markdown-documenten (Volgende / Onuitgegeven)
        │   └── version-1.2.9/             # Vertaalde Markdown-documenten (Versie 1.2.9)
        └── docusaurus-plugin-content-pages/ # Vertaalde statische JS/React pagina-elementen
```

---

## 2. Markdown-inhoud vertalen

Om pagina-inhoud of documentatie te vertalen, kopieert u de bron-markdownbestanden naar de juiste locatie in de submap `i18n/nl/`, met behoud van exact dezelfde mapstructuur en bestandsnamen.

### Workflow voor "Volgende" (Onuitgegeven) Docs
1. Zoek het Engelse bronbestand onder `website/docs/` (bijv. `website/docs/contributing/getting-started.md`).
2. Kopieer het naar het equivalente pad in de huidige vertaalmap:
   `website/i18n/nl/docusaurus-plugin-content-docs/current/contributing/getting-started.md`
3. Vertaal de Markdown-inhoud.

### Workflow voor geversioneerde documenten (Versie 1.2.9)
1. Zoek het Engelse bronbestand onder `website/versioned_docs/version-1.2.9/` (bijv. `website/versioned_docs/version-1.2.9/technical/release-process.md`).
2. Kopieer het naar het equivalente pad in de geversioneerde vertaalmap:
   `website/i18n/nl/docusaurus-plugin-content-docs/version-1.2.9/technical/release-process.md`
3. Vertaal de Markdown-inhoud.

:::note
Als de submap van bestemming (bijv. `contributing/` of `technical/`) niet bestaat onder `i18n/nl/...`, maak deze dan aan voordat u kopieert.
:::

### Workflow voor statische pagina's (website/src/pages/)
1. Zoek de pagina die u wilt vertalen (bijv. `website/src/pages/index.js`).
2. Kopieer het naar:
   `website/i18n/nl/docusaurus-plugin-content-pages/index.js`
3. Vertaal de tekstuele inhoud in het paginabestand.

---

## 3. UI-strings en zijbalken vertalen (JSON)

Docusaurus gebruikt JSON-bestanden om UI-componenten (zoals knoppen, broodkruimels, zoeklabels en navbar-/footerlinks) en zijbalkcategorielabels te lokaliseren.

### Stap 1: UI-vertaalstrings extraheren/synchroniseren
Als u nieuwe UI-items, pagina's of geversioneerde zijbalken toevoegt, synchroniseert u de vertaalbestanden door de volgende opdracht uit te voeren in de map `website/`:

```bash
npm run write-translations -- --locale nl
```

Dit bijwerkt of genereert drie belangrijke JSON-vertaalbestanden:
1. `website/i18n/nl/code.json` (geëxtraheerd uit React-pagina's, themacomponenten en `docusaurus.config.js`-items).
2. `website/i18n/nl/docusaurus-plugin-content-docs/current.json` (geëxtraheerd uit zijbalkcategorienamen gedefinieerd in `website/sidebars.js`).
3. `website/i18n/nl/docusaurus-plugin-content-docs/version-1.2.9.json` (geëxtraheerd uit geversioneerde zijbalkcategorienamen gedefinieerd in `website/versioned_sidebars/version-1.2.9-sidebars.json`).

### Stap 2: Vertaal de JSON-bestanden
Open het bijgewerkte JSON-bestand en vertaal de waarde `"message"` voor elke sleutel. Wijzig de sleutel zelf of de velden `"description"` niet.

Voorbeeld (`version-1.2.9.json`):
```json
{
  "sidebar.docs.category.Contributor": {
    "message": "Bijdrager",
    "description": "The label for category 'Contributor' in sidebar 'docs'"
  }
}
```

---

## 4. Lokale ontwikkeling en preview

Om te controleren of vertalingen correct zijn toegewezen en gestyled:

### Start de lokale server in de Nederlandse locale
Voer deze opdracht uit in de map `website/`:

```bash
npm run start -- --locale nl
```
Dit serveert de Nederlandse vertaling rechtstreeks op `http://localhost:3000/timemanagement/nl/`.

### Voer een volledige productiebuild uit
Om ervoor te zorgen dat alle pagina's en beide locales worden gebouwd zonder gebroken links:

```bash
npm run build
```
Dit bouwt zowel de Engelse (`/timemanagement/`) als de Nederlandse (`/timemanagement/nl/`) versie van de site naar de map `build/`.

---

## 5. Beste praktijken voor vertaling

:::tip
* **Frontmatter**: Vertaal de `title`, `sidebar_label`, en `description` in de Markdown frontmatter. Wijzig geen sleutelnamen of variabelen zoals `slug`.
* **Codeblokken**: Vertaal geen inhoud binnen codeblokken (```` ``` ````) of inline code (` ` `) tenzij het om code-commentaren gaat die bedoeld zijn om door gebruikers gelezen te worden.
* **Component-props**: In MDX-documenten vertaalt u de tekstinhoud, maar vertaalt u geen React-componentnamen of prop-sleutels (bijv. `<Admonition title="Vertaal Mij">`).
* **HTML-tags**: Houd HTML-tags intact (bijv. `<br />`, `<strong>`).
:::
