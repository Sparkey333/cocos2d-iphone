from __future__ import annotations

import time
from pathlib import Path

from .catalog import InspirationCatalog, ensure_dirs, import_local_file
from .config import MEDIA_EXT, Settings


def scan_inbox(settings: Settings, catalog: InspirationCatalog) -> int:
    """Import Google Takeout dumps / manual drops / AirDrop copies."""
    ensure_dirs(settings.watch_dir)
    imported = 0
    for path in settings.watch_dir.rglob("*"):
        if not path.is_file():
            continue
        if path.suffix.lower() not in MEDIA_EXT:
            continue
        # Skip macOS junk
        if path.name.startswith("."):
            continue
        dest = import_local_file(
            path,
            catalog,
            source="inbox",
            meta={"from": str(path.relative_to(settings.watch_dir))},
        )
        if dest:
            imported += 1
    return imported


def watch_forever(settings: Settings, catalog: InspirationCatalog) -> None:
    """Best-effort polling watcher (works without inotify quirks)."""
    ensure_dirs(settings.watch_dir)
    print(f"Watching inbox: {settings.watch_dir}")
    print(f"Inspiration out: {catalog.out_dir}")
    seen_mtime: dict[Path, float] = {}
    while True:
        n = 0
        for path in settings.watch_dir.rglob("*"):
            if not path.is_file() or path.suffix.lower() not in MEDIA_EXT:
                continue
            try:
                m = path.stat().st_mtime
            except OSError:
                continue
            if seen_mtime.get(path) == m:
                continue
            seen_mtime[path] = m
            if import_local_file(path, catalog, source="inbox"):
                n += 1
        if n:
            catalog.write_gallery_index()
            print(f"Inbox imported {n} file(s)")
        time.sleep(max(5, settings.poll_seconds // 4))
