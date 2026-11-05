# pi-wallaby-provider

[![npm version](https://img.shields.io/npm/v/pi-wallaby-provider)](https://www.npmjs.com/package/pi-wallaby-provider) [![npm downloads](https://img.shields.io/npm/dm/pi-wallaby-provider)](https://www.npmjs.com/package/pi-wallaby-provider) [![license](https://img.shields.io/npm/l/pi-wallaby-provider)](https://github.com/Dawncoral/pi-wallaby-provider/blob/main/LICENSE)

Use [Wallaby](https://wallabytoken.com)'s Kimi K3 and K3.1 Pro models in the [pi coding agent](https://github.com/earendil-works/pi) — one-line install, pay-per-token, no subscription.

## Install

```bash
pi install npm:pi-wallaby-provider
```

Or try it for a single run without installing:

```bash
pi -e npm:pi-wallaby-provider
```

## Configure

Set your API key (get one at [wallabytoken.com](https://wallabytoken.com)):

```bash
export WALLABY_API_KEY=sk-...
```

The key is read from the environment at request time — it is never written to disk by this package.

Then pick the model:

```bash
pi --model wallaby/kimi-k3
pi --model wallaby/kimi-k3.1-pro
pi --model wallaby/kimi-k3.1-pro-highspeed
# or inside pi: /model → Kimi K3.1 Pro (Wallaby)
```

## Model discovery

With `WALLABY_API_KEY` set, the provider reads the gateway's `/models` and the public `pricing.json` at startup and registers whatever the endpoint currently serves. Models without a price entry are skipped. If the network or key is unavailable, it falls back to the static list below, so a fresh or offline session still works.

## What you get

| Model | Context | Max output | Pricing (per 1M tokens, 10% off the official list) |
|---|---|---|---|
| `kimi-k3` | 1,048,576 | 131,072 | $2.55 in / $12.75 out / $0.255 cache hit |
| `kimi-k3.1-pro` | 1,048,576 | 131,072 | $1.80 in / $9.00 out / $0.18 cache hit |
| `kimi-k3.1-pro-highspeed` | 1,048,576 | 131,072 | $3.60 in / $18.00 out / $0.18 cache hit (2-3x speed) |

## No install alternative

If you prefer zero packages, the same setup works via `~/.pi/agent/models.json` — see the step-by-step guide: [How to Use Kimi K3 in pi](https://wallabytoken.com/blog/p/kimi-k3-in-pi).

## License

MIT — WALLABY DATA PTY LTD
