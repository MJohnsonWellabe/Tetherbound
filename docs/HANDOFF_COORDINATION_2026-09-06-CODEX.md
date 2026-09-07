# HANDOFF — coordination follow-through, 2026-09-06/07 (for a Codex session)

**Read this before anything else in this file tree except `CLAUDE.md` and `docs/00_START_HERE.md`.**
Written by a Claude coordination session, updated after the consolidation work it describes
actually finished and merged. Precision over prose: every claim below is either verified
against the repo/GitHub directly, or explicitly marked as unverified.

**This is a rewrite of an earlier version of this same file.** The first version was written
mid-task, before the work below actually landed, and hedged accordingly ("check if a live
session already did this," "state unknown"). Those hedges are resolved now — this version
states what is actually true today.

## Scope — read this first

This handoff covers **consolidation, multiplayer wrap-up, Meadows/Cloudreach visual
finishing, and menu/HUD UI work**. It does **not** cover Stormwood or Water — biome
construction is already underway in a separate, active line of work:

- PR #68 (merged) landed owner reference boards (Stormheart Tree, Water roster, Veilfall,
  Sky Aviary) and a frozen Stormwood 0/100 baseline scorecard.
- PR #70, `ralph/stormwood-phase1-handoff-0906` (open, not draft) — Stormwood phase 1:
  terrain foundation, realm/save migration, level cap to 100, Wings/Skyborne stamina,
  three relic slots. Its own PR body says it is "a foundation landing, not a completed
  chapter" and flags an unresolved two-peer loading-heartbeat failure and a first blind
  visual judge rejecting landmark readability/framing/forest presentation as remaining work.
- PR #69, `ralph/water-foundation-0906` (open, **draft**, owner instruction is to keep it on
  the branch and merge later) — Water Archipelago foundation: twelve islands, roster/NPC
  data, swimming-state and current-field models. Explicitly not a playable chapter yet.
- `claude/meshy-characters-creatures-huok0q` (unmerged, no PR seen) — Meshy prompt/reference-
  crop prep for the Water/Stormwood/Cloudreach creature rosters and three alternate main-
  character choices. States "no generations submitted yet" (its Meshy API key was rejected).

**Do not touch any of the four items above.** If anything below appears to overlap them,
defer to whoever owns that line — this document's author has no visibility into them beyond
what's stated here.

**One real coupling point worth raising with whoever owns Stormwood, not just filing away:**
PR #70's own body says Stormwood's multiplayer acceptance is unproven, and this project's
Stormwood execution policy says Stormwood must ship on whatever multiplayer architecture
exists when it starts. Task 4 below carries two open multiplayer protocol questions (does a
wild scale with party size; can a client originate an encounter) that Stormwood's own MP work
will likely need answered too. Surfacing this to the Stormwood owner sooner rather than later
is probably worth more than doing it silently in Task 4's own timeline.

## Current state of `main`

Tip as of this rewrite: `c820dee4` ("Merge pull request #72 ..."). Verify with
`git log -1 --oneline origin/main` before trusting anything below — this will drift as
biome work keeps landing on `main` concurrently.

Landed since the previous version of this doc, in order: PR #63 (the whole multiplayer
build plus the Meadows/Cloudreach owner-list pass, 145 commits), PR #67 (QUICK_TOUR.cmd),
PR #68 (biome-build reference boards), **PR #71** (this handoff doc itself, first version),
**PR #72** (see below).

### PR #72 — the second-biome art lanes AND the menu work, consolidated onto one branch

Per direct owner instruction, everything real and unmerged from this coordination pass was
put on **one branch** (`claude/land-second-biome-art-lanes-0906`) rather than landed as
separate PRs, then merged as PR #72 with **CI fully green** (confirmed: all 25 jobs
completed, including all 5 `verify-multiplayer-shard` shards). It carries two genuinely
different pieces of work:

**1. The 6 second-biome art lanes**, each merged individually then given follow-up rounds
addressing what the rendered frames actually showed: `art-cloudreach-atmosphere-0906`,
`art-cloudreach-dressing-0906`, `art-hall-round-0906`, `art-tether-machine-0906`,
`art-warrens-round-0906`, `second-biome-art-plan-470zru`. **Important honesty check**: the
merge is confirmed and CI (functional smokes) is green, but nobody has re-run a fresh blind
visual-judge pass against the final merged state. The specific open visual findings the
first version of this doc listed per-lane (Cloudreach C3 verticality, C6/C7/C8 dressing
geometry, Hall's 5 unrendered tuning values, tether machine silhouette lighting, Warrens W3
interior geometry) may have been improved by the follow-up commits that landed with this
PR (commit messages like "Cloudreach dressing round 2: fix what the rendered frames
actually showed", tether machine "round 1/2/3" commits, "Warrens round 2") — but that is
not confirmed by a fresh blind judge. **Treat those specific items as still open until you
personally re-render and re-judge them** (`.claude/skills/visual-judge/SKILL.md`), not as
closed just because the branch merged.

**2. Menu: character-select step + curated teleport-spot data.** Added to the same branch
after the PR was already open (owner: "put together on one branch"). Two clearly different
completion states:
- **Character-select: DONE and test-verified.** `scripts/ui/title_screen.gd` shows a
  "Choose Your Character" step before every new-game path (Start New Game; Join, when this
  machine has no local character yet), reading from `data/config/characters.json` (one
  entry today — "The Trainer" — a second is a JSON row, not a UI rewrite). Two existing
  smokes that press through "Start New Game" broke when this landed
  (`tests/smoke_title_new_game.gd`, and `tests/helpers/gate_a_opening_drive.gd` which
  `smoke_gate_a_opening_segment.gd`/`smoke_gate_b_continuous.gd` both use) — both were fixed
  to answer the new screen the same way they already answered the existing "Start Fresh
  Game" confirmation, and CI confirmed green afterward.
- **Teleport-spot curation: DATA DONE, WIRING NOT DONE.** `data/config/debug_teleport_spots.json`
  hand-curates exactly two spots per Meadows band / Cloudreach region (positions verified
  against `data/config/map_landmarks.json`/`cloudreach_world.json`, not invented). **But
  `scripts/ui/tab_settings.gd`'s `_build_debug_teleport_section()` still reads from the old
  `GameState.debug_teleport_destinations()` 34-destination generator — nothing was changed
  to make it read the new file.** This is real, scoped, unstarted work — see Task 7.

### CI is fast now — do not let it regress

`verify-multiplayer-shard` used to run ~20-29 two-process net smokes sequentially in one
job, 46-65 minutes, and had never once completed without being auto-cancelled
(`.github/workflows/ci.yml`'s `ci-${{github.ref}}` concurrency group cancels in-progress
runs on every push to the same ref). Fixed by splitting discovery from a 5-way sharded
execution matrix, after auditing all ~29 smokes for genuine duplicates (found none — every
one ties to a distinct lane/directive item, nothing was cut for speed) and fixing two real
pre-existing bugs the sharding surfaced (`smoke_net_riding.gd`'s under-budgeted `race()`
call; `smoke_net_deploy_two_creatures.gd`'s name collision with the shared harness base
class, which was a silent parse failure contributing zero coverage). Result: 46-65 min →
~17-20 minutes, confirmed by direct measurement on multiple large PRs including this one.

**Known trap:** this repo's CI concurrency group can auto-cancel a still-running, actually-
progressing run if another run starts on the same ref. Watch for it after any push; cancel
the redundant one, never the progressing one.

## Branches present right now (verify with `git branch -r`, this will drift)

The owner deleted 10 fully-merged branches directly after PR #72 landed. As of this
rewrite, remaining branches are:

| Branch | Status |
|---|---|
| `claude/mp-realm-reopen` | 1 commit ahead, **never merged, and confirmed to have zero unique value** — its docs/perf corrections and one log-format string are already on `main` in a more complete form via a separate path (`main`'s own `docs/decisions/D97-*.md` documents three successive rounds of self-correction on these exact numbers, ending later and differently than this branch's own claim). **Safe to delete, nothing to fold in** — this corrects the first version of this doc, which wrongly called it "real value." |
| `ralph/water-foundation-0906`, `ralph/stormwood-phase1-handoff-0906`, `claude/meshy-characters-creatures-huok0q` | Out of scope, active biome work — see Scope above. Do not touch. |

Everything else this pass touched (all 6 art-lane branches, `claude/land-second-biome-art-lanes-0906` itself, `claude/handoff-coordination-2026-09-06`, `claude/quick-tour-owner-2026-09-06`, `claude/codex-biome-build-prompts-4cs0n0`, `claude/push-permission-test-scratch`) is deleted.

---

## Task 1 — Land PR #63 — DONE

## Task 2 — Fold 6 art lanes onto main — DONE (merged, CI green; visual re-judge still owed)

Merged as PR #72. See "PR #72" above for exactly what is and isn't verified. **Next action
here, if anyone picks it up:** re-render and re-judge the specific per-lane open items listed
there — do not assume the follow-up commits closed them without checking.

## Task 3 — Delete stale branches — DONE except one

Owner deleted 10 branches directly. `claude/mp-realm-reopen` remains and is safe to delete
(see Branches table above) — it was never folded in because it turned out to have nothing
to fold in, not because the fold-in is still pending.

## Task 4 — Multiplayer wrap-up — NOT STARTED, fully open

**Correction to the first version of this doc:** a local subagent was assigned this and
left zero real work behind (checked directly — its worktree had only stray `.uid` sidecar
files, no actual commits or content). Start fresh from this brief. Also: **the first
version's point 1 (fold in `mp-realm-reopen`) is no longer needed** — see Branches table,
it has nothing unique left to fold in. Everything else from the original brief still stands:

1. **Get real evidence for the acceptance table** now that CI can finish
   (`docs/acceptance/MULTIPLAYER_ACCEPTANCE.md`, 24 §17 rows + §21/§23 — owner column stays
   unsigned, that's expected). No net smoke puts two pilots in a shared *Cloudreach* fight —
   write `smoke_net_shared_cloudreach_fight.gd` modeled on `smoke_net_shared_wild_fight.gd`,
   **must include the `place_stand_in` compensating arm** or it inherits a known spawn-
   table-lottery defect (`join_encounter()` binds a joiner to `nearest_live_wild()`, and
   since wild bodies aren't replicated, an unarmed smoke gets an arbitrary distance between
   the two pilots' actual targets). `smoke_aggression`'s flake rate has never been measured
   — run it ~7 times, read `<out>/net-*/SUMMARY.md` per run, never trust stdout
   (`tools/net/run_net_smoke.sh` ends in a `tail -f` that hangs forever if piped — use
   `--out=` and read the file). `smoke_net_host_join_leave` and `smoke_net_pickup_race` were
   never re-measured under 7.A's jitter profile — run
   `TB_NET_CONDITIONS="delay=150,jitter=30,loss=1" tools/net/run_net_smoke.sh <name>` on
   both. `smoke_net_shared_boss` hasn't been reverified since the MP-F1-F2 merge landed.
2. **Re-run `smoke_net_shared_wild_fight` ~10x** to determine whether the shipped fix
   (verdict-polling) also resolved a since-abandoned alternate diagnosis (non-deterministic
   pre-swing creature placement), or whether that's a second live defect nobody chased down.
   Cite your own measurement either way.
3. **Flag, do not decide, two owner-level design questions** (see Scope above for why
   Stormwood's own MP work may need these answered too — raise this with whoever owns that
   line, don't just log it here and move on): (a) whether a wild creature should scale in
   difficulty when a friend joins (currently doesn't — deliberately, since a scaled wild is
   also a harder catch and catching is core progression); (b) whether a client should be
   able to originate a wild encounter at all (currently only the host can).
4. **Read the 7 named process traps in `docs/owner/STAGE_B_HANDOFF_2026-09-06.md`** before
   touching this area.
5. **Lower priority:** retire the legacy v22 save-slot file (read
   `ralph/reports/MP-1C-CHARSAVE-0906/REPORT.md` §4 first); fix the `reconnect_window_s`
   doc-vs-code mismatch (doc says 120s, code removes the registry row immediately).

## Task 5 — Meadows Burrow Warrens visual finish — unblocked, not started

Task 2 is done, so this can start. `docs/owner/MEADOWS_VISUAL_SWEEP_GOAL_2026-09-06.md` §5
wants a full "hero location pass." Check Task 2's re-judge first — W3 (interior geometry)
was open pending an owner tunnel-kit-budget decision before PR #72; get that decision before
attempting W3's geometry.

## Task 6 — Cloudreach grass — unblocked, has a detailed live investigation

Owner invariant (verbatim): *"There should be nowhere you can stand that doesn't have grass
or isn't a bare dirt patch or mud pit... it cannot just be plain green painted on a parking
lot."* Status not re-checked since PR #72 merged — verify against the current build before
trusting the repro below.

Repro (as of the investigation before PR #72): stand `05-upper-cloudreach-cliffhold` renders
as flat painted green with zero tufts, despite 500,397 tufts existing realm-wide and a probe
reporting 60/60 nearby points "plantable." **9 things already ruled out with evidence — don't
re-investigate:** density, patch-bounded cover layers, ground material UV tiling, terrain
flatness, glTF metallic defect, wrong turf surface ID, `_is_turf_top` collider-name
rejection, ledge-cap material-override collection miss, tufts planted inside rock.

**Next steps, in order:** (1) re-run `tools/_probe_cloudreach_cover_near.gd` properly — the
one "0 instances within 20m" reading may have been taken before a fill pass finished; (2) if
tufts ARE there but invisible, check `shaders/cloudreach_ground_cover.gdshader`'s
`camera_clearance`/visibility-range fade tiers/foreshortening; (3) if NOT there, use
`tools/_probe_cloudreach_turf_rejects.gd` on `cloudreach_look.gd::_fill_tuft_at`'s
`_excluded`/`_inside_settlement_clearance`/`_near_route`; (4) **untried fallback if 1-3
don't resolve it fast:** give the surface a dirt/mud material instead of forcing grass —
satisfies the invariant without solving placement.

Also fix in passing (found, not fixed): `cloudreach_look.gd::_near_route`'s 260m early-out
uses a bare `pass` instead of `continue`, so it never actually skips anything.

## Task 7 — Menu overhaul — character-select DONE, teleport wiring is the only thing left

Small, exact, well-scoped remaining piece:

`scripts/ui/tab_settings.gd`'s `_build_debug_teleport_section()` (around line 302) currently
builds its rows from `game.call("debug_teleport_destinations")`. Change its data source to
`data/config/debug_teleport_spots.json` instead: flatten that file's `biomes[].bands[].spots[]`
structure into the same flat `{display_name, position, realm, entry_id}` shape
`_build_teleport_row()`/`_on_teleport()` already expect. `entry_id` for a cross-realm spot
should be resolved at build time via the same lookup `GameState._debug_teleport_entry_id_for()`
already provides (see `autoload/game_state.gd` around line 2118) — the JSON file's own header
comment records this as the intended design. **Nothing in the actual teleport-move path
(`debug_teleport_to()`) needs to change** — only what feeds the row list. Test with
`tests/smoke_realm_teleport.gd` (exercises `debug_teleport_to` directly, unaffected) plus a
manual pass through the Settings tab to confirm exactly 2 rows per band/region show up.

## Task 8 — HUD overhaul (map + compass bar) — NOT STARTED, clean unclaimed work

**Correction to the first version of this doc:** confirmed directly — the subagent
previously assigned this left no trace of any work at all (no worktree, no branch). Full
brief, unchanged from before:

1. **Replace the minimap with a directional compass bar.** `scripts/ui/minimap.gd` (796
   lines) has a long-standing, never-addressed blind-judge finding ("the minimap carrying
   almost nothing" — `docs/GATE2_GATE3_CLOSURE_PLAN.md` row CL-B4; `GF-18-MAP-03` in
   `docs/acceptance/GATE_F_MASTER_PROTOCOL.md`). Remove it; replace with a horizontal
   0-360° heading strip, N/E/S/W (ideally + intercardinals), that scrolls with the player's
   facing and shows an off-screen-indicator-style marker for the current objective's
   bearing when one is set.
2. **Make the full map screen actually useful.** Build on `scripts/ui/tab_map.gd`'s current
   state (realm-selector row, cross-realm crossing markers from
   `data/config/realm_transitions.json` — landed with PR #63, don't redo it). Needs:
   auto-highlight the next objective with a "set as destination" action (wire it to the
   compass bar above); fix why the revealed map area reads as only ~5% of the screen
   (almost certainly a zoom/fit-to-viewport bug fitting to total world bounds instead of the
   discovered/relevant area). Prove any fix with a rendered before/after via
   `.claude/skills/visual-judge/SKILL.md` — never judge your own frames.

## Task 9 — Quick tour script — DONE (PR #67)

## Task 10 — CI speedup — DONE

---

## What to actually do next, in priority order

1. **Task 7's remaining piece first** — it's small, exact, and closes out a task that's
   otherwise 90% done. Do this before anything else.
2. **Surface Task 4's two owner-decision questions to whoever owns the Stormwood line**,
   even before doing the rest of Task 4's engineering work — see the coupling note in Scope.
   This is a "get an answer moving" action, not engineering work, and it's cheap to do early.
3. **Task 8 (HUD)** is clean, self-contained, unclaimed work — good next chunk if you want
   something with no dependencies on anything else in this doc.
4. **Task 4's engineering work** (acceptance-table evidence, the flake re-run) — real
   verification work, no code changes implied beyond a new smoke file.
5. **Tasks 5/6 (visual finishing)** need an owner call each before the hard part (Warrens
   tunnel-kit budget; Cloudreach grass may resolve on step 1 of its own investigation, or
   may not need an owner call at all — try the fallback in step 4 before escalating).
6. **Re-judge Task 2's specific open visual items** whenever there's room for it — it's not
   blocking anything else, but it's the one place this handoff is knowingly not confirming
   final state.

## General process notes

- This repo's own process discipline (`CLAUDE.md`, `docs/AGENT_WORKFLOW.md`) treats a CI run
  under 5 minutes as having verified nothing. Let runs finish. Don't merge on a partial run.
- Never judge your own rendered frames for a visual claim — use the blind visual-judge
  workflow.
- A lane's own self-report is a claim, not evidence — this document itself included. Verify
  branch/PR/CI state directly before acting on anything above.
- Branch from current `main`, never push to `main` directly, land through a PR.
