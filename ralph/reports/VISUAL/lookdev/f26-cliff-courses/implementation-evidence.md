# F26#3 Cloudreach cliff surface candidate

Source-only production change from `9806bef7bcd893e3b8b4856dd7f45e47f7c3f9c7`.
Exclusive lookdev author; ROOT owns independent review, engine queue and integration.
Effective permissions remain never/danger-full-access. No Godot, import, parser,
render, export, engine checks, unit suites or CI were launched.

## Observed defect and references

After clearing reference skip-worktree and restoring `docs/reference`, viewed the
actual Sky Aviary board and `palworld-04-plateau-landmark.jpg`, then archived
Cloudreach stand 01 day on High/Medium, stand 01 night on Medium, and stand 03 day
on High. Frame identities and byte hashes are in `source-evidence.json`.

The stand 01 cliff occupies much of the left view with brown, stretched grain
and weak surface structure. Stand 03 repeats that read across the cliff under
the bridge. The board separates exposed grey stone, weathered courses and mossy
shelves; the Palworld view retains readable stone planes among green vegetation.
This is an author diagnosis, not a new independent visual verdict. Archived
capture source is `f43cde88acde0648123b89895d3023e1f5c50a08`; the original
`cloudreach-visual-r1/independent-codeblind-review.txt` retains both full-bar FAILs.

## Concrete production change

- `shaders/cloudreach_rock.gdshaderinc`: reuse installed Rock030 colour/normal
  inputs with 2.78 m detail repeats, palette-owned grain, interrupted 4.8 m
  bedding, sheltered stains, shelf-oriented moss and tangent-only normal relief.
  Fade bed variation and joints as their world-space pixel footprint grows.
  The OFF path retains the previous material equations and sampling scales.
- `shaders/cloudreach_cliff.gdshader`, `shaders/cloudreach_surface.gdshader`:
  supply pixel footprint before any varying turf/rock branch, sharing the same
  geology on walls and crown banks without undefined boundary derivatives.
- `project.godot`: register three presentation shader globals with disabled
  candidate strength at project load, before either shader is built.
- `scripts/world/world_look.gd`: bind bounded art tunables when the existing
  graphics refresh runs, using the existing preset data path. Device-local
  presentation; no save, authority or gameplay mutations.
- `data/config/art.json`: material tunables and `cloudreach_rock_candidate=false`
  in Low, Medium and High. ROOT can enable the same production hook in a recorded
  capture candidate; there is no hidden harness-only shader replacement.
- `docs/design/ART_DIRECTION.md` §4.1: stone coherence/readability target and
  explicit candidate/OFF/evidence boundary. No lowered bar or RD/hard-rule change.

## Preservation and proof limits

No new assets, generations, lights, draw surfaces, placement, collider, terrain,
camera, creature scale or renderer-default edits. Both material paths retain
three colour plus three normal samples; candidate arithmetic/GPU cost is not
measured. Existing Ally and outdoor-light/draw/primitive budgets still apply.

`ignored-before.json` fingerprints all 3,202 pre-existing ignored files;
`preservation-audit.json` confirms no added, changed or missing ignored bytes.
Moves and VFX configuration bytes are unchanged. Git diff whitespace inspection
passed; data inspection confirms all candidate preset switches are false.
Shader/global binding and visual behavior have not been run or accepted.

F26#3 remains OPEN. Material-census PASS remains limited to its established
F26#0 material-presence scope; it certifies no appeal or atmosphere. The other
Cloudreach matrix defects and every other biome's full bar remain independently
open. Capture request follows after the pushed source checkpoint, at the engine
authority boundary. ROOT must record the actual integrated/candidate SHA and
independent code-blind result before enabling or claiming any visual PASS.

Balance: game 7 production files / tests-tools 0; evidence artifacts accompany
the content and do not substitute for real frames.
