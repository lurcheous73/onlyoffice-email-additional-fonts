#!/usr/bin/env bash
set -Eeuo pipefail

[[ $EUID -eq 0 ]] || { echo "Run this installer as root." >&2; exit 1; }
command -v docker >/dev/null 2>&1 || { echo "Docker is required." >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "python3 is required." >&2; exit 1; }
command -v flock >/dev/null 2>&1 || { echo "flock (util-linux) is required." >&2; exit 1; }

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_ROOT="/opt/onlyoffice-email-additional-fonts"
FONT_DIR="$INSTALL_ROOT/fonts"
STATE_DIR="/var/lib/onlyoffice-email-additional-fonts"
ALIAS_FILE="/etc/onlyoffice-email-additional-fonts.aliases"

mkdir -p "$INSTALL_ROOT" "$FONT_DIR" "$STATE_DIR" /etc/systemd/system /usr/local/bin /usr/local/sbin
install -m 0755 "$ROOT/lib/update-fonts.sh" /usr/local/sbin/onlyoffice-email-additional-fonts
install -m 0755 "$ROOT/status.sh" /usr/local/sbin/onlyoffice-email-additional-fonts-status
ln -sfn /usr/local/sbin/onlyoffice-email-additional-fonts /usr/local/bin/onlyoffice-email-additional-fonts
ln -sfn /usr/local/sbin/onlyoffice-email-additional-fonts-status /usr/local/bin/onlyoffice-email-additional-fonts-status
if [[ "$(readlink -f "$ROOT/uninstall.sh")" != "$(readlink -f "$INSTALL_ROOT/uninstall.sh" 2>/dev/null || true)" ]]; then
    install -m 0755 "$ROOT/uninstall.sh" "$INSTALL_ROOT/uninstall.sh"
fi

if [[ ! -f /etc/onlyoffice-email-additional-fonts.conf ]]; then
    cat > /etc/onlyoffice-email-additional-fonts.conf <<EOFCONF
# onlyoffice-email-additional-fonts
FONT_DIR="$FONT_DIR"
STATE_DIR="$STATE_DIR"
ALIAS_FILE="$ALIAS_FILE"

# auto = also update Document Server when it is detected.
# Set to 0 to update Community Server Mail only.
SYNC_DOCUMENT_SERVER="auto"

# Restart Community Server only when the generated font set/config changes.
RESTART_COMMUNITY_SERVER="1"
EOFCONF
fi

if [[ ! -f "$ALIAS_FILE" ]]; then
    cat > "$ALIAS_FILE" <<'EOFALIASES'
# Optional CKEditor Mail display aliases.
# Format:
#   Display Name=Real Font Family
#
# Example:
#   Chalkboard=Cantarell
#
# Aliases change only the name/value exposed in the Mail font menu.
# They do not rename, modify or redistribute font files.
EOFALIASES
    chmod 0644 "$ALIAS_FILE"
fi

install -m 0644 "$ROOT/systemd/onlyoffice-email-additional-fonts.service" /etc/systemd/system/onlyoffice-email-additional-fonts.service
install -m 0644 "$ROOT/systemd/onlyoffice-email-additional-fonts.path" /etc/systemd/system/onlyoffice-email-additional-fonts.path
install -m 0644 "$ROOT/systemd/onlyoffice-email-additional-fonts.timer" /etc/systemd/system/onlyoffice-email-additional-fonts.timer

systemctl daemon-reload
systemctl enable --now onlyoffice-email-additional-fonts.path onlyoffice-email-additional-fonts.timer

cat <<EOFMSG
============================================================
 ONLYOFFICE EMAIL ADDITIONAL FONTS
============================================================

INSTALL COMPLETE

PUT FONT FILES HERE:

  $FONT_DIR

Supported files:
  .ttf  .otf  .woff  .woff2

You can create subdirectories; every supported font below that directory is scanned.

Optional Mail display aliases:

  $ALIAS_FILE

Format:
  Display Name=Real Font Family

After copying fonts or changing aliases, either wait for the path watcher or run:

  onlyoffice-email-additional-fonts

Status:

  onlyoffice-email-additional-fonts-status

Configuration:

  /etc/onlyoffice-email-additional-fonts.conf

The 15-minute timer also re-checks the patch after ONLYOFFICE container updates/recreation.
============================================================
EOFMSG

/usr/local/sbin/onlyoffice-email-additional-fonts
