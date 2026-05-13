# Pull Request Guidelines

Thank you for your interest in contributing! Please follow these rules to ensure smooth code review and merge process.

---

## 1. Branch Strategy

- **Branch from `main`**: Always create feature/bugfix branches from `main`
- **Naming convention**: `type/ticket-description`
  - `feature/add-timesheet-export`
  - `fix/timer-pause-issue`
  - `refactor/phase1-models`

---

## 2. Before Opening a PR

### Code Quality
- [ ] Code passes `clickable desktop` && `clickable build && clickable review` build without errors
- [ ] No hardcoded credentials, URLs, or API keys
- [ ] No `console.log` / debug statements in production code
- [ ] Follow existing code style and conventions

### Testing
- [ ] Test changes on desktop first (`clickable desktop`)
- [ ] Test on device if possible (`clickable install`)
- [ ] For CLI changes, verify with `python3 -m py_compile <file>`

### Documentation
- [ ] Update relevant docs if adding new functionality
- [ ] Add inline comments only where code is non-obvious
- [ ] Update naming contracts in `docs/refactor/` if applicable

---

## 3. PR Description

Every PR must include:

> **Note**: When you open a new PR on GitHub, the [PR template](https://github.com/CITOpenRep/timemanagement/blob/Enhancement-Docs/.github/PULL_REQUEST_TEMPLATE/pull_request_template.md) will auto-populate with the required sections.

```
## Summary
Brief description of what this PR does.

## Type
- [ ] Feature
- [ ] Bug Fix
- [ ] Refactor
- [ ] Documentation

## Testing
How was this tested?

## Screenshots (if UI change)
```

---

## 4. Commit Rules

- **Commit message format**: `type: short description`
  - `feat: add quadrant timer widget`
  - `fix: resolve sync timeout issue`
  - `docs: update README`
- **One logical change per commit**: Squash if needed
- **No merge commits in PR**: Rebase instead
- **Atomic commits preferred**: Each commit should be self-contained

---

## 5. Code Review Checklist

### For Authors
- Respond to comments within 48 hours
- Address all feedback or explain reasoning
- Mark threads as resolved after addressing

### For Reviewers
- Be constructive and specific
- Approve only when ready to merge
- Use `Request Changes` for blocking issues

---

## 6. Merge Criteria

PRs require:
- [ ] At least 1 approval (for non-trivial changes)
- [ ] All checks passing
- [ ] No unresolved conversations
- [ ] Up-to-date with `main` (rebase if needed)

### Merge Method
- **Squash merge** for features/bug fixes (clean history)
- **Merge commit** for large refactors (preserves context)

---

## 7. What NOT to Submit

-  Work-in-progress PRs without description
-  PRs with failing builds
-  Code with debug logs or TODO comments left in
-  Large refactors without prior discussion
-  Files with secrets or credentials

---

## 8. Getting Help

- **Issues**: Open at https://github.com/CITOpenRep/timemanagement/issues
- **Discussion**: Use GitHub Discussions for design questions
- **Quick questions**: Tag maintainers in PR comments

---

## Quick Reference

```bash
# Create branch
git checkout main && git pull
git checkout -b feature/my-feature

# Keep updated
git fetch origin
git rebase origin/main

# Squash commits before PR
git rebase -i HEAD~3
```
