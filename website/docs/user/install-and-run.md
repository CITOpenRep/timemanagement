title: Install and Run
sidebar_label: Install and Run
---

# Install and Run

This guide explains the current developer-friendly path for building and running TimeManagement.

## Prerequisites

- Ubuntu or another Debian-based environment
- Git
- Python 3
- Docker for Clickable-driven device and cross-build workflows

## Install Clickable

Follow the current project prerequisites:

```bash
sudo apt update
sudo apt install git python3 python3-pip
pip3 install --user clickable-ut
echo 'export PATH=$PATH:~/.local/bin' >> ~/.bashrc
source ~/.bashrc
clickable --version
```

## Run on desktop

Clone the repository and start the desktop app with:

```bash
clickable desktop
```

## Install on a connected device

Use:

```bash
clickable install
```

## Notes

- The current repository is desktop and Ubuntu Touch oriented rather than a web app.
- Local database files are typically stored under `~/.clickable/home/.local/share/ubtms/Databases`.
