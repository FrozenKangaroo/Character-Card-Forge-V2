# Character Card Forge User Documentation Plan

The GitHub Wiki will be the primary expanded task-oriented user manual during the pre-1.0 public bake period. Repository `docs/` remains the home of schemas, architectural contracts, milestone implementation notes and regression details.

v0.20.3 establishes the first verified documentation set inside the app: 12 searchable
offline guides covering first launch, core creation and editing, Library, images,
import/export, Front Porch, backup, troubleshooting and privacy. Those guides are the
starting source for the corresponding Wiki pages, not a substitute for the full manual.

v0.20.5 completes the structured manual source: 49 focused articles cover the ten
sections below, while a deterministic exporter produces Home, sidebar, category and
article Markdown from the same validated catalog. Publication remains an explicit
reviewed maintainer action, so generated pages cannot overwrite the Wiki automatically.

## README: product front door

The final pre-1.0 README should contain only:

- what Character Card Forge is;
- current screenshots and major capabilities;
- supported desktop platforms;
- installation and first launch;
- a short first-character path;
- a concise Front Porch integration summary;
- links to releases, Wiki, roadmap and developer documentation;
- current stable/development status.

Version-by-version history belongs in `CHANGELOG.md`, `roadmap.md` and milestone documents rather than the README's main path.

## Wiki structure

### Getting Started

- Installation
- First Launch
- Provider Setup
- Creating Your First Character
- Importing an Existing Character

### Creating Characters

- Manual Editing and Manual Guided
- Character Builder
- Idea Generator
- Character Collaborator
- Idea Notebook
- Templates and Generation Modes

### Editing and Quality

- Workspace and Layouts
- Alternative Greetings
- Scenario Presets
- Lorebooks and Relationships
- Card Inspector
- AI Review
- Revision History
- Compact/Lite Derivatives

### Library and Organisation

- Character Library
- Search, Filters and Saved Views
- Collections, Tags and Workflow States
- Duplicate Handling and Archive
- Adult/Private Presentation Controls
- Portable, Shared-Folder and NAS Libraries
- Library Panels, Auto-Hide and Card Density

### Multi-Character Work

- Multi-Character Projects
- Adding Existing Library Characters
- Group Cards and Split Character Sets
- Persistent Roster and Active Cast
- Shared Worlds and Card Workflow Studio

### Images

- Image Studio and Provider Setup
- Image Styles and Generation Profiles
- Image-to-Image, References and Inpainting
- Portraits, Avatar Gallery and Expression Sets

### Import and Export

- Character Card V2 JSON and PNG
- SillyTavern and Export Profiles
- Project Packages
- PDF and URL Reference Sources

### Front Porch

- Connecting Character Card Forge
- Installing, Updating and Syncing Characters
- Optional Character-Life Fields
- Group Cards and Worlds
- Expressions and Avatar Gallery
- Test Chat and Chat Exchange
- Troubleshooting

### Settings and Advanced

- Primary, Fast, Deep Review and Fallback Text Routes
- Vision and Image Profiles
- Storage and Updates
- Diagnostics
- Advanced/Expert Functions

### Help

- Troubleshooting and FAQ
- Backup and Recovery
- Known Limitations
- Reporting a Bug

## Authoring rules

- Organise pages by user goal, not version number.
- Use exact shipped labels and current screenshots.
- Prefer focused pages with Related Pages links over one enormous manual.
- Put warnings only beside destructive, privacy-sensitive or networked actions.
- Name supported configurations and limitations instead of implying universal third-party compatibility.
- Keep sections focused and consistently headed so a future retrieval-based in-app help system can reuse them without sending the entire manual to a model.

## Publication order

1. Getting Started and first-character workflow.
2. Import/export, provider setup and troubleshooting.
3. Core Workspace, Library and quality tools.
4. Front Porch and multi-character workflows.
5. Image Studio and advanced settings.
6. Recovery, known limitations and FAQ.

Each page should be verified against the current packaged build before publication.
The first screenshot pass maps 19 reviewed v0.20.7 Linux captures across the core
creation, editing, Library, multi-character, image, import/export and Front Porch pages.
Windows and macOS captures are still required for platform-specific visual comparison;
the Wiki does not need duplicate platform images where the application UI is identical.

## v0.20.5 implementation status

- [x] Expand the offline catalog into all ten manual sections.
- [x] Preserve the original stable article IDs and canonical in-app action routes.
- [x] Generate deterministic Wiki Home, sidebar, category and article pages.
- [x] Validate article/category identities, related links and Wiki slug uniqueness.
- [x] Restructure README as the product and first-use front door.
- [x] Capture, review and integrate the first current Linux package screenshot set.
- [ ] Capture Windows and macOS comparison screenshots for platform-specific differences.
- [x] Publish the generated 61-page manual to the GitHub Wiki.
