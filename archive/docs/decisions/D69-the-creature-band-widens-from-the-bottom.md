# D69 — The creature band widens from the bottom

**Status:** accepted, by the owner. **Amends D19's scale band.**
**Decided:** 2026-08-23, during the VIS-CAST visual lane.

## The decision

The owner, shown the roster photographed against the 1.80 m trainer:

> *"widen the creature band size if appropriate"*

The band moves from **1.35–2.60 m (1.93x)** to **0.60–2.60 m (4.33x)**.

Every metre of that widening comes from the **bottom**. The starters and the
whole large tier do not move.

| | D19 | **D69** | |
|---|---|---|---|
| Pipwing | 1.35 m | **0.60 m** | |
| Bramblebun | 1.50 m | **0.78 m** | |
| Mudsnout | 1.55 m | **0.95 m** | pre-evolution |
| Brooktail | 1.60 m | **1.05 m** | |
| Paddlenewt | 1.65 m | **1.15 m** | |
| Trailpup | 1.70 m | **1.28 m** | tie preserved |
| Duskhush | 1.70 m | **1.28 m** | tie preserved |
| Mosshell | 1.75 m | **1.40 m** | |
| Reedwing | 1.80 m | **1.50 m** | |
| Burrowback | 1.85 m | **1.70 m** | |
| **Galewisp** (starter) | 1.90 m | **1.90 m** | unchanged |
| **Ripplet** (starter) | 1.95 m | **1.95 m** | unchanged |
| **Terrapup** (starter) | 2.00 m | **2.00 m** | unchanged |
| Meadowhart | 2.05 m | **2.05 m** | unchanged |
| Galecrest | 2.10 m | **2.10 m** | unchanged |
| Tuskroot | 2.15 m | **2.15 m** | unchanged, evolved form |
| Veridian Stag | 2.60 m | **2.60 m** | unchanged, legendary |

## Why the bottom, and only the bottom

**Because D19 was right about the thing it was actually about.** D19 was made
after the owner played the build, and its finding was specific: *"your creature
felt small — the one you pilot in combat, the one that follows you all game."*
That is a finding about the STARTERS. Shrinking them to widen the band would
have re-broken exactly what D19 fixed, and would have read as an autonomous lane
overturning owner-play evidence on aesthetic grounds.

The complaint D69 answers is a different one, and both can be true at once:
there was no small tier. Measured off `tools/_capture_creature_roster.gd` with
the trainer in every frame, **ten of seventeen creatures stood at or above the
player's height**, the smallest creature in the game was a metre-and-a-third
songbird chick, and a domestic waterbird stood eye to eye with the player. Three
independent blind rounds named it; the last put it in its top three gaps against
the Palworld bar, whose roster *"spans knee-high to house-sized"*.

Widening downward answers that without touching the piloted creatures. Seven
species now stand at or above the trainer instead of ten, and those seven are
the three starters plus the four the roster is meant to be impressed by.

## What is preserved

**D13's relative ordering, exactly.** This is the promise D19 itself named as
the thing worth keeping when the absolute band moves, and D69 keeps it
bit-for-bit — including the ties D19 deliberately preserved. Trailpup and
Duskhush still tie in the middle. Pipwing and Bramblebun are still the smallest
pair. Meadowhart, Galecrest and Tuskroot are still the largest wild tier.

**D17.** Mudsnout 0.95 m → Tuskroot 2.15 m is still strictly increasing, and
now by a great deal more: the line more than doubles in height where it used to
gain 39%. `tests/test_evolution_links.gd` passes without amendment. Pulling the
pre-evolution down without moving the evolved form is a side benefit worth
stating — an evolution that doubles in size looks like an evolution.

**D12's radius rule.** Every radius is scaled by the *same* ratio as its own
height, so the height:radius ratio is unchanged for every species. Three things
follow from that and none of them needed separate handling: attack reach and the
catch formula's accuracy bonus both derive from `body_radius()` and scale with
it exactly as they did under D12 and D19; and `creature_body._fit()`'s footprint
allowance sees an unchanged ratio, so no model re-fits differently and
`tests/smoke_art.gd`'s rendered-height check is unaffected.

**No model is rebuilt.** Height is one number per species, applied at load, the
same as every previous rescale.

## What this does NOT change

- **The starters.** 1.90–2.00 m, exactly where D19 put them, for D19's reasons.
- **The legendary's headroom.** The Veridian Stag stays 2.60 m and its lead over
  the largest wild creature stays 0.45 m. D19 flagged that margin as something to
  watch; D69 neither helps nor hurts it.
- **The reference sheets.** Their centimetre figures remain the creature's
  biology, not its game scale — D12's carve-out, unchanged.

## The combat implication — flagged, tunable, not solved here

D19 flagged that peer-sized fighters may crowd the 11 m arena and that the
piloted camera frames more body than ground. D69 **helps** that for every fight
against a small wild creature and changes nothing for the starters, so the watch
item is narrower than it was but is not closed. `data/config/combat.json`'s
arena radius and `camera` block remain the dials, both already labelled tunable.

What D69 does introduce is the opposite question, which the next play gate should
answer: a 0.60 m Pipwing is now genuinely small on screen, and whether a fight
against something that size reads well — whether it is findable in grass, whether
the camera holds it — is a playtest finding and not a still-frame one.
