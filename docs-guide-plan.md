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

## Done When
- `website/docs/contributing/documentation-guide.md` is created.
- `website/sidebars.js` is updated.
- Website builds successfully without errors.
