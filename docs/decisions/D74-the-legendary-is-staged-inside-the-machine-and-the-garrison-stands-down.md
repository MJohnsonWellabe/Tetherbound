# D74 — The legendary is staged inside the machine, and the Hall's garrison stands down

**Date:** 2026-09-04 · **Decided by:** lane W06-FINALE-0904, implementing owner
playtest OP-0904-8 and closure items CL-O8 / CL-G5 / CL-W7. Small calls recorded
here rather than asked.

## What was decided

1. **The bound legendary stands inside the Tether Machine's own cage void**, on the
   machine's axis, above the dais the installed mesh carries there and under its crown.
   The void is *measured* off the mesh at build time
   (`stronghold_climax.gd::_measure_cage`: the highest geometry within 1.0 m of the
   axis in the lower half is the dais, the lowest geometry within 1.0 m above that is
   the crown), never taken from a transform or an authored metre — D49's lesson. On
   the installed mesh fitted to 15 m that is a dais at 3.13 m, a crown at 8.89 m, a
   5.76 m void; the 3.17 m creature has 2.6 m of headroom.
2. **The 24-bar floor ring is gone.** It was the "ring outside the machine" the owner
   reported. What says "held" now is two tight restraint rings on the body, sized from
   the species' own gameplay radius and height, plus the machine's cold light. The
   node keeps its `ContainmentVFX` name, so every reload test's "freed means no cage"
   assertion is unchanged.
3. **The freeing moves the creature out.** On the lever it steps down off the dais and
   across the floor to R8.2's `legendary_stand` mark (2.4 s, two legs so it never
   slides through the base), turns to the player, and on the join offer crosses to
   within 2.6 m of them. A save loaded inside the freed-but-unsettled window stands it
   at the mark directly. `legendary_stand` therefore now means *where the freed
   creature stands*, not where the bound one does.
4. **The garrison withdrawal lives in `stronghold_occupation.gd`, driven from the
   climax.** CL-G5 named `stronghold_occupation.gd`, but that file's `build()` has been
   dead since T1-HALL-REBUILD retired `landmark.gd`'s castle; the garrison the player
   sees is `stronghold.gd::_build_occupation()`'s, with the same node vocabulary. This
   lane may not touch `stronghold.gd`, so the occupation file gained
   `watch_withdrawal(root)` — poll `progression.revision` for `legendary_freed`, then
   once hide the sentries and the camp and darken every light, flame and emissive
   surface under the braziers, sconces, lamps and relay hub — and
   `stronghold_climax.gd` hangs one of those watchers off the Stronghold node at build,
   which is also what makes it fire on a load that already carries the flag. The
   lists are data (`stronghold_occupation.json` → `withdrawal`).
5. **Darkening is immediate, not faded.** The player is inside the chamber when the
   flag lands and sees the exterior only on the walk out; a tween would fight the two
   per-frame flicker loops that rewrite light energy. Lights are hidden, not zeroed,
   for the same reason.
6. **The endgame dialogue budget is a test** (`tests/test_stronghold_dialogue_budget.gd`,
   on the merged table): no line over 110 characters, the Warden's challenge under 350,
   the file under 2,000, with §33's beats asserted alongside so a cut cannot flatten
   him. Readout, duty board and chamber narration keep the player's portrait: they are
   what the player reads and sees, and the 2026-09-04 portrait contract gives no other
   first-person face. The Warden's lines point at `warden.png`, which another lane
   produces; until it lands, `tests/test_dialogue_runner.gd`'s portrait-on-disk
   assertion is red for those two conversations by design.

## Why

OP-0904-8 is an owner reproduction and outranks the previous staging. Prompt 69 asks
for the reveal to read "the creature *is* the power source" and for the freeing to be
"physically and emotionally legible"; a creature inside the thing draining it, walking
out of it, is that in one image rather than four paragraphs. CL-G5's A11 ("the world
looked changed because of what I did") is only true at the Hall if the Hall changes.

## What this does not change

`stronghold.gd`, `meadow_healing.gd`, `rift_collapse.gd` and every other dialogue
file are untouched. No mesh is new, no generation was spent, nothing shrinks.
