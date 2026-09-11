# Takeover checkpoint 01 — ROAD measurement correction

Date: 2026-09-10
Base: `5269a6d1c` (`main`, PR117 integrated)
Branch: `codex/four-biome-continuation-0910`
Status: **focused green; aligned earned runtime evidence still required**

## Retained change

The continuous fresh-save observer now separates three different facts that the
prior 154 MB record had conflated:

- what the live camera actually sees;
- the player's net travel heading over the actual approximately 10 m sample leg;
- the nearest authored route tangent, oriented in the direction of travel.

Every sample retains the original camera-frustum, projected-size and centre-ray
telemetry. `below_two_samples` is now narrower: it grades only a sample within
5 m of an authored route when camera-forward, travel heading and oriented route
tangent all have dot products strictly above 0.9. Off-route, unusable-heading and
unaligned samples have separate counters and remain evidence rather than false
ROAD failures. Per-body travel-forward and route-forward size-candidate counts
are also recorded; they do not pretend to be rendered-silhouette proof.

The canonical continuous driver turns the real Meadows camera with the ordinary
`look_left` / `look_right` actions after the earned tournament. It never assigns
a camera transform and releases its action during modal ownership, trainer or
wild combat, pauses, stationary frames, scene boundaries and non-Meadows play.
Production free-orbit camera behavior is unchanged.

No creature was added, moved or recolored. The five-creature rule and existing
asset restrictions remain intact. No authored gap is claimed until a fresh
aligned-camera run produces it.

## Validation

Using the repository-pinned Godot 4.7 console binary:

- `test_four_biome_road_coverage_observer.gd`: 7 tests, 54 assertions, green;
- `test_meadows_earned_warrens_segment.gd`: 8 tests, 82 assertions, green;
- `test_realm_transition.gd`: 16 tests, 95 assertions, green;
- parse-only checks for `smoke_four_biome_continuous.gd` and
  `smoke_net_split_realms.gd`: green;
- `git diff --check`: green.

The unsharded full unit run completed 3,286 tests / 3,847,277 assertions with
two failures outside this diff, each reproduced in isolation:

- `test_gate_f_harness_predicates.gd` rejects the existing S04/S05 route-row
  thresholds (420 vs a 363-row shortest run and 970 vs 500);
- `test_gate_f_rig.gd` cannot launch `bash tools/gate_f/run_segment.sh` from
  this Windows Godot process, so its lane-declaration fixture is not written.

Those are baseline harness-policy/environment exceptions, not a full-suite
green claim. Neither failing test nor its inputs are changed in this checkpoint.

An aligned earned road run has not yet completed, so this checkpoint validates
the measurement seam, not road population coverage.

## Quarry reproduction and withdrawal

The retained pre-failure save was copied before every replay; its source was not
mutated. The first quarry failure is a real authored contact, not an embedded
target: the `Foundation_0` wall face is at world Z `-1.825` in foundation-local
space, while the player capsule surface stopped at `-1.824403`, a gap of about
`0.000597 m`. The driver then travelled about `80.28 m` over `24.8 s` inside a
small rectangle without advancing to the rootstone beyond the wall.

A confinement reset and then a local AStar collider-grid detour each failed the
copied-save replay gate at adjacent quarry contacts. Both candidates and their
tests were withdrawn completely. The next attempt should use fresh contact-guided
wall-following evidence rather than another clearance/grid guess.

## Departure-sync finding

The stale `Trainer_*/Sync` / cached-node errors belong to the later **host**
Meadows-to-Cloudreach crossing, not the earlier client departure. The host updates
membership before its scene swap, but the old authoritative Meadows root is then
destroyed before a replacement simulation shell can own the same replicated node
paths for the client who stayed behind.

A proposed source-pin unit test was intentionally not retained: `pins_realm()` is
not consumed by the shell lifecycle, so making that assertion green alone would
not repair the receiver-generation handoff. This remains open and requires a
coherent host-side protocol plus a clean two-process log-suffix smoke.

## Next evidence gate

Run the corrected continuous observer far enough to produce aligned Meadows road
samples. Map only remaining graded below-two intervals to authored clusters and
exclusions before considering spawn edits. In parallel, continue the next
contact-guided quarry diagnosis and design the host receiver-generation handoff.
