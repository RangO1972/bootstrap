# Debian 13 - Installation and Initial Setup (No GUI) --- "Preliminay"

## 1. Install Debian 13

Download the official Debian 13 ISO from:  
👉 https://www.debian.org/distrib/

During installation:
👤 When prompted to create a user, enter:

```text
Username: stra
```

✅ Select:
- **Standard system utilities**
- **SSH server**

❌ Do **not** select:
- **Desktop Environment** (no GUI)

> ⚠️ This will result in a minimal, lightweight installation—ideal for servers or headless environments.

## 2. Install all

```bash
Username: root
Password: [your root password]

wget --no-cache -qO- https://tinyurl.com/y2y5b6x7 | bash
reboot
```

## 3. Cleaning

```bash
sudo apt autoremove --purge
sudo apt clean
```
