# v0.15.36-hotfix2 — AI Ideas Agency, Backstory, and POV Validation

## Why this hotfix exists

A real AI Ideas diagnostic showed two successful provider responses being rejected by Character Card Forge after semantic validation. The provider returned HTTP 200 responses, normal `stop` termination, complete parseable JSON, and all requested ideas. CCF then spent a second large repair request and still failed the batch.

The failure exposed three application-side validation problems rather than a provider/API failure.

1. A secrecy premise beginning with **“Without {{user}} realising…”** was incorrectly classified as detached POV because the older detector treated any occurrence of `without {{user}}` as an observer/narrator request.
2. The old character-role guard scanned every guarded relationship/profession term anywhere in `character_role`. A correct card subject such as `{{user}}`'s wife could therefore be rejected merely because the sentence also mentioned a supporting colleague, therapist, brother, or other NPC.
3. The v0.15.33-hotfix3 User Agency rule was intentionally conservative but too broad for practical roleplay openings. It could treat harmless temporary scene logistics as if CCF had authored the player's identity.

## Refined `{{user}}` boundary

The hotfix distinguishes **temporary scene setting** from **substantive user canon**.

### Allowed scene logistics

AI Ideas may create small, temporary circumstances when they are useful to make an opening playable and do not define who `{{user}}` is. Examples include:

- `{{user}}` passed out early at an ordinary event;
- `{{user}}` works late on a particular occasion or as a scheduling circumstance;
- `{{user}}` is on a work call;
- `{{user}}` is asleep or in another room;
- `{{user}}` is at work, arriving home, or briefly out on an ordinary errand.

Ordinary past logistics are also permitted when they do not create durable personality or life-history canon.

### Still prohibited unless supplied by the author

AI Ideas must not invent substantive, durable `{{user}}` canon such as:

- personality or long-term emotional tendencies;
- beliefs, values, preferences, jealousy, possessiveness, or trust style;
- profession/career identity;
- upbringing, trauma, major family history, or established personal history;
- sexual preferences, kinks, or other durable private traits;
- ongoing suspicions, motives, plans, or long-running behaviour;
- a meaningful opening reaction, accusation, confrontation, forgiveness, investigation, consent decision, or other consequential choice.

Conditional choices remain valid. For example, `whether {{user}} confronts her` leaves the roleplayer's decision open and is different from `{{user}} confronts her immediately`.

## Detached POV

Detached mode now requires an explicit author request for an observer/narrator/world-NPC/omniscient/detached viewpoint. Generic text such as `without {{user}} realising`, `without {{user}} knowing`, or other secrecy framing no longer enables detached mode.

## Card-subject identity

Identity validation now asks whether the generated card subject itself is valid. Supporting NPC terms inside a longer `character_role` no longer redefine the card subject.

A concept clearly identifying its supplied `character_name` in third person is valid. `the character` and clean pronoun-led third-person prose are also supported. Second-person `you/your` narration and attempts to make `{{user}}` the generated card subject remain invalid.

## Repair and Diagnostics

Semantic repair receives the refined agency/backstory contract and is told to repair only reported problems while preserving valid detail and diversity. The repair prompt explicitly states that minor temporary scene logistics are allowed.

Idea validation now writes its report into the existing Generation Diagnostics state. A future failed Idea batch therefore records the actual identity/POV/agency issues that caused the failure instead of exporting an empty validation report.

## Regression coverage

The focused v0.15.36-hotfix2 regression uses the same kind of secrecy premise that exposed the bug and verifies:

- `Without {{user}} realising...` does not trigger detached POV;
- an explicit observer-card request still does;
- a correct partner card remains valid when its role also mentions a supporting colleague;
- `{{user}} passed out early`, `{{user}} works late`, and `{{user}} is on a work call` are accepted as scene logistics;
- invented jealousy/controlling personality, detective profession, and childhood trauma are rejected as substantive user canon;
- forced confrontation/dialogue is rejected;
- conditional confrontation remains valid;
- queued and repair prompts carry the refined contract;
- validation state is retained for Diagnostics;
- the real main scene uses the new hotfix2 generation-service leaf.

The broad regression layer inherits v0.15.36-hotfix1 and therefore also retains the configured-default-template fix, Collaborator Compare & Apply coverage, Forward+ assertions, and historical cross-feature protection.
