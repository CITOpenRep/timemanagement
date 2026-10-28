# Python Backend Unit Testing Guide

This directory contains automated unit tests for the Python backend modules (`src/backend/`).

## Running Tests

To run the entire Python test suite:

```bash
pytest tests/python
```

To run with verbose output:

```bash
pytest tests/python -v
```

To run a specific test file:

```bash
pytest tests/python/test_storage.py -v
pytest tests/python/test_auth.py -v
pytest tests/python/test_voice.py -v
pytest tests/python/test_attachments.py -v
pytest tests/python/test_sync.py -v
pytest tests/python/test_backend_facade.py -v
```

## Test Directory Structure

```
tests/
└── python/
    ├── README.md                 # This guide
    ├── conftest.py               # pytest configuration and sys.path setup
    ├── test_attachments.py       # Unit tests for attachment downloads and operations
    ├── test_auth.py              # Unit tests for reachability, db discovery, and auth
    ├── test_backend_facade.py    # Unit tests for QML API backward compatibility
    ├── test_storage.py           # Unit tests for storage and attachment path utilities
    ├── test_sync.py              # Unit tests for synchronization concurrency and locks
    └── test_voice.py             # Unit tests for voice models layout and signals
```

## Guidelines for New Backend Tests

1. **Isolation**: Always use pytest fixtures (`tmp_path`, `monkeypatch`) to avoid side effects on the user's filesystem or real database files.
2. **Fast Execution**: Backend unit tests must run purely in memory or using isolated temporary directories without spawning network requests or live background daemons.
3. **AAA Pattern**: Follow the Arrange-Act-Assert structure in every test method.
4. **Naming**: Test files should be named `test_<module>.py`, classes `Test<Feature>`, and methods `test_<behavior>`.
