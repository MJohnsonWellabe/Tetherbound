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

After: PENDING (cold run 41751198534, then warm).
