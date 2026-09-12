# Full-game exit handoff — 2026-09-11

This is the stopping-point document for the September 11 visual run. The owner's
next-session direction is explicit: continue moving every named destination toward
**PASS**, starting with the remaining Meadows POLISH locations and the Cloudreach
FAIL locations, while improving terrain and environmental presentation across all
four biomes. Cloudreach specifically needs a new terrain/wear treatment and real
clustered cloud banks instead of the current flat cloud blobs.

This handoff is intentionally conservative. A location changes grade only after a
valid production capture and independent visual review. Code-only changes, static
fixtures, tests, and author self-review are useful preparation but do not promote a
ledger row by themselves.

## Owner's target

Build Tetherbound into a complete, stable, commercially coherent four-biome game:

- a continuous Meadows -> Cloudreach -> Stormwood -> Water campaign;
- satisfying traversal, combat, catching, riding, gathering, crafting, quests,
  settlements, named destinations, bosses and chapter transitions;
- readable creatures, evolutions, starters, characters and environment art at
  normal gameplay scale;
- safe single-player and multiplayer state, saving and recovery;
- a packaged build that performs acceptably on the owner's target hardware; and
- every biome supported by honest route-scale evidence, not isolated beauty shots.

The immediate visual milestone is not a percentage. It is an auditable ledger in
which every named destination is first at least POLISH and then independently PASS.

## Truthful named-location ledger at shutdown

| Biome | PASS | POLISH | FAIL | Unknown/invalid | Total | Next milestone |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Meadows | 12 | 11 | 0 | 0 | 23 | Promote the remaining 11 with valid production captures and independent reviews. |
| Cloudreach | 0 | 10 | 2 | 0 | 12 | Stormward Overlook and Summit Eyrie remain FAIL after blind review; repair them to POLISH. |
| Stormwood | 0 | 5 | 6 | 1 invalid | 12 | Make Crown Arch capturable, then lift every FAIL to POLISH. |
| Water | 0 | 2 | 0 | 22 unknown | 24 | Complete the named-destination survey before claiming readiness. |

### Meadows POLISH queue

The Inn, The Old Quarry, The Stonewater Reach, The Long Water, Old Mill Crossing,
The Ironwood Grove, The Highfield, The Rise, The Ridgeline Watch, The Broken Tower,
and Stronghold Approach.

Recent work does not yet change those grades:

- Ironwood R20 is a major identity improvement and is retained, but remains POLISH.
  The lightning network still reads trunk-heavy; cyan crown flecks, the trapped
  source, night exposure and the detached workyard remain open.
- Old Quarry R5B remains POLISH because its boulders do not yet read as a convincing
  terraced excavated face.
- Broken Tower R3 remains POLISH because the black plane and rectangular slab
  terminations still read procedurally.
- The Rise R2 remains POLISH. An R3 composition candidate exists only as local,
  uncommitted work in the original worktree and must be revalidated before use.
- Inn R10, Stonewater R5 and Highfield R6 are code/test-ready on
  `codex/meadows-three-pass-0911` at `1fef7b28`; they were deliberately not rendered
  during shutdown and therefore earn no promotion yet.

### Cloudreach FAIL queue and shared environment work

Stormward Overlook R1 and Summit Eyrie R2 both remain FAIL under independent review.
Do not carry forward earlier author-rated POLISH claims. The smallest credible work
is structural and compositional, not another prop-density tweak:

1. Stormward: replace the white rectangular arch plane and unsupported facade slab
   with grounded piers, arch depth and a readable Stormwood vista; use a normal
   third-person threshold camera and preserve player readability at night.
2. Summit: ground or remove floating slab silhouettes, retire the malformed salmon
   proxy, keep the player fully in frame, stop grass piercing the paving, and add a
   deliberate court/arrival light hierarchy.

Cloudreach's broad terrain problem has four already-diagnosed mechanisms:

1. Replace turf-painted trail and settlement overlays with true coverage masks so
   the underlying crown shows through, and build continuous route ribbons with
   proper joins and endpoint fades.
2. Replace 760 independent flattened cloud spheres with roughly 80–120 deterministic
   multi-lobe cloud banks using height tiers, shaded bases and night-aware exposure.
   Preserve the safety-owned CloudSea height and recovery contract.
3. Break the exact repeating cliff-strata cadence with low-frequency spatial
   variation; if that is insufficient, add a few authored cliff silhouettes without
   changing walkable crowns or region bounds.
4. Rebuild grass into low, medium and sparse-tall roles with width proportional to
   height. Do not resume the exhausted tip/arc/count tuning rounds.

The prepared Cloudreach work from `codex/cloudreach-final-fails-0911` at
`86c40409a` is included in the shutdown integration. Its focused tests were green,
but the latest production reviews still grade the two target locations FAIL. Treat
that code as a starting implementation, not a completed promotion.

### Stormwood survey truth

The latest recovery survey produced 8/8 valid files and 9 tests / 1,059 assertions
green, but its visual grades are **0 PASS / 5 POLISH / 6 FAIL / 1 invalid**.

- Verge Rod Station: FAIL; the pylon is too small and isolated to read as a station.
- Crown Arch: invalid; the current coordinate falls off the stable Crown platform.
- Crown Heartstone: FAIL; the focal is tiny and overwhelmed by repeated large
  creatures and flat ground.
- Fallen Giant: FAIL; the capture lacks named-landmark identity.
- Lantern Pools and Crown Overlook were already FAIL in the prior valid survey.

First correct Crown Arch's evidence coordinate. Then improve the six FAIL locations
to POLISH with biome-wide terrain/ecology changes where the same defect repeats.
Stormwood needs irregular forest-floor material, rooted vegetation, less repeated
creature crowding, readable electrical landmarks, authored route thresholds and
night values that preserve terrain and character silhouettes. Keep the Dynamo,
conduits, captive legendary, aftermath and Waterward route tied to their campaign
functions rather than treating them as disconnected set dressing.

### Water survey and terrain work

Water has 24 named destinations. Only two First Shore destinations currently have
POLISH evidence; 22 remain unknown. The next session should survey before redesign,
then batch shared fixes for repeated failures. Expected high-leverage systems are
island terrain/material variation, shoreline transitions, vegetation and reeds,
water depth/readability, dock and settlement grounding, horizon composition, night
exposure, and safe combat footing near water and ravines.

Do not infer that an unknown is POLISH. Do not spend multiple rounds on one island
before the full 24-row baseline exists.

## Cross-biome art and gameplay backlog

The next worker should retain the broad creature and character improvements, then
audit the entire shipped roster at gameplay scale, including all starters and every
evolution. Do not repeat a previous count without checking the current species data
and current captures. Pebblik's texture/paint remains an owner-reported Cloudreach
defect and needs a subject-specific review.

Owner-reported play blockers remain in scope:

- fights near water and South Ridge can place trainers or creatures underwater or
  in ravines;
- after one such invalid fight, combat buttons stopped registering;
- the player could not remount the saddled creature after entering Cloudreach; and
- the common Cloudreach creature Pebblik has weak texture and paint treatment.

Fix these at the shared system level where possible: arena/participant footing
validation, safe fallback placement, combat teardown/input recovery, and mounted
state reconstruction across realm transitions. Add focused regressions and then
prove the behavior in real play.

## Route from visual milestone to full game

### Phase 1 — finish the honest visual ledger

1. Render and independently judge the three code-ready Meadows candidates.
2. Work the remaining Meadows POLISH rows to PASS, favoring shared water, cliff,
   terrain, vegetation, prop and lighting fixes when they appear in several frames.
3. Repair Cloudreach's two FAIL rows to POLISH while implementing the shared
   wear-overlay, cloud-bank, cliff and grass mechanisms above.
4. Fix Stormwood's invalid capture, then raise all six FAIL rows to POLISH.
5. Survey all 24 Water destinations and lift every discovered FAIL to POLISH.
6. Make one cross-biome POLISH-to-PASS sweep until every named row is PASS.

Every visual submission needs production-scene day/night frames, a normal gameplay
camera with the player readable, manifest integrity, no hidden collision or route
regression, and an independent reviewer. One renderer at a time on the 8 GB machine.

### Phase 2 — make the campaign continuously playable

Run a clean save through the ordinary opening, Meadows tournament and bridge,
Cloudreach traversal and Stormward gate, Stormwood Dynamo/legendary/aftermath, Water
chapter and final roster decision. Repair the first real blocker rather than seeding
past it. Repeat in multiplayer for realm transitions, hosted encounters, rewards,
disconnect/reconnect and save ownership.

### Phase 3 — complete content and progression

Audit every named location for a reason to visit: encounters, gatherables,
consumables, trainers, quests, rewards, shortcuts, lore and visual payoff. Verify
crafting and economy pacing, creature availability/evolution, boss rewards, chapter
keys and optional loops. Eliminate dead spaces and duplicate-feeling destinations.

### Phase 4 — stability, performance and release proof

Recheck owner-hardware freezes and frame pacing, especially grass and large encounter
scenes. Exercise save/load, autosave, recovery, UI reopen, combat cancellation and
realm travel. Produce a fresh Windows package from the exact merged main SHA, launch
it beside its PCK/libraries, and run a clean packaged campaign smoke. A green CI run
is necessary but not equivalent to a finished game.

## Integration and CI discipline

- Main is PR-only. Never push directly to `main`.
- Keep batches small and single-purpose. Push once after local focused tests, inspect
  every executed CI job, and repair red checks before merging.
- Exact-stage authored files. Never commit incidental `.uid`, broad `.import`, cache,
  screenshot or generated churn. Import sidecars are committed only when they are
  the intentional VRAM-policy output for a shipped texture.
- Keep lane worktrees isolated; merge shared-file work serially.
- A ledger promotion and a code merge are separate claims. Record both explicitly.
- Never place service keys or credentials in source, reports, logs or command lines.

At shutdown start, PR #125 (`codex/visual-polish-0911-f`) contained the retained
Ironwood, Old Quarry and Broken Tower work but was red. The shutdown integration
repairs the stale scatter bake, seven non-VRAM texture sidecars, route-creature
visibility, over-budget dialogue, incorrect Gate F region assertion and split-band
fixture drift. It also includes the prepared Meadows, Cloudreach and Stormwood
commits described above. This document is part of that final PR batch. Verify that
PR #125 and its exact resulting `main` SHA completed green; if either did not, CI
recovery remains the first task and no visual work should start.

## First actions next session

1. Read `CLAUDE.md`, `docs/00_START_HERE.md`, this handoff, and then the underlying
   `docs/prompts/77-CODEX-GOAL-four-biome-push-2026-09-07.md`.
2. Verify `origin/main`, open PRs, CI and the exact landed SHAs before trusting branch
   names in this document.
3. Rebuild the authoritative four-biome ledger from committed evidence.
4. Start with the highest-leverage shared Cloudreach environment mechanism while a
   separate evidence lane renders the already-prepared Meadows candidates.
5. Maintain the owner-visible PASS/POLISH/FAIL/unknown ledger after every independent
   review and keep main green at each merge checkpoint.
