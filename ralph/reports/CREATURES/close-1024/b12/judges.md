# b12 (24 Oct 2026, CPU): F36#1 roster fixes vs the roster shipping tiles

Fixes (authored clips): recoil hit (head snaps up and away, chest back, feet planted) on Terrapup, Burrowback, Bramblebun; back-to-camera -90 roll faint on Terrapup and Burrowback; flat chin-down faint on Paddlenewt; sunk level swim (body median at the stage water line) on Ripplet; belly-flat sprawl faint on the Torrentoad, Mosshock and Cannonback remakes (vs the installed shipping models). Base tiles are the r1-r4 roster tiles (shipping, land head). Standard prompt verbatim, three fresh code-blind judges, anchors craft, f36_0_npc:C1 and one more pair (confirming). Fit linear slope 1.306, intercept -1.342, RMSE 0.26. Warning: Bramblebun (both sides) meets the bar only above the top anchor (7.53); this is the confirming batch.

| Species | Shipping | Fix | F36#1 poses on the fix | Disposition |
|---|---|---|---|---|
| bramblebun | 7.71 | **8.02** | hit Pa/F/Pa; faint F x3 | ON; F36#1 pass |
| terrapup | 7.02 | **7.28** | hit Pa x3; faint F x3; ride Pa x3 | ON; F36#1 pass |
| ripplet | 7.36 | **7.49** | hit Pa x3; faint F x3; swim Pa/F/Pa; ride F x3 | ON; F36#1 pass |
| burrowback | 6.93 | **7.23** | hit Pr/Pa/Pa; faint F x3; ride Pa/F/Pa | ON (beats shipping, faint fixed); F36#1 still open on the hit |
| mosshock (remake) | 4.45 | 7.15 | hit Pa x3; faint F x3 | HELD: judges read the remake as a toad and the shipping Mosshock as a lizard (identity change; coordinator call) |
| paddlenewt | 6.19 | 6.19 | faint Pr x3 (stands) | reverted |
| torrentoad (remake) | 6.19 | 6.45 | faint Pr/Pa/Pr | OFF; reverted to the roll faint |
| cannonback (remake) | 5.88 | 6.06 | faint Pr x3 (flip) | OFF; reverted to the roll faint |
