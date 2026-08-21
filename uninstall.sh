#!/usr/bin/env bash
set -Eeuo pipefail
[[ $EUID -eq 0 ]] || { echo "Run as root." >&2; exit 1; }

systemctl disable --now onlyoffice-email-additional-fonts.path onlyoffice-email-additional-fonts.timer 2>/dev/null || true
rm -f /etc/systemd/system/onlyoffice-email-additional-fonts.service \
      /etc/systemd/system/onlyoffice-email-additional-fonts.path \
      /etc/systemd/system/onlyoffice-email-additional-fonts.timer
systemctl daemon-reload

COMM="$(docker ps --format '{{.Names}}|{{.Image}}' | awk -F'|' '{line=tolower($0)} line ~ /communityserver|community-server/ {print $1; exit}')"
if [[ -n "$COMM" ]]; then
    CFG=/var/www/onlyoffice/WebStudio/UserControls/Common/ckeditor/config.js
    TMP="$(mktemp)"
    docker cp "$COMM:$CFG" "$TMP" >/dev/null
    python3 - "$TMP" <<'PY'
from pathlib import Path
import sys
p=Path(sys.argv[1]); t=p.read_text()
s="    /* ONLYOFFICE_EMAIL_ADDITIONAL_FONTS_BEGIN */"
e="    /* ONLYOFFICE_EMAIL_ADDITIONAL_FONTS_END */"
if s in t and e in t:
    before, rest=t.split(s,1); _, after=rest.split(e,1)
    p.write_text(before.rstrip()+"\n"+after.lstrip("\n"))
PY
    docker cp "$TMP" "$COMM:$CFG" >/dev/null
    rm -f "$TMP"
    docker exec "$COMM" rm -rf /var/www/onlyoffice/WebStudio/UserControls/Common/ckeditor/onlyoffice-email-additional-fonts
    docker exec "$COMM" chown onlyoffice:onlyoffice "$CFG" || true
    docker restart --timeout 30 "$COMM" >/dev/null || true
fi

rm -f \
    /usr/local/sbin/onlyoffice-email-additional-fonts \
    /usr/local/sbin/onlyoffice-email-additional-fonts-status \
    /usr/local/bin/onlyoffice-email-additional-fonts \
    /usr/local/bin/onlyoffice-email-additional-fonts-status

echo "Patch removed. Font source directory was NOT deleted."
echo "If you also want to remove it manually: /opt/onlyoffice-email-additional-fonts/fonts"
