from __future__ import annotations

import hashlib
import json
import shutil
import time
from pathlib import Path
from typing import Any

from .config import MEDIA_EXT


def ensure_dirs(*paths: Path) -> None:
    for p in paths:
        p.mkdir(parents=True, exist_ok=True)


def safe_name(name: str) -> str:
    keep = "".join(c if c.isalnum() or c in "._- " else "_" for c in name)
    return keep.strip().replace(" ", "_")[:180] or "media"


def file_fingerprint(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()[:16]


class InspirationCatalog:
    """Tracks imported inspiration so re-runs are incremental."""

    def __init__(self, out_dir: Path):
        self.out_dir = out_dir
        self.path = out_dir / "catalog.json"
        ensure_dirs(out_dir)
        self.data: dict[str, Any] = {"imported": {}, "updated_at": None}
        if self.path.exists():
            self.data = json.loads(self.path.read_text())

    def has_key(self, key: str) -> bool:
        return key in self.data.get("imported", {})

    def register(
        self,
        key: str,
        *,
        source: str,
        dest: Path,
        meta: dict[str, Any] | None = None,
    ) -> None:
        rel = dest.relative_to(self.out_dir).as_posix()
        self.data.setdefault("imported", {})[key] = {
            "source": source,
            "path": rel,
            "meta": meta or {},
            "imported_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        }
        self.data["updated_at"] = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
        self.save()

    def save(self) -> None:
        self.path.write_text(json.dumps(self.data, indent=2) + "\n")

    def write_gallery_index(self) -> Path:
        items = []
        for key, row in sorted(
            self.data.get("imported", {}).items(),
            key=lambda kv: kv[1].get("imported_at", ""),
            reverse=True,
        ):
            items.append(
                {
                    "id": key,
                    "path": row["path"],
                    "source": row.get("source"),
                    "imported_at": row.get("imported_at"),
                    "meta": row.get("meta") or {},
                }
            )
        idx = {
            "title": "Morgelon inspiration",
            "count": len(items),
            "items": items,
        }
        out = self.out_dir / "gallery.json"
        out.write_text(json.dumps(idx, indent=2) + "\n")
        # Mirror into web assets when running from Morgelon tree
        try:
            web_insp = (
                Path(__file__).resolve().parents[2] / "web" / "assets" / "inspiration"
            )
            web_insp.mkdir(parents=True, exist_ok=True)
            # Symlink/copy media tree for the local web server
            for sub in self.out_dir.iterdir():
                if sub.name.startswith(".") or sub.name in {"catalog.json", "gallery.json"}:
                    continue
                target = web_insp / sub.name
                if sub.is_dir() and not target.exists():
                    try:
                        target.symlink_to(sub.resolve())
                    except OSError:
                        pass
            (web_insp / "gallery.json").write_text(json.dumps(idx, indent=2) + "\n")
        except Exception:
            pass
        return out


def import_local_file(
    src: Path,
    catalog: InspirationCatalog,
    *,
    source: str,
    key: str | None = None,
    meta: dict[str, Any] | None = None,
) -> Path | None:
    if not src.is_file():
        return None
    if src.suffix.lower() not in MEDIA_EXT:
        return None
    fp = file_fingerprint(src)
    k = key or f"{source}:{fp}"
    if catalog.has_key(k):
        return None
    dest_name = f"{safe_name(src.stem)}_{fp}{src.suffix.lower()}"
    dest = catalog.out_dir / source / dest_name
    dest.parent.mkdir(parents=True, exist_ok=True)
    if not dest.exists():
        shutil.copy2(src, dest)
    catalog.register(k, source=source, dest=dest, meta=meta)
    return dest
