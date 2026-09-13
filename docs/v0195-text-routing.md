# v0.19.5 — Task-Specific Text Routing and Fallback

## Text roles

Primary Text remains the required default and continues to handle full character
generation, Idea Generator, Character Collaborator, controlled builds and other existing
text workflows. Three optional assignments are available under **Settings → Character
AI → Task-specific Text routing**:

- **Fast / Suggestion Text** handles a single normal field or individual Front Porch
  field requested through **AI Suggest**.
- **Deep Review Text** handles the explicit full **AI Review** consistency pass.
- **Fallback Text** is an alternate producer used only through the bounded technical
  failure policy below.

Every optional selector starts at **Use Primary Text (default)**. This preserves existing
settings and behavior after upgrade and lets authors opt into only the routes they need.
Vision and Image Generation remain separate and are not changed by these assignments.

## Bounded technical fallback

Fallback requires both an explicitly selected profile that differs from the producing
profile and the separate fallback checkbox. It remains disabled by default. After the
configured ordinary retries are exhausted, one fallback request may be made for:

- a network transport failure;
- a request that cannot start;
- an unavailable endpoint or model response;
- provider rate limiting; or
- a provider service failure.

The fallback attempt has no further retry or fallback chain. Authentication failures,
permission failures, refusals, empty assistant content, invalid JSON, parse failures,
semantic validation failures and concept-fidelity failures do not trigger it.

## Visibility and provenance

The running job status names both the failed and fallback profiles when a switch occurs.
Successful result metadata records the requested task route, configured profile,
fallback reason, source producer, and actual producing fallback profile and model.
Failure diagnostics retain the routing event without exposing stored API credentials.
