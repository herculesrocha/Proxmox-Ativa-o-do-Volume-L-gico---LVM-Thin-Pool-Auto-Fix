# Automação da Correção

Criar script:

```
/usr/local/sbin/proxmox-lvm-fix.sh
```

Permissão:

```
chmod +x /usr/local/sbin/proxmox-lvm-fix.sh
```

Criar serviço systemd:

```
/etc/systemd/system/proxmox-lvm-fix.service
```

Conteúdo:

```
[Unit]
Description=Proxmox LVM Auto Fix
After=lvm2-monitor.service
After=systemd-udev-settle.service
Before=pve-guests.service

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/proxmox-lvm-fix.sh
TimeoutStartSec=60

[Install]
WantedBy=multi-user.target
```

Ativar:

```
systemctl daemon-reload
systemctl enable proxmox-lvm-fix.service
```
