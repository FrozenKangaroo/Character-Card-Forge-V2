# v0.17.3-hotfix1 — OpenRouter Images Routing

The v0.17.3 OpenAI-compatible image adapter always appended `/images/generations` to an Image profile's API base URL. That is correct for OpenAI's Images API and several compatible providers, but OpenRouter's dedicated image-generation contract uses `POST /api/v1/images`. OpenRouter model discovery could still succeed through its general `/api/v1/models` endpoint, producing the misleading sequence of a successful connection test followed by HTTP 404 during generation.

This hotfix detects the exact `openrouter.ai` host (including genuine subdomains but excluding lookalike domains) and routes Text to Image requests to OpenRouter's native endpoint. Other OpenAI-compatible providers retain `/images/generations`; Forge/A1111 behavior is unchanged.

## Configuration

Create or edit an Image Generation provider with:

- **Backend:** OpenAI-compatible Images API
- **API base URL:** `https://openrouter.ai/api/v1`
- **API key:** the user's OpenRouter key
- **Model:** an image-capable OpenRouter model slug

**Refresh Model Capabilities** now prefers `GET /api/v1/images/models`, so the selector is populated from OpenRouter's image-only catalog rather than its general text/model catalog. Existing profiles using the standard OpenRouter base URL require no migration.

The generation payload remains the existing provider-neutral `model`, `prompt`, `n` and optional `size` structure. OpenRouter's buffered `data[].b64_json` response is already accepted by CCF's image decoder. Model-specific additive parameters discovered by the existing v0.16.4 capability system continue to pass through without replacing core fields.

If a request fails, the visible Image Studio error now includes the credential-redacted request route and transport name. API keys, URL queries and fragments are never included in that route summary.

The focused regression verifies OpenRouter URL normalization, lookalike-host rejection, image-only model discovery, preservation of generic `/images/generations`, `b64_json` decoding, diagnostic URL redaction and the real mounted Image Studio service. It performs no provider request and uses no API key.
