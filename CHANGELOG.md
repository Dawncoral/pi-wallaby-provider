# Changelog

## 0.2.0 (2026-11-05)

- Add `kimi-k3.1-pro` and `kimi-k3.1-pro-highspeed`, with Highspeed priced at
  2x fresh input/output and the same cached-read rate.
- The extension factory is now async. With `WALLABY_API_KEY` set it reads the
  gateway's `/models` and the public `pricing.json` at startup, so new models
  appear after a restart without an npm release; ids without a price entry are
  skipped. Any failure falls back to the three-model static list.
- Provider display name is now "Wallaby" instead of "Wallaby (Kimi K3)".
- Update K3 pricing to $2.55 input / $12.75 output / $0.255 cache hit per 1M tokens, 15% off the official list.

## 0.1.1 (2026-10-13)

- Metadata/SEO pass: expanded npm keywords (`pi`, `cli`, `moonshot`, `kimi`);
  README badges (npm version/downloads/license); pricing table wording aligned
  with the standing "10% off the official list" positioning (was "promotional").
  No code changes.

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
