# Controlled Builds

Character Card Forge v0.4.1 adds targeted generation workflows for changing only part of a character project.

Open a character and choose **Controlled Build** from the Character Workspace toolbar. The tool is a detachable native desktop window and uses the same API profile, model, queue, retry, cancellation, and Generation Preview systems as normal character generation.

## Safe Section Build

Safe Section Build targets every AI-generatable field in one template section.

The selected section is sent as the only writable output scope. Existing fields outside that section are supplied as protected context so the model can remain consistent with the character without being invited to rewrite unrelated content.

This is useful when, for example, the Overview is already correct but the complete Character section needs to be regenerated together.

## Custom Section Build

Custom Section Build allows any combination of AI-generatable template fields to be selected, even when they belong to different sections.

Only those field IDs are accepted as valid output targets. The Generation Preview applies the same scope boundary again, so a model that returns another known template field cannot sneak that field into the project.

## Revise Existing Content

Revision mode combines a custom field selection with freeform revision instructions.

Examples include:

- make the dialogue voice more distinctive without changing established facts;
- shorten the description while preserving appearance and backstory;
- make the first message more immediately interactive;
- remove repetitive personality wording across selected fields.

Existing target values are explicitly supplied as text to revise. Unselected character content remains protected context.

## Review and application

Controlled generation never applies directly to project data.

Results open in the normal Generation Preview, where each proposed field can be kept or discarded independently and the proposed value can be edited before applying it.

For controlled-build jobs, the preview also enforces the job's original allowed field-ID list. Out-of-scope fields returned by the model are blocked even when they are valid fields in the active template.

## Response repair and diagnostics

AI providers occasionally wrap JSON in prose or return almost-valid JSON. v0.4.1 adds a layered parser:

1. direct JSON parsing;
2. extraction of the first balanced JSON object or array;
3. local repair for common issues such as smart quotation marks and trailing commas;
4. one automatic AI JSON-repair request when the response is still unusable.

When repair was required, Generation Preview reports it. Applied generation-history entries also record the parse strategy and automatic repair count for later diagnostics.

No project data is changed when parsing or repair ultimately fails.

## Assigned series context

Controlled Build jobs receive the project's current series bible in addition to protected character, project, and relationship context. Series guidance cannot expand the job's allowed-field list; Preview still enforces the exact selected scope.
