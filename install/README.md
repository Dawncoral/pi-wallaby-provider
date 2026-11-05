# One-click install / uninstall (Windows)

For fleets of Windows machines. No admin rights required; everything lands in
`%LOCALAPPDATA%\wallaby` and `%USERPROFILE%\.pi` only.

## Install

Open PowerShell in this folder (or download the two scripts) and run:

```powershell
powershell -ExecutionPolicy Bypass -File install.ps1 -ApiKey "sk-<one-key-per-machine>"
```

If `-ApiKey` is omitted, the script prompts for it — each user signs up at
[wallabytoken.com](https://wallabytoken.com?utm_source=npm&utm_medium=readme&utm_campaign=pi-wallaby-provider)
and creates their own key (trial credit included). One key per person/machine:
attributable, capped, revocable.

What it does:

1. Installs portable Node.js 22 (SHA256-verified) — skipped if Node ≥ 22.19 exists
2. Installs the pi coding agent into a private npm prefix
3. Runs `pi install npm:pi-wallaby-provider`
4. Sets `WALLABY_API_KEY` as a user-level environment variable
5. Installs portable Git Bash (best effort; pi works without it)
6. Verifies: `pi --list-models` must show `wallaby  kimi-k3`

Full log at `%LOCALAPPDATA%\wallaby\install.log`.

## Uninstall

```powershell
powershell -ExecutionPolicy Bypass -File uninstall.ps1        # keep chat history
powershell -ExecutionPolicy Bypass -File uninstall.ps1 -All   # also delete ~/.pi
```

Removes the private install root, the user PATH entries, and the API key.
Pre-existing system Node.js / Git for Windows are never touched.
