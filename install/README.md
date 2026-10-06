# One-click install / uninstall (Windows)

For fleets of Windows machines. No admin rights required; everything lands in
`%LOCALAPPDATA%\wallaby` and `%USERPROFILE%\.pi` only.

## Install

Open PowerShell in this folder (or download the two scripts) and run:

```powershell
powershell -ExecutionPolicy Bypass -File install.ps1 -ApiKey "sk-<one-key-per-machine>"
```

If `-ApiKey` is omitted, the script prompts for it. Use **one key per machine**
so usage stays attributable and revocable.

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

## 中文速查（给装机同事）

1. 把这两个文件拷到机器上（或同一文件夹）
2. 右键 → 使用 PowerShell 运行 `install.ps1`，按提示粘贴这台机器的 key
   （key 由 Wallaby 提供，一台机器一个，不要混用）
3. 看到绿色 “Done” 即完成；新开终端输入 `pi` 开始用
4. 要删除：运行 `uninstall.ps1`（加 `-All` 连聊天记录一起删）
5. 全程不需要管理员权限，不动系统目录，不影响电脑里其他软件
