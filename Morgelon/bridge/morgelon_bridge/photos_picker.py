from __future__ import annotations

import time
from typing import Any

import requests
from google.oauth2.credentials import Credentials

from .auth import bearer_headers
from .catalog import InspirationCatalog, safe_name
from .config import Settings

PICKER_BASE = "https://photospicker.googleapis.com/v1"


def create_session(creds: Credentials) -> dict[str, Any]:
    r = requests.post(
        f"{PICKER_BASE}/sessions",
        headers={**bearer_headers(creds), "Content-Type": "application/json"},
        json={},
        timeout=60,
    )
    r.raise_for_status()
    return r.json()


def get_session(creds: Credentials, session_id: str) -> dict[str, Any]:
    r = requests.get(
        f"{PICKER_BASE}/sessions/{session_id}",
        headers=bearer_headers(creds),
        timeout=60,
    )
    r.raise_for_status()
    return r.json()


def list_picked_media(creds: Credentials, session_id: str) -> list[dict[str, Any]]:
    items: list[dict[str, Any]] = []
    page_token = None
    while True:
        params: dict[str, Any] = {"sessionId": session_id, "pageSize": 100}
        if page_token:
            params["pageToken"] = page_token
        r = requests.get(
            f"{PICKER_BASE}/mediaItems",
            headers=bearer_headers(creds),
            params=params,
            timeout=60,
        )
        r.raise_for_status()
        data = r.json()
        items.extend(data.get("mediaItems") or [])
        page_token = data.get("nextPageToken")
        if not page_token:
            break
    return items


def download_base_url(creds: Credentials, base_url: str, dest_path, *, video: bool) -> None:
    # Photos baseUrl requires auth header + =d / =dv
    url = base_url + ("=dv" if video else "=d")
    r = requests.get(url, headers=bearer_headers(creds), timeout=300, stream=True)
    r.raise_for_status()
    dest_path.parent.mkdir(parents=True, exist_ok=True)
    with dest_path.open("wb") as f:
        for chunk in r.iter_content(1024 * 256):
            if chunk:
                f.write(chunk)


def run_picker_import(
    creds: Credentials,
    settings: Settings,
    catalog: InspirationCatalog,
    *,
    open_browser: bool = True,
) -> int:
    """
    Google no longer allows apps to scrape your whole Photos library.
    Picker API: you choose albums/items in Google Photos; we import those.
    """
    session = create_session(creds)
    session_id = session.get("id") or session.get("sessionId")
    picker_uri = session.get("pickerUri") or session.get("pickerUri".lower())
    if not session_id or not picker_uri:
        # Some responses nest fields
        session_id = session_id or session.get("name", "").split("/")[-1]
        picker_uri = picker_uri or session.get("pickerUri")
    if not picker_uri:
        raise RuntimeError(f"Unexpected picker session response: {session}")

    # Web autoclose helper
    if "/autoclose" not in picker_uri:
        sep = "&" if "?" in picker_uri else ""
        # Docs: append /autoclose to URI path for web
        if picker_uri.rstrip("/").endswith("autoclose"):
            pass
        else:
            picker_uri = picker_uri.rstrip("/") + "/autoclose"

    print("\n=== Google Photos Picker ===")
    print("Open this URL, select inspiration photos/videos, then Done:\n")
    print(picker_uri)
    print()
    if open_browser:
        try:
            import webbrowser

            webbrowser.open(picker_uri)
        except Exception:
            pass

    # Poll until mediaItemsSet
    deadline = time.time() + 60 * 30
    while time.time() < deadline:
        st = get_session(creds, session_id)
        if st.get("mediaItemsSet") is True:
            break
        poll = settings.photos_poll_seconds
        # Honor server pollingConfig if present
        cfg = st.get("pollingConfig") or {}
        if cfg.get("pollInterval"):
            # e.g. "3.5s"
            raw = str(cfg["pollInterval"]).rstrip("s")
            try:
                poll = float(raw)
            except ValueError:
                pass
        time.sleep(max(1.0, poll))
    else:
        raise TimeoutError("Photos Picker timed out — run again and finish selecting.")

    media = list_picked_media(creds, session_id)
    imported = 0
    for m in media:
        mid = m.get("id") or (m.get("mediaItem") or {}).get("id")
        item = m.get("mediaItem") or m
        mid = mid or item.get("id")
        if not mid:
            continue
        key = f"photos:{mid}"
        if catalog.has_key(key):
            continue
        base = item.get("baseUrl") or m.get("baseUrl")
        if not base:
            continue
        meta = item.get("mediaFile") or item.get("mediaMetadata") or {}
        mime = (meta.get("mimeType") if isinstance(meta, dict) else None) or ""
        filename = (
            (meta.get("filename") if isinstance(meta, dict) else None)
            or item.get("filename")
            or mid
        )
        is_video = "video" in mime or str(filename).lower().endswith(
            (".mp4", ".mov", ".m4v", ".webm")
        )
        ext = ".mp4" if is_video else ".jpg"
        if "." in str(filename):
            ext = "." + str(filename).rsplit(".", 1)[-1].lower()
        dest = (
            catalog.out_dir
            / "photos"
            / f"{safe_name(str(filename).rsplit('.', 1)[0])}_{mid[:8]}{ext}"
        )
        download_base_url(creds, base, dest, video=is_video)
        catalog.register(
            key,
            source="photos",
            dest=dest,
            meta={"filename": filename, "mimeType": mime},
        )
        imported += 1
    return imported
