# Exit handoff — owner requested stop, 2026-09-08

**Do not resume automatically.** The owner's latest instruction was to write this
handoff, store it in the repository, push all work, and stop for now. Work is
incomplete, not blocked on an approval and not complete. Resume only when requested.
All three agents were interrupted; no Godot process remained at the final check.

## Start here when the owner resumes

Read `CLAUDE.md`, `docs/00_START_HERE.md`, this handoff, then
`docs/owner/OWNER_DIRECTIVE_2026-09-08_STAGE_C6_FULL_VISUAL_AUDIT.md`.
That newest directive pulls Stage C6 forward and supersedes the bounded cloud,
terrain and loading work previously underway. It requires a GENERAL visual audit,
not a repair checklist based on the owner's examples. Keep a separate earned-content
agent moving in parallel. The original genuine fresh opening→Tidewake objective
remains unfulfilled; debug survey travel cannot satisfy it.

## Git and CI at exit

- Branch: `codex/four-biome-wave6`; draft PR #90:
  https://github.com/MJohnsonWellabe/Tetherbound/pull/90.
- Last verified main: `65267c4bd935d80b2e073799caeffc81b913952c`, PR #89.
  Its OWN push CI34281611197 passed, all jobs/steps/executed logs reviewed,
  Windows artifact10078655466 exported. See `MAIN-GREEN-20260908.md` under
  `ralph/reports/FOUR-BIOME-BUILD/`. No new main landing occurred this exit.
- PR90 gameplay head `10fb6f1dbcc4dd42fdf4fb532c7fee4101dac801` passed
  CI34287024505 attempt1:26 successful jobs/three expected skips,3060 unit
  tests/487393 assertions,86 first-attempt wrapped smokes. Exhaustive review
  is preserved in `.artifacts/wave6-pr90-ci-34287024505-FINAL.txt` and its
  alljobs/logreview files; all26 raw logs are in `.artifacts/ci-34287024505/`.
- Picker/input head `8eb887baced51b611abcf8dfadd630dfc1c5640c` passed
  CI34288938433 attempt1, terminal23:21:44UTC:26 success/three expected skips.
  All four unit shards passed:3062 tests/487412 assertions. All26 executed
  logs were downloaded at exit, but final exhaustive smoke/diagnostic review
  was NOT completed. Evidence `.artifacts/wave6-picker-ci-34288938433-*` and
  `.artifacts/ci-34288938433/`.
- The exit commit additionally preserves route-cache work, opt-in profiling,
  the owner directive, diagnostics and this handoff. It needs its OWN CI and
  review; the preceding green heads do not verify it. Keep PR90 draft.
  Check `git log -1` and GitHub for the exit head/run after fetching.
- Do not merge unverified work, raise ceilings, add retries, skip shards, or
  rerun an unchanged failed head to obtain a pass. Let each pushed run finish.

## Completed local work in PR90

The character picker now presents Arlo, Lyra, Kael and Sera as portrait/name cards.
Arlo is the original character, still ID`trainer` for saves/network/body selection.
Installed art was reused. All four selections, keyboard selection and controller
Back passed actual UI checks; blind picker review passed. Root inspected the
1280×800 image `.artifacts/wave6-picker-after.png`. Combined picker/device unit
checks13 tests/70 assertions passed. Input tracking ignores old-device releases and
stationary cursor events; genuine mouse movement still switches to mouse hints.
`gate_a_opening_drive.gd` and `smoke_title_new_game.gd` identify the picker by
stable `character_id` metadata instead of the old display name. Details in
`CHARACTER-PICKER-OWNER-FIX.md` under the report directory.

The owner confirmed Command Center→Control Mode→Gamepad/use X resolved the reported
ROG bed problem. A real wake-scene diagnostic also accepted physical X and advanced
wake→house, but it was injected pad input on this machine, not ROG hardware.
No wake-specific production change was justified. Logs `.artifacts/urgent-wake-pad-v2*`.

Lantern Hollow's four NPCs have distinct placements around the unchanged Spark
shrine. Ordinary grounded approach reached all four exact prompts, and Sable's
dialogue granted captive_truth_learned. Crown preparation derives its six-glass
requirement from the real arch cost; full builder payment remains required.
Reports `GAMEPLAY-WAVE6.md` and `LANTERN-HOLLOW-CONTACTS.md` record scope and checks.

## Loading evidence and retained partial optimization

Actual solo Meadows→Cloudreach through `Game.enter_realm` completed in336.006s,
with pending entry cleared and44,347 destination nodes. This diagnostic bypassed
the progression gate explicitly; it is NOT an earned crossing or campaign proof.
Construction took322.431s: routes82.878s; post-environment ground-cover/chapter/look/
encounter setup233.020s. CPU kept advancing during the quiet interval; no deadlock
was observed. Exit0 and owner save fingerprints matched. Logs
`.artifacts/realm-load-baseline-v2{,-engine}.log`; original instrumentation parse
failure retained as `.artifacts/realm-load-baseline{,-engine}.log`.

Retained source changes:

- `autoload/game_state.gd`, `scripts/world/shell_build_budget.gd`, and
  `scripts/world/cloudreach_look.gd`: timing output behind `--profile-realm-load`.
  No new slicing, content removal or changed timing ceiling.
- `scripts/world/cloudreach_world.gd::_add_geological_face`: sample shared grid
  vertices once, retaining triangle order, UVs and winding. One actual authored
  ridge fixture measured267,896µs→212,454µs total; geological sampling
  194,430µs→128,043µs. Both868 calls/49,812 vertices, exact identical mesh-array
  and collision SHA256:
  `213e3dccb23330a560fec6d2604c5c12aae17c116ded6c67eb10874151c970d8`.
  Both valid runs exited0 without errors/warnings. Earlier two invalid receipt
  fixtures are preserved. These single native measurements do NOT establish a
  full-transition speedup. No optimized full-transition run was completed.

The native result only covers the measured ridge; broaden geometry equivalence
before shipping as appropriate. Do not turn the resume into a performance project:
the owner's latest Stage C6 directive superseded further optimization work.

## New unresolved rendered Cloudreach crash

The three-stand Cloudreach baseline was supplemental work begun before the general
audit directive. It did NOT complete. `.artifacts/wave6-cloudreach-before.log`
reports `ERROR: Parameter "mem" is null` at alloc_static, then a C++ crash/signal11.
The GDScript stack names `_plant_tufts` in cloudreach_look.gd:1086,
`_dress_ground_cover_finish`:714, `dress`:152, runtime`mount`:70, world`_ready`:362.
Line numbers can move with later instrumentation. No authoritative numeric exit
code was recovered: its session handle40509 was unavailable at exit. No Godot
process remained. This is a crash, not a successful capture or an owner interruption.
The after-save fingerprint was captured by root and exactly matches before:
`.artifacts/wave6-cloudreach-before-owner-{before,after}.json`.

Do not infer a finished visual baseline from this run. Investigate the actual memory
allocation failure enough to capture the complete production view, without hiding
ground cover or reducing visible content just to obtain a sheet.

## Stage C6 audit — not executed yet

The catalogue is `data/config/debug_teleport_spots.json`, the actual Settings source:

| Biome | Destinations | Minimum day/night destination records |
|---|---:|---:|
| Meadows |10|20|
| Cloudreach |12|24|
| Stormwood |12|24|
| Water/Tidewake |24|48|
| Total |58|116|

This is a coverage floor, not a cap on camera views. Survey EVERY catalogue location,
both day and night, and frame creatures/structures with the1.80m trainer where
possible. Do not extrapolate from routes. Extend `tools/survey.sh` or an equivalent;
the complete catalogue survey implementation was not written before the stop.
Existing `tools/contact_sheet.gd` can assemble images; it prints an order manifest
and draws separator rules rather than text labels, so preserve exact frame identity.
Produce four complete biome sheets and one combined sheet, retaining full frames.

Use a fresh code-blind judge with `fork_turns="none"`: only frames, the unchanged
`.claude/skills/visual-judge/SKILL.md` rubric, and `docs/reference`. Do not tell it
the changes, owner complaints, or that this is a hard pass. Run the WHOLE rubric.
No numeric scores. Existing agents know implementation context and cannot be that
blind judge. Judge every sheet; use individual frames for legible inspection.

For every accepted finding record priority, exact frame/location, observed problem,
likely owner file/system, proposed fix, acceptance criterion/Beta impact, whether
LOCAL or SYSTEMIC, and whether in-engine or needs new art/reference. Repeated defects
belong in shared systems. Group evidence into actionable Stage-C items without
discarding affected locations. Every claimed fix needs before/after sheets on ALL
affected biomes. No shrinking to fix scale. Installed families only; no extra Meshy
exception, no new gameplay explanation for a visual gap; oxblood remains Team Tether.

Unjudged leads ONLY, not the audit findings or scope: opaque Cloudreach sphere clouds;
Stormwood ground materials borrowed from Meadows; Water lacks a vegetation/groundcover
renderer; installed alternate ground textures may be more appropriate. No visual
production repair was made, and no biome-wide blind visual verdict exists this exit.

## Separate earned-content lane — preserve the original deliverable

Keep this lane running when work resumes; it cannot wait for the entire visual audit.
Serialize only conflicting files and full Terrain3D processes for RAM. Debug visual
travel may coexist as separate evidence but must never count as the genuine campaign.

The previously interrupted Stormwood chapter fixture can resume by starting its
existing earned helper from its disclosed starting state, not by copying a later save:
`.artifacts/run-wave6-stormwood-crown.ps1`, `wave6-stormwood-crown{,-engine}.log`.
It had reached Ashfoot/Hesk/Tamsin, an actual Break and six gathered Stormglass, then
was explicitly stopped for the ROG issue. No Crown completion. It carries an already
completed Cloudreach/five-level44 fixture, so it cannot satisfy the fresh-save goal.
No new content run or source edits occurred after the latest lane reassignment.

Genuine fresh evidence remains incomplete. Best earlier frontier:595.393s, five
earned creatures/10 training wins, paid camp materials, two actual bed rests, then
third-bed assignment navigation stalled. No full care/tournament or all-biome proof.
Wave6 new fresh run on526bb5aac failed302.373s into the first fight before capture;
two off-reticle throws, then loss. The changed run on10fb6f1db failed212.729s because
the final production aim verdict was outside the target BEFORE an orb was spent.
After two no-yield fresh runs, full opening repetitions stopped. An isolated proposed
aim-follow hook also failed and was withdrawn; do not restore it as if verified.
Relevant logs `.artifacts/wave6-fresh-campaign*`, `wave6-fresh-final-verdict*`, and
`aim-follow-*`. No HP/items/progress injection, copied-save workaround, added retry or
loosened assertion is permitted to finish the genuine opening→ending run.

## Reproduction artifacts and final stop

Raw logs, images and isolated profiles remain local in `.artifacts/`; generated
payloads and owner saves are intentionally not committed. Small diagnostic source
copies are pushed under `ralph/reports/FOUR-BIOME-BUILD/exit-20260908-diagnostics/`.
Their README explains restoration; they are diagnostics, not registered tests or
complete survey tooling. Older untracked capture folders and the unrelated neighbor-
tree probe were preserved, not swept into this exit commit or deleted.

Resume sequence: inspect exit-head CI and draft state; resolve the rendered capture
crash enough to survey; execute all58 destinations day/night and blind full-rubric
audit; classify accepted findings before repairs; keep the separate earned-content
lane advancing. Land only exact verified heads and verify main's own run.

**Stop now as requested. No deployment, merge, full audit, full campaign, or goal
completion is claimed.**
