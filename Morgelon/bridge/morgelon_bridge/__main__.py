from __future__ import annotations

import argparse
import sys
import time

from .auth import load_credentials
from .catalog import InspirationCatalog, ensure_dirs
from .config import Settings
from .drive_sync import sync_drive
from .photos_picker import run_picker_import
from .rclone_sync import rclone_available, sync_configured_rclone
from .watch_inbox import scan_inbox, watch_forever


def cmd_auth(settings: Settings) -> int:
    load_credentials(settings)
    print(f"OK — token saved to {settings.token_path}")
    return 0


def cmd_status(settings: Settings) -> int:
    print("Morgelon bridge status")
    print(f"  client_secrets: {settings.client_secrets}  exists={settings.client_secrets.exists()}")
    print(f"  token:          {settings.token_path}  exists={settings.token_path.exists()}")
    print(f"  drive_folder:   id={settings.drive_folder_id or '-'} name={settings.drive_folder_name}")
    print(f"  watch_dir:      {settings.watch_dir}")
    print(f"  out_dir:        {settings.out_dir}")
    print(f"  rclone:         installed={rclone_available()} gdrive={settings.rclone_gdrive or '-'} gphotos={settings.rclone_gphotos or '-'}")
    cat = InspirationCatalog(settings.out_dir)
    print(f"  catalog items:  {len(cat.data.get('imported', {}))}")
    return 0


def cmd_inbox(settings: Settings) -> int:
    cat = InspirationCatalog(settings.out_dir)
    ensure_dirs(settings.watch_dir, settings.out_dir)
    n = scan_inbox(settings, cat)
    cat.write_gallery_index()
    print(f"Inbox imported {n}")
    return 0


def cmd_drive(settings: Settings) -> int:
    creds = load_credentials(settings)
    cat = InspirationCatalog(settings.out_dir)
    n = sync_drive(creds, settings, cat)
    cat.write_gallery_index()
    print(f"Drive imported {n}")
    return 0


def cmd_photos(settings: Settings) -> int:
    creds = load_credentials(settings)
    cat = InspirationCatalog(settings.out_dir)
    n = run_picker_import(creds, settings, cat)
    cat.write_gallery_index()
    print(f"Photos Picker imported {n}")
    return 0


def cmd_rclone(settings: Settings) -> int:
    cat = InspirationCatalog(settings.out_dir)
    n = sync_configured_rclone(settings, cat)
    cat.write_gallery_index()
    print(f"rclone imported {n}")
    return 0


def cmd_sync_all(settings: Settings) -> int:
    """All ways that don't require interactive Photos picking."""
    ensure_dirs(settings.watch_dir, settings.out_dir)
    cat = InspirationCatalog(settings.out_dir)
    total = scan_inbox(settings, cat)
    print(f"inbox: {total}")
    if settings.client_secrets.exists():
        try:
            creds = load_credentials(settings)
            d = sync_drive(creds, settings, cat)
            print(f"drive: {d}")
            total += d
        except Exception as e:
            print(f"drive skipped: {e}", file=sys.stderr)
    if settings.rclone_gdrive or settings.rclone_gphotos:
        try:
            r = sync_configured_rclone(settings, cat)
            print(f"rclone: {r}")
            total += r
        except Exception as e:
            print(f"rclone skipped: {e}", file=sys.stderr)
    cat.write_gallery_index()
    print(f"total new: {total}")
    print(f"gallery: {settings.out_dir / 'gallery.json'}")
    return 0


def cmd_daemon(settings: Settings) -> int:
    """Poll Drive + inbox forever; Photos remains on-demand (Picker)."""
    ensure_dirs(settings.watch_dir, settings.out_dir)
    print("Daemon: inbox + Drive (+ rclone if configured). Ctrl+C to stop.")
    print("Photos: run `python -m morgelon_bridge photos` anytime to pick more.")
    while True:
        cmd_sync_all(settings)
        time.sleep(max(30, settings.poll_seconds))
    return 0


def cmd_watch(settings: Settings) -> int:
    cat = InspirationCatalog(settings.out_dir)
    watch_forever(settings, cat)
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        prog="morgelon_bridge",
        description="Auto-import Google Drive / Photos Picker / inbox / rclone into Morgelon inspiration plates.",
    )
    sub = parser.add_subparsers(dest="cmd", required=True)

    for name, help_ in [
        ("auth", "OAuth login (Drive + Photos Picker scopes)"),
        ("status", "Show config / catalog"),
        ("inbox", "Import local watch folder / Takeout drops"),
        ("drive", "Sync configured Google Drive folder"),
        ("photos", "Interactive Google Photos Picker import"),
        ("rclone", "Sync configured rclone remotes"),
        ("sync", "All non-interactive paths once"),
        ("daemon", "Poll Drive+inbox forever"),
        ("watch", "Watch inbox folder only"),
    ]:
        sub.add_parser(name, help=help_)

    args = parser.parse_args(argv)
    settings = Settings.load()

    dispatch = {
        "auth": cmd_auth,
        "status": cmd_status,
        "inbox": cmd_inbox,
        "drive": cmd_drive,
        "photos": cmd_photos,
        "rclone": cmd_rclone,
        "sync": cmd_sync_all,
        "daemon": cmd_daemon,
        "watch": cmd_watch,
    }
    try:
        return dispatch[args.cmd](settings)
    except FileNotFoundError as e:
        print(e, file=sys.stderr)
        return 2
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
