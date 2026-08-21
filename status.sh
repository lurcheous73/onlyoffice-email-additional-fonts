#!/usr/bin/env bash
set -Eeuo pipefail
CONFIG_FILE="/etc/onlyoffice-email-additional-fonts.conf"
[[ -r "$CONFIG_FILE" ]] && . "$CONFIG_FILE"
FONT_DIR="${FONT_DIR:-/opt/onlyoffice-email-additional-fonts/fonts}"
STATE_DIR="${STATE_DIR:-/var/lib/onlyoffice-email-additional-fonts}"

echo "============================================================"
echo " ONLYOFFICE EMAIL ADDITIONAL FONTS — STATUS"
echo "============================================================"
echo "Font drop directory: $FONT_DIR"
echo "Supported: .ttf .otf .woff .woff2"
printf 'Source font files: '
find "$FONT_DIR" -type f \( -iname '*.ttf' -o -iname '*.otf' -o -iname '*.woff' -o -iname '*.woff2' \) 2>/dev/null | wc -l

echo
COMM="$(docker ps --format '{{.Names}}|{{.Image}}' | awk -F'|' '{line=tolower($0)} line ~ /communityserver|community-server/ {print $1; exit}')"
DOC="$(docker ps --format '{{.Names}}|{{.Image}}' | awk -F'|' '{line=tolower($0)} line ~ /documentserver|document-server/ {print $1; exit}')"
echo "Community Server: ${COMM:-NOT FOUND}"
echo "Document Server:  ${DOC:-NOT FOUND}"

if [[ -n "$COMM" ]]; then
    CKROOT=/var/www/onlyoffice/WebStudio/UserControls/Common/ckeditor
    echo -n "Mail patch marker: "
    if docker exec "$COMM" grep -q 'ONLYOFFICE_EMAIL_ADDITIONAL_FONTS_BEGIN' "$CKROOT/config.js" 2>/dev/null; then echo PRESENT; else echo ABSENT; fi
    echo -n "Installed webfont files: "
    docker exec "$COMM" sh -lc "find '$CKROOT/onlyoffice-email-additional-fonts/fonts' -maxdepth 1 -type f 2>/dev/null | wc -l" || true
fi

echo
echo "Watcher: $(systemctl is-active onlyoffice-email-additional-fonts.path 2>/dev/null || true)"
echo "Timer:   $(systemctl is-active onlyoffice-email-additional-fonts.timer 2>/dev/null || true)"
echo "Last mail hash:     $(cat "$STATE_DIR/mail.hash" 2>/dev/null || echo none)"
echo "Last document hash: $(cat "$STATE_DIR/document.hash" 2>/dev/null || echo none)"
