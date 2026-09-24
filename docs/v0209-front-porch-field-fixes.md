# v0.20.9 — Front Porch field reliability

This release corrects four issues found while authoring and exporting Front Porch 2.5 character-life data.

## Work days

Generated Work Days remain an editable comma-separated preview, but applying the preview now restores the canonical integer-array type before writing `extensions.front_porch.realism_engine.workDays`. Monday is `1` and Sunday is `7`; duplicate values are removed and values remain sorted.

## Work hours

Work hours now use separate **Start** and **End** controls in 24-hour `HH:MM` form. Character Card Forge serializes those controls to the exact string Front Porch's own time pickers produce, such as `9am–5pm` or `9:30am–5:15pm`.

Existing compatible 12-hour and 24-hour ranges reopen in the two controls. Free-form prose is retained visibly as an invalid imported value until the author replaces it, and validation prevents it from being treated as a valid shift. AI suggestions explicitly request a real clock range and reject holiday, flexible-schedule or availability prose in this field.

## Tab selection

Every Front Porch tab now includes **Select All Fields** and **Select None**. Hidden adult fields remain untouched until the author explicitly reveals them.

## First-message transport cleanup

The safe standalone-text recovery boundary now detects a provider response that contains valid First Message prose followed by a second raw `{"first_message": ...}` wrapper. Only the trailing wrapper is removed. Other fields and ordinary authored JSON-like prose are not changed.

The supplied Mika card demonstrated this provider-shape failure: its valid opening ended at character 2,933 and an unterminated second first-message object followed it. The character's private text is not stored in the regression fixture.
