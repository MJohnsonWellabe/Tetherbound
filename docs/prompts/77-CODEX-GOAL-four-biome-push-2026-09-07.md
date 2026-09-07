# /goal — THE FOUR-BIOME PUSH, 2026-09-07

**Written 2026-09-07 by a Claude coordination session** after reading every live
document in `docs/`, the open branches and pull requests, the owner's 2026-09-07
playtest, the Codex biome reports and the blind visual verdicts. It is the single
contract for the next long Codex orchestration run. It rolls together, in one
prioritised plan, everything that the separate handoffs, sweep goals, biome tails and
the combat contract each asked for. Where it disagrees with an older document, this
file wins, except for `CLAUDE.md` and anything newer in `docs/owner/`.

**Kickoff line (paste this as the `/goal`):**

> Execute `docs/prompts/77-CODEX-GOAL-four-biome-push-2026-09-07.md` in full, on
> the integration branch it names, with the parallel lanes it names, using astra
> for the lanes it marks astra and sol for everything else. Land through the one
> pull request it names. Stop only on the stop conditions it names.

---

## 0. How this run works

### 0.1 Models

| Role | Model | Why |
|---|---|---|
| Orchestrator (this session) | **sol** | Decomposition, lane briefs, integration, checkpoints, roadmap and `CURRENT_STATE.md` upkeep. |
| Implementation lanes, by default | **sol** | Bounded 30–90 minute briefs with owned files, a named test and a stop condition (`docs/AGENT_WORKFLOW.md` §2). |
| Lanes marked **astra** below | **astra** | Root-causing the Ally freeze; the code-blind visual judge; resolving the Water rebase; designing the two-pilot combat harness; the final integration review before the PR leaves draft. These are judgment-heavy and have each already burned rounds when done by guesswork. |
| Code-blind visual judge | **astra**, separate sub-agent | Told nothing about what changed. Never the lane that made the change. `.claude/skills/visual-judge/SKILL.md`. |

Use many sub-agents at once. The parallelism rule is `docs/AGENT_WORKFLOW.md` §3:
lanes that touch independent files run together; lanes that share
`playground_hud.gd`, `game_state.gd`, `playground_world.gd`, `vegetation.json`,
`grass_field.json`, `species.json`, `save_game.gd`, `world_save.gd` or
`combat_manager.gd` are serialized on that file, not hoped about. Only one Godot
render at a time per box.

### 0.2 Branches and the one pull request

- Integration branch: **`codex/four-biome-push-0907`**, cut from current `main`.
- Open a **draft pull request** for it in the first hour. CI runs only on
  `pull_request` events and on `main` (`.github/workflows/ci.yml` `on:`), so a
  branch with no PR is never verified. Every push to the integration branch then
  gets one CI run; a newer push cancels the older run on the same ref
  (`concurrency.cancel-in-progress`), so batch pushes, never fragment them.
- Lanes work in worktrees on `ralph/<LANE>-0907` branches and merge into the
  integration branch when their brief's tests pass locally. Lane branches do not
  open their own PRs (that doubles the CI queue for nothing).
- Merge `main` forward into the integration branch after every landing on `main`
  by anyone else. Never rebase a branch another agent is live on; merge.
- Never push to `main`. Land through the PR when §8 holds. "Landed" means
  `git merge-base --is-ancestor <sha> origin/main`, not a badge.
- A CI run under five minutes verified nothing. A full run is ~18–25 minutes since
  the shard split; check that the code jobs ran and read every job.

### 0.3 Cadence, checkpoints and stop rules

These are the Stormwood execution rules, applied to the whole run
(`docs/biomes/stormwood/EXECUTION_PROGRESS_POLICY.md`,
`docs/owner/OWNER_DIRECTIVES_2026-09-05_STORMWOOD_EXECUTION.md:20-24`):

- **Checkpoint every two wall-clock hours** from the run's start, written to
  `ralph/reports/FOUR-BIOME-PUSH-0907/checkpoints.md`: player-visible capability
  added, regions or paths newly reachable, systems newly working in real play,
  content added, integration-branch SHA, blockers, next highest-value task. Credit
  counts only for work that is on the integration branch with runtime evidence. A
  missed checkpoint is a delta of zero, not a pause.
- **Two no-yield attempts on one narrow issue is a trigger to change strategy.** No
  third near-identical attempt, no repeated harness run without a changed
  hypothesis, no micro-tuning one axis after two no-yield rounds, no agent spawned
  to rediscover known facts, no acceptance criterion rewritten to manufacture
  progress.
- **Two consecutive checkpoints with no material delta: stop building**, integrate
  what is done, write the final report and a fresh-session tail
  (`docs/biomes/stormwood/00_CODEX_START_HERE.md:190-199` says what a tail contains).
- Visual rounds: two serious rounds per issue, then record the ceiling and the
  mechanism that blocks it (`docs/VISUAL_BIBLE.md:64-67`).
- Smallest test that answers the current question while building; full suite at
  landing waves and for save/autoload/shared-state changes.

### 0.4 Owner precedence for this run

`docs/owner/OWNER_PLAYTEST_2026-09-07.md` is the newest owner record. It sets the
priority order for this run:

1. **Stability first**: the game must not freeze (§3 lane STAB).
2. **Then looks and content.** Visual sweeps and audits, the road creature presence,
   the roster wiring, the combat depth ladder, the Stormwood and Water tails.
3. **Performance: cheap wins only.** The owner will come back to performance. The
   grass A/B on the Ally is the owner's own twenty-minute run and is still the only
   thing that settles the frame-rate question; prepare it, do not block on it, and
   do not fund a deep optimisation track from a container.

Where the combat contract (`docs/prompts/76-CODEX-combat-depth-performance-and-visual-bar.md`)
says "performance is upstream of everything" it is describing the evidence chain,
not the owner's order of work. Its §2 is deferred to lane PERF below except the
two items that are free.

---

## 1. Read in this order

1. `CLAUDE.md` — hard rules, binding.
2. `docs/00_START_HERE.md` — routing, validation, branch rules.
3. `docs/owner/OWNER_PLAYTEST_2026-09-07.md` — the newest owner record.
4. This file.
5. `docs/DEVELOPMENT_ROADMAP.md` — the cross-biome sequence this run advances.
6. `docs/CURRENT_STATE.md` §1–§3 (git truth, system status, ranked known issues).
   The dated sections below §5 are history; read them only when a lane brief
   points at one.
7. Per lane, the documents that lane names in §3. Do not cold-read
   `archive/`.

Branch `claude/early-game-combat-design-fp3tua` carries evidence this file depends
on and merges clean onto `main`. Merge it into the integration branch in Wave 0
(§2). It adds `docs/prompts/76-CODEX-combat-depth-performance-and-visual-bar.md`,
`docs/PERF_ALLY_FIRST_MEASUREMENT_2026-09-07.md`,
`ralph/reports/JUDGE-OWNER-RUN-20260907/VERDICT.md` and the repaired owner kickoff
scripts under `tools/owner/`.

---

## 2. Ground truth at the time of writing

Verify with `git log -1 --oneline origin/main` and the open PR list before trusting
any of this; it drifts.

- `origin/main` = `4acfb109`, PR #78 merged 2026-09-07 13:48 UTC, CI green
  (run 34127711895, 18 minutes, all shards). Release run 809 publishing. PR #78
  landed: 33 new creature models (all 12 Water, 9 Stormwood, 10 of 11 Cloudreach)
  rigged and wired into `species.json`; Lyra's rig; four playable characters in
  `data/config/characters.json` with portraits and a character-select step in
  `title_screen.gd` that swaps the body through `PlayerState.chosen_character`;
  HUD portraits for 32 species; move-slot and Best Creature ability fixes; the
  combat plan `docs/specs/COMBAT_DEPTH_PLAN.md`.
- Stormwood: PRs #68, #70, #74, #76, #77 merged. Scorecard 12/100 frozen weights;
  `ralph/reports/STORMWOOD-PROGRESS/fresh-session-tail-0907.md` is the live tail.
- Water: PR #69, **draft**, branch `ralph/water-foundation-0906`, 35/100 on the
  branch, 0 on `main`; base is 10+ commits behind `main` with ten content
  conflicts recorded; carries a P0 save-integrity defect (§3 lane WATER).
- Open unmerged branches with unique work: `claude/early-game-combat-design-fp3tua`
  (evidence + kickoff repairs, merges clean), `owner-run/20260907T023802Z` (the
  kickoff evidence payload; read, do not merge).
- Multiplayer: implementation scope complete and on `main` (PR #63); the 5-way
  `verify-multiplayer-shard` completes in CI; the scheduled 3/4-peer workflow ran
  green on 2026-09-07 08:27 UTC. Owner evidence rows unsigned (owner-only).
- The Ally: six of nine authored stands under 8 fps with grass on at 2053×1080
  (`docs/PERF_ALLY_FIRST_MEASUREMENT_2026-09-07.md`). Shipped build passes its
  export check with scatter present. Gate F chain S03+ refused by the harness
  budget guard at 0.049 s/frame.
- Two facts that older docs get wrong, so you do not re-learn them:
  `structure_visibility_ranges` is **true** on `main`
  (`data/config/performance.json:21`, since `222ea390`); only
  `scatter_lod_ranges` is false. `data/config/vegetation.json:527` and `:739`
  claim `scatter_lod_ranges` is live; it is not, and every `lod_*` key there is
  inert. Fix those two comments in Wave 0.

---

## 3. The lanes

Each lane is a brief in the `docs/AGENT_WORKFLOW.md` §2 form: branch, player-visible
outcome, owned files, forbidden files, tests, visual or not, completion report,
stop condition. Lanes in the same wave run at once. A lane's own definition of done
is in its last bullet; the run's is §8.

### Wave 0 — orchestrator, first hour, no sub-agents yet

1. Cut `codex/four-biome-push-0907` from `main`; open the draft PR.
2. Merge `origin/claude/early-game-combat-design-fp3tua` (clean).
3. Fix the two wrong `vegetation.json` comments (§2). Correct
   `docs/prompts/76-...md` §2.2 and `docs/PERF_ALLY_FIRST_MEASUREMENT_2026-09-07.md`
   §7 where they say `structure_visibility_ranges` is off.
4. Install Godot 4.7 and xvfb as `.claude/skills/visual-judge/SKILL.md` describes;
   `godot --headless --path . --import`; run `tests/smoke_playground.gd` and grep
   the log for `^ERROR:` to record the baseline set of benign errors. One known
   real one to keep in view: `ERROR: Parameter "material" is null` from
   `creature_body.gd:492 _build_model` via `encounter_director.gd:818 _make_alpha`
   on the GPU renderer.
5. Render the baseline: `tools/survey.sh` (Meadows five stands), the Cloudreach
   twelve, the Stormwood eight, contact sheets, committed as one `_sheet.png` per
   set under `ralph/reports/FOUR-BIOME-PUSH-0907/baseline/`. Every visual lane
   compares against these.
6. Write checkpoint 0.

### Wave 1 — runs in parallel

#### Lane STAB — the Ally freezes (astra)

Player-visible outcome: a fresh game on the shipped Windows build does not hitch
repeatedly in its first ten minutes and does not hang when a second creature bed
is placed.

Owner words: "It froze a lot at the beginning then after about ten minutes it just
froze for good while placing a second creature bed without going back to the menu."

Start from what is already known, do not rediscover it:
- `docs/CURRENT_STATE.md` §3 "Gate B's tail stalls placing creature beds (3 of 5)"
  and "stale terrain bake forcing live compute on boot"; OP-0905-02 "build screen
  from play cannot place" was never reproduced headless.
- `archive/docs/prompts/39-RG1-owner-playtest-modal-freeze-reopen.md` and
  `ralph/reports/W03-S08-FREEZE-0904/` for the prior freeze diagnoses.
- §STAB-LEADS below, filled from the code read done for this file.

Method: reproduce first with an interact-driven smoke that builds a camp and places
two creature beds in a row from the play screen (not via the menu), on a fresh
save, with the frame-time log on. Then bisect the hang: a synchronous
`ResourceLoader.load`, a scatter or navmesh rebake on placement, an autosave that
stringifies the world, an O(n²) structure scan, an `await` that never resumes.
Fix the cause, not the symptom. Add the smoke to CI's gate-a/build shard.

Owned: `scripts/build/`, the bed/structure placement scripts, the autosave
trigger, `tests/smoke_build_*.gd`. Forbidden: rendering, grass, combat.
Tests: the new smoke, `smoke_gate_a_build_house`, `smoke_free_build`,
`smoke_gate_b_continuous` reliable prefix. Done when the two-bed smoke passes ten
runs in a row with no frame over 250 ms after the first minute, and the early
hitching has a named cause with either a fix or a measured "needs the Ally".

#### Lane ROAD — creatures visible on every Meadows road (sol)

Player-visible outcome, in the owner's words: "I'd expect to always be able to see
multiple creatures in a 180 view in front of me." Applies to the whole Meadows
road, bands 1–5, and by extension to Cloudreach and Stormwood routes.

Known state: the worst road gap was reduced 119 → 91 m (`CURRENT_STATE.md:301`),
band 4's worst authored gap is 110 m (`:582`), and the owner still sees bare
patches. The bar is not a gap length; it is *what the player sees*.

Method: write a probe that walks the authored road at player speed and, every 10 m,
counts wild creatures inside a 180° forward cone within the draw distance actually
shipped (not the spawn radius). Report the longest run of samples with fewer than
two visible creatures per band. Then fix it in data first
(`data/config/spawn_tables.json`, the per-band creature configs, D69's band
widening), with wander leashes pulled toward the road and roadside clusters
authored where the probe says, not uniformly. Retention (creatures despawning
behind the player) is part of it. Use the new roster where a band's ecology wants
it (lane ROSTER lands the tables; coordinate on `species.json`).

Owned: spawn tables, band creature data, `scripts/world/*wild*`, the new probe
under `tools/gate_f/`. Forbidden: `species.json` edits (ROSTER owns it this wave).
Tests: `smoke_playground`, `smoke_wild_presence` if it exists or the new probe as a
smoke, `verify-scatter-rules`. Done when the probe shows zero samples with fewer
than two visible creatures on any band's road at shipped draw distance, and a
frame set from `tools/survey.sh` stands shows creatures in frame.

#### Lane ROSTER — new creatures and characters in the right places (sol)

Player-visible outcome: the four playable characters are all offered and all work;
every new creature appears in its biome's wild, alpha or trainer tables where its
design puts it.

Character select: verify on the integration branch, on real input, that
`title_screen.gd` shows all four entries from `data/config/characters.json` with
portraits on both the new-game and the join-without-save paths, that the chosen
body is the one that spawns, and that a joining peer renders the host's chosen body
(D101). If any of that fails, fix; do not rebuild the picker.

Creatures: §ROSTER-MATRIX below lists, species by species, whether a mesh is
installed, whether `species.json` has it, and whether any spawn, alpha or trainer
table places it. Close every gap in the matrix for Cloudreach, Stormwood and Water
(Water into the Water branch, not the integration branch). The Meadows roster is
frozen by `CLAUDE.md`; do not add new species there. Then run `tests/smoke_art.gd`
and the roster unit tests.

Owned: `data/creatures/species.json`, `data/config/*spawn*`, `cloudreach_world.json`
roster rows, Stormwood encounter data, `characters.json`, `title_screen.gd`.
Tests: `smoke_art`, `test_species*`, `smoke_title_new_game`, the character-select
smoke, a net smoke that joins with a non-default body. Done when the matrix has no
empty cells for the three built biomes and the character path is proven on real
input.

#### Lane VIS-MEADOWS — the free visual fixes with the best ratio (sol; astra judges)

Everything here comes from the blind verdict on the owner's own GPU frames
(`ralph/reports/JUDGE-OWNER-RUN-20260907/VERDICT.md`) and the Meadows sweep goal
(`docs/owner/MEADOWS_VISUAL_SWEEP_GOAL_2026-09-06.md`). Do them in this order; each
one is measured before and after, in numbers decided before the render.

1. **Fix the broken capture stands** (camera inside the trainer's legs, inside a
   grey box, inside a canopy, an NPC clipping the near plane at survey tiles 1 and
   5). `tools/_capture_route_strip.gd` has a refusal mechanism; find out why the
   survey path does not use it. Fails if a re-run reproduces any of them.
2. **Reallocate the chroma budget.** The ground (acid yellow-green grass,
   orange-brown path) is the most saturated thing in frame and creatures the
   least; Palworld holds a muted sage-and-tan ground so creatures pop. Desaturate
   and de-yellow the ground, give the chroma to creatures and the player. Numbers:
   crop-median chroma of ground vs creature before and after. This is the single
   highest-value visual change and costs nothing at runtime. It also answers the
   Warrens rounds' "#1: pale whitish grey-green ground". This is W2 from the grass
   handoff, which no lane has ever touched.
3. **Landmarks along the road.** 23 of 24 route stages contain nothing to navigate
   by. The one that works is Team Tether pylons with the cyan cable and the fort on
   the ridge; that is exactly the asset category `CLAUDE.md` allows. Extend that
   language along the corridor, plus terrain massing and the installed nature,
   village and prop families. The key art names a windmill, a watchtower, a peak
   and a standing rune stone. Do not invent a new asset family.
4. **Night relight.** `route_night_002` is a near-black rectangle with clouds
   brighter than the ground. Give night a second light colour, rim, bounce.
5. **The hard shadow-distance band** with no caster (survey tiles 1 and 5), and
   "no cast shadows on terrain" (directional shadow range).
6. **Oxblood off friendly props** (the wayfinding arrow, the friendly camp banner);
   texture the arrow. D87 exists to protect this palette.
7. **Tree scale ladder**: a 1.8 m trunk beside 4 m mid-band trees with nothing
   between. Fill the ladder from the installed tree family; evaluate the Sakura
   asset the sweep goal names as a *sparing* hero accent.
8. **Team Tether grunt silhouette value** — grey on grey against grey stone.
9. Village composition, signs, props, NPC placement per the sweep goal §4; the
   floating chimney on `cottage_a` (`Prop_Chimney2`), the fence-through-fence.
10. Aerial perspective, path material detail, sky variation, water shoreline
    blend — only after 1–9, and only if the checkpoint delta is still material.

**Deferred to lane PERF, do not do here:** pushing the scatter radius out, denser
scatter, canopy draw distance. The judge wants them and the Ally measurement
suspects them; the grass A/B settles it, not this lane.

Owned: `data/config/vegetation.json` colours, `grass_field.json` tint only,
`scripts/world/world_look.gd`, `shaders/`, landmark placement data, the survey
tools. Forbidden: scatter counts, LOD ranges, `performance.json`. Visual: yes;
every round is judged code-blind by astra with the baseline sheet beside the new
one. Done when a fresh blind judge, given new frames and told nothing, no longer
leads with the inverted chroma budget or the absent landmarks, and the sweep
goal's 14 before/after pairs exist.

#### Lane VIS-CLOUDREACH — audit first, then the open items (sol; astra judges)

The owner's audit goal
(`docs/owner/CLOUDREACH_VISUAL_AUDIT_AND_SWEEP_GOAL_2026-09-06.md`) is
audit-first: "do not assume the fixes in advance". Its Phase A output,
`docs/CLOUDREACH_VISUAL_AUDIT_AND_SWEEP.md`, does not exist. Write it from a fresh
twelve-stand render on the integration branch, judged blind, before touching the
scene. Note that every Cloudreach verdict before the atmosphere lane was judged
with effectively no distance fog (`cloudreach_look.gd` compounded fog per frame
while the capture clock was frozen); the baseline you render in Wave 0 is the first
honest one.

Then work the audit's ranked list. What is already known to be open:
- **Stand `05-upper-cloudreach-cliffhold` ground reads flat green** with 500k tufts
  present; owner invariant "nowhere you can stand that isn't grass or bare dirt"
  NOT MET. Ruled out already (do not repeat): density, patch layers, untextured
  material, flat terrain, metallic defect, non-turf surface, `_is_turf_top`, ledge
  caps, tufts in rock. Next: re-run `tools/_probe_cloudreach_cover_near.gd` with a
  real wait; then camera clearance, visibility range, blade foreshortening; if
  those fail, give that ground a dirt/mud material and call it bare dirt.
- C3 verticality: no drop within ~60 m of any judged stand; move the stands to
  edges or cut a drop where the player stands.
- C4 horizon: layers exist but read as "opaque white cardboard"; needs a
  soft-edged cloud material, not more billows.
- C6 arena needs geometry (kerb, step, rim), not tint. C8 cottages need lean and
  wind, and dressing sized to read at the judged distance. C7 aviary: interior is
  hidden behind its own 9 m drum wall; lattice vs membrane is an owner decision
  (§7).
- Three incompatible rock languages (pale putty boulders 6× brighter than the
  cliff; tan hoodoo vs the board's grey-green granite); the spiral scratch lines on
  the stand-11 spire come from nested sines in `cloudreach_cliff.gdshader`.
- No sunlight in the top quarter of the value range; no aerial perspective.
- Placeholder cube on the keep and the path; white slivers in the grass at 02/12.

Owned: `scripts/world/cloudreach_*.gd`, `data/config/cloudreach_*.json`,
`shaders/cloudreach_*`. Forbidden: Meadows files, `grass_field.json`. Visual: yes.
Done when the audit doc exists with its 21 evidence pairs and the judge's answers
to its 15 questions move on the items above, or the ceiling is recorded per item.

#### Lane VIS-HALL-WARRENS — finish the Meadows hero interiors (sol; astra judges)

- Hall: the final tuning round of HALL-ART-0906 was never rendered; render it. Then
  the leftovers: `TetherReadout/Panel` flat maroon plane at 2.9 m in T-02,
  `RestraintRing0` edge-on white chevron, walls terracotta against the key art's
  granite, oxblood at 11–14 % of frame against 0.63 % on the board, the T-03
  sconce clip, the arena ivy, "no creature, no Warden in frame" at the capture
  stands (stage the capture after the fight starts).
- Tether machine H6: the style mismatch is closed. The silhouette is a **lighting
  and staging** failure (Michelson 0.65 against the torch-lit wall vs 0.23/0.30
  elsewhere). Do not spend another albedo round; three grades exhausted it, the
  roughness change measured no-op, there is no emissive, and the owner rejected the
  procedural re-author. Light it and stage it.
- Warrens interior: the material half landed (one earth cladding); `07-den`
  regressed 46.6 → 32.0 because its lights were tuned for the old albedo; the
  duplicate chests from the playground pickup pass; then the sweep goal's hero
  pass (§5). The geometry half ("hard 90° extruded prisms, nothing says dug")
  needs an organic tunnel kit and is an owner budget decision (§7); do not fake it
  with more tint.
- Burrowback's style split (W4) is an owner call (§7); leave it.

Owned: `scripts/world/stronghold*.gd`, `warrens*.gd`, their configs, their capture
tools. Visual: yes. Done when the Hall's leftovers are gone in a blind round and
the Warrens interior no longer regresses `07-den`.

#### Lane COMBAT — the ladder out of button-mash (sol implements; astra designs the harness)

The full contract is `docs/prompts/76-CODEX-combat-depth-performance-and-visual-bar.md`
§3 and `docs/specs/COMBAT_DEPTH_PLAN.md`. Ship, each as one lane branch merged in
order:

1. **COMBAT-1** poise/stagger both sides, wind-up interrupted by a hit, charged into
   TELEGRAPH interrupts, hitstop, flinch. `combat_manager.gd` strike resolve and
   `_tick_action`, `wild_creature.gd`, `data/config/combat.json` `poise` block, the
   combat HUD.
2. **COMBAT-2** creature stamina ("wind"): per-species caps in `species.json`
   (coordinate with ROSTER), satiety and bond move the cap.
3. **COMBAT-5** the opponent answers back, in `combat_ai.gd::decide()` as added
   inputs to a pure function, unit-tested.
4. **COMBAT-7** the early fight ladder, content and dialogue only, from the plan's
   §6 table.
5. **The two-pilot harness first, before 1–4 are judged done**: a READER pilot
   beside the existing MASHER in `tests/smoke_combat_baseline.gd`, with the
   per-band assertions in `chapter_curve.json` `difficulty` from contract §3.1.
   Fails if both pilots produce the same numbers.

COMBAT-3 (telegraph retune and the get-out-of-the-way verb), COMBAT-4 (the Y skill
slot and level learnsets) and COMBAT-6 (type chart 1.5/0.67) are **blocked on
owner decisions** (§7). Build everything that does not depend on them; leave the
decisions in `docs/decisions/` as OPEN entries with the recommendation, do not
choose.

Acceptance is not trustworthy until the frame rate is readable on the Ally
(contract §2.4); say so in the report, and do the work anyway, because its
diagnosis was read from code.

Owned: `scripts/combat/`, `data/config/combat.json`, `type_chart.json` untouched,
the combat HUD panel. Forbidden: `species.json` outside the `wind` caps. Tests:
`smoke_combat_baseline`, `test_type_chart`, `smoke_tournament_bracket`,
`smoke_catching`. Done when READER beats MASHER per the assertions at every band
entry.

#### Lane STORMWOOD — finish the main path (sol; astra for the Dynamo integration)

Live tail: `ralph/reports/STORMWOOD-PROGRESS/fresh-session-tail-0907.md:55-60`,
directive `docs/biomes/stormwood/BUILD_STORMWOOD_TO_COMPLETION.md`. In order:

1. Host-owned remote encounter starts: `_open_encounter_if_networked()` returns on
   non-host; a client must be able to start a wild or trainer fight the host
   simulates. This is the same question the multiplayer handoff left open (§7 has
   the owner half); implement the host-authoritative default and record it.
2. The six named encounters, the Crown guardian as a real encounter (it exists only
   as data; Wen can tell the truth early), the Rootgate path.
3. Co-op Marrow/Dynamo phases: mount the Dynamo encounter (Marrow refuses until
   `arena_ready()`), conduits, the captive legendary release and five-slot
   ceremony.
4. Spark/Livewire, aftermath, the non-enterable Waterward view, then the full
   chapter evidence run.
5. Persistence gaps from the settlement audit: `village_door.gd` state is neither
   persisted nor replicated; `village.gd` never checks `realm_id`.
6. Content to the §13 census targets: 57 of 160 dialogue nodes, 8 of 12 recipes,
   461 placeholder replacement points ranked by what the player meets first.
7. Visual: every judge has rejected both bars ("pale skeletal tower with a black
   spiral", "empty scatter field", the frame-05 white rectangle). The white
   rectangle is release-blocking; fix it first. Then the Stormheart's readability
   and the forest's authored structure, two rounds each, judged blind.

Owned: `scripts/world/stormwood_*`, `data/config/stormwood_*`, Stormwood tests.
Multiplayer-native from the first commit. Done per the directive's exit criteria;
report the scorecard delta at each checkpoint.

#### Lane WATER — keep building on its own branch (astra rebases; sol builds)

Owner instruction of record: keep PR #69 **draft and unmerged**; nothing newer
lifts it (§7 asks the owner to confirm or lift it). Work continues on
`ralph/water-foundation-0906`:

1. Rebase (merge `main` forward — the branch is the owner's; do not rewrite it)
   through the ten recorded conflicts (`autoload/item_db.gd`, `world_ledger.gd`,
   `save_game.gd`, `world_save.gd`, `quest_log.gd`, two tests, `tools/survey.sh`,
   two docs) and now PR #78's roster files. Resolve in favour of `main`'s shared
   systems and the branch's Water content.
2. **P0 save integrity**: `world_save.gd::write` and `character_save.gd::write` do
   not check the `store_string` result and do not write atomically; disk-full
   produced truncated JSON with a success return. Write to a temp file, fsync,
   rename; fail loud. This fix also belongs on the integration branch for `main`'s
   own saves — port it there as a small separate lane.
3. Swap the 12 placeholder Water bodies for the meshes PR #78 installed.
4. Then the report's next five (`FINAL-REPORT-AND-FRESH-SESSION-TAIL.md:91-95`):
   the continuous key → Veilfall route, the six side chains and objective spine,
   the Aquaryn surface arena, two-then-four-peer finale/reconnect, aftermath.
5. Full regression in a healthy environment (the branch's last run died on a
   Windows Bash fork and a CRLF checkout, not on the game).

Done when the branch is green on current `main`, its P0 is fixed and its
scorecard moves; merging is the owner's call.

#### Lane MP-KEEP — multiplayer stays playable while everything else lands (sol)

Not new features. The known-open engineering from
`docs/owner/STAGE_B_HANDOFF_2026-09-06.md` and the coordination handoff:

- `tests/smoke_net_shared_cloudreach_fight.gd` does not exist; the evidence bar
  "shared Cloudreach encounter" is unmet. Write it, with the `place_stand_in` arm.
- Re-measure `smoke_net_host_join_leave` and `smoke_net_pickup_race` under
  `TB_NET_CONDITIONS="delay=150,jitter=30,loss=1"`; `smoke_net_shared_boss` after
  F1/F2; `smoke_net_shared_wild_fight` ten times; `smoke_aggression` flake rate.
- `reconnect_window_s` says 120 s in `data/config/multiplayer.json:27-28`; the code
  evicts immediately. Make the config true.
- Run the net shard on the integration branch after every wave lands. A net smoke
  that goes red because a lane changed shared state is that lane's bug.

The owner rows (LAN session, outside tester, Ally host frame time) are owner-only;
list them, do not simulate them.

#### Lane CONTENT-MEADOWS — the fun rebuild's unbuilt half (sol)

Owner asks that are still contracts without code:
- **Task feed** (`docs/specs/C2_TASK_FEED.md`): things appear on the map and tell
  the player to go do them; "beat the Tether grunts at each relay, turn the relay
  off"; the all-trainers quest. `relay_site.json:4` still says the station "IS NOT
  BUILT YET". Only alpha pins landed.
- **Level gates that exist**: no shipped trainer carries `min_level`
  (`CURRENT_STATE.md:558`); D75/D79 define placement. Place them once ROAD lands.
- The relay assault as a Grunt → Officer → Captain Vance mission and the Captains
  as three distinct exams (`docs/owner/TETHERBOUND_MEADOWS_MIDGAME_FUN_REBUILD.md`).
- Refused Veridian seen roaming and uncatchable (09-04 Q3).
- Village replan (C3) and camping-necessary (C4) are second-wave: start them only if
  the checkpoint delta is still material after the above.

Owned: `data/objectives/`, `data/config/relay_site.json`, trainer configs,
`scripts/story/`, the task-feed UI. Forbidden: `playground_hud.gd` outside the feed
panel (coordinate). Tests: `smoke_gate_b_continuous`, the objective-chain smokes,
`test_story_flags` (D99: every flag has a declared scope). Done when a played
continuous segment shows the feed driving the relay chain.

#### Lane PERF — the cheap wins, and nothing deep (sol)

The owner: "Don't focus too much on performance yet ... you can do the easy wins
first." The only measurement that settles the frame rate is the grass A/B on the
Ally, which is the owner's twenty-minute run. So:

1. Prepare that run so it is one double-click: `KICKOFF.cmd -Only perf` with
   `grass_field.enabled` false then true at the same nine sites, writing both
   `fps.json` sets side by side. Put the exact instruction in
   `docs/acceptance/KICKOFF_RUN.md` and in the final report for the owner.
2. Expose a **render scale** setting: the probe ran at 2053×1080 on an iGPU and no
   `scaling_3d` lever exists anywhere in config. A 0.75–0.8 scale on the Ally is
   the cheapest frame-time win in the project and is a settings row, not an
   optimisation track. Default it for the Ally profile if one exists; otherwise a
   Settings tab entry.
3. Re-test `scatter_lod_ranges` against *frame time*, not draw calls, once the A/B
   result exists; until then leave it.
4. The `grass_field.json` knobs (`tuft_count`, `field_radius`, `fade_start`, the
   `lod` block, per-tier `reach_m`, the far-cover reach) are the levers *after* the
   A/B, not before.
5. The harness budget guard: S03+ of the Gate F chain does not fit a night at
   0.049 s/frame. Do not raise `segment_cost_ceiling_s`. If the render-scale row
   and the A/B answer double the frame rate, the chain fits; that is the path.

Nothing else. Do not open a deep optimisation track from a container.

#### Lane DOCS — keep the next reader from being confused (sol, continuous)

- `docs/CURRENT_STATE.md` is the evidence-backed status and is 250 KB. Keep §1–§5
  live; every dated checkpoint section below them moves to
  `archive/docs/current-state-history/` as it is superseded, with one line left
  behind pointing at it. Record this run's findings in §3, ranked by player impact.
- `docs/DEVELOPMENT_ROADMAP.md`: the master table's Stage A row and the Stage 0
  status notes are stale (PR #63 merged, the shard completes, Stormwood in
  progress); fix them and the "Current next action" at each checkpoint.
- Decisions go in `docs/decisions/` as they are made; owner decisions stay OPEN
  there with a recommendation.
- On landing, delete nothing; archive per `docs/CLEANUP_MANIFEST.md`'s convention
  and rewrite references. The coordination session that wrote this file already
  archived the handoffs it judged historical (§5).

### Wave 2 — after Wave 1's lanes have landed on the integration branch

1. **The full visual audit over everything (astra judges).** Fresh renders of every
   stand set on the integration branch, plus the owner's Meadows sweep 14 pairs and
   the Cloudreach 21 pairs, judged code-blind against `docs/reference/` with the
   Stage C question list from `docs/DEVELOPMENT_ROADMAP.md` (C6): finished
   commercial game or prototype; the three most visible things holding it back;
   an obvious reason to explore; a distinct identity per region; is the creature
   the focus; what quality tier. Include the "things that don't work together"
   axis explicitly: the judge has said, in five separate verdicts, that the
   trainer, the villagers, the guardians and the wild creatures are "three
   different games" and that the rock kits, the prop family and the tether machine
   belong to different sets. Ask for the ranked list of *which pairs clash most*,
   and fix what a scene can fix (palette, value, outline weight, material
   roughness via `creature_visual.gd`) — the mesh-level answer is an owner
   decision (§7).
2. **A four-biome density census** with the C2 measures (time and distance between
   meaningful interactions, worst dead-travel gap, on-route vs off-route reward)
   for Meadows, Cloudreach, Stormwood and the Water branch. Later biomes must not
   be thinner. Fix the worst gap per biome.
3. **Continuous-path smokes** on the integration branch: `smoke_gate_b_continuous`
   full, the Cloudreach continuous acceptance replay, the Stormwood chapter run,
   the net shard. Then the full unit suite.
4. Second-wave content (C3 village replan, C4 camping) and the remaining VIS items
   only if the checkpoint delta is still material.

---

## 4. Lane-specific evidence gathered for this file

### §STAB-LEADS — the second-bed freeze, from a static read of `main`

Nothing in the ledgers records a process-level hang on bed placement before the
2026-09-07 playtest. The prior "Gate B tail stalls placing creature beds (3 of 5)"
item is a build-menu refusal (`build_menu.gd:745-756`, `can_afford`), not a hang,
and predates the code below; it shares the location, not the mechanism.

**H1, strongest — a re-entrant ledger loop introduced by multiplayer Wave 5 lane
5.A (`f428ba02`, 2026-09-06), which is in the build the owner played.** All on the
main thread, all synchronous:

1. Place → `scripts/build/build_placer.gd:797-842 _place` →
   `scripts/net/ledger_rpc.gd:104-130 submit/_commit_here` commits and **emits
   `delta_applied` synchronously**.
2. `build_placer.gd:892-940 _on_delta_applied → _settle_placement` →
   `scripts/build/home_progress.gd:193-202 maybe_set_creature_beds`, which loops
   `for i in mini(standing, 3): _grant(flag[i])` with **no `progression.has()`
   guard** (`maybe_set_home_built` at line 137 has one).
3. `_grant` (`home_progress.gd:237-241`) → `story_ledger.gd:133-162
   write_flag/grant_player_flag` → ledger submit again.
   `world_ledger.gd:493-505 _grant_player_flag` "never refuses as already granted",
   so every grant is a fresh commit with a new `seq` and another synchronous emit.
4. `scripts/story/sequence_director.gd:879-909 _on_ledger_delta` runs
   `_share_the_camp()` on **every** delta, which calls `maybe_set_creature_beds`
   again. Its `_last_delta_seq` guard cannot stop this because each nested commit
   has a new seq.

With N beds standing, every delta fans out into N further commits, each re-entering
step 4: linear with one bed, a binary tree with two. The release binary has no
GDScript call-stack cap, so the outcome is a pinned main thread with no return to
the menu. Caveat: `smoke_gate_a_rest_torch` places **one** bed through the real
controller path in CI on the owner's sha with no stack error, so either something
not found statically bounds the one-bed case or the pathology opens only at two.
**The decisive measurement is cheap: count `Game.ledger.delta_applied` emissions per
placement with one bed standing, then two.** Run it on `main` and on `main` with
`f428ba02` reverted.

**H2 — per-bed construction cost (a hitch, not a hang).** `creature_bed.gd:237-360
_build_rim` builds ~57 `CapsuleMesh` and ~38 `TorusMesh` instances each with a
`duplicate()`d material, two `load()` texture calls (`:212-215`, `:243-247`), a GLB
`build_real` and a `CAMP_FILL_LIGHT`; the ghost is rebuilt the same way on arm
(`build_placer.gd:435-476`). First-sight shader work on Compatibility.

**H3 — `build_placer.gd:573-583 preview_placement`** deep-duplicates
`placed_buildings` every physics frame while armed; O(n), harmless at five.

Ruled out for the hang: autosave on placement (autosave is rest, realm entry, or a
180 s fallback), navmesh or scatter rebake on placement, `while` loops in the
placement path, thread joins.

**Early hitching, ranked:** (1) `sequence_director.gd:889-891` calls
`STORY_LEDGER.restore_all` on any delta carrying a world flag, and after 5.A the
opening's dialogue flag drains are ledger intents, so each opening flag re-poses
every `progression_restore` node; (2) the 180 s fallback autosave
(`game_state.gd:653, 925-930`) does a same-frame `JSON.stringify` and
`store_string` of world, character and slot (`save_game.gd:343-352, 558, 572`);
(3) first-sight GL shader compilation and synchronous species GLB `load()` on first
spawn (`creature_body.gd:502`; `load_threaded_request` is used only in
`realm_shells.gd`); (4) the map bake on first map open on a fresh install
(`tab_map.gd:1340`, `playground_hud.gd:2523`).

**No smoke places two beds through the controller with the director live on
post-5.A code.** `smoke_gateb_flags.gd:108-131` registers beds directly and bypasses
the settle path; `gate_b_tail_segment.gd:279-301` runs only under the known-red
full chain. The smoke lane STAB writes: title → New Game → `_set_beat("free_play")`
→ the Practice Meadow build patch → `_select_piece("creature_bed")` → `build_place`
→ settle 24 frames → repeat at an adjacent spot; a frame-time watchdog (fail over
500 ms), a `delta_applied` counter per placement, a `_pending_placements` empty
check; then a 180 s soak for the autosave and restore-sweep hitches.

Levers, not designs: a `has()` guard in `maybe_set_creature_beds`; `_share_the_camp`
only on `building_add` deltas or never on a delta the local peer just committed;
`_grant_player_flag` / `_commit_here` not emitting for already-set flags; a
re-entrancy guard or deferred emit in `_on_ledger_delta`; cache the rim material and
meshes per bed; move the fallback autosave and first-spawn GLB loads off the frame.

### §ROSTER-MATRIX — what is wired and what is not, on `main` @ `4acfb109`

Species source `data/creatures/species.json`: 25 → 57 entries; every entry's
`placeholder.model` exists under `assets/creatures/tetherbound/<id>/models/`. Every
one of the 32 new ids appears **only** in `tools/art_pipeline/meshy.py` outside
`species.json`: none is in any spawn, encounter, trainer or legendary table.

| Species (new in PR #78) | Biome | Mesh | `species.json` | Spawn / encounter table |
|---|---|---|---|---|
| pebbik, craghorn, stormcapra, skyrill, aeriex, ribbonray, breezetail, cloudfang, cliffspike; tempestwing (alpha); solmane (legendary) | Cloudreach | yes | yes (air) | **no** |
| voltwig, glimmermoth, stormbrush, mosshock, staticub, tanglevolt, stormraven, thundertunnel; voltarach (alpha); fulgocobra (legendary) | Stormwood | yes | yes (electric) | **no** |
| cannonback, riptusk, mirejaw, aquaryn, torrentoad, cragclaw, riverdrake, sirenseal, mangrove_monitor, tidecoil; abyssal_guardian (legendary) | Water | yes | yes (water) | **no** — the Water realm exists only on PR #69's branch, with 12 placeholder bodies |
| galecrest, sparkit, mosshell (reused anchors) | B2 / B3 / B4 | yes | yes | Meadows bands; galecrest and sparkit also as Cloudreach/Stormwood *placeholders* |

Where the tables are, and how the data already anticipates the swap:

- **Cloudreach:** `data/config/cloudreach_chapter.json:560+`, six `encounter_tables`
  (`cloudreach_lower_wild` … `cloudreach_summit_wild`, levels 18–33) each carry
  `placeholder_species` from the Meadows set (pipwing, sparkit, galecrest, shadelet,
  galewisp, bramblebun, frostclaw, reedwing); `cloudreach_encounter_director.gd:152,174`
  read that field. Sites: `cloudreach_encounters.json` `wild_sites` (two per site,
  likely too thin). Trainers: `team_contract.slots`.
- **Stormwood:** `data/config/stormwood_encounters.json`, twelve tables
  (`verge_calm` … `dynamo_surge`, levels 30–43) plus `legendary_placeholder`
  (`stormheart_placeholder` = sparkit at ×1.8), each with `placeholder_species` and
  an explicit `replacement_point`; `stormwood_encounter_catalogue.gd:79,157`;
  `stormwood_trainers.json`; expectations in `tests/test_stormwood_encounters_data.gd`.
- **Water:** on the branch, the twelve placeholder bodies in the Water species rows.
- Stats on the new entries are placeholder-functional (moves `["quick","charged"]`,
  `_comment_placeholder_stats`); lane COMBAT-2's `wind` caps and a real move set per
  species are the follow-on.

Playable characters on `main`: `data/config/characters.json` has `trainer`, `lyra`,
`kael`, `sera` (the trainer has no portrait); GLBs under `assets/characters/`;
`art.json:33-100`. `title_screen.gd` `_show_character_select` (~560–615) renders four
cards; `:631-636` and `:847-850` set `PlayerState.chosen_character`;
`trainer_model.gd:63-70` builds it. Defects to fix in lane ROSTER:

1. `chosen_character` is **not persisted** (`player_state.gd:375-399`;
   `character_save.gd:45`) — Load Game returns the trainer body.
2. **Remote peers render the local choice, not theirs** (`remote_trainer.tscn:14`
   attaches `trainer_model.gd`, which reads the local `PlayerState`); the session
   hello (`session.gd:234-242`) and `trainer_spawn.gd` carry no body key. D101.
3. Duplicate `_character_box` construction at `title_screen.gd:443-446` and
   `:453-456` (merge artefact; dead node).
4. No test asserts four options or that each id resolves a body
   (`smoke_title_new_game.gd:91-97` only presses the first button).
5. `docs/art/HUMANOID_ASSET_INVENTORY.md` (authoritative per `CLAUDE.md`) does not
   list the three new playables; `docs/CREATURE_DESIGN.md:15-17` still says 25
   species.

Road presence numbers, computed for lane ROAD against each band's spine
(`terrain_playground.json` `trail.bands[].points`) with cluster edge within 25 m of
the line:

| Band | Spine | Clusters / creatures | Longest bare intervals | Sub-1.3 m species | Time/weather-gated clusters |
|---|---|---|---|---|---|
| 1 Lower Meadows | 2403 m | 75 / 237 | 83, 82, 81 m | 87 % | 6 |
| 2 Stone & Root | 2653 m | 71 / 237 | **159, 150, 148 m** | 67 % | 14 |
| 3 River Lock | 2375 m | 66 / 193 | **138**, 92, 92 m | 62 % | 10 |
| 4 Upper / Ironwood | 3436 m | 91 / 309 | 120, 110, 108 m | 58 % | 8 |
| 5 Stronghold | 651 m | 24 / 81 | 84, 63, 50 m | 52 % | 0 |

Cluster size median 3. The contract's own bar (`docs/specs/GATE3_CREATURE_PRESENCE.md`
§3 CP-2a, 250 m) passes on paper; the owner's bar does not. Streaming reach is
cluster radius + 24 m (`encounter_director.gd:2652-2658`), respawn 45 s
(`data/config/spawns.json`), and 52–87 % of members are species that read at ~15 px
at 40 m. No existing probe measures a forward 180° cone
(`tools/_probe_band_density.gd` counts pickups as gap-closers; `test_spawns_data.gd`
has no spacing assertion).

---

## 5. What the coordination session already did, so you do not redo it

- Recorded the owner's 2026-09-07 playtest verbatim in
  `docs/owner/OWNER_PLAYTEST_2026-09-07.md`.
- Archived the handoffs that were fully superseded (`archive/docs/handoffs/HANDOFF_2026-09-03.md`,
  `archive/docs/handoffs/HANDOFF_2026-09-06.md`, `archive/docs/gates/GATE3_COORDINATOR_BRIEF.md`,
  `archive/docs/VISUAL_PARITY_PROGRESS_cloudreach.md`) and the closed owner records under
  `archive/`, rewrote the references, and corrected `docs/00_START_HERE.md`,
  `AGENTS.md` and `docs/DEVELOPMENT_ROADMAP_START_HERE.md` to route here. The
  two handoffs that still carry live state
  (`docs/HANDOFF_GRASS_AND_ART_LANES_2026-09-06.md` §3–§6 and
  `docs/HANDOFF_COORDINATION_2026-09-06-CODEX.md` Tasks 4, 5, 6, 8) are folded into
  the lanes above; they stay in `docs/` until this run lands.
- Corrected the stale status rows in `docs/DEVELOPMENT_ROADMAP.md`.

---

## 6. Integration and landing

1. Each lane merges into the integration branch only with its brief's tests green
   locally and `tests/smoke_playground.gd`'s `^ERROR:` set unchanged.
2. After each wave: merge `main` forward, push once, read the whole CI run job by
   job. A retry that turns 0-for-1 into green is a finding.
3. Before the PR leaves draft (astra reviews): the §8 list holds; `CURRENT_STATE.md`
   §1–§3 describe the integration branch truthfully; the final checkpoint and the
   fresh-session tail are written under `ralph/reports/FOUR-BIOME-PUSH-0907/`;
   the owner decisions in §7 are listed in the PR body with recommendations.
4. Mark the PR ready. Do not merge it yourself unless the owner has said to;
   the kickoff line above authorises landing "when it's ready", which means §8.
   Confirm the landing with `git merge-base --is-ancestor`.
5. `release.yml` publishes from `main`; before telling the owner a fix is playable,
   check the release asset timestamp.

## 7. Owner decisions — do not invent these

Record each as an OPEN entry in `docs/decisions/` with the recommendation; build
around them.

1. **Water merge hold.** The standing instruction keeps PR #69 draft and unmerged.
   Does the 2026-09-07 "merge to main when it's ready" lift it? Default in this
   run: no; Water stays on its branch and is rebased and built.
2. **Combat verb**: movement only, retuned / a burst step on A without i-frames
   (recommended) / a dodge roll with i-frames. Blocks COMBAT-3.
3. **Y as the third move slot** and **moves learned by level** vs TM-only. Blocks
   COMBAT-4.
4. **Type chart 1.5/0.67.** Blocks COMBAT-6 and reopens D77 and W-1 numbers.
5. **A wild can exhaust your creature** (wind slowdown as a cost). Tunes COMBAT-2.
6. **Creature and character style coherence** across the cast: the judge says the
   meshes were never designed as a set and scene fixes cannot close it; `CLAUDE.md`
   forbids new Meadows meshes and Meshy without owner art. Which way does the owner
   want to go, biome by biome?
7. **Warrens tunnel kit** budget (W3) and **aviary dome** lattice vs membrane (C7).
8. **Multiplayer**: does a wild scale when a friend joins; may a client originate a
   wild encounter (this run implements the host-authoritative default so Stormwood
   can proceed); are wild bodies on clients meant to be unreplicated.
9. **Gil's face** needs owner reference art; **Bramblebun's** look is still under
   judge.

## 8. Definition of done for this run

Code existing is not done. The run is done when, on the integration branch and
then on `main`:

- STAB: the two-bed smoke passes ten runs; the early hitching has a named cause.
- ROAD: no road sample on any Meadows band shows fewer than two visible creatures
  in the forward 180° at shipped draw distance.
- ROSTER: all four characters play, on real input, solo and joined; the roster
  matrix has no empty cells for Cloudreach, Stormwood and Water.
- VIS: a fresh blind judge no longer leads with the inverted chroma budget, the
  absent landmarks, the Stormwood white rectangle or the flat-green Cloudreach
  stand; the Meadows sweep's 14 pairs and the Cloudreach audit doc with its 21
  pairs exist; the Hall leftovers are gone.
- COMBAT: READER outperforms MASHER at every band entry per contract §3.1, with
  the caveat about Ally readability written down.
- STORMWOOD: the main path runs from the Stormward gate through the Dynamo,
  release and aftermath in one continuous run, solo and two-peer; scorecard moved.
- WATER: rebased on current `main`, save-integrity P0 fixed, green CI on its own
  head; still draft unless the owner lifts the hold.
- MP-KEEP: the net shard and the 3/4-peer workflow green on the integration
  branch's final head; the shared-Cloudreach-fight smoke exists.
- CONTENT: the task feed drives the relay chain in a played segment; level gates
  are placed.
- PERF: render-scale setting shipped; the A/B instruction is in the owner's hands;
  nothing deep was started.
- DOCS: `CURRENT_STATE.md` §1–§3 are true for `main`; the roadmap's status rows
  are true; the fresh-session tail exists.
- The chapter and biome acceptance documents are unchanged and still govern.

The owner's sentences are the real bar: it does not freeze, you always see
creatures ahead of you on the road, it looks like one game, and the fights are
worth having.
