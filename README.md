# ONLYOFFICE Email Additional Fonts

Adds administrator-supplied fonts to the CKEditor-based Mail composer in ONLYOFFICE Workspace / Community Server, including the Mail compose, signature and autoreply editors that inherit the standard `Font` toolbar control.

The project does **not** ship proprietary fonts. It installs the mechanism and gives the administrator a persistent font drop directory.

## Font drop directory

After installation, copy fonts to:

```text
/opt/onlyoffice-email-additional-fonts/fonts
```

Supported formats:

```text
.ttf  .otf  .woff  .woff2
```

Subdirectories are allowed. Every supported file under the directory is scanned and the Mail font list/CSS is regenerated automatically.

## Optional Mail display aliases

If you need a familiar name in the Mail font menu to point at an installed equivalent family, use:

```text
/etc/onlyoffice-email-additional-fonts.aliases
```

Format:

```text
Display Name=Real Font Family
```

Example:

```text
Chalkboard=Cantarell
```

That makes `Chalkboard` appear in CKEditor's Mail font menu while applying the installed `Cantarell` family. It does not rename or modify the font files, and aliases are optional. The systemd watcher also watches the alias file, so changes are applied automatically.

## Install

On the Docker host running ONLYOFFICE Workspace / Community Server:

```bash
git clone https://github.com/lurcheous73/onlyoffice-email-additional-fonts.git
cd onlyoffice-email-additional-fonts
sudo bash ./install.sh
```

Use `bash ./install.sh` rather than changing the Git checkout's executable bit with `chmod +x`; this keeps the checkout clean for future `git pull --ff-only` updates.

Then copy your fonts into the drop directory:

```bash
sudo cp /path/to/fonts/*.ttf /opt/onlyoffice-email-additional-fonts/fonts/
sudo onlyoffice-email-additional-fonts
```

A systemd path unit watches the font directory and alias file. A separate timer validates the patch **once after boot**; it does not run on a repeating 15-minute schedule.

## Update an existing checkout

```bash
cd /path/to/onlyoffice-email-additional-fonts
git restore install.sh status.sh uninstall.sh lib/update-fonts.sh systemd/onlyoffice-email-additional-fonts.timer 2>/dev/null || true
git pull --ff-only
sudo bash ./install.sh
```

The font drop directory is outside the Git source checkout, so updating or restoring the checkout does not remove administrator-supplied fonts from `/opt/onlyoffice-email-additional-fonts/fonts`.

## What it updates

By default the updater:

1. Detects the running ONLYOFFICE Community Server container.
2. Scans every supported font in the font drop directory.
3. Uses the real font family name where `fontconfig` can identify it.
4. Reads optional administrator-defined Mail display aliases from `/etc/onlyoffice-email-additional-fonts.aliases`.
5. Generates browser `@font-face` CSS.
6. Copies the fonts into the Community Server CKEditor web tree.
7. Adds the real families and optional display aliases to CKEditor's `config.font_names` while retaining the stock font list.
8. Adds the generated stylesheet to `config.contentsCss`, including a cache-busting version.
9. Uses stable content hashes so an unchanged font set does not look changed on every validation.
10. Restarts Community Server only when the generated font set/config actually changes.
11. When Document Server is detected (`SYNC_DOCUMENT_SERVER="auto"`), copies the same real font files into Document Server and runs `documentserver-generate-allfonts.sh` when the font set changes. Display aliases affect Mail only and do not trigger unnecessary Document Server font regeneration.

Mail's standard toolbar already contains the `Font` and `FontSize` controls; this project extends the catalogue behind that control rather than replacing the Mail toolbar.

## Manual update

```bash
sudo onlyoffice-email-additional-fonts
```

## Status

```bash
sudo onlyoffice-email-additional-fonts-status
```

The status output shows the configured font drop directory, source font count, alias file and active aliases, detected containers, CKEditor patch state, and watcher/timer state.

## Configuration

```text
/etc/onlyoffice-email-additional-fonts.conf
```

Default configuration:

```bash
FONT_DIR="/opt/onlyoffice-email-additional-fonts/fonts"
STATE_DIR="/var/lib/onlyoffice-email-additional-fonts"
ALIAS_FILE="/etc/onlyoffice-email-additional-fonts.aliases"
SYNC_DOCUMENT_SERVER="auto"
RESTART_COMMUNITY_SERVER="1"
```

Set `SYNC_DOCUMENT_SERVER="0"` if you want to modify Community Server Mail only.

## After an update

If ONLYOFFICE Mail is already open in a browser, reload the entire ONLYOFFICE page and then open a new compose window. The generated stylesheet includes a cache key so changed font content is not hidden behind an old browser CSS cache.

## Uninstall

```bash
sudo /opt/onlyoffice-email-additional-fonts/uninstall.sh
```

The uninstaller removes only this project's marked CKEditor configuration block and generated webfont directory. It deliberately leaves `/opt/onlyoffice-email-additional-fonts/fonts` in place so locally supplied font files are not destroyed.

## Notes

- Designed for the Docker-based ONLYOFFICE Workspace / Community Server layout where CKEditor lives at `/var/www/onlyoffice/WebStudio/UserControls/Common/ckeditor` inside Community Server.
- The updater is idempotent and uses a lock to prevent overlapping path/timer runs.
- An original CKEditor config is backed up by checksum before the first patch of a stock config.
- Do not commit proprietary/licensed font binaries to this public repository unless redistribution is permitted by their licence.
