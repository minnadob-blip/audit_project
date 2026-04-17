# Linux System Audit & Monitoring Suite

A professional, modular Bash toolkit for auditing Linux systems, generating reports, emailing results, and remote monitoring via SSH.

---

## Table of Contents

1. [Overview](#overview)
2. [Features](#features)
3. [Requirements](#requirements)
4. [Installation](#installation)
5. [Configuration](#configuration)
   - [Email Setup](#email-setup)
   - [Remote Monitoring SSH Setup](#remote-monitoring-ssh-setup)
6. [Usage Guide](#usage-guide)
   - [Main Menu](#main-menu)
   - [Hardware Audit](#hardware-audit)
   - [Software Audit](#software-audit)
   - [Report Generation](#report-generation)
   - [Email Reports](#email-reports)
   - [Remote Monitor](#remote-monitor)
   - [Bonus Features](#bonus-features)
7. [File Structure & Outputs](#file-structure--outputs)
8. [Script Details & Customization](#script-details--customization)
9. [Troubleshooting](#troubleshooting)
10. [Security Considerations](#security-considerations)
11. [License](#license)

---

## Overview

This suite provides a complete solution for system administrators and security analysts to:

- Collect detailed hardware and software information from local or remote Linux machines.
- Generate concise (short) or comprehensive (full) text reports.
- Email reports directly from the command line.
- Remotely execute audits over SSH without leaving traces.
- Monitor system health with alerts and a lightweight web dashboard.

All scripts are written in pure Bash and use standard Linux tools (`lscpu`, `dmidecode`, `ss`, `systemctl`, etc.). They are modular, so you can run any component independently.

---

## Features

### Core Audits

| Audit Type | Information Collected |
|------------|------------------------|
| **Hardware** | CPU model/cores/threads, RAM total/used/swap, disk partitions & usage, network interfaces (MAC, IP), GPU, motherboard (manufacturer, product, serial, BIOS), USB devices |
| **Software** | OS version/kernel, installed packages (dpkg/rpm), logged‑in users & login history, running services, top processes by CPU, open ports (TCP/UDP), firewall status (ufw/iptables), environment variables, cron jobs |

### Reporting Modes

- **Short** – quick overview (CPU, RAM, OS, processes) – suitable for daily checks.
- **Full** – complete dump of all available information – suitable for compliance or debugging.

### Delivery & Automation

- **Email** – attach any generated report to an email using `mail`.
- **Remote execution** – run hardware audit on another machine via SSH, copy the script automatically, and pull back the report.
- **Logging** – all actions logged to `~/sys_audit/audit.log` with timestamps.

### Bonus Tools

- **HTML report** – generates a styled HTML version of the hardware/software audit.
- **Resource alerts** – checks CPU (>80%) and RAM (>80%) usage, prints warnings and logs them.
- **Web dashboard** – starts a simple Python HTTP server on port 8080 to serve reports over the local network.

---

## Requirements

### System

- Linux distribution (Debian/Ubuntu recommended, works on RHEL/CentOS with minor adjustments)
- Bash 4.0 or higher
- User with `sudo` access for some hardware queries (optional, falls back gracefully)

### Mandatory Tools

Most are pre‑installed on typical Linux servers. Install missing ones with your package manager.

| Tool | Purpose | Install command (Debian/Ubuntu) |
|------|---------|--------------------------------|
| `lscpu` | CPU info | `apt install util-linux` |
| `lspci` | GPU detection | `apt install pciutils` |
| `lsusb` | USB devices | `apt install usbutils` |
| `dmidecode` | Motherboard, BIOS, RAM slots | `apt install dmidecode` |
| `df` / `lsblk` | Disk usage & partitions | part of `coreutils` / `util-linux` |
| `ip` | Network interfaces | `apt install iproute2` |
| `ss` | Open ports | `apt install iproute2` |
| `ps` / `free` | Processes & memory | `procps` |
| `systemctl` | Service management | `systemd` |
| `bc` | CPU alert calculations | `apt install bc` |

### Optional for Email

- `mailutils` (or `bsd-mailx` with attachment support)
- A configured MTA (Postfix, Sendmail) or SMTP relay (e.g., msmtp for Gmail)

### Optional for Remote Monitoring

- `ssh` and `scp` clients
- Passwordless SSH key authentication to the remote host

### Optional for Web Dashboard

- `python3` (for `http.server`)

---

## Installation

1. **Download all scripts** into a single directory, for example:
   ```bash
   mkdir -p ~/sys_audit_tools
   cd ~/sys_audit_tools
   # Copy or clone the scripts here




## Authors

- Student 1: DOB MINNA
- Student 2: BOUACHERIA HIBAT ALLAH
- Supervisor: Dr. BENTRAD Sassi

