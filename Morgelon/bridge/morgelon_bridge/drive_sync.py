from __future__ import annotations

import io
from typing import Any

import requests
from google.oauth2.credentials import Credentials
from googleapiclient.discovery import build
from googleapiclient.http import MediaIoBaseDownload

from .catalog import InspirationCatalog, safe_name
from .config import MEDIA_EXT, Settings


def drive_service(creds: Credentials):
    return build("drive", "v3", credentials=creds, cache_discovery=False)


def resolve_folder_id(service, settings: Settings) -> str:
    if settings.drive_folder_id:
        return settings.drive_folder_id
    name = settings.drive_folder_name
    if not name:
        raise ValueError("Set BRIDGE_DRIVE_FOLDER_ID or BRIDGE_DRIVE_FOLDER_NAME")
    q = (
        "mimeType = 'application/vnd.google-apps.folder' "
        f"and name = '{name.replace(chr(39), chr(92) + chr(39))}' "
        "and trashed = false"
    )
    res = (
        service.files()
        .list(q=q, spaces="drive", fields="files(id, name)", pageSize=10)
        .execute()
    )
    files = res.get("files") or []
    if not files:
        raise FileNotFoundError(
            f"No Drive folder named '{name}'. Create it or set BRIDGE_DRIVE_FOLDER_ID."
        )
    return files[0]["id"]


def list_media_in_folder(service, folder_id: str) -> list[dict[str, Any]]:
    out: list[dict[str, Any]] = []
    page_token = None
    q = f"'{folder_id}' in parents and trashed = false"
    while True:
        res = (
            service.files()
            .list(
                q=q,
                spaces="drive",
                fields="nextPageToken, files(id, name, mimeType, md5Checksum, size, modifiedTime)",
                pageSize=100,
                pageToken=page_token,
            )
            .execute()
        )
        for f in res.get("files") or []:
            name = f.get("name") or ""
            mime = f.get("mimeType") or ""
            ext = ("." + name.rsplit(".", 1)[-1].lower()) if "." in name else ""
            if mime.startswith("image/") or mime.startswith("video/") or ext in MEDIA_EXT:
                out.append(f)
            elif mime == "application/vnd.google-apps.folder":
                out.extend(list_media_in_folder(service, f["id"]))
        page_token = res.get("nextPageToken")
        if not page_token:
            break
    return out


def download_file(service, file_meta: dict[str, Any], dest_path) -> None:
    request = service.files().get_media(fileId=file_meta["id"])
    dest_path.parent.mkdir(parents=True, exist_ok=True)
    fh = io.BytesIO()
    downloader = MediaIoBaseDownload(fh, request)
    done = False
    while not done:
        _, done = downloader.next_chunk()
    dest_path.write_bytes(fh.getvalue())


def sync_drive(creds: Credentials, settings: Settings, catalog: InspirationCatalog) -> int:
    service = drive_service(creds)
    folder_id = resolve_folder_id(service, settings)
    items = list_media_in_folder(service, folder_id)
    imported = 0
    for f in items:
        key = f"drive:{f['id']}"
        if catalog.has_key(key):
            continue
        name = f.get("name") or f["id"]
        ext = ""
        if "." in name:
            ext = "." + name.rsplit(".", 1)[-1].lower()
        elif (f.get("mimeType") or "").startswith("image/"):
            ext = ".jpg"
        elif (f.get("mimeType") or "").startswith("video/"):
            ext = ".mp4"
        dest = catalog.out_dir / "drive" / f"{safe_name(name.rsplit('.', 1)[0])}_{f['id'][:8]}{ext}"
        download_file(service, f, dest)
        catalog.register(
            key,
            source="drive",
            dest=dest,
            meta={
                "name": name,
                "mimeType": f.get("mimeType"),
                "modifiedTime": f.get("modifiedTime"),
            },
        )
        imported += 1
    return imported
