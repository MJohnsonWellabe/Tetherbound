# Coordinator handover — 2026-09-02, evening

Written by the outgoing backlog/Gate-F coordinator at the owner's request.
This supersedes `ralph/COORDINATOR_HANDOVER_2026-09-02.md` (the morning
coordinator's) for anything the two disagree on — most importantly its
"player sleep is a confirmed live bug" claim, which turned out to be built
on a build the owner could not have played. See §4.

A separate **visual coordinator** ran in parallel all session and owns the
`claude/vp-*` branches and `grass_field.gd`. Nothing in this handover
covers that program; do not merge or revert VP-owned files without going
through it.

Read `CLAUDE.md` and `ralph/START_HERE.md` first, as always. This file is
one session's snapshot, not a replacement for either.

---

## 0. The single most important thing: this repo's CI can lie to you

Three separate mechanisms produced a green badge over a red or unverified
tree **today**. All three cost real time. Do not trust a conclusion without
checking against all three.

**Trap 1 — a docs-only commit repaints the badge.** A red commit followed by
a docs commit shows the branch as green while the red still stands. Check
the run on the *code* commit, not the branch tip.

**Trap 2 — `[skip ci]` plus the `changes` job.** `ci.yml`'s `changes` job
diffs against `github.event.before`, i.e. **the previous push on that
branch**, not against main. So a branch that pushes code, then pushes
`ralph/` evidence, gets every verify job SKIPPED on that second push and the
run concludes `success` in about 75 seconds — with the code never executed.
This bit three branches today. `ralph-merge.yml` lands branches whose "CI
went green", so this is a live hole in the ship process, not just a
reporting annoyance.

> **Rule: a CI run under ~5 minutes is not a verification.** A real full run
> here is 35–45 minutes. Check the *duration* before you believe a success.

**Trap 3 — `RETRIES: 3` masks a consistent failure.** A deterministic
first-attempt failure passed on retry across four separate runs, including
main's own parent and a PR's "green" run. When you see a long verify step,
divide: a ~21-minute traversal step is three ~7-minute attempts, not one.

**And one of my own mistakes worth inheriting:** `get_job_logs` with
`failed_only: true` on a run that is still *in progress* returns zero failed
jobs. That is not a verdict. I nearly landed on it. Only run it against a
`completed` run.

The verification I settled on, and recommend: the run is `completed`, AND
`failed_only` returns 0, AND the run duration is over five minutes, AND for
a specific concern the individual step's duration looks like one attempt.

---

## 1. What landed on main this session

In order:

| Commit | What |
|---|---|
| `e97baa30` | Re-bake the playground scatter; add `verify-scatter-bake-freshness` as its own named CI job |
| `c98998fa` | Rest progress indicator, plus proof a rest actually completes end to end |
| `8bf4f0bd` | Interact reliability: real-input evidence (0 misses / 162 attempts, and 0/277 on re-runs). **Explicitly not a fix** |
| `0f1b2661` | Train clarity, verified on real handheld-resolution frames |
| `107c9644` | Traversal breadcrumb/teleport race — **incomplete, see §3** |
| `8b0e72d3` | Player sleep: does not reproduce; the evidence harness was what was broken (§4) |

Plus `87b306ac` and `019cfa98`, two backlog records.

The scatter re-bake matters beyond its own lane: the bake goes stale
**silently** when `vegetation.json` or `grass_field.json` change, and a stale
bake was the real cause of a load-time bug the owner hit. The new CI job
exists so that can never again be discovered by accident.

## 2. In flight at handover — finish these first

Three branches were not yet on main when this was written. They are a chain,
not three independent items.

- **`ralph/CONSOLIDATE-0902-EVENING` @ `e5c86cff`** — contains BOTH the
  traversal fix (`ralph/TRAVERSAL-BRIDGE-TELEPORT-GUARD` @ `412a474b`) and
  the entire grass lane (`ralph/OWNER-0901-CREATURE-GRASS-VISIBILITY-V2` @
  `671b8e85`). Merged cleanly. Consolidated deliberately: grass only ever
  failed on the traversal bug, so one CI cycle verifies both. The guard also
  has its own solo run — if the consolidation fails but the solo passes, the
  grass half is at fault.
- **`ralph/GATE-F-S03-CATCH-LOOP` @ `f20a504d`** — see §5.

Verify each per §0, then merge to main. If the consolidation is red, do not
revert the grass lane reflexively: read the failure first, and check whether
the same failure reproduces on an unmodified tree (`git stash` is how three
VP lanes established exactly that for the South Bridge red).

## 3. The traversal red, both halves — one fixed, one OPEN and more serious

`smoke_traversal`'s locked South Bridge check fails, byte-identical, 3/3
attempts, on any branch whose world perturbs the breadcrumb trail even
slightly:

```
[player] entombed at 7.90, -3.42, 1319.00 -- recovering to 504.95, 8.24, 7678.40
the South Bridge, locked:   reached +6348.4m past the gap
the South Bridge, unlocked: reached +22.9m past the gap
traversal FAIL: crossed the South Bridge without the key (6348.4m past the gap)
```

**Half one — the harness (FIXED, `412a474b`).** My earlier fix `107c9644`
diagnosed this correctly and then fixed the half that cannot work. It made
the harness settle properly and plant a real breadcrumb before the walk —
but `player_controller.gd::_recovery_position()` skips any breadcrumb closer
than `min_recovery_distance_m` (6.0m, `movement.json`), and an entombed body
never moves horizontally, so the breadcrumb the harness just planted sits at
the entombment site and is **always** discarded. Recovery falls back to the
perimeter cap-walk 6.3km away, and `depth_past_crossing` scores that
teleport as a stroll past a locked gate. The real fix is the guard
`_check_sigil_gate()` already had and `_walk_at_the_bridge()` did not: a step
larger than `STEP_SANITY_M` in one physics frame is a teleport, not a
stride, so stop and keep what was earned on foot. **The 6.0m rule was
deliberately left alone** — it is production behaviour protecting real
players from being rewound into the hole they just fell in.

**Half two — the world (OPEN, and nobody has looked at it).** The player
capsule genuinely IS entombed when placed 11m back from the South Bridge at
(7.9, −3.4, 1319): all eight compass probes sealed,
`_clamp_runaway_velocity` firing hundreds of times on 121 m/s
depenetration, reproducible to the centimetre. `RETRIES: 3` plus the
recovery failsafe hid this for weeks. **The guard stops it being
misreported as a gate breach; it does not make that ground sound.** A player
who walks into that gully has a real hole to fall in. The same
`(x, -3.0, 1319.0)` pin recurs across the Gate F S05–S10 notes ("stopped
12.4m short at (3.0, -3.0, 1319.0)"), so it is plausibly already costing
Gate F runs. **This needs its own world/collision session and is the single
highest-value unclaimed item in this handover.**

## 4. "Player sleep is still broken" was stale-build evidence

The morning handover recorded sleep as an owner-confirmed live bug. It is
not, and the correction matters as a method, not just a fact.

Both sleep paths — Grandpa's bed and the post-camp-split Bedroll — complete
under real interact-driven headless runs: real prompt text, real day
advance, real save. What settled it was the timeline, pulled from GitHub's
actual **release-asset build times** rather than merge timestamps: the
confirmation-pass write-up was pushed at 10:29:48 UTC, seven minutes
**before** `OWNER-0902-CAMP-SPLIT`'s release build finished at 10:36:55, and
no release ran between 05:47:38 and 10:36:55. The Bedroll did not exist as a
placeable piece in any build the owner could have played.

**Method to inherit:** when an owner reproduction conflicts with a passing
test, check *which build they actually played* before assuming the test
lies. `ralph/conventions.md` already warns that a Ralph merge does not
reliably trigger `release.yml`.

Chasing that proof also surfaced a **family of harness bugs worth hunting**:
six instances of *fixed-slot-offset lookups* — code asserting an item is in
a specific inventory or hotbar slot, which goes stale the moment an assign
order changes. Revive's `focus_item`, knife `hotbar_5`→`hotbar_4`, berries,
a gather-node wrong-tool, plus a visit-order bug where Mira's gifts were
asserted after visiting only Tam. That last one had kept
`smoke_gate_b_continuous.gd` — the one test meant to prove wake → catch →
tools → gather → build → sleep as a single fresh-save run — from ever
reaching its build/sleep segment. Grep for hardcoded slot numbers in
`tests/` and `tools/`; there are likely more.

## 5. Gate F

Lane session `session_01A3C1e6jqo5ifUa3nC6G1tL`, branch
`ralph/GATE-F-S03-CATCH-LOOP`. S03 went from 42 FAILs to 6, all six outside
that lane's scope. The lane is idle and review-ready.

Its "green" was Trap 2 — a 73-second all-skipped run. Forcing a real run
(by merging main forward) immediately caught a genuine failure the fake
green had hidden:

```
test_gate_f_instrumentation.gd :: test_every_implemented_action_is_documented
operator_harness.gd implements action 'force_aim' and SEGMENT_SCHEMA.md never mentions it
```

Fixed in `f20a504d` by documenting the step. **Note what `force_aim` is
before using it in a segment:** it is a harness shortcut that assigns
`camera_rig`'s `yaw`/`pitch` directly, bypassing the analog turn-rate limit.
It shortcuts the *steering* only — the catch roll, orb physics and
everything downstream are untouched — but `track_aim` remains the honest
player-input simulation and must be preferred in any segment whose subject
is aim itself. It was added because a real aim-tracking defect (creatures
not slowing on entering catch mode) was landing in a separate lane and was
adding flakiness on top of what S03 was actually verifying. **If that aim
fix has since landed, consider moving S03 back to `track_aim`.**

Do not start S04 until S03 is clean on current main.

## 6. Grass density — decided, with one open design question

The owner noticed grass had become far less dense and asked who changed it
and why. Current shipped values in `data/config/grass_field.json`:
`tuft_count: 75000`, `blades_per_tuft: 4`, `blade_segments: 3` — cut from an
original 300000/6/4, with stones 90000→25000 and litter 49000→15000.

**Decision: keep 75k.** Two visual judges, one of them blind to which frame
was which, agreed. I initially read the frames backwards and said 75k looked
denser than 150k; the blind judge measured the opposite and pixel-diff
confirmed it. Density is not the defect.

**The real gap is blade SHAPE**, and it is unresolved: isolated thin spikes
on a blurry ground read as "hair on a lawn", where
`docs/reference/moong-01-mounted-in-tall-grass.jpg` shows overlapping blades
with mass. Recommended change, **not owner-approved, do not ship
unilaterally**: a clump card (3–5 blades per instance, wider base,
root-to-tip gradient, ±30% height variation) at the current instance count.
`grass_field.gd` is VP-owned since PR #20 — route this through the visual
coordinator.

## 7. Still open

**Only the owner's ROG Ally hardware can close these two.** No container can
measure real ROG GPU frame time (`PERF-ROG-GPU`), and the interact
game-breaker never reproduced under 439 scripted attempts:

- the interact game-breaker, and
- the ~10 FPS lag (its earlier retest was invalid — run with grass off).

Do not spawn another session to "fix" either without new owner evidence;
that is how "believed fixed" labels get manufactured.

**Open and workable:**

- **The South Bridge entombment (§3, half two).** Highest value here.
- **Bram-exit navigation defect** — `_exit_through()` walks a straight line
  from wherever the movement probe left the player and clips shop furniture.
  Reproduced twice, 6.5m short both times; one attempted fix insufficient.
  Bram is commerce-only, unrelated to sleep. Needs its own session.
- **MAIN STORY objective label truncates at 1280x800** — "Train with your
  team before the …". The hint card carrying the full "how" is timed (~10s,
  once per rung change), so a player who misses it sees a cut sentence until
  they open the quest log. Small and real.
- **Two questions put to the owner and not yet answered** (asked once — do
  not re-ask unprompted): whether the clump-card blade redesign proceeds,
  and whether he ever tried Grandpa's loft bed.

## 8. Process notes

**Lane supervision.** Cloud sessions are **not** reachable via
`SendMessage`. To poke one: `create_trigger` with `persistent_session_id`
and no schedule → `fire_trigger` → `delete_trigger`.

**Watch `status_bucket`, not branch commits.** A lane that stops to ask a
question does not push, so a coordinator watching branch heads sees nothing
wrong. I lost 1h37m to a lane sitting BLOCKED because of exactly that. Check
`get_session`'s `status_bucket` / `post_turn_summary.needs_action` on every
check-in, and **re-arm the next check-in every single time** — the gap that
cost that 1h37m was a check-in I forgot to re-arm.

**Do not trust a lane's self-report.** Verify the branch and the CI, not the
summary line. Several lanes this session reported "review ready" against a
fake-green run.

**Practical.** Plain `git fetch` hangs here past two minutes — always
`timeout 100 git fetch origin --prune`. `mcp__github__actions_list` output
routinely exceeds the token limit; parse the saved file with python instead.
