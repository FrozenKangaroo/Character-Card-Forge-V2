# v0.15.40-hotfix4 Build Notes

This hotfix is intentionally scoped to the remaining Character Collaborator Reference Context width collapse observed after v0.15.40-hotfix3. It does not change Card metadata/Vision ingestion semantics, UserPersona filtering, AI job scheduling, or generation behavior.

The key invariant is structural: prose labels do not share the source action HFlow. They receive their own full-width source-panel row, while the action flow contains only compact controls.
