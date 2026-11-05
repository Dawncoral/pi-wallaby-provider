/**
 * pi-wallaby-provider — Wallaby provider for the pi coding agent.
 *
 * Registers the "wallaby" provider using pi's legacy ProviderConfig form,
 * reusing the built-in "openai-completions" streaming implementation
 * (zero custom wire code). The API key is read from the WALLABY_API_KEY
 * environment variable at request time ($-interpolation, never stored).
 *
 * Model list: the extension factory is async, so pi waits for a short
 * discovery call before startup continues. When WALLABY_API_KEY is present,
 * it reads the gateway's /models plus the public pricing.json and registers
 * whatever the endpoint currently serves. Any failure falls back to the
 * static list below, so a fresh or offline session still works. New models
 * therefore appear after a restart without an npm release; only metadata for
 * a brand-new family needs a code change.
 *
 * Install: pi install npm:pi-wallaby-provider
 * Try once: pi -e npm:pi-wallaby-provider
 */

const BASE_URL = "https://api.wallabytoken.com/v1";
const PRICING_URL = "https://wallabytoken.com/pricing.json";
const DISCOVERY_TIMEOUT_MS = 2000;

type Cost = { input: number; output: number; cacheRead: number; cacheWrite: number };

type ModelSpec = {
  id: string;
  name: string;
  reasoning: boolean;
  input: ("text" | "image")[];
  contextWindow: number;
  maxTokens: number;
  cost: Cost;
};

/** Kimi family defaults; the endpoint is curated, so unknown ids fall back here. */
const KIMI_LIMITS = { contextWindow: 1048576, maxTokens: 131072 };

const STATIC_MODELS: ModelSpec[] = [
  {
    id: "kimi-k3",
    name: "Kimi K3 (Wallaby)",
    reasoning: true,
    input: ["text", "image"],
    ...KIMI_LIMITS,
    cost: { input: 2.55, output: 12.75, cacheRead: 0.255, cacheWrite: 2.55 },
  },
  {
    id: "kimi-k3.1-pro",
    name: "Kimi K3.1 Pro (Wallaby)",
    reasoning: true,
    input: ["text", "image"],
    ...KIMI_LIMITS,
    cost: { input: 1.8, output: 9.0, cacheRead: 0.18, cacheWrite: 1.8 },
  },
  {
    id: "kimi-k3.1-pro-highspeed",
    name: "Kimi K3.1 Pro Highspeed (Wallaby)",
    reasoning: true,
    input: ["text", "image"],
    ...KIMI_LIMITS,
    cost: { input: 3.6, output: 18.0, cacheRead: 0.18, cacheWrite: 3.6 },
  },
];

async function getJson(url: string, headers: Record<string, string> = {}): Promise<any> {
  const ctrl = new AbortController();
  const timer = setTimeout(() => ctrl.abort(), DISCOVERY_TIMEOUT_MS);
  try {
    const res = await fetch(url, { headers: { Accept: "application/json", ...headers }, signal: ctrl.signal });
    if (!res.ok) return undefined;
    return await res.json();
  } catch {
    return undefined;
  } finally {
    clearTimeout(timer);
  }
}

/** Build models from the live endpoint + the public price list. */
async function discoverModels(): Promise<ModelSpec[] | undefined> {
  const key = typeof process !== "undefined" ? process.env?.WALLABY_API_KEY : undefined;
  if (!key) return undefined;

  const [live, pricing] = await Promise.all([
    getJson(`${BASE_URL}/models`, { Authorization: `Bearer ${key}` }),
    getJson(PRICING_URL),
  ]);

  const ids: string[] = Array.isArray(live?.data)
    ? live.data.map((m: any) => m?.id).filter((id: unknown): id is string => typeof id === "string")
    : [];
  const prices: Record<string, any> = {};
  for (const m of pricing?.models ?? []) {
    if (m && typeof m.id === "string" && m.ours) prices[m.id] = m;
  }

  const models: ModelSpec[] = [];
  for (const id of ids) {
    const entry = prices[id];
    if (!entry) continue; // no price source, no honest cost to show
    const input = Number(entry.ours.input) || 0;
    const output = Number(entry.ours.output) || 0;
    const cacheRead = Number(entry.ours.cacheHitInput) || 0;
    models.push({
      id,
      name: `${entry.label ?? id} (Wallaby)`,
      reasoning: true,
      input: ["text", "image"],
      ...KIMI_LIMITS,
      cost: { input, output, cacheRead, cacheWrite: input },
    });
  }
  return models.length ? models.sort((a, b) => a.id.localeCompare(b.id)) : undefined;
}

export default async function (pi: any) {
  const discovered = await discoverModels();
  pi.registerProvider("wallaby", {
    name: "Wallaby",
    baseUrl: BASE_URL,
    apiKey: "$WALLABY_API_KEY",
    api: "openai-completions",
    models: discovered ?? STATIC_MODELS,
  });
}

export { STATIC_MODELS };
