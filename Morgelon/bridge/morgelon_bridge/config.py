from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path

from dotenv import load_dotenv

BRIDGE_ROOT = Path(__file__).resolve().parents[1]
REPO_MORGELON = BRIDGE_ROOT.parent


def _path(value: str | None, default: Path) -> Path:
    if not value:
        return default
    p = Path(value).expanduser()
    if not p.is_absolute():
        p = (BRIDGE_ROOT / p).resolve()
    return p


@dataclass
class Settings:
    client_secrets: Path
    token_path: Path
    drive_folder_id: str
    drive_folder_name: str
    watch_dir: Path
    out_dir: Path
    poll_seconds: int
    photos_poll_seconds: float
    rclone_gdrive: str
    rclone_gphotos: str
    rclone_path: str

    @classmethod
    def load(cls) -> "Settings":
        load_dotenv(BRIDGE_ROOT / ".env")
        out = _path(
            os.getenv("BRIDGE_OUT_DIR"),
            REPO_MORGELON / "cinematic" / "assets" / "plates" / "inspiration",
        )
        watch = _path(
            os.getenv("BRIDGE_WATCH_DIR"),
            REPO_MORGELON / "cinematic" / "assets" / "plates" / "inbox",
        )
        return cls(
            client_secrets=_path(
                os.getenv("GOOGLE_OAUTH_CLIENT_SECRETS"),
                BRIDGE_ROOT / "credentials" / "client_secret.json",
            ),
            token_path=_path(
                os.getenv("GOOGLE_TOKEN_PATH"),
                BRIDGE_ROOT / "credentials" / "token.json",
            ),
            drive_folder_id=os.getenv("BRIDGE_DRIVE_FOLDER_ID", "").strip(),
            drive_folder_name=os.getenv(
                "BRIDGE_DRIVE_FOLDER_NAME", "Morgelon Inspiration"
            ).strip(),
            watch_dir=watch,
            out_dir=out,
            poll_seconds=int(os.getenv("BRIDGE_POLL_SECONDS", "120")),
            photos_poll_seconds=float(os.getenv("BRIDGE_PHOTOS_POLL_SECONDS", "3")),
            rclone_gdrive=os.getenv("BRIDGE_RCLONE_GDRIVE", "").strip(),
            rclone_gphotos=os.getenv("BRIDGE_RCLONE_GPHOTOS", "").strip(),
            rclone_path=os.getenv("BRIDGE_RCLONE_PATH", "").strip(),
        )


# Drive + Photos Picker scopes (Photos full-library readonly removed by Google in 2025)
SCOPES = [
    "https://www.googleapis.com/auth/drive.readonly",
    "https://www.googleapis.com/auth/photospicker.mediaitems.readonly",
]

MEDIA_EXT = {
    ".jpg",
    ".jpeg",
    ".png",
    ".gif",
    ".webp",
    ".heic",
    ".heif",
    ".tif",
    ".tiff",
    ".mp4",
    ".mov",
    ".m4v",
    ".avi",
    ".mkv",
    ".webm",
}
