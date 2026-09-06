# HANDOFF — coordination follow-through, 2026-09-06 (for a Codex session)

**Read this before anything else in this file tree except `CLAUDE.md` and `docs/00_START_HERE.md`.**
Written by a Claude coordination session being wound down mid-task, for a single Codex
session to pick up cold and carry through. Precision over prose: every claim below is
either verified against the repo/GitHub directly, or explicitly marked as unverified.

## Scope — read this first

This handoff covers **consolidation, multiplayer wrap-up, Meadows/Cloudreach visual
finishing, and menu/HUD UI work**. It does **not** cover Stormwood or Water — biome
construction is already underway in a separate, active line of work:

- PR #68 (merged, `main` @ `e78f2ab4`) landed owner reference boards (Stormheart Tree,
  Water roster, Veilfall, Sky Aviary) and a frozen Stormwood 0/100 baseline scorecard.
- Branch `ralph/water-foundation-0906` (1 commit ahead of main, unmerged) is live Water
  biome work.

**Do not touch Stormwood/Water content.** If anything below appears to overlap it, defer
to whoever owns that line — this document's author has no visibility into it beyond the
two facts just stated.

## Current state of `main`

Tip as of writing: `e78f2ab4` ("Merge pull request #68 ..."). Verify with
`git log -1 --oneline origin/main` before trusting anything below — this may already be
stale by the time you read it (biome work is landing on `main` concurrently).

Landed today, in order:
1. **PR #63** — the whole multiplayer build (host/join UI, replicated movement, shared
   encounters, catch-ownership races, riding/Fly, cross-realm occupancy, portable
   characters) *plus* the previously-unmerged Meadows/Cloudreach art+gameplay owner-list
   pass (80 commits from `docs/owner/OWNER_PLAYTEST_2026-09-05.md`). 145 commits,
   46,824 additions, 353 files.
2. **PR #67** — `tools/owner/QUICK_TOUR.cmd` + `quick_tour.ps1`, a lightweight ~20-min-
   per-biome capture tool, separate from the full `KICKOFF.cmd` evidence pipeline. Merged
   on the owner's explicit instruction *without* the usual ROG Ally verification step —
   the authoring agent had no Godot/GPU/PowerShell and could only verify by reading
   source. **Owner should still run it once on the Ally** to confirm it actually works;
   not currently blocking anything.
3. **PR #68** — biome-build groundwork, see Scope above.

### CI is now fast — do not let it regress

`verify-multiplayer-shard` used to run ~20-29 two-process net smokes **sequentially in
one job**, taking 46–65 minutes, and had **never once completed without being
auto-cancelled** before today (`.github/workflows/ci.yml`'s `ci-${{github.ref}}`
concurrency group cancels in-progress runs on every push to a non-`main` ref). Fixed
today by:
- Splitting discovery (`discover-net-smokes`, unchanged floor/roster check) from
  execution (`verify-multiplayer-shard` is now a 5-way matrix, round-robin `index % 5`
  over the discovered file list).
- Auditing all ~29 net smokes for genuine duplicates first — found none; every one ties
  to a distinct lane/directive item. **Nothing was cut for speed.**
- Fixing two real, pre-existing bugs the sharding surfaced (both were silently
  contributing zero coverage before): `smoke_net_riding.gd`'s `round_five` `race()` call
  had a default ~55s timeout against a documented-guaranteed ~14s minimum cost (widened
  to `budget_frames: 6000`, not weakened); `smoke_net_deploy_two_creatures.gd` declared a
  local `_proxy_for(bodies, peer_id) -> Dictionary` helper that name-collided with the
  shared `net_harness.gd` base class's own `_proxy_for(target_port: int) -> int`, which
  is a GDScript parse error — the whole file failed to load and had been contributing
  **zero** real coverage for an unknown period. Renamed to `_creature_proxy_for`.
- Result: full CI run 46–65 min → **~17 minutes** (run `34054416497`,
  `19:17:17`–`19:34:27` UTC), confirmed by direct measurement, not estimate.

**Known trap, cost real time twice today:** this repo's CI concurrency group means a
`workflow_dispatch` run and a `pull_request` run on the same commit can both fire and one
will auto-cancel the other. If you dispatch CI manually to dodge the cancel-in-progress
problem on a slow job, **do not also let a normal push-triggered run start on the same
commit** — cancel the redundant one immediately (`gh api` or the GitHub MCP
`actions_run_trigger` `cancel_workflow_run` method) or you lose the run that was actually
making progress. This happened twice landing PR #63 today.

## Branches present right now (verify with `git branch -r`, this will drift)

| Branch | Ahead of main | Status |
|---|---|---|
| `claude/art-cloudreach-atmosphere-0906` | 6 | Unmerged art lane — see Task 2 |
| `claude/art-cloudreach-dressing-0906` | 7 | Unmerged art lane — see Task 2 |
| `claude/art-hall-round-0906` | 8 | Unmerged art lane — see Task 2 |
| `claude/art-tether-machine-0906` | 12 | Unmerged art lane — see Task 2 |
| `claude/art-warrens-round-0906` | 14 | Unmerged art lane — see Task 2 |
| `claude/second-biome-art-plan-470zru` | 7 | Coordination/grass-investigation branch — see Task 2 and Task 6 |
| `claude/land-second-biome-art-lanes-0906` | 48 | **Active integration branch, see Task 2 — check this first** |
| `claude/mp-realm-reopen` | 1 | Never merged, real value — see Task 4 |
| `claude/push-permission-test-scratch` | 0 | My own throwaway test branch. Safe to delete, no unique content. Couldn't delete it myself — branch *deletion* (not push) failed with an HTTP 403/git-negotiation error in my sandbox; push itself works fine. May or may not apply to your environment. |
| `claude/quick-tour-owner-2026-09-06` | 0 | Merged via PR #67, safe to delete |
| `claude/codex-biome-build-prompts-4cs0n0` | 0 | Merged via PR #68, safe to delete |
| `ralph/water-foundation-0906` | 1 | **Out of scope — biome work, do not touch** |

Everything else (17 multiplayer/misc lane branches, all confirmed merged into `main` via
`git merge-base --is-ancestor`) was already deleted by the owner directly.

---

## Task 1 — Land PR #63 — DONE

No action needed. Verified via `git merge-base --is-ancestor` against `main`, not just
GitHub's own "merged" flag (that flag can also be trusted here, but the independent check
was done anyway per this project's own evidence discipline).

## Task 2 — Fold 6 art lanes onto main — IN PROGRESS, has a live session, check it first

**Before doing anything else here: check whether `claude/land-second-biome-art-lanes-0906`
already has an open PR, and read its current diff/CI state.** A Claude Code Remote
session (id `session_01Qr4YewixyAXHjjzS9bgBfK`, if it's still reachable in whatever
environment you're in — it may not be, it belongs to the Claude session writing this,
not to Codex) was actively merging all 6 branches onto this working branch and had, as of
last check, merged all 6 and was re-rendering the Hall lane's fixes for a final blind-judge
round. It is **not confirmed finished** — do not assume it landed anything. Check the
branch's actual commit log and diff against `main` to see how far it got, and pick up
from there rather than re-doing the merge from scratch if it's already substantially done.

**If it needs to be finished or redone from scratch, here is the full brief** (verified
today by reading each lane's own `REPORT.md`, not the thinner cross-lane coordination
doc, which omits the Hall lane entirely):

**Known merge hazard:** `docs/DEVELOPMENT_ROADMAP.md` was revised on `main` on
2026-09-06 (old 10-stage plan → new 8-stage plan, marked with a "**Revision, 2026-09-06
(owner direction)**" banner). All 6 art branches predate that revision and carry the
stale 10-stage copy. Whichever version wins the merge, main's newer revision must survive
— verify with `grep -i "revision, 2026-09-06" docs/DEVELOPMENT_ROADMAP.md` after merging.
(This was already hit once landing PR #63 and resolved correctly there.)

1. **`claude/art-cloudreach-atmosphere-0906`** — C5 (floating islands) closed, praised by
   blind judge. C4 (thin horizon) half-closed: cloud below eye level improved, but billow
   edges read as "opaque white cardboard" — needs alpha falloff (soft-particle depth fade
   or fresnel), ~1hr shader job. **C3 (verticality) NOT closed** — judged stands sit on
   route shoulders between regions, not on region crowns, so nothing reads as vertical;
   needs either terrain that actually drops near the stands or different judged stands on
   real edges. **Real bug fixed here, worth keeping regardless of the rest**:
   `cloudreach_look.gd::_process` was re-applying a fog delta by multiplying the
   environment's *current* value every frame instead of a base value, compounding fog to
   near-zero over a frozen capture clock — Cloudreach has had effectively no distance fog
   in any captured frame to date until this fix.
2. **`claude/art-cloudreach-dressing-0906`** — C6 (arena/summit), C7 (aviary), C8
   (cottages) **all three still fail blind judging** per the lane's own close-out commit.
   Judge wants geometry (raised kerb ring + step-down for the arena fight floor, dressing
   visible from *inside* the aviary dome not just outside, bigger/higher-contrast cottage
   bracing), not more texture tuning. Two already-made fixes (aviary membrane opacity,
   removal of two market-stall awnings leaking Team Tether's reserved oxblood color onto
   ordinary furniture) were made but never re-rendered/judged — do that first, it may
   already help.
3. **`claude/art-hall-round-0906`** — Mostly closed against two blind-judge rounds, but
   **five tuning values shipped completely unrendered/unverified**: `glow_energy`
   0.9→0.45, `siphon_core_energy_max` 0.7→0.4 (practicals 0.85/0.8→0.6/0.55), the Elite
   figure's rim-light height y 1.78→1.25, arena ambient lights y 3.8→2.6 (energy
   4.9→4.4), an east-wall torch-pair reposition. **Re-render stands T-01/T-02/T-03 and
   get a fresh blind-judge verdict before trusting any of these five.** Leaves two items
   for whoever owns `scripts/world/stronghold_climax.gd`: `TetherReadout/Panel` reads as
   a flat unlit "second sky" banner; `RestraintRing0`'s emission is too bright.
4. **`claude/art-tether-machine-0906`** — Machine's material/hue now matches the wall
   (style-mismatch closed), but silhouette readability still fails blind judging.
   **Proven with three-camera evidence that this is a lighting/staging problem in the
   Hall's own files** (two of three camera stands aim at an unlit wall; the one lit stand
   reads fine), not a defect in the machine mesh. Fix chamber lighting at those two
   stands first (cheap, free of new art risk) and re-judge before spending more budget
   here. **The owner already rejected a procedural cube-based rebuild of this asset on
   sight** ("I prefer the original 3d asset version... unless there's a lot of
   improvement left to make") — do not attempt a full geometry rebuild without genuinely
   new owner-supplied reference art. If you do touch geometry: author at 15.0m height
   (`_fit_to_height` divides by measured mesh bounds), `machine.facing_deg = -101.2°` is
   an owner playtest fix, and **never put a Light3D inside the GLB** (it's a
   VisualInstance3D subtype and silently corrupts the bounds `_fit_to_height` uses).
5. **`claude/art-warrens-round-0906`** — W1 (mushrooms) and W5 (burrow arch) both closed
   and praised ("the best frame in the survey" per the judge). **W3 (interior geometry —
   "hard 90-degree extruded prisms, nothing says dug") NOT closed**; needs an organic
   tunnel-kit decision, which is an owner asset-budget call, not scene work — do not
   attempt to force this without that decision (see Task 5). **This lane introduced its
   own regression that must be fixed on the way in**: the `07-den-dressing` stand's frame
   median dropped from 46.6 to 32.0 when the den's walls switched from pale stone to an
   earth material, because the room's lights were never retuned for the new (much
   darker) albedo. Also: the lane's last 4 commits never got a full `smoke_warrens` CI
   run (only fixture-level) — run it for real.
6. **`claude/second-biome-art-plan-470zru`** — Coordination/handoff branch, also carries
   the Cloudreach grass investigation (see Task 6 — **do not try to finish that here**,
   it's tracked separately with its own next-steps). Land the real working content
   (realm-wide turf-cover fill, ground-truth fixes) without trying to close the open
   grass question.

**When done:** re-render/re-judge anything marked "made but never verified" above using
`.claude/skills/visual-judge/SKILL.md` (never judge your own frames), run `smoke_warrens`
(full) and `smoke_stronghold` for real, update `docs/CURRENT_STATE.md` with specific,
numeric status per area (not "improved"), land through a PR with a full CI run (~15-20
min now, let it finish — a run under 5 minutes verifies nothing per this repo's own
process docs).

## Task 3 — Delete stale branches — blocked on Task 2

Once Task 2's PR merges, `claude/art-*` (5 branches), `claude/second-biome-art-plan-
470zru`, and `claude/land-second-biome-art-lanes-0906` become safe to delete (verify each
with `git merge-base --is-ancestor` first, don't assume). `claude/push-permission-test-
scratch`, `claude/quick-tour-owner-2026-09-06`, `claude/codex-biome-build-prompts-4cs0n0`
are already safe now (0 ahead of main). Leave `claude/mp-realm-reopen` until Task 4 folds
its content in. Leave `ralph/water-foundation-0906` alone entirely — not yours.

## Task 4 — Multiplayer wrap-up — attempted, unknown completion state

**A local, non-persistent subagent (not an independent session) was working on this and
was interrupted before it reported completion. Do not assume any of it landed — check
for a branch/PR first (search for recent branches/PRs touching `scripts/net/`,
`tests/smoke_net_*`, or `docs/acceptance/MULTIPLAYER_ACCEPTANCE.md`), and if nothing
landed, start fresh from this brief.**

Scope: backend/engineering only, not menu UI (that's Task 7 — keep them in separate
files to avoid conflicts if both are worked at once: this task should not touch
`scripts/ui/title_screen.gd`).

1. **Fold in `claude/mp-realm-reopen`'s unique unmerged content** (tip commit
   `e9827859`, never merged anywhere). It carries: (a) better/later realm-shell perf
   numbers that should replace stale ones in `docs/decisions/D97-*.md` and
   `docs/acceptance/MULTIPLAYER_ACCEPTANCE.md` (Cloudreach worst window should read
   ~2.6s not 4.4s, Meadows ~7.5s not 9.9s, both against a 15s budget); (b) an
   independent, **unreconciled** root-cause diagnosis for `smoke_net_shared_wild_fight`'s
   flake (non-deterministic pre-swing creature placement) that differs from the fix that
   actually shipped on `main` (verdict-polling). Re-run that smoke ~10x on current `main`
   to determine whether the shipped fix also resolved the placement-nondeterminism
   theory, or whether it's a second live defect — correct the docs to reflect whichever
   is true, citing your own measurement, not either branch's claim.
2. **Get real evidence for the acceptance table** now that CI can finish
   (`docs/acceptance/MULTIPLAYER_ACCEPTANCE.md`, 24 §17 rows + §21/§23 — owner column
   will stay unsigned, that's expected and correct, nothing CI can sign). Specifically:
   no net smoke puts two pilots in a shared *Cloudreach* fight — write
   `smoke_net_shared_cloudreach_fight.gd` modeled on `smoke_net_shared_wild_fight.gd`,
   **must include the `place_stand_in` compensating arm** or it inherits a known
   spawn-table-lottery defect (`join_encounter()` binds a joiner to
   `nearest_live_wild()`, and since wild bodies aren't replicated, an unarmed smoke gets
   an arbitrary distance between the two pilots' actual targets). `smoke_aggression`'s
   flake rate has never been measured — run it ~7 times, read `<out>/net-*/SUMMARY.md`
   per run, never trust stdout (`tools/net/run_net_smoke.sh` ends in a `tail -f` that
   hangs forever if you pipe its stdout — use `--out=` and read the file). `smoke_net_
   host_join_leave` and `smoke_net_pickup_race` were never re-measured under 7.A's jitter
   profile (only `smoke_net_shared_wild_fight` was) — run
   `TB_NET_CONDITIONS="delay=150,jitter=30,loss=1" tools/net/run_net_smoke.sh <name>` on
   both. `smoke_net_shared_boss` hasn't been reverified since the MP-F1-F2 merge landed.
3. **Flag, do not decide, two owner-level design questions** — write them into the
   acceptance doc's known-open section and `docs/CURRENT_STATE.md`: (a) whether a wild
   creature should scale in difficulty when a friend joins (currently doesn't —
   `encounter_director.gd` only scales trainer/boss fights, deliberately, because a
   scaled wild is also a harder catch and catching is core progression); (b) whether a
   client should be able to originate a wild encounter at all (currently only the host
   can start one — `docs/specs/MP_ENCOUNTER_PROTOCOL.md` should say which is intended,
   and acceptance row 5 should reflect it).
4. **Read the 7 named process traps in `docs/owner/STAGE_B_HANDOFF_2026-09-06.md`**
   before touching this area — they cost real time today (`OfflineMultiplayerPeer`
   false-positive on `is_server()`, a GDScript parse failure counting as exactly one
   silent failure regardless of test count, fixed-settle reads of a host verdict being a
   race not a wait, etc).
5. **Lower priority, only if time allows:** retire the legacy v22 save-slot file (touches
   the Gate F harness, 19 test files, `tools/net/peer_runner.gd` — read
   `ralph/reports/MP-1C-CHARSAVE-0906/REPORT.md` §4 first, has its own blast radius); fix
   the `reconnect_window_s` doc-vs-code mismatch (doc says 120s, code removes the
   registry row immediately on disconnect).

## Task 5 — Meadows Burrow Warrens visual finish — blocked on Task 2

Two things converge here: (1) `docs/owner/MEADOWS_VISUAL_SWEEP_GOAL_2026-09-06.md` §5
demands a full "hero location pass" (exterior composition, interior structure/lighting,
compared against Cloudreach's best authored locations) — not started anywhere yet; (2)
Task 2's Warrens lane (once landed) will have closed W1/W5 and left W3 (interior
geometry) open pending an owner tunnel-kit decision. **Land Task 2 first**, don't redo
W1/W5 work that already passed blind judging, then treat the visual-sweep directive as
the remaining scope on top of that baseline. Get an owner call on the tunnel-kit budget
question before attempting W3's geometry.

## Task 6 — Cloudreach grass — blocked on Task 2, has a detailed live investigation

Owner invariant (verbatim, `docs/HANDOFF_GRASS_AND_ART_LANES_2026-09-06.md` on
`claude/second-biome-art-plan-470zru`, not yet on main): *"There should be nowhere you
can stand that doesn't have grass or isn't a bare dirt patch or mud pit... it cannot just
be plain green painted on a parking lot."* Marked explicitly **NOT MET**.

Repro: stand `05-upper-cloudreach-cliffhold` renders as flat painted green with zero
tufts, despite 500,397 tufts existing realm-wide and a probe reporting 60/60 nearby
points "plantable."

**9 things already ruled out with evidence — don't re-investigate:** density (already
uniform ×1.0), patch-bounded cover layers (already replaced with a realm-wide fill),
ground material UV tiling, terrain flatness, glTF metallic defect, wrong turf surface ID,
`_is_turf_top` collider-name rejection, ledge-cap material-override collection miss,
tufts planted inside rock.

**Next steps, in order:**
1. Re-run `tools/_probe_cloudreach_cover_near.gd` properly — the one "0 instances within
   20m" reading was likely taken before the ~60s fill pass finished and may be invalid.
   Cheapest step, forks the investigation.
2. If tufts ARE there but invisible: check `shaders/cloudreach_ground_cover.gdshader`'s
   `camera_clearance` (shrinks blades to 1.5% within 1.2m of camera), MultiMeshInstance
   `visibility_range_end` fade tiers, or simple foreshortening at that camera pitch.
3. If tufts are NOT there: use `tools/_probe_cloudreach_turf_rejects.gd` to find which of
   `_excluded`/`_inside_settlement_clearance`/`_near_route` in
   `cloudreach_look.gd::_fill_tuft_at` is rejecting the point.
4. **Untried fallback, explicitly recommended if 1-3 don't resolve it fast:** give that
   surface a dirt/mud material instead of forcing grass — satisfies the invariant without
   solving placement, "no one has tried it."

Also fix in passing (found, not fixed): `cloudreach_look.gd::_near_route`'s 260m
early-out uses a bare `pass` instead of `continue`, so the distance-check "optimization"
never actually skips anything.

## Task 7 — Menu overhaul (character select + teleport list) — interrupted, state unknown

**This was being worked by a local subagent that was explicitly stopped mid-task. Do not
assume anything was saved.** Check for a worktree or branch first
(`.claude/worktrees/agent-*` if you have filesystem access to the machine that ran it —
you likely don't, since you're a fresh Codex session; more realistically, just check
`git branch -r` and any open PRs for anything touching `scripts/ui/title_screen.gd` or
`scripts/ui/tab_settings.gd` created around 2026-09-06 23:00-23:15 UTC). If nothing
landed, here's the full brief:

1. **Character select on every new-game path (SP and MP).** No dedicated character-
   select screen exists today — identity is just "whatever your local save file is"
   (`user://characters/<character_id>/character.json`, minted on "New Character").
   `scripts/ui/title_screen.gd` already has full MP host/join UI (`--mp-host`/`--mp-join`
   flags, LAN-beacon "Join a Game" list, routed through `Session.host()`/`Session.
   join()` — this landed with PR #63). Owner wants a character-choice step inserted into
   every new-game flow, even though only one option exists today — build the plumbing
   (a small JSON/resource list of character definitions) so a second option is trivial
   to add later. Don't invent lore/cosmetic content for additional characters.
2. **Curate a real teleport-spot list, two per band per biome.** A "Debug teleport"
   feature already exists in Settings (`scripts/ui/tab_settings.gd`,
   `data/config/menu.json`, gated behind a dev/test toggle — its own comment calls it
   "OF26... a development setting, not a game rule"). Already has 34 destinations across
   both biomes, including a working cross-realm coroutine path (`debug_teleport_to()`,
   proven by `tests/smoke_realm_teleport.gd`, landed with PR #63). Build on this, don't
   invent a new mechanism: curate the list to guarantee exactly two spots per band, per
   biome (check `docs/specs/MEADOWS_PROGRESSION_SPEC.md` for band boundaries). Always
   listed regardless of discovery/fog state. **Design question not yet decided:** keep
   it gated behind the existing dev-only toggle (the owner's own phrasing was "with
   teleporting on," which suggests keeping the toggle is fine) or promote to a normal
   "fast travel" feature — default to keeping it gated, note the choice in your PR so
   it's revisitable.

## Task 8 — HUD overhaul (map + compass bar) — interrupted, state unknown

**Same caveat as Task 7: was being worked by a local subagent, may not have landed
anything, check `git branch -r` / open PRs touching `scripts/ui/tab_map.gd` or
`scripts/ui/minimap.gd` before assuming you're starting from scratch.**

1. **Replace the minimap with a directional compass bar.** `scripts/ui/minimap.gd` (796
   lines) has a long-standing, never-addressed blind-judge finding: "the minimap
   carrying almost nothing" (`docs/GATE2_GATE3_CLOSURE_PLAN.md` row CL-B4, "proven
   failing"; also `GF-18-MAP-03` in `docs/acceptance/GATE_F_MASTER_PROTOCOL.md`). Nobody
   has ever touched this file — clean, unclaimed work. Remove it; replace with a
   horizontal 0-360° heading strip, N/E/S/W (ideally + intercardinals), Fortnite-style,
   that scrolls with the player's facing and shows an off-screen-indicator-style marker
   for the current objective's bearing when one is set.
2. **Make the full map screen actually useful.** Build on `scripts/ui/tab_map.gd`'s
   current state (grew 1198→1640 lines via PR #63: realm-selector row, `_view_realm`/
   `_display_realm` split, cross-realm crossing markers from
   `data/config/realm_transitions.json`) — don't redo that. Needs: auto-highlight the
   next objective on the map with a "set as destination" action (wire it to the compass
   bar above so the bar points at the active destination); and fix why the revealed map
   area reads as only ~5% of the screen — almost certainly a zoom/fit-to-viewport bug
   (fitting to total world bounds instead of the discovered/relevant area), not a
   content problem. Prove any fix with a rendered before/after comparison via
   `.claude/skills/visual-judge/SKILL.md` — never judge your own frames.

## Task 9 — Quick tour script — DONE

Merged as PR #67. Owner should run it once on the ROG Ally to confirm it works for real
(not currently blocking anything else).

## Task 10 — CI speedup — DONE

See "CI is now fast" above.

---

## General process notes for whoever picks this up

- This repo's own process discipline (`CLAUDE.md`, `docs/AGENT_WORKFLOW.md`) treats a CI
  run under 5 minutes as having verified nothing, and a full run as 15-45 minutes
  depending on what changed. Let runs finish. Don't merge on a partial run.
- Never judge your own rendered frames for a visual claim — use the blind visual-judge
  workflow (`.claude/skills/visual-judge/SKILL.md` if you have access to an equivalent).
- A lane's own self-report is a claim, not evidence — this document itself included.
  Verify branch/PR/CI state directly before acting on anything above.
- Branch from current `main`, never push to `main` directly, land through a PR.
