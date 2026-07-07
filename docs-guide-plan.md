# Create Documentation and Versioning Contributor Guide

## Goal
Add a comprehensive contributor guide on creating documentation, Docusaurus native versioning, and local previewing to the Docusaurus site, and register it in the sidebar.

## Tasks
- [x] Task 1: Create `website/docs/contributing/documentation-guide.md` with:
  - Document structure (paths, folder organization)
  - Page creation guidelines (frontmatter, MDX, Mermaid charts)
  - Sidebar configuration instructions
  - Native Docusaurus versioning workflow details (how to run `npm run docusaurus docs:version <version>`, folder structure: `versioned_docs`, `versioned_sidebars`, `versions.json`)
  - Local development commands (`npm install`, `npm start`, `npm run build`)
  → Verify: File exists with correct content.
- [x] Task 2: Modify `website/sidebars.js` to include the new document in the `Contributor` category.
  → Verify: `"contributing/documentation-guide"` is listed under `Contributor` in `sidebars.js`.
- [x] Task 3: Build the website locally to verify there are no broken links or build errors.
  → Verify: `npm run build` runs successfully in the `website` directory.
- [x] Task 4: Add the guide to version 1.2.9 documentation and update its sidebar.
  → Verify: `website/versioned_docs/version-1.2.9/contributing/documentation-guide.md` exists and is registered in `website/versioned_sidebars/version-1.2.9-sidebars.json`.

## Done When
- `website/docs/contributing/documentation-guide.md` is created.
- `website/sidebars.js` is updated.
- `website/versioned_docs/version-1.2.9/contributing/documentation-guide.md` is created.
- `website/versioned_sidebars/version-1.2.9-sidebars.json` is updated.
- Website builds successfully without errors.
