# G3-HARNESS-0904

Lane: `tests/helpers/**`, `tools/gate_f/**` (segments, harness, probes). Branch
`ralph/G3-HARNESS-0904` off `ralph/G3-LAND-0904` (SHA `44f06cf9`), landed by the
Gate 3 coordinator; no PR opened per brief.

## 0. What this covers

The brief named three items; the coordinator added a fourth mid-session
(notification at 2026-09-04T01:20:07Z, after item 1 was already fixed):

1. The walker cannot leave the Pond basin (2.9) — **fixed and verified**.
2. S08 has no post-faint switch or revive (Band 4's blocker) — **fixed**;
   live end-to-end verification blocked by a new, separate, unresolved
   finding (§4).
3. Stale trace-length thresholds (2.14) — **re-derived from real runs**,
   twice, because the first derivation used a bad seed (§5).
4. Re-run S04/S05 on the merged tree, fix what survives — **done**: S04 is
   clean; S05 had one real, unfixed instance of the pre-2.8 blind-press
   pattern, now fixed, plus a new open finding (§3.4).

Every number below comes from a real headless run at this SHA (or the SHA
plus this session's own commits), not from re-reading an old report. Run
directories live under this session's scratch space, not `ralph/reports/`
(rows and verdicts are recorded here; the raw payload is not carried into the
tree per "commit verdicts, not payloads").

## 1. The walker cannot leave the Pond basin (2.9) — FIXED

### Root cause

`tests/helpers/stick_navigator.gd`'s `step()` measured progress **only** as
straight-line closing distance on the target. When a detour ended — its
frame budget spent, or aborted by `_drops_away`/`_detour_stalled` — control
fell straight back into that distance check. On a target hundreds of metres
away (the Old Bram detour, (195, 905), from deep in the Pond basin), a whole
detour's worth of honest sideways travel around the basin's shoulder barely
moves that number. So the gap check read it as a fresh stall, waited out
`STALL_FRAMES` pushing straight back into the same slope, and re-detoured —
on the documented case, this cycled without ever committing enough lateral
distance to crest the shoulder, for the length of the walk's budget.

`docs/CURRENT_STATE.md` §3 records the same root shape at a different site
(the settlement fence's concave corner past TrailGate: "79 side-flips in
133s") — a corner needs the same thing a basin shoulder needs: sustained
lateral travel that a far-target distance metric cannot see as progress.

### The fix

In `step()`, once a detour ends, if `_side` is still committed **and** the
straight line to the target is still blocked (`_free_space(to.normalized())
< BODY_WIDTH`), immediately continue following the obstacle — call
`_begin_detour` again — instead of falling through to the distance-based
stall check. Only once the straight line is genuinely open does control fall
back to normal walking, and at that point `_side`/`_side_detours` reset so a
later, unrelated stall doesn't inherit a side-count run up against a
different obstacle. `_begin_detour`'s own `DETOURS_PER_SIDE` flip and the
wedge/back-off cases are untouched — this does not weaken either.

No teleport, no waypoint. `S05-32x` (the workaround waypoint through the
basin's north-east shoulder) is retired, not merely left in place.

### Verification

- **`probe_pond_stranding.gd`, re-run unchanged**: 0 of 10 stands wedged,
  12–17 m of travel in five-plus of eight bearings, still on the authored
  heightfield. The world is exactly as passable as GATE2-EVIDENCE-0903 found
  it — nothing about this fix touches the world.
- **`probe_pond_walker_fix.gd`** (new): stands the real player body at the
  exact documented stall coordinate, `(-328.7, -14.2, 505.3)`, and drives
  `stick_navigator.walk_to()` at the Old Bram bearing under the **same
  29,250-frame budget** the original failing run used. Result:
  **arrived in 10,385 frames (173.1 play-seconds)**, unassisted — against the
  original 543 s-and-counting freeze (the first documented run burned its
  full budget and never arrived at all).
- **Segment-level, with `S05-32x` removed for real**: a fresh S05 run (proper
  seed, see §5) reached **past** the old stranding point, through the Pond,
  and (before hitting the separate, new finding in §3.4) travelled well into
  the corridor toward Old Bram — the basin is no longer a dead end.

### What this does NOT claim to have fixed

The fence-corner oscillation `docs/CURRENT_STATE.md` §3 records (TrailGate,
the gather-route fiber at (-5.0, 141.0)) is the same root shape and should
benefit from the same change, but this session did not independently
re-verify it at that specific site — `ralph/FENCE-CORNER-0903`, which the
brief said addressed one instance of it, does not exist as a pushed branch
(checked: `git ls-remote origin` has no such ref), so there was nothing to
read or reconcile against. Flagged rather than assumed fixed.

## 2. S08's post-faint switch/revive (Band 4's blocker) — FIXED, verification incomplete

### The fix

Two additions to `tools/gate_f/segments/S08.json`, both direct reuse of
already-proven patterns:

- **`S08-45r*`** (after the wild Meadowhart fight, where Band 4's own
  addendum found the lead creature — Tup, L13 Terrapup — faints: 27 hits,
  206.4 → 0.0 HP): a revive-and-recall block, byte-for-byte the same
  open-Satchel / focus-Revive / Use / confirm / put-back-or-close /
  close-for-real / wait-for-world sequence `S05-11r*` already uses (itself
  production-menu-driven, proven in this session's own S05 runs — see §5).
  Confirmed safe to run even when nobody is fainted:
  `tab_backpack.gd::_open_target_picker` refuses to open when
  `_any_eligible_target` is false (nobody eligible), so `interact` is a
  no-op and the block's own "put back an accidental pick-up" press absorbs
  it — the same shape `S05-11r*` already relies on. Followed by one
  `creature_recall` press, because Gate 2 evidence item 4.5 already found a
  revived creature is not re-deployed on its own.
- **`active_creature_alive`**: a new assert check (`operator_harness.gd`,
  documented in `SEGMENT_SCHEMA.md`), backed by a new probe method
  `gate_f_probe.gd::active_creature_hp()`. Placed immediately before each of
  the three captain challenges (`S08-77a`, `S08-88a`, `S08-106a`). This is a
  **pre-flight gate**, not a revive: it fails the segment *at the moment*
  the party stops being fight-ready, instead of letting
  `encounter_director.gd::can_challenge()`'s silent refusal — or worse, a
  scripted press landing on whatever menu happens to be focused instead —
  burn the rest of the segment's budget on evidence that was never going to
  mean anything. This is a strengthening, not a weakening: nothing before
  this session asserted party health before a fight at all.

### Verification: real but incomplete

Ran S08 twice, from a freshly-built synthetic entry seed
(`build_s08_entry_synthetic.gd`, unmodified, matching Band 4's own
methodology — five creatures, L13 lead). **Both runs deterministically froze
on the very first long walk** (crossing → Ironwood Grove, `S08-22`), well
before reaching the Meadowhart fight my revive block targets. See §4 — this
is a new, separate, unresolved finding, not a consequence of anything in
this section.

So the switch/revive fix was **not independently confirmed end-to-end in a
live S08 run this session**. What backs it instead:

- It is the identical UI sequence as `S05-11r*`, which this session's own
  S04→S05 chain (§5) exercised for real, successfully, through the
  production Satchel menu, on the current merged tree.
- `active_creature_alive` was code-reviewed against the existing
  `party_state()`/`active_creature()` probe methods it's built from, which
  are already live and tested elsewhere in this file.

Stated plainly per the brief's own rule: this is real, reasoned confidence,
not a live-run PASS. The blocker in §4 needs to clear before S08 can produce
that PASS.

## 3. Re-running S04/S05 on the merged tree (the coordinator's addendum)

### 3.1 The first attempt was invalid — a seed artifact, not a finding

The first S04 run used a raw `S03-exit.json` copied from an existing
evidence-run directory (`gate-f-run-20260902T200321Z-s03fablefix11`). It
produced 21 cascading step failures starting at `S04-11` ("tracked objective
... wanted `tournament_enter`", got `tournament_training_ready` instead) —
every tournament round, sign-up, and the trace-count assert failed downstream
of that one mismatch.

This is **not** a real S04 defect. `GATE2-EVIDENCE-0903`'s own
`RUN_METADATA.json` names the actual methodology: a **built** seed via
`tools/gate_f/build_gate2_seed.gd`, which takes that same raw played S03 exit
and applies the CI allowance `smoke_gate_b_continuous.gd` already uses —
levels the party to the tournament's entry floor, sets the
sleep/bed/feed rung flags — because a raw S03 exit legitimately sits below
the tournament's own entry bar. A raw copy is not a valid S04 entry state at
all; this was learned the hard way, cost one full run, and is recorded here
so the next lane does not repeat it.

### 3.2 S04, properly seeded — clean

Rebuilt the seed with `build_gate2_seed.gd` (unmodified, its own documented
default source). Ran S04:

**Zero defects. Every step, including the re-derived trace-count assert,
passed.** 651 route rows over a 329.7 s segment. 2.8's rewrite (the
`advance_dialogue_until_closed`/`move_to_entity`/`interact_with`/
`fight_until_resolved` replacements the coordinator described) works
correctly against the current merged tree.

### 3.3 S05, chained from that clean S04 exit — one real defect found and fixed

First pass (before the fix below) reported 8 defects. Tracing them: **one
root cause**, not eight — `S05-35` ("hear him out", Old Bram's dialogue)
still used a fixed `press interact times: 10`, the exact blind-press-count
class `CD-3`/`GATE2-EVIDENCE-0903` already fixed **nine times** in `S04.json`
via `advance_dialogue_until_closed` but had **not yet been fixed in
`S05.json`**. Measured live: Old Bram's own greeting outlasts 10 presses, so
the modal was still open when the next walk started
(`S05-35w`'s own diagnostic caught it: `input_context=narrative_modal`), and
it never closed again — the South Bridge fight itself then couldn't start
(`S05-48`/`S05-48f`: `combat_running=false`, still `narrative_modal`), the
bridge never opened, the crossing move_to fell 9.4 m short, and the
trace-count assert failed low because the segment stopped early. Six
reported defects, one cause.

**Fixed**: `S05-35` now uses `advance_dialogue_until_closed` (`max_presses:
20`), matching the established pattern exactly. This is squarely
`tools/gate_f/segments/**`, inside this lane's ownership, and is exactly what
the coordinator's addendum asked for — "fix only what survives the rewrite."

One further defect, **not a bug**: `S05-11rx` ("three Revives were actually
spent") fails against `build_gate2_seed.gd`'s output because that seed sets
the party to full health directly rather than simulating tournament combat
damage — nobody is fainted, so the revive block correctly finds nothing to
revive, and the assert (written for a real played tournament that leaves
three creatures down) has nothing to confirm. This is a seed-methodology
limitation, not a defect in `S05.json`; the original `GATE2-EVIDENCE-0903`
run (real fainted creatures) exercised this block correctly and is still the
right reference for it. Not touched.

### 3.4 A new, real, unresolved finding on the Old Bram detour leg

After the `S05-35` fix, re-ran S05 end to end. It now gets **past** the Pond
(§1's fix holding) and past Old Bram's dialogue (§3.3's fix holding), but
**`S05-33`** (the walk from the Pond to Old Bram itself, target `(195, 905)`)
now stops **171.7 m short**, wedged at `(53.0, -3.0, 808.0)`, having spent
its full 29,250-frame budget — the same "0 held, full budget, no arrival"
signature as the original Pond stall.

Checked and ruled out this session: **not** a CarveFailsafe recovery volume
(`probe_carve_failsafe_at.gd --at=53,-3,808`: not inside any of the 25
volumes in the scene, none within 60 m). Not investigated further given the
time already spent on this lane's three explicit items plus the
coordinator's fourth. This is a **new, real, open finding** — reported, not
hidden, not "fixed" by weakening the trace-count threshold to route around
it (see §5's reasoning for why 1200 was chosen specifically to stay honest
about this).

## 4. New finding: S08's Ironwood-approach leg freezes, deterministically — NOT this session's fix, NOT a CarveFailsafe volume, root cause OPEN

**`S08-22`** (crossing → Ironwood Grove, target `(-345, 5060)`) froze solid
for its **entire 45,000-frame budget** at **`(-164.12, -9.13, 4334.56)`** —
confirmed on **two independent full S08 runs from the identical synthetic
seed**, coordinate identical to the centimetre both times (`t=933.8` and
`t=933.75`). `route.csv` shows the position pinned exactly, `input_context`
staying `world` the whole time — the walker is actively pushing every frame
and nothing is moving it, and nothing is holding input either.

This blocked both S08 attempts before they ever reached the Meadowhart fight
§2's switch/revive fix targets, and (in the second run) the segment also hit
the same `input_context=build_catalogue` misresolution Band 4's original
report found at Oreth — this time first appearing after Captain Riverwatch
(`t=1653`), persisting for the rest of the run.

**What this session ruled out**, so the next investigation doesn't repeat
the work:

- **Not the 2.9 fix.** `probe_ironwood_approach.gd` drives the identical
  `stick_navigator.gd` call — same start (`(-152, -2.15, 4238)`, matching
  `build_s08_entry_synthetic.gd`'s own settled position), same target, a
  comparable budget — in isolation, with no other segment state. It
  **arrives cleanly, in 10,792 of 12,000 frames.** The walker's own logic is
  not what's failing here.
- **Not a CarveFailsafe volume.** `probe_carve_failsafe_at.gd
  --at=-164.12,-9.13,4334.56`: not inside any of 25 volumes, none within
  60 m. (`tools/_probe_river_gate.gd` had already documented a *different*
  river-volume overlap near this crossing, at `x=-150, z=4198-4208` — 130 m
  short of the actual freeze point in `z`. Checked and it is not the same
  site.)
- **Inconclusive**: a cold-teleport probe standing the body directly at the
  freeze coordinate (no preceding travel) found no ground within 8 m below
  and nothing within 6 m in any direction — but a body that *walked* through
  the same area (the isolated probe above) passed it without incident,
  which is consistent with this being a Terrain3D streaming artifact of
  instant placement into a never-visited chunk rather than a real hole. Not
  treated as evidence either way.

**What's still open**: this is deterministic and real, blocks S08 entirely,
and its mechanism is unidentified. `operator_harness.gd::_step_move_to`'s
own wrapper around `stick_navigator.gd` was read in full and is not doing
anything the isolated probe doesn't also do (its extra `_tick()` call is
pure telemetry bookkeeping, confirmed by reading it — no world-simulation
side effect). The most likely remaining candidates are (a) something with
real collision — a wandering trainer or wild creature — positioned
differently by the time a full segment run reaches this point than in a
probe that starts walking almost immediately, or (b) a genuine terrain gap
that only a rendered/visual inspection would confirm. Neither was reachable
in headless logic mode within this session's remaining budget. Handed back
per the brief's own rule: a world-shaped defect is reported with its
measurements, not silently patched around by the walker.

Both new probes (`probe_ironwood_approach.gd`,
`probe_carve_failsafe_at.gd`) are committed so the next pass starts from
these measurements instead of re-deriving them.

## 5. Stale trace-length thresholds (2.14) — re-derived twice, from real runs

The first derivation (from the stale-seed S04 run and an S05 run before the
`S05-35` fix) produced `S04-61: 480` and `S05-60: 1600`. Both were revisited
once the properly-seeded runs (§3) produced more, and more representative,
real numbers:

- **`S04-61`**: `1200 → 480`. The clean, properly-seeded run (§3.2) wrote
  520 rows at this assert's own checkpoint in a 329.7 s segment (2 Hz would
  want ~659 for that duration; menu/dialogue holds account for the gap, same
  as the original report's own finding). 480 stays a real margin below the
  one clean measurement available.
- **`S05-60`**: `3000 → 1200` (revised down from an initial `1600`, which
  was derived from a single run and would have flaked against the range
  actually measured). Real row counts gathered this session at this exact
  checkpoint, across every run shape encountered: **1349** rows
  (`GATE2-EVIDENCE-0903`'s own original reference run, reproduced by reading
  its committed telemetry), **1720** (a full run to the South Bridge with
  `S05-32x` retired, before the `S05-35` fix), **1353** (a run that hit
  §3.4's new stall). 1200 sits below all three rather than pinned to any
  single run's ceiling — it keeps proving the trace ran (the stale `3000`
  never did, on any run shape, at any point in this repo's history) without
  going flaky on ordinary variance, and without being weakened *because* of
  the open §3.4 finding — the trace itself ran correctly straight through
  that stall, exactly as it did through the original Pond one.

Both assertions carry an `observation` field recording the real numbers
behind the choice, so the next person re-deriving these has the same trail
this report does.

## 6. Files changed

| File | What |
|---|---|
| `tests/helpers/stick_navigator.gd` | 2.9's fix: continue obstacle-following instead of falling back to the distance-based stall check while the direct line stays blocked. |
| `scripts/debug/gate_f_probe.gd` | New `active_creature_hp()`, backing the new assert. |
| `tools/gate_f/operator_harness.gd` | New `active_creature_alive` assert check. |
| `tools/gate_f/SEGMENT_SCHEMA.md` | Documents `active_creature_alive`. |
| `tools/gate_f/segments/S08.json` | Revive+recall block after the wild Meadowhart fight; `active_creature_alive` pre-flight before each of the three captain fights. |
| `tools/gate_f/segments/S05.json` | `S05-32x` retired (note, not deleted — history stays searchable); `S05-35` moved to `advance_dialogue_until_closed`; `S05-60` re-derived twice. |
| `tools/gate_f/segments/S04.json` | `S04-61` re-derived. |
| `tools/gate_f/probe_pond_walker_fix.gd` | New. Verifies 2.9 directly at the documented stall coordinate. |
| `tools/gate_f/probe_ironwood_approach.gd` | New. Isolated repro tool for §4's freeze bearing — proves the walker itself is clean. |
| `tools/gate_f/probe_carve_failsafe_at.gd` | New, general-purpose (takes `--at=X,Y,Z`). Replaces two one-off point-check scripts written and then generalized during this session's investigation. |

## 7. What is still open, for whoever picks this up next

1. **§4 — the S08 Ironwood-approach freeze.** Deterministic, real, blocks all
   of S08's captain-fight evidence including this session's own switch/revive
   fix. Not a walker-logic defect (ruled out), not a CarveFailsafe volume
   (ruled out). Needs either a rendered/visual pass at
   `(-164, -9, 4335)` or investigation of wandering-NPC placement timing.
2. **§3.4 — the new Old-Bram-detour stall** at `(53, -3, 808)`, same
   signature, also not a CarveFailsafe volume. Not investigated beyond that
   one check.
3. **§1's closing caveat** — the fence-corner oscillation this fix should
   also help was not independently re-verified this session; `FENCE-CORNER
   -0903` does not exist as a pushed branch to read against.
4. Once §4 clears, S08 should be re-run to get the live, end-to-end
   confirmation that the three captain fights actually start — the thing
   this lane was asked to prove and could not, this session, for a reason
   outside its own fix.
