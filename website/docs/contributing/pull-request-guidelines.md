title: Pull Request Guidelines
sidebar_label: Pull Request Guidelines
---

# Pull Request Guidelines

This page migrates the current repository PR guidance into the site.

## Branch strategy

- branch from `main`
- use branch names such as `feature/add-timesheet-export`
- keep work scoped to one logical change where possible

## Before opening a PR

### Code quality

- code should pass the relevant app build and review steps
- no hardcoded credentials, URLs, or API keys
- no debug logging left in production code
- follow existing code style and conventions

### Testing

- test on desktop with `clickable desktop`
- test on device when possible with `clickable install`
- for CLI-oriented Python changes, verify with `python3 -m py_compile <file>`

### Documentation

- update relevant docs when adding or changing functionality
- add inline comments only where code is non-obvious
- update naming or architecture contracts when applicable

## PR description

Every PR should include:

- summary
- change type
- testing notes
- screenshots for UI changes

## Current source

The original project source remains in the repository during migration:

- [Pull Request Guidelines Source](https://github.com/CITOpenRep/timemanagement/blob/main/docs/PR-GUIDELINES.md)
