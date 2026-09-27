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
| B2 | run2 @ 44adfbe4 (`run2-44adfbe4.log`) | Dynamo: walk to the core ascent after Kestrel | `ordinary locomotion could not reach Stormheart approach foot`: the player wedged at (-96.1, 109.4, 5374.6). A read-only probe of the saved pose (title Load of the dry-run save) found the `OuterWorksApproach` slab, 10 m wide from the rod station (-100, 5350) to the deck edge at z 5426, floating over the terrain: 113.18 over terrain 110.34 at Kestrel's seat (-100, 5390), 111.10 over the player at the stall. Kestrel's trainer seat stood 2.7 m under it, and his NPC seat (-100, 5358) poked up through it (body top 109.79, slab 108.85). | Stormwood (seat data, helper) | Fixed: both Kestrel seats moved 13 m west onto open terrain (probed clear), with `_why_moved_f11_approach`; the scatter was re-baked (its fingerprint seeds every region); a data test now forbids any terrain seat inside the slab's footprint; the Dynamo helper keeps west of the slab and mounts it at its foot from the south. Re-run pending. Not fixed, for the owner of `scripts/world/stormheart_tree.gd`: the slab still floats with an open underside a player can walk into. |

Reached before B1 in run1, with 0 SCRIPT ERROR: the Stormwood prefix, a Still
Grove rest, the Capacitor Alpha, six live harvests, two camp crafts, the paid
Crown arch and Crown arrival.

Reached in run2 before B2, with 0 SCRIPT ERROR: everything above plus the Crown guardian, Wen, the Rootgate (Act II), Lantern Hollow, Sable, Nysa's Deepwood rod, Lieutenant Sera and the last rod, Ember Bivouac, and Officer Kestrel.
