# Spawn request — four parallel fix lanes, T2-GATEF operator, 2026-08-30

**Written by:** the T2-GATEF operator lane (`ralph/T2-GATEF`), at the owner's
explicit request, because this session's own `create_session` calls could
not get past a permission gate in this environment (four attempts, both
before and after the owner said he'd approved them, all returned
`MCP tool call requires approval`). **This document is the exact, ready-to-use
spawn spec for whoever can actually call `create_session`** — the coordinator,
or the owner directly — so none of the scoping work has to be redone.

**Do not start the S03-S10 re-run, and do not run X03 or X06, until at least
lane 1 below reports a healthy `S03-exit.json` — verified by reading the
save's actual party HP, not by trusting "complete: true".** Everything else
in Gate F run 3 that could be run without that fix has already been run by
this operator lane; see `ralph/reports/handover-T2-GATEF-2026-08-30.md` for
the full account.

---

## Why four lanes, and why these four

Gate F run 3's evidence past S03 is compromised by one root cause (a fainted
party from S03 that nothing ever heals — see `ralph/reports/
FINDING-T2-STRANDING-2026-08-30.md` and `ralph/reports/
FINDING-T2-BUILDPLACE-2026-08-30.md` for the full chain), plus three smaller,
independent, already-diagnosed defects that don't block each other and don't
touch each other's files:

| Lane | Fixes | Files touched | Blocks |
|---|---|---|---|
| 1. T2-BUILDPLACE round 2 | The one remaining gap in the S03 fix: reliably walking to Mira | `tools/gate_f/segments/S03.json`, new probes under `tools/gate_f/` | Everything downstream — this is the hard gate |
| 2. T2-S10-COST | S10's real cost-gate BLOCKER (a capacity limit, not a bug) | `tools/gate_f/segments/S10.json` (split into sub-segments) | Only S10's own evidence; independent of lane 1 |
| 3. T2-GATEF-RIGFIXES | RIG-19 (X04's undersized `move_to` budgets) + RIG-22 (X05's wrong-tab save checks) | `tools/gate_f/segments/X04.json`, `tools/gate_f/segments/X05.json` | Only X04/X05's own evidence; independent of lane 1 |
| 4. T2-RIG10 | `save_out` never verifies the slot actually changed (already bit this run once — byte-identical S03/S04/S05 exit saves went undetected) | `tools/gate_f/operator_harness.gd`, scoped to the save-step functions only | Nothing directly, but protects every future segment's handoff integrity |

File scopes were chosen so all four can run **fully in parallel with no
merge conflicts**: S03.json / S10.json / X04+X05.json / operator_harness.gd's
save-functions-only are four disjoint surfaces. Lane 4's prompt explicitly
tells it to stay narrowly scoped within `operator_harness.gd` so it doesn't
collide with lane 2, which may also need to touch that file's cost-gate
logic (a different section of the same file).

Only lane 1 gates anything — lanes 2-4 can run, finish, and land independently
of whether lane 1 converges.

---

## Exact `create_session` calls to make

Each block below is a complete, self-contained call. Copy the `prompt` field
verbatim — it was written assuming the reader has no memory of this
conversation, includes exact file paths, function names, and evidence
citations, and tells each lane exactly what NOT to touch.

### Lane 1 — T2-BUILDPLACE round 2

```
title: T2-BUILDPLACE round 2 — Mira positioning fix
source_url: https://github.com/MJohnsonWellabe/Tetherbound
source_revision: ralph/T2-BUILDPLACE
outcome_branch: ralph/T2-BUILDPLACE
tags: ["gate-f", "T2-BUILDPLACE", "parallel-fix-lane"]
```

```
You are continuing the T2-BUILDPLACE lane on the Tetherbound repo (Godot game, `github.com/MJohnsonWellabe/Tetherbound`). Read `CLAUDE.md` first, then read `ralph/reports/FINDING-T2-BUILDPLACE-2026-08-30.md` and `ralph/reports/handover-T2-BUILDPLACE-2026-08-30.md` in full before doing anything else — they are the complete record of what a prior session on this exact branch already found and tried.

## Where things stand

Gate F run 3 (`ralph/reports/gate-f-run-20260828T183531Z`) found that the whole chapter's evidence past S03 is compromised: the player's only creature faints during S03's ordinary catch-loop attempts (a fair game outcome), and nothing in the S03 step-script ever heals it before the tutorial's sleep step, so every trainer/gate fight from S04 onward correctly refuses to start for the rest of the run (verdict: RIG, not GAME — confirmed live in the engine, see `ralph/reports/FINDING-T2-STRANDING-2026-08-30.md` for the original root-cause chain).

The prior T2-BUILDPLACE session fixed the actual build-placement bug (S03's gathering loop never equipped a tool before harvesting tool-gated resources — `harvest_logic.gd` gates wood/stone/fiber on an equipped tool by design) and, while proving that fix out, independently found and flagged (but correctly did NOT fix, since it's outside this lane's file ownership) a second, more severe GAME defect: `scripts/combat/encounter_director.gd::interaction_offer()` unconditionally returns a priority-100, distance-0 "is out of the fight" prompt whenever the tracked ally is fainted, with no proximity gate, which outranks every other interaction in the world for the rest of the session until a reload. That defect belongs to a concurrent T3-TYPECHART lane (`scripts/combat/**`) — do not touch it; if you rediscover it, just note that it's already documented.

## What is NOT yet solved — your actual job

Ten full-segment replays never got a reliable walk to Mira during S03's tool-granting visit. The catch loop's own upstream RNG shifts the player's exact position entering that leg enough that the same walk target lands anywhere from 0-120 held frames and 2.27m-4.9m short, run to run. Every tolerance/coordinate/primitive combination tried (`move_to` at a fixed coordinate, `move_to_entity` against Mira's live position, tightening/loosening `close_enough`/`within`) has been inconsistent. **No healthy `S03-exit.json` exists anywhere yet.**

The prior session's own diagnosis of why: they wrote a diagnostic raycast probe late in their session, found it unreliable (it likely hit Mira's own collision body rather than real wall geometry, because it did not replicate the two clearance trims that the real game function applies), and deleted it rather than commit unreliable evidence. **Their own stated next step, which you should do first rather than guess at more tolerances:**

1. Read `scripts/world/interactable.gd::_has_line_of_sight` in full — understand its exact clearance-trimmed raycast, including both trim constants it applies before casting.
2. Either (a) write a new live-engine probe (`tools/gate_f/probe_mira_los_check_v2.gd` or similar) that replicates that exact logic against Mira's real live position and the walker's real historical stop points (several are recorded in the finding doc, with exact coordinates and held-frame counts), so you can see definitively which check is refusing and why; or (b) add temporary debug prints inside `interaction_offer()` itself (radius check vs. line-of-sight check — which one fails) and read the answer directly from a live segment replay. Either is fine; the point is to get a real answer instead of another blind tolerance guess.
3. Once you know the actual cause, fix `tools/gate_f/segments/S03.json`'s Mira-approach step so it reliably reaches her regardless of the catch loop's RNG variance. This might mean widening a genuinely-safe tolerance, using a different approach angle, adding a settle/retry loop, or something else entirely — let the diagnostic tell you, don't guess.
4. **Prove it**, the same way the prior session tried to: run a real, full S03 replay via `tools/gate_f/run_segment.sh` into a fresh scratch run directory (see `ralph/reports/gate-f-buildplace-validation/` for the prior session's exact invocation and the local `RUN_METADATA.json` shape needed to satisfy the harness's capture pre-flight), then **read the resulting `S03-exit.json`'s actual party HP directly** — do not trust `"complete": true` or a probe's own PASS as proof of a healthy party. The prior session's own round-1 probe (`probe_mira_intro_grant.gd`) passed clean on a fainted-party scenario it constructed by hand, and completely missed the real bug, because it set state directly on a data object rather than going through the same summon/faint path the real game uses (`encounter_director.gd`'s own cached `_ally` reference). Don't repeat that mistake — validate against a REAL replay's REAL save file, not a synthetic probe alone.

## File ownership — stay in scope

You may touch: `tools/gate_f/segments/S03.json`, and add new probe scripts under `tools/gate_f/` (with `.uid` files as Godot requires). You may READ `scripts/combat/encounter_director.gd` and `scripts/world/interactable.gd` freely. **Do NOT edit either of those two game-code files** — the first belongs to T3-TYPECHART, and the second is core movement/interaction code with wide blast radius; if you determine a real game-code fix is warranted anywhere, name it precisely in your findings doc rather than touching it.

Three other lanes are working in parallel on other files and will NOT touch `S03.json`: one on `S10.json`'s cost-gate problem, one on `X04.json`/`X05.json` step-script bugs, one on `operator_harness.gd`'s save-verification logic. You do not need to coordinate with them, but don't be surprised if `operator_harness.gd` changes underneath you — if a validation run behaves unexpectedly and you don't recognize why, check whether that file has new commits from `ralph/T2-RIG10` before assuming your own change is at fault.

## Environment setup (fresh container, budget this up front)

Godot is not preinstalled:
```
curl -fL -o g.zip https://github.com/godotengine/godot/releases/download/4.7-stable/Godot_v4.7-stable_linux.x86_64.zip && unzip -o g.zip && chmod +x Godot_v4.7-stable_linux.x86_64 && mkdir -p ~/.cache/tetherbound-art && mv Godot_v4.7-stable_linux.x86_64 ~/.cache/tetherbound-art/godot
```
Then `~/.cache/tetherbound-art/godot --headless --path . --import` once (~5 min, produces `.godot/imported/`, gitignored, redo on any fresh container). Never combine `--headless` with `--rendering-driver` — hangs forever. This work is all headless/logic-mode (no rendering driver needed).

## Branch and deliverable

Work on branch `ralph/T2-BUILDPLACE` (checkout `origin/ralph/T2-BUILDPLACE`, continue it — do not start a fresh branch). Commit and push per meaningful step, not one batch at the end. When done (fix converges, or you've spent a genuinely thorough effort and it still doesn't), write `ralph/reports/handover-T2-BUILDPLACE-ROUND2-2026-08-30.md` following the same structure as the existing `handover-T2-BUILDPLACE-2026-08-30.md` (what you did, what's verified vs. not, disagreements, file footprint, exact commands, next steps). If you converge on a healthy `S03-exit.json`, say so unambiguously and paste the actual party HP value from the save file in your handover — that is the single fact everyone downstream is waiting on.
```

### Lane 2 — T2-S10-COST

```
title: T2-S10-COST — split S10 under the cost ceiling
source_url: https://github.com/MJohnsonWellabe/Tetherbound
source_revision: main
outcome_branch: ralph/T2-S10-COST
tags: ["gate-f", "T2-S10-COST", "parallel-fix-lane"]
```

```
You are a new fix lane on the Tetherbound repo (Godot game, `github.com/MJohnsonWellabe/Tetherbound`). Read `CLAUDE.md` first, then `ralph/GATE_F_MASTER_PROTOCOL.md` (focus on §H.3, the cost-gate mechanism, and §A's blocker rule), then `ralph/reports/gate-f-run-20260828T183531Z/S10/BLOCKER.md` and `.../S10/INVENTORY.json` — the real, measured evidence from the actual blocked run — before doing anything else.

## The problem

S10 (the finale journey segment: Hall entry → gauntlet → recovery → elite → the Warden → the legendary choice → release ceremony) is a single step-script (`tools/gate_f/segments/S10.json`) run under a hard 14,400-second (4-hour) per-segment wall-clock cost ceiling that the harness (`tools/gate_f/operator_harness.gd`) enforces to keep any one segment from silently running for days. In the real Gate F run 3 evidence, S10 ran 27 of its 121 steps before the harness's own cost gate refused to continue:

```
re-priced at in-play, the REST of this segment predicts 40195 s (11.2 h)
against 13974 s of the 14400 s ceiling left: 413884 planned frames at a
MEASURED 0.097 s/frame in THIS scene, plus a 0 s boot. The last price was
0.0400 s/frame.
```

The price jump (0.04 → 0.097 s/frame) happened immediately after a real combat exchange (`combat_quick` x38, a party switch, `combat_quick` x24) and the rest of S10's content is combat-dense (the gauntlet, elites, the Warden fight, the legendary sequence). This has already been assessed by a prior operator as a **genuine capacity limit measured on this specific hardware (single-core CPU, headless logic mode — no GPU involved, this is pure game-logic cost), not a pricing bug** — unlike an earlier, since-fixed defect (nicknamed CD-7c in this run's history) where the cost gate genuinely mispriced a scene-standup's transient cost. Do not go looking for a pricing bug here; there almost certainly isn't one. The problem is real: S10's actual content costs more real time than the ceiling allows in one segment.

## Your job

Get real S10 evidence produced within the existing infrastructure, without weakening the cost gate itself (it exists for a good reason — see the master protocol's own §H.3 history of what happens when segments aren't priced honestly) and without just raising the ceiling blindly (that could let a genuinely runaway segment consume a whole session; if you conclude raising it IS the right call for this one segment specifically, justify it explicitly with numbers, don't just bump a constant).

**The approach a prior operator suggested, which you should evaluate and most likely implement:** split `S10.json` into multiple sub-segments (e.g. `S10a` = Hall entry through the gauntlet and recovery, `S10b` = elite fights through the Warden, `S10c` = the legendary choice and release ceremony — or whatever split the actual step content supports), each individually costed to land comfortably under the 14,400s ceiling, chained by save handoff exactly the way the main journey segments (S01→S10) already chain (`S0n-exit.json` produced by one, consumed by the next via `seed_save`). Look at how `S01.json` through `S09.json` structure their own entry/exit save steps for the pattern to follow, and at `ralph/GATE_F_MASTER_PROTOCOL.md`'s §B table for how segment boundaries are chosen elsewhere in the protocol (natural narrative/gameplay gates, not arbitrary step counts).

Use the real S10 telemetry from the blocked run (`ralph/reports/gate-f-run-20260828T183531Z/S10/telemetry/events.jsonl` and `route.csv`) to estimate where the combat-heavy sections actually are, so your split boundaries land the expensive content inside individually-affordable sub-segments rather than concentrating it all in one.

If, after actually doing this analysis, you conclude splitting doesn't solve it (e.g. even the smallest sensible sub-segment is still over budget because of one single unavoidable long fight), say so plainly in your findings and propose the real alternative (a faster host, a GPU, or an owner-level scope decision about what S10 evidence is actually required) rather than forcing an unconvincing split.

## Validating your work honestly

**You do not have a healthy chain to seed a full validation run from yet** — S10 needs `S09-exit.json`, and no healthy one exists in this run (a separate, concurrent lane — `ralph/T2-BUILDPLACE` — is working on the upstream blocker; do not wait for them, and do not touch their work). So:

1. Validate the **harness mechanics** of your split (does `S10a`'s step-script run to completion and produce a real exit save; does `S10b` correctly seed from `S10a`'s exit and continue; does the cost-gate math actually land where you predicted) using whatever save you have available — even the existing, stranded `S09-exit.json` from `ralph/reports/gate-f-run-20260828T183531Z/S09/saves/S09-exit.json` is fine for this, since you are testing the RIG mechanics of segment chaining and cost pricing, not making any claim about the game itself. **Be explicit and unambiguous in your findings doc that any run using the stranded save is mechanics-only validation, not game evidence** — this run's whole recent history is full of exactly this confusion (rig evidence mistaken for game evidence) and the write-up should not add to it.
2. A real, evidence-bearing run of your split segments needs to wait for a healthy chain from the other lane. Your job is to have the split ready and proven-mechanically-sound so that when a healthy `S09-exit.json` exists, running your S10a/S10b/etc. is a drop-in replacement for the old monolithic S10.

## File ownership — stay in scope

You may touch: `tools/gate_f/segments/S10.json` (and its replacement/split files, e.g. new `S10a.json`, `S10b.json`, etc. — update `ralph/GATE_F_MASTER_PROTOCOL.md`'s §B table if you rename/split segment IDs, since that table is the authoritative segment list). You may need to read `tools/gate_f/operator_harness.gd`'s cost-gate logic closely to understand exactly how pricing/re-pricing works, but **avoid editing it** unless the split alone genuinely cannot work without a harness change — if so, scope your edit narrowly to the cost-gate/pricing code path only. A separate, concurrent lane (`ralph/T2-RIG10`) is editing a DIFFERENT part of that same file (the save-verification/`save_out` logic) — if you must touch `operator_harness.gd`, keep your diff far from anything related to `_step_save_out`/`seed_save` to avoid a merge conflict, and say so explicitly in your commit messages.

## Environment setup (fresh container, budget this up front)

Godot is not preinstalled:
```
curl -fL -o g.zip https://github.com/godotengine/godot/releases/download/4.7-stable/Godot_v4.7-stable_linux.x86_64.zip && unzip -o g.zip && chmod +x Godot_v4.7-stable_linux.x86_64 && mkdir -p ~/.cache/tetherbound-art && mv Godot_v4.7-stable_linux.x86_64 ~/.cache/tetherbound-art/godot
```
Then `~/.cache/tetherbound-art/godot --headless --path . --import` once (~5 min). Never combine `--headless` with `--rendering-driver` — hangs forever. This is all headless/logic-mode work.

## Branch and deliverable

New branch `ralph/T2-S10-COST` off `origin/main`. Commit and push per meaningful step. Write `ralph/reports/handover-T2-S10-COST-2026-08-30.md` when done: your analysis, your chosen approach and why, what's mechanically validated vs. still blocked on a healthy save chain, exact commands to reproduce, and a clear recommendation for whoever runs the real S10 evidence once it's unblocked.
```

### Lane 3 — T2-GATEF-RIGFIXES

```
title: T2-GATEF-RIGFIXES — RIG-19 + RIG-22
source_url: https://github.com/MJohnsonWellabe/Tetherbound
source_revision: main
outcome_branch: ralph/T2-GATEF-RIGFIXES
tags: ["gate-f", "T2-GATEF-RIGFIXES", "parallel-fix-lane"]
```

```
You are a new fix lane on the Tetherbound repo (Godot game, `github.com/MJohnsonWellabe/Tetherbound`). Read `CLAUDE.md` first, then `ralph/GATE_F_MASTER_PROTOCOL.md` for context on what these step-script segments are, then the two findings below in full.

## Your job: fix two independent, small, mechanical rig defects

Both were found by an operator running Gate F run 3's evidence in `ralph/reports/gate-f-run-20260828T183531Z/`. Full detail is in `ralph/reports/GATE_F_RUN_3_RIG_FINDINGS.md` under "RIG-19" and "RIG-22" — read both sections in full before starting. Summary of each:

### RIG-19 — `tools/gate_f/segments/X04.json`'s `move_to` steps have no budget and undershoot every combat site

X04 (the combat lab) has seven `move_to` steps (`X04-019`, `X04-030`, `X04-058`, `X04-066`, `X04-078`, `X04-094`, `X04-111`) targeting its named combat sites, none of which specify an explicit `budget_frames` in their `args`. The harness defaults to a value (empirically ~2400 frames, roughly 40 seconds of game time) far too small for the real distances involved — in the actual run, every one of these steps FAILed, undershooting by 110m to 6278m depending on the step, across all three of X04's entry saves (`ralph/reports/gate-f-run-20260828T183531Z/X04/notes/X04.md` has the exact FAIL lines with stopped-at coordinates and distances-short). One case (`X04-030`/`058`/`066`/`078`, all targeting the same coordinate `(195, 905)`) shows real cumulative progress across repeated attempts (1109→530→402→283→110m short), confirming `move_to` correctly resumes from wherever the player stopped — it just isn't given enough attempts/budget to actually arrive.

**Fix:** give each of these seven `move_to` steps an explicit `budget_frames` sized to the real distance from its entry point. Look at how the main journey segments (`S06.json` through `S10.json`) size their own `move_to` budgets for multi-hundred/multi-thousand-meter walks — they specify large explicit `budget_frames` values (tens of thousands) precisely because they know the real distance in advance. Do the same math here: measure or estimate the real distance from each entry save's actual starting position (readable from `ralph/reports/gate-f-run-20260828T183531Z/S04/saves/S04-exit.json`, `S06/saves/S06-exit.json`, `S09/saves/S09-exit.json` — or from the segment's own telemetry) to each target coordinate, and size the budget generously (the measured walking cost on this hardware is roughly 0.017-0.03 s/frame; convert your target real-world seconds-of-in-game-walk-time to frames at ~10-15 frames per meter as a rough starting ratio, then round up generously — being over-budget costs nothing but a few wasted CPU-seconds if the target is reached early; being under-budget produces exactly the FAIL this defect describes).

### RIG-22 — `tools/gate_f/segments/X05.json`'s save-verification steps land on the wrong tab

X05 has one "verify a normal save" block per journey exit save (e.g. `X05-015` through `X05-018`), and each opens the pause shell with a bare `open_menu` (no tab specified) then presses `menu_tab_right` a fixed 5 times, assuming the shell reopens on the Backpack (index 0) tab. It does not — `game_menu.gd` reopens the shell on whichever tab was LAST used, which is a state that persists across steps within the same segment. In the real run, **at least 7 of the 8 completed blocks landed on the wrong tab** (`input_context=menu_backpack`/`menu_quest_log`/`menu_creatures`/`menu_settings`, wanted `menu_save` every time), and the immediately-following save-write assertion correctly reported "FAIL slot N has no file... did the Save tab actually write?" — not because saving is broken, but because the Save tab was never actually reached. Confirmed as tab-specific and fixable: `X01-350` in a different segment does the identical probe via a *named* tab open and correctly reports `menu_cancel closed the shell: context menu_map -> world` — proving a named-tab approach works when used.

An identical defect shape (there called RIG-14) was already found and fixed elsewhere in this run's history, in `S06.json` and `S08.json`'s own save steps — **read those two files' save-tab-opening steps as your reference pattern** (they open via a named tab argument, e.g. `{"tab": "map"}` as an intermediate anchor, then press a smaller, correct number of times to reach Save from a known starting point, rather than assuming Backpack). Apply the equivalent fix to every one of X05's own save-verification blocks (there are 9, one per `S0n-exit` from S02 through S10, per `tools/gate_f/segments/X05.json`'s own `seed_save` list — grep the file for `menu_tab_right` to find all of them).

## Validating your work honestly

**Entry saves for both segments may still be compromised** (fainted party from an upstream, separately-being-fixed defect — a concurrent lane, `ralph/T2-BUILDPLACE`, is working on that; do not wait for them, do not touch their work). That's fine for validating YOUR fixes specifically:
- For RIG-19 (X04): confirm the `move_to` steps now actually REACH their targets (position matches within a few meters, no more "did not reach" FAILs) — whether a fight then successfully starts once arrived is a separate question gated on the party-health fix, not something your fix needs to solve.
- For RIG-22 (X05): confirm the shell now correctly lands on `menu_save` context every time, regardless of what tab it last had open — and if a save genuinely does succeed, confirm the resulting slot file's mtime/content actually changed (the underlying "does save write" question is what this whole defect was obscuring).

**Be explicit in your findings write-up about what's now fixed-and-confirmed (arrival, tab navigation) versus what remains blocked by the separate upstream party-health issue (real combat, a truly informative save/load lifecycle result).** Do not claim more than your fix actually proves.

## File ownership — stay in scope

You may touch ONLY: `tools/gate_f/segments/X04.json` and `tools/gate_f/segments/X05.json`. Do not touch `S03.json`, `S10.json`, or `operator_harness.gd` — three other concurrent lanes are working on those.

## Environment setup (fresh container, budget this up front)

Godot is not preinstalled:
```
curl -fL -o g.zip https://github.com/godotengine/godot/releases/download/4.7-stable/Godot_v4.7-stable_linux.x86_64.zip && unzip -o g.zip && chmod +x Godot_v4.7-stable_linux.x86_64 && mkdir -p ~/.cache/tetherbound-art && mv Godot_v4.7-stable_linux.x86_64 ~/.cache/tetherbound-art/godot
```
Then `~/.cache/tetherbound-art/godot --headless --path . --import` once (~5 min). Never combine `--headless` with `--rendering-driver` — hangs forever. This is all headless/logic-mode work.

## Branch and deliverable

New branch `ralph/T2-GATEF-RIGFIXES` off `origin/main`. Commit and push per fix (X04's fix and X05's fix can be separate commits). Write `ralph/reports/handover-T2-GATEF-RIGFIXES-2026-08-30.md` when done: what you changed, exact validation evidence for each fix, what remains gated on the upstream party-health issue, and exact commands to reproduce.
```

### Lane 4 — T2-RIG10

```
title: T2-RIG10 — save_out never verifies the slot actually changed
source_url: https://github.com/MJohnsonWellabe/Tetherbound
source_revision: main
outcome_branch: ralph/T2-RIG10
tags: ["gate-f", "T2-RIG10", "parallel-fix-lane"]
```

```
You are a new fix lane on the Tetherbound repo (Godot game, `github.com/MJohnsonWellabe/Tetherbound`). Read `CLAUDE.md` first, then `ralph/GATE_F_MASTER_PROTOCOL.md` §B (segment structure, save handoff design) for context, then `ralph/reports/GATE_F_RUN_3_RIG_FINDINGS.md`'s "RIG-10" section in full before starting.

## The problem

`tools/gate_f/operator_harness.gd`'s save-handoff mechanism works like this: each segment's step-script calls `seed_save` to copy the PREVIOUS segment's exit save into a live save slot (usually slot 4) before booting, then later calls `save_out` (via `_step_save_out`) to copy that same slot's file back out as THIS segment's own exit save, after the segment has (in theory) played through the game and used the real production Save tab to write fresh data into that slot.

The bug: `_step_save_out` only checks that the destination file **exists** —

```gdscript
if not FileAccess.file_exists(src):
    return "FAIL slot %d has no file at %s -- did the Save tab actually write?" % [slot, src]
```

— it never checks that the slot's content actually **changed** as a result of this segment's own play. So if a segment's step-script fails to actually reach and use the Save tab (a wrong-tab navigation bug, a stuck panel, a missing button press — any of several real defects already found elsewhere in this run's history), `save_out` silently re-exports whatever `seed_save` originally put in that slot, under THIS segment's name, reporting PASS. This isn't hypothetical: it already happened for real in this run's evidence — `S03-exit.json`, `S04-exit.json`, and `S05-exit.json` are **byte-identical** (md5 `62344f09b811`) despite S04 and S05 each running for hundreds of play-seconds and reporting dozens of PASS/FAIL verdicts of their own. The question `save_out`'s own error message asks — "did the Save tab actually write?" — is exactly the question its current check cannot answer.

The whole point of this run's save-handoff design (§B of the master protocol) is that a blocker in one segment restarts from the LAST GATE, not the whole chapter — and that design silently was not in force for at least one stretch of this run, undetected until someone diffed the save files by hand.

## Your job

Fix `_step_save_out` (and/or wherever `seed_save`/the harness otherwise tracks slot state — look at both functions together) to detect and correctly FAIL when the destination slot's content is unchanged from what `seed_save` originally put there. The natural approach: record a hash (or mtime, though a hash is more robust against a filesystem with coarse mtime resolution) of the slot file's content at the moment `seed_save` writes it, then at `save_out` time, compare the slot file's current hash against that recorded value — if unchanged, `FAIL` with a clear message ("slot N's content is byte-identical to what seed_save wrote at the start of this segment — the Save tab was never actually used") instead of silently succeeding. Store whatever state you need for this comparison wherever the harness already keeps other per-segment state (look at how it tracks other cross-step data).

**Secondary, lower-priority item if you have time left after RIG-10 is solid:** a related, separately-numbered defect (RIG-4, also in `GATE_F_RUN_3_RIG_FINDINGS.md` — read it too) is that when `seed_save`'s OWN source file doesn't exist (e.g. the previous segment never produced an exit save at all, such as when it hit a cost-gate BLOCKER), the segment does not stop — it FAILs that one assert and keeps running against stale/empty state for its entire remaining step count and wait-budget, producing non-evidence rather than stopping cleanly. If you have time, consider whether `seed_save` should derail/refuse the whole segment when its source genuinely does not exist, rather than continuing. This is explicitly optional — RIG-10 is the assigned priority.

## Validating your work honestly

This is core harness code every other segment and lane depends on — be conservative and test broadly:

1. **Confirm a genuine, correct save/load cycle still PASSes** after your fix — run at least 2-3 existing segments end to end (whatever entry saves are currently available in `ralph/reports/gate-f-run-20260828T183531Z/` — even fainted-party ones are fine for this, since you're testing save MECHANICS, not the game) and confirm `save_out` still succeeds when the segment genuinely uses the Save tab correctly.
2. **Confirm your fix actually catches the failure mode it's meant to catch.** The cleanest way: deliberately construct or find a step-script (or a small standalone test segment) where the Save tab is never actually reached, and confirm your new check correctly FAILs it, with a clear message naming what happened — rather than the old silent-success behavior. You could use a copy of one of X05's own save-verification blocks (`tools/gate_f/segments/X05.json` — note a separate concurrent lane, `ralph/T2-GATEF-RIGFIXES`, is independently fixing a real instance of exactly this failure mode there; you don't need to touch that file, just note it's good real-world evidence of the shape you're testing against).

## File ownership — stay in scope

You may touch ONLY `tools/gate_f/operator_harness.gd`, scoped specifically to the `seed_save`/`save_out` step implementations (and whatever small amount of shared state-tracking code they need). **Do not touch anything else in that file** — three other concurrent lanes (`ralph/T2-BUILDPLACE` on `S03.json`, `ralph/T2-S10-COST` on `S10.json` and possibly the cost-gate logic in this same file, `ralph/T2-GATEF-RIGFIXES` on `X04.json`/`X05.json`) are all relying on the rest of this file's current behavior not changing underneath them. If your fix needs to touch anything beyond the save-related step functions, stop and reconsider scope before proceeding, and say so explicitly in your handover if you believe a wider change is genuinely necessary.

## Environment setup (fresh container, budget this up front)

Godot is not preinstalled:
```
curl -fL -o g.zip https://github.com/godotengine/godot/releases/download/4.7-stable/Godot_v4.7-stable_linux.x86_64.zip && unzip -o g.zip && chmod +x Godot_v4.7-stable_linux.x86_64 && mkdir -p ~/.cache/tetherbound-art && mv Godot_v4.7-stable_linux.x86_64 ~/.cache/tetherbound-art/godot
```
Then `~/.cache/tetherbound-art/godot --headless --path . --import` once (~5 min). Never combine `--headless` with `--rendering-driver` — hangs forever. This is all headless/logic-mode work.

## Branch and deliverable

New branch `ralph/T2-RIG10` off `origin/main`. Commit and push per meaningful step. Write `ralph/reports/handover-T2-RIG10-2026-08-30.md` when done: what you changed, both validation results (positive case still passes, negative case now correctly FAILs, with concrete evidence for each), whether you also addressed RIG-4, and exact commands to reproduce. Flag clearly if you believe any other lane's in-flight work could be affected by your change, since this file is shared infrastructure.
```

---

## What happens after these four land

1. Verify lane 1's `S03-exit.json` directly (party HP, not `"complete": true"`).
2. If healthy: run S04 through S09 in order, each freshly seeded from the
   previous segment's new exit, superseding (never deleting) the existing
   S03-S09 directories per `RESTARTS.md`'s convention.
3. Swap in lane 2's split S10 sub-segments for the old monolithic S10 once
   a healthy `S09-exit.json` exists.
4. Re-run X04 and X05 against lane 3's fixed step-scripts, once healthy
   saves exist.
5. Run X03 and X06 once the chain is healthy (X06 last, stop early if it
   reproduces a new problem rather than confirming an old one — see
   `ralph/reports/handover-T2-GATEF-2026-08-30.md` §5 for the full reasoning).
6. Merge lane 4's `operator_harness.gd` fix in regardless of the above —
   it's infrastructure hardening, not gated on anything.
7. Rewrite `ralph/reports/GATE_F_RUN_3_FINDINGS.md` and
   `GATE_F_RUN_3_RIG_FINDINGS.md` one more time, from the new, real, healthy
   evidence — everything they currently say about bands 2-5 needs to be
   replaced with actual content findings once the player can actually reach
   those bands, not just the stranding's own signature.
