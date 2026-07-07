---
title: Installeren en uitvoeren
sidebar_label: Installeren en uitvoeren
---

# Installeren en uitvoeren

In deze handleiding wordt het huidige ontwikkelaarsvriendelijke pad voor het bouwen en uitvoeren van TimeManagement uitgelegd.

## Vereisten

- Ubuntu of een andere op Debian gebaseerde omgeving
- Git
- Python 3
- Docker voor klikbare apparaten en cross-build workflows

## Klikbaar installeren

Volg de huidige projectvereisten:

```bash
sudo apt update
sudo apt install git python3 python3-pip
pip3 install --user clickable-ut
echo 'export PATH=$PATH:~/.local/bin' >> ~/.bashrc
source ~/.bashrc
clickable --version
```

## Uitvoeren op bureaublad

Kloon de repository en start de desktop-app met:

```bash
clickable desktop
```

## Installeer op een aangesloten apparaat

Gebruik:

```bash
clickable install
```

## Opmerkingen

- De huidige repository is desktop- en Ubuntu Touch-georiënteerd in plaats van een webapp.
- Lokale databasebestanden worden doorgaans opgeslagen onder `~/.clickable/home/.local/share/ubtms/Databases`.
