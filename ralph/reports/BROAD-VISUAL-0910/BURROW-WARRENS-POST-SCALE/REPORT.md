# The Burrow Warrens — post-creature-scale composition

Status: **PASS** (strict named-location review; approved interior night exposure
remains shared polish, not a Warrens blocker).

Binding scope: `docs/VISUAL_BIBLE.md` says the Warrens interior is approved and
must never be touched. This pass changes no interior environment, material,
geometry, lighting, route, spawn count, progression, reward, or combat tuning.

## Current evidence audit

- Fresh catalogue arrival day/night (`shots/catalogue/meadows/arrival-sightline-0910/`)
  already gives the exterior a strong named-place read: complete mound, root-brow
  mouth, trodden approach, road, trainer ruler, and clear silhouette.
- Fresh `shots/locations/04-warrens-approach-day.png` remains commercially strong.
- The revised `04-warrens-standing-day.png` proves the historical full-frame
  rock clip is already fixed: player and camera are seated on the open apron.
- `04-warrens-den-day.png` appeared to carry the current defect: a Burrowback
  was a cropped foreground wall and the approved den composition was largely
  lost. The first dedicated manifest later proved the guardian itself remained
  22.30m from the hall marker. The cropped body was the mandatory hall resident,
  because that proof teleported into a room whose required fight was still live.

## Root cause and bounded fix

The global roster scale pass grew ordinary Burrowback from 1.70m to 2.95m, but
`burrow_warrens.json` retained the guardian's historical 2.1x instance
multiplier. Because `apply_size_multiplier()` scales art, capsule, reach and
catch dimensions together, the live guardian became 6.195m tall inside its
7.0m den rather than the intended ~3.57m.

The multiplier is retuned to 1.35: 3.9825m tall, still 2.21x the fixed trainer
and 35% larger than ordinary Burrowback. Its 2.886m diameter and 3.983m height
fit the authored 3.2 x 4.4m hall-to-den threshold with 0.314m lateral and 0.418m
vertical clearance. Alpha colourway, glow, bearing, combat, level and encounter
position are unchanged.

Static PowerShell parse receipt: JSON clean; base 2.95m, multiplier 1.35,
guardian 3.9825m, diameter 2.8861m, den 7.0m, passage 3.2 x 4.4m.
`git diff --check`: clean.

## First production proof — rejected for state, not art

The first five-frame production run exited 0, but is held rather than used as a
visual receipt. `01-arrival-day/night` retained the strong exterior. The live
mouth resident accumulated AI time between day and night and crowded
`02-threshold-night`. More importantly, `03-den-arrival-day` left the mandatory
hall resident alive while placing the player at its chamber marker; that body,
not the guardian, filled frame right. The manifest's measured 22.30m guardian
distance is the decisive diagnosis.

The revised harness now uses existing lifecycle operations rather than deleting
art or encounters: each exterior comparison resets living residents through
`revive_at_home()`, and the den frame applies `take_damage()` ->
`notify_fainted()` -> `clear_faint()` only to the mandatory mouth/hall residents
a player must already have beaten to reach the hall-to-den threshold. The
guardian and optional branch resident remain live. This staging is disclosed in
the manifest and sets no clear/reward/progression flag. Corrected visual proof is
queued after the current authoritative bake.

The first corrected earned-sequence rerun wrote 5/5 frames and proved the den
fix, but remains held: its manifest exposed the first arrival player at
`y=-12.935` against `y=4.355` at the identical night XZ. The capture had seated
the player before the remote production collision stream followed the evidence
camera. The harness now moves/settles the camera first, samples the same live
ground helper for both times, seats the player second, records surface and
player-ground delta, and hard-fails a day/night surface mismatch or an absolute
ground delta over 0.75m. Resident reset also occurs after that camera-only
settle; previously the mandatory mouth resident spent the settle interval
advancing toward the previous player pose and replaced the tunnel composition.
This timing correction uses its existing authored home and lifecycle; no actor,
interior art, environment, or encounter data moves.

## Accepted production proof

The single authorized rerun wrote all five 1280x720 production frames and a
`complete: true` manifest with no failures. Arrival day/night sampled the exact
same live surface (`y=4.353477m`) and retained player offsets of only 0.00084m
and 0.00104m; threshold offsets were 0.00277m in both frames. Full-resolution
review accepts the mound/road silhouette, unobstructed day/night arrival, and
threshold tunnel read. Post-settle home reset keeps the required mouth resident
left of the opening rather than letting elapsed proof time turn it into a crop.

The disclosed earned den frame clears only `Warrens_mudsnout_1` at the mouth and
`Warrens_burrowback_1` in the hall. The guardian stays live 22.30m away at
3.9825m tall and reads through the open passage without filling the frame.
Independent review accepted this as strict PASS. The approved interior's dark
night value remains residual shared lighting polish; it does not block the
named place or this post-scale composition correction.

## Shared creature-staging candidate

The first run also exposed the common post-roster-scale defect visible at Quarry,
Trail Camp, and the Stronghold road: open-world cluster placement knew only a
constant vegetation margin, not creature body radii or earlier members, and idle
wander targets could merge the bodies again. The held shared candidate preserves
the original seeded draw and all stat RNG, then resolves only an actual overlap
with a separate order/member-derived generator. Same-cluster wander destinations
use the same sum-of-live-radii plus 1.25m tunable presentation gap. Counts,
species, cluster centres/radii, art, combat and progression are unchanged; an
infeasible authored disc retains every body at its best deterministic candidate
and emits a warning. The one deliberately infeasible shallow-water pair (Band 1
order 6) now carries a documented per-spawn opt-out because its measured 0.4m
disc is the binding depth-safety limit; the live file and tracked pre-split
fixture mirror agree. Land roadside pairs 2920 and 4914 instead widen only from
3.0m to 4.5m, preserving centre/count/sightline while giving the resolver room.

Validation on the held combined candidate:

- cluster spacing: **7 tests, 19 assertions, 0 failed**;
- shiny/stat determinism: **8 tests, 36 assertions, 0 failed**;
- spawn tables: **27 tests, 9,112 assertions, 0 failed**;
- authored spawn data: **25 tests, 1,961 assertions, 0 failed**;
- band merge: **6 tests, 1,435 assertions, 0 failed**;
- Warrens scale: **1 test, 8 assertions, 0 failed**;
- earned Warrens route: **10 tests, 1,298 assertions, 0 failed**;
- wild streaming, Warrens fixture, and full Warrens world smoke: **PASS**.

Focused spacing + band mirror + spawn validation rerun together: **38 tests,
3,415 assertions, 0 failed**. The subsequent full live Warrens world smoke
exited 0, completed the walked route/reward/second-build checks, and emitted
**zero `wild cluster` spacing warnings**. The only warnings were the unrelated
existing `Torch_Metal` glow notices. One unrelated Gate-F harness threshold test
remains red in foreign, currently modified S04/S05 helper files; it is not
attributed to this candidate.
