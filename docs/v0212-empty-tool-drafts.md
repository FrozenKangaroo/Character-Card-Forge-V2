# v0.21.2 Empty Workspace Tool Drafts

## Purpose

Starting Idea Generator, Character Collaborator or another creation route needs a real
in-memory project so the Workspace has a template, stable IDs and an active character.
That technical draft should not become a Character Library entry before the author has
created anything.

## Persistence contract

- A newly created project with one empty placeholder character remains in memory.
- Selecting a template or opening a Workspace tool does not persist that draft.
- Idea Notebook and Character Collaborator retain their own durable tool/session state;
  that state does not turn the empty character placeholder into a Library project.
- Adding meaningful character or project content and choosing **Save** performs the
  normal first save and adds the project to the Library.
- Already persisted projects continue to save normally and are never removed by this
  guard.

Meaningful content follows the existing deferred-save contract: an authored character
name or field, Generation Concept, project name, shared context, relationships,
attachments and other deliberate project data all qualify. Default IDs, timestamps,
placeholder names, template assignment and Workspace navigation state do not.

## Existing empty projects

The fix prevents new accidental entries. It does not automatically delete blank projects
written by older builds, because CCF cannot safely infer that every existing project is
disposable. Those entries remain available for manual review, archive or deletion.
