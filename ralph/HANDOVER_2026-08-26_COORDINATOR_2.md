# Coordinator handover — 2026-08-26, second rotation

Written for a successor with no memory of today. Read this before touching a
branch. The immediately actionable state is in §1; everything after it exists so
you do not re-derive what has already been measured.

This is a **cost rotation, not a correction.** Nothing here is going wrong. The
one blocking item is a GitHub Actions outage with no ETA, and waiting it out in a
long-context session is the exact mechanic that took two earlier sessions to
$131 and $186 — cache reads scale with context times turns.

---

## 1. Do this first

**`ralph/LAND-ALL` (`7d194883`) is one green CI run away from putting every piece
of outstanding work on `main`.** It is 0 behind `main` and 38 ahead.

CI run **2523** (id `32984987975`) was created 15:23:59Z and has never started.
That is not the branch's fault — see §3.

1. Re-read `https://www.githubstatus.com/api/v2/summary.json` for the Actions
   component. If it is still `major_outage` or degraded: **do nothing.** Do not
   re-push, do not cancel-and-retry, do not dispatch. That only adds runs to a
   queue that is not draining and costs queue position when it resumes. Arm a
   check-in ~30 minutes out and stop.
2. When Actions is healthy: if 2523 never started, re-run that run id via the
   Actions API rather than pushing. Only re-push the branch if a re-run will not
   take.
3. When it runs, **check the `changes` job before anything else.** See §2 — a
   run can report success having tested nothing, and it has happened twice today.
4. Green: sweep via `ralph-sweep.yml`. **Never push `main`. No pull requests.**
   Confirm by reading `git log origin/main`, not by the sweep's own output.

### After it lands

- Push and sweep **this branch** (`ralph/COORDINATOR-DOCS`) if it has not landed
  already. It is documentation only, so the changes filter skips every job and it
  costs about a minute even while the queue is busy.
- Delete `claude/gate-f-grass-coordination-m2mzcr`. It exists only to hold the
  four coordination documents recovered onto this branch; once they are on
  `main` it carries nothing unique.
- Message the Gate F lane that `main` is complete (§5).
- Verify the download site still tracks `main`. **Never dispatch `release.yml`
  against a `ralph/**` ref.**
- Then, and only then, the CI speed work in §6.

### Branches that exist, and why

The owner cleaned up the subsumed branches already. Five remain and all five are
deliberate:

| branch | keep because |
|---|---|
| `main` | `1dc18642` |
| `ralph-status` | unrelated history (no merge base), coordinator notes |
| `ralph/LAND-ALL` | `7d194883`, the landing |
| `ralph/CATCH3-ENGAGE` | `07452b65`, **live** Gate F work, unmerged |
| `claude/gate-f-grass-coordination-m2mzcr` | the four docs, until this branch lands |

Do not delete `ralph/CATCH3-ENGAGE`. Its CI went green but it is **not** on
`main`, and green there means the bug did not reproduce, not that it is fixed.

---

## 2. Three ways CI lies, all hit today

Every one of these looks like success. Check for them by name.

**A `timeout-minutes` kill reports as `cancelled`, not `failed`.** Downstream
jobs then skip, and the run reads as a tidy no-op rather than a job that died.
Run 2520 died exactly this way with nothing tested.

**A path-filtered skip and a real pass are identical at run level.** Run 2518 on
`ralph/GATE-F-DEFECT-FIX` concluded `success` with all 28 jobs `skipped` — the
changes filter read it as documentation-only. Always check that the `changes`
job's "Decide whether anything but documentation changed" step actually RAN and
printed `code=true`, then check the individual jobs. A run conclusion alone is
never evidence.

**`verify-continuous-core-known-red` is `continue-on-error: true`.** It fails
routinely and does not block. Do not chase it.

Also, not a CI lie but the same shape: **`git diff A...B` (three dots) compares
against the merge base, not against B's current content.** It told me the arena
containment fix was missing from `LAND-ALL` when it is present on both `main` and
the branch. Use two dots (`git diff A B`) for content comparison.

---

## 3. Why run 2523 is stuck, and why 2520 died

**2523 — GitHub Actions major outage.** Began 15:11:58Z, impact critical, latest
update 15:23:10Z: "We've identified an issue with a database primary and are
failing over to a replica immediately." 2523 was created 15:23:59Z, squarely
inside it, and has zero job records. Note the tell: a run merely waiting on busy
runners still gets job records in `queued` state. `total_count: 0` means GitHub
never scheduled it. Nothing else in the repo was running or queued.

For contrast, Gate F's run 2522 started 14:58:40Z — before the outage — and
finished green at 15:23:18Z. That is the entire difference between the two runs.

**2520 — a timeout kill I caused.** The `changes` job had `timeout-minutes: 5`
and its `actions/checkout@v4` uses `fetch-depth: 0`. That checkout took 45
seconds on run 2515 and blew past five minutes on 2520.

The cause is the consolidation itself: `LAND-ALL` merges five lanes that each
carry their own full bake of roughly 300 scatter binaries, so a full-depth fetch
pulls every version of every one of them — about eleven thousand large blobs, to
produce a list of filenames.

Fixed on `7d194883` with `filter: blob:none`. That job runs `git diff
--name-only` and `git merge-base`; both want commits and trees and neither ever
reads file contents, so a blobless fetch keeps the full-depth diff the filter
needs while leaving the bakes on the server. The timeout went 5 to 15 as a safety
net only — raising a ceiling to fit a job that got slower just moves the cliff.

**Consolidating lanes is still right** and is why one run can land all of this.
But it multiplies exactly this cost, so keep the filter in mind as more lanes
land.

---

## 4. What is on `ralph/LAND-ALL`, and what was verified

`9b5c2fa8` carries the grass consolidation (762,058-placement reconciled rebake,
`"groundmat"` added to `suppress_scatter_layers`), both defect fixes below,
`ralph/CI-SPEEDUP`'s core-verb matrix, `ralph/GATE-F-DEFECT-FIX`, and
`ralph/GATE-F-RUN-20260826`. `7d194883` adds the blobless checkout.

**`data/config/grass_field.json` `enabled` stays `false`.** Turning it on is an
owner decision against an ROG Ally, not a lane's against a container.

**Do not revert the path narrowing.** `terrain_playground.json` `paths.width`
2.0 to 1.4 and `shoulder` 2.5 to 1.1 are owner-authorised.

Both defects were verified locally before pushing — `smoke_traversal` reports
`traversal: OK`, exit 0, all eight Sigil probes sealing and no wedge.

### The Sigil Gate seal

`road_gate.gd::_build_wings` sized each wing's collider from the ground under
that wing's own centre. The +1 side of the causeway falls -1.09m to -3.71m over
ten metres, so consecutive wings step down almost a metre each. At the +6.10m
seam that left wing 1's top standing **0.84m** above local terrain and wing 0's
bottom floating 0.32m above it. The player walked over it. The -1 side passed
throughout only because its terrain is nearly flat there (-0.43m to -1.39m over
the same span) — that is the whole of the asymmetry that made it look mysterious.

`smoke_traversal.gd`'s span check is blind to Y: it projects colliders onto the
across-axis, so the barrier read as a contiguous -18.29m..18.29m the entire time
it was being walked past. "The barrier is wider than the causeway, so nothing is
missing" was true and useless.

Now sized from each wing's whole footprint. Measured: +6.0m north-to-south went
from +4.5m past the locked gate to -0.5m.

Two dead ends, recorded so they are not retried. **Burying the box downward does
not work** — a fixed-size box pushed down lowers its top by exactly as much as
its bottom, which makes the walk-over easier; measured at +4.6m to +4.5m, no
effect. And **the leak was never on `main`**: run 2519, which is `ci.yml` only,
seals at all eight probes. It was a regression from the grass bake, which is why
handing it to the Gate F lane as a gate defect was wrong.

`tools/_probe_sigil_wings.gd` prints the geometry if it regresses.

### The stuck-check false positive

`smoke_traversal.gd` flagged a wedge at (53, -65). A physics query names the
blocker: `Vegetation/Rock_Medium_1_Collision` occupying (52..54, -63..-64). The
terrain there runs -0.83m to +1.05m over eight metres — about 14 degrees, well
inside the existing slope exclusion — and every direction but backward is open
meadow. The player walked into a rock.

The constants' stated assumption is that "only a snag causes a dead stop, a
glancing brush off a rock will not trip it." That is false for a walk that holds
ONE direction for 1700 frames: the first solid object it meets stops it for the
rest of the leg. Whether it fired depended on how the runner's physics timing
steered the walk, which is why identical trees passed and failed for days.

OF15's original wedge was itself a prop collider, so this cannot excuse every
prop. What separates a snag from scenery is whether the player can leave, so that
is what is now asked: eight compass probes with the player's own collider.

Two things the first attempt got wrong, both fixed: reusing the player's absolute
y reads every upslope direction as blocked (the capsule sinks into rising
ground), and placing the bare shape ignores the collider's offset from the body
origin, burying half of it. `tools/_probe_wedge_site.gd` names blockers by
physics query rather than by node position — a first pass compared each
collider's `global_position` to the spot and found nothing within six metres,
which proves only that no collider's ORIGIN is nearby.

---

## 5. The Gate F lane

Session `session_01HZgCaFHAPjWzFkUJadAmgZ`, being rotated at the same time as
this one. Reach it with `create_trigger` + `fire_trigger`; it cannot reply, and
writes its check-ins to `ralph/reports/gate-f-lane-log.md`.

**Their open item is the last known real defect:** `smoke_party_count_after_catches`
fails intermittently with "stopped 23.7m away (engage range 6.0m)". Their
check-in 9 established it is **not** a routing problem — all three
practice-cluster targets are reachable from the test's own start point (arrived
frames 102, 299, 228). The catch-3 walk begins wherever catch 2's fight left the
body. Same family as the `smoke_arena_contain` race already on `main`.

Their `07452b65` killed four hypotheses with measurements (an unconvergeable
chase; the entombment class; a bad route; the stand-aside teleport parking the
body in rock) and made the failure self-diagnosing instead of guessing again — it
now reports distance walked, frames, eight-direction clearance and
`on_wall`/`on_floor`. It does not reproduce locally. `stick_navigator` is
deliberately withheld because it would green the test and hide the cause.

**When `main` is complete, tell them:** merge `main` forward into
`ralph/CATCH3-ENGAGE` (merge, never rebase), re-freeze a candidate from the new
`main`, then run **S01–S10 followed by X01–X07 in one chain. X08 is dropped** by
owner decision. The visual judge is unblocked at that point and not before.

`ralph/reports/gate-f-candidate/RUN_METADATA.json` on the landing branch is the
2026-08-26 freeze at `14e88c7c`. It is **void** — it is only there because
`ABORTED.md` beside it explains why that run stopped. Gate F overwrites it when
it re-freezes. Do not read it as a live candidate.

---

## 6. CI duration — measured, with the remaining ceiling

A green run should be roughly 20–25 minutes. Run 2519's 33.6 minutes was almost
entirely one job burning 27.5 minutes on three failing traversal retries.

Landed already: `verify-core-verb-shard` ran five smokes serially for 22.2
minutes and was the last job to finish; splitting it into a parallel matrix makes
its cost the longest single smoke (~9 min) instead of the sum.

**Do this next, in this order, on its own branch after `LAND-ALL` lands.** Not
before — another `ci.yml` push restarts the landing's CI.

1. **The import, biggest win, ~4 minutes off every job.** Every job spends ~5
   minutes in `setup-godot` before running a test. Inside it: the cache reports
   `Cache hit occurred on the primary key import-4.7-stable-cccac75e…`, then
   "Import project (cold)" takes 3m40s, then an identical "Import project
   (verify)" takes 2s. `LAND-ALL` changes zero `.import` files and zero
   `project.godot`, so the key hits exactly and this should be a no-op.
   **Hypothesis, not proven:** `actions/checkout` stamps fresh mtimes on all 728
   imported assets, Godot judges them stale, re-imports, writes new timestamps,
   and the second pass is clean. Test that before changing anything.
2. **Split `verify-gate-evidence-shard`** — six smokes serially, same shape as
   the pole already fixed. Engine-boot timings from run 2515: roughly 0.1, 2.7,
   2.4, 0.1, 1.5, 1.8, 3.0, 4.3 minutes (eight boots including the opening
   segment's retry), totalling 15.9 against a 15.8-minute step. Splitting takes
   it to ~4.5 minutes.
3. **Split `verify-owner-regressions-shard`** (~13 minutes) the same way.

**Then you hit the floor at ~12 minutes**, and it is one file:
`test_scatter_rules.gd`, about 11 minutes in a single process. No job split
touches it. Its runtime tracks vegetation density, so any further density
increase needs re-timing. Going below 10 minutes means changing that test, which
is an owner decision, not a plumbing one — do not quietly rewrite it.

Retracted, do not repeat: **collapsing the unit shards is not a speedup.** The
full suite minus `test_veg_corridor.gd` and `test_scatter_rules.gd` is 535s /
1395 tests / 977,745 assertions. One job would be worse. The shards are fine.
Also do not chase `test_auto_run.gd` — measured at 1 second.

---

## 7. Standing constraints

- **Never push `main`.** Ship via `ralph/<task>` branches and a dispatched sweep.
  **No pull requests.**
- The download site tracks `main`. **Never dispatch `release.yml` against a
  `ralph/**` ref.**
- `ship_branch.sh` skips anything more than **20 commits behind** `main`
  (`MAX_BEHIND`, not a dispatch input). Merge `main` forward before it matters —
  merge, never rebase, so nobody's checkout breaks.
- [OWNER-ONLY], never claimed from this Linux container: device frame rate, GPU,
  VRAM, thermals, controller feel, audio, Windows-export identity.
- Anything worth keeping must be committed and pushed. The container is
  ephemeral.
- **Never end a turn without an armed check-in** while work is outstanding.
  Failing to re-arm once already cost seven hours. Note that a `send_later` fires
  into the session that created it — after a rotation the successor must arm its
  own, and nothing watches the landing in the gap.

## 8. Practical notes about this environment

- Godot 4.7-stable is at
  `/tmp/claude-0/-home-user-Tetherbound/1a66f7f6-4da7-56ce-919a-b92644101621/scratchpad/godot/godot`
  with the project already imported. `smoke_traversal` takes about 10 minutes.
- **`git worktree add` is too slow here** — it times out on this repo's baked
  assets. Consolidate with `git merge-tree --write-tree` and `git commit-tree`
  instead: pure object-database work, no checkout, and it does not disturb a
  running test. Resolve a conflicted file by writing the resolution with
  `hash-object`, then `read-tree` / `update-index` / `write-tree` against a
  temporary `GIT_INDEX_FILE`.
- Do not check out branches while a Godot test is running; Terrain3D streams from
  disk mid-run and it will invalidate the measurement.
- Generated lane state (`RUN_METADATA.json`, bakes) must not be blind-merged.
  Decide which side reflects reality and say so in the merge message.
