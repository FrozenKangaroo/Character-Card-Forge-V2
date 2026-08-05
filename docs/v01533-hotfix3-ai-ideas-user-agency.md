# v0.15.33-hotfix3 — AI Ideas User Agency Contract

## Goal

AI Ideas should define the generated character, the situation around them, and the pressures or choices available in the roleplay without deciding how `{{user}}` acts.

The future chat user is controlled by the person roleplaying. An Idea Generator result may preserve `{{user}}` facts/actions explicitly supplied in the source premise, but it must not invent new dialogue, choices, reactions, feelings, consent, attraction, hostility, forgiveness, investigation, confrontation, or other behaviour for `{{user}}`.

## Prompt contract

Every queued AI Ideas request now receives an explicit **USER AGENCY CONTRACT** in both the system and user prompt context.

The model is told to:

- treat `{{user}}` as exclusively player-controlled;
- describe the generated character's actions, wants, fears, plans, secrets, offers, expectations, and pressures;
- set up choices for `{{user}}` without choosing an answer;
- avoid asserting new `{{user}}` actions, dialogue, thoughts, feelings, decisions, consent, attraction, jealousy, forgiveness, hostility, or other reactions;
- preserve a `{{user}}` action when the author explicitly established it in the source premise;
- leave future actions open after that established setup;
- allow conditional/hypothetical framing such as `whether {{user}} confronts her` or `if {{user}} chooses to investigate`.

## Semantic validation

Prompt wording alone is not treated as sufficient. The v0.15.33-hotfix3 generation-service leaf extends the existing AI Ideas identity/POV validation with user-agency checks over:

- `concept`;
- `roleplay_hook`.

The validator rejects common forms of model-authored user agency, including direct actions/reactions, prescriptive `must`/`should`/`has to` language, and asserted emotional states.

Examples rejected when not present in the source premise:

```text
{{user}} confronts Hana and demands an explanation.
{{user}} forgives her.
{{user}} is jealous.
{{user}} must decide to stay.
```

Examples intentionally allowed:

```text
Hana worries that {{user}} may reject her.
The tension depends on whether {{user}} confronts Hana.
If {{user}} chooses to investigate, Hana has several secrets to protect.
```

A source-authored setup such as:

```text
{{user}} catches Hana hiding a second phone.
```

may be preserved by the generated concept. The generator still may not decide what `{{user}}` does after that event unless the author supplied that action too.

## Repair

Agency violations feed into the existing single bounded semantic-repair pass. The repair request receives the same User Agency Contract and is explicitly instructed to preserve valid source facts while removing invented `{{user}}` behaviour.

This keeps the existing repair/fail-closed pipeline rather than adding a parallel response path.

## Runtime composition

The current worker chain is:

```text
v0.15.26 scheduler / concurrency / Safe Sections
        ↓
v0.15.31 AI Jobs inspection / selective cancellation
        ↓
v0.15.33 provider-envelope hardening
        ↓
v0.15.33-hotfix3 AI Ideas user-agency contract
```

The live Workspace installs the hotfix3 service leaf for current workers while retaining v0.15.33-hotfix2 Idea Notebook completion capture and v0.15.33-hotfix1 Structured Builder → Collaborator handoff.

## Scope

This hotfix is deliberately limited to AI Ideas. The same player-agency principle may later be generalised into shared Character Collaborator/card-generation guidance, but v0.15.33-hotfix3 does not silently alter every authoring workflow.

v0.15.34 remains reserved for Existing Character → Character Collaborator.
