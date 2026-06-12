---
title: Documentation Governance
sidebar_label: Documentation Governance
---

# Documentation Governance

The Docusaurus site becomes the primary public documentation surface for the project.

## Rules of thumb

- update user docs when behavior visible to users changes
- update technical docs when code ownership, architecture, or build flow changes
- update contributor docs when workflow or review expectations change
- keep the homepage focused on product narrative, not deep implementation detail

## Ownership model

Recommended lightweight ownership:

- one maintainer owns information architecture and homepage consistency
- feature authors own correctness of feature-specific pages
- reviewers check documentation impact as part of PR review

## Content lifecycle

During the migration period:

- the root `README.md` stays short and points to the site
- legacy files under `docs/` remain as source material
- curated, audience-oriented guidance lives in `website/docs/`
