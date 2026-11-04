# CI-SPEED (4 Nov 2026): shared assets cache for engine-job checkouts

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

### After, warm run: PENDING (dispatched 01:4x on 5aa5cb68c)

