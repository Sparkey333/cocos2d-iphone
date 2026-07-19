# Higgsfield status (this environment)

CLI installed: `higgsfield` 1.1.18  
Auth: **not completed** in the cloud agent (OAuth needs your browser login).

## What to run on your machine

```bash
curl -fsSL https://raw.githubusercontent.com/higgsfield-ai/cli/main/install.sh | sh
higgsfield auth login
cd Morgelon/cinematic
./generate_higgsfield.sh
```

That generates Cinema Studio 2.5 stills + Cinema Studio Video 3.5 horror clips into `assets/stills` and `assets/clips`, then refreshes `manifest.json` for the cinematic player / DMG rebuild.

## Credentials alternative

```bash
export HF_CREDENTIALS='KEY_ID:KEY_SECRET'
# or HF_KEY / HF_API_KEY + HF_API_SECRET per Higgsfield docs
./generate_higgsfield.sh
```

Until auth succeeds, the DMG ships interim key art + the premium web slice.
