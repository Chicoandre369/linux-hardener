# Checklist manual - P6

Usa esto despues de correr ./harden.sh --check-only:

- [ ] SSH: sudo grep PermitRootLogin /etc/ssh/sshd_config debe ser no
- [ ] UFW: sudo ufw status debe decir active
- [ ] Updates: sudo apt update && apt list --upgradable
- [ ] Usuarios: sudo grep NOPASSWD /etc/sudoers debe estar vacio
- [ ] Permisos: stat -c %a /etc/shadow debe ser 640 o 600
- [ ] Servicios: systemctl is-enabled telnet debe decir disabled
- [ ] Kernel: sysctl net.ipv4.ip_forward debe ser 0

## Como revertir

Si algo se rompe en modo --apply, restaura desde el backup:

```bash
ls backups/
sudo cp backups/backup-FECHA/sshd_config.bak /etc/ssh/sshd_config
sudo systemctl restart ssh
```
