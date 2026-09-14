# v0.20.2 Support & Diagnostics

v0.20.2 adds a permanent **Support & Diagnostics** entry to the sidebar and to
**Quick Actions**. It is intended for the pre-1.0 public bake period, where a
reproducible problem report is more useful than another broad feature family.

## What the report contains

- Character Card Forge and Godot versions.
- Operating-system, architecture, display and renderer categories.
- Window size and screen count.
- Library availability and local/portable storage category.
- Categorical AI-role state: configured or not, local or remote, whether a
  credential and model identifier are configured, and the Image backend type.

Configured model identifiers are excluded by default. The author may opt in when
the selected provider/model is relevant to the problem.

## What is always excluded

- Character, project, lorebook, scenario and revision content.
- Generation prompts, provider responses, Collaborator and Test Chat messages.
- API keys, passwords, two-factor codes, cookies and other session data.
- Provider and Front Porch endpoint addresses.
- Library roots, filenames and other file-system paths.
- Custom profile names and internal library/writer identifiers.

The report is previewed in full before sharing. **Copy Support Summary** and
**Export Diagnostic Bundle…** are explicit local actions. **Open Bug Report…**
opens the repository issue chooser only after an explicit click; Character Card
Forge never uploads or submits the report automatically.

Generation Diagnostics and Front Porch Connection Diagnostics remain the focused
tools for individual provider requests or connection tests. The v0.20.2 report is
a small environment summary that can be attached alongside those reports when
needed.
