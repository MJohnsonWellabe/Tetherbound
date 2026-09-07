# /goal — BUILD THE FOUR-BIOME GAME TO COMPLETION

**Written 2026-09-07.** The standing contract for Codex until Tetherbound is a
finished, playable four-biome game: Meadows, Cloudreach Cliffs, Stormwood, Water
Archipelago. It supersedes `77-CODEX-GOAL-four-biome-push-2026-09-07.md` as the
top-level goal and keeps 77 as its lane detail — 77's lanes are the work items of
Phase 1 and Phase 2 here, and its §4 carries evidence you should not re-derive.

This is a **multi-run program**, not one session. It is written to be re-entered
cold: every phase has an exit criterion, every run ends with a checkpoint and a
fresh-session tail, and the next run starts by reading the last one.

---

## 0. Where to start

`codex/four-biome-push-0907`, which is PR #79. Every branch that carried unique
work is merged onto it: Water, the Stormwood hosted-combat wave, the HUD compass
work, the combat/performance/visual evidence, the owner's kickoff run, and the
documentation consolidation.

**Your first act is to land it.** Read its CI run job by job, fix what the merge
broke, and land it before starting anything else — the tree everything else builds
on has to be true first. Do not start a lane on a branch that is about to move.

**It is currently red: 5 of 25 jobs** on `e062cf1e` (run 34133703620) —
`verify-unit-tests (1)`, `verify-owner-regressions-shard`, and multiplayer shards
2, 3 and 4 (1 and 5 passed). PR #79's comment thread carries the full diagnosis;
the short version is two merge-integration defects in shared code, both reachable
only once Water met current `main`:

1. **The ledger verdict contract disagrees.** `water_veilfall.gd::host_commit`
   returns `_game.ledger.submit({...})` straight through and its test reads `.ok`
   with property syntax; on merged `main` the ledger can return a pending verdict
   with no `ok` key. Decide whether `submit()` guarantees `ok` on every path or
   whether every caller uses `.get("ok", false)`, then apply it to all callers.
   Note the test's own assertions passed — this reds the job through the
   `SCRIPT ERROR` check, which is the rule working as intended.
2. **Two per-frame handlers assume a live world.** `game_state.gd:68-69` declares
   `world` and `local` as null until a world is built, and both
   `ledger_rpc.gd::reconcile_satchel_escrow` and
   `water_capture_claims.gd::_process` dereference them on a timer. They now run
   in unit shards that never build a world. A null guard is the correct fix, not a
   workaround — but make it fail for the right reason before you trust it.

Both sit in shared multiplayer and save-adjacent code, the same surface the save
rewrite and the `session.gd` change landed on. Run the **full suite and all five
net shards** after fixing, not just the three that were red. The failing smoke
names for the net shards are in the `net-smoke-runs-{2,3,4}` artifacts on that run;
the owner-regressions failure line was not in the log tail and still needs
identifying rather than assuming.

After it lands, every other branch is fully contained in `main` and the owner will
delete them.

## 1. Read before acting

1. `CLAUDE.md` — hard rules, binding, and they override this file.
2. `docs/00_START_HERE.md` — routing, validation, branch rules.
3. `docs/owner/` — every file; the newest owner record always wins. Today that is
   `OWNER_PLAYTEST_2026-09-07.md` and
   `OWNER_DIRECTIVE_2026-09-07_AGENT_GENERATED_REFERENCE_ART.md`.
4. This file, then `docs/prompts/77-CODEX-GOAL-four-biome-push-2026-09-07.md` for
   lane detail and its §4 for evidence already gathered.
5. `docs/CURRENT_STATE.md` §0–§3.
6. `docs/DEVELOPMENT_ROADMAP.md` — the stage sequence this file executes.
7. Per phase: the exit-criteria document that phase names.

Three exit handoffs describe work that is on `main` and does not work yet. Read the
one for any lane you pick up; none of them is optimistic and all three are accurate:
`ralph/reports/WATER-PROGRESS/EXIT-HANDOFF-2026-09-07.md`,
`ralph/reports/STORMWOOD-PROGRESS/EXIT-HANDOFF-2026-09-07.md`,
`docs/CODEX_EXIT_HANDOFF_2026-09-07.md`.

## 2. What "finished" means — READ THIS BEFORE ANY PHASE

**Owner directive, 2026-09-07:
`docs/owner/OWNER_DIRECTIVE_2026-09-07_PLAYABLE_FIRST.md`.** It outranks every biome
exit-criteria document for what it covers. Read it before deciding anything is "done".

This run does **not** target the full acceptance bars. It targets one milestone:

> **THE PLAYABLE FOUR-BIOME BUILD** — a fresh save plays from the opening through the
> end of Water without a console command, a debug teleport, or a reload to advance.

Reaching that ends the run. Everything else is a second pass.

### What blocks — the only things that stop you

A criterion blocks only if failing it means the player **cannot proceed, loses data, or
the game stops working**:

1. **The path completes.** Every region enterable, every gate openable by its intended
   means, every objective advances, every required fight resolvable, every required
   reward obtainable. No dead ends.
2. **Nothing breaks.** No freeze, crash, softlock or save corruption. Saves load,
   migrate, survive realm travel.
3. **Solo is the bar.** Multiplayer must not corrupt shared state or duplicate items;
   four-peer finale, reconnect stress and separated-island proofs are deferred.
4. **`CLAUDE.md`'s hard rules hold.** Five creatures, the human never fights, real-time
   piloted combat, no storage box. These never bend for speed.
5. **Content floor, not target.** On the critical path: no dead-travel gap over 120 m,
   and every region's named encounters present and fightable — placeholders wearing
   another creature's body are acceptable.

### What is deferred — record it, never block on it

Blind visual bars on every biome. Ally performance budgets. Full §13 density counts,
dialogue-node counts, recipe counts. Meshy replacements beyond the authorised pilot.
Four-peer multiplayer proofs. Audio, VFX, animation polish. Anything a player would
describe as "it looks rough" rather than "I can't get past this".

### Anti-grind rules, binding

1. **The blind visual judge runs once per biome, to RECORD a verdict — not to pass one.**
   Log it, file the findings, move on. Never iterate a scene to change a verdict this run.
2. **One round, not two, for anything cosmetic** — grass, ground, lighting, landmarks,
   sky, night, dressing, composition, HUD. The standing rule is two no-yield attempts;
   for scene polish it is one.
   **Exception, owner amendment 2026-09-07: creature and character MESHES get up to
   THREE blind-judge rounds per subject.** Not one, not countless. The third rejection
   ends that subject — register it in `docs/SECOND_PASS_BACKLOG.md` with all three
   verdicts and move to the next. This exception exists because the judge's standing
   finding is that the cast cannot be fixed by lighting, placement, retexturing or
   rescaling; it is the one visual problem where scene work cannot substitute. It does
   **not** reopen scene polish.
3. **Take the free wins and stop.** Runtime-free data or palette changes — the
   ground/creature chroma reallocation, landmarks from installed families, the night
   relight — once, early, then move on. Do not chase what needs new art.
4. **A placeholder is a valid answer.** Ship the encounter with the wrong body rather
   than block on the right one. Register it; do not replace it.
5. **Never weaken a test, an assertion or an acceptance criterion to move faster.**
   Deferring is written down; quietly lowering one is not permitted. The first is a
   decision, the second is a lie in the ledger.

### The backlog is what makes this safe

Every deferral goes in **`docs/SECOND_PASS_BACKLOG.md`** as it happens, with what was
skipped, which criterion it belongs to, why, and what evidence already exists.
**A deferral that is not written down is a defect, not a shortcut.**

### The bars that still define done, for the second pass

Unchanged and not to be edited: `docs/DEVELOPMENT_ROADMAP.md` Stage E,
`docs/acceptance/MEADOWS_EXIT_CRITERION.md`,
`docs/biomes/cloudreach/BUILD_CLOUDREACH_CLIFFS_TO_COMPLETION.md`,
`docs/biomes/stormwood/BUILD_STORMWOOD_TO_COMPLETION.md` §32, and
`docs/biomes/water/BUILD_WATER_ARCHIPELAGO_TO_COMPLETION.md` §21. No document may be
edited to make a deferred criterion look satisfied.

The binding principle still holds, read against the playable bar rather than the full one:

> A region or system is not done because code and data exist. It is done when the
> complete player path produces the intended Tetherbound experience.

## 3. Order of work

Phases are ordered by what has to be true before the next thing is worth doing.
Within a phase, run lanes in parallel. Phase 4 (visual and art) runs **beside**
Phases 2 and 3 the whole way, because art has the longest lead time and because the
owner's priority is that the game look good.

### Phase 0 — land PR #79 and make the tree trustworthy

Three things landed unproven by their own authors, and shipping on top of them is
building on sand. Lane detail in 77: **SAVE**, **HUD-MAP**, **STORMWOOD-HOSTED**.

- **SAVE.** The save rewrite that arrived with Water now governs every save in every
  biome. Prove it against an existing pre-merge save, backup-only fallback, a corrupt
  canonical file, split world/character failure, and the full suite — or revert it to
  the prior code plus the minimal `store_string`-result check that fixes the original
  truncation bug. This is the highest-risk item in the repository.
- **HUD-MAP.** The minimap is gone and the map's second open is corrupt on the real
  Meadows world. Fix it, or restore the minimap and keep the compass on a branch.
- **STORMWOOD-HOSTED.** Host-owned Stormwood combat is on `main`, its smoke fails at
  trainer start, and it changed shared `scripts/net/session.gd` without the full suite
  its own handoff required. Make it work with all five net shards green, or revert it.

**Exit:** PR #79 on `main`, all three resolved one way or the other, full suite and
every net shard green, `docs/CURRENT_STATE.md` true.

### Phase 1 — the owner's playtest, which outranks everything

From `docs/owner/OWNER_PLAYTEST_2026-09-07.md`. Lane detail in 77: **STAB**, **ROAD**,
**ROSTER**.

- **The game must not freeze.** A hard freeze placing a second creature bed, and
  repeated freezes in the first ten minutes. 77 §STAB-LEADS has a static root-cause
  read with the exact call chain; start there, do not re-derive it.
- **Creatures on the road.** "I'd expect to always be able to see multiple creatures
  in a 180 view in front of me." Build the probe that measures what the *player sees*,
  then fix the data. The existing 250 m contract passes on paper and is not the bar.
- **The roster and the characters.** 57 species have meshes; the 32 new ones are in no
  spawn, encounter or trainer table. Four characters are offered but the choice is not
  saved and other players see the wrong body.

**Exit:** a fresh game plays its first hour on the Ally without a freeze, no road
sample shows fewer than two creatures ahead, every new species appears where its
design puts it, and all four characters work solo and joined.

### Phase 2 — finish Stormwood (Biome 3)

`docs/biomes/stormwood/BUILD_STORMWOOD_TO_COMPLETION.md` is the contract;
`ralph/reports/STORMWOOD-PROGRESS/EXIT-HANDOFF-2026-09-07.md` is the live tail and
its status table is honest about what is "implemented but unproven" versus "blocked
by missing implementation". Scorecard is 12/100.

The blocked main path, in order: host-owned remote encounter starts → the six named
encounters and the Crown guardian → the Stormheart Dynamo controller with Marrow's
three phases → the captive legendary release and five-slot ceremony → Spark and
Livewire → the storm aftermath → the non-enterable Waterward view that hands off to
Water. Then the continuous chapter run, solo and two-peer.

**Exit for THIS run (§2's playable bar, not §32):** a player entering from a completed
Cloudreach save reaches the Waterward view through ordinary play — every gate, objective,
named encounter, the Dynamo, the release and the aftermath — solo, with no console, no
debug teleport and no reload to advance. Placeholders are fine. §32's visual (#14),
performance (#15) and full density (#7) criteria are **deferred to the second pass** and
recorded in `docs/SECOND_PASS_BACKLOG.md`; run the blind judge once to log a verdict and
do not iterate on it.

### Phase 3 — finish Water (Biome 4)

The design directive and `BUILD_WATER_ARCHIPELAGO_TO_COMPLETION.md`;
`ralph/reports/WATER-PROGRESS/EXIT-HANDOFF-2026-09-07.md` is the live tail.
Scorecard is 35/100. The foundation is real — twelve islands, swimming and drowning,
five mounted swim species, docks, camps, the Veilfall interior, the Guardian ceremony
— and the chapter still cannot be entered by ordinary play.

Corrected blockers, from that handoff: no production emitter for the
`aftermath:waterward_view` reveal and no Water transition point (depends on Phase 2's
ending — do not duplicate it); late joiners can be permanently denied the Swim Stone;
the Aquaryn Alpha fight is dry, with an empty `surface_route`. Then the first-half
route with real stamina and resources, the six side chains, the objective spine
(twelve of 28–32 exist), named encounters through host authority, the four-peer
finale and reconnect, and the aftermath.

**Exit for THIS run (§2's playable bar, not §21):** a player reaches Water through
ordinary play — the Spark-gated reveal and the one-time key — and completes the route to
the legendary climax, solo, with no console and no dead ends. A late joiner can still
earn the Swim Stone. §21's visual, performance, full-density and four-peer criteria are
**deferred to the second pass** and recorded in `docs/SECOND_PASS_BACKLOG.md`.

### Phase 4 — how it looks, running beside Phases 2 and 3

The owner's words: "Focus more on making things look good and the rest of the
content." Lane detail in 77: **VIS-MEADOWS**, **VIS-CLOUDREACH**, **VIS-HALL-WARRENS**,
**ART-PILOT**.

- The two free wins first: **reallocate the chroma budget** (the ground is the most
  saturated thing in frame and the creatures the least — Palworld is the opposite) and
  **give the road landmarks** (23 of 24 route stages have nothing to navigate by).
- The owner's two sweep goals, `docs/owner/MEADOWS_VISUAL_SWEEP_GOAL_2026-09-06.md`
  and `CLOUDREACH_VISUAL_AUDIT_AND_SWEEP_GOAL_2026-09-06.md`, in full. Cloudreach is
  audit-first and its Phase A document does not exist yet.
- Stormwood and Water have never passed a blind visual round at all.
- **ART-PILOT** is §4 below.

**Exit for THIS run:** the free wins are taken once, and a code-blind judge has been run
**once per biome to record a verdict** — not to pass one. File every finding to
`docs/SECOND_PASS_BACKLOG.md` and move on. The "no biome reads as a prototype" bar is the
second pass's exit, not this run's. If a judge fails a scene twice, that is the signal to
stop, not to try a third time.

### Phase 5 — the four-biome product audit

**Scoped to the playable bar this run.** The audit's job here is to find what stops a
player finishing, not to grade polish: dead ends, softlocks, save corruption, missing
rewards, unfightable encounters, dead travel over 120 m on the critical path. Record the
polish findings — visuals, density, balance, performance — straight into
`docs/SECOND_PASS_BACKLOG.md` without fixing them. The full six-question audit in
`docs/DEVELOPMENT_ROADMAP.md` Stage C is the second pass's opening move.

`docs/DEVELOPMENT_ROADMAP.md` Stage C, its six questions, in full: does it work, is
there enough to do, is progression satisfying, is it fun minute to minute, does the
world feel authored, does it meet the visual bar. Real runtime evidence and a density
census across all four biomes, not another architecture inventory. Output is a short
ranked P0/P1/P2/DO-NOT-WORK repair plan, not a 300-item backlog.

### Phase 6 — the repair pass, then Beta Ready

Stage D: close every P0 and every Beta-blocking P1 before any new content. Then
Stage E, the four-biome Beta Ready gate — continuous completion, multiplayer
reliability, onboarding, performance on the Ally, visual consistency, density
consistency, progression balance, save migration, release hygiene.

**This is where performance finally gets its full pass.** Until then it is cheap wins
only, per the owner: a render-scale setting (none exists, and the Ally runs at
2053×1080 on an integrated GPU), and preparing the grass A/B for the owner's own
twenty-minute run, which is still the only measurement that settles the frame rate.
Do not fund a deep optimisation track from a container before Stage E.

## 4. The art loop — agent-generated reference art

Authorised by `docs/owner/OWNER_DIRECTIVE_2026-09-07_AGENT_GENERATED_REFERENCE_ART.md`,
which lifts two `CLAUDE.md` rules — the "owner-supplied reference art" precondition and
the Meadows Meshy ban — for a **pilot of one subject**. Full task detail is 77's lane
ART-PILOT.

The problem it exists to solve: the blind judge's standing verdict is that the cast is
"three incompatible languages" — a stylised rock-shelled tortoise that matches the
world, a recoloured photoreal eagle, generic photo-fur deer, a badger head grafted onto
a rock shell inside one silhouette, a trainer and a villager in two different character
styles — and that this **cannot** be closed by lighting, placement, retexturing or
rescaling. Every cheaper lever has been spent.

The loop:

1. Choose one creature or character, justified from the blind verdicts in the repo.
2. Generate **three** reference images — same subject, three genuinely different takes.
   Clean character-sheet framing, plain background, full body, neutral pose, one
   creature, no base, no text. Identity comes from `species.json` and the subject's
   `SPECIES_PROMPTS` entry in `tools/art_pipeline/meshy.py`, which is deliberately
   authoritative over "anything an image generator wrote onto a sheet". House style is
   that file's `STYLE` constant, and the target is the installed stylised end of the
   cast.
3. A **code-blind** judge picks the winner — shown the three plus the installed cast,
   told nothing about which is which or which you prefer. It may answer "none of
   these", which stops the loop at zero credits spent.
4. Run Meshy from the winner. `meshy.py` takes any local PNG as a data URI, so a
   generated image is the same input as a cropped owner board.
5. Judge the finished mesh **in the world, beside the creatures it has to live with**.
   A mesh that looks good alone and still clashes has failed the only thing this was
   for. Then write the `docs/specs/ASSET_LEDGER.md` row.

**If this session cannot generate images at all**, say so plainly in the report and run
`/openapi/v2/text-to-3d` instead — it needs no image and every subject already has a
prompt. Do not fabricate a board and do not silently skip the work.

**Credits.** `MESHY_API_KEY` is read from the environment and nowhere else. Run
`tools/art_pipeline/meshy.py balance` before spending anything and record the number;
the 33-creature batch in PR #78 left no ledger row, so the repo cannot currently state
the balance. The art-source order still applies first — installed asset, then free
pack, then Meshy; the ledger's own cautionary tale is 120 credits spent chasing a
mushroom that was already in `assets/environment/`.

**Scope and budget.** The pilot is one subject. If its blind judge passes it and the
owner has set a credit ceiling in this goal's invocation, extend the same loop to the
judge's other named offenders, worst first, stopping at that ceiling or at the first
subject the judge rejects twice — whichever comes first. Without a stated ceiling, stop
after the pilot and report what a full pass would cost. Never spend past a ceiling to
finish "just one more".

## 5. How to work

**Branches and landing.** Never push to `main`. Work on `codex/<task>` or
`ralph/<TASK>` branches and land through pull requests. CI runs only on
`pull_request` events and on pushes to `main`, so a branch without a PR is never
verified — open the PR early. A newer push cancels the run in flight on the same ref,
so batch pushes rather than fragmenting them. A run under five minutes verified
nothing; a full run is 18–25 minutes. Read every job. A retry that turns 0-for-1 into
green is a finding, not a pass. "Landed" means `git merge-base --is-ancestor`, never a
badge. Land in reviewable pieces — one coherent change per PR — rather than one
enormous drop at the end.

**Parallelism.** Many sub-agents at once, each with a written brief: the branch, the
player-visible outcome, the files it owns, the files it must not touch, the tests it
runs, whether it is visual, and a stop condition. Lanes touching independent files run
together; lanes sharing `playground_hud.gd`, `game_state.gd`, `playground_world.gd`,
`vegetation.json`, `grass_field.json`, `species.json`, `save_game.gd`, `world_save.gd`,
`session.gd` or `combat_manager.gd` are serialized on that file. One Godot render at a
time per box.

**Checkpoints and stopping.** Checkpoint every two wall-clock hours to
`ralph/reports/FOUR-BIOME-BUILD/checkpoints.md`: player-visible capability added, paths
newly reachable, systems newly working in real play, content added, merged SHA,
blockers, next highest-value task. Credit counts only for work merged with runtime
evidence; a missed checkpoint is a delta of zero, not a pause. **Two no-yield attempts
on one narrow issue is a trigger to change strategy** — no third near-identical
attempt, no repeated harness run without a changed hypothesis, no micro-tuning one axis
after two no-yield rounds, no acceptance criterion rewritten to manufacture progress.
Two consecutive checkpoints with no material delta: stop building, integrate what is
done, write the final report and a fresh-session tail, and hand the narrow tail to a
fresh run. Front-load broad playable progress; do not spend the end of a long run
grinding a tail after the chapter is broadly built.

**Testing and evidence.** Smallest test that answers the current question while
building; the full suite for save, autoload and shared-state changes and at every
landing wave. Tests exercise real behaviour — real input events, real open/close
cycles, persisted player-facing state. Never skip, disable or weaken a test to get
green. A world boot is its own test: grep its log for `^ERROR:`, not just
`SCRIPT ERROR`, and watch whether the distinct set grows. Address inventory by item
identity, never by slot number. Never `--headless` together with a rendering driver.
Never judge your own frames — every visual round goes to a code-blind sub-agent, and
two rounds that name no new defect and move no measured axis means record the ceiling
and stop.

**Decisions.** Record settled decisions in `docs/decisions/`. Ask the owner only when
implementation requires choosing between materially different game behaviours that
nothing in the repo settles — the open list is 77 §7. Implementing a documented owner
directive is ordinary work, not a question. Do not silently invent a major gameplay or
story decision.

**Keep the documents true.** `docs/CURRENT_STATE.md` is the evidence-backed status and
must describe what is actually on `main`; `docs/DEVELOPMENT_ROADMAP.md` carries the
stage states. Update both when state materially changes. Archive superseded documents
rather than leaving two truths in the tree.

## 6. What never bends

From `CLAUDE.md`, which overrides this file wherever they touch:

- Godot is locked. Windows and the ROG Ally are primary. Controller first.
- **Five creatures total.** No storage, no reserve box, no hidden sixth slot.
- The human never fights. Creatures do not perform base jobs.
- Creature combat is real-time and directly piloted. No shields.
- Catching is available during wild combat; trainer-owned creatures cannot be caught.
- No hunting or butchering. Light satiety only — no starvation death.
- Slot and stack inventory; no carry weight. Multiple death satchels persist.
- Creatures stand taller than the 1.80 m trainer; fix relative-scale defects by growing
  the smaller side, never by shrinking.
- One nature family, one village family, one prop family. Reuse the installed humanoid
  cast. The art carve-out in §4 is scoped to its pilot subject and nothing else.
- Every new system is multiplayer-native from its first implementation.

## 7. Definition of done for this goal

The four-biome Beta Ready gate in `docs/DEVELOPMENT_ROADMAP.md` Stage E:

- a fresh player completes opening → Meadows → Cloudreach → Stormwood → Water without
  developer intervention, solo and on a representative multiplayer path;
- 1–4 player co-op is reliable across join, leave, reconnect, realm transitions, boss
  fights, building, gathering, catches, death and revive, sleep, storage and save;
- no open P0s; every Beta-blocking P1 closed;
- saves are trustworthy and migrate;
- performance is acceptable on the Ally;
- content density is consistent and later biomes are not thinner than earlier ones;
- a new player understands the game without external instructions;
- a blind judge says the whole thing reads as one cohesive commercial stylised game.

The owner's own sentences remain the real bar: it does not freeze, you always see
creatures ahead of you on the road, it looks like one game, the fights are worth
having, and the first clear is 3–4 focused hours that feel like a finished chapter.
