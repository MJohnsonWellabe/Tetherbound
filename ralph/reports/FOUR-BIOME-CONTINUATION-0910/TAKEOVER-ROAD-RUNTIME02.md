# Takeover checkpoint 02 — earned ROAD trace and wild retention

Date: 2026-09-10
Source: `491a10508b3c12e6cef38d16c44787cde91a865d`
Branch: `codex/four-biome-continuation-0910`
Status: **runtime defect repaired and focused green; bridge/campaign still open**

## Earned run result

The first run with the corrected, real-input camera alignment used an isolated
profile and the canonical continuous driver with `--through-bridge`. It earned:

- the live Bramblebun starter and all five party creatures;
- the gate/tool sequence and exact 19 wood / 20 fiber / 8 stone route;
- ten live training wins, including the depleted-stock pilot path;
- paid camp and all-five rest through day six;
- the three tournament rounds (22, 19 and 50 landed attacks);
- the real `south_bridge_grunt` admission at depth `-11.5743408203125`.

The earned party then lost the actual South Bridge guardian. The driver exited 1
with `campaign_complete=false`, `reached=tournament_won` and
`requested_prefix_passed=false`. This is an honest failed bridge attempt, not a
bridge-prefix or campaign pass.

Receipt root:
`.artifacts/four-biome-continuation-0910/runs/aligned-through-bridge-first/`

## Corrected road evidence

The record contains 352 total samples and 3,716.177 m of observed travel. All
216 graded samples belong to the controlled post-tournament road leg; no earlier
camera state was misclassified as ROAD evidence. Camera-to-travel alignment was
effectively exact throughout that leg. The summary reports:

- 216 graded samples;
- 96 graded below-two samples;
- 121 off-route, 14 unaligned and 1 unusable-heading samples, held separately;
- 1 undersampled interval;
- no observer contract failure.

The 96 failures form 27 contiguous intervals, all on
`band1_lower_meadows`. Body-level inspection does **not** support a blanket spawn
rewrite. Most sustained intervals had several route-forward, size-qualified
bodies, but those bodies were outside the actual camera frustum or occluded by
Terrain3D. The short arc 225–236 interval had no 15 px candidate; its nearest
next clusters were roughly 99–156 m away after the earned training route had
already depleted nearby live stock. That is valid depletion-path evidence, but
not enough on its own to add or move a cluster before the runtime corruption
below is removed from a fresh comparison.

## Runtime defect found and repaired

The trace also recorded orders 1052 and 1053's night Duskhush at Y values from
about -301,514 m to -435,563 m. Those bodies were still counted by route-oriented
2D diagnostics even though they had fallen irrecoverably below the world.

Cause: STREAM-D called `_reground_if_fallen()` only while changing a cluster
from inactive to active. Terrain3D collision tiles arrive asynchronously around
the camera. If an active body missed the floor on a later physics frame, the
cluster remained active and therefore never crossed the only code path that
could restore it.

Repair: nearby active clusters now reuse the existing guarded reground path once
per second. The check remains cluster-scaled and never operates on the distant
population. `_set_wild_active()` continues to protect active fights, faint and
respawn timers, and closed spawn gates. No creature identity, roll, authored
home, spawn count or spawn position changes.

## Validation

Using the repository-pinned Godot 4.7 console binary:

- `tests/smoke_wild_streaming.gd`: green, including an already-active delayed
  fall injected 44 m below analytic ground;
- `tests/smoke_night_ecology.gd`: exit 0 in the real Meadows Terrain3D scene,
  all 12 night bodies grounded, 12/12 hidden by day and present after dark, and
  the live Duskhush engage offer reached;
- `test_four_biome_road_coverage_observer.gd`: 7 tests / 54 assertions green;
- `git diff --check`: green at checkpoint preparation.

An accidentally misspelled test-runner filter began the known full suite and
was stopped rather than represented as validation; the correctly filtered ROAD
run above is the only unit result claimed here.

## Next gate

Commit this isolated retention repair, then resume the retained quarry replay
with contact-guided wall following. A later fresh earned ROAD comparison should
be used to decide whether any interval remains an authored placement gap after
nearby night wildlife can no longer fall out of the scene.
