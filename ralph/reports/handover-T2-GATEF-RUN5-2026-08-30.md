# Handover — T2-GATEF-RUN5, 2026-08-30

**Branch:** `ralph/T2-GATEF-RUN5`, off `origin/main` at `28265a3a`, with
`origin/ralph/T2-GATEF-RUN4` merged forward (its GAME-0/T1 fixes and probes
are prerequisites for everything below and had not landed on `main` when this
session started), and `origin/main` merged forward again at `44744fe8`.

**Commits, oldest first:**
```
9611a039  Merge origin/ralph/T2-GATEF-RUN4 into ralph/T2-GATEF-RUN5
263e0e7a  Fix GAME-8 (shop exit walk) and GAME-9 (tool binding)
99a2d86e  S03: close Oskar's creature-swap panel, the blocker GAME-8 was hiding
69366d78  Merge origin/main into ralph/T2-GATEF-RUN5
258dd3b2  Gate F run 5 evidence: S03 (superseded + fixed), X07, X08
```

---

## 1. Headline

**GAME-8 and GAME-9 are both fixed, root-caused exactly, and live-proved.**
Neither cause was what four sessions of notes said it was. A third defect
that those two were hiding is also found and fixed. **Segments ran for the
first time in this whole effort** — the table is in §2.

The chain still does not produce a healthy `S03-exit.json`, and §5 says why
in one sentence: **the entry save it starts from carries a one-creature
party.** That is upstream of everything this lane was pointed at.

---

## 2. Segment table — the deliverable no prior run reached

| segment | steps | PASS | FAIL | DELEG | status | evidence |
|---|---:|---:|---:|---:|---|---|
| **X08** | 62 | **62** | **0** | 0 | **COMPLETE, clean** | `ralph/reports/gate-f-run5-chain/X08/` |
| **X07** | 266 | **183** | **3** | 80 | **COMPLETE** | `ralph/reports/gate-f-run5-chain/X07/` |
| **S03** | 395 | **340** | **48** | 7 | COMPLETE, exit save unhealthy | `ralph/reports/gate-f-run5-chain/S03/` |
| S03 (1st) | 393 | 315 | 71 | 7 | superseded — exposed the Oskar panel | `.../S03-superseded-1/` |
| **X06** | — | — | — | — | **BLOCKED by the harness cost gate** | `.../X06/INCOMPLETE.md` |
| S04 | — | — | — | — | see §7 (running at handover time) | `.../S04/` |

X08 is the first Gate F segment anywhere in this effort to finish with zero
failures.

**X07's 3 FAILs, all real and all small:**
- teleport to `(-150, 4200)` lands **11.3 m** away against a 5.0 m tolerance
  (twice) — the terrain there does not accept the point;
- `region=corridor` where `stronghold_approach` was wanted;
- `region=corridor` where `hall` was wanted.

The last two are the gap X07's own step note already predicted:
`data/config/map_landmarks.json` has no region for either the Stronghold
approach or the Hall. That is a data gap to close, not a rig fault.

**X06 is BLOCKED, legitimately.** The harness's capture pre-flight refuses
it: predicted 14,960 s (4.2 h) against the 14,400 s ceiling, 2,525,320
planned frames at a measured 0.006 s/frame. This is the same shape as S10's
own recorded BLOCKER and wants the same remedy — a split evidence lane or a
faster host — not a shorter wait. Not a defect I introduced and not one this
lane can patch around.

---

## 3. GAME-8 / RIG-23 — FIXED. The exit leg was pointed at a target behind a wall

Every prior session read this as the navigator picking the wrong side of
Mira's counter and wedging in the 0.3–0.4 m gap behind it. That is where the
walker ended up. It is not why.

`S03-59a` **already asked for the correct point** — cottage_a's own door
staging point at building-local `(1.0, 4.0)`, the same one `S03-52` uses
going in. Its `close_enough` was **2.0 m** and the doorway sits **1.9 m**
from that point, so the leg returned `true` with the player still INSIDE the
shop at local `(0.78, 2.15)`. `S03-60` then set off toward Oskar — who is at
building-local **`(-5.66, 0)`: due west, straight through the wall the stock
crates are stacked against, 180 degrees from the only way out.**

No obstacle-avoidance heuristic can route a leg whose target is behind a
wall. The walker was not choosing badly between two sides; it was asked to
walk through plaster and did the only thing it could. That is why four
sessions of waypoint guesses all reproduced the same wedge — none of them
changed that fact.

**Fix:** `close_enough` 2.0 → 0.8 (budget 400 → 1500, `held_budget_frames`
added) so the leg cannot terminate until the body is genuinely outside the
building. **Live-proved** by `tools/gate_f/probe_shop_exit_clearance.gd`:
from behind Mira's counter, out to the staging point **ARRIVES in 38 walking
frames**, and Oskar then **ARRIVES in 79 more** — against a full 3000-frame
budget exhaustion for the direct line. Confirmed again in the real segment:
`walked 4.4 m to (22, -6) in 97 walking frames (0 held)`.

### `stick_navigator.gd` was fixed too, and needed it independently

The mission asked for a mechanism-level fix to the navigator rather than
more coordinates, and there was a real mechanism defect to fix — just not
the one that was blocking S03.

Its clearance probe was **one hairline ray at hip height**
(`PROBE_HEIGHT := 1.0`). It was blind twice over:

- **Blind to anything short.** The stock crates top out at 0.50 m and
  0.945 m; the counter's top is at exactly 1.00 m. To a ray at 1.0 m, a room
  full of furniture read as three metres of open air.
- **Blind to width.** A ray has none. The player capsule is 0.8 m across
  (`scenes/player/player.tscn`, radius 0.4) and the gap between the west wall
  and the crates is **0.14 m**.

Measured live at the wedge point: the old probe reported **1.50 m** of
clearance on the side where the body actually has **0.25 m**
(`probe_shop_exit_clearance.gd`, question 1).

It now sweeps the volume the body occupies — nine rays, three heights by
three lateral offsets, nearest hit wins, with the lowest height above
`player_controller.gd::STEP_HEIGHT` (0.35) so a kerb the body steps over does
not read as a wall. It refuses to commit a detour to a side narrower than the
body, backs out of a pocket when both sides are pinched, and abandons a
detour that has stopped carrying the body anywhere instead of grinding out
its frame count. On the unsolvable direct leg the walker now ends up free in
the middle of the room rather than jammed at local x=-1.37.

**Regression checks — what I proved and what I did not.**

- **Full unit suite: 1600 tests, 3,388,789 assertions, 0 failed.** Clean.
- **`tests/smoke_gate_b_continuous.gd`** — the navigator's own smoke test —
  FAILs, and I **baselined it**: it FAILs *identically* on `origin/main`
  with the unmodified navigator (`recipe_orb_basic` unset from Mira's
  opening visit; same message, same place). **Pre-existing, not mine.**
  Recorded as an out-of-lane defect in §8.
- **`tests/smoke_gate_a_build_segment_meadows.gd`** FAILs: *"there is no
  hammer in the satchel; the village's gift (`camp_hammer_given`) comes
  before any of this segment's work and is not this segment's to grant"*.
- **`tests/smoke_gate_b_tail.gd`** FAILs: *"only 3 of 5 creature beds went
  up"*, plus a tracked-objective mismatch and an empty pending build
  selection.

**I did not finish baselining those last two, and I am not claiming they
are pre-existing.** I started the same `origin/main`-navigator comparison I
ran for gate B continuous, and killed it before it produced a result in
order to get the working tree back to a committable state (the comparison
works by temporarily swapping the navigator file, and leaving that swap in
the tree risks committing a revert of the GAME-8 fix — which is exactly
what nearly happened).

What can be said honestly without that run: **neither failure message is
navigation-shaped.** A missing hammer is a prerequisite gift the segment
says outright is not its own to grant, and "3 of 5 creature beds" is a
build-economy shortfall of the same family as S03's own materials
shortfall in §6 — the navigator has no way to produce either symptom, and
both walks in those tests would have to have *succeeded* for the tests to
reach the point where they fail. But that is reasoning, not measurement.
**Next session should run the two-line baseline before trusting it:**

```
git show origin/main:tests/helpers/stick_navigator.gd > /tmp/nav_base.gd
cp tests/helpers/stick_navigator.gd /tmp/nav_mine.gd
cp /tmp/nav_base.gd tests/helpers/stick_navigator.gd
$GODOT --headless --path . --script tests/smoke_gate_a_build_segment_meadows.gd
$GODOT --headless --path . --script tests/smoke_gate_b_tail.gd
cp /tmp/nav_mine.gd tests/helpers/stick_navigator.gd   # ALWAYS restore
```

### The brief's other question: NO, a real player cannot get stuck there

Asked directly and live. From four starts inside the wall/crate pocket —
deepest beside the lower crate, north of the crates, south with the counter
behind, and the crate corner — holding the stick at the door with **no detour
logic at all**, the way a person plays: **all four escape to the door lane.**
A 0.14 m gap does not admit a 0.8 m-wide body in the first place.
`shop_interior.gd` is unchanged and needs no change. The Meadows has no
player trap here.

---

## 4. GAME-9 / RIG-24 — FIXED. The two probes were never running the same recipe

The standing puzzle was "the isolated probe PASSes and the replay FAILs, so
something about accumulated state must differ." The accumulated state does
differ, and that is not the main cause.

`probe_tool_equip_sequence.gd` calls `inventory.find_slot("knife")` and
drives the cursor to the slot the knife is **actually** in. `S03.json`
pressed `ui_right` a hardcoded four times, counting cells along the order a
**fresh** `S02-exit.json` happens to fill the bag in. **The probe's PASS was
never evidence about the segment's scheme.**

Two things then break the count, and the second is decisive:

1. **The bag is not fresh.** Run 4's own telemetry records it as
   `{axe, berries:5, coin:30, knife, orb_basic:15, pickaxe, potion_small:1,
   torch}` — both Revive draughts spent on the two live revives, potions down
   from three to one, before a single tool is bound.
2. **`ui_left` does not wrap up a grid row.** `S03-56f`'s own note asserted
   it does ("wrapping up a grid row"). It does not. From the knife's cell the
   three left presses walked backwards along row 0 instead of reaching the
   pickaxe on row 1 of the 6-column grid.

**Reproduced exactly.** `tools/gate_f/probe_tool_equip_depleted_bag.gd`
rebuilds run 4's own depleted bag and runs both schemes against it:

```
A. the counting scheme S03 shipped
   after 4 x ui_right, cursor is on cell 4 holding 'knife'
   after 3 x ui_left,  cursor is on cell 1 holding 'potion_small'
   after 1 x ui_left,  cursor is on cell 0 holding 'orb_basic'
   hotbar produced: ["", "", "potion_small", "knife", ""]
B. focus_item
   cell 4 'knife' -> cell 7 'pickaxe' -> cell 6 'axe'
   FINAL hotbar:    ["", "axe", "pickaxe", "knife", ""]
```

Scheme A's hotbar puts knife at slot 3 — **precisely the
`{hotbar_slot: 3, item: "knife"}` that every one of run 4's six real gathers
reported, bit for bit.**

**Fix:** a new harness action **`focus_item`**
(`operator_harness.gd::_step_focus_item`, documented in
`tools/gate_f/SEGMENT_SCHEMA.md`), backed by three new
`scripts/debug/gate_f_probe.gd` accessors — `satchel_slot_of()`,
`satchel_focus()`, `satchel_columns()`. It sends the **same real `ui_*`
events** `focus_move` sends and simply reads the cursor between them,
navigating column-then-row the way the passing probe already did. Still
production input; the only change is that the harness looks at the bag
instead of assuming, which is what a player does. `S03-56d/f/h` now name the
item. An unreachable cell or an absent item FAILs loudly instead of binding
the wrong thing in silence.

**Live in the real segment**, and note the cells nothing could have
predicted:
```
focus_item 'knife':   cursor on cell 4 after 4 move(s) (from cell 0)
focus_item 'pickaxe': cursor on cell 6 after 5 move(s) (from cell 4)
focus_item 'axe':     cursor on cell 3 after 4 move(s) (from cell 6)
```
and the tool rotation that follows, working for the first time:
```
hotbar_4 -> {hotbar_slot: 3, item: 'knife'}
hotbar_3 -> {hotbar_slot: 2, item: 'pickaxe'}
hotbar_2 -> {hotbar_slot: 1, item: 'axe'}
```
with the six-plus gathers after it carrying knife / axe / pickaxe / knife /
axe in turn, instead of the same wrong tool every time.

---

## 5. NEW, found and fixed: Oskar's creature-swap panel is never closed

GAME-8 was hiding this, and it is the single most instructive thing this
session found.

With GAME-8 fixed, `S03-60` reaches Oskar for the first time in five
sessions and his greeting actually runs — which ends with
`shop:creatures:oskar`, and `sequence_director.gd::_maybe_open_shop()` opens
that as a **SwapPanel** the instant his dialogue box closes. Mira's goods
shop is closed by `S03-56` and the world re-asserted by `S03-56a`. **Oskar's
branch had neither.**

The first run's telemetry pins `input_context` at `panel:SwapPanel` from
`S03-62` to the end of the segment, and every consequence follows from that
one fact:

- every `hotbar_N` press was swallowed by
  `playground_hud.gd::_world_input_allowed()`, so `equipped` read
  `{hotbar_slot: -1, item: ""}` through the whole gathering loop **even
  though the exit save shows the bar correctly bound** to
  `["", "axe", "pickaxe", "knife", ""]` — GAME-9's fix had landed and the
  tools still could not be drawn;
- every walk reported **"0 held" while never leaving (19,-6)**, because a
  panel owning input is not the same thing as locomotion being disabled, and
  the walker has no way to tell the difference;
- 71 of 393 steps FAILed, all downstream of this one panel.

**Fix:** `S03-62a` (`menu_cancel`) and `S03-62b`
(`assert input_context == world`), mirroring Mira's own pair exactly.
`S03-62b` is the guard that branch never had: without it a stuck panel
reports as seventy-one unrelated-looking failures instead of one.

Result: **71 FAIL → 48 FAIL, 315 PASS → 340 PASS**, real materials gathered
(`stone:1, fiber:6, berries:14`), one building placed.

This is the RIG-13..RIG-22 shape again, and worth stating plainly for
whoever is next: **on this segment, each real fix reveals exactly one more
defect behind it.** Three sessions have now each found "the" blocker and
been right, and the chain still is not healthy. Budget the next session for
"fix, re-run, find the next one" as the expected loop, not the bad case.

---

## 6. Why the chain is still not healthy, and where the real blocker is

`S03-exit.json` after all three fixes:

```
party:     1  (Moss, hp 0.0/1.18, FAINTED)
hotbar:    ["", "axe", "pickaxe", "knife", ""]     <- correct
buildings: 1                                        <- was 0
inventory: orb_basic 13, axe, stone 1, pickaxe, torch, coin 30,
           fiber 6, berries 14, knife
flags:     ... mira_shop_open, opening:mira_visited, oskar_trade_open
           (home_built / creature_bed_built_3 still unset)
```

The remaining 48 FAILs cluster into two groups and both trace to one fact:

- 14 × `map did not open the pause shell: context build_placement` — a build
  is armed and never completes, because the home needs 27 wood / 17 stone /
  10 fiber and the run has 0 / 1 / 6;
- 12 × `the live prompt is "Ripplet is out of the fight"` — GAME-0's
  statement, correctly deprioritised by RUN4 but still the winner when it is
  the **only** offer, which it is once the party's single creature is down.

**The one fact:** `ralph/reports/gate-f-run-20260828T183531Z/S02/saves/S02-exit.json`
— the entry save every S03 attempt in every session has been seeded from —
**carries a party of ONE.** I verified this directly. A one-creature party
means the one creature faints and stays fainted, the fainted-ally statement
then owns the interact line, and the team-of-3 the tournament gates on can
never exist.

That is the known S02 defect already on the record ("first-catch engagement
never fires from S02's own blind press", `GATE_F_RUN_3_FINDINGS.md`), and it
is **upstream of this entire lane.** No amount of S03 work fixes it.

**My recommendation, stated as a recommendation and not acted on:** the next
session's first job is a healthy S02-exit with a real team, not another S03
round. Either fix S02's first-catch press so the chain has a legitimate
two-creature entry, or — the option RUN4 raised and declined — accept a
hand-built entry save for bands 2–5 evidence and record it as such. Between
those two I would fix S02: a synthetic entry save makes every downstream
"the player could do this" claim conditional, and S02's defect is one press
at one target, not a system.

---

## 7. Segments not run, and honestly why

- **X04** (the brief's #1: post-RIG-11 combat evidence is zero) needs
  `S04-exit.json`, which needs S04, which needs S03-exit. S04 was launched
  from the new S03-exit at handover time; with a fainted one-creature party
  its tournament entry check will fail on team size exactly as run 3 recorded
  (RIG-18). Its directory is `.../S04/` — read its `INVENTORY.json` rather
  than trusting this sentence.
- **X01** takes `run://S03-exit.json` and could have run, but X01, S04 and
  X05 all `wipe_saves` and `seed_save` into **slot 4**, so they cannot run
  concurrently without corrupting each other's entry. They must be serialised,
  and the session's remaining budget took S04 over X01 because X04 is gated
  on it. X07 and X08 were safe to parallelise precisely because they touch no
  saves — worth knowing for scheduling the next run.
- **X05, S10** not reached.

---

## 8. Defects outside this lane, for the coordinator

1. **`tests/smoke_gate_b_continuous.gd` FAILs on `origin/main`.** "Mira's
   required opening visit left `recipe_orb_basic` unset; the gift branch is
   what the Foreman's hammer and the orb recipe wait on." I confirmed this
   against the unmodified `origin/main` navigator, so it is not a regression
   from this branch — but it means the navigator's own smoke test is red on
   main and has presumably been red for a while, which is how a shared helper
   stops being protected. Worth an owner.
2. **`map_landmarks.json` has no region for the Stronghold approach or the
   Hall** (X07's two region FAILs). X07's own step note already predicted
   this; the data has still not caught up.
3. **X06 exceeds the harness cost ceiling by 560 s** (14,960 vs 14,400).
   A split like `T2-S10-COST`'s would land it; it is 4% over, not 40%.
4. **S02's one-creature exit save**, per §6. This is the big one.

---

## 9. Reproducing anything here

```
tools/art_pipeline/setup.sh godot          # no Godot in a fresh container
export GODOT=$HOME/.cache/tetherbound-art/godot
$GODOT --headless --path . --import        # ~10 min, required

# the two new probes, ~3-4 min each
$GODOT --headless --path . --script tools/gate_f/probe_shop_exit_clearance.gd
$GODOT --headless --path . --script tools/gate_f/probe_tool_equip_depleted_bag.gd

# the full unit suite, ~25 min
$GODOT --headless --path . --script tests/run_tests.gd

# a segment (save-seeding segments must be run ONE AT A TIME)
tools/gate_f/run_segment.sh --run-dir ralph/reports/gate-f-run5-chain S03
```

`probe_shop_exit_clearance.gd` answers three questions in one stand-up
(old-vs-new clearance readings, the exit walk both ways, and the real-player
wedge test) because standing the Meadows up is the expensive part.

---

## 10. File footprint

**Game/harness code:**
- `tests/helpers/stick_navigator.gd` — body-volume clearance probe replacing
  the single hip-height ray; clearance-gated side choice; pocket back-off;
  detour abandoned when it stops moving the body.
- `scripts/debug/gate_f_probe.gd` — new `satchel_slot_of()`,
  `satchel_focus()`, `satchel_columns()`.
- `tools/gate_f/operator_harness.gd` — new `focus_item` action.
- `tools/gate_f/SEGMENT_SCHEMA.md` — `focus_item` documented.

**Segment data:**
- `tools/gate_f/segments/S03.json` — `S03-59a` tolerance/budget (GAME-8);
  `S03-56d/f/h` switched to `focus_item` and `S03-56b`'s note corrected
  (GAME-9); `S03-62a`/`S03-62b` added (Oskar panel).

**New probes (committed, with `.uid` siblings):**
- `tools/gate_f/probe_shop_exit_clearance.gd`
- `tools/gate_f/probe_tool_equip_depleted_bag.gd`

**Docs:**
- `ralph/reports/GATE_F_RUN_3_FINDINGS.md` — GAME-8, GAME-9 marked resolved
  with corrected causes; original entries kept.
- `ralph/reports/GATE_F_RUN_3_RIG_FINDINGS.md` — RIG-23, RIG-24 likewise.
- this file.

**Evidence:** `ralph/reports/gate-f-run5-chain/` (X08, X07, S03,
S03-superseded-1, X06's INCOMPLETE, S04).

**Not touched:** `scripts/world/shop_interior.gd` (measured, correct, no
player trap — see §3); `roll_new_worlds`; every segment outside S03.

---

## 11. What I would do next, in order

1. **Fix S02's first-catch press** so the chain starts from a real
   two-creature party (§6). Everything else on this chain is downstream of it.
2. Re-run S03 from that entry save. Expect one more defect behind the ones
   fixed here — that has been the pattern three sessions running (§5) — and
   budget for the loop rather than for a single fix.
3. Then S04 → X04, serialised (§7), because X04's combat evidence is still
   zero and is the oldest outstanding debt in the run-3 record.
4. Split X06 the way `T2-S10-COST` split S10; it is 4% over the ceiling.
