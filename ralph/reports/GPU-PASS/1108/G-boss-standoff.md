# G-boss-standoff: large-foe standoff (F41#3, F41#6, F41#21): NOT JUDGED, functional blocker

Frames: `tb/gpu-frames-1108` 7a89eccc, High.
- **Live and live2:** main 90886c306.
- **Arm and arm2:** live plus `contact_spacing.gd`, `combat_manager.gd` and `combat.json` at tb/item-boss-standoff ddedeefe0, plus `overlay_large_foe_standoff.json` (min_extent_m 2.5, extra_clearance_m 1.2, trainer_margin_m 1.5).

## Why it was not judged
The GPU lane's capture note and missing_reason show the arm breaks the fight. In both arm runs:
- the Voltarach held 11.3–12.7 m from the ally for the whole 18 s capture;
- it never started an attack (`tells: []` on arm and arm2);
- so the tell1 start and impact frames for F41#3 and F41#6 do not exist on the arm side.

A boss that never attacks fails COMBAT before any look score matters, so this arm can't ship whatever the judges say. I held three judges back to save usage. What is left to judge:
- **F41#3:** one i01 frame per run, and the camera splits by side, 2 of 2 arm against 0 of 2 live.
- **F41#21:** a post-win frame that fight spacing doesn't touch.

Judging those would not give a real verdict on the arm.

## Probable cause (read-only, tb/item-boss-standoff head 0b358e4b)
1. `contact_spacing.gd` `config_for_pair()` gives any pair with a large foe a `render_box` footprint and raises `visible_clearance_m` from 0.6 to 1.8.
2. `min_separation()` is `extent_a + extent_b + clearance`, clamped to `max_separation_m` (12.0). With Voltarach's render box (leg span), that sum reaches the 12 m cap.
3. `pair_need()` feeds the opponent's `preferred_range` floor (`wild_creature.gd:1367`), so Voltarach walks to about 12 m. The 11.3–12.7 m hold matches the cap.
4. From there it never enters the start range of any move, so it never attacks.

## What would fix it (for the lane)
- **Apply the standoff to the ally only.** Keep the ally and trainer outside the leg span (the ally's own spacing, the trainer margin), but leave the foe's `preferred_range` and `pair_reach_need` on the live numbers so the boss still closes to attack.
- **Or cap the large-foe floor below the boss's shortest attack reach.**

Re-capture after the fix and confirm that tells fire on both arm runs before the section is queued for judging.

## Verdict
**VOID / DO NOT SHIP.** Functional blocker: with the arm, the boss never attacks.
