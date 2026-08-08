# v0.15.40-hotfix2 — Release Summary

This hotfix addresses the runtime report that v0.15.40-hotfix1 still showed giant vertical source controls after Character Card PNG **Card data + Vision** ingestion.

The active Collaborator now treats the compact stacked source renderer as a live refresh invariant, not just a helper component. The final source-panel state is verified after normal refresh and any inherited horizontal fallback row is removed and rebuilt immediately.

The release preserves the existing v0.15.40 Workspace AI activity lifecycle, v0.15.39 Character Card metadata + Vision semantics, UserPersona exclusion, Safe Section contamination protection, Image Studio, updater safety, and Forward+ configuration.
