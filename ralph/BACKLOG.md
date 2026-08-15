# Backlog

Ordered. Work top-down. **This file is the state of the project.**

Legend — `▶` owner play checkpoint. **Gates no longer stop the loop** (owner
directive 2026-08-09, D21): the loop lists them in `BLOCKED.md`'s play-gate
section for the owner and keeps building past them. `🔒` needs Meshy credits.
`model:` the cheapest tier that can do the job. `tests:` exactly what to run.

**`model: fable` (owner directive, 2026-08-12) is not "the cheapest tier that
can do the job" — it is a hard floor.** These items are ceiling-setting
narrative or aesthetic authorship (world-building, story beats, dialogue, or
"does this actually look right" visual-direction judgment calls) where a
weaker first pass becomes the ceiling a later pass can't rescue — `R9.4`'s own
history is the proof: an uncapped multi-round critique loop against an
already-built scene still hit a wall neither critic could tune past. **Any
firing that reaches a `model: fable` item must not do the creative work in its
own session, regardless of which lane it is** — see `ralph/PROMPT.md`'s
"Fable-tagged items" section for the dispatch rule.

**Standing task, every visual milestone:** re-shoot the website's screenshots
after any milestone that changes how the game looks (this rewrite, D18/D19's
overhaul, is the precedent — the site had claimed "sourced stand-ins" months
after the roster was real). `model: haiku` when it is just screenshots.

---

## Phase -1.1 — the owner played again (owner-reported, 2026-08-12)

Fresh playtest feedback, folded in the same way `Phase 0` absorbed the first
round: spliced ahead of everything else because it's the owner's direct,
current read on the build. Two items (`OF11`, `OF12`) replace `BLOCKED.md`
entries that stopped clearing after repeated tuning rounds — see
`BLOCKED.md` for why those are redos, not continuations.

**`OF1` (catching redone as a staged performance — shake choreography, camera handoff, VFX, HUD odds/feedback) shipped — see `DONE.md`.** Converged over 3 blind-pass rounds; residual gaps are honest and out of scope (no audio pipeline in the project, the orb is still the placeholder M11 asset, and real feel needs an on-device controller playtest on the Ally).

**`OF2` (item-target picker for consumables; party reorder found already built) shipped — see `DONE.md`.**

**`OF3` (dialogue-advance guard buffer + naming-grid column fix) shipped — see `DONE.md`.** Manual controller verification still open; DONE.md says what to check if it reopens.

**`OF4` (masonry/weathering surface pass, then a full blind-verified massing rebuild across six rounds) shipped — see `DONE.md`.** What those rounds could not clear split into `OF4-remainder-mound` (below, shipped) and `BLOCKED.md`'s "OF4 silhouette ceiling" entry (design/asset question, lands with Phase 8e).

**`OF4-remainder-mound` (real scale-givers on the rise — authored scatter anchors, outcrops, a talus apron and a broken tree line on the two judged vantages) shipped — see `DONE.md`.** Three blind rounds cleared the mound from the critic's ranked worst-scale offenders, this item's own done-when.

**`OF5` (running/walking looked unnatural — gait cadence didn't match travel speed, feet ice-skated) shipped — see `DONE.md`.**

**`OF6` (world boundary collision tightened to the visible perimeter) shipped — see `DONE.md`.**

**`OF7` (perimeter fence/wall rebuilt — continuous joins, real jitter, real coursing) shipped — see `DONE.md`.** Found a real, unfixed bug while shipping it: `vegetation.json`'s `rocks` layer places boulders through the boundary ring in segment 1 — needs a `clear_radius` around the ring, not yet done.

**`OF8` (player standing on the bed instead of lying in it — a bad furniture collider plus a missing lie-down pose) shipped — see `DONE.md`.**

**`OF9` (should the stronghold be visible from the start) flagged, not silently fixed — see `BLOCKED.md`'s "Design questions awaiting the owner" for the evidence and what would close it.**

**`OF13` (hide the stronghold, move it farther from the village) shipped — see `DONE.md`.**

**`BG1` (real grid/rotate/snap building placement, `D28`'s first `OF4-rebuild` prerequisite) shipped — see `DONE.md`.** Serves both the player's own base (M8) and the coming `OF4-rebuild`. `BG2` (real castle-parts assets, `OF4-rebuild`'s other prerequisite) has since shipped too — see below — so `OF4-rebuild` is unblocked.

**`OF10`/`OF11` (hillside rebuilt from scratch — real landform via ridged/terraced geometry, root-caused and fixed the rock texture's tiling, rise-gated boundary blend) real progress shipped, both items' own done-when NOT fully cleared — see `DONE.md`'s `OF10`/`OF11` entry for the six-round history and `BLOCKED.md` for what's still open on each.** `OF10a`'s walkability fix already shipped separately.

**`OF10-remainder` (a trailhead fingerpost + cairn at the road's end, `[74,-41]`) shipped — see `DONE.md`.** Residue: shipped on the orchestrator's hard time cap after two render rounds (one self-critique pass, not the usual fresh-blind-subagent pass — no local subagent-spawning tool was available in this lane's toolset and a separate remote session could not see the worktree's render output); a third round was planned but not run. Round 2 fixed a real defect round 1's own inspection caught (the sign's single arm was nearly collinear with the approach camera and read as a bare post) but was not re-checked by a second independent pass.

**`OF11-remainder` (hillside rock ceiling) CLOSED 2026-08-13 by owner decision — the current state is accepted as good enough for a hillside the player climbs past, not stares at.** The 11-round history is in `DONE.md`; `BLOCKED.md`'s entry is marked resolved.

**Magenta-canopy (near-field tree magenta/red-striped foliage) root-caused and fixed** — see `DONE.md`. `Leaves.png`, the texture `trees`/`grove`/`saplings` retextured their canopy material onto, turned out to be a multi-species sample sheet (green/blue/orange/**magenta**, confirmed by direct pixel read) rather than the single muted leaf R9.4 believed it was; CommonTree/TwistedTree's leaf-card billboards sample almost the entire canvas per card (measured: median per-triangle UV box 0.80x1.00), so every card rendered the atlas's magenta and blue swatches alongside the green ones. Fixed by pointing all three `retexture` blocks back at `Leaves_NormalTree_C.png` (the pack's own single-hue leaf, already proven safe as the `bushes` layer's crimson-bush fix). Proven with an isolated before/after repro (single tree, no terrain, exact shipped material transform): magenta/pink-hue pixel count went from thousands to zero. **Not blind-verified past this point** — the actual named viewpoints (`road-end-lookup.png`, `dome-overview.png`) were not re-rendered/critiqued in-session (render-lock contention plus the 90-minute cap); next pass should re-render those two and run one `visual-judge` round before treating this as fully closed.

**`OF12-remainder`'s defect (a) — the-rise-route's mirrored tree stand — fixed, see `DONE.md`.** A new per-layer `seed_offset` mechanism on `scatter_rules.gd` broke the LEFT/LEFT/LEFT-then-RIGHT segregation a probe confirmed at the old seed; not re-rendered/blind-checked, only probe-verified — see the DONE entry for exactly what that does and doesn't confirm.

**`OF12-remainder` CLOSED 2026-08-14 — the blind round it was owed finally ran, see `DONE.md`.** A fresh, genuinely blind critic confirmed all three defects resolved or accepted: the mirrored-tree-stand fix held, a second broader-footprint grass species pair is curated into the `grass` layer, and the recurring hard-edged shadow-shape complaint was not reopened (`BLOCKED.md`'s closed entry already tested ten mechanisms and the owner accepted it as ordinary grass/path contrast). A fourth critic tracing that shadow complaint to a specific untested mechanism would be grounds to reopen it.

**`BG2`** (source a CC0 castle/fortress asset kit) shipped — see `DONE.md`. Quaternius's "Modular Medieval Building Pack" (30 models) staged at `assets_raw/vendor/quaternius_modular-medieval-buildings/`, ledgered in `docs/ASSET_LEDGER.md`.

**`OF4-rebuild` (construct the stronghold as an actual assembled castle, not a shader silhouette) shipped — see `DONE.md`.** Real curtain walls, a gate, and four differently-sized/shaped towers (2.02m-6.20m) assembled from `BG2`'s Quaternius castle kit, replacing `landmark.gd`'s procedural primitives. Critique pass (self-administered, see `DONE.md` for why and the honest limitation that names) converged after 4 rounds with one still-open remainder: the gate reading as a jagged opening rather than a clean archway. **That remainder is now closed by `OF4-gate-arch` — see `DONE.md`.** Its stated cause was wrong: the two entrance modules do share an arch profile, and the jaggedness was Godot's OBJ importer fan-triangulating the kit's concave n-gon wall faces (304 of them across the 21 staged models), filling a wedge of the archway back in with solid geometry. Assets ear-clipped in place, the gate rebuilt as one scaled module with a two-ring passage and a dark slab closing it, and the curtain's mid-height crenel light-leak sealed. Two genuinely blind critic sessions this time; round 2 called the opening "a clean, deliberate pointed archway ... nothing about the outline is jagged, broken, half-formed, or bricked up". Still open and named by both blind rounds, ahead of the gate and out of that item's scope: the whole south facade renders near-black because the sun sits north of the site with little ambient fill, plus untextured wall surfaces, irregular merlon rhythm at segment seams and a shed-like 1:8 massing at distance — `DONE.md`'s `OF4-gate-arch` entry carries the full list. `OF4-remainder-mound`'s bare-dune fix (below) is unaffected by this and still open on its own terms.

**`NP7`** (modular hair/accessory geometry split from the existing NP4 art, no new generation) shipped — see `DONE.md`. `villager_female`'s ponytail was genuinely separable and was cut into its own `hair_ponytail` mesh; `villager_male` and `grunt` were checked directly (6-angle renders) and found genuinely not separable, so no split was forced — item fully resolved for all three bases.

---

**`R6-village-notification-freed-instance` (the freed-instance SCRIPT ERROR in `building_prefabs.gd`'s teardown handler) fixed — see `DONE.md`.** A boolean-order bug (`is Node` ran before `is_instance_valid`, and Godot's `is` throws rather than returning false on an already-freed reference), not the genuine double-free the symptom suggested.

## Phase 0 — the owner played. This is the response.

**`R0.10`'s play gate fired 2026-08-09 — the owner played the first build, and the overhaul session that followed absorbed the entire feedback loop** — see `docs/HANDOFF.md` §3 and `docs/decisions/D18`–`D20` for the full record. It also absorbed much of Phase 2's first-day scope: ~10 authored harvest nodes, camp placement, campfire/bedroll, and rest-until-morning (parts of old R2.1/R2.4/R2.6/R2.8). What those items still owe is listed under Phase 2 below.

**`R0.11` ▶ CLOSED 2026-08-14 — the owner played it.** The response is on record in the 2026-08-14 "Blind playtest pass" commit (`6f5f8aa`): input-glyph lies, one-directional pause-menu tab cycling, a missing Use-on-berries path, flat-colour NPCs, no starting light source after dark, and an overlong opening conversation were all found, root-caused and fixed, each with real headless input-driven smoke coverage. Nothing from this playthrough is still open under this item; anything that surfaces later is new feedback, not a reason to reopen `R0.11` itself.

---

## Phase -1 — urgent PC bugs (owner-reported, 2026-08-10)

The owner played the published Windows build. One bug left, ahead of
everything else in this file — **do this first, then Phase -0.5, then
Phase 1 onward.**

**`RB1` (mouse look) — the first fix was WRONG; the real cause is found and fixed, see `RB1-actual` in `DONE.md`.** The owner's 2026-08-11 report that mouse look still didn't work after `RB1` shipped was the negative on-device confirmation the original fix (a mouse-capture race on focus) was waiting for. The real cause: `scenes/ui/playground_hud.tscn`'s `Root` `Control` had no `mouse_filter` line, so it defaulted to `MOUSE_FILTER_STOP` and consumed every mouse-motion event before `camera_rig.gd`'s `_unhandled_input` could see it — every other UI scene already set `mouse_filter = 2`. The original fix (re-asserting capture on focus gain) is kept, since `SH53` still wants it, but it was not this bug. A separate disproven guess in `RB1`'s original entry — that the owner's inability to reach Grandpa was a symptom of this same bug — was also wrong; `SA0` later root-caused that to an unrelated one-way beat machine.

**RB2 (walk/run animation) fixed — see `DONE.md`.** Real bug, found after
the owner corrected an earlier wrong "already fixed" pass this same firing:
every baked humanoid clip shipped `Animation.loop_mode = LOOP_NONE`, so
`character_model.play()` played walk/sprint once and froze for as long as
the state held — creatures already avoided this (`pal_animator.gd`), humans
never did. Fixed in `character_model.gd`/`trainer_model.gd`, verified by
`tests/smoke_input.gd` reading `loop_mode` directly and by real rendered
screenshots. Real on-device confirmation by the owner is still worth having,
same as RB1, but this one no longer needs it to know the bug was real.

---

**RB3 (smoke_aggression flake) fixed — see `DONE.md`.**

**RB4-diagnostics (startup boot log) shipped — see `DONE.md`.** **RB4
(Ally freeze root cause + fix: switched to the Compatibility renderer)
shipped — see `DONE.md`.** Real on-device confirmation that the freeze is
actually gone on the Ally is still worth having, same as RB1/RB2, but the
diagnosis and fix no longer need it to know the bug was real.

---

## Phase -0.95 — the loop itself (`D25`)

One item, above everything, because it is upstream of everything: a flaky test
does not fail *its own* task, it fails whatever healthy branch happens to be in
flight when it flakes, and `ralph-merge.yml` only ships green.

**`LP1` (the `smoke_traversal`/`smoke_combat` flakes) fixed — see `DONE.md`.**

**`LP2` (the `smoke_opening` beat-3 press-count flake) — a pattern-matched fix
shipped, the underlying race not directly reproduced. See `DONE.md` for the
full elimination trail and what would still confirm it.**

**`LP4` (green branches silently never merging) fixed — see `DONE.md` and
`D26`.** A lane reported `EV4-textures-remainder` green but unmerged. Four
branches were stranded, and the mechanism was not what the report guessed:
`ralph-merge.yml` rebases with the default `GITHUB_TOKEN`, and GitHub raises no
`workflow_run` event when a run initiated by that token completes — so the
rebase path could never merge anything. Every branch whose green run came from a
`push` had shipped; every branch whose green run came from a
`workflow_dispatch` was stuck. Fixed with `ralph-sweep.yml`, a ten-minute
reconciler that does not depend on an event arriving.

**Standing note for every firing:** if your branch is green and has not merged
within ~15 minutes, do NOT assume it is lost or start a second attempt. The
sweep lands it. If it is still there after two sweeps, read the sweep run's log
— a conflict or the rebase cap will name your branch explicitly.

**`LP3` (`release.yml`'s `cancel-in-progress` starving the download build)
fixed — see `DONE.md`.** The concrete case the note above is written for:
`ralph/LP3` had already burned 15 rebase cycles to the exact bug `LP4` fixed
before that fix landed, so it arrived at the new cap already over the limit.
`tools/ci/ship_branch.sh` stopped and named it explicitly, per design, and
this firing landed it by hand the way the script's own message says to.

**`LP5` (`ralph-sweep.yml`'s loop didn't return to a clean ref after a stuck
branch) fixed — see `DONE.md`.** Found and filed here after landing `EV3` by
hand; independently re-found and fixed the same hour by a different firing
sitting on `SA2-flake`, which was itself one of the branches stranded by this
exact bug — its own `DONE.md` entry (`LP5`) has the full root-cause trail and
an isolated scratch-repo reproduction. One correction to this entry's own
"done when": only the CONFLICT path actually needed the fix.
`ship_branch.sh`'s rebase-cap path fails and exits before its own
`git checkout -B "$BRANCH" "$SHA"` ever runs, so HEAD never leaves `__ship` —
that path was already safe and needed no change.

**`LP6` (a script-based mechanism so `STATUS.md` leases can't drift past
`## END LEASES` again) shipped — see `DONE.md`.**

**`LP7` (the `smoke_aggression` flake) root-caused and fixed — see `DONE.md`.**

**`LP8`** (`smoke_opening.gd`'s road-gate check failing against `main`) fixed — see `DONE.md`'s `OF3` entry. Root cause was `OF3`'s own `dialogue_panel.gd` advance-guard buffering change (`f8a42a92`), not `main`, not a CI race — fixed by suppressing the input check for one physics tick after `start()`; verified on two independent live CI runs.

**`LP9`** (`smoke_combat.gd`/`smoke_catching.gd` flaky under real CI load) closed — see `DONE.md`. Confirmed load-sensitivity, not a live bug: 26 instrumented runs escalating to 16-way CPU oversubscription reproduced two real hangs, both in `smoke_catching.gd`'s post-catch re-engage wait, with zero terrain-embedding signatures (LP1's mechanism doesn't reproduce here). `ci.yml`'s `verify-combat`/`verify-catching` jobs now retry once on failure, matching the existing `smoke_aggression`/`RB3`/`LP7` precedent.

### LP9 — `smoke_combat.gd` is flaky under real CI load; `LP1` did not fully close it
`model: sonnet` · `tests: smoke_combat`
Found 2026-08-15 shipping `ralph/R3.2` (a save/load item touching zero combat
code): CI run 31862240991's `verify-combat` job failed on **two consecutive
attempts, two different ways**, while `tests/smoke_combat.gd` reproduced
clean 4/4 times in an isolated local headless run on the exact same commit.
`conventions.md`'s flake procedure was followed before treating this as
someone else's bug: R3.2's own diff touches only `autoload/game_state.gd`,
`scripts/save/save_game.gd`, `scripts/world/death_satchel.gd`,
`scripts/world/player_death.gd` and two test files — nothing in the combat
path.

- **Attempt 1:** the fight resolved normally (enemy fainted, 'won'), but
  `_a_swing_at_the_enemy_connects`'s point-blank check failed: "a quick
  attack at point-blank range did no damage (117.8 -> 117.8)" and "a landed
  quick attack built no energy (0.0 -> 0.0)".
- **Attempt 2 (a GitHub Actions re-run of just the failed job, not a new
  push):** a quick attack landed fine this time (117.8 -> 108.2), but the
  FOLLOW-ON fight-to-finish step hung: "the enemy never landed a hit in 15
  seconds of standing still", "the fight never resolved after 2500 action
  frames", plus every downstream cleanup assertion failing in a cascade
  (arena never torn down, trainer input never restored) — the same
  symptom LP1's own history lists as caused by the enemy pal ending up
  embedded under terrain with no floor to catch it.

**Two different failure shapes on two attempts, both clean locally in
isolation, reads as CI-load-sensitive timing rather than a deterministic
bug** — this file's own history (`D25`) already states batching/concurrent
jobs make these exact two tests worse, and this run had 12 jobs racing on
shared runners. That said, attempt 2's specific wording is close enough to
what `LP1` catalogued as symptoms of the terrain-embedding bug that `LP1`'s
fix (grounding the teleport in `_a_swing_at_empty_air_misses` only) should
not be assumed to have fully closed the class — `_a_swing_at_the_enemy_
connects` and `_the_enemy_closes_and_hits_back` do their own real-time
movement/AI stepping that was never instrumented the way `LP1` instrumented
the one function it fixed.

**Not the fix, just the finding, backed by real evidence this time (unlike
a guess).** Done when: an instrumented run (the same per-frame position/
velocity watchdog `LP1` used, extended to cover the whole fight, not just
the opening teleport) either catches a live repro of attempt 2's hang, or
enough clean instrumented runs accumulate to say the load-sensitivity
theory is more likely than a live bug. Whoever picks this up should also
re-read `LP1`'s own "20/20 consecutive clean runs" claim skeptically —
that was 20 runs, uncontended, which per this entry's own theory is close
to the least likely condition to reproduce a load-sensitive flake.

**Second, independent test confirms this isn't `smoke_combat.gd`-specific.**
Found 2026-08-15 shipping `ralph/SB10` (a road-gate item touching zero
combat/catching code): CI's `verify-catching` job failed —
`tests/smoke_catching.gd`'s post-catch re-engage step timed out with
"could not re-engage after a catch; the fainted case could not be tested"
(the test throws an orb, catches the wild creature, then starts a SECOND
fight to confirm a fainted target refuses a throw — the hang is in getting
that second fight to actually start/resolve). Followed the same flake
procedure: SB10's diff touches only `scripts/world/road_gate.gd` and adds
`scripts/world/item_gate.gd`/its test, nothing combat- or catching-adjacent.
Local repro (headless, same commit, no CI contention): 2 of 3 runs hung
past 200s at the exact same point (re-engage after catch, no error, no
progress); the 3rd passed clean end-to-end in well under 200s. Same shape
as `LP9`'s own theory — a load/timing-sensitive fight-loop issue, not a
deterministic bug, and not unique to `smoke_combat.gd`'s specific
assertions. Rerunning the failed job in CI (uncontended, one job) passed
green on the first retry, consistent with contention being the variable.
Whoever picks up `LP9` should widen its scope to `smoke_catching.gd`'s
post-catch fight-start path, not just `smoke_combat.gd`'s in-fight steps.

**Closed 2026-08-15 — the done-when is met.** Extended LP1's per-frame
position/velocity watchdog to cover the whole fight (both `smoke_combat.gd`
and, per the note above, `smoke_catching.gd`'s post-catch re-engage path),
kept local and never committed exactly as LP1's own instrumentation was.
26 runs total, escalating CPU contention on a 4-core box: 6x concurrent
combat (uncontended-ish), 8x mixed combat+catching, then 12x mixed plus 4
pure-CPU `yes` loops (16 competing processes on 4 cores, deliberately past
what a real CI runner would see, to force the mechanism to show itself).
**Zero Y-plunge/embedded-under-terrain anomalies fired in any run** — LP1's
specific mechanism does not reproduce here, confirming this is a genuinely
different class of flake. **Caught a live repro twice**, both under the
16-way round, both in `smoke_catching.gd`'s post-catch respawn wait
(`_a_fainted_creature_cannot_be_caught`), both external-timeout kills, not
an internal fail — the watchdog showed physics ticks still advancing
normally (300-tick-spaced heartbeats present) with the wild creature's
state frozen between them, i.e. real simulated time passing with no
terrain/position fault, just far more real-world wall-clock cost per tick
than uncontended. That is the mechanism: every one of these tests bounds
itself in PHYSICS TICKS (`respawn_seconds * physics_ticks_per_second + 900`,
"2500 action frames", "15 seconds of standing still" counted in ticks), which
assumes ticks track real time. Under genuine CPU starvation they decouple,
and a tick budget that finishes in ~93s uncontended can blow through a CI
job's wall-clock timeout without the game logic itself being stuck. Shipped
the same mitigation `smoke_aggression` already uses for the identical reason
(`RB3`/`LP7`): `verify-combat` and `verify-catching` in `ci.yml` now retry
once before failing the job. Not a game bug, so nothing in `tests/` or
`scripts/` changed — the fix is entirely in the CI workflow.

---

## Phase -0.9 — the two blockers from the published build (owner, 2026-08-11)

**`SA0` (the opening soft-lock) shipped — see `DONE.md`.** The owner could not
interact with Grandpa at all and left the house with no starter. Root cause was
not the interaction system: the beat machine started at `wake`, `wake` had
exactly one exit (pressing the bed), and nothing forced it — so walking off the
bed pinned the beat forever, which keeps Grandpa's interactable disabled by
design. Fixed, plus the second route in (a houseless world had no exit at all),
plus a falsifying test (`tests/smoke_wake_softlock.gd`).

**`SA1` (Ally VRAM) shipped — see `DONE.md`.** ~630 MB reclaimed: 91 textures
moved off Lossless RGBA8 to S3TC, twelve 2048² all-black emissive maps shrunk to
4×4, foliage mipmaps enabled, both shadow atlases off the 4096 desktop default,
MSAA 4×→2×. **On-device confirmation is still open** — CI cannot measure VRAM,
same as `RB4`.

**`SA0-orbs` (starter choice moves into Grandpa's conversation) shipped — see
`DONE.md`.**

**`SA0-orbs-remainder` (lighting depth, UI chrome ownership, creature appeal)
shipped/resolved — see `DONE.md`.** All three sub-questions closed: a rim light
plus a selected-label treatment shipped (round 5 and 6 of the blind-judge pass,
five rounds total), `EV9`'s own scope note now names the narrative panels
explicitly, and the roster-wide creature-appeal question moved to `BLOCKED.md`
for the owner rather than staying stranded in a backlog item nobody could
execute.

**`SA1-lod` (vegetation discarding the importer's LOD chain) shipped — see
`DONE.md`.**

---

## Phase -0.6 — the look (owner's art bible, `D24`)

`docs/ENVIRONMENT_AND_UI_BIBLE.md`, made canon by `docs/decisions/D24`. This is
the answer to *"the visuals is the most important part… and it's not getting
fixed"* — and R9.4's own evidence agrees: both blind critics ranked **"needs art
that is not in the build"** first, and scene tuning had genuinely run out of
road. The repo has 42 of 116 nature models, **no** village kit, **no** props
kit and **no** UI assets beyond two portraits.

**Free Standard tiers only** — the owner declined the Source editions, so their
foliage shaders and optimised collisions are not available and nothing may
assume them. Ledger every pack **before** its commit; the ledger's own rules
require it.

**`EV1-remainder` (the two Quaternius MegaKits) shipped — see `DONE.md`.** The
owner supplied both zips directly on 2026-08-11, clearing the itch.io block
this item was originally opened for. Staged under `assets_raw/vendor/` and
ledgered, same as the Kenney four. This unblocks `EV6`, `EV7` and
`EV2-landmark-ceiling`.

**`EV2` (an approved Meadows nature subset) shipped — see `DONE.md`.** Hero
trees and standard canopy curated to the bible's counts with controlled
material variants; wetland forms and a distinct rock large-tier are honest
remainders, not done. Two new findings opened below: `EV2-trunk-colour` and
`EV2-landmark-ceiling`.

**`EV2-trunk-colour` (pale salmon/pink bark) fixed — see `DONE.md`.**

### EV2-landmark-ceiling — Hero trees don't read as landmark specimens even at the best 3-of-5 subset
`model: sonnet` · `tests: none` · `area: vegetation`
`EV2` curated `grove` to the 3 TwistedTree forms with the widest footprint,
tallest height and most asymmetric silhouette (measured, not guessed). A
blind critic still ranked this the #1 gap against the key art: "nothing in
these five frames comes close to the key art's oaks, whose canopies are
wider than they are tall and whose trunks visibly fork and lean... the
current asset's silhouette ceiling won't get there just by rescaling."
This is a real asset ceiling, not a placement/curation problem `EV2`'s own
lever (which models, what tint) can solve — the fuller Stylized Nature
MegaKit that might carry a genuinely broader-canopy hero form is itch.io-
blocked (`EV1-remainder`), and `CLAUDE.md`/`D24` forbid a Meshy generation
for a routine nature asset regardless. Not a `BLOCKED.md` design question —
there's no decision to make, just an asset gap with a known unblock path.
Done when: the Stylized Nature MegaKit's itch.io block clears and the fuller
pack is searched for a broader-canopy hero form, or the owner accepts the
current ceiling.

**Checked twice, 2026-08-12 — still blocked, unchanged, and worth stating
plainly since two different firings have now independently gotten this
wrong.** `EV1-remainder`'s own note that it "unblocks... `EV2-landmark-
ceiling`" is incorrect: the two zips the owner supplied and `EV1-remainder`
staged are the Quaternius **Village** and **Fantasy Props** MegaKits (176 +
94 `.gltf` files, verified by listing every one: zero tree or foliage
assets, purely architecture and props). **The Stylized Nature MegaKit this
item actually needs is NOT staged anywhere in `assets_raw/vendor/`** — a
second, separate firing's edit to this same paragraph assumed otherwise
("staged, `assets_raw/vendor/`... someone actually searching") without
checking, which would have sent the next firing searching for a pack that
was never downloaded. It remains itch.io-blocked exactly as `EV1` originally
found it.

**Owner answered 2026-08-13 (asked directly in an interactive session): the
owner will supply the Stylized Nature MegaKit zip themselves**, the same way
the Village and Fantasy Props kits arrived — explicitly chosen over
accepting the current ceiling. The zip landed the same day (`d64df71`,
staged full pack) and `d92cbbe` curated `CherryBlossom_3` — the only tree in
the full 270-file pack measured genuinely wider than tall by its glTF
`POSITION` bounds (16.59w × 14.49h) — into the `grove` layer in place of
`TwistedTree_1`, but left it "not yet rendered or blind-judged."

**2026-08-14 — rendered and blind-verified. Found and fixed a real bug the
config-only ship had, and the underlying ceiling question is now answered
by direct evidence rather than glTF bounds alone.**

A first blind pass against `tools/survey.gd`'s standard 5-frame set never
named a wide-canopy hero tree at all — turned out to prove nothing either
way: `tools/_probe_grove.gd` (new, dumps the layer's real seeded placements)
showed none of the 21 `grove` instances land anywhere near any of that
survey's five fixed cameras. A dedicated close-up
(`tools/_capture_grove_closeup.gd`, new — frames one `CherryBlossom_3`
instance with the trainer parked alongside for scale) found the canopy
rendering bright pink/purple, not green. Root cause, confirmed by reading
the glTF directly: `CherryBlossom_3`'s leaf material is named
`Leaves_CherryBlossom`; the `grove` layer's `retexture`/`retint`/
`variant_retint` blocks all keyed `Leaves_TwistedTree` only, so none of
them ever matched the new model — it shipped wearing its pack-native
blossom texture, untouched by the green swap the commit message claimed.
Fixed in `data/config/vegetation.json`: added matching `Leaves_CherryBlossom`
entries alongside the existing `Leaves_TwistedTree` ones, same
`Leaves_NormalTree_C.png` swap and `#78c86e` (`spring`) tint TwistedTree_1
carried before this item replaced it in that species slot. Re-rendered and
confirmed green by direct inspection.

With the colour bug fixed, a focused blind pass on that single frame
(scale ruler: the 1.8m trainer standing beside it) gave a direct, honest
answer to this item's own question: canopy reads "wider than tall, but only
modestly — roughly 1.5:1, not the 2.5-3:1, flat-topped, multi-lobed spread
the reference oaks show"; the trunk visibly leans/curves (a real, confirmed
win — the previous entry's "not confirmed by data alone" caveat is now
resolved, and it does NOT fork, staying one curving stem into the foliage).
Verdict: **"not yet" a landmark specimen** — the lean and modest width help,
but canopy shape/complexity, not scale, is what still falls short.

**Where this leaves the item.** Real, shipped progress (a genuine bug fixed,
confirmed by render) that is NOT the same thing as clearing this item's own
bar. `CherryBlossom_3` was already established as the ONLY tree in the full
270-file pack that's wider than tall at all, and no candidate anywhere in
that pack has separate trunk/branch nodes to produce a forking silhouette —
so this isn't a placement or curation lever left to pull; it's the pack's
own ceiling, now confirmed by direct render rather than inferred from glTF
bounds. Moved to `BLOCKED.md` for the owner: accept the current tree
(genuinely the pack's best option, and a real improvement — leaning trunk,
modestly wider canopy, correct colour) as the ceiling, or treat true
landmark-oak geometry as needing content this pack doesn't have (which
runs straight into `CLAUDE.md`/`D24`'s bar on new creature/nature-hero
meshes for the Meadows — a question for the owner, not a firing's call).
Unblocked in principle, same delivery: `EV5-remainder-2`'s third waterside
plant and `OF12-remainder`'s ground-cover species-variety half — both acted
on below/above.

**`EV3` (a first, narrower ground-cover slice) shipped — see `DONE.md`.** Fixed `path_stones` clumps disconnected from the real paths, and tightened `clump_radius` on `grass`/`drygrass`. Did not reach the item's full bar — "seven layered bands driven by slope, elevation, path distance AND landmark distance" is broader than this slice; the remainder continues in the `EV3-remainder` chain below.

**`EV3-remainder` round 1 (the flowers-along-a-path density bias) shipped a real but partial improvement — see `DONE.md`.** `path_bias`/`path_bias_jitter` measurably improved one of three judged frames with no regression on the other two, but `square-convergence.png` and `grandpas-house-route.png` still miss the done-when. **The elevation/landmark-distance placement-bias half of this item was not attempted at all this round** — still open, still needs the mechanisms bible §7C names, and needs `EV5` (water) to exist before "distance to water" means anything. Remainder continued in `EV3-remainder-2` below.

**`EV3-remainder-2`'s `square-convergence.png` half (row-planted flowers at the well) fixed — see `DONE.md`.** Root cause was not clump placement: `terrain_playground.json`'s four routes all share one endpoint at the well, so every ground-cover layer's path-exclusion isoline forms a straight four-way wedge there. Confirmed by two independent blind critics.

**`EV3-remainder-3`'s grass/drygrass mechanism fix shipped — see `DONE.md`.** Verified with real placement data before/after: offending clump distances from a path dropped from 2.35-4.26m to 9.46-11.16m after `path_avoid_radius` shipped. Did not close the parent item — a third blind critic still named the same hedge pattern; root cause traced further in `EV3-remainder-4` below.

**`EV3-remainder-4`** (grass/drygrass strays fixed structurally; flowers' path-biased clumps stop straddling the road) shipped, partial — see `DONE.md`. Did not close the parent item — a fresh critic still named `grandpas-house-route.png` for the same pattern, but a real placement-data dump found neither `flowers` nor `bushes` present there in meaningful quantity, ruling out further `path_bias`/`path_avoid_radius` tuning as the lever for that frame. Remainder continued in `EV3-remainder-5` below.

**`EV3-remainder-5` round 1 (the `path_stones` clump_radius fix) shipped, partial — see `DONE.md`.** Cut `clump_radius` from 8.0 to 3.5m near Grandpa's house, verified before/after (18→6 in-region instances, worst-case offset 8m→2.8m). Did not close the parent item — a fresh critic still named a flanking pattern there but attributed it to flowers/grass, not stones; a frustum-projection check does not support that attribution (real near-field flowers there are heavily left-skewed, not symmetric). Remainder continued in `EV3-remainder-6` below.

**`EV3-remainder-6`** tried the item's own named lever (denser ground cover via a new `extra_clumps` mechanism) and got a real result: worse, not better — see `DONE.md`. The new clump paired with the pre-existing left-side flower concentration and reproduced the exact mirrored flanking read the whole investigation was trying to eliminate; reverted cleanly. Five real, evidence-first rounds (`EV3-remainder` through `-6`) exhausted the mechanism-level investigation — moved to `BLOCKED.md` for the owner.

**EV4's mechanism (paths as a real control-map material, not a colour-map
tint) shipped — see `DONE.md`.** Five blind-judge rounds; the first four
tuned the wrong texture, round 5 wired in `Ground030` (sourced independently
by another lane specifically for this, credited in `DONE.md`) as a dedicated
`path` texture and the material genuinely improved — a fresh critic called it
"real progress... works as a navigational read." Two narrower remainders
opened below from round 5's own honest read of what is still wrong.

**`EV4-textures`** (moss-blotch saturation, and the slope-specific edge stepping) shipped — see `DONE.md`. Both converged over three blind-judge rounds: edge-stepping never reproduced past mild, ambiguous waviness, and moss saturation dropped from 0.36 to 0.09 via a direct feathered-mask edit to the CC0 source photo. Two new findings from round 3, out of this item's scope, were opened separately: the path reads paler than references even where moss is resolved, and an unmotivated hard-edged shadow crosses sunlit path frames.

**The `path_stones`-disconnected-from-the-real-paths finding (found
independently while blind-judging `EV4`'s paths, 2026-08-11) is fixed by
`EV3` — see `DONE.md`.**

**`EV4-textures-remainder`** (moss blobs reshaped from circular stamps to varied streaks) shipped, partial — see `DONE.md`. Round 1 fixed the hard-edge/circular-outline complaint outright; round 2 (per-blob asymmetric taper) only partially fixed the follow-on shape-variety complaint, and a separate class of grey fibrous "tuft" blobs still reads as repeating. Accepted as the item's own low-priority framing predicted — genuine shape variety needs hand-authored moss silhouette variants a procedural warp can't produce; no further remainder opened. `docs/ASSET_LEDGER.md`'s `Ground030` row has the full before/after account for anyone revisiting.

**`EV4-textures-lighting`** (blown-highlight/shadow-contrast on sunlit ground) shipped — see `DONE.md`. `SA1`'s shadow-atlas cut was ruled out as the cause; the real fix was day `exposure` 1.22→0.6 and `ambient_energy` 1.02→1.5, which resolved both the Barn's real occlusion shadow (`square-convergence.png`) and grass-vs-path contrast reading as a false shadow (`grandpas-house-route.png`). Did not fully clear the bar — remainder continued in `EV4-textures-lighting-remainder` below.

**`EV4-textures-lighting-remainder` (the unmotivated dark near-camera patch
at `square-convergence`/`the-rise-route`) closed 2026-08-12 — identified, not
just ruled out — see `DONE.md`'s `EV4-textures-lighting-remainder-3` entry.**
Ten mechanisms tested and ruled out across this item's full history (shadow
toggle, SSAO, normal-map depth/AO, ambient energy, vertex colour, photo
content, PSSM cascade splits, shadow bias); the actual cause is ordinary
grass/path luma contrast at the deliberately-feathered path edge
(`build_playground_terrain.gd::_path_control()`'s own documented design),
the exact same phenomenon `BLOCKED.md`'s open `grandpas-house-route.png`
"flanking" question already names and has spent five rounds on without a
fix. Folded into that existing `BLOCKED.md` entry rather than opened as a
duplicate. `tools/diag_control_texture.gd`, `tools/diag_shadow_cascade.gd`,
`tools/diag_shadow_bias.gd` and `tools/diag_path_factor_grid.gd` are kept as
reusable diagnostics. History below kept for the record.

`EV4-textures-lighting`'s own self-administered rubric pass (see its
`DONE.md` entry for why this wasn't a true blind sub-agent read — no
`Agent`/`Task`-equivalent tool was available in that checkout) still named
the Barn's shadow in `square-convergence.png`, and found a second,
previously-undiagnosed instance in `the-rise-route.png` — confirmed by the
same instrumentation to be genuine terrain self-shadowing off the Rise's own
nearby crest, not an artifact. Both are physically motivated (toggling
`sun.shadow_enabled` removes them cleanly) and both got less severe once the
highlight stopped blowing out (less contrast to read the shadow against),
but neither went away. Two levers were tried and both went flat —
`shadow_blur` 1→3 plus a further `ambient_energy` bump moved the sampled
shadow edge by single-digit luma, and `light_angular_distance` 0.6→4.0 on
top of that changed nothing visible — consistent with the Compatibility
renderer (`D06`) not implementing the soft-shadow machinery those properties
drive under Forward+; worth re-testing on real hardware before writing the
levers off entirely. Reaching further than that needs either a sun-angle
change (trades against the terrain-form-vs-shadow-length balance `R9.4`
already negotiated) or a scene-level change (the Barn's placement relative
to that viewpoint, or the Rise's crest shape) — neither is a `lighting`-scope
config edit, which is why this is a narrower remainder rather than more work
on the same item. Whoever takes this should also re-run a genuine blind
`visual-judge` pass first (a real sub-agent, not a self-review) in case the
verdict changes with fresh eyes. Done when: a blind critic given
`square-convergence.png` or `the-rise-route.png` either stops naming the
shadow, or explicitly agrees it reads as motivated (traces it to the Barn /
the Rise itself without being told).

**Root-caused 2026-08-12 by `RENDER-PERF-DIAG` (see `DONE.md`) — the earlier
"100+ minutes, no progress" attempt above was not measuring a real render
wall.** `tools/capture_paths.gd`, run with its own documented invocation
(no `--headless`), produced all four real PNGs in **4m34s**. The prior
attempt's mistake was adding `--headless`, which silently swaps in Godot's
no-op "Dummy" rendering driver regardless of `--rendering-driver` and makes
`await RenderingServer.frame_post_draw` hang forever on a signal that
structurally cannot fire — the main loop spins at high frequency the whole
time it's stuck there, which is consistent with the "CPU pinned near 100%,
not hung" symptom this entry originally recorded. `tools/diag_scene_perf.gd`
now exists specifically to re-diagnose this class of problem in minutes
instead of another open-ended wait; its own header has the full mechanism.

**The real blind pass ran 2026-08-12 (this entry's own missing step) — verdict
unchanged.** Re-rendered `square-convergence.png`/`the-rise-route.png` with
the documented invocation, then dispatched a genuine `Agent`-tool sub-agent
(not a self-review) against `docs/reference/` with no hint of what to look
for. It independently named both blobs unprompted — "the two large soft-edged
shadow blobs… Neither has a silhouette that matches any object visible in
frame… nothing in either shot gives the eye a caster to anchor them to, so
they read as unmotivated dark patches" — the exact opposite of this entry's
done-when (stop naming it, or trace it to the Barn/Rise unprompted). So the
earlier self-administered read was not the false positive a fresh look might
have overturned; a genuinely blind critic reaches the same place.

**Not chased further this pass, and not a `lighting`-scope task.** This
entry's own prior analysis already named the only two remaining levers as
outside `lighting`: a sun-angle change (risks the terrain-form-vs-shadow
balance `R9.4` negotiated across many other frames) or a scene-level change
(the Barn's placement — `data/config/village.json`, `area: village` — or the
Rise's crest shape — terrain heightfield, `area: terrain`). Checked both
before writing this off as someone else's problem rather than assuming it:
`EV6` (rebuild the settlement on the Medieval Village MegaKit) is live on
`area: village` right now and is explicitly repositioning/replacing the farm
buildings the current Barn shadow is cast by, so diagnosing or fixing that
caster's exact placement today would very likely be thrown away the moment
`EV6` lands. The Rise's crest half has no such conflict but is squarely
`EV4-hillside-seam-remainder`'s own territory (terrain-area slope/placement
work on the same landform), not a second unrelated terrain task. Given
neither remaining lever fits `area: lighting` and one actively collides with
a live lane, this stops here rather than reaching across areas. Whoever picks
up the Barn half: wait for `EV6` to land first, then re-render and re-judge
against the new settlement geometry before touching anything — the caster
this entry diagnosed may not exist in its current form afterward.

**`EV6` landed 2026-08-12 (see `DONE.md`) — the Barn is gone, the patch is
not.** Re-rendered fresh and re-ran a genuine blind pass exactly as instructed
above: the same defect is still named, independently, in **all four**
viewpoints now (not just the two named in this item's original done-when).
Five mechanisms were tested directly with real before/after renders —
`sun.shadow_enabled`, `env.ssao_enabled`, `normal_depth`/`ao_strength` on
both the `grass` and `path` textures, `ambient_energy` (up to 4x), and
Terrain3D's `show_colormap` debug override (rules out the baked vertex
colour map entirely — with textures off, no patch anywhere) — see
`DONE.md`'s full entry for the numbers. **None of them meaningfully move
it.** This also retroactively corrects this entry's own `square-convergence`
diagnosis: that shadow WAS real and WAS the Barn (confirmed at the time by
toggling `shadow_enabled`), but the Barn is gone now and disabling
`shadow_enabled` today changes nothing — a different, still-unidentified
mechanism produces the same-looking defect on the geometry that replaced it.
No code shipped this round (every experiment reverted, config files
byte-identical to before). Two real levers remained genuinely untested by
direct render rather than by inspection at the time — see
`EV4-textures-lighting-remainder-2` below for both.

**`EV4-textures-lighting-remainder-2` (both remaining levers tested: photo
content ruled out, blend-zone narrowed to a specific mechanism) shipped, no
code — see `DONE.md`.** Photo content is cleanly ruled out (neither source
JPG has a pixel dark enough anywhere). The control map genuinely does show
grass "holes" punched into the path where the patch appears (real signal,
confirmed via `tools/diag_control_texture.gd`'s new `show_control_texture`
debug view), but a direct experiment ruled out the dominant/dither blend
logic as the specific cause. Narrowed to `path_factor`'s own route-geometry
coverage as the next thing to instrument directly. Done when: a blind
critic given any of the four `tools/capture_paths.gd` frames stops naming
an unmotivated dark patch, or explicitly traces it to a visible object.

**`EV4-hillside-seam`** (blotchy hillside slope material) rounds 1-4 shipped — see `DONE.md`. Rock went from mathematically unreachable to a proportionate accent, verified by three independent blind-critic rounds. Did not fully clear the bar — remainder continued in `EV4-hillside-seam-remainder` below.

**`EV4-hillside-seam-remainder`** (rock near-black, ring-like placement) fixed; soil band still not visible — see `DONE.md`. Two of round 4's three named defects were resolved and confirmed by independent blind critics (rock's `ao_strength`/`normal_depth` cut stopped it reading as a cast shadow; a new `outcrop_jitter_deg` noise field broke the uniform rock ring into separated blobs). The third defect — no visible soil band — was NOT fixed after two real attempts, and the second was reverted as a regression; see `EV4-hillside-seam-remainder-2` below for the root cause both attempts ran into.

**`EV4-hillside-seam-remainder-2`** (the two lever-2 fixes: photo saturation, then the tint/colour-map compounding it hid) shipped, partial — see `DONE.md`. Fixed the raw soil photo's oversaturation directly (0.45 → 0.17, same technique as `Ground030`'s moss fix), then found and fixed a second compounding bug: `colour.soil`'s own multiply layer was itself saturated and stacking with the texture's `tint` (the same multiplicative-saturation bug `R9.4` already fixed for grass elsewhere in this file) — fixed both, reverified by direct pixel sampling (transition-zone saturation 0.65–0.76 → 0.18–0.43). Did not close the item: a third blind critic still reported no clearly legible third material, because soil and rock now differ mainly in value rather than hue and rock's low native brightness reads as "a shadow hole" rather than a second material. Colour-only levers on `soil` are now close to exhausted; narrower remainder opened below for the value/contrast half.

**`EV4-hillside-seam-remainder-3`** (both named levers tried: rock's floor brightness, soil's hue pushed away from rock) shipped, partial — see `DONE.md`. Three rounds: round 1 got the first critic-confirmed positive on rock (real internal texture/veining); rounds 2-3 found direct pixel sampling of the real render (not the offline texture chain) showed ~87% of visible ground pixels in one narrow hue band, and pushed soil toward true tan/dirt hue instead, moving the ground-hue histogram measurably with no rust regression. Did not close the item — the blind critic's core verdict did not move across any of the three rounds; no third material, rock still read as a stain/AO artefact. Colour/value levers on this specific soil/rock pair now read as genuinely exhausted; narrower remainder opened below, aimed at a different kind of lever entirely.

**`EV4-hillside-seam-remainder-4` (real height relief, gated to each rise's flank, tried at two amplitudes) shipped, did not clear the bar — see `DONE.md`.** A genuinely different lever from every colour round above; still didn't move the critic's core verdict even at 2.5m amplitude. Moved to `BLOCKED.md` per this item's own pre-authorized fallback — the hillside's rock/soil read is now an owner-facing question, not an open backlog item.

Also named by this item's rounds, explicitly out of scope (pre-existing,
unrelated to the slope-material bands specifically): the sun/moon disc
reading as a flat blurred sprite; the tower/spire on the hilltop rendering
as a flat unlit silhouette with no surface shading; a white, faceted,
crystalline-looking shape (very likely the known stronghold landmark
silhouette, `landmark.gd`) partially visible at the edge of two frames from
these specific camera angles.

**`Ground037` (mossy forest floor, ambientCG, also pre-sourced and ledgered
alongside `Ground030`) is still unused.** Bible sec8 item 5, Deep Grass/
Forest Floor, painted near the valley basin or under tree canopy once `EV3`
gives the bake real tree-placement data to key off. Whoever picks up that
layer should reach for it directly rather than re-sourcing.

**`EV5` (the pond, its inflow stream, reeds at the banks) shipped — see
`DONE.md`.** The waterline is a height (`terrain_playground.json`'s `water`
block), so anything that later wants "distance to water" as a placement
signal (`R7.1-remainder-2`'s original ask) can read
`playground_heightfield.water_level()`/`stream_factor()` directly.

**`EV5-remainder` (waterside dressing: rocks, driftwood, lily pads, the
jetty, a second marginal plant, the flowing-stream variant) shipped — see
`DONE.md`.** The "needs assets not in the build" framing was wrong for most
of it: everything except sedge/cattail was already staged and ledgered in
the packs. What genuinely remains is below.

**`EV5-remainder-2`'s OUTLET half shipped — see `DONE.md`.** The premise
above (no downhill destination) was overtaken by `SA4`'s `river_gorge`
spoke, which gave the pond a real basin to drain into; the outlet fix is a
deliberate sill+channel neck through what had been a diffuse merge shelf,
not the Band-3 downstream-terrain project this entry originally called for.

**`EV5-remainder-2`'s third waterside species** (`Grass_Wheat`, curated `d92cbbe`) shipped and blind-verified, real but partial. A blind critique found three distinguishable waterside forms across four frames, meeting the item's original "third silhouette" ask, but variety concentrated in one frame while the other three showed one repeated species or none; `Grass_Wheat` itself wasn't confirmed as visually distinct from the existing reed (only 8 clumps across ~300m shoreline, or its shared tint reads too close to call apart). Not chased further this pass — the remaining gap is a `water.json` marginal-density question for whoever next touches that layer, an `EV3`/`OF12`-style density question, not a species gap.

**`EV6` (settlement rebuilt on the Medieval Village MegaKit) shipped — see
`DONE.md`.** Workshop, two cottages, composed well, kit fences, two authored
square oaks; the windmill removed rather than left as a second family. The
mill, the ranger station, the bridges and Grandpa's-house-as-modules are
carried forward below.

**`EV6-remainder`** (mill/crossing, ranger station, farmhouse-as-modules, furniture blackness, well RockTrim, and `EV6-remainder-polish`'s cottage/soil-apron/cabinet/gamma fixes) shipped — see `DONE.md`. Open follow-ups: the mill's water wheel doesn't read as a wheel (no axle/spokes/paddles) and needs recomposing, along with a stray hillside plank and an identifying silhouette element for the ranger station; a settlement round 2 is still needed to confirm the polish fixes and re-judge the Backpack→`Bag` swap. Placing Oskar/the Rescued Ranger and fixing flat-black exterior NPCs are cheap `lane: npc` follow-ups (also `NP2`); other out-of-scope defects the polish round named are recorded in `DONE.md`'s `EV6-remainder-polish` entry.

**`EV6-remainder-well-rocktrim-shadow`** (root cause: `MI_RockTrim` imported with `metallic=1.0`) fixed — see `DONE.md`. A genuine blind critic on the fixed render still names a softer colour-temperature mismatch, most likely the Compatibility renderer's lack of ambient bounce/GI (`D06`) rather than a further material property (`roughness` already maxed, `ao_light_affect` confirmed inert). Accepted as the honest ceiling; no further remainder opened.

**`EV7` (a first slice: work area and farmhouse yard) shipped — see `DONE.md`.**
Two of the bible's five named clusters. `bridge repair site`, `quarry station`
and `trainer camp` need geography that doesn't exist yet (no bridge, no built
quarry — `SA4`/`EV5` territory) and are carried forward below.

**`EV7-remainder`** (`trainer_camp` and `bridge_repair_site`, built 2026-08-13) shipped — see `DONE.md`. A genuinely blind critic run overturned an initial self-graded pass, naming real composition defects in both clusters (`trainer_camp` failed outright, `bridge_repair_site` had five defects despite its purpose reading through); `EV7-clusters-fix` addressed them (re-spaced/re-sited, `props.gd` gained `pitch_deg`/`roll_deg`/`sink_m`), but that fix's own confirm read was self-judged, not blind — no subagent tool was available either round. `quarry_station` remains open and unbuilt, and is `SD16`'s scope, not tracked further here.

**`EV8`** (lighting and atmosphere) shipped — see `DONE.md`. Two rounds of the blind pass; warm sun/cool fill were already correct, and the pale-horizon/sky-inconsistency defects (`R9.4-remainder-2`) are fixed. A parallel lane independently fixed the same sky-inconsistency class in the website capture tool (`tools/capture_site_shots.gd`) — see `DONE.md`'s follow-on entry.

### EV9 — Rebuild the HUD
`model: opus` · `tests: smoke_menu` · `area: ui`
Bible §16–§18. Native `Control` nodes over Kenney UI + Input Prompts. Dark
translucent panels, teal accent, warm gold for progression, no fantasy scroll
frames. **Tested at physical 7-inch scale, not on a desktop monitor** — §17 is
explicit.

**First slice shipped 2026-08-11 (`eea16a9`): the exploration HUD.** Styled health/stamina bars, a party/orb count panel, and a live contextual interact prompt replaced the old always-on debug overlay (now F3-toggled). Blind visual-judge (3 rounds) converged on "coherent, intentional HUD"; remaining gaps were named as needing new assets, not more scene tuning.

**Second slice shipped 2026-08-11: real icon glyphs on five prompts, before `HD1` was found** — see `DONE.md`. `dialogue_panel.gd`, `name_prompt.gd`, `starter_picker.gd`, `prompt_arbiter.gd` and `encounter_director.gd` now draw real Kenney Input Prompts icons via new `input_glyph.gd`, with three real legibility fixes found across four blind-judge rounds. Does not close `HD1`: device selection still checks "a joypad is connected" rather than last-input-used, and `combat_hud.gd`'s Actions row (the owner's own F/RB repro case) was left untouched on purpose — reconciled in `HD1`'s own entry below.

**Third slice landed: `tab_backpack.gd` quantity-clipping bugfix — see
`DONE.md`.** A round-3 blind-judge finding (item quantity vanishing off
longer item names, e.g. "Small Potion" showing no held-count at all) found
stranded on an abandoned, never-merged branch and finished/shipped by a
later firing. Does not touch the re-skin itself — see `EV9-panel-reskin`
below.

**`EV9-panel-reskin` (inventory grid + crafting panel re-skin, plus the
crafting screen's missing primary-action button) shipped — see `DONE.md`.**
This entry's own "still open" bullet below was stale: `tab_backpack.gd` and
`tab_build.gd` were already wrapped in `menu_tab.gd`'s shared dark/teal
`_panel()`/`_style_slot()` language by the time this was picked up — the
reskin itself had shipped without ever being recorded here or getting the
required blind-judge pass. Ran that pass for real; it confirmed the panel
language and found one genuine gap the fix above closes.

**Still open — do NOT re-scope these as a separate item, they are this
item's remainder:**
- ~~The "[X] / [E]" input-glyph replacement...~~ **Tracked as `HD1`,
  Phase -0.85 — narrowed, not closed, by this item's second slice above.**
  Still needs the last-used-input-device tracker (no "joypad merely
  connected" shortcut) and still needs `combat_hud.gd`'s Actions row wired
  through it — see `HD1`'s own entry for the current, accurate scope.
- The "one tracked objective" line has nothing to read yet — `SB9`/`SB11`
  (progression-state system, quest log) are still open. Wire the label once
  that state exists; a label bound to nothing is a permanent blank box, the
  opposite of §16's "hide/fade what's not relevant."
- Compass — bible says "if it exists"; it doesn't yet, not this item's job to
  invent one.
- ~~Icon glyphs for HP/STA/Pals/Orbs~~ **HP/Stamina/Pals wired 2026-08-14 —
  see `DONE.md`.** The owner supplied all four (`369ecc5`); three now mount
  on their real widgets (HP bar, stamina arc, pal block), confirmed by
  direct render. `orb_capture` still has no mount point — there is no
  orb-count panel anywhere in the current HUD to hang it on, checked
  directly rather than assumed, and stays open. **The handheld-scale
  blind-judge round this bullet asked for ran 2026-08-15 and found and
  fixed two real defects — see `DONE.md`'s `EV9-handheld-icon-judge`
  entry.**
- A branded display font matching the "TETHERBOUND" key-art logotype, and
  gradient/beveled bar fills — still open. The owner supplied a style board
  (`ev9_display_lettering_style_guide.png`, same commit) but it has nowhere
  to apply: there is no title/logo screen anywhere in the game that renders
  a "TETHERBOUND" wordmark at all (the game boots straight into the world,
  D18), checked directly. Needs either a mount point (a title screen) to
  exist first, or the owner naming a different place this should apply.

**`EV9-double-prompt` (CombatHUD silently mirrored the exploration prompt outside a fight) fixed — see `DONE.md`.**

### EV10 ▶ — Cohesion pass
`model: fable` · `tests: none` · `area: visual`
Bible §22 Phase G and §23's metrics. Re-shoot the same viewpoints, blind-judge
against both reference sets, fix the three biggest gaps, repeat until further
improvement is asset-quality-limited rather than composition-limited.

**Deliberately not started 2026-08-13.** Its own premise is that it only
converges once `EV2`–`EV9` are actually shipped — `EV5-remainder`,
`EV6-remainder` and `EV7-remainder` landed this session but none has had
its own blind pass run yet (all three say so explicitly above), so a
cohesion pass now would be judging unverified, possibly-still-rough work.
Run this after those blind passes land, not before. It will also still
hit a real ceiling even then: `EV9`'s objective-tracker label
(Phase 3.5-blocked), icon glyphs/font and compass are all out of reach for
documented reasons above — record that plainly when this runs rather than
treating it as a failure to converge.

---

## Phase -0.55 — the cast (owner's NPC board)

`docs/art/reference/12_NPC_Bases_Reusable.png`, and spec §21/§22/§35/§36.
The board specifies **three** base bodies at player height — Female Villager,
Male Villager, Team Tether Grunt — each with hair/head variants, outfit
variants, palette rows and accessories, and it **supersedes §22's "one or two"**.

Its own implementation notes are the technical brief: *material/texture swap for
colour variants, hide/show accessories via separate mesh parts, hair variants
sharing head topology, keep colour calls low by using shared materials.*

**`NP1` (the modular NPC variant system: per-material palette, hair,
accessories, all data) shipped — see `DONE.md`.** The hair/accessory shapes
are placeholder primitives, not real geometry — none of the three rigs has a
separable hair or accessory mesh yet.

**`NP1-geometry` checked and moved to `BLOCKED.md` (2026-08-12) — its own
premise didn't hold.** It read as blocked-then-unblocked once `NP4`/`NP4-rig`
shipped three new humanoid bases; checked directly (parsed each `.glb`'s glTF
JSON the same way `NP1` did for the original three rigs) rather than trusting
the premise, and `villager_female`/`villager_male`/`grunt` are each **one
fused mesh, one material, no separate hair or accessory node** — identical to
trainer/Grandpa/Warden's own limitation. `NP4`'s Meshy image-to-3D pipeline
never was going to produce the board's own "hide/show accessories via
separate mesh parts, hair variants sharing head topology" brief; it generates
one manifold body. `EV1-remainder`'s two Quaternius kits (checked directly,
`assets_raw/vendor/`) are village architecture and props, nothing
character-shaped. So there is still no real modular hair/accessory geometry
anywhere in the project, and `D23`/`D24` foreclose generating one — humans are
rework-only, permanently, at any credit balance. See `BLOCKED.md` for the
full entry. **Trap for whoever eventually takes it:** `_attach_part()` sets a
placeholder's `offset`/mesh size as a *local* child of a `BoneAttachment3D`
inside the same 0.01-scale Armature chain `docs/HANDOFF.md` §6 documents for
the giant-player bug — `NP2` measured it directly, a "size 13" primitive
renders as 0.13m, a factor of 100. `_apply_hair()`'s own `0.08` offset is
almost certainly landing at ~0.0008m in the live game, effectively at the
bone origin rather than actually offset. Real geometry from a modular mesh
may sidestep this by not needing a manual offset at all — but if this item
still calls `_attach_part()` for anything, budget time to fix the scale
compensation there rather than rediscovering the same trap `NP2` did.

**Correction, found by `NP2`: the palette mechanism itself was invisible.**
All three human rigs' materials carry `emission_enabled = true` with
`emission_texture` set to the same painted albedo texture at a full-white
multiplier. Emission is additive and independent of lighting, so it swamped
any `_apply_palette()` tint completely — proven with a diagnostic that
tinted the Warden pure red and rendered him fully green, unchanged.
`character_model.gd`'s `_shared_variant_material()` now tints emission the
same way, so this is fixed for every caller, not just `NP2`'s — but it means
R7.2's three villagers, believed visibly tinted since `NP1` shipped, have
never actually looked different from each other in a rendered frame. Worth
a look next time anyone is near `village_npcs.gd`.

**`NP2` (Team Tether rank palettes) shipped — see `DONE.md`.** Grunt,
officer, captain and Warden, all on the Warden's rig (the only faction-
appropriate body installed; `NP4`'s Grunt has no game path yet, see
`NP4-rig`). A body-tint-only ladder failed blind review outright ("a
lighting gradient, not a rank system"); the real rank marker that shipped
is a chest badge using `NP1`'s own accessory mechanism, escalating in both
colour and size, converged after 3 rounds.

**`NP3` (the named Meadows cast) shipped — see `DONE.md`.** Mira, Oskar and
Tam got identity lines (Meadow Keeper, Bridgehand, Field Scout); the Quarry
Foreman and Rescued Ranger were added as two new reused-rig villagers. Real
trainer battles stay out of scope — that's `R8.1` and `SC12`–`SC15`, not §35.

**`NP4` (generate the three bases) shipped — see `DONE.md`.** Two of three
(villager_female, grunt) passed a two-round blind critique; villager_male's
trousers render darker/colder than the reference after three texture
attempts and villager_female has a persistent UV-seam texture blotch on one
shin — both recorded there as an honest remainder, not chased further after
two flat attempts each per `conventions.md`'s stopping rule.
**Re-checked 2026-08-13: ceiling confirmed, still no fix.** Tried a
genuinely new mechanism (direct glTF-geometry-informed pixel masking on
the texture atlas, same family as `desaturate_soil_texture.py`'s
precedent) rather than repeating the same retexture/prompt levers. It
surfaced why the ceiling holds: the character atlas is a single fused-
mesh/single-material UV layout with no per-garment boundary a height-band
heuristic can isolate — the trousers mask also caught the satchel, boots
and face fringe. No safe targeted fix without real per-garment UV
islands (Blender-assisted manual selection), so no code changed.
**`NP4-uv-split` (2026-08-13) closed both `NP4` texture defects — see `DONE.md`.** Splitting the character atlas into per-garment mesh/material/texture let villager_male's trousers and villager_female's shin stain both be fixed and blind-critic verified over two rounds; per-garment `palette` entries are now possible for the first time (spec §21). A macro-only residual on each is disclosed in `DONE.md`, the same bar `NP7` accepted.

**`NP4-rig` (rig, animate and install the three NP4 bases) shipped — see
`DONE.md`.**

**`NP5` (swap village NPCs onto the NP4 bases instead of recolored hero
rigs) shipped — see `DONE.md`.** One judgment call flagged there rather than
made silently: no source in the repo names a canonical gender for any of
the five villagers, so the female/male base split went by name convention
and roster balance.

**`NP6` (village NPCs reading flat-black in exterior frames) fixed — see
`DONE.md`.** Three real local blind-judge rounds; the darkest two villager
tints were brightened until a genuinely blind critic stopped calling any of
them unlit/silhouetted.

---

## Phase -0.75 — the owner's Meadows spec, P0 (owner directive, 2026-08-11)

`docs/MEADOWS_PROGRESSION_SPEC.md` §1 and §38 Phase A, made canon by
`docs/decisions/D23-the-meadows-is-the-first-game.md`. Owner-reported from a
real playtest of the published build, the same way Phase -1 was — **above the
rest of Phase -0.5**, because three of the five change what a survey frame
contains and judging a build that is about to change wastes a render pass.

Step 1 of the spec's Phase A — the PC mouse-capture lifecycle (spec §1C) —
**already shipped as `RB1`; do not rebuild it.** `playground_world.gd`
re-asserts capture on `Window.focus_entered` and backs off through
`_mouse_wanted_elsewhere()` for menu, dialogue and the name prompt, which is
the same mechanism §1C's Escape / menu-restore / Alt-Tab clauses describe. The
spec's ten-minute acceptance test is on-device work and is tracked as `SH53`,
not as a reopening of RB1.

**`SA2` (Grandpa's door gated until the opening beat is done) shipped — see
`DONE.md`.** One new finding opened below: `SA2-flake`, a pre-existing
`smoke_opening` beat-4 intermittent failure, unrelated to `SA2` itself.

**`SA2-flake` (`smoke_opening` beat 4 intermittent failure) fixed — see
`DONE.md`.** A pattern fix, same shape as `LP2` — the race itself was not
directly forced to reproduce locally, but it did reproduce for real on
`main`'s own CI moments before this was picked up, with the exact documented
signature.

**`SA3` (physical perimeter + below-world failsafe) shipped — see `DONE.md`.**

**`SA4`** (seven outward spokes, each believably severed) shipped — see `DONE.md`. All seven physically hold, verified by `tools/_probe_sa4.gd` walking the real player controller into each blocker. Honest residue, recorded here rather than as a new item: `high_pass` has no ice/snow reading yet (altitude and bare rock only); `mountain_trail`'s pile and `stone_gate`'s wall sever the road but stop short of the meadow on either side, reading as props rather than terrain; and `river_gorge` reads as a flat reservoir, not a gorge — its floor sits ~11m below the waterline and no depth that still blocks keeps it dry, so moving the spoke is the only route to a dry gorge. The `cliff_road`/Rise-trailhead duplication risk is closed — a blind critic shown both in one frame did not read them as duplicates.

**`SA5` (recolour Burrowback away from Terrapup) shipped — see `DONE.md`.**

**`SA6` (separate the five birds by palette) shipped — see `DONE.md`.**

---

## Phase -0.85 — HUD and item access (owner's third pass, 2026-08-11)

The owner played again and reported a long list of usability gaps. Checked
against the actual code before touching the backlog, because several of them
turned out to already be built:

**Already shipped, not backlog items — verify on-device before anyone rebuilds
them.** The active pal already follows the player automatically once adopted
(`follower_pal.gd` + `encounter_director.gd::adopt_starter()`, wired into the
live `meadows_playground.tscn`). The orb throw already shows a glowing sphere
with a halo and a trail, plus a trajectory arc while aiming (`orb.gd`,
`throw_preview.gd`) — the code comments describe this as a deliberate fix from
an earlier visual pass for this exact symptom. If either is still missing on
the owner's device, that's a bug report against a specific build, not a gap to
plan for here — check the build timestamp first.

**Genuinely new work below.** `HD1`/`HD2` are new; `R7.4` (minimap) is
promoted from Phase 7 by pointer, not duplicated; `CO1` extends the existing
follow system rather than replacing it; `SA7`/`SA8` are explicit owner
directives (`CLAUDE.md`'s carve-out applies — implementing these is not a
firing inventing a story beat).

**`HD1`** (device-aware input glyphs) shipped — see `DONE.md`. `combat_hud.gd`'s Actions row now draws real device-aware icons, and `input_glyph.gd` reads a real last-used-input-device tracker instead of "is a pad connected"; two blind-judge rounds found and fixed a size regression and a dimming bug. Deliberately did not build UI for `combat_switch_left`/`combat_switch_right` — confirmed no code reads those bindings, so there's no real feature to wire icons to. One remainder (`HD1-remainder`, closed) is below.

**`HD1-remainder`** (Quick and Charged combat icons render the same mouse-button silhouette, only mirrored) closed 2026-08-13 — owner accepts the current icon pair as final — see `DONE.md`. Checked the staged Kenney pack for a better-differentiated pair; none exists — a real asset ceiling, not an unexplored lever.

**Corroborating evidence from an independent re-check, 2026-08-13** (before
the owner's acceptance above landed): the staged Kenney Game Icons
Expansion pack has a real, differently-drawn `mouseLeft.png`/
`mouseRight.png` pair (a genuine shape difference, not just a recolor —
verified by alpha-channel diff), but at actual on-screen size it's barely
more legible than the current pair, and it's drawn in a flat-silhouette
icon language while every other glyph in the row uses Input Prompts'
keycap style — adopting it would swap one legibility complaint for a
visible style-cohesion regression (CLAUDE.md). No other staged pack has a
mouse-button asset at all. Reinforces the owner's call rather than
reopening it.

**`HD2`** (a real quick-access item hotbar) shipped — see `DONE.md`. The five slots are satchel slots 0-4, drawn live with `HD1`-style device-aware prompts and usable with one press each. Deliberately does not share code with `tab_backpack.gd`'s target picker — a hotbar heal applies to whichever pal is hurt worst instead of opening a picker, a considered fork not a silent revert of `OF2`. One gap (`HD2-remainder`, shipped) is below.

**`HD2-remainder`** (hotbar combat gate) shipped — see `DONE.md`. Landed inside the HUD-overhaul branch's own rewrite as expected, but wasn't logged back here until a bookkeeping pass found it done.

**`CO1` (manual pal summon, dismiss and swap) shipped — see `DONE.md`.**

**`SA7` (a gated road out of the village, with a key nearby) shipped — see
`DONE.md`.** One narrower remainder opened below.

**`SA7-remainder` (the gate's lock and the key both read clearly to a blind
critic now) shipped — see `DONE.md`.** The "shape-resolution ceiling" this
item's own prior rounds diagnosed was not real; a debug render caught two
actual bugs (a facing-direction sign error, and a metallic material with no
environment reflection to show under this renderer) that had kept both
objects effectively invisible or dark regardless of shape/colour tuning.

**`SA8` (Grandpa's opening dialogue: the Team Tether urgency beat) shipped — see `DONE.md`.**

---

## Phase -0.5 — Visual pass (owner directive: finish this before R1–R8)

Everything the two 2026-08-09 blind reviews (`docs/reviews/2026-08-09-site-
frames-blind-critique.md`, `docs/reviews/2026-08-09-r0.8.5-full-blind-
review.md`) found that is fixable by changing the scene, gathered here and
worked in this order. The one finding that is NOT here on purpose: the
creature/human art-pipeline style mismatch is a design decision (rework vs.
replace assets) parked in `BLOCKED.md` for the owner — `CLAUDE.md` forbids
inventing that call, gate or no gate.

**VP2 (preview_creatures.gd rendering zero creatures) fixed — see `DONE.md`.**

**R5.1 (day/night cycle) shipped — see `DONE.md`.**

**R7.1's signposts and stronghold silhouette shipped — see `DONE.md`.** Three
bullets of the original five are still open:

**R7.1-visual (blind-reviewed the signposts and stronghold silhouette, three
rounds) shipped — see `DONE.md`.** One remainder opened below.

**R7.1-visual-remainder (new wall/roofline/crenellation geometry, blind-
reviewed over three rounds) shipped — see `DONE.md`.** Close and mid range
now genuinely read as fortified architecture; a narrower long-range
remainder is opened below.

**R7.1-visual-remainder-2 (long-range fortress read) CLOSED by R9.4 — see
`docs/reviews/2026-08-11-r9.4-full-visual-pass.md`.** The shape was never the
problem. Its own third round had suspected as much ("a placeholder-primitive
fortress cannot clinch this distance") and it was wrong: R9.4 rendered the same
geometry at all three ranges with a corrected material and it reads as a
fortified silhouette at every one, crenellations and varied massing included.
What was actually wrong was the COLOUR — `unshaded` at `#2a2630` is so dark a
fresh critic called it "a hole punched in the image rather than a stone ruin".
Now `unshaded` at a dark slate stone value. The two smaller findings that entry
carried are still live: the north tower's cap reads as a chimney, and the
ridge's hard-edged tan mound cap is terrain material, which `R7.1-remainder-2`
below already owns.

**The olive/lime ground seam is fixed — see `DONE.md`.**

**R7.1-remainder (ridge-bias clump placement + ground-cover clustering, three
rounds) shipped — see `DONE.md`.** Genuine, visible improvement over the
pre-fix state, but neither bullet fully passes the blind critic yet; a
narrower remainder is opened below.

**R7.1-remainder-2 COLLAPSED into `EV3` (ground cover) and `EV5` (the water
question it raised).** Not closed — superseded. It spent three rounds
redistributing a fixed instance count and the critic kept saying the same
thing, which is the signal that the lever was wrong: `EV3` rebuilds placement
around clusters, clearings and seven layered bands instead of tuning noise, and
`EV5` answers the "would water do more for depth than more vegetation?"
question it ended on by just building the pond. Its evidence is kept below
because `EV3` inherits it as the bar to clear.

Original entry — Ground cover still reads procedural, horizon mid-ground still sparse:

R7.1-remainder's third and final blind-critic round, on the post-fix survey
(owner-directed interactive session, 2026-08-10/11): the field still "reads
underpopulated" against both references (its #2 ranked gap, right behind
sky/fog consistency), and names both original bullets specifically —

- **Continuous ground cover, still not clearing.** Despite three rounds of
  tuning (bigger tufts, per-instance colour jitter, cut `strays` grass
  2000→500 / drygrass 700→200 for tighter clumping — see `DONE.md`), the
  critic still calls the scatter "roughly even spacing and uniform scale in
  02, 03, and the open ground of 01 and 05... no clearings, no clustering
  around features, and no scale variety within a prop type." The clump
  structure that IS there (visible in 03, 04) isn't enough density to read
  as continuous cover rather than isolated groups. Next attempt should try
  a genuine density lever inside the clumps themselves (more `per_clump`,
  smaller `clump_radius` for tighter packing) rather than further
  redistributing the same instance count, and re-judge against Palworld's
  own field shots specifically for how many blades are actually on screen
  at once.
- **Horizon/mid-ground, partly the known unfixable limit, partly not.**
  "No middle-distance layering anywhere in the set (no tree lines,
  ridgelines, or water)... the single biggest reason these frames feel
  empty." Some of this is `world_background = NOISE` (Terrain3D's
  procedural continuation past the 512m bake, genuinely can't hold props —
  see the original `R7.1-remainder` entry in `DONE.md`), but the finding
  reads as broader than just the unreachable far band — the near/mid
  ground inside the bake is also thin. Worth investigating whether a
  water feature (a pond/stream, named as a biome pillar in `GAME_DESIGN.md`
  but absent from every survey frame) would do more for depth-reading than
  further vegetation tuning.

Two smaller findings from the same round, not chased further to stay
inside the three-round cap **that no longer exists** — it was replaced on
2026-08-11 by a convergence test, so whoever takes `EV3`/`EV8` should not
inherit this entry's reason for stopping: sky/fog treatment is inconsistent between
frames (01/05 show a blue gradient sky, 02 a dark navy sky with hard-edged
cloud shapes, 03/04 a flat cream band) — likely a lighting/environment
config difference between survey viewpoints rather than a scatter issue,
worth its own investigation; and a small aliased red-maroon shape in 03
that the critic couldn't resolve into a legible object, possibly a
retint/LOD edge case on a single tree instance.

**R7.1-found (rise-overlook eye moved off the tower cluster) fixed — see `DONE.md`.**

**R7.1-found-2 (near-vertical bank near spawn, root-caused to overlapping
building-pad flattening, not a path or texture bug) fixed — see `DONE.md`.**

**R7.1-found-3 COLLAPSED into `EV4`.** The stripe is a colour/blend-map
artefact, and `EV4` replaces that whole painting approach with the control map
and eight authored layers — fixing it under the old scheme would be work thrown
away. Evidence kept:

Original entry — a flat texture-splat stripe on the hillside behind the spawn crate:

Found running the confirmation visual-judge pass for R7.1-found-2 (frames
01, 05): a diagonal tan/khaki stripe on the hillside behind the wooden
crate, "crisp and uniform-width rather than irregular or grass-feathered,"
and not picking up raking-light shading in the low-sun frame the way real
terrain relief would — reads as an unintentional texture-blend artefact,
not an authored dirt trail or any part of R7.1-found-2's fix (that fix
touched height/geometry only, not the colour/blend map). Needs its own
look at whatever paints dirt/soil blends onto slope near the spawn pad in
`build_playground_terrain.gd`. Not chased here — out of scope for the
near-vertical-bank defect this pass was confirming.

**R7.2 (NPC villagers and interior polish) shipped — see `DONE.md`.** The
sub-agent that built it disclosed a real process gap (no way to spawn a
genuinely blind critic and read back its verdict from its own toolset) and
self-graded instead. The owning interactive session had that capability and
used it afterward — a real blind critique ran against a confirmed-on-`main`
render; see `DONE.md` for the verdict and why none of its findings needed
an R7.2-specific fix.

**R9.4 (full visual pass) ran — see `DONE.md` and
`docs/reviews/2026-08-11-r9.4-full-visual-pass.md`.** Two blind critics, three
render rounds, real measured movement on every axis, and a lot fixed —
including four defects no test could see (mirrored signpost text, a creature
embedded in a roof, a magenta placeholder cube, and a plinth regression the
same pass introduced and caught). It did **not** reach the bar, and the
remainders below are the honest split rather than a pass. The original item is
kept beneath them because its instruction — re-run and compare sheets, never
assert the fix landed — is the standing rule.

**R9.4-remainder-1 COLLAPSED into `EV4`.** Same file, same bake, same command.
`EV4` rewrites `terrain_playground.json`'s material set and re-runs
`build_playground_terrain.gd`; re-solving `colour.grass_low` / `grass_high`
toward neutral is one field of that edit, and doing it first would mean baking
the `.res` files twice for one large binary diff each. **`EV4` inherits the
acceptance number**: `frame_stats` mean saturation inside 0.40–0.50 on frame 01
without the ground going grey. The diagnosis below is why, and it is the part
worth carrying forward:

Original entry — Ground saturation still above the bar, and the rest of it is baked:

`tools/frame_stats.py` after three rounds: mean saturation 0.59 on frame 01
against 0.40–0.46 for the Palworld references and 0.39 for the key art. Round 1
found the cause and it is structural, not taste — `albedo_color` multiplies, so
every tinted multiplier RAISES saturation, and the ground had three stacked
(texture tint 0.675→0.796, baked colour map →0.859, macro variation →0.873).
Two of the three are now solved or neutralised. **The third is the baked colour
map** (`terrain_playground.json` `colour.grass_low` `#c2d492` / `grass_high`
`#d8dc9c`), and it cannot be changed at runtime: it is written into
`data/terrain/playground/*.res` at bake time. That file's own comment sets a
floor of `#c0` on every channel so the map "modulates rather than paints", and
`#c2d492`'s blue is `0x92` = 146 — it has been violating its own stated rule
since it was written. Done when: the map is re-solved toward neutral, the
terrain rebaked (`godot --headless --path . --script
scripts/world/build_playground_terrain.gd`), and `frame_stats` puts mean
saturation inside 0.40–0.50 without the ground going grey. Expect a large
binary diff on the `.res` files; that is the cost of the fix, not a mistake.

**`R9.4-remainder-2` CLOSED by `EV8`** — see `DONE.md`. The pale-horizon/sky-inconsistency defect was fixed by `world_background = 0` (NONE, draws nothing past the bake) combined with dropping the photographic sky panoramas, whose baked-in sun position didn't track the scene's own sun angle — the real cause of the sky-treatment inconsistency.

**R9.4-remainder-3 COLLAPSED into `EV6`**, which already names it. Building a
`retint` hook for the Quaternius structures that `EV6` then replaces wholesale
is the definition of wasted work — but the *requirement* survives the swap and
`EV6` owns it: `village.json` must be able to lift a structure's roof the way a
vegetation layer retints a leaf, whatever kit is underneath. Acceptance carries
over too: roofs in the reference's warm 35–65% band, not the 11–16% measured
here. Evidence kept:

Original entry — The pack buildings have no material override path:

Every roof in the settlement measures 11–16% luminance in direct midday sun
against a reference board that keeps its roofs in the warm 35–65% band and
spends its darks on tree canopy. The windmill's tower reads as a black cutout
in two frames, taking its own modelled mullions, gallery and arch down with it,
and the fences are solid black with no rail-vs-post break. `village.gd` places
Quaternius structures and never touches their materials — there is no `retint`
hook at all, unlike `vegetation.gd`, which has had one since the crimson-bush
fix. Done when: `village.json` can lift a structure's roof the way a vegetation
layer can retint a leaf, and the settlement's roofs sit in the reference band.

**R9.4-remainder-4 COLLAPSED into `EV4`**, which already names it and states the
same fix — the control map, not the colour map. Evidence kept, including the one
fact worth knowing before anyone re-tunes it: round 3 made the existing tint
visible for the first time, because desaturating the grass stopped drowning it.

Original entry — Paths are a colour-map tint, not a material:

`build_playground_terrain.gd` paints paths by lerping the COLOUR map toward
`#c8a874`, and its own comment already calls a real material "queued as
polish". Because the colour map multiplies the grass albedo, a path is
grass-coloured grass with a tan cast rather than bare earth — which is why both
critics reported "no worked ground anywhere in the settlement" and "stepping
stones scattered in loose clumps that don't form a path". The fix is the
CONTROL map, not the colour map: paint the soil texture along the route so a
path is a different material. Round 3 made the existing tint visible for the
first time (desaturating the grass stopped drowning it), which is worth knowing
before anyone re-tunes it. Done when: a path reads as trodden earth from
standing height, and the path stones sit in it rather than on grass.

**R9.4-remainder-5 COLLAPSED, split across `EV6` (the site plan and the trees)
and `EV7` (the props).** Both already name it. This is the item that most
justifies the whole of Phase -0.6: it is the one both critics ranked first or
second independently, and it was never fixable by tuning — the props it asks for
are in a pack the repo does not have. `EV1` acquires them, `EV7` places them in
authored clusters rather than scattering them. Evidence kept, especially the
critic's own shopping list:

Original entry — The settlement has no trees, no props and no site plan:

Both blind critics ranked this first or second, independently. The key art's
own STARTING SETTLEMENT panel is organised around oak canopy framing a worn
dirt square, rail fences leading the eye in, and garden beds against the walls;
the build has buildings standing on open ground, fence stubs that enclose
nothing, and **not one tree anywhere in the settlement** (`vegetation.json`'s
`clearings` hold vegetation off the square by design, and nothing was ever
authored back in). The critic's list of what would fix it: woodpile, barrels,
crates, a cart, a hand-pump, hitching rail, garden beds, a washing line.
Content, not tuning — and it belongs with `R7.3`'s authored-space work rather
than in a palette pass. Done when: the square reads as a place people use.

**R9.4-remainder-7 COLLAPSED into `SA1-lod` (the mechanism) and `EV3` (the
judgement).** Read the entry below knowing it names the wrong cause. It blames
the hard alpha scissor and R9.4 shipped alpha-to-coverage against that theory;
`SA1` then measured the actual problem, which is that the foliage pack imports
with `mipmaps/generate=false` on all 14 textures **and** `vegetation.gd`
rebuilds an `ArrayMesh` that discards the importer's LOD chain. So 28,732
instances draw at LOD0 at every distance, sampling un-mipmapped 512² textures at
roughly 50:1 minification — which is aliasing by construction, and also the best
explanation of the owner's "high memory, 25% GPU" profile. The mipmap half
shipped in `28af489`; `SA1-lod` is the LOD half. Alpha-to-coverage stays and is
still unverified on the Ally, but it was never going to be sufficient. Evidence
kept — the entry's *observation* was right even though its diagnosis was not:

Original entry — Foliage aliases into confetti at distance:

**Two independent blind critics, on different frame sets, both named this the
most bug-like thing in the build** — "blue, magenta and cyan speckle… reads as
compression noise, not foliage" and "blue/green/white confetti speckle".
Confirmed by crop: a distant tree resolves to a scatter of unrelated pixels.
Root cause is a hard alpha scissor, which has no partial coverage — every texel
is fully in or fully out, so a ten-pixel tree is a handful of disconnected leaf
texels with background between them. R9.4 turned on alpha-to-coverage in
`vegetation.gd`'s `_retint()` so the project's existing 4× MSAA
(`project.godot` `anti_aliasing/quality/msaa_3d=2`) can finally act on foliage
edges — **but that is unverified**: llvmpipe's MSAA is not something these
survey frames can honestly test, so this needs judging on the Ally. And it is
only half the problem: a ten-pixel tree carries almost no information whatever
the sampling, which is an LOD or impostor question this item does not answer.
Done when: a critic looking at the mid-distance stops calling the trees noise.

**R9.4-remainder-8 (three of its findings) fixed — see `DONE.md`.** The other
five did not reproduce, were out of this item's scope, or were not chased —
see the remainder below.

**R9.4-remainder-8-followup (both findings checked) closed — see `DONE.md`.**
One real, one a false alarm on the same pattern as the windmill rock. A
narrower open item, `R9.4-remainder-8-rocks-repeat`, is below it.

**`R9.4-remainder-8-rocks-repeat`** (the colour half — rocks layer now reads as varied stone) shipped — see `DONE.md`. Three genuinely different hue families (warm tan, cool blue-grey slate, rust-brown ironstone) survive scene lighting, confirmed by a third blind critic as "real material variety, not a repeated instance." Not fixed, and out of this item's scope: every rock is still the same faceted low-poly silhouette at the same scale in a loose evenly-spaced row — real shape/size variety needs the itch.io-blocked Stylized Nature MegaKit (`EV1-remainder`), the same ceiling `EV2-landmark-ceiling` already hit for hero trees.

**`R9.4-remainder-6`** (root-caused why `survey_combat.sh` never completed) shipped — see `DONE.md`. Not a hang: real per-phase timing showed `SETTLE_FRAMES` alone costs ~278s on this box's software renderer, ~1.16s per physics frame against a 24,314-prop scene. Fixed a real bug found along the way (the charged-attack energy wait had no iteration cap). The arena still had not been visually reviewed at this point — continued in `R9.4-remainder-9` below with the timing evidence needed.

**`R9.4-remainder-9` (get real combat frames) shipped — see `DONE.md`.** All
eight frames, for the first time — but getting there needed three separate,
real bug fixes in the survey harness itself, not just render-time patience:
the D18/SA0 indoor-opening redesign moved the scene's default player spawn
into Grandpa's farmhouse, which cascaded into the player never reaching the
wild pal, never having an ally pal to fight with, and never having orbs to
throw. All three fixed. The required blind pass on the real frames then found
genuine combat-presentation defects — narrower remainder opened below.

**`R9.4-remainder-9-combat`** (impact flash, telegraph glow, and a real-opponent marker, all newly working — verified by direct pixel inspection) shipped, partial — see `DONE.md`. Charged-vs-quick size differentiation is confirmed working by a fresh blind critic; the orb now sits correctly on its drawn arc. What didn't close: this encounter's camera lined the two fighters up from the camera, occluding the ground-level telegraph ring and the quick-attack target being judged — not proof the mechanisms fail, just not proof they read in the case that matters. Continued in `R9.4-remainder-9-combat-2` below.

**`R9.4-remainder-9-combat-2`** (off-axis combat survey finally rendered, twice
over — see `DONE.md`) shipped. The target marker's "unreliable" complaint is
closed for good: a per-frame position dump (`survey_combat.gd::_dump_marker`)
showed `flat_offset` exactly `0.000` against the wild pal in all 9 samples
across both runs, and a direct render confirmed the real cause was visual
confusion from a decorative lookalike rabbit, not a tracking bug —
`target_marker.gd` is untouched and needs no further look. Two things stay
open and REAL, confirmed by re-rendering rather than asserted away: the
ground telegraph ring (`telegraph_glow.gd`) never draws at all, in either
run, even in a fully unoccluded frame — the obvious fix (`no_depth_test =
true`, the same fix that cured `impact_flash.gd`'s identical-shaped bug) was
tried and RE-VERIFIED by a second full render NOT to be the actual cause;
left in (still correct by the same reasoning) but the file's own comment now
says plainly it didn't work and names the next lever (confirm
`telegraph_started` actually reaches `_on_enemy_telegraph()` for this
creature/attack). And the quick-attack capture point (frame 05, -70° swing)
recurred occluded in BOTH independent runs — a real, repeating pattern at
that specific capture point, not one encounter's bad luck, still unfixed
per this item's own instruction not to build the taller/camera-facing ring
without a critic naming it. `orb.gd`'s blown-out bloom recurs, untouched (no
genuinely blind critic reached it this round — self-judged only, disclosed
as such, not a substitute for the real blind pass). The backdrop-drift
oddity is very likely just the arena's small fixed radius plus genuinely
different off-axis camera headings revealing/hiding a real, static nearby
village — not a repositioning bug, not chased further.

**Both named next-levers now actually checked.** The camera-occlusion
pattern is root-caused, not a mystery: `survey_combat.gd::_capture_the_impact()`
swung the camera off-axis then awaited a PHYSICS frame before pausing —
but `camera_rig.gd` has no `_physics_process()` at all, only `_process()`,
so the swing had no guaranteed chance to bake into `rotation`/`global_position`
before processing froze. Fixed by awaiting two `process_frame`s instead.
The exact "confirm `telegraph_started` reaches `_on_enemy_telegraph()`" lever
this entry itself named was also run for real: instrumented all three links
(emit, handler, draw) and drove a live `smoke_combat.gd` fight, not a static
trace. Every link fires cleanly every time — `telegraph_started` emits,
`_on_enemy_telegraph()` receives it, `_draw_ring()` runs with sane numbers
(radius ~0.46, alpha ~0.9, `visible=true`, `custom_aabb` correctly set).
The signal/logic chain is confirmed clean, not the bug. What's left, per
`telegraph_glow.gd`'s own updated comment: the one real structural
difference from its working siblings is that it draws flat on the ground
plane instead of as a camera-facing billboard — a rendering-only question
now, needing the actual render pass to test, not more code archaeology.
**The full-roster
creature sheet (`tools/preview_creatures.gd`) is still NOT run and still open
for `SA5`/`SA6`** — this round's tightened time cap said pick it up only if
already rendered, and it was not.

---

## Phase 1 — vocabulary, before the codebase grows

**`R1.1`/`R1.2` (rename `pal` → `creature` everywhere) shipped 2026-08-14 — see `DONE.md`.** One mechanical commit, camelCase/snake_case-aware, applied
identically to paths and content; the four directory moves, every code
reference, and the explicitly-named docs all landed together. `docs/decisions/`
kept its original vocabulary with a one-line note per affected file, per this
item's own instruction. Full suite (596 tests) and every CI smoke test green.

---

## Phase 2 — the first day, remainder

The session shipped harvest nodes, camp placement, campfire/bedroll and rest
(see Phase 0's note). What is left is the part that makes them an *economy*
rather than a scripted route.

**`R2.1` (Tools) shipped — see `DONE.md`.**

**`R2.2` (Tool durability and free repair) shipped — see `DONE.md`.** Repair
is free, from the backpack menu rather than a physical workbench — `R2.7`
(Workbench and storage container, below) hasn't built a placed station yet
for GAME_DESIGN.md §19's "at appropriate station" to gate against.

**`R2.3` (real tree/rock harvesting on the vegetation) shipped, partial — see
`DONE.md`.** The core mechanism is real and tested: a deterministic slice of
the world's own scattered trees/rocks (not a second set of authored nodes)
is now genuinely harvestable, tool-gated the same way as `harvest_node.gd`'s
tutorial spots, sharing the durability/tool logic through a new
`harvest_logic.gd` rather than a second copy of it. **Did not fully clear
the owner's own added bar** — narrower remainder opened below.

**`R2.3-remainder` (the harvest-point glint reads as a designed convention,
not a debug sticker) shipped — see `DONE.md`.** The next untried lever this
entry itself named — real glow falloff, a `GPUParticles3D` sparkle — closed
it: three local rounds (each fixing a real defect a fresh blind critic found
in the previous one — a faceted low-poly sphere core, then untextured hard-
edged sparkle quads), converging on a fourth critic's direct verdict, "reads
as an intentional resource-glint convention... not a debug leftover."

**`R2.4` (Orb and potion crafting) shipped — see `DONE.md`.**

**`R2.5` (REMOVE the post-fight auto-heal) shipped — see `DONE.md`.**

**`R2.6` (floor/wall/door/roof/fence as a real, generalized build-piece
catalogue) shipped — see `DONE.md`.** Two real rounds of the required blind
pass, real movement both times; did not fully clear the bar. The residual
gaps (door not in a cut wall opening, wall/roof palette mismatch) are
`EV6`-shared, not R2.6-specific — see `DONE.md` for the full account and
the concrete next lever (`Wall_Plaster_Door_Flat`) for whoever picks this
back up.

**`R2.7` (Workbench and storage container) shipped — see `DONE.md`.** Bookkeeping
gap: the code landed on `main` (`188853c`, `483b4a8`) before this entry was
ever moved here; recorded after verifying 362/362 tests green on current `main`.

**`R2.8` (Creature bed) shipped — see `DONE.md`.**

### R2.9 ▶ Play gate — does building a small home feel useful and enjoyable?
§33 criteria 6 and 7.

---

## Phase 3 — art debt and persistence

**`R3.0` (re-process the three humanoid GLBs through the fixed pipeline)
shipped — see `DONE.md`.** The literal Meshy-refetch path was unavailable
(the pre-animation rig output was never committed and this ran in a fresh
container with no Meshy key); fixed `animate_humanoid.py` to work from the
currently-installed GLBs instead, by stripping any pre-existing animation
before authoring fresh clips. Verified structurally (the `Armature` node's
malformed `0.01` scale is gone from the exported file) as well as by
`smoke_art`. The trainer's undersized backpack (HANDOFF §6) is unchanged,
same as before — a mesh-volume edit outside this item's scope.

**`R3.1` (save and load) shipped — see `DONE.md`.** `SB9` did not exist yet
to carry (Phase 3.5 is still ahead of this in the file), so version 1 has no
progression-flag section; whoever ships `SB9` owns the version bump this
item's own brief anticipated. One narrower gap opened below.

**`R3.1-remainder` (a placed storage chest's own contents now survive save/load) shipped — see `DONE.md`.**

**`R3.2` (death satchels persist across save/load) shipped — see `DONE.md`.**
`GameState.death_satchels` joins `placed_buildings` as its own small array
(`{position, state}`, `state` in `storage_state.gd::save_data()`'s own
shape), joined at save format VERSION 4. `player_death.gd` gained the same
group-based sync/restore seam `build_placer.gd` already had for placed
buildings: every live satchel joins a `"player_death"`/`"death_satchel"`
group pair, `GameState.save_game`/`load_game` walk it the same way they
already walked `"build_placer"`. A save written before this migrates to an
empty list — no death satchel can exist in a save that predates the system
that persists them, the same "nothing to migrate FROM" answer `VERSION 1 -> 2`
already gave the map.

**`R3.3` (player death and respawn) shipped — see `DONE.md`.**

---

## Phase 3.5 — reusable progression infrastructure (spec Phase B)

`docs/MEADOWS_PROGRESSION_SPEC.md` §15, §16, §35. Everything in the Meadows
chapter (Phase 8) stands on what this phase builds.

**The two NPC items that used to live here moved.** `SB7` and `SB8` are now
`NP1` and `NP2` in Phase -0.55, because the owner's NPC board arrived and made
them art-direction work that the whole cast waits on, not progression plumbing.
Their headings below are collapsed, not open. What is left here is state:
`SB9`, `SB10`, `SB11`.

Placed *after* Phase 3 on purpose: `R3.1` writes the first save format and it
is "versioned from the first write". `SB9`'s flags belong in version 1, or
adding them later costs a format bump for nothing.

**SB7 COLLAPSED into `NP1`, which supersedes it and now runs far earlier
(Phase -0.55).** They are the same work, but the owner's NPC board asks for more
than this entry did: per-material overrides are necessary and not sufficient,
because the board specifies **hair variants sharing head topology and
accessories as separate toggleable mesh parts**. Colours alone cannot express
that. `NP1` carries this entry's acceptance test forward unchanged and adds
visible accessories to it. Evidence kept:

Original entry — Per-material NPC variants, not one global tint:

Spec §21. R7.2 already proved the idea — Mira, Oskar and Tam in the square are
Grandpa's and the trainer's rigs with a `tint` in `art.json` — but `tint` is a
single multiply over every surface (`character_model.gd::_apply_tint`), and §21
names that exact failure: "do not recolor everything with one global tint if it
destroys material separation." Grow the `art.json` block into per-material
overrides (hair, jacket, trousers, boots, belt, pack visibility) keyed by
surface or material name, with the existing single `tint` still honoured so
nothing already placed breaks. Done when: two NPCs on the same rig differ in
jacket and hair colour independently, and neither is a flat wash of one hue.

**SB8 COLLAPSED into `NP2`.** Identical work, moved to Phase -0.55 with `NP1`
underneath it. One thing changed since this was written and `NP2` records it:
the board's Team Tether Grunt base means the "keep the main-character base for
civilians until §22's optional grunt base exists" hedge below now has an end
date — `NP4` generates that base. Until then this entry's advice stands, and
`NP2` repeats it. Evidence kept:

Original entry — Team Tether rank palettes on the Warden rig:

Spec §21, §35, §36. The Warden's rig is the faction's base body. Four rank
tiers as data on top of `SB7`: grunt (charcoal, muted forest green, minimal
gold), relay/field officer (deeper green, bronze trim), captain (dark green,
brass, one regional accent), Warden (richest materials, cream fur mantle,
strongest gold — unchanged). Rank has to be readable at gameplay distance
without a nameplate, because the geometry repeats. One caution the spec hedges
on and this item should not: §21 offers the **main-character** base for "junior
Team Tether personnel", but that rig is the player's own body and enemies
wearing it will read as clones of the player. Prefer the Warden base for every
faction NPC; keep the main-character base for civilians until §22's optional
grunt base exists. Done when: the relay captain, a regional captain and the
Warden stand in one frame and a blind critic ranks them correctly by seniority.

**`SB9` (the smallest progression-state system that survives the chapter) shipped — see `DONE.md`.** No consumer wired up yet — `data/progression/`
(objectives as data) and the first real caller are left for whoever picks up
`SB10`/`SB11` against a real objective list, rather than this item guessing
its shape blind.

**`SB10` (the generic item-gate mechanism, `road_gate.gd` refactored onto it) shipped — see `DONE.md`.** The three specific gates the spec names (South Bridge Key, Mill Bridge Gear, three Sigils) still want geography that doesn't exist yet — `SC14`/`SE22`/`SF34` own building those, and should reach for `item_gate.gd` directly rather than re-deriving the pattern.

**`SB11` (one tracked objective, and a two-list quest log) shipped — see `DONE.md`.** `data/progression/objectives.json` (Main Story / Local Requests, one real entry today — the road gate) plus `scripts/world/quest_log.gd`, a pure reader over `SB9`'s flags with no branching/prerequisites/counters. `Game.objective_text` now recomputes from it whenever `progression.revision` moves, replacing the never-written placeholder; a new Quests tab (`scripts/ui/tab_quest_log.gd`) shows both lists. `smoke_menu.gd` drives the real tab and proves the HUD line changes live, no scene reload.

---

## Phase 4 — combat, progression, the team

**`R4.1` (Levels and XP) shipped — see `DONE.md`.** The mechanic itself
(level/XP curve, combat-XP award, wild-level independence from player level)
was already built by `D30` and never recorded here or in `DONE.md`; this
pass verified it against §11 directly (full suite, 600/83762/0 failed,
before and after) and found one real spec gap — the level cap was a
tunable `30`, §11 says "1–50" — fixed to `50`. **One honest remainder**:
§11's "smaller XP can come from exploration and bonding activities" has no
implementation; combat is currently the *only* XP source (trivially
"primary" by default, not by design). Not built this pass — which
activities and how much XP is a real content/balance call, not a
mechanical follow-on, so opened as `R4.1-remainder` below rather than
invented here.

**`R4.1-remainder` (a second, smaller XP source: resting at camp, the bonding half) shipped — see `DONE.md`.** §11 says "can come from exploration and bonding activities" (permissive, not a checklist), so one real source clears the bar; picked resting because `camp.gd::_pass_the_night()` was already the single call site touching the whole party at once. **Exploration XP was not built** — no equivalent single hook exists yet (nothing today marks "the player discovered something new"), so that half stays open rather than being invented against no real trigger. Also found and deliberately not touched: `bond.per_day_in_party` in `data/config/progression.json` has been dead config since `D30` — never read anywhere in the codebase — and would wire into this same rest call site if anyone wants "resting also deepens bond" as its own item.

**`R4.2` (core stats and per-instance individuality) shipped — see `DONE.md`.** Both halves of GAME_DESIGN.md 11's "Individuality" section: real per-instance stat variance (IV-like rolls on hp/attack/defence, shown as stars/bars, never exact numbers) and a flavour trait system (one at creation, a hidden second revealed once bond is maxed). See `docs/decisions/D37` for why traits stop at flavour/display and carry no numeric combat effect.

**`R4.3` (named moves per species: quick/charged, power multiplier, wired into combat and the Team screen) shipped — see `DONE.md`.** This line's own "`data/moves/` is empty" was stale: `D30` (2026-08-13) already built the data-driven moves layer — `data/moves/moves.json`, `scripts/creatures/move_db.gd`, every species pointing at one quick/one charged id — and wired it into `combat_manager.gd`'s damage calc, `combat_hud.gd`'s in-fight display and `tab_creatures.gd`'s Team screen, with a full test file (`tests/test_moves_data.gd`, 11/11) already covering it. Verified rather than rebuilt: ran the full local suite (645 tests, 83864 assertions, 0 failed) to confirm. `D30` itself explicitly punts spec §13's "2 known, 1 equipped, swap moves" 4-slot system as deliberate future scope, not required here — a species carries exactly one quick and one charged move today, by owner decision, not by gap.

**`R4.4` (TMs and teaching moves) shipped — see `DONE.md`.** A TM found in the world permanently unlocks its move as teachable (never consumed — the same TM can teach any number of compatible creatures); species compatibility is a per-TM list, same-type only this pass. D30's one-quick/one-charged-slot decision stands — teaching replaces whichever slot the move belongs to, not a 4-slot system.

**`R4.5` (Tuskroot's real model) verified and closed — see `DONE.md`.** It
was already a real rigged/animated model, not the songbird stand-in — the
open question was whether `smoke_art` actually proved that, and it didn't:
Tuskroot never spawns wild (D13, the Meadows' one evolution, no evolution
system built yet to trigger it), so the test's existing world-check never
saw it. Extended `smoke_art.gd` to build any `evolves_from` species directly
and run the same height/clip checks the wild-spawned creatures get.
Confirmed clean: 2.15m model against its 2.15m collider, all six clips
present. No generation or graft needed.

### R4.6 — Evolution mechanic and ceremony
`model: opus` · `tests: test_evolution_links, smoke_evolution` (new)
Mudsnout → Tuskroot gets a rope pulled at last. D20 fixed the intent: the
first evolution the owner sees will be a creature they caught as a piglet and
have carried since — build the ceremony knowing that. Honour D17 (the evolved
form is always larger — at D19 scale that is 1.55 → 2.15). Blocked on R4.5:
no ceremony with the stand-in.

**Spec §4 (D23) fixes the shape.** Mudsnout → Tuskroot is **the** Meadows
evolution line and no other normal species evolves — it exists to teach the
limited evolution system. Recommended: a level requirement (~15), a bond
requirement, and one Heartstone-type item from the Burrow Warrens' optional
deep branch (`SD17`). All three numbers and the item name are tunable per
`CLAUDE.md`; do not let a working name become a permanent mechanic.

### R4.7 — Bond and best creature · `model: sonnet` · `tests: test_bond` (new) · §12

**`R4.8` (fainting and home recovery) shipped — see `DONE.md`.** The mechanical half: a placed `creature_bed` now has a real interaction (`R2.8`'s own deferred brief) that revives/tops up any party member and grants the same flat rest bonus XP camp's overnight rest already gives. "Unavailable state" and catching-refuses-fainted were already built and are tested here as the baseline this recovers from, not as new code. Deliberately not built: a live in-world animation cue for "visible creature rest behaviour" — that is visual-affecting work needing a genuinely blind `visual-judge` pass, out of this item's budget; clear on-screen text stands in instead.

### R4.9 — Orb economy and tiers · `model: sonnet` · `tests: test_catch_math` · §15
Spec §3 Band 2: the improved orb tier is the **first** thing Rootstone
(`SD18`) buys. Build the tier ladder here; `SD18` supplies the material.
Note: the old "rework orb aiming" item that sat beside this was **absorbed by
the overhaul** — trajectory preview sharing `_release()`'s math, wired
sensitivity, fine-aim exponent, piecewise snap assist, cancel during windup.
Whether it now *feels* satisfying (§33 criterion 3) is R0.11's and R4.12's
question, not a build task.

### R4.10 — The release ceremony · `model: fable` · `tests: test_party, smoke_release` (new)
`party.add()` refuses a sixth creature and there is no ritual. The slice
warns it must not be "a generic delete dialog" — it is the emotional payload
of the five-creature rule, and since D18 the five-cap has a physical body in
the world: the belt Grandpa gave you has five holders.

**Spec §5 states the precondition, and it is not work on this item.** The
ceremony only lands if the Meadows has already produced more creatures worth
keeping than five slots — a Ground tank, a Water counter, an Air attacker, a
rideable Meadowhart, a rare-trait catch, the Mudsnout line, a favourite first
catch. That is a content requirement on Phase 8's bands, not on R4.10, and the
first biome must not be allowed to dodge the tension.

### R4.11 — Combat animation bug · `model: sonnet` · `tests: smoke_combat`
Owner-reported: creatures "static posed and sliding around". Ruled out by
measurement — clips exist, drive real bone motion, the animator is ticked
every physics frame with real velocity, loops are set at runtime. Best
remaining lead: Terrapup's idle moves bones by 0.088 against 1.53 for walk,
and a creature in combat is in idle almost always. **Next step is a recorded
fight logging the clip playing against the body's speed — not more
reasoning.** Re-check against the owner's R0.11 impressions first; the feel
pass (auto-face, lunge timing) may have changed the report.

### R4.12 ▶ Play gate — is repeated combat enjoyable, not merely functional? §33 criterion 2.

---

## Phase 5 — the living world

**R5.1 (day/night cycle) relocated to Phase -0.5** — owner directive,
2026-08-10: visual-pass work runs before Phase 1 onward.

### R5.2 — Rain, fog and cloud variants · `model: sonnet` · `tests: none`

### R5.3 — Spawn conditions · `model: sonnet` · `tests: test_spawns`
At least one nocturnal (Duskhush) and one weather-gated, per M10. Extend
`spawns.json`'s schema per D20 — this is the task that decision deliberately
deferred the fields for. Tests keep addressing species through the `roles`
block, never ids.

**Spec §13 supplies the area table**, which is what makes deeper regions change
the team you can build: lower fields Bramblebun / Mudsnout / Pipwing; grove
Trailpup / Duskhush at night / Burrowback; quarry and warrens Burrowback /
Mudsnout / strong Ground spawns; river Paddlenewt / Mosshell / Brooktail /
Reedwing; upper ridge Galecrest / Meadowhart / stronger Trailpup. Duskhush is
already the nocturnal example above. No random battle screens, ever (§13).

---

## Phase 6 — riding

**R6.1 and R6.2 are worked inside Phase 8's section 8d** — spec §3 Band 4 (D23)
makes riding a Band 3 / early Band 4 unlock gated on a Riding Saddle whose
components cost Rootstone and Ironwood, which is a progression step rather than
a free-standing milestone. Their briefs are kept here; the ordering is there.
R6.3's play gate stays where it is.

### R6.1 — Riding · `model: opus` · `tests: smoke_riding` (new) · M12
Mount/dismount, generic saddle, riding stamina, a clear advantage over
running, and no species-specific saddle clutter.

### R6.2 — Meadowhart as the rideable creature; craftable generic saddle
`model: sonnet` · `tests: test_build_catalogue`
Spec §3 Band 4 confirms Meadowhart as the rideable Meadows creature and prices
the saddle in Rootstone/Ironwood components (`SD18`, `SF31`). Riding should
dramatically improve *revisiting* known areas — that is the value it is being
sold on, not raw speed.

### R6.3 ▶ Play gate — does riding make exploring better?

---

## Phase 6.5 — locomotion quality rebuild (owner's quality plan, `MQ1A`/`MQ1B`)

**Added 2026-08-15.** `ralph/planning/MEADOWS_QUALITY_REBUILD_PLAN.md` §1's
build order puts a full locomotion rebuild and a movement/catching checkpoint
strictly before any large-scale Meadows world construction (`R7.3`/`MQ2A`).
Nothing in the backlog previously encoded that ordering — `R7.3`'s own text
cited `R0.11` (closed, but its shipped scope was input-glyph/menu fixes, never
locomotion feel) and `R6.3` (a play gate, which per this file's own legend and
`D21` does not block the loop) as having already answered "is movement fun."
Neither actually had. These three items exist to make the plan's ordering
self-enforcing for a lane working top-down, not just something a careful lane
notices by separately reading the plan.

### MQ1A — Full locomotion motion rebuild · `model: fable` · `tests: none` · quality plan §2
**START WITH FABLE.** Do not hand this to a lesser tier to inherit the current
procedural gait and tune it further — assume the current clips may themselves
be the ceiling (already tuned repeatedly, still visibly unnatural). Fable
reviews fresh walk/run renders from rear, side, front three-quarter, rear
three-quarter, start, stop and turn, then decides what's fundamentally wrong
and whether to rebuild clips procedurally, author/import better ones, or use
another allowed approach. Target: grounded, weighty, readable, natural enough
the player stops noticing it — anatomically correct arm/leg opposition,
natural stride and cadence, a clear walk/sprint distinction, no foot skating
on flat ground. Fix the shared humanoid locomotion foundation once — the
trainer, Grandpa, Warden and villagers all ride on it, so don't leave any of
them on visibly worse motion than the trainer ends up with.

**Done when** a fresh blind visual critic, given full walk-cycle and
sprint-cycle contact sheets plus rear/side/start/stop/turn captures, does not
flag broken arm/knee/elbow anatomy, floatiness, robotic cadence, or obvious
flat-ground foot skating. If the critic still calls the motion fundamentally
wrong after multiple implementation rounds, stop micro-tuning that approach —
return to Fable and restart the motion solution rather than iterate further.

### MQ1B — Terrain adaptation and foot placement · `model: fable` · `tests: none` · quality plan §3
**START WITH FABLE.** Depends on `MQ1A` closing first — don't build terrain IK
on top of a base cycle that hasn't already passed its own blind critique.
Evaluate and implement the minimum robust solution for uphill, downhill,
cross-slope and uneven-ground walking, small terrain height variation, and
idle stance on slopes (foot planting/IK, orientation to ground normal, pelvis
compensation, stance-phase locking as needed — don't add complexity for its
own sake).

**Done when** blind rendered/play inspection on flat and sloped test terrain
shows no gross foot penetration, no obvious hovering, no sustained slope
skating, no knee inversion, no broken pelvis motion, no visible IK snapping,
and walk/run still reads as natural.

### MQ1-gate ▶ Play gate — movement + catching owner checkpoint · quality plan §4
Before `R7.3` (large-scale Meadows world construction) begins: does `MQ1A`/
`MQ1B` actually read as fixed in real play? And separately, judged on its own
current merits (trajectory preview, aim-assist already shipped, not old
complaints) — can the player predict the throw before release, does aiming
feel controllable, is the tutorial/common catch experience satisfying? Only
open a new catch-probability task if play still shows a real problem. Same as
`R6.3`: this is an owner judgment call, not something a lane can pass/fail
itself — per this file's legend and `D21` it does not block the loop on its
own. What actually keeps the loop from reaching `R7.3` first is `MQ1A`/`MQ1B`
sitting above it in this file's top-down order; this gate exists so the
owner's read on the result is captured and visible in `BLOCKED.md`, the same
way `R6.3` already works for riding.

---

## Phase 7 — the village lives, the meadow reads

**R7.1 (wayfinding polish) and R7.2 (villagers and interior polish)
relocated to Phase -0.5** — owner directive, 2026-08-10: visual-pass work
runs before Phase 1 onward.

### R7.3 — Grow the authored space toward the 4–8 hour arc · `model: opus` · `tests: smoke_traversal` · M7, §30
The village and paths were the seed; §30 is explicit — dense rather than
empty, and do not pick a kilometre count before movement is fun. That is now
gated on `MQ1A`/`MQ1B` and the movement+catching checkpoint in Phase 6.5, per
`ralph/planning/MEADOWS_QUALITY_REBUILD_PLAN.md` §1/§4 — not `R0.11`/`R6.3`
(neither actually answered it; see Phase 6.5's header for why). Do not start
this item until Phase 6.5's `MQ1A` and `MQ1B` are closed.

**This is now the chapter's capacity item, and the single largest unpriced
piece of D23.** `terrain_playground.json`'s own first line says it is *a test
area, not the Meadows*, and 512 m on a side cannot hold spec §3's five bands, a
quarry, a dungeon, a major river, a mini-stronghold, an upper region and seven
perimeter spokes. Growing it costs a terrain rebake, more Terrain3D regions and
a real performance question on the Ally — none of which is budgeted anywhere.
R7.3 owns the *space and the bake*; the individual areas belong to `SD16`,
`SD17`, `SE21`, `SE23` and `SF31`. §30's rule still governs the number: prove
movement and riding are fun first, then size it.

### R7.4 — Map and minimap · `model: sonnet` · `tests: smoke_menu` · §23
The `map` action is bound, labelled and rebindable, and **read by nobody**.
Spec §16 adds the rule: the map reveals explored areas and landmarks and never
reveals everything automatically. The tracked-objective line and the two-list
quest log are `SB11`, not this item — R7.4 owns the map itself.

**Promoted, 2026-08-11 — see Phase -0.85 for why.** This item's text stays
here; Phase -0.85 only points at it. The minimap is unblocked and can be
picked up from either location.

### R7.5 — Food buffs · `model: sonnet` · `tests: test_food` (new)
Buffs only. No starvation meter, ever.

### R7.6 — Berry plot and simple fishing · `model: sonnet` · `tests: test_farming` (new)
Deliberately shallow — §32 excludes deep farming.

### R7.7 — Player HP and armour slot architecture · `model: sonnet` · `tests: test_player_hp` (new)

---

## Phase 8 — the Meadows chapter (spec Phases C–G)

This was five items called "Team Tether and the culmination". `D23` turns it
into the chapter: five bands, two material tiers, physical gates, roughly
12–17 trainer battles, a dungeon, a mini-stronghold, a rescue, and a world
event. The `S<letter><number>` ids trace straight back to a numbered step in
`docs/MEADOWS_PROGRESSION_SPEC.md` §38, so a branch name carries its own
provenance.

**Why the whole chapter sits this late:** it consumes levels and XP (R4.1),
moves (R4.3), riding (R6.1) and trainer combat (R8.1). That is build order, not
play order. The honest cost is that the owner will not play a Band 1 trainer
battle for a long time — if that is the wrong trade, the cheap thing to hoist
is `R8.1` + `SC12` + `SC13` once R4.1/R4.3 exist. **That is an owner call, not
a firing's.**

### 8a — Lower Meadows (spec Phase C)

### R8.1 — World trainer encounter and team combat · `model: sonnet` · `tests: smoke_trainer_battle` (new)
Trainer-owned creatures **cannot** be caught. Spec §12 sizes what this has to
carry: 12–17 battles across the chapter, spread over meaningful locations
rather than one long trainer tunnel. It is the substrate for everything in 8a
through 8e, not a single encounter.

### SC12 — Mira, Oskar and Tam become the three Band 1 trainers
`model: fable` · `tests: test_dialogue_runner`
Spec §3 Band 1 and §35. **These three already exist** —
`data/config/village_npcs.json` places Mira, Oskar and Tam around the well with
greetings in `data/dialogue/village.json`, and the spec names the same three
("possible existing village NPCs can fill these roles if their existing
characterization fits"). Do not add three more people to the square. Mira
becomes the Meadow Keeper, Oskar the Bridgehand who holds the South Bridge
mechanism (he is already `villager_keeper`), Tam the Field Scout. Repalette
through `SB7`, extend their conversations, give each a battle offer. Done when:
all three are challengeable and none of them is a newly-placed body.

### SC13 — The three Band 1 trainer battles, each with a distinct lesson
`model: sonnet` · `tests: smoke_trainer_battle`
Spec §3 Band 1, §12. Mira is the introduction, Oskar is the gate, Tam teaches
switching and type awareness. Uses R8.1's system, `SB9`'s defeated flags and
`SC15`'s rewards. Recommended natural team level by the time the bridge opens
is roughly 5–8 — **guidance for tuning, never a check the game performs**
(§3, §19). Done when: each can be beaten once, sets its flag, and cannot be
re-fought into an XP faucet.

### SC14 — The South Bridge, and the key that opens it
`model: sonnet` · `tests: smoke_traversal`
Spec §3 Gate 1. The deeper Meadows is visible across an old bridge the player
can walk to at any level and cannot cross. Beating Oskar yields the South
Bridge Key (`SB10`); the bridge is a mechanism, not a message. Done when: the
crossing is visible from the village, blocked without the key, open with it,
and never explains itself with UI text.

### SC15 — Trainer battles pay out
`model: sonnet` · `tests: test_progression_state`
Spec §17 P1 step 9. A defeated trainer grants XP plus one authored reward — an
item, a TM, a recipe or a key — recorded against `SB9`'s flag so it cannot be
farmed. Done when: beating a trainer twice pays once.

### 8b — Rootstone (spec Phase D)

### SD16 — The Old Quarry
`model: sonnet` · `tests: smoke_traversal`
Spec §3 Band 2, §32. Rootstone deposits, old foundations, and the first
physical evidence Team Tether is routing something beneath the region —
conduits, excavation, energy-routing hardware, material moving toward the
stronghold. Evidence, not an explanation: §32's reveal ladder is explicit that
nobody here knows about the legendary. Done when: the quarry is reachable past
the South Bridge and yields Rootstone.

### SD17 — Burrow Warrens, the required dungeon
`model: fable` · `tests: smoke_traversal, smoke_combat`
Spec §3 Band 2. A compact cave: aggressive Ground creatures, Rootstone
deposits, chamber navigation, a guardian fight, one rare side branch. **The
guardian is a strong normal species — the spec says outright not to invent
another legendary**, and §20 forbids the model anyway. The optional deep branch
is where the Mudsnout evolution item lives (R4.6). Done when: it can be
entered, cleared, and cleared only once for its story reward.

### SD18 — Rootstone, the first progression tier material
`model: sonnet` · `tests: test_recipes`
Spec §10. Two tier materials in the entire biome — Rootstone then Ironwood — on
top of wood, stone, fiber and berries. Rootstone **upgrades what already
exists** rather than opening ten new systems: better orb tier (R4.9), workbench
upgrade (R2.7), better gathering tool (R2.1), the saddle component (R6.2), a TM
component, a modest camp/storage improvement. §32's ban on a large crafting
tree is the boundary. Done when: every recipe that consumes Rootstone improves
something the player already owns.

### 8c — the river and the relay (spec Phase E)

### SE21 — A real river divides the deeper Meadows
`model: fable` · `tests: smoke_traversal`
Spec §3 Band 3. Also closes a question the visual pass left open:
`R7.1-remainder-2`'s second bullet found "no middle-distance layering anywhere
in the set (no tree lines, ridgelines, or water)" and asked outright whether a
water feature would do more for depth-reading than more vegetation tuning. This
is that feature, and it is load-bearing for the story too. Done when: the river
reads as a landmark from the ridge and cannot be crossed except at authored
points.

### SE22 — Old Mill Crossing, seized and then restored
`model: sonnet` · `tests: smoke_traversal`
Spec §3 Band 3. Team Tether has disabled the crossing and taken the person who
knows the mechanism. Freeing them (`SE27`) yields the Mill Bridge Gear
(`SB10`) and the crossing opens for good. Done when: the same bridge is
impassable before the rescue and passable after, with no menu in between.

### SE23 — The Tether Relay Station
`model: fable` · `tests: smoke_traversal`
Spec §3 Band 3. The first mini-stronghold: a natural site partly
industrialised, a compact traversal and environment challenge, and the moment
Team Tether stops being something Grandpa described and becomes a threat the
player has personally confronted. R8.2's visual-language brief is used here
first, at small scale. Done when: it can be entered, fought through, and its
local tether/control equipment disabled.

**The "local tether/control equipment" now has a board** —
`docs/art/reference/14_Relay_Apparatus.png`, owner-supplied 2026-08-11 and
labelled Band 3, so it is drawn for exactly this item. It is one of the three
hero objects D24 reserves Meshy for, and it is `lane: art`. Its artist note is
the build spec rather than flavour: *modular construction, core and rings
serviceable, conductor arms and manifolds replaceable*, with five labelled
subassemblies (tether core, conductor ring, control console, output manifolds,
grounding base). The console is the thing the player disables, and the board
details it down to individual routing levers.

### SE25 — Relay trainers and the relay captain
`model: sonnet` · `tests: smoke_trainer_battle`
Spec §3 Band 3, §12: two or three Team Tether trainers and a relay captain, all
on `SB8`'s rank palettes — the captain visibly outranking the trainers and
visibly below the Warden. Done when: the captain's defeat sets the flag `SE27`
waits on.

### SE27 — Free the captive
`model: sonnet` · `tests: test_dialogue_runner`
Spec §3 Band 3, §35. The captive ranger/researcher is built on the civilian or
main-character base — **not a new model** (§20/§21 apply to the whole cast).
Rescue scene, the Gear, and the first testimony that the region's isolation is
made rather than natural. They return to the settlement afterward (`SG46`,
§14). Done when: rescued, the NPC exists in the village and their dialogue has
changed.

### SE30 — The reveal ladder, laid in
`model: fable` · `tests: test_dialogue_runner`
Spec §32. Villagers know travel is controlled and trade restricted, and no
more. The quarry shows conduits. The relay shows energy routing and a captured
investigator. The captive knows the separation is artificial but **not** that a
legendary is the source. Grandpa's opening must not spoil any of it — §32 and
§1's "do not dump the entire plot in one speech" are the same instruction.
Done when: no line of dialogue before the stronghold names the legendary as the
power source.

### 8d — Upper Meadows (spec Phase F)

**R6.1 and R6.2 (riding, Meadowhart, the generic saddle) are worked here** —
spec §3 makes riding a Band 3 / early Band 4 unlock priced in Rootstone and
Ironwood. Their briefs stay in Phase 6; the ordering is this.

### SF31 — Ironwood, the second preparation tier
`model: sonnet` · `tests: test_recipes`
Spec §3 Band 4, §10. Supports stronger crafting, riding equipment, better
utility and final-stronghold preparation. It does not need to literally be
iron. Keep the economy small and readable. Done when: nothing needed for the
stronghold requires a third new material.

**`SF33` (the Tether Energy Pylon hero asset, generated and ledgered; two of the seven spokes — `river_gorge` and `storm_road` — dressed with the full severed-rift grammar) shipped, partial — see `DONE.md`.** `model: fable` dispatch, done in the authoring agent's own session with no subagent spawning available, so its blind-pass rubric was self-administered rather than an isolated critic — recorded honestly in `DONE.md`, same disclosure pattern as `OF10-remainder`. The other five spokes continue in `SF33-remainder` below.

**`SF33-remainder` (rift dressing for the other five spokes — `mountain_trail`, `high_pass`, `cliff_road`, `stone_gate`, `blighted_road`) shipped — see `DONE.md`.** All seven spokes now carry the severed-rift grammar. `model: fable` dispatch, verified at two layers: the fable-authoring session self-administered its own pass (no subagent tool in that session, same disclosure `SF33` carries), and the orchestrating session separately dispatched a genuinely isolated critic — both real, both credited in `DONE.md` (an intermediate draft of this entry conflated the two into "no critic ran at all"; corrected). Found and fixed: three occluded/mis-framed viewpoints, a rigid-elbow cable artefact, and a real material bug (the Team Tether wall/gate colour shading to pure black under `gl_compatibility`, named unprompted by the isolated critic). Two honest, disclosed remainders: the fixed material still reads dark by design (measured, not eyeballed — see `DONE.md` for why brighter would be the wrong fix), and `cliff_road`'s notch itself never reads in a player-height still after four framings; the convergence stop and the reason are recorded in the capture tool's own comment.

### SF34 — Three regional captains, three Sigils
`model: fable` · `tests: smoke_trainer_battle`
Spec §3 Band 4. Field Captain (Ground team, Field Sigil), Ridge Captain (Air,
Ridge Sigil), Riverwatch Captain (Water/balanced, River Sigil), all on `SB8`'s
captain palette with one regional accent each. The three physical Sigils open
the Hall approach through `SB10`. This is what gives trainer battles direct
progression meaning. Natural team expectation entering this band is roughly
10–16 — **tunable, and never player-scaled** (§3). Done when: the approach is
sealed at 2/3 and open at 3/3, and the count is visible on `SB11`'s tracker.

### 8e — the stronghold and the first reconnection (spec Phase G)

**The Tether Chamber's centrepiece has a board.**
`docs/art/reference/15_Legendary_Tether_Machine.png`, owner-supplied
2026-08-11, headed WARDEN STRONGHOLD — it is drawn for this section. ~15 m
against its own 0–20 m scale bar, so it is architecture rather than a prop and
the chamber has to be built around it. It is `lane: art` and one of the three
hero objects D24 reserves Meshy for.

**Read this before generating it.** The board shows a legendary bound inside
the containment ring, because that is what the machine does to legendaries —
it is the D23 macro-story drawn. **The board licenses the machine, not its
occupant.** `D23` §20 forbids new creature meshes at any credit balance, so
the bound creature is an existing roster asset or VFX. Generating the whole
board as one asset breaks a hard rule while appearing to follow one.

### R8.2 — Authored stronghold route · `model: sonnet` · `tests: smoke_traversal`
Visual language: a sacred natural site industrialised by Tether. R7.1's ridge
silhouette is the promise this pays off. Spec §8 gives the interior: Outer
Works → Courtyard / Hall Approach → Tether Chamber Approach → Warden Arena →
Legendary Chamber, target first clear 30–60 minutes. **Not a giant puzzle
dungeon** — §8 rules that out unless separately decided. Note the same
industrialised-sacred-site language is used twice: first at `SE23`, then here at
full scale.

### SG38 — The stronghold trainer gauntlet
`model: sonnet` · `tests: smoke_trainer_battle`
Spec §8, §12: a patrol trainer at the Outer Works, a courtyard fight, an elite
before the Tether Chamber, and a recovery opportunity before the Warden. Two to
four battles across the five named spaces. Done when: a prepared team clears it
inside an hour and an unprepared one does not.

### R8.3 — The Warden boss fight · `model: fable` · `tests: smoke_boss` (new) · M14
His face is still painted, not modelled — needs a real sheet before this is
judged (HANDOFF §6). Note §20 covers *creatures*; a Warden face pass is still
legal under §22's budget. Spec §33 gives the character: he sincerely believes
separation prevents chaos and that ordinary people do not understand the risks.
Not a moustache-twirler. His line is closer to "You don't understand what these
barriers are holding apart" than "You cannot stop me."

### SG40 — The reveal: the legendary is the power source
`model: fable` · `tests: test_dialogue_runner`
Spec §28, §32, §33. Inside the stronghold and nowhere earlier — `SE30` holds
the rest of the ladder. The Warden warns rather than gloats, and genuinely
believes freeing it is reckless. Done when: the reveal happens in the
stronghold and the player makes the choice knowing what it costs.

### R8.4 — Free the legendary; it offers to join; triggers the release ceremony if full · `model: fable` · `tests: smoke_boss`
Spec §28's order, which is not optional: reach the chamber → the legendary is
freed → it **voluntarily** offers to join → the five-creature decision if the
roster is full (R4.10) → the tether machinery fails → `SG44`'s world event.

### SG44 — The first Tether Rift collapses and the world gets bigger
`model: fable` · `tests: smoke_boss`
Spec §27, §28, §30. The machinery fails, the exterior event runs, and one
severed spoke visibly reconnects — a distant landmass moving closer, a ravine
contracting, roots bridging a gap, a storm wall dissipating. **The carve-out is
not negotiable: this is a distant, non-enterable view.** `CLAUDE.md` forbids
Biome 2 work until the Meadows exit gate and D23 holds that rule over this
step; the spec's own §19 non-goals ("all seven future biomes") agree. No second
biome's terrain, spawns or species — the reconnected road still ends at a
believable barrier. If that reads as an unsatisfying payoff, it is a
`BLOCKED.md` question for the owner, not a licence. Done when: standing where
`SF33` put the seam, before and after the Warden, gives two visibly different
horizons — and the player still cannot walk into the next region.

### SG46 — The Meadows answers
`model: fable` · `tests: test_progression_state`
Spec §9. Barriers deactivate, patrol density drops, the rescued NPC is back in
the settlement, villagers acknowledge the victory, stronghold effects change,
the legendary is no longer tethered, and at least one outward spoke gains new
dialogue. Done when: no part of the region is visually or conversationally
identical to how it was before the Warden.

### R8.5 — The legendary's superior ride ability · `model: sonnet` · `tests: smoke_riding`
The tier above Meadowhart's (R6.2), not a parallel system.

### R8.6 — The larger mystery and future-biome hook · `model: fable` · `tests: test_dialogue_runner`
No longer open-ended: the mystery is spec §23–§31, and `SA4`'s seven spokes are
its physical hook. `GAME_DESIGN.md` §3's "the exact endgame motive remains
intentionally open" is false as of D23 and is amended there.

---

## Phase 8.5 — pacing and the chapter's own gate (spec Phase H)

### SH47 — Tune the chapter to 4–7 hours
`model: sonnet` · `tests: none`
Spec §17 P7, §38 Phase H. XP curve, trainer levels, material costs, travel
time, spawn density, and the specific instruction to **remove dead walking**.
Distinct from R9.1 (input feel and combat cadence) and R9.3 (performance on
hardware): this is arc pacing, and it can only be judged once 8a–8e exist.
§11's test of a good grind is the standard — "I know a harder challenge is
ahead, so I am deliberately improving my five", never walking in circles
killing identical weak enemies to inflate a number. Done when: a full run is
timed end to end and lands inside 4–7 hours.

### SH53 ▶ Play gate — the P0 fixes are actually gone on real hardware
`model: haiku`
Spec §38 step 53, §18. Ten minutes of a fresh Windows launch with mouse and
keyboard, never once having to think about cursor capture — through a menu
open and close, the name-entry screen, and an Alt-Tab. Then: the door cannot be
crossed before Grandpa, and no bearing walked from spawn falls off the world.
**This is the on-device confirmation `RB1`, `RB2` and `RB4` all still owe** —
each is closed on diagnosis and a real fix, none on the owner's own hands.

### SH54 — Audit: nothing in the chapter assumed new creature credits
`model: haiku` · `tests: none`
Spec §38 step 54, §20. Walk every item shipped for this chapter and confirm
none of them installed, requested or planned a new creature mesh. Cheap, and
worth doing once at the end, because the constraint is a budget the owner holds
and a single quiet violation spends it.

---

## Phase 9 — polish gate (M15)

### R9.1 — Input feel, combat cadence, catch feel, camera · `model: sonnet` ▶
### R9.2 — Controller UI readability on the Ally · `model: sonnet` ▶
### R9.3 — Performance on target hardware · `model: sonnet` ▶

**R9.4 (visual cohesion pass) relocated to Phase -0.5** — owner directive,
2026-08-10: it now serves as that phase's own checkpoint, run before
Phase 1 onward rather than at the end.

### R9.5 ▶ **The exit gate.** All twelve of `GAME_DESIGN.md` §33. Only the owner can call it.

---

## Found along the way — small, unscheduled

**`smoke_aggression`'s post-`LP7` flake root-caused and fixed — see
`DONE.md`.** Two independent investigations ran on this in parallel and
found different pieces of the same picture. One (`LP7-remainder`, this
branch) caught the freeze directly via a physics-shape query at the
frozen position: `CharacterBody3D.move_and_slide()` reporting a false
`is_on_wall()` against ordinary Terrain3D ground (5-11° grade, nowhere
near `floor_max_angle`), not a scattered-prop collision — fixed by giving
the test's own `_walk_towards()` the same unstick/steer escape
`wild_pal.gd::_tick_aggression` already uses for the aggressor's chase,
verified 20/20 clean afterward (2/20 hit a different, already-tracked
`LP7` residual, unrelated). The other investigation (concurrent session,
`main`) found a related clue worth keeping on record even though its own
fix attempt didn't pan out: heavier instrumentation (logging
`locomotion_enabled()`, dialogue state, `is_fighting()`) made the failure
stop reproducing entirely (9/9 clean) while bare runs still failed ~2/3 of
the time — a timing-sensitivity signature consistent with (though not
identical to) the false-wall-collision finding above. That session also
ruled out the follower pal, the road gate, and village NPC proximity as
causes, and tried and correctly reverted a wider-escalating-angle unstick
variant that didn't measurably help. Recorded here so the two
investigations' evidence stays together rather than only the shipped fix
surviving.

- ~~`docs/ASSET_LEDGER.md` claims "everything currently in the build is
  CC0 1.0". False (Meshy creatures, Plumberry pack). Blocked on the owner
  for the correct wording.~~ **Resolved 2026-08-12** — the owner supplied
  the correct wording (All Rights Reserved / proprietary, owner-licensed)
  and `docs/ASSET_LEDGER.md` was updated accordingly (also independently
  re-confirmed and closed by a concurrent session — see `BLOCKED.md`'s
  "✅ RESOLVED — `ASSET_LEDGER.md` licence claim" entry).

- ~~Backpack has no use/consume/equip/drop/split verb; the only action is
  moving an item.~~ **Corrected 2026-08-11: this was stale.** A use verb
  already exists (`tab_backpack.gd::_read_use()`) and already heals from
  `heal`-tagged items — `potion_small` (`heal: 35`) is usable today. The real
  remaining gaps are narrower: `berries` carries no `heal` value (`R7.5`
  owns giving it one), and using any of it required the full backpack menu
  with no quick path — **fixed by `HD2`, see `DONE.md`.**
  **Drop and split shipped 2026-08-13** — see `DONE.md`
  (`backpack-drop-split`). **Equip did not**, and is not simply undone work:
  no item in `items.json` is tagged equippable, and GAME_DESIGN.md's two
  "Equip" concepts are both unbuilt systems of their own — §13's move
  loadout (2 Quick/2 Charged known, 1/1 equipped, per-pal) and §18's trainer
  armor slots (Helmet/Upper body/Lower body/Boots/Backpack). Wiring a
  backpack verb to either means inventing which one first and then adding
  real equipment slots to hang it on — CLAUDE.md's "changing type system" /
  "adding storage" flag, not a verb-on-existing-stack-data task like drop and
  split were. Left for the owner to pick a direction rather than invented.
- **`menu.json`'s stray `test_menu_config.gd` references and phantom
  `hotbar_columns` comment fixed — see `DONE.md`.**
- ~~Opening the menu mid-fight is silently refused with no on-screen
  explanation.~~ **Fixed 2026-08-12 — see `DONE.md` (`menu-mid-fight-refusal-
  hint`).**
- **`smoke_traversal` / `smoke_combat` flakes — PROMOTED to `LP1` in
  Phase -0.95.** Batched pushes make a random red cost up to four finished
  items instead of one, so this stopped being a small item.
- **Spec §6 — 6–10 optional activities, not forty shallow quests.** Lost Pal,
  Broken Cart, Night Watch, The Old Champion, Deep Warren, River Nest, Team
  Tether patrols, Meadowhart Herd. Each wants a home in Phase 8's bands rather
  than a list of its own; promote individually when the band it belongs to is
  built. `model: sonnet`
- **Spec §14 — home must stay relevant.** Grandpa's dialogue evolves per band,
  creature beds and recovery, storage and crafting, villagers updating what
  they know, the rescued NPC returning, story check-ins. The farmhouse should
  not become a room you never re-enter after the first twenty minutes.
  `model: sonnet`
- **`tools/survey.gd` and `tools/preview_creatures.gd`, both found broken by
  R0.8.5, relocated to Phase -0.5 as VP1/VP2** — owner directive,
  2026-08-10: visual-pass work runs before Phase 1 onward, and both tools
  are needed to verify that phase's own work.
