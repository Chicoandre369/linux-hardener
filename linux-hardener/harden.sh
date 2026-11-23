#!/bin/bash
# P6 - Linux Hardener - Audita y endurece Ubuntu / Debian
# Uso:
#   ./harden.sh --check-only   # Solo audita, NO cambia nada (por defecto, seguro)
#   ./harden.sh --apply        # Audita + aplica cambios (pide confirmacion)
# Solo para tus propios sistemas / labs.
set -euo pipefail
MODE="check-only"
REPORT_DIR="reports"
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
REPORT_FILE="$REPORT_DIR/hardening-report-$TIMESTAMP.md"
BACKUP_DIR="backups/backup-$TIMESTAMP"
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; BLUE='\033[0;34m'; NC='\033[0m'
PASS=0; WARN=0; FAIL=0
log() { echo -e "${BLUE}[*]${NC} $1"; }
ok()  { echo -e "${GREEN}[OK]${NC} $1"; PASS=$((PASS+1)); }
warn(){ echo -e "${YELLOW}[WARN]${NC} $1"; WARN=$((WARN+1)); }
fail(){ echo -e "${RED}[FAIL]${NC} $1"; FAIL=$((FAIL+1)); }
show_help() {
  echo "Linux Hardener - P6"
  echo "Uso:"
  echo "  ./harden.sh --check-only   Solo audita, no cambia nada"
  echo "  ./harden.sh --apply        Aplica hardening con backup y confirmacion"
  echo "  ./harden.sh --help         Muestra esta ayuda"
}
for arg in "$@"; do
  case $arg in
    --apply) MODE="apply" ;;
    --check-only) MODE="check-only" ;;
    --help|-h) show_help; exit 0 ;;
    *) echo "Arg desconocido: $arg - usa --help"; exit 1 ;;
  esac
done
mkdir -p "$REPORT_DIR"
{
echo "# Linux Hardener - Reporte $TIMESTAMP"
echo ""
echo "**Modo:** $MODE"
echo "**Host:** $(hostname)"
echo "**Fecha:** $(date)"
echo ""
echo "## Resultados"
echo ""
} > "$REPORT_FILE"
if [ "$MODE" = "apply" ]; then
  echo ""
  log "Modo APPLY - Vas a cambiar el sistema."
  read -rp "Estas seguro? Escribe SI para continuar: " confirm
  if [ "$confirm" != "SI" ]; then echo "Cancelado."; exit 0; fi
  mkdir -p "$BACKUP_DIR"
  cp /etc/ssh/sshd_config "$BACKUP_DIR/sshd_config.bak" 2>/dev/null || true
  cp /etc/login.defs "$BACKUP_DIR/login.defs.bak" 2>/dev/null || true
  cp /etc/sysctl.conf "$BACKUP_DIR/sysctl.conf.bak" 2>/dev/null || true
  log "Backup en $BACKUP_DIR"
fi
log "1. Revisando SSH..."
SSH_CONFIG="/etc/ssh/sshd_config"
if [ -f "$SSH_CONFIG" ]; then
  if grep -Eq "^PermitRootLogin no" "$SSH_CONFIG"; then ok "SSH: PermitRootLogin no"; else fail "SSH: PermitRootLogin NO esta en no"; echo "- SSH PermitRootLogin debe ser no" >> "$REPORT_FILE"; fi
  if grep -Eq "^PasswordAuthentication no" "$SSH_CONFIG"; then ok "SSH: PasswordAuthentication no"; else warn "SSH: PasswordAuthentication no esta en no"; fi
  if grep -Eq "^MaxAuthTries [1-3]" "$SSH_CONFIG"; then ok "SSH: MaxAuthTries <= 3"; else warn "SSH: MaxAuthTries no limitado a 3"; fi
else
  warn "SSH: no se encontro $SSH_CONFIG"
fi
log "2. Revisando Firewall UFW..."
if command -v ufw >/dev/null 2>&1; then
  if ufw status 2>/dev/null | grep -q "Status: active"; then ok "UFW activo"; else fail "UFW NO activo"; echo "- UFW debe estar activo" >> "$REPORT_FILE"; fi
  if [ "$MODE" = "apply" ]; then
    ufw default deny incoming || true
    ufw default allow outgoing || true
    ufw allow OpenSSH || true
    ufw --force enable || true
    ok "UFW: aplicado deny incoming + allow OpenSSH"
  fi
else
  warn "UFW no instalado (apt install ufw)"
fi
log "3. Revisando Updates..."
if dpkg -l | grep -q unattended-upgrades; then ok "unattended-upgrades instalado"; else warn "unattended-upgrades NO instalado"; fi
log "4. Revisando politica de contrasenas..."
if grep -Eq "^PASS_MAX_DAYS[[:space:]]+90" /etc/login.defs; then ok "PASS_MAX_DAYS 90"; else warn "PASS_MAX_DAYS no es 90"; fi
if grep -Eq "^PASS_MIN_DAYS[[:space:]]+7" /etc/login.defs; then ok "PASS_MIN_DAYS 7"; else warn "PASS_MIN_DAYS no es 7"; fi
log "5. Revisando usuarios..."
UID0=$(awk -F: '$3 == 0 {print $1}' /etc/passwd | tr '\n' ' ')
if [ "$UID0" = "root " ] || [ "$UID0" = "root" ]; then ok "Solo root tiene UID 0"; else warn "UID 0 extra: $UID0"; fi
if grep -q "NOPASSWD" /etc/sudoers 2>/dev/null; then warn "Hay NOPASSWD en /etc/sudoers"; else ok "Sin NOPASSWD en sudoers"; fi
log "6. Revisando permisos..."
SHADOW_PERM=$(stat -c %a /etc/shadow 2>/dev/null || echo "???")
if [ "$SHADOW_PERM" = "640" ] || [ "$SHADOW_PERM" = "600" ]; then ok "/etc/shadow permisos $SHADOW_PERM"; else warn "/etc/shadow permisos $SHADOW_PERM (ideal 640 o 600)"; fi
log "7. Revisando servicios innecesarios..."
for svc in telnet ftp rsh rlogin; do
  if systemctl is-enabled "$svc" >/dev/null 2>&1; then fail "Servicio inseguro activo: $svc"; else ok "Servicio $svc no activo"; fi
done
log "8. Revisando sysctl..."
if sysctl net.ipv4.ip_forward 2>/dev/null | grep -q "= 0"; then ok "net.ipv4.ip_forward = 0"; else warn "net.ipv4.ip_forward no es 0"; fi
echo ""
echo "======================================"
echo -e "  OK: $PASS  WARN: $WARN  FAIL: $FAIL"
echo "  Reporte: $REPORT_FILE"
echo "======================================"
{
echo ""
echo "## Resumen"
echo ""
echo "- OK: $PASS"
echo "- WARN: $WARN"
echo "- FAIL: $FAIL"
} >> "$REPORT_FILE"
if [ "$FAIL" -gt 0 ]; then
  echo "Hay FAILs criticos. Revisa el reporte y corre con --apply en tu lab."
  exit 1
else
  echo "Sin FAILs criticos. Bien."
  exit 0
fi
