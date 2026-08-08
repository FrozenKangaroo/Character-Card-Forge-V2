# v0.15.40-hotfix4 Runtime Report

Desktop runtime testing of v0.15.40-hotfix3 confirmed that the previous giant full-height action columns were removed, but the Reference Context sidebar was still not correct. The inherited Character Card helper sentence rendered as a narrow vertical column with approximately one character per line.

This proves hotfix3 fixed one user-visible failure shape but did not close the overall sidebar-layout issue. The development history must retain that distinction rather than marking hotfix3 fully resolved.

The visible vertical text matches the v0.15.37 helper label beginning `Character Card JSON/PNG added through Attach Files...`. That label was still inside `CollaboratorMultiSourceActionsV01537`, an `HFlowContainer`, while hotfix1–hotfix3 focused primarily on dynamic source/context rows and action-button geometry.

v0.15.40-hotfix4 moves explanatory labels out of action flow containers and makes that separation a tested runtime invariant.
