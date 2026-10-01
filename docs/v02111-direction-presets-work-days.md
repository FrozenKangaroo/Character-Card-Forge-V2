# v0.21.11 Direction Presets and Work Days

v0.21.11 adds optional, reusable **Additional Direction presets** to Idea Sources and
hardens Front Porch **Work Days** generation and application.

## Idea Source direction presets

An Idea Source can keep an ordered set of presets with a stable ID, optional group,
display title and exact direction text. The Idea Source editor provides a scrollable
list plus Add, Duplicate, Delete, Move Up and Move Down controls, so larger collections
remain manageable.

When a source is active, AI Ideas shows compact group and direction selectors. Choosing
a preset copies its text into the existing **Additional Direction** box. The copied text
is ordinary editable input: authors can tweak or replace it without changing the saved
preset. Choosing another preset replaces the box with that preset; choosing None/Custom
does not erase text that the author has edited.

Presets are shortcuts, not hidden prompt context. CCF never injects every saved preset
into generation. Only the actual text in Additional Direction is combined with the Idea
Source, exactly once. Completed generation and Generate More continue freezing that
actual text in their ordinary session snapshots.

Portable Idea Sources remain schema version 1. The new `direction_presets` array is
optional, source and preset order are preserved, and unknown future fields round-trip.
Preset records require unique non-empty IDs, titles and direction text. Presets by
themselves do not make an otherwise empty Idea Source generatable.

## Front Porch Work Days

The provider prompt now states the complete Front Porch mapping (Monday=1 through
Sunday=7) and requests a JSON integer array such as `[1,2,3,4,5]`.

For provider compatibility, CCF also accepts exact day-name arrays, comma-separated
numeric IDs, clear inclusive ranges such as `Mon-Fri`, and the exact words `weekdays`
or `weekends`. Accepted values are stored as sorted, unique integers in
`character.card_extensions.front_porch.realism_engine.workDays`. Ambiguous prose is
rejected and reported rather than being shown as successfully applied.

No project migration is required.
