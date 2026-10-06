# Changelog

## 0.1.0+install (2026-10-06)

- Add `install/` — one-click Windows fleet installer (`install.ps1`) and
  uninstaller (`uninstall.ps1`). No admin required; everything lands in
  `%LOCALAPPDATA%\wallaby` and `%USERPROFILE%\.pi`; uninstall is zero-residue.
- `npm pkg fix` normalization (repository URL, keyword formatting).
  npm package content unchanged from 0.1.0.

## 0.1.0 (2026-10-06)

- Initial release: legacy `registerProvider("wallaby")` extension reusing pi's
  built-in `openai-completions` streaming; model `kimi-k3` (1,048,576 context /
  131,072 max output); key via `$WALLABY_API_KEY`; `pi-package` keyword + `pi`
  manifest for the pi.dev package gallery.
