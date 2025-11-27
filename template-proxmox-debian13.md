# Procedura per Creare un Template Debian 13 su Proxmox (q35 + UEFI + VirtIO + Serial0)

Questa guida descrive tutti i passaggi necessari per creare un **template Proxmox perfetto**, pulito e ottimizzato, basato su Debian 13 minimal.

## 📌 1. Installazione iniziale della VM

Creare la VM con queste impostazioni:

- **Machine:** q35  
- **BIOS:** OVMF (UEFI)  
- **SCSI Controller:** VirtIO SCSI single  
- **Disk:** VirtIO SCSI, cache=writeback, discard=on, io-thread=on, ssd=1  
- **NIC:** VirtIO  
- **Display:** Default (temporaneo)  
- **Memory:** 2GB (min) – 2GB (max), ballooning OFF per l’installazione  
- **CPU:** 1 socket, 2+ cores, Type=host  
- **ISO:** debian-13.x netinst  

Durante l’installer:

- hostname es: `base-template`  
- installazione minimale  
- nessun software extra oltre al bare system  

## 📌 2. Configurazione base post-installazione

Dopo il primo avvio:

### Aggiorna il sistema
```
apt update && apt full-upgrade -y
```

### Installa il QEMU Guest Agent
```
apt install -y qemu-guest-agent
systemctl enable --now qemu-guest-agent
```

### Abilita TRIM
```
systemctl enable fstrim.timer --now
```

## 📌 3. Abilitare la console Serial0 in Debian

### 1) Abilita il getty sulla seriale
```
systemctl enable --now serial-getty@ttyS0.service
```

### 2) Aggiungi la console al kernel
Modifica `/etc/default/grub`:

```
GRUB_CMDLINE_LINUX_DEFAULT="quiet console=tty0 console=ttyS0,115200n8"
```

Applica:
```
update-grub
```

Riavvia:
```
reboot
```

## 📌 4. Preparazione finale alla conversione (pulizia pre-template)

Esegui questi comandi **dentro la VM**:

### Pulisci APT
```
apt clean
```

### Rimuovi le chiavi SSH
```
rm -f /etc/ssh/ssh_host_*
```

### Reset del machine-id
```
rm -f /etc/machine-id
rm -f /var/lib/dbus/machine-id
systemd-machine-id-setup
```

### (Opzionale) Pulisci i log
```
journalctl --rotate
journalctl --vacuum-time=1s
```

### Spegni la VM
```
shutdown -h now
```

## 📌 5. Correzioni lato Proxmox prima della conversione

Con la VM SPENTA:

### Imposta Display su Serial0  
Assicurati che ci sia una porta seriale (`serial0: socket`)

### Assicurati che non ci siano ISO montate  
Rimuovi eventuale CD/DVD

### Imposta Ballooning  
- Memory max: 2048 MB  
- Minimum: 512 MB  
- Ballooning: ON  

### Controlla il disco  
- cache = writeback  
- discard = ON  
- ssd = ON  
- io-thread = ON  

## 📌 6. Converti a template

In Proxmox:

- Seleziona la VM  
- More → Convert to template  

## 📌 7. Note importanti

- Il template **mostrerà errore su ssh.service** → È NORMALE  
  perché le chiavi SSH sono state rimosse  
- Nei cloni generare nuove chiavi con:
```
dpkg-reconfigure openssh-server
systemctl restart ssh
```

## 📌 8. Creare un template derivato

1. Clona `node-template-empty`  
2. Installa ciò che ti serve  
3. Ripeti la pulizia:
```
apt clean
rm -f /etc/ssh/ssh_host_*
rm -f /etc/machine-id
rm -f /var/lib/dbus/machine-id
systemd-machine-id-setup
journalctl --rotate
journalctl --vacuum-time=1s
shutdown -h now
```
4. Converti a template
