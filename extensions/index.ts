/**
 * pi-wallaby-provider — Wallaby (Kimi K3) provider for the pi coding agent.
 *
 * Registers the "wallaby" provider using pi's legacy ProviderConfig form,
 * reusing the built-in "openai-completions" streaming implementation
 * (zero custom wire code). The API key is read from the WALLABY_API_KEY
 * environment variable at request time ($-interpolation, never stored).
 *
 * Install: pi install npm:pi-wallaby-provider
 * Try once: pi -e npm:pi-wallaby-provider
 */

export default function (pi) {
  pi.registerProvider("wallaby", {
    name: "Wallaby (Kimi K3)",
    baseUrl: "https://api.wallabytoken.com/v1",
    apiKey: "$WALLABY_API_KEY",
    api: "openai-completions",
    models: [
      {
        id: "kimi-k3",
        name: "Kimi K3 (Wallaby)",
        reasoning: true,
        input: ["text", "image"],
        contextWindow: 1048576,
        maxTokens: 131072,
        cost: { input: 2.7, output: 13.5, cacheRead: 0.27, cacheWrite: 2.7 },
      },
    ],
  });
}
