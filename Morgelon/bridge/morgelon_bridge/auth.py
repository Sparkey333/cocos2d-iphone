from __future__ import annotations

import json
from pathlib import Path

from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow

from .config import SCOPES, Settings


def load_credentials(settings: Settings) -> Credentials:
    if not settings.client_secrets.exists():
        raise FileNotFoundError(
            f"Missing OAuth client secrets at {settings.client_secrets}\n"
            "1) Google Cloud Console → APIs & Services → Credentials → Create OAuth client (Desktop)\n"
            "2) Enable: Google Drive API + Google Photos Picker API\n"
            "3) Download JSON → save as bridge/credentials/client_secret.json\n"
            "4) cp bridge/.env.example bridge/.env"
        )

    creds: Credentials | None = None
    if settings.token_path.exists():
        creds = Credentials.from_authorized_user_file(str(settings.token_path), SCOPES)

    if creds and creds.expired and creds.refresh_token:
        creds.refresh(Request())
        _save(creds, settings.token_path)
        return creds

    if creds and creds.valid:
        # Re-auth if scopes changed
        have = set(creds.scopes or [])
        need = set(SCOPES)
        if need.issubset(have):
            return creds

    flow = InstalledAppFlow.from_client_secrets_file(str(settings.client_secrets), SCOPES)
    creds = flow.run_local_server(port=0, prompt="consent")
    _save(creds, settings.token_path)
    return creds


def _save(creds: Credentials, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(creds.to_json())


def bearer_headers(creds: Credentials) -> dict[str, str]:
    if not creds.valid:
        if creds.refresh_token:
            creds.refresh(Request())
        else:
            raise RuntimeError("Credentials invalid; run: python -m morgelon_bridge auth")
    return {"Authorization": f"Bearer {creds.token}"}
