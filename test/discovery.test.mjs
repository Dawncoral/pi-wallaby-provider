// Discovery smoke test: stub /models + pricing.json, assert the registered list.
import assert from "node:assert/strict";

process.env.WALLABY_API_KEY = "test";

const pricing = {
  models: [
    { id: "kimi-k3", label: "Kimi K3", ours: { input: 2.55, output: 12.75, cacheHitInput: 0.255 } },
    { id: "kimi-k3.1-pro", label: "Kimi K3.1 Pro", ours: { input: 1.8, output: 9, cacheHitInput: 0.18 } },
    {
      id: "kimi-k3.1-pro-highspeed",
      label: "Kimi K3.1 Pro Highspeed",
      ours: { input: 3.6, output: 18, cacheHitInput: 0.18 },
    },
  ],
};

globalThis.fetch = async (url) => ({
  ok: true,
  json: async () =>
    String(url).includes("pricing")
      ? pricing
      : { data: [{ id: "kimi-k3" }, { id: "kimi-k3.1-pro" }, { id: "kimi-k3.1-pro-highspeed" }, { id: "unpriced" }] },
});

const mod = await import("../extensions/index.ts");
const registered = [];
await mod.default({ registerProvider: (name, cfg) => registered.push({ name, models: cfg.models }) });

const models = registered[0].models;
assert.deepEqual(models.map((m) => m.id), ["kimi-k3", "kimi-k3.1-pro", "kimi-k3.1-pro-highspeed"]);
assert.equal(models[1].cost.input, 1.8);
assert.equal(models[2].cost.output, 18);
assert.deepEqual(models[1].thinkingLevelMap, { minimal: null, medium: null });
assert.deepEqual(models[2].thinkingLevelMap, { minimal: null, medium: null });
assert.equal(models[0].thinkingLevelMap, undefined);
for (const id of ["kimi-k3.1-pro", "kimi-k3.1-pro-highspeed"]) {
  assert.deepEqual(mod.STATIC_MODELS.find((m) => m.id === id).thinkingLevelMap, { minimal: null, medium: null });
}
assert.equal(mod.STATIC_MODELS[0].thinkingLevelMap, undefined);
console.log("ok:", models.map((m) => m.id).join(", "));
