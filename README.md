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

## Install

On the Docker host running ONLYOFFICE Workspace / Community Server:

```bash
git clone https://github.com/lurcheous73/onlyoffice-email-additional-fonts.git
cd onlyoffice-email-additional-fonts
sudo ./install.sh
```

Then copy your fonts into the drop directory:

```bash
sudo cp /path/to/fonts/*.ttf /opt/onlyoffice-email-additional-fonts/fonts/
sudo onlyoffice-email-additional-fonts
```

A systemd path unit watches the font directory and a 15-minute timer revalidates the patch. This allows the custom font layer to be reapplied after a Community Server container update or recreation.

## What it updates

By default the updater:

1. Detects the running ONLYOFFICE Community Server container.
2. Scans every supported font in the font drop directory.
3. Uses the real font family name where `fontconfig` can identify it; it does not create arbitrary family aliases.
4. Generates browser `@font-face` CSS.
5. Copies the fonts into the Community Server CKEditor web tree.
6. Adds the families to CKEditor's `config.font_names` while retaining the stock font list.
7. Adds the generated stylesheet to `config.contentsCss`, including a cache-busting version.
8. Restarts Community Server only when the generated font set/config actually changes.
9. When Document Server is detected (`SYNC_DOCUMENT_SERVER="auto"`), copies the same font set into Document Server and runs `documentserver-generate-allfonts.sh` when the font set changes.

Mail's standard toolbar already contains the `Font` and `FontSize` controls; this project extends the catalogue behind that control rather than replacing the Mail toolbar.

## Manual update

```bash
sudo onlyoffice-email-additional-fonts
```

## Status

```bash
sudo onlyoffice-email-additional-fonts-status
```

The status output always shows the configured font drop directory, source font count, detected containers, CKEditor patch state, and watcher/timer state.

## Configuration

```text
/etc/onlyoffice-email-additional-fonts.conf
```

Default configuration:

```bash
FONT_DIR="/opt/onlyoffice-email-additional-fonts/fonts"
STATE_DIR="/var/lib/onlyoffice-email-additional-fonts"
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
- The updater is idempotent and uses a lock to prevent overlapping timer/path runs.
- An original CKEditor config is backed up by checksum before the first patch of a stock config.
- Do not commit proprietary/licensed font binaries to this public repository unless redistribution is permitted by their licence.
