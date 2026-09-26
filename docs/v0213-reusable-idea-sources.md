# v0.21.3 — Reusable Idea Sources

Character Card Forge now separates reusable generator instructions from the specific
Ideas they produce.

## The three stages

- **Idea Source** — reusable input used to create many Ideas. It may describe a Series,
  scenario engine, premise, rules, variables, guardrails or a raw prompt.
- **Idea** — one specific generated result. Keep selected results in **Idea Notebook**.
- **Generation Concept** — the existing detailed Workspace input used later to build an
  actual character card.

The intended pipeline is:

```text
Idea Source → Idea Generator → generated Idea → Idea Notebook
            → Generation Concept → finished card
```

An Idea Source never becomes an Idea Notebook entry merely because it was loaded or
used. Likewise, the existing `.ccfideas.json` Idea Pack format still represents
finished Idea outputs and continues to import into Idea Notebook.

## Portable `.ccfideasource.json` files

The initial portable format uses:

```json
{
  "format": "character-card-forge-idea-source",
  "schema_version": 1,
  "id": "stable-source-id",
  "title": "Optional source title",
  "core_premise": "A reusable scenario engine"
}
```

The full schema may also carry a description, Source Bible/Series object, source
version, summary, setup, core variables, generation rules, guardrails, suggested
diversity axes, cross-links, tags, notes, arbitrary labelled sections and raw prompt
text. Unknown future fields are preserved. Files from a newer schema can be inspected
read-only but are not used as if the older app understood them.

The stable `id` is required. The title is optional. If it is blank, CCF asks the
configured Text model for a concise reusable name when the source is activated or the
author chooses **Suggest Name**. The response is editable. A failed or unavailable
naming request falls back locally and never blocks Idea generation.

## Source Library workflow

Open **Idea Generator → Idea Sources**.

1. Choose **New Source** or **Load Idea Source…**.
2. Review or edit the structured fields.
3. Choose **Use in Idea Generator**.
4. Configure the usual idea count, per-request batch size and detail/Custom length.
5. Generate normally.
6. Optionally choose **Save Current Source** or **Export Idea Source…**.

### Active source and one-off direction

After **Use in Idea Generator**, the AI Ideas tab shows a prominent active-source panel.
The source remains active across every request in a batch until it is cleared or
replaced.

- **Active Idea Source** is the reusable structured generator input.
- **Additional Direction** is optional, one-off guidance for the current generation
  or batch. Leaving it blank generates directly from the active source.
- **View/Edit Source** opens that same saved or temporary source in the existing
  source editor without copying or saving it automatically.
- **Change Source** returns to the Idea Sources workflow so another source can be
  selected, loaded or created and activated.
- **Clear Source** only stops using the source for generation. It does not delete a
  saved library entry, remove an external file or alter generated Ideas.

The structured source remains internal context and is injected once. CCF never copies
the rendered source into the Additional Direction field, so using both does not
duplicate the source context.

Loading an external file is temporary. It does not fill the Source Library and does not
create an Idea Notebook record. Only **Save Current Source** makes an internal durable
copy. Saved sources can be edited, renamed without changing their stable ID, duplicated
with a new ID or deleted independently of generated Ideas.

Example: load a “She Got Pregnant” source that defines its relationship engine,
paternity/confession variables, rules and guardrails. Generate 20 Ideas in batches of
four. Every provider request receives the same labelled source context, while the model
varies the allowed axes to produce distinct scenarios.

## Idea Packs remain outputs

The **Idea Notebook** tab retains **Import Idea Pack…** and **Export Idea Pack…**.
`.ccfideas.json` files are not generator instructions and are not reinterpreted as Idea
Sources. Existing preview, validation, stable-ID conflicts, Skip/Replace/Keep Both,
provenance and structured round-trip behavior remain intact.

## Generate Similar Ideas

With an existing card open, choose **Character → Generate Similar Ideas…**.

CCF builds a temporary editable Idea Source from the card's relationship structure,
setting role, tension engine, reveal mechanism, ground truth and variable axes. Exact
names, appearance, dialogue, biography, incidental hobbies, workplace, ages and scene
prose are explicitly marked as disposable unless essential to the engine.

Choose a similarity level:

- **Close** — strongly preserve the scenario engine while substantially changing the
  cast and surface circumstances.
- **Balanced** — preserve the main concept while changing several structural axes. This
  is the default.
- **Loose** — use the card as broader inspiration and permit related reinterpretations.

Then choose:

- **Generate Now** to activate the extracted source and start normal Idea generation;
- **Edit Extracted Source** to refine every field first; or
- **Save as Idea Source** to keep the engine for later reuse.

Example: a card about an established couple, a secret reconnection with an ex and a
delayed confession can become new concepts with different personalities, settings,
third parties, relationship histories, triggers, secrecy structures and reveal
mechanisms.

## Not Alternative Version

**Alternative Version** remains the existing workflow for another version of the same
character/card. It deliberately preserves much of that character.

**Generate Similar Ideas** uses only the reusable engine to propose new characters and
scenarios. It must not merely change a name, hair colour, job and location. Neither
extraction nor generation overwrites the source card.
