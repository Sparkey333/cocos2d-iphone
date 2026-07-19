# Morgelon Google Bridge

Auto-import **Google Drive**, **Google Photos** (Picker), **local inbox / Takeout**, and optional **rclone** into:

`Morgelon/cinematic/assets/plates/inspiration/`

Google removed full-library Photos scraping (2025). Photos now uses the official **Photos Picker** — you select albums/items; we download them. Drive folder sync still runs unattended.

## One-time Google Cloud setup (you)

1. Open [Google Cloud Console](https://console.cloud.google.com/) → create/select a project  
2. **APIs & Services → Library** → enable:
   - **Google Drive API**
   - **Google Photos Picker API**
3. **OAuth consent screen** → External (or Internal if Workspace) → add your Google account as test user  
4. **Credentials → Create Credentials → OAuth client ID → Desktop app**  
5. Download JSON → save as:

```text
Morgelon/bridge/credentials/client_secret.json
```

6. Config:

```bash
cd Morgelon/bridge
cp .env.example .env
# edit .env — set BRIDGE_DRIVE_FOLDER_ID from your Drive folder URL
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python -m morgelon_bridge auth
```

Browser opens → sign in → allow Drive (read) + Photos Picker.

## All ways to import

| Command | What it does |
| --- | --- |
| `python -m morgelon_bridge auth` | OAuth once |
| `python -m morgelon_bridge drive` | Sync Drive folder (recursive images/videos) |
| `python -m morgelon_bridge photos` | Open Photos Picker → import your selection |
| `python -m morgelon_bridge inbox` | Import `plates/inbox` (Takeout / AirDrop / DJI copies) |
| `python -m morgelon_bridge rclone` | If `BRIDGE_RCLONE_*` set |
| `python -m morgelon_bridge sync` | inbox + Drive + rclone (non-interactive) |
| `python -m morgelon_bridge daemon` | Poll forever (Drive + inbox) |
| `python -m morgelon_bridge watch` | Inbox watcher only |
| `python -m morgelon_bridge status` | Config / catalog counts |

### Drive folder

Create a Drive folder (e.g. `Morgelon Inspiration`), paste photos/videos there, put its ID in `.env`:

```bash
BRIDGE_DRIVE_FOLDER_ID=1abc...   # from https://drive.google.com/drive/folders/1abc...
```

### Photos

```bash
python -m morgelon_bridge photos
```

Select Colorado / body / texture refs → Done. Files land under `inspiration/photos/`.

### Inbox / Takeout (no API)

Drop files or unpack Google Takeout into:

```text
Morgelon/cinematic/assets/plates/inbox/
```

Then `inbox` / `daemon`.

### rclone (optional third path)

```bash
rclone config   # remotes e.g. gdrive, gphotos
```

```env
BRIDGE_RCLONE_GDRIVE=gdrive
BRIDGE_RCLONE_GPHOTOS=gphotos
BRIDGE_RCLONE_PATH=Morgelon Inspiration
```

## Output

- Media: `cinematic/assets/plates/inspiration/{drive,photos,inbox,...}/`
- Catalog: `inspiration/catalog.json`
- Gallery JSON (for web): `web/assets/inspiration/gallery.json`
- View: serve `Morgelon/web` → `/inspiration.html`

## Security

- Never commit `client_secret.json` or `token.json` (gitignored)
- Scopes are read-only Drive + Photos Picker only
