# v0.21.12 settings data-safety hotfix

The v0.21.12 streaming regression originally exercised the production
`CCFSettingsService.save_settings()` wrapper. The official regression runner isolated
HOME and platform app-data directories, but launching that Godot test directly could
write a fresh default object to the real `app_settings.json`. That removed provider
profiles and UI state such as `getting_started_seen_v0201`.

## Intrinsically safe tests

The streaming test now saves and reloads through an explicit disposable path. Its
generation-service fixture receives that same path through a test-only override, so it
still exercises real normalization, serialization and preference routing without touching
the production settings file.

`tools/test_user_data_isolation.gd` supplies a second barrier. Every regression that writes
settings, projects, templates, notebooks, sessions, presets or other `user://` fixtures
activates it before persistence. The normal Python runner keeps its existing temporary
HOME/XDG/AppData isolation; a directly launched Godot test instead receives a separate
`ccf-regression-direct` user-data directory. A focused audit test prevents future
persistence regressions from omitting this guard.

## Durable production settings

Settings writes now:

1. normalize and serialize to a uniquely named staging file;
2. flush and parse that staged JSON;
3. preserve the current valid primary as `app_settings.json.bak`;
4. install the verified staging file using rename/rollback semantics;
5. verify the installed primary.

An unreadable primary with a valid backup loads the backup and reports recovery without
deleting the corrupt primary. A later safe save preserves that corrupt file with a
`.corrupt-…` suffix before replacement. If both primary and backup are invalid, defaults
may be used in memory so the application can start, but normal saves fail closed and both
files remain untouched for diagnosis.

Navigation now writes `last_view` only when its persisted value changes instead of
rewriting provider/API settings on every view refresh.

## Migration preservation

The focused regression begins with a populated format-9 fixture and verifies format-10
preservation of multiple text/image profiles, fake API keys, model and token settings,
Fast/Deep/Fallback/Vision/Image role assignments, generation preferences, library storage,
unknown supported fields, `last_view` and `getting_started_seen_v0201`. The new
`stream_ai_responses` field defaults to `false` when absent and both boolean values survive
atomic save/reload.
