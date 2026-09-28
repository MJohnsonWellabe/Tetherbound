# F03#0 lure judge, set D (code-blind; all six)

**Input:** the 22 frames in `lure-judge-d/`. Each filename caption gives only distance, whether the player was on the road, or "glance" (the player turning the camera toward the place from the road).

| activity | run | verdict |
|---|---|---|
| herd | 36314439928 (S04, road-bound) | PASS (marginal): two harts on a rock read from the road at 63 m |
| bram | 36324730837 (S04, `--via=372,957`) | **PASS**: a dark column at 75-80 m from the road; camp and figure readable on approach |
| doss | 36320244563 (S07-band3) | **FAIL**: the column shows at 63 m behind the crest, but Doss, the fire and the perch are hidden until the prompt |
| juno | 36320553577 (S07-band4, column restored) | **PASS**: column at 160 m on the road; oxblood standards and the Meadowhart readable at 44-57 m |
| hall | 36311702392 (earned) | PASS (marginal): nameplate over trees at 86 m; the alpha readable at 30 m |
| vault | 36317749324 (derived pre-guardian S06) | **FAIL**: the door reads unlit beyond the guardian; one frame has the camera clipped inside the guardian |

**Result: 4 of 6. F03#0 stays PARTIAL.**

**Probe context:** `lure0/SIX-LURE-PROBE.txt`. All three columns are geometrically clear from most road samples. Doss's readability problem is the hill crest between the river-loop road and the camp.

## Next fixes (not started; owner wind-down)

- **Doss:** bring the camp, fire and perch into the river-loop sightline at 50-60 m (placement), or add a crest-top marker.
- **Vault:** the door seam light (art, Codex) needs to read from the den entry. The walker's den-entry shot must avoid the guardian clipping the camera.
