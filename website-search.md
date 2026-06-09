# PLAN-website-search

## Overview
This plan outlines the integration of a fast, offline, and lightweight client-side search engine into the TimeManagement documentation website using `@easyops-cn/docusaurus-search-local`. This allows users to easily search through all static Markdown documentation pages directly from the website header.

- **Project Type**: WEB
- **Target Component**: Docusaurus Documentation Website (`website/`)

## Success Criteria
1. The search bar is visible in the global navigation header.
2. Users can search and find relevant documentation from static Markdown files (User, Technical, and Contributing docs).
3. Search index is generated during the build process (`npm run build`).
4. Search runs entirely client-side without external API calls.
5. The production build of the website runs and compiles successfully.
6. The search UI matches the website's existing modern/dark design language (no purple accents, clean typography).

## Tech Stack
- **Search Library**: `@easyops-cn/docusaurus-search-local` (v0.46.1+ for Docusaurus v3 & React 19 compatibility)
- **Framework**: Docusaurus v3
- **Styling**: Custom CSS overrides if needed to fit the design system

## File Structure Changes
```plaintext
website/
├── docusaurus.config.js       # Configure search-local plugin
└── package.json               # Add @easyops-cn/docusaurus-search-local dependency
```

---

## Task Breakdown

### Task 1: Install Search Dependency
- **Agent**: `frontend-specialist`
- **Skills**: `clean-code`
- **Priority**: P0
- **Dependencies**: None
- **INPUT**: `website/package.json`
- **OUTPUT**: Dev dependency added, `node_modules` updated
- **VERIFY**: Run `npm install` in the `website/` directory to ensure package installs cleanly.
- **Rollback Strategy**: Discard `package.json` change and delete `node_modules` lockfile edits.

### Task 2: Configure Docusaurus Search Local Plugin
- **Agent**: `frontend-specialist`
- **Skills**: `clean-code`
- **Priority**: P1
- **Dependencies**: Task 1
- **INPUT**: `website/docusaurus.config.js`
- **OUTPUT**: Plugin added to the configuration
- **VERIFY**: Ensure syntax is valid and it is loaded via `themes` (as required by `@easyops-cn/docusaurus-search-local` which is a theme plugin).
- **Rollback Strategy**: Revert `docusaurus.config.js` changes to git HEAD.

### Task 3: Build Documentation Website & Generate Search Index
- **Agent**: `frontend-specialist`
- **Skills**: `performance-profiling`
- **Priority**: P2
- **Dependencies**: Task 2
- **INPUT**: `website/src`, `website/docs`
- **OUTPUT**: Production build in `website/build`
- **VERIFY**: Run `npm run build` inside `website/`. Ensure the search index is built and serialized correctly into JSON files in the build output.
- **Rollback Strategy**: Rebuild with clean cache (`npm run clear` followed by `npm run build`).

### Task 4: Verify Search Functionality in Browser
- **Agent**: `frontend-specialist`
- **Skills**: `webapp-testing`
- **Priority**: P3
- **Dependencies**: Task 3
- **INPUT**: Local preview server running via `npm run serve`
- **OUTPUT**: Interactive verification report
- **VERIFY**: Run local server and use browser subagent to interactively type a query (e.g. "odoo" or "architecture") and confirm matching documents appear and are clickable.
- **Rollback Strategy**: Check search configuration options (like language, indexing strategy) if matches don't appear.

---

## Phase X: Final Verification & Checklist

- [x] **Purple Ban**: Verify no purple/violet accents are added to the search UI.
- [x] **Template Ban**: Verify search input coordinates clean and modern with the custom hero/style.
- [x] **Lint/Typecheck**: Run `npm run lint` if configured in the website.
- [x] **Production Build**: Verify `npm run build` completes successfully.
- [x] **UX Audit**: Verify touch target size and accessibility for search input.
- [x] **Playwright/E2E check**: Verify search interaction in browser.

### ✅ PHASE X COMPLETE
- Lint: [x]
- Security: [x]
- Build: [x]
- Date: 2026-06-09
