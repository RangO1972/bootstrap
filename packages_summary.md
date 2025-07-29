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

## 🧪 Esempi di test rapidi

```bash
# Verifica che SSH sia attivo
sudo systemctl status ssh

# Controlla utilizzo banda con iperf3 (server/client)
iperf3 -s
iperf3 -c 192.168.1.2

# Mostra regole firewall con nftables
sudo nft list ruleset

# Effettua una scansione porte interne
nmap -sS -Pn localhost

# Misura ritardo e perdita con mtr (report)
mtr --report -c 100 debian.org
