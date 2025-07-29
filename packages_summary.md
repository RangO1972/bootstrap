# 🛠️ Panoramica Pacchetti Installati & Comandi Rapidi per Test

_Esempio basato su Debian 12_

| Pacchetto         | Descrizione breve                                              | Comando rapido                                                                             |
|-------------------|---------------------------------------------------------------|-------------------------------------------------------------------------------------------|
| sudo              | Gestione privilegi amministrativi                             | `sudo -v`                                                                                 |
| openssh-server    | Accesso remoto via SSH                                        | `sudo systemctl status ssh`                                                              |
| wget              | Download da terminale                                          | `wget --version`                                                                          |
| systemd-resolved  | Resolver DNS di sistema con systemd                           | `resolvectl status`                                                                       |
| git               | Controllo di versione                                          | `git --version`                                                                           |
| htop              | Monitor di sistema interattivo                                | `htop`                                                                                    |
| iperf3            | Test banda TCP/UDP                                            | `iperf3 -s` e in un altro host `iperf3 -c <host>`                                        |
| nftables          | Firewall moderno che sostituisce iptables :contentReference[oaicite:1]{index=1} | `sudo nft list ruleset`                                                                   |
| dnsutils          | Include `dig`, `nslookup` per debug DNS                       | `dig debian.org +short`                                                                   |
| mtr               | Traceroute interattivo che combina ping e traceroute          | `mtr --report google.com`                                                                 |
| traceroute        | Tracciamento statico del percorso di rete                     | `traceroute debian.org`                                                                   |
| lsof              | Mostra file aperti e socket aperti                            | `lsof -i TCP:22`                                                                           |
| tcpdump           | Cattura pacchetti di rete                                      | `sudo tcpdump -c 10 -i any icmp`                                                          |
| nmap              | Scansione porte e servizi                                     | `nmap -sS -Pn localhost`                                                                  |
| bmon              | Monitor traffico rete in tempo reale                          | `bmon`                                                                                    |
| bpfcc-tools       | Strumenti eBPF per osservabilità avanzata (richiede kernel recente) | `sudo execsnoop` o `sudo opensnoop`                                                       |
| tailscale         | VPN zero‑config per accesso remoto via rete privata           | `tailscale status` e `tailscale up`                                                        |

---
# 📦 Pacchetti installati - Manuale operativo rapido

Un riferimento sintetico ma completo ai comandi più usati per i pacchetti di base installati su Debian 12.

---

## 🔐 sudo

Gestione privilegi amministrativi.

```bash
sudo -v                 # Aggiorna il timestamp di sudo (autenticazione)
sudo su                 # Passa a root
sudo <comando>          # Esegue un comando come root
```

---

## 🔐 openssh-server

Server SSH per accesso remoto sicuro.

```bash
sudo systemctl status ssh        # Verifica se è attivo
sudo systemctl start ssh         # Avvia il servizio SSH
sudo systemctl enable ssh        # Abilita l'avvio automatico
sudo ufw allow ssh               # (se usi UFW) consenti connessioni SSH
```

---

## 🌐 wget

Download di file via HTTP/FTP.

```bash
wget http://example.com/file.iso         # Scarica file
wget -c http://example.com/file.iso      # Riprende download interrotto
wget -r -np -k http://example.com/dir/   # Scarica intero sito in locale
```

---

## 🔧 systemd-resolved

Risoluzione DNS con systemd.

```bash
resolvectl status                   # Stato generale della risoluzione DNS
resolvectl query debian.org         # Query DNS manuale
resolvectl dns                      # Mostra server DNS per ogni interfaccia
```

---

## 🧬 git

Controllo di versione distribuito.

```bash
git clone https://repo.git        # Clona un repository
git status                        # Stato locale
git add .                         # Aggiunge modifiche all'index
git commit -m "msg"               # Commit locale
git push                          # Invia al remoto
```

---

## 📈 htop

Monitor di sistema interattivo.

```bash
htop                     # Avvia interfaccia interattiva
F6                      # Cambia colonna di ordinamento
F9                      # Termina processo
```

---

## 🚀 iperf3

Test di velocità di rete TCP/UDP.

```bash
iperf3 -s                            # Avvia in modalità server
iperf3 -c <host>                     # Avvia in modalità client verso <host>
iperf3 -c <host> -u -b 100M          # Test UDP a 100 Mbps
```

---

## 🔥 nftables

Firewall di nuova generazione (successore di iptables).

```bash
sudo nft list ruleset               # Mostra tutte le regole attive
sudo nft flush ruleset              # Cancella tutte le regole
sudo nft -f /etc/nftables.conf      # Ricarica configurazione
```

---

## 🔎 dnsutils

Strumenti per debug DNS (incluso `dig`).

```bash
dig debian.org                      # Query DNS
dig @8.8.8.8 debian.org             # Query DNS usando server specifico
```

---

## 🌍 mtr

Traceroute interattivo in tempo reale.

```bash
mtr google.com                      # Avvio interattivo
mtr --report google.com             # Report statico
```

---

## 🌐 traceroute

Tracciamento del percorso dei pacchetti IP.

```bash
traceroute debian.org               # Traccia il percorso dei pacchetti
```

---

## 🧩 lsof

Lista file aperti da processi.

```bash
lsof -i                             # Connessioni di rete attive
lsof -i :22                         # Processi che usano la porta 22
```

---

## 📡 tcpdump

Sniffer di pacchetti da terminale.

```bash
sudo tcpdump -i any -c 10           # Cattura 10 pacchetti su tutte le interfacce
sudo tcpdump port 53                # Mostra traffico DNS
```

---

## 🔍 nmap

Scanner di rete e porte.

```bash
nmap -sS -Pn <host>                 # Scansione SYN senza ping
nmap -A <host>                      # Rilevamento sistema operativo e servizi
```

---

## 📊 bmon

Monitor interfaccia di rete in tempo reale.

```bash
bmon                                # Avvia interfaccia interattiva
```

---

## 🧠 bpfcc-tools

Strumenti eBPF avanzati per tracciamento kernel (necessita kernel recente).

```bash
sudo execsnoop                      # Traccia comandi eseguiti
sudo opensnoop                      # Traccia apertura file
```

---

## 🌐 tailscale

VPN zero-config con rete mesh automatica.

```bash
sudo tailscale up                   # Connetti al nodo Tailscale
tailscale status                    # Mostra stato e peer attivi
tailscale ip                        # Mostra IP interno Tailscale
```
