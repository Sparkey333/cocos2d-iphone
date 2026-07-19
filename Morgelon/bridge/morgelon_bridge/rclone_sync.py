from __future__ import annotations

import shutil
import subprocess
from pathlib import Path

from .catalog import InspirationCatalog, import_local_file
from .config import Settings


def rclone_available() -> bool:
    return shutil.which("rclone") is not None


def sync_rclone_remote(
    remote: str,
    remote_path: str,
    staging: Path,
    catalog: InspirationCatalog,
    source_label: str,
) -> int:
    if not rclone_available():
        raise RuntimeError("rclone not installed. https://rclone.org/install/")
    staging.mkdir(parents=True, exist_ok=True)
    src = f"{remote}:{remote_path}" if remote_path else f"{remote}:"
    cmd = [
        "rclone",
        "copy",
        src,
        str(staging),
        "--drive-acknowledge-abuse",
        "--update",
        "--fast-list",
    ]
    print("+", " ".join(cmd))
    subprocess.run(cmd, check=True)
    imported = 0
    for path in staging.rglob("*"):
        if path.is_file() and import_local_file(
            path, catalog, source=source_label, meta={"rclone": src}
        ):
            imported += 1
    return imported


def sync_configured_rclone(settings: Settings, catalog: InspirationCatalog) -> int:
    total = 0
    stage_root = catalog.out_dir / ".rclone_stage"
    if settings.rclone_gdrive:
        total += sync_rclone_remote(
            settings.rclone_gdrive,
            settings.rclone_path,
            stage_root / "gdrive",
            catalog,
            "rclone_drive",
        )
    if settings.rclone_gphotos:
        # Note: rclone Google Photos backend has its own limits; still useful as a path.
        total += sync_rclone_remote(
            settings.rclone_gphotos,
            settings.rclone_path,
            stage_root / "gphotos",
            catalog,
            "rclone_photos",
        )
    return total
