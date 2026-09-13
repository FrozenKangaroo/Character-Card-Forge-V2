# v0.19.3-hotfix1 — Front Porch Test Chat Completion

Character Card Forge's v0.19.2 Test Chat connected to Front Porch and accepted
send requests, but decoded the multiplexed WebSocket envelope with the wrong
discriminator. Front Porch emits server events in the `event` field. Its `type`
field is reserved for inbound client commands such as ping. As a result, CCF
ignored `token`, `done`, `error` and `chat_updated` events and could leave the
status at **Generating in Front Porch…** after Front Porch had finished.

This hotfix follows Front Porch's supported `/api/ws` contract:

- `token` appends live response text;
- `done` refreshes canonical `/api/chat/state` history and clears the status;
- `error` clears the pending state and presents Front Porch's error text;
- `chat_updated` refreshes canonical history;
- `generating` restores an accurate indicator after a reconnect; and
- the chat-state `isGenerating` and `isSettlingTurn` flags provide a fallback
  completion check if a client reconnect misses the terminal frame.

The older `type` discriminator remains a compatibility fallback for early
development builds. The change does not add a new simulation engine, store
credentials, alter Front Porch settings or access its database.
