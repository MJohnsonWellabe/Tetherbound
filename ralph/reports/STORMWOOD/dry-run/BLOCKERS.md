# Stormwood relay segment — DRY RUN blockers (does not count)

Every run here starts from `tests/smoke_stormwood_continuous.gd`'s disclosed
Cloudreach-boundary fixture: an in-memory completed-Cloudreach party and
entitlement, then entry through the production realm router. **DRY RUN — does
not count.** It exists to find what would stop the earned relay segment
(`stormwood_arrived` → Crown → Rootgate → Dynamo → Marrow → Waterward →
`water_arrived`), so each owned blocker is fixed before the earned run.

Command: `godot --headless --path . --script tests/smoke_stormwood_continuous.gd -- --through-aftermath --witness-dir=user://<dir>`

| # | Run / SHA | Stage | What stopped it | Owner | Status |
|---|---|---|---|---|---|
| B1 | run1 @ bdec4948 (`run1-bdec4948.log`) | Rootgate: Crown guardian | Crossed the paid arch with Bramblebun fainted and the lead at 44 hp; Brooktail lost the guardian at 81/318. Three more approaches pressed nothing: an ordinary wild Staticub stood 1.1 m from the stance, so every Engage offer named it (`candidate Wild_staticub_…_2`), and the helper presses only a guardian offer. | Stormwood (`tests/helpers/stormwood_earned_rootgate_segment.gd`) | Fixed in the helper: rest at Still Grove Shelter (~40 m from the arch footing) when worn before crossing; fight the nearer wild first, as `_clear_capacitor_alpha` already does; 6 approaches. Re-run pending. |

Reached before B1 in run1, with 0 SCRIPT ERROR: the Stormwood prefix, a Still
Grove rest, the Capacitor Alpha, six live harvests, two camp crafts, the paid
Crown arch and Crown arrival.
