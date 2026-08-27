# Coordinator handover — 2026-08-27, third rotation

Written for a successor with no memory of today. This rotation did one thing:
CI speed. Nothing is going wrong; the session is being archived because it
could not dispatch (§1).

---

## 1. Do this first — check whether you can reach GitHub Actions

Run this before planning anything:

    curl -sS -o /dev/null -w "%{http_code}\n" https://api.github.com/repos/MJohnsonWellabe/Tetherbound

**200** — you have the App scope. Proceed to §2.
**403** — you are in the same hole this session was. The body reads
`GitHub access is not enabled for this session. An org admin must connect the
Claude GitHub App for this organization.` That 403 comes from the Anthropic
egress proxy, not GitHub. Git clone/fetch/push still work, because credentials
are injected into git smart-HTTP only (`GITHUB_TOKEN` is literally the string
`proxy-injected`). There is no `gh` binary and no Actions tool in the tool
surface — I searched.

**The likely cause, unproven:** this session's record had **no `sources`**. The
repo was attached after the fact with `add_repo`, which grants git access but
apparently not the GitHub App scope. The Gate F lane's session record *does*
carry `sources: [{git_repository: tetherbound}]` and the 2026-08-26 coordinator
was reading run numbers and job timings, so the App is connected for the org —
this session just was not scoped to it. **Start a coordinator session with the
repo as a source at creation, not with `add_repo` afterwards.**

Without it you can push branches but cannot dispatch `ralph-sweep.yml` and
cannot read a run. Do not spend the session rediscovering that.

**Also worth knowing:** `ci.yml` is `on: push` for `ralph/**`, so CI runs
automatically when you push a branch. Only the *sweep* is dispatch-only. A run
for `8f11e675` exists and has never been read by anyone.

---

## 2. State

`main` is **`f082bdf6`**, unmoved all rotation. Four branches exist:

| branch | |
|---|---|
| `main` | `f082bdf6` |
| `ralph-status` | unrelated history, coordinator notes |
| `ralph/CI-IMPORT-AND-SHARDS` | `8f11e675` — this rotation's work, green status unknown |
| `ralph/GATE-F-RUN-20260827` | Gate F's live evidence branch, still growing |

**Sweep hazard:** `ralph-sweep.yml` takes no branch argument and lands EVERY
green `ralph/**` branch. Two are outstanding. I checked: they touch **no file
in common**, so they merge cleanly in either order and neither carries a scatter
re-bake. Landing both together is safe — but Gate F is mid-run, and landing
their branch moves `main` under a live lane. Make it a decision, not a surprise.

---

## 3. What is on `ralph/CI-IMPORT-AND-SHARDS`

Full measurements are in **`ralph/CI_SPEED_2026-08-27.md`**. Read that, not this
summary, before touching CI again.

1. **`.gdignore` on `ralph/` and `shots/`.** Godot was importing the
   visual-judge output — 381 report PNGs and 161 survey files — as game
   textures on every job. Cold import **533 s → 218 s**, `.godot` **980 MB →
   484 MB**. Over half of every job's import cost was screenshots of the game.
2. **Deleted the 16 jobs carrying `if: false`** — superseded by shards, never
   removed. 1342 lines that ran nothing and showed as 16 skipped entries every
   run.
3. **Split all five serial shards into per-smoke matrices.** Splitting only the
   two the previous handover named would not have moved the critical path.
4. **blob:none + sparse-checkout on verify jobs**, excluding `ralph/`,
   `assets_raw/`, `docs/`, `shots/`: **2.08 GB → 895 MB** per checkout.
5. The 13 missing `.gd.uid` sidecars.

**Verified, not assumed:** coverage is identical before and after — 35 distinct
smokes, none lost; every matrix entry resolves to a real test file; the YAML
parses; the generated runner block was executed here against two real smokes;
and the sparse tree imports clean and passes smoke + unit shard.

**The one open risk.** Live legs go **26 → 51**. They contend for runners, and
checkouts degrade to 7–12 minutes under load. The sparse-checkout commit is the
paired mitigation. **Whether the net is positive needs one observed run, which
this session could not do.** If the first run is worse rather than better,
revert `ff75c5a` alone — it is self-contained and leaves the rest in place.

### Two corrections to `HANDOVER_2026-08-26_COORDINATOR_2.md` §6

- **The re-import hypothesis is dead.** §6 item 1 proposed that checkout stamps
  fresh mtimes and Godot re-imports. Measured: touching all 12,977 tracked files
  costs **11 seconds**, not 533. Godot 4.7 validates by content. Do not spend
  more time on mtimes.
- **The repo-size weight is not `data/scatter`.** All of `data/` is 50.1 MB and
  `data/scatter` is 27 MB — about 1%. The weight is `ralph/` 736.7 MB,
  `assets_raw/` 350.0 MB, `docs/` 69.0 MB, `shots/` 47.0 MB: 1.20 GB of the
  2.08 GB tip, read by no job.

**Still an owner decision, deliberately not done:** those trees are in git
history, so `.git` stays 1.8 GB and every full clone pays for them.
Sparse-checkout avoids the cost in CI without touching history. Removing or
LFS-ing them is the only thing that shrinks the clone.

The floor is unchanged: `test_scatter_rules.gd` is ~11 minutes in one process
and no split touches it. Going below that is a decision about the test.

---

## 4. The Gate F lane

Session `session_01RG7KvPNBDWN9NCU4JqqJRX`, re-froze its candidate at
`f082bdf6` and is running. **S01–S10 complete — journey lane done** — now on
X01 (1085 PASS / 118 FAIL over 975 probes). Reach it with `create_trigger` +
`fire_trigger`; it cannot reply.

What their commit subjects report finding, theirs to chase, not yours: a
**blocked crossing hit four times across S06–S09**, panels holding input
(`SwapPanel` for 84% of S03, `DialoguePanel` to the end of S04), and the first
fight never staging in S02. The catch-3 engage defect
(`smoke_party_count_after_catches`) remains their open item.

Good hygiene worth preserving: this run commits manifests and telemetry,
**no PNGs and no `.import` sidecars**, unlike the 381 frames already in
`ralph/reports` from earlier runs.

`smoke_party_count_after_catches` deliberately keeps `retries: 1` in the new
matrix. A retry would green it and hide the cause — the same reason
`stick_navigator` is withheld from it. Its own leg means its flake no longer
fails six unrelated owner regressions with it.

---

## 5. Standing constraints, unchanged

- **Never push `main`.** Ship via `ralph/<task>` branches and a dispatched
  sweep. **No pull requests.**
- The download site tracks `main`. **Never dispatch `release.yml` against a
  `ralph/**` ref.**
- **Never rebase a branch carrying a scatter re-bake** — merge `main` forward
  by hand. Use two-dot `git diff A B` for content comparison.
- A `timeout-minutes` kill reports as **cancelled**, not failed. A path-filtered
  skip and a real pass are identical at run level — confirm the `changes` job's
  filter step actually RAN and printed `code=true`.
- `verify-continuous-core-known-red` fails by design. Do not chase it.
- [OWNER-ONLY], never claimed from a Linux container: device frame rate, GPU,
  VRAM, thermals, controller feel, audio, Windows-export identity.
- The container is ephemeral. Commit and push anything worth keeping.
