---
title: Translation and Localization Guide
sidebar_label: Translation & Localization
description: A contributor's guide to translating documentation, pages, and UI elements for the TimeManagement website.
---

# Translation & Localization Guide

This guide describes how to translate the TimeManagement documentation website. It covers the complete workflow for translating both core markdown content (documentation and static pages) and UI strings (theme code and sidebar categories).

---

## 1. Overview of Translation Architecture

This website is built with Docusaurus and supports multilingual content. The current configured locales are:
* **English (`en`)**: The default source language.
* **Dutch (`nl`)**: The target translation locale.

All translation assets are stored in the `website/i18n/` directory.

### Directory Structure

```text
website/
├── docs/                                  # Source English documentation (Next / Unreleased)
├── versioned_docs/
│   └── version-1.2.9/                     # Source English documentation (Version 1.2.9)
└── i18n/
    └── nl/                                # Dutch Translation Assets
        ├── code.json                      # Translated UI strings (navbar, footer, theme buttons)
        ├── docusaurus-plugin-content-docs/
        │   ├── current.json               # Translated sidebar labels (Next / Unreleased)
        │   ├── version-1.2.9.json         # Translated sidebar labels (Version 1.2.9)
        │   ├── current/                   # Translated Markdown docs (Next / Unreleased)
        │   └── version-1.2.9/             # Translated Markdown docs (Version 1.2.9)
        └── docusaurus-plugin-content-pages/ # Translated static JS/React page elements
```

---

## 2. Translating Markdown Content

To translate page content or documentation, copy the source markdown files into the appropriate location in the `i18n/nl/` subdirectory, keeping the exact same folder structure and filenames.

### Workflow for "Next" (Unreleased) Docs
1. Locate the source English file under `website/docs/` (e.g., `website/docs/contributing/getting-started.md`).
2. Copy it to the equivalent path in the current translation directory:
   `website/i18n/nl/docusaurus-plugin-content-docs/current/contributing/getting-started.md`
3. Translate the Markdown content.

### Workflow for Versioned Docs (Version 1.2.9)
1. Locate the source English file under `website/versioned_docs/version-1.2.9/` (e.g., `website/versioned_docs/version-1.2.9/technical/release-process.md`).
2. Copy it to the equivalent path in the versioned translation directory:
   `website/i18n/nl/docusaurus-plugin-content-docs/version-1.2.9/technical/release-process.md`
3. Translate the Markdown content.

:::note
If the destination subfolder (e.g., `contributing/` or `technical/`) does not exist under `i18n/nl/...`, create it before copying.
:::

### Workflow for Static Pages (website/src/pages/)
1. Locate the page you want to translate (e.g., `website/src/pages/index.js`).
2. Copy it to:
   `website/i18n/nl/docusaurus-plugin-content-pages/index.js`
3. Translate the textual content inside the page file.

---

## 3. Translating UI Strings & Sidebars (JSON)

Docusaurus uses JSON files to localize UI components (such as buttons, breadcrumbs, search labels, and navbar/footer links) and sidebar category labels.

### Step 1: Extract/Sync UI Translation Strings
If you add new UI items, pages, or versioned sidebars, sync the translation files by running the following command in the `website/` directory:

```bash
npm run write-translations -- --locale nl
```

This updates or generates three key JSON translation files:
1. `website/i18n/nl/code.json` (extracted from React pages, theme components, and `docusaurus.config.js` items).
2. `website/i18n/nl/docusaurus-plugin-content-docs/current.json` (extracted from sidebar category names defined in `website/sidebars.js`).
3. `website/i18n/nl/docusaurus-plugin-content-docs/version-1.2.9.json` (extracted from versioned sidebar category names defined in `website/versioned_sidebars/version-1.2.9-sidebars.json`).

### Step 2: Translate the JSON Files
Open the updated JSON file and translate the `"message"` value for each key. Do **not** alter the key itself or the `"description"` fields.

Example (`version-1.2.9.json`):
```json
{
  "sidebar.docs.category.Contributor": {
    "message": "Bijdrager",
    "description": "The label for category 'Contributor' in sidebar 'docs'"
  }
}
```

---

## 4. Local Development and Preview

To verify that translations are correctly mapped and styled:

### Start the Local Server in the Dutch Locale
Run this command in the `website/` directory:

```bash
npm run start -- --locale nl
```
This serves the Dutch translation directly at `http://localhost:3000/timemanagement/nl/`.

### Run a Complete Production Build
To ensure that all pages and both locales build without broken links:

```bash
npm run build
```
This builds both English (`/timemanagement/`) and Dutch (`/timemanagement/nl/`) versions of the site to the `build/` directory.

---

## 5. Translation Best Practices

:::tip
* **Frontmatter**: Translate the `title`, `sidebar_label`, and `description` in the Markdown frontmatter. Do **not** change key names or variables like `slug`.
* **Code Blocks**: Do not translate content inside code blocks (```` ``` ````) or inline code (` ` `) unless they are code comments meant to be read by users.
* **Component Props**: In MDX documents, translate the text content but do not translate React component names or prop keys (e.g., `<Admonition title="Translate Me">`).
* **HTML Tags**: Keep HTML tags intact (e.g., `<br />`, `<strong>`).
:::
