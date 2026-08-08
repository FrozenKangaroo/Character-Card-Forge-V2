# v0.15.40-hotfix4 Regression Scope

The regression now targets the exact structure visible in the desktop screenshot:

- `CollaboratorMultiSourceActionsV01537` exists as the inherited source-action flow.
- The Character Card JSON/PNG explanatory helper must not be a child of that flow.
- The helper must be a direct full-width child of the source panel.
- The action flow must contain no `Label` children.
- Reintroducing the old helper-inside-HFlow structure must trigger the normal hotfix3 deferred reflow and restore the full-width layout.

Previous hotfix regressions remain active so giant source buttons, Card + Vision linkage, UserPersona exclusion, updater preservation, and Workspace AI activity are not regressed while correcting the helper-label width issue.
