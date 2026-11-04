# CI-SPEED (4 Nov 2026): shared assets cache for engine-job checkouts

**Coordinator: READY to land in a PR with full-ci** (send_message to your session was
refused for an untrusted device, 02:11 UTC). Head of tb/ci-speed-1104; design
complete at a9ea0b2e7. Two fast-tier runs were green (41751198534, 41755756668).
Checkout per engine job went from 4-47.5 min (median ~26) to 12-17 s; restore
takes 1.25-2.1 min and verifies all 7,548 files against git. A third run proves the
trimmed export templates. The main-only import-cache save is proven only after
landing (the first main run fills main's caches).

**PR #810 landed this lane on main only up to 5aa5cb68c (the assets cache).
The cache-budget fix a9ea0b2e7 is still open: tb/ci-speed-1104 now has main
merged in, and its diff against main is just that fix plus this report. Please land
it in the next batch.**
Without it, every branch and PR keeps saving its own 2.7 GB import cache and
1.27 GB template set, GitHub keeps evicting main's caches, and setup-godot
falls back to cold imports (7.5-8 min). Run 41759063511 below proves a9ea0b2e7.

Owner (4 Nov): "Do all the fixes to make the download faster without losing any meshy assets permanently".

## Design (as built, branch tb/ci-speed-1104)

- `assets-cache` job (needs `changes`, runs when `code == true`): blobless sparse
  checkout of `/tools/ci/` only; `tools/ci/assets_cache.py plan` splits assets/
  (7,548 files, 6.99 GB) into 8 chunks by a hash of each path's first four
  components (one creature/Meshy folder = one chunk; 0.67-1.24 GB each). A
  chunk's key is sha256 of its exact `mode oid path` listing, so a key can never
  name other bytes. Lookup-only restores find hits; each missing chunk is
  fetched with 4 parallel blob fetches, tarred, its files deleted, then saved.
  It cannot fail a run (continue-on-error); engine jobs fall back to git.
  It prints repo cache usage and prunes this ref's stale `assets-v1-` entries
  (unused for 60 min), so other caches are not evicted by our own leftovers.
- 12 engine jobs: sparse checkout now also excludes `/assets/`; then
  `.github/actions/restore-assets` restores the 8 tars, fetches any missing or
  malformed chunk from git (the old path), clears skip-worktree on assets/ and
  lets `git update-index --refresh` re-hash every file against its blob id;
  any modified/missing/extra file is rewritten from git and re-verified, else
  the job fails. The work tree ends identical to a full checkout (`git status`
  clean; `git ls-files`/`git diff` unchanged).
- Partial-hit diffing from the brief was replaced by chunking: a change
  re-saves ~1 GB chunk(s), not 7 GB, with no T0 bookkeeping.
- Nothing is deleted from the repository or its history.

## Tests
- tests/test_ci_assets_cache.py (new, runs in `changes`): real blobless sparse
  clone; warm restore with zero fetch; missing chunk falls back; malformed and
  tampered tars rejected; bytes re-hashed independently.
- test_ci_select_jobs, test_ci_suites pass unchanged; test_ci_net_shards'
  header check updated for `needs: [changes, assets-cache]` (still asserts no
  discovery dependency).

## Timings (before: run 41722777593, 3 Nov, full-ci PR)
Checkout per engine job: 4.0-47.5 min, median ~26 min (21 jobs).

### After, run 41751198534 (cold: no assets cache existed; fast tier; ci-gate success)

| Job | checkout | assets restore | total job | before (3 Nov) checkout / total |
|---|---|---|---|---|
| assets-cache (prep) | 2 s | build all 8 chunks from git 1.9 min + save 0.75 min | 4.5 min | (new job) |
| verify-suite (3) | 15 s | 1.6 min, 8/8 chunks hit, 7,548 files verified | 7.7 min | 5.6 / 25.1 min |
| verify-suite (4) | 12 s | 1.3 min, 8/8 hit, verified | 13.6 min | 10.7 / 29.2 min |
| export | 17 s | 2.1 min, 7/8 hit, chunk 7 "Cache not found", fetched from git in 55 s, verified | 18.5 min | 23.2 / 36.1 min |

Every restore printed `assets/ verified: 7548 files match their git blob ids`.

Cache budget (prep job's `actions/cache/usage` and list, 01:07 UTC): 12.57 GB active
against GitHub's 10 GB default. Entries: three Godot import caches of 2.66 GB
(two on main, one on tb/repo-slim-1104), godot-4.7-stable 1.27 GB, godot-editor
70 MB, and the eight assets chunks 6.25 GB (595-1,105 MB each, zstd).
GitHub then evicted: export found no import cache at all (cold import, 6 min)
and missed chunk 7. The fallback kept the run correct and green.

The minimum set for one branch is assets 6.25 + templates 1.27 + editor 0.07 +
one import cache 2.66 = **10.25 GB**, just over 10 GB. Commit 5aa5cb68c prunes
each ref's older import caches (keeps the newest) and stale assets chunks.
Branch runs save only the chunks that differ from main once main holds a set.
**Owner option:** raise the repository's Actions cache limit (Settings >
Actions > Caches; billed above 10 GB). Without it, an occasional eviction
costs a 1 GB chunk re-fetch (~1 min) or one cold import (~6 min), never
correctness.

### After, run 41755756668 (warm; 5aa5cb68c; fast tier; ci-gate success)

| Job | checkout | assets restore | setup-godot | total job |
|---|---|---|---|---|
| assets-cache (prep) | 2 s | 4/8 chunks still cached; rebuilt 0,1,2,7 (evicted) in 56 s, saved in 19 s | - | 3.3 min |
| verify-suite (3) | 15 s | 1.8 min, 8/8 hit, 7,548 files verified, 0 from git | 7.5 min (import cache evicted: cold) | 15.7 min |
| verify-suite (4) | 12 s | 1.25 min, 8/8 hit, verified, 0 from git | 8.1 min (cold) | ~21 min |
| export | 12 s | 1.25 min, 8/8 hit, verified, 0 from git | cold import 7.8 min | 18.6 min |

Cache at 01:49 UTC: 11.24 GB active. **Every main-scoped entry had been
evicted** (main's import caches, godot-4.7-stable, godot-editor); what remained
was this branch's assets chunks and godot-4.7-stable plus PR #808's import
(2.67 GB) and godot-4.7-stable (1.27 GB). Per-branch import and template copies
were the overflow: GitHub evicts least recently used entries beyond 10 GB.

### Budget fix, a9ea0b2e7 (third run dispatched to prove the export path)
- Godot import caches (~2.7 GB) are restored everywhere and **saved only from
  main runs** (setup-godot and export). Branches restore main's by prefix and
  reimport only what they changed.
- The export job's editor+templates entry keeps only Windows and Linux
  templates under a new key `godot-winlinux-<ver>` (was 1.27 GB with every
  platform). release.yml keeps its own full `godot-<ver>` entry.
- Steady state on main: assets ~6.3 + one import ~2.7 + editor 0.07 +
  win/linux templates (well under 1.27) is about 9.3 GB, so it fits 10 GB with room
  for a PR's changed chunks (~1 GB each, pruned when stale).
- Can only be fully proven on main: the first main run after landing fills
  main's assets and import caches, and later branch/PR runs hit them.


### After, run 41759063511 (a9ea0b2e7; fast tier; ci-gate success; 17 min wall)

| Job | checkout | assets restore | setup-godot / import | total job | before (3 Nov) total |
|---|---|---|---|---|---|
| assets-cache (prep) | 1 s | 8/8 chunks cached, nothing to build | - | 2.0 min (1.9 of it the disk-free step) | (new) |
| verify-suite (3) | 12 s | 1.4 min | 1.35 min (warm) | 8.2 min | 25.1 min |
| verify-suite (4) | 12 s | 1.3 min | 1.3 min (warm) | 14.3 min | 29.2 min |
| export | 11 s | 1.9 min | templates install 38 s (win/linux only), import 41 s | 12.3 min | 36.1 min |

Export (Windows debug) and the Linux run check (tools/verify_export.sh) are green
with the trimmed templates; the import save stayed skipped off main, as designed.

Follow-up worth one more change: the "Free runner disk" step costs 0.6-2 min
in every job and was added for the old 7 GB checkout written twice. The peak is
now the 6.3 GB of tars plus 7 GB extracted; unpacking each chunk right after
its restore would let that step go.

### On main: first full-tier run with the cache, 41787100516 (schedule 06:40 UTC, 12e76f2aa = #813 merge)

All 36 engine jobs: checkout 0.2-0.3 min, assets restore 1.1-2.1 min, every
restore step green (before 3 Nov: checkout 4-47.5 min, median ~26). Prep
job 3.9 min (built changed chunks in 1.7 min).

Run concluded **failure**, not from the cache: verify-regions-relay
(tidewake) failed "Water species catalogue accepts the Aquaryn fixture";
verify-suite (2) and verify-multiplayer-shard (9) failed in their test steps.
The restore had already verified all 7,548 assets/ files against git, so these are
game/data regressions in the merged batches. They belong to the owning lanes.

setup-godot was 5.4-9.1 min in 21 of 35 jobs (cold import) and 1.1-1.5 min in
the rest. That is the cache-budget eviction a9ea0b2e7 fixes, and it is still
unlanded (#810-#817 all lack it). Landing it should take each of those jobs
back to ~1.3 min.
