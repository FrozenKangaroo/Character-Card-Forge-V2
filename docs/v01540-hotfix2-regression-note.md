# Regression note — why hotfix1 missed the runtime failure

The v0.15.40-hotfix1 source-row regression validated `_build_source_row_v01540_hotfix1()` directly. That proved the replacement component's structure but did not prove the real Collaborator refresh lifecycle selected that renderer after structured Character Card ingestion and Vision linkage.

v0.15.40-hotfix2 closes that gap by testing the actual main scene, `add_source_v01537()`, stored linked Vision context, `_refresh_all()`, and `_refresh_source_panel_v01533()`. It also injects the old horizontal row shape and requires the active leaf to eliminate it during normal refresh.
