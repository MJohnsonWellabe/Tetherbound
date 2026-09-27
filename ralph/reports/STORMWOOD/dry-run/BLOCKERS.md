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
| B2 | run2 @ 44adfbe4 (`run2-44adfbe4.log`) | Dynamo: walk to the core ascent after Kestrel | `ordinary locomotion could not reach Stormheart approach foot`: the player wedged at (-96.1, 109.4, 5374.6). A read-only probe of the saved pose (title Load of the dry-run save) found the `OuterWorksApproach` slab, 10 m wide from the rod station (-100, 5350) to the deck edge at z 5426, floating over the terrain: 113.18 over terrain 110.34 at Kestrel's seat (-100, 5390), 111.10 over the player at the stall. Kestrel's trainer seat stands 2.7 m under it, and his NPC seat (-100, 5358) pokes up through it (body top 109.79, slab 108.85). | Stormwood (helper); product geometry: owner of `scripts/world/stormheart_tree.gd` | Helper fixed: `approach_foot_route()` steps straight sideways out from under the slab (headroom is constant across its width) to a lane 3 m west of it (x -108, 5 m from Kestrel's NPC), south past the foot, then onto it; unit test with a negative control (the old straight walk fails it). **Verified** in run4: from Ember Bivouac the player reached the foot and started the climb. **Product defect left open:** the slab has an open underside a player can walk into, and both Kestrel seats sit in its footprint. Moving the seats needs a scatter re-bake, and that is unsafe today (B3). Re-run pending. |
| B3 | run3 @ 6b25c50d (`run3-6b25c50d.log`) | Prefix: Ashfoot arch relight | Self-inflicted by 6b25c50d, which moved Kestrel's seats and re-baked the scatter: the relight press activated a vegetation prompt (`Vegetation/@Node3D@4222/Interactable`) at the same stance runs 1 and 2 relit from. The seat clearings changed which plants the bake keeps near Kestrel, and that shifts every later placement's index (the per-cell seeds did not change: a re-bake with the old seats reproduces HEAD byte for byte). Saved harvest state is a per-layer bitset by placement index (`vegetation.gd` `restore_from_game`), and the kept total stayed 34,638, so existing saves would silently mark the wrong plants harvested. | Stormwood | Reverted: the seats, re-bake and seat test are back to 44adfbe4. A seat move that changes the scatter needs a harvest-state migration first, so it is recorded as a product request, not done here. |
| B4 | run4 @ a9b6da46 (`run4-a9b6da46.log`) | Dynamo: Stormheart ascent | `unexpected combat blocks the bounded physical Stormheart ascent`: a wild engaged the player on the approach during the climb, and the helper failed on any combat. | Stormwood (`tests/helpers/stormwood_earned_dynamo_segment.gd`) | Fixed: a wild fight during the climb is fought at 1x like on every walk (`_fight_ascent_wild`), a healthy member leads on, and its frames are given back to the 6000-frame climb budget; a trainer battle mid-climb still fails. The budget test pins this. Re-run pending. |

Reached before B1 in run1, with 0 SCRIPT ERROR: the Stormwood prefix, a Still
Grove rest, the Capacitor Alpha, six live harvests, two camp crafts, the paid
Crown arch and Crown arrival.

Reached in run2 before B2, with 0 SCRIPT ERROR: everything above plus the Crown guardian, Wen, the Rootgate (Act II), Lantern Hollow, Sable, Nysa's Deepwood rod, Lieutenant Sera and the last rod, Ember Bivouac, and Officer Kestrel.

Reached in run4 before B4, with 0 SCRIPT ERROR (note: the dry-run framing changed under the 06:58 owner ruling; the fixture start is now a disclosed shortcut): everything in run2, plus the route round the approach slab to its foot and the start of the Stormheart climb.
