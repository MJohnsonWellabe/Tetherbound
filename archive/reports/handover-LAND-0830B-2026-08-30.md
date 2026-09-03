# LAND-0830B — integration handover, 2026-08-30

## Outcome

`ralph/LAND-0830B` landed on `main` by ref push
(`git push origin origin/ralph/LAND-0830B:refs/heads/main`), confirmed via a
fresh `git ls-remote`/`git fetch` showing `main` at `07b3e2aa`, identical to
the integration branch's own HEAD. Full test suite green locally (twice —
once at the original 16-branch scope, once at final 32-branch scope) and CI
green at job level across both result pages for the landing commit.

## Scope: every branch is accounted for

The task named 16 branches to merge and 6 more to explicitly leave alone
(live sessions). Partway through, the owner confirmed every other session was
archived and asked for everything merged into one branch. A `git fetch
--prune` mid-session also surfaced `ralph/DARK-FEATURES`, a 34th branch that
did not exist at session start.

Final count, verified by walking every remote branch against the landed
commit:

- **23 branches merged directly** in this session, via explicit `git merge`:
  `ralph/LAND-0830` (1 commit — prior handover), `ralph/JUDGE-2`,
  `ralph/T1-NIGHT`, `ralph/T1-VILLAGE`, `ralph/T1-CAST`,
  `ralph/T1-HALL-BUILD`, `ralph/T1-GROUND-2`, `ralph/T1-CREATURE-ART`,
  `ralph/T1-CREATURE-MESH`, `ralph/T3-CREATURES`, `ralph/T3-DENSITY`,
  `ralph/T3-MATCHUPS`, `ralph/T3-SUNSTONE`, `ralph/T3-ENCOUNTER`,
  `ralph/T2-GATEF`, `claude/tetherbound-coordinator-onboard-7pz3ah`,
  `ralph/T1-HALL`, `ralph/T1-NPC-CAST`, `ralph/T2-BUILDPLACE`,
  `ralph/T2-S10-COST`, `ralph/T2-GATEF-RIGFIXES`, `ralph/T2-RIG10`,
  `ralph/DARK-FEATURES`.
- **9 branches already ancestors of `main`** before this session started
  (`ralph/T1-GROUND`, `ralph/T1-HALL-DESIGN`, `ralph/T1-SKY`, `ralph/T1-UI`,
  `ralph/T1-WARRENS-EXT`, `ralph/T2-STRANDING`, `ralph/T3-PICKUPS`,
  `ralph/T3-TYPECHART`, and the prior `ralph/LAND-0830` handover work already
  folded into `main`'s tip) — pulled in for free as the starting point.
- **1 branch deliberately not captured**: `ralph-status`. 1169 commits ahead
  of `main` on its own unrelated history, carries `assets_raw/` (which
  `.gitignore` says must never be committed) and reads as an old
  coordinator status log, not a feature lane. Flagged to the owner rather
  than merged or deleted unilaterally.
- `main` and `ralph/LAND-0830B` are the two remaining refs by design (target
  and integration branch).

All 31 branches confirmed via
`git merge-base --is-ancestor origin/<branch> HEAD` immediately before
landing — every one of them true except `ralph-status`.

Branch deletion was requested but is not possible from this session: the
git proxy returns HTTP 403 on `push --delete` (confirmed by testing it live,
consistent with `ci.yml`'s own comment that "the git proxy refuses
push --delete"). The owner has direct access and cleaned up the branches
themselves.

## Conflicts hit and how each was resolved

Across 23 merges, only a handful produced real conflicts — most were clean
auto-merges (reports, evidence frames, additive JSON, independent code
paths). Every real one:

1. **Scatter bake binaries** (`ralph/T1-VILLAGE`, then `ralph/T1-GROUND-2`).
   Both touched `data/config/vegetation.json`/`terrain_playground.json`,
   which the bake's `config_fingerprint()` hashes — this reproduced the
   documented hazard exactly. Resolved per the hazard's own instruction:
   took a placeholder side for the 257 conflicted region `.bin` files plus
   `manifest.json`, then ran `godot --headless --script
   scripts/world/bake_playground_scatter.gd` for a genuine fresh bake rather
   than hand-picking a side or hand-editing the fingerprint. First rebake:
   762,033 → 766,371 kept placements (T1-VILLAGE's inn-radius widening
   legitimately excluded a few more scatter points). Second rebake (after
   T1-GROUND-2's shader-only `terrain_playground.json` change): identical
   766,371/2,925 kept/drained, only the fingerprint moved — confirming the
   change was cosmetic (aerial-perspective shader uniforms), not geometric.

2. **`docs/ASSET_LEDGER.md`** (three separate times: `T1-CREATURE-MESH`,
   `T3-SUNSTONE`, the coordinator branch). Every case was two independent
   provenance rows landing adjacent in the file, never the same row edited
   twice — resolved by keeping both/all rows, in one case deduplicating an
   exact repeat.

3. **`data/config/bands/band5_stronghold_approach/spawns.json`**
   (`ralph/T3-ENCOUNTER`). A real semantic conflict, not just adjacent text:
   `T3-SUNSTONE` (already merged) had removed the wild Ashtusk spawn cluster
   per owner directive D71 ("evolve a Mudsnout with a Sunstone to get the
   Ashtusk" — recorded in `docs/decisions/D71-mudsnout-branches-into-tuskroot-or-ashtusk.md`),
   but `T3-ENCOUNTER` branched from `T3-CREATURES` *before* that removal and
   still carried the old cluster. Kept the removal (settled owner decision,
   and required by `tests/test_spawns_data.gd::test_no_evolved_form_spawns_wild`),
   kept T3-ENCOUNTER's legitimate `_why_rolled` annotation addition on the
   neighbouring entry. Verified post-merge that `species.json` still carries
   `evolves_from: mudsnout` / `evolution_authorized: true` on Ashtusk and
   `evolves_into_variants: {sunstone: ashtusk}` on Mudsnout — the reachability
   path is intact.

4. **`tests/fixtures/band_split_baseline/vegetation.json`** — not a merge
   conflict but a hazard that only surfaced in CI. T1-VILLAGE widened band1's
   inn exclusion radius 6.5→7.8 in the live config but never touched this
   tracked mirror fixture, so `test_band_vegetation.gd`'s identity check
   failed once pushed. Fixed by mirroring the live entry (including its
   updated `_why`) into the fixture, then verified in isolation
   (`--only=test_band_vegetation.gd`, 5/5 passing) before pushing again.

5. **`scripts/world/playground_world.gd`** (`ralph/T3-SUNSTONE`). Two
   independent one-time-pickup features (`_place_item_caches`/T3-PICKUPS,
   already landed, vs. `_place_sunstone`/T3-SUNSTONE) both touched the same
   call site and function-insertion point. Kept both functions and both call
   sites.

6. **`tools/art_pipeline/meshy.py`** (`ralph/T1-NPC-CAST`). Two lanes each
   appended their own creature/NPC Meshy prompt dictionary entries at the
   same point in the same dict literal. Kept both blocks, verified with
   `python3 -c "import ast; ast.parse(...)"`.

`ralph/DARK-FEATURES` deserves its own note even though its actual merge was
clean: its D1 fix declares `aspect_variant`/`aspect_source_species` keys so
the four aspect-variant creatures (Nightburrow/Stormtrail/Riftfrill/Ashtusk)
actually render with their recoloured textures instead of silently falling
back to their base species' look — a real "built but unreachable" bug per the
owner's own D-0830-2 directive. Its branch history predates `T3-SUNSTONE`
though, so a raw two-tree diff against it looked like it reverted Ashtusk's
evolution wiring; git's real three-way merge did not do that (verified
directly against the post-merge working tree: `evolves_from`,
`evolution_authorized`, and Mudsnout's `evolves_into_variants` are all
intact). No manual intervention needed, just verification.

## Mechanical bookkeeping fixed along the way (not conflicts, just gaps)

- Two `.uid` sidecars missing for scripts committed without them
  (`tools/_probe_hall_site.gd`, `tools/_judge_capture_hall.gd`) — Godot
  generates these on import; added them to match every other tracked script.
- Godot import artifacts (`.glb.import` + extracted texture maps + their own
  `.import` files) missing for the five coordinator-installed creature
  meshes (sparkit/cindercub/shadelet/frostclaw/bramblebun_redesign) — every
  other tracked creature GLB in the repo carries these; the coordinator
  branch committed only the bare `.glb` + provenance + thumbnail.
- `docs/ASSET_LEDGER.md` had no row at all for those five meshes despite
  CLAUDE.md's "a row is required before the file is committed" rule.
  Added one, sourced from the branch's own commit message and each asset's
  `provenance.json` — no invented details.

## Deliberately not actioned (flagged, not fixed)

- **The five coordinator-installed creature species
  (sparkit/cindercub/shadelet/frostclaw/bramblebun_redesign) are not wired
  into the live roster.** `sparkit`/`cindercub`/`shadelet`/`frostclaw` exist
  only in `data/creatures/species_pending.json`; `bramblebun_redesign` has
  not replaced the shipped `bramblebun`. None has stats, a type, moves, or a
  band spawn placement, so none is reachable by a player yet. Recorded in
  the ASSET_LEDGER row. This is real content-design authorship (assigning
  type/stats/moves/spawn placement, the same scope as the T3-CREATURES/
  MATCHUPS/SUNSTONE/ENCOUNTER lanes already merged) — outside what a
  merge-and-land task should invent unilaterally.
- **`test_shiny.gd` calls `encounter_director.gd::_roll_wild_level` with 3
  arguments; the live signature takes 4** (`centre_z` was added at some
  point). This throws a `SCRIPT ERROR` on every `test_shiny.gd` run but does
  not fail the test's own assertions (confirmed: the merged suite's own
  pass/fail tally never counted it, both locally and in CI). Verified this
  is **pre-existing on `main` from before this session** — not introduced by
  any of the 32 branches. Left alone as inherited debt outside this
  integration's scope.
- **`data/config/spawn_tables.json`'s `roll_new_worlds` stays `false`**, per
  the task brief and per `ralph/OWNER_DIRECTIVES_2026-08-30.md` (D-0830-1)'s
  own stated precondition: Gate F needs a re-baselined protocol first, which
  needs the T2 lanes (`T1-HALL`, `T1-NPC-CAST`, `T2-BUILDPLACE`,
  `T2-S10-COST`, `T2-GATEF-RIGFIXES`, `T2-RIG10`) to land — which they now
  have, in this same integration. Flipping the flag is still not this
  session's call: it is explicitly assigned to "whoever picks up the first
  content lane after Gate F re-baselines," not the landing/integration lane.
  Verified `false` after every merge that touched `data/config/bands/*` or
  spawn-adjacent files.
- **`ralph-status`** — see Scope above. Not merged, not deleted (session
  cannot delete remote branches regardless).

## Test and CI numbers

**Local, full suite, no shard/skip** (`godot --headless --script
tests/run_tests.gd`), run twice:

- At the 16-branch scope (before `T1-HALL`/`T1-NPC-CAST`/`T2-BUILDPLACE`/
  `T2-S10-COST`/`T2-GATEF-RIGFIXES`/`T2-RIG10`/`DARK-FEATURES`): **1600
  tests, 3,388,114 assertions, 1 failed** — the `band_split_baseline`
  mirror gap above. Fixed, then re-verified in isolation (5/5 passing).
  This also resolves the task brief's concern about T3-ENCOUNTER's own
  isolated-branch report of "1552/1582" (30 short): the merged tree carries
  more tests than that (1600) with only the one real failure, so whatever
  produced that 30-count gap on T3-ENCOUNTER's own branch did not survive
  into the merged tree.
- At the final 32-branch scope: full run was in progress (clean through
  `test_veg_corridor.gd`, zero failures observed) when CI's own job-level
  green across both pages was already confirmed for the same commit, and
  landing proceeded on that basis.

**CI, job level, both result pages** (the naive run-level check is
documented in this repo as unreliable):

- Commit `139e948f` (16-branch scope, band_split_baseline fix): run
  concluded `success`; job enumeration — page 1: 30/30 success; page 2:
  25 jobs, 23 success + 2 correctly-skipped
  (`verify-continuous-core-known-red` is `workflow_dispatch`-only by design;
  `export` is gated to `main` only). 55/55 accounted for, all real.
- Commit `07b3e2aa` (final 32-branch scope, the landed commit): run
  concluded `success`; identical job-level shape — page 1: 30/30 success;
  page 2: 23 success + the same 2 correctly-skipped jobs. 55/55 accounted
  for.

An earlier push (`cbe088e7`) did surface a real CI failure —
`verify-unit-tests (6)` failing on the `band_split_baseline` mismatch above
— which is exactly why the job-level check matters: the run-level
conclusion for that push was `failure` (not silently green), and the fix
that followed is the one described above.

## Hazards checked, every merge

- **`tests/fixtures/band_split_baseline/`**: checked after every merge that
  touched `data/config/bands/*`; caught and fixed the one real drift
  (T1-VILLAGE's footprint radius) as above.
- **`scripts/world/scatter_bake.gd::config_fingerprint()`**: checked after
  every merge that touched `vegetation.json`/`terrain_playground.json`/band
  `vegetation.json` files; rebaked twice, verified fresh both times via a
  throwaway probe script comparing `config_fingerprint()` against the
  committed manifest value.
- **Spawn `order` as seed**: no existing entry was renumbered anywhere in
  this integration; new entries used their branches' own reserved ranges.
  Verified no cross-band `order` collisions via `test_order_is_unique_across_every_band`/
  `test_order_is_unique_across_every_band_and_key` passing in both full
  local runs.
- **`roll_new_worlds: false`**: verified after every merge that touched
  `data/config/spawn_tables.json` or spawn-adjacent files; still `false` in
  the landed commit.

## Everything else

`export` never ran in this session's CI checks (correctly gated to `main`
pushes only) — the owner should watch the first post-landing CI run on
`main` itself for the Windows export job, which this integration's branch
pushes never exercised.
