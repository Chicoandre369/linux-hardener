# P6 - Linux Hardener

Audita y endurece Ubuntu / Debian. Solo para tus propios sistemas y labs.

## Que hace?

Revisa 8 controles:
1. SSH - PermitRootLogin, PasswordAuthentication, MaxAuthTries
2. Firewall UFW - activo, deny incoming
3. Updates - unattended-upgrades
4. Password policy - PASS_MAX_DAYS, PASS_MIN_DAYS
5. Usuarios - UID 0 extra, NOPASSWD en sudoers
6. Permisos - /etc/shadow
7. Servicios - telnet, ftp, rsh deshabilitados
8. Kernel sysctl - ip_forward

## Uso seguro

```bash
./harden.sh --check-only
./harden.sh --apply
```

En modo `--check-only` NO cambia nada. Empieza siempre ahi.
En modo `--apply` pide que escribas SI y hace backup en `backups/backup-FECHA/` de sshd_config, login.defs y sysctl.conf.

## Reporte

Cada corrida genera `reports/hardening-report-FECHA.md` con OK / WARN / FAIL.

## Demo en tu VM / WSL

```bash
git clone https://github.com/Chicoandre369/linux-hardener.git
cd linux-hardener
chmod +x harden.sh
./harden.sh --check-only
```

## CI

GitHub Actions corre ShellCheck + tests en cada push.

## Legal y etico

Solo en tus sistemas, labs locales o con autorizacion explicita. Nunca en sistemas de terceros.

## Estructura

```
harden.sh              # Script principal
config/hardening.conf  # Valores esperados
tests/test_harden.sh   # Tests sin root
docs/checklist.md      # Checklist manual
reports/               # Reportes generados
```
