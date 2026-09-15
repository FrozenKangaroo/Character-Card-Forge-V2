# v0.20.5 Expanded User Manual and Wiki Export

v0.20.5 turns the first searchable Help Center into the maintained user-manual source
for both the application and the GitHub Wiki. Guidance remains task-oriented, offline
inside the app and independent from provider or project data.

## Expanded in-app manual

The versioned catalog now contains 49 focused articles in ten sections:

- Getting Started;
- Creating Characters;
- Editing & Quality;
- Library & Organisation;
- Multi-Character Work;
- Images;
- Import & Export;
- Front Porch;
- Settings & Advanced;
- Help & Recovery.

The original 12 article IDs remain available. New articles split large feature families
into goal-focused tasks such as Character Collaborator handoff, AI Review, revisions,
portable libraries, group cards, image inputs, export profiles, Front Porch sync and
privacy-safe bug reporting.

## One documentation source

`data/help_articles_v1.json` remains the canonical structured article source.
`data/help_screenshots_v1.json` maps reviewed release-build captures to those stable
article IDs. The v0.20.5 exporter validates category/article IDs, related links, steps,
Wiki slug uniqueness, screenshot filenames, alternative text, captions and local source
assets, then creates:

- one Home page;
- one sidebar;
- ten category pages;
- 49 article pages.

All 61 pages are rendered deterministically. Export writes the expected Markdown files
and reviewed `images/user-manual/` assets into the selected directory; it does not
publish, delete remote content or contact GitHub.

```bash
python3 tools/export_user_manual_v0205.py
python3 tools/export_user_manual_v0205.py --output /path/to/wiki-checkout
```

## README front door

README now leads with the product, current status, major capabilities, supported desktop
platforms, installation, the first-character workflow, Front Porch boundaries, Help and
developer references. Detailed version history remains in `CHANGELOG.md`, `roadmap.md`
and milestone documents.

The first reviewed screenshot set contains 19 v0.20.7 Linux captures. Outer desktop
chrome and debug title bars are removed from documentation copies while the supplied
source captures remain untouched. Windows and macOS comparison captures remain part of
the public-bake evidence rather than being implied by this set.

## Safety and compatibility

- Help browsing and Wiki rendering are local deterministic operations.
- No AI provider, Front Porch or GitHub request occurs while reading or exporting Help.
- No character, project, prompt, conversation, credential or file-path data enters the
  manual.
- Screenshot assets are repository-owned, locally validated and copied byte-for-byte by
  the exporter rather than fetched from an external host.
- Existing stable article IDs, direct app routes and related links remain valid.
- The Help UI still routes actions through existing canonical Quick Actions instead of
  creating parallel workflows.
