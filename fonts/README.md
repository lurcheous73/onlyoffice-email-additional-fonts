# Put your fonts here

Copy your own `.ttf`, `.otf`, `.woff`, and `.woff2` files into this directory (subdirectories are allowed).

The installer deploys this repository to `/opt/onlyoffice-email-additional-fonts`, so the live font drop directory is:

```text
/opt/onlyoffice-email-additional-fonts/fonts
```

After adding or removing font files, the systemd path watcher runs the update automatically. You can also force an update with:

```bash
onlyoffice-email-additional-fonts
```

Do not commit proprietary or licensed font files to this public repository unless their licence explicitly allows redistribution.
