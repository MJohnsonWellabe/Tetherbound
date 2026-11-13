# THINGS-WARDENRING: fainter boundary ring in the Warden's arena (F38#28 Medium close-out)

**Row.** F38#28 Warden arena boundary: High 7.54 (meets the bar), Medium 6.99. `G-f38-medium.md`, 3/3 at Medium: "the thin cyan floor arc still reads as a guide line under the creatures". At High the same arc was marked FIXED; Medium shows it more strongly.

**Change** (flag flip only): `combat.json arena.boundary_per_trainer_candidate` ON. It already exists on main, off and never GPU-judged: in the Warden's fight only, the boundary ring goes from 0.3 to 0.12 alpha and from 0.8 m to 0.45 m tall. Every other fight and every rule (radius, staging) is unchanged; `tests/test_combat_arena_boundary_candidate.gd` covers it.

**CPU** (`_sheet_warden_ring_cpu.jpg`; left main, right arm, frames 01 and 04): no script errors and the fight plays the same. **The arc itself is not visible on CPU on either side**, so the sheet shows no difference; this needs the GPU at Medium.

**Also named at Medium, not in this arm.**
- The frame-3 dust burst, "a ring of flat, white, blobby billboard puffs over Terrapup" (3/3). `THINGS-DUSTTRAIL` changes the trail, not this burst.
- A red banner on the arena wall (3/3 flagged against the oxblood reserve). The Warden is Team Tether, so I read the banner as allowed.

**Ask.** The F38#28 Warden fight set at Medium, base vs arm. If it reaches 7.5 the row closes (High is already there); add a High no-loss read.
