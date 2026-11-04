You are the Tetherbound CI-SPEED lane (4 Nov 2026). Your branch: tb/ci-speed-1104. Create it from origin/main, work and push only there. Lane folder: ralph/reports/LANES/CI-SPEED/.

Read CLAUDE.md first; it is binding. The coordinator is session session_01CfKRDSan7LUFmNAx6VWNUy. It lands your work in a PR with full-ci; never push to main.

OWNER (4 Nov 2026, verbatim): "Do all the fixes to make the download faster without losing any meshy assets permanently". This explicitly authorises CI work; it is not ordinary harness work.

Measured facts (coordinator, 3–4 Nov):
- Every engine job in .github/workflows/ci.yml does `actions/checkout@v4` with `filter: blob:none`, depth 1, and a sparse checkout that excludes ralph/, docs/, shots/, assets_raw/, archive/ and tests/fixtures/earned_saves/f49_*/save/.
- That materialises 16,842 files, 7.1 GB. assets/ alone is 6.5 GB: assets/creatures/tetherbound 2.9 GB, assets/props/meshy-* about 2.2 GB. The full tip is 8.9 GB.
- With ~30 jobs per run, checkout took 6–59 minutes per job on 3 Nov. One runner hit "Out of diskspace", and many jobs were cancelled at their limits.
- #809 (on main) added a free-disk step and +30 min per job. That is a stopgap.
- A non-blobless shallow fetch would download 8.9 GB instead of 7.1 GB, so it is no help.
- A separate REPO-SLIM lane (tb/repo-slim-1104) is moving UNREFERENCED Meshy files to an archive branch, tb/meshy-archive. Don't duplicate that.

Your task is to make each engine job's checkout take a few minutes, using a shared assets cache. Recommended design (improve it if you measure something better):
1. **Prep job.** A new job, `assets-cache`, needs only `changes` and runs only when engine jobs will run. It:
   a. does the existing sparse blobless checkout, also excluding /assets/;
   b. computes `ASSETS_TREE=$(git rev-parse HEAD:assets)`;
   c. calls `actions/cache/restore` for path `assets` plus a small metadata file outside assets/ (e.g. `.ci-assets/tree`), with key `assets-${ASSETS_TREE}` and restore-keys `assets-`;
   d. on an exact hit, does nothing more;
   e. on a partial hit (an older tree T0 recorded in the metadata), fetches T0's commit trees blobless (`git fetch --filter=blob:none --depth=1 origin <commit>`, with the commit recorded too), diffs T0 against ASSETS_TREE, materialises only the changed or added paths in one batched lazy fetch (e.g. `git checkout --ignore-skip-worktree-bits HEAD -- <paths>`), and deletes removed paths;
   f. on a miss, materialises all of assets once;
   g. saves the cache under the exact key with `actions/cache/save`.
2. **Engine jobs.** Each engine job `needs: assets-cache`. It checks out sparse blobless excluding /assets/, then restores the exact cache key with `fail-on-cache-miss: true`. Keep a guarded fallback: if the restore fails, materialise assets the old way.
3. **Correctness.**
   - Godot import must see exactly the same assets/ tree as today. Add a verification step that compares, for every path under assets/, the git blob hash with the restored file's hash (`git hash-object`), or a cheaper but sound equivalent. Never trust a stale cache silently.
   - Anything that shells out to git over assets/ must still work. Check tests and tools for `git ls-files` or `git diff` use under assets/.
4. **Cache budget.** GitHub's cache limit is 10 GB per repo, and existing caches include the Godot editor and import caches. Measure the cache list (`gh`/API via the GitHub MCP tools if available, or note what you can't check). Make sure the assets cache does not evict the others every run. If 6.5 GB doesn't fit alongside them, cache only the largest stable subfolders, such as assets/creatures and assets/props, and fetch the rest normally.
5. **Tests.** Keep `tests/test_ci_select_jobs.py`, `tests/test_ci_net_shards.py` and `tests/test_ci_suites.py` passing, updating them only where they enumerate jobs. Never weaken a test.
6. **Prove it on a real PR run.** Push the branch. The coordinator opens a PR with full-ci, or you can ask it to. Report per-job checkout and restore minutes before and after in READY.md.

Rules:
- Never lose or delete any asset file from the repository or its history.
- Never skip, disable or quarantine tests.
- Don't change test content or timeouts that bound tests.
- Push hourly.
- When the design passes a real run, send the coordinator the commit and timings with send_message to session_01CfKRDSan7LUFmNAx6VWNUy.
- Never sit idle. Arm send_later 20–30 minutes out before ending any turn.
