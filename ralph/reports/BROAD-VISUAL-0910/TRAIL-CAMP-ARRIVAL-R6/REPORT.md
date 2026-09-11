# Trail Camp arrival identity R6 — 2026-09-11

## Outcome

**Strict PASS.** All eight current production frames establish the same named
place from the ordinary south road through the threshold and into the rest
site. The road tunnel, signed timber threshold, installed lanterns, fire,
tent, rest kit, and separated companion silhouettes form a coherent arrival
sequence by day and night. No creature blocks the route or replaces the camp
as the subject.

## Accepted production treatment

- Adds a collisionless roadside timber threshold with two readable Trail Camp
  signs and two installed wall lanterns. Its light is local and bounded; it
  does not alter the shared Meadows lighting curve.
- Adds one tightly scoped vegetation clearing at `(339.7, 919.7)`, radius 7m,
  so the actual south-road approach exposes the threshold and first camp beat
  without broadly thinning the surrounding woodland.
- Preserves the fire, tent, rest/crafting offer, road traversal, encounter
  counts, creature scale, and authoritative scatter rules.

## Production evidence

Evidence directory: `ralph/reports/BROAD-VISUAL-0910/TRAIL-CAMP-ARRIVAL-R6/`.
`manifest.json` records `complete: true`, zero failures, eight 1280x720 frames,
production `meadows_playground.tscn`, verified live-ground camera/player
positions, explicit day/night application before freeze, and hidden HUD plus
independent `SubmersionOverlay`.

- `01`/`02`, south-road arrival (fire 35.65m): uninterrupted road tunnel to a
  complete illuminated Trail Camp threshold; no trunk or creature obstruction.
- `03`/`04`, threshold approach (fire 26.17m): broad, readable named-place
  threshold with matched day/night identity.
- `05`/`06`, clearing mouth (fire 17.15m): threshold hands off to the first
  visible fire/rest-kit beat at frame right.
- `07`/`08`, fire/tent (fire 7.43m): fire, tent, furniture, and companions read
  as one functioning rest site, with creature silhouettes separated from the
  route and primary camp forms.

## Validation and bake receipt

The accepted consolidated authoritative Meadows scatter bake completed with
fingerprint `2895914238642130`: 256 regions, 823,448 kept instances, 3,466
drained, and 29,731,541 bytes. It changed the manifest plus 254 region bins;
neither the Trail Camp clearing nor the Old Quarry deadfall anchor emitted an
anchor warning. At that canonical-input checkpoint, scatter freshness/load/
performance/batch tests were green (3 tests), fingerprint coverage was green
(5 tests / 26 assertions), and the final freshness plus Trail suite was green
(8 tests / 62 assertions). The final non-freshness Trail composition/arrival
plus Old Quarry identity bundle is also green: **10 tests / 93 assertions / 0
failed**.

After that accepted bake, the separate Highfield lane added an unstaged Band4
vegetation input. Whole-worktree freshness is therefore intentionally stale
until the next coordinated authoritative bake; this sequencing dependency is
not a Trail Camp regression and this report relies on the recorded green
canonical-bake receipt above.

## Residual shared polish

Night frames retain the broader Meadows low-fill darkness outside the installed
lantern and fire pools. The route, threshold, and camp identity remain readable,
so this is shared biome polish rather than a blocker for Trail Camp PASS.
