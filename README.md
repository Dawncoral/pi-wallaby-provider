# pi-wallaby-provider

Use [Wallaby](https://wallabytoken.com)'s Kimi K3 in the [pi coding agent](https://github.com/earendil-works/pi) — one-line install, pay-per-token, no subscription.

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
# or inside pi: /model → Kimi K3 (Wallaby)
```

## What you get

| Model | Context | Max output | Pricing (per 1M tokens, promotional) |
|---|---|---|---|
| `kimi-k3` | 1,048,576 | 131,072 | $2.70 in / $13.50 out / $0.27 cache hit |

## No install alternative

If you prefer zero packages, the same setup works via `~/.pi/agent/models.json` — see the step-by-step guide: [How to Use Kimi K3 in pi](https://wallabytoken.com/blog/p/kimi-k3-in-pi).

## License

MIT — WALLABY DATA PTY LTD
