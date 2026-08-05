# v0.15.36-hotfix1 — Configured Default Template Inheritance

## Problem

Character Card Forge allowed a user-created template to be selected as the application default, but some Workspace creation paths still hard-coded the built-in `default` template.

The main affected paths were:

- creating a brand-new Character Project from Home/Library;
- using **Add Character** inside an existing project;
- refreshing templates when a character's previously assigned template no longer exists.

This could make Workspace visibly switch to the built-in Default template even though a custom template remained configured as the application default.

## Root cause

The original shell used `CCFTemplateService.load_default_template()` for new projects. That function intentionally means the built-in bundled template, not the user's configured default preference.

Fresh character records also initialise `generation.template_id` to `default`. The old **Add Character** path switched to that record immediately without replacing the placeholder template ID with the configured application default.

Template refresh recovery likewise fell straight back to `default` when the previously assigned template was missing.

## Fix

v0.15.36-hotfix1 resolves the configured default through `CCFTemplatePreferenceService.default_template_id(settings)` whenever CCF needs to choose a template for newly created content.

- New projects assign the configured default template to the first character before the project is saved and opened.
- **Add Character** assigns the configured default template to the new character before Workspace switches to it.
- Missing-template recovery first falls back to the configured application default; the built-in Default remains the final fallback if the configured template is itself unavailable.

## Existing character behaviour

The hotfix does **not** reinterpret an existing explicit `generation.template_id = "default"` as the user's current application default.

That value continues to mean the built-in Default template for existing characters. This preserves per-character template choices and prevents changing old projects merely because the application default was changed later.

## Regression coverage

The focused regression creates a real user template, marks it as the application default, then verifies through the live app shell that:

1. a new project opens with the custom template;
2. the first character stores that custom template ID;
3. **Add Character** gives the next character the same configured default;
4. Workspace visibly remains on that custom template;
5. missing-template refresh recovery falls back to the configured custom default rather than directly to the built-in template.

The test runs with isolated `user://` state and is included in the hotfix quick regression manifest.
