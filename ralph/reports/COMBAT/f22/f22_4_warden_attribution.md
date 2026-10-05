# F22#4 Warden C3 single-hit attribution

Run: `smoke_meadows_named_c2c3 --case=warden`, 12 seeds per starter and pilot.
The switching reader is used for READER rows. Each run records its worst
incoming hit (foe, move, target, type multiplier) through
`combat_depth_pilot.gd` `max_hit_by`.

| Starter | Masher max hit | Verdict |
|---|---|---|
| terrapup | 0.502 | FAIL (≥0.50) |
| ripplet | 0.510 | FAIL (≥0.50) |
| galewisp | 0.495 | PASS |

Readers win every run. Lead-faint rates for the switching reader:

| Starter | Lead-faint |
|---|---|
| terrapup | 0.08 |
| ripplet | 0.00 |

The worst hits in all three starters' masher runs are the same blow every
time: the Warden's **tuskroot `earth_fist` into the retained pipwing**, with a
type multiplier of **1.25**. Hit sizes: 0.510, 0.502, 0.500, 0.499, 0.497,
0.495, 0.492, 0.472.

This is a super-effective matchup, not a neutral one. Plan (a) trims a
member's authored power only for a neutral-matchup overshoot, so no
data change was made. The overshoot is 0.2–2% above the bar, and it comes
from the fixture leaving a weak-to-earth retained creature in the line of a
charging blow.

## Coordinator ruling (2026-10-05)

COMBAT.md:144 sets the bar: "No single hit removes ≥50% of an uninjured,
full-health, entry-level **neutral-matchup** creature. Test the worst allowed
variance and legal type/TM modifiers, not the mean."

A super-effective `earth_fist` into Pipwing (×1.25) is outside that bar.
Type advantage is meant to hurt, and that is the switching value F24 now owns.
Tuskroot is therefore not trimmed.

The smoke's C3 gate was brought into line with the spec in its own commit:

- **Gated value.** Each landed blow is re-derived from the inputs the
  manager rolled it from: the foe's `power`, its effective attack, the
  struck creature's entry effective defence and the move power. It is
  re-rolled at the top of the ±10% variance band with type ×1.0, as a
  fraction of that creature's entry HP (`combat_depth_pilot.gd`,
  `neutral_worst_frac`).
- **Reported value.** The worst observed hit in any matchup is still printed
  with its attribution (`MEADOWS_C2C3_HITS`), but it no longer gates.
- **Real failure.** Any neutral worst-variance hit ≥0.50 is a real failure
  and gets tuned.

## Re-run under the aligned gate

Run: `smoke_meadows_named_c2c3 --case=warden`, 2 seeds.

| Starter | Pilot | Neutral worst-variance (gated) | Worst in any matchup (reported) | Verdict |
|---|---|---|---|---|
| terrapup | masher | 0.409 (tuskroot `earth_fist` → pipwing) | 0.499 (same blow, ×1.25) | PASS |
| terrapup | reader | 0.165 (burrowback `rock_throw`) | 0.164 | PASS |
| ripplet | masher | 0.409 (tuskroot `earth_fist` → pipwing) | 0.492 (×1.25) | PASS |
| ripplet | reader | 0.190 (burrowback `rock_throw`) | 0.149 | PASS |
| galewisp | masher | 0.409 (tuskroot `earth_fist` → pipwing) | 0.452 (×1.25) | PASS |
| galewisp | reader | 0.250 (brooktail `aqua_shot`) | 0.173 | PASS |

The neutral worst-variance value for the tuskroot blow is 0.409. Multiplied
by the 1.25 type multiplier, that gives 0.511. This matches the worst
super-effective hit the 12-seed attribution run measured (0.510), so the
re-derivation agrees with the live roll.
