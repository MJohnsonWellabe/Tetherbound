STATUS: parked
BRANCH: tb/item-f41-fight-read  HEAD: see the commit that adds this READY (pushed head)

Lane LANE-MESHY, Stormwood fight readability (coordinator 8 Nov): rim light on both fighters and an occluder fade, with no camera reframing and the magenta telegraphs left alone.

**Nothing ships ON.**

## Diagnosis (today's main 0a5ba676, CPU, capacitor_alpha and hollows_alpha, 18 x 1 s plus every tell)
- Trunk/canopy occlusion is mostly solved on main (line_of_sight_fade is live for Stormwood via enabled_realms; near_lens_fade is ON).
  - Capacitor: 0/18 interval frames and 0/14 tells occluded.
  - Hollows: 2/18 (i16, i17). A giant root covers about 35% of the frame and half-hides Sparkit.
  - The judges' "camera fully blocked" came from the old anchor build.
- The largest wash-out today is the tan dash-dust cloud: about 10/14 capacitor tells and about 14 hollows frames. It is the tell's "where" cue, so it goes to the owner's telegraph question (coordinator) and was not touched.

## Arm A (foliage_camera_visibility near_lens_hide): parked
- The hollows fight is nondeterministic: base and arm diverge from i05 (about 40% of pixels differ), and neither run reproduced this morning's i16/i17 root occlusion.
- There was nothing to fix in today's frames, so it was not judged (coordinator option a).
- Evidence: `_sheet_visibility_v1.jpg`.

## Arm B (creature rim in Stormwood): parked
- Code (on this branch, inert): Stormwood loads no realm look, so `creature_rim.gd` never reached it. I added `wanted(cfg, look, scene)` and a `realm_scenes` list in `creature_rim.json` (shipped empty), and `world_look.gd` now passes its world scene. `tests/test_creature_rim.gd` has a new case: 14 tests, 0 failed.
- Round `qj/F41-FR-b-matched/`:
  - Arm: rim only (`overlay_b.json`, realm_scenes = stormwood.tscn).
  - Frames: the 11 moments where base and arm match (i00-i04 plus tell1 a-f, at most 3.1% of pixels differ). The recorded defect was reworded so it does not name the change.
  - Result: mapped **6.33 -> 6.33 (+0.00)**. Raw 5.6 / 5.4 / 5.6 -> 5.7 / 5.4 / 5.5; only 1 of 3 prefers the arm.
  - Two judges call the rimmed boss more blown out ("pushes it towards blown-out", "B's enemy is slightly more blown out"), which is the coordinator's stop condition.
- Why: Voltarach is already pale lavender and cream, so a cool fresnel edge whitens it further instead of separating it. The rim would only help dark creatures.

## Judges' asks (all three)
- Stormwood storm grade in fights: purple sky, bark-toned rather than mauve trunks, less lime moss.
- Cut the beige bokeh dash dust (owner telegraph question).
- Voltarach in Hollows reads off its roster board (pale armadillo, not the dark gold-legged spider). The capacitor stand's Voltarach matches the board; worth checking whether Hollows uses a different look or variant.

**Next idea:** a per-species rim allowance (rim only on creatures darker than a value threshold), or a darker underside value on Voltarach, before any rim returns. The storm grade in fights is a bigger lever than the rim.

## Files
- `scripts/world/creature_rim.gd`
- `scripts/world/world_look.gd`
- `data/config/creature_rim.json` (inert)
- `tests/test_creature_rim.gd`
- `ralph/reports/LANES/ITEM-F41-FIGHT-READ/**`

These need not land; nothing behaves differently.
