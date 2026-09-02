# Round 8 prep — the three camps (VP5)

**Prepared, not started**, per the round-7 dispatch. This is a plan for the coordinator to approve or
amend; no camp file has been edited for it.

## What already exists

Grepped from the band prop configs, so this is what a round-8 lane would be extending, not inventing:

| site | authored cluster(s) | band file |
|---|---|---|
| relay camp (`05-relay-camp`) | `relay_approach_checkpoint`, `relay_station` | `band3_the_river_lock/props.json` |
| ridge camp (`08-ridge-camp`) | `ridge_patrol_camp`, `ridge_road_picket`, `highfield_stockcamp` | `band4_upper_meadows_ironwood/props.json` |
| waystop (`09-waystop`) | `the_waystop` | `band5_stronghold_approach/props.json` |

Round 1 already touched all three lightly: band3 gained a second camp seat and a `camp_tent`; band4
gained firewood plus a `rest` block with a `creature_bed` it never had; band5 gained a log, tent, barrel
and crate. Those are additions to a thin base, not a composed camp.

**None of these three sites has been re-rendered since round 1.** Their last frames are in `00-before/`
and `round1/`. Any round-8 work needs fresh before-frames first — the current state is unknown, and this
report has twice caught judgements made against frames that did not match the code.

## The bar, from the dispatch

> a fire focal point, seating, supplies, authored irregular clustering and a visible reason the camp exists

Read against the owner's standing constraints, which pull the other way and win where they conflict:
"do not overfill with props", "every object should look intentionally placed", installed assets only,
no new meshes.

## Per camp: the reason it exists, which is the part that is missing

Composition is the easy half. The dispatch's "visible reason the camp exists" is the half these three
sites actually fail, and it differs per camp:

1. **Relay camp** — a Team Tether picket watching the relay approach. The reason should read as
   *surveillance of the road*: the fire faces the road, seating faces outward not inward, and the supply
   pile is packed for a stay, not a night. It already has a checkpoint barricade grammar
   (`relay_approach_checkpoint`) to extend.
2. **Ridge camp** — `ridge_patrol_camp` is the Upper Meadows' only authored camp, and round 1 gave it a
   `creature_bed`. The reason should read as *rest on a long patrol*: the bed and the fire are the
   subject, the supplies secondary. This is the one camp where the player's own creatures matter to the
   read.
3. **The waystop** — a travellers' halt on the stronghold approach, the last rest before the Hall. The
   reason should read as *shelter before something dangerous*: it faces the Hall, and it should feel
   used by people who did not want to camp in the open.

## Proposed method, in the order that has actually worked in rounds 1-7

1. **Before-frames first** (`05-relay-camp`, `08-ridge-camp`, `09-waystop`, day and night where the
   capture tool marks them), because their state is unknown.
2. **Fire focal point.** Reuse `campfire_glow.gd` (`EMBER_HEIGHT`/`LIGHT_HEIGHT`/`SMOKE_TOP_HEIGHT` and
   the counter-scale rule) — the chapter's own solved warm-light recipe, already used at every camp and
   at Grandpa's door. Do not author a new light system.
3. **Irregular clustering.** The failure mode in rounds 1-6 was even spacing reading as procedural. The
   lesson that finally worked at the Warrens was *fewer, larger, deliberately asymmetric* — two touching
   pieces and one unpaired, not a ring. Apply the same rule here.
4. **Seating and supplies** from installed props (`tree-log`, `Bench`, `Crate_Wooden`, `Barrel`, `Bag`,
   `Bucket_Wooden`, whetstone/axe), placed as *someone put them down*, not distributed.
5. **Grass suppression** under the camp floor via the `CLEAR_RADIUS_META`/apron mechanism, so camps sit
   in the ground rather than on the lawn — the same fix that moved the Warrens.
6. **Guard:** `smoke_authored_camps.gd` owns these sites and must stay green; a prop that blocks a path,
   a rest point or a spawn is a defect to fix by moving the prop.

## Budget estimate

Roughly 10-14 new objects per camp, which is within "do not overfill" for three sites that currently
read as sparse. Cheap in draw calls (props, no new lights beyond the three fires) and far from the Hall,
so `hall_approach` is unaffected.

## One flag for the coordinator

Round 1's frames for these three sites are 1280x720 full-settle; every round since has used `VP_FAST`
960x540. A round-8 before/after pair must be captured at the same settings as each other — the
resolution mismatch has already caused one false "nothing changed" verdict (round-2 addendum).
