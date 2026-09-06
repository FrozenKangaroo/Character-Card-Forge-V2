# v0.17.1 — Collaborator Evidence Roles & Conflict Review

v0.17.1 makes multi-source precedence visible and keeps potential conflicts reviewable without pretending that every kind of evidence belongs in a single simplistic hierarchy.

## Evidence roles

Character Collaborator now labels each structured source by how it should be used:

- **TARGET CANON** — the one current Workspace character eligible for Compare & Apply.
- **STRUCTURED FACTS** — established facts belonging to a separately identified character or Character Card source. A reference never silently overwrites the target.
- **AUTHOR REFERENCE** — Ideas, Builder material, pasted sources and other author-supplied context that can inform proposals.
- **CREATIVE INTENT** — an Image Studio result and its generation prompt/settings. The prompt records intent and provenance, not proof that every detail appears in the pixels.
- **VISION OBSERVATION** — a separately linked Vision description of apparent image content. It is supplementary evidence and never overwrites structured metadata automatically.

The author's current request can explicitly ask for a change, branch or reinterpretation, but stored source snapshots remain immutable.

## Conflict review

The new **Evidence roles & conflict review** panel lists all active sources and explains their roles. It raises review notices when:

- an existing target is accompanied by references;
- several structured character/card sources need to remain separately identified;
- Character Card metadata and linked Vision both describe the same card image;
- an Image Studio prompt and linked Vision both describe the same generated image.

These are review boundaries, not automated claims that a semantic conflict definitely exists.

For linked visual sources, **Review Evidence…** presents the structured/raw AI-facing source snapshot and each linked Vision description in one read-only dialog. Differences remain visible for an explicit author decision.

## Model-facing behaviour

The Text Collaborator receives the same evidence map and rules before its normal structured source context. It must identify discrepancies, preserve source identity, label proposed details and avoid silently selecting or blending incompatible facts.

Presentation and review never mutate source snapshots, Vision context, project data or canonical character fields. Existing explicit Collaborator apply and completion flows remain the only write boundaries.
