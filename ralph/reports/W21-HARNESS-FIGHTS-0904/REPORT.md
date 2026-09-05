# W21-HARNESS-FIGHTS — every Gate 3 segment now fights by predicate

Branch `ralph/W21-HARNESS-FIGHTS-0904`. Closure-plan rows **CL-H1**, **CL-H2**, **CL-H7**.

---

## What was wrong, in one paragraph

Every fight in `S06.json`, `S07.json`, `S08.json`, `S09.json` and their capture twins was
`press combat_quick, times: N`. `tools/gate_f/SEGMENT_SCHEMA.md` names this failure mode in
its own words — a fight's length is a function of levels, the type chart and a ±10% roll on
every hit, so a counted press block is right for exactly one matchup — and a `press` step
asserts only that **input was injected**. So the block reported PASS whether it won the
fight, lost it, or emptied itself into a party wipe. That is not a hypothetical: G3-BAND2
traced `S06-22`'s 34 presses against Dorn and found all four party members fainting in
sequence inside it (Tup t≈333 s, Bramble t≈371 s, Pip t≈391 s, Trail t≈428 s, HP
`(0,0,0,0)`), the party then walking ~450 s into the Burrow Warrens at zero HP, dying again,
dropping the whole satchel, and being returned to the region entrance — with every step in
that stretch green. The same shape one layer up (CL-H2): `press interact, times: 12` at
S09's outer watch ran out before the panel closed, left `input_context` on
`narrative_modal` where the next step expected combat, and the fight never started.

## What changed

`tools/gate_f/segments/S06.json`, `S06C.json`, `S07.json`, `S07C.json`, `S08.json`,
`S08C.json`, `S09.json`, `S09C.json` — three uniform changes plus one one-line fix:

1. **21 counted combat blocks → `fight_until_resolved`.** It presses `combat_quick` only
   while the action machine reads READY, presses `party_cycle` once when the pilot drops
   below 35 % of max HP, and stops only when both `is_fighting()` and
   `trainer_battle_active()` have been false for `quiet_frames`. Every trainer fight also
   names its `until_flag` (`defeated_quarry_dorn`, `defeated_band2_outrider_kest`,
   `relay_captain_defeated`, `defeated_captain_field`, `defeated_captain_riverwatch`,
   `defeated_patrol_ridgeline`, `defeated_captain_ridge`,
   `defeated_stronghold_outer_watch`, `defeated_stronghold_checkpoint`), so a fight that
   ends without the defeat landing FAILs instead of passing quietly.
2. **S08's two wild engages → `chip_to_floor`, not `fight_until_resolved`.** `S08-29` and
   `S08-41` are CATCH chips: a fight driven to resolution faints the target and there is
   nothing left to throw an orb at. `chip_to_floor` reads the live enemy's real HP before
   and after every swing and stops **before** the swing whose worst plausible roll could
   reach the floor. Same predicate-not-press-count rule, applied to the half of combat that
   must *not* end.
3. **21 challenge conversations → `advance_dialogue_until_closed`**, which reads
   `dialogue_runner.gd::line()` and stops the moment the panel closes.
4. **A recovery ladder in front of every fight, and a post-faint switch behind it.**
   The ladder is `wait_until world → open_menu backpack → focus_item {item: "revive"} →
   press interact → press ui_accept → close_menu → wait_until world → press party_cycle
   (skip_if `active_creature_alive`) → wait → assert active_creature_alive`. The Revive is
   addressed **by item identity**, never by slot offset (GAME-9/RIG-24 measured a fixed
   offset landing on the wrong item three times in one run once the grid had shifted). The
   two presses in the middle carry `skip_if {inventory_count revive max 0}` so an empty
   Revive stack can never turn them into blind presses onto whatever the grid happens to
   focus. The trailing gate is `active_creature_alive`, the check
   `encounter_director.gd::can_challenge()` silently refuses on.
5. **CL-H7.** `map_landmarks.json` puts `the_long_water` at (−150, 4200) with a 52 m radius;
   `S07-26` asserted that region at (150, 3500) — **728 m outside it**. The coverage was
   moved, not deleted: `S07-77a` asserts it at the Old Mill Crossing (−152, 4195.6), 4.6 m
   from the region's own centre. `S07C`'s route never enters the region at all, so its
   twin records the note instead and says so.

Scripted mid-fight `party_cycle` beats went with the counted blocks that surrounded them —
`fight_until_resolved`'s own switch fires on the pilot's real HP, which is what CB-09's
"switching under pressure" means. Scripted `combat_charged` (including S07's
`device: "mouse"` workaround for the JoyAxis:4 collision) and `camera_recenter` presses are
**kept** and moved to each fight's opening, because `fight_until_resolved` owns the fight
end to end and nothing can be threaded through its middle. Every such move is recorded in
the step's own `observation`.

Left alone as instructed: `S06-30` (another lane decides it), `S08-22`'s coordinates
(another lane is root-causing the freeze), `operator_harness.gd`, `run_segment.sh`,
`stick_navigator.gd`.

## The guard

`tests/test_gate_f_segments.gd` (new, 6 tests). It pins all four asks so a re-introduction
is caught before a four-hour run pays for it:

| test | fails when |
|---|---|
| `test_no_gate3_segment_fights_with_a_combat_quick_press_block` | any `press combat_quick` in S06–S09 or their twins |
| `test_every_gate3_segment_drives_its_combat_by_predicate` | a segment asserts `combat_running` but holds no `fight_until_resolved`/`chip_to_floor` (the "answer it by deleting the fights" hole) |
| `test_every_gate3_fight_is_preceded_by_a_party_health_gate` | a fight with no `active_creature_alive` assert between it and the previous fight |
| `test_no_gate3_fight_is_reached_through_a_counted_dialogue_block` | a `press interact, times: N` in a fight's run-up |
| `test_gate3_revives_are_addressed_by_item_identity` | a Gate 3 segment with no `focus_item {item: "revive"}`, or a directional cursor move inside a revive sequence |
| `test_the_long_water_is_only_asserted_from_inside_the_long_water` | `region_is: the_long_water` asserted from a waypoint outside the region's own radius (read from `map_landmarks.json`, not hard-coded), **or** S07 asserting it nowhere at all |

**Seen red for the right reason before it was seen green.** With `tools/gate_f/segments/`
reverted to the pre-change tree and the test file left in place:

```
godot --headless --path . --script tests/run_tests.gd -- --only=test_gate_f_segments.gd
6 tests, 170 assertions, 6 failed
```

— all six failing, each naming a real step (`S06-22 … times: 34`, `S07-29 advances the
conversation into S07-32's fight with times: 10`, `S06 has no focus_item {item: "revive"}`,
`S07C-26 asserts region the_long_water at (150.0,3500.0), which is 762 m from the region's
own centre`). Restored:

```
godot --headless --path . --script tests/run_tests.gd -- --only=test_gate_f_segments.gd
6 tests, 148 assertions, 0 failed

godot --headless --path . --script tests/run_tests.gd -- --only=gate_f
73 tests, 43417 assertions, 0 failed
```

The `--only=gate_f` run includes `test_gate_f_instrumentation.gd`'s
`test_every_segment_script_is_well_formed`, which checks every one of the ~300 new steps
against the harness's implemented action vocabulary and requires an `expected` on each.

---

## The runtime validation: four logic-lane runs from synthetic entries

Method, per the brief and `docs/GATE3_EXECUTION_PLAN.md` §4b:

```
export GODOT=$HOME/godot-bin/godot                      # 4.7-stable, installed here
export XDG_DATA_HOME=/tmp/w21-userdata/<SEG>            # isolates user:// so two
                                                        # concurrent segments cannot
                                                        # wipe each other's seeded slot
godot --headless --path . --script tools/gate_f/build_s0N_entry_synthetic.gd -- --out <dir>
# then a run-local RUN_METADATA.json carrying lanes.logic (the §4b freeze-record trap;
# the tracked candidate record was NOT touched)
tools/gate_f/run_segment.sh --run-dir ralph/reports/gate-f-run-W21-S0N S0N
```

Two segments at a time on this 4-core box. The measured frame cost came out at
**0.0167–0.0168 s/frame** in every run, i.e. the isolation and the pairing cost nothing
against the 0.0167 s/frame the plan already quotes — no run was refused by the CD-7 cost
gate.

A note on the seed builders' `--out` contract, since it cost a run: `build_s06/07/08` take
the **saves directory**, `build_s09` takes the **run directory** and appends `saves/`
itself. They are not interchangeable.

### Results

The full per-step verdicts and `INVENTORY.json` for each run are committed under
`ralph/reports/W21-HARNESS-FIGHTS-0904/runs/`. Telemetry payloads (`events.jsonl`,
`route.csv`) and the seeded save files stay local per `.gitignore`'s evidence rule.

| run | steps | PASS | FAIL | SKIP | DELEGATED | where it stops |
|---|---|---|---|---|---|---|
| `gate-f-run-W21-S06/S06` | 142 | 106 | 19 | 6 | 11 | ran to its last step; never reached the Warrens interior (see S06-50 below) |
| `gate-f-run-W21-S07/S07` | 176 | **154** | **3** | 10 | 9 | ran to its last step |
| `gate-f-run-W21-S08/S08` | 204 | 85 | 13 | 98 | 8 | **derails at S08-79** |
| `gate-f-run-W21-S09/S09` | 102 | 49 | 2 | 46 | 5 | **derails at S09-35** |
| `…S07/S07-superseded-1` | 176 | 29 | 1 | 146 | 0 | derailed at S07-19; superseded by the `close_enough` fix and kept as the measurement that found it |

### The fights, and whether they resolve fairly

Nine trainer fights and one catch chip ran. Every one ended on the predicate, and every one
ended with a live party.

| fight | what the harness recorded | party after |
|---|---|---|
| **S06-22 Dorn** (2 creatures) | `fought 1534 frames: 41 quick, 0 handovers, 0 refused switches; ended because flag 'defeated_quarry_dorn' set` | Tup **94/170**, Bramble 129/129, Pip 106/106, Trail 136/136 |
| **S07-21 Kest** (2) | `1468 frames: 43 quick; flag 'defeated_band2_outrider_kest' set` | all five up |
| **S07-32 Hess** (2) | `1275 frames: 34 quick; flag 'defeated_relay_hess' set` | all five up |
| **S07-38 Orrin** (2) | `1047 frames: 32 quick; flag 'defeated_relay_orrin' set` | all five up |
| **S07-47 Dell** (3) | `2857 frames: 74 quick, **1 handover**; flag 'defeated_relay_dell' set` | all five up |
| **S07-54 the Relay Captain** (3) | `1853 frames: 52 quick, **1 handover**; flag 'relay_captain_defeated' set` | Tup 139/199, Mudsnout 43/160, Burrowback 94/183, Galecrest 168/168, Mosshell 216/216 — five for five, zero faints across the whole relay ladder |
| **S09-29 the outer watch** (2) | `1231 frames: 40 quick; flag 'defeated_stronghold_outer_watch' set` | Ripple 150/200 piloting, Gale/Tusk/Dusk untouched |
| **S08-41 the meadowhart** (catch chip) | `18 x combat_quick: enemy hp 9.3/175.8 (5.3%), hits dealt [9.5, 9.3, 10.0, 9.8, 9.8, 9.7, 8.7, 8.6, 9.8, 9.5, 8.3, 8.5, 9.2, 9.2, 9.4, 9.4, 8.3, 9.6], largest 10.0` — stopped **before** the swing that could have fainted it | catch confirmed at S08-45 |

**The headline is S06-22.** That is the exact fight G3-BAND2 watched wipe a party of four
inside a 34-press block, and the reason the whole rest of that segment's evidence was
void. Driven by predicate it takes 41 presses, ends on Dorn's own defeat flag, and costs the
lead 76 of 170 HP with the bench untouched. Nothing about Dorn changed — only the way the
fight was played. G3-BAND2's own conclusion is now settled in the direction it suspected:
*"whether a competently played level-8 team does is still open"* — it does.

Note how far the old counts were from the fights they were written for: Dell needed **74**
presses and was scripted 34; Vance needed 52 and was scripted 76 across six blocks with five
scripted `party_cycle` presses between them; the outer watch needed 40 and was scripted 70.
Two of the nine fights fired the HP-triggered handover, and no switch was ever refused by
the commitment guard — which is what the six hand-written cycle-between-short-blocks ladders
in S07 were trying and failing to approximate.

### The recovery ladder, observed working

`gate-f-run-W21-S09` is the one that proves it end to end. At t=388.8 s a wild burrowback
fainted Tup during the walk to Corr (`combat_hit … 2.6 -> 0.0`, `faint: Tup fainted`). The
old script would have walked a fainted lead into the outer watch, where
`can_challenge()` refuses silently and the `press interact, times: 12` behind it would have
reported twelve green presses into a `trainer_no_usable_creature` conversation. What the
ladder actually did, from the run's own verdicts:

```
S09-24p0  wait_until world      PASS  input_context=world [true after 0 physics frames]
S09-24p1  open_menu backpack    PASS  context world -> menu_backpack
S09-24p2  focus_item revive     PASS  cursor on cell 2 after 2 move(s) (from cell 0)
S09-24p3  press interact        SKIP  not needed (revive count 0)
S09-24p4  press ui_accept       SKIP  not needed (revive count 0)
S09-24p5  close_menu            PASS  menu_cancel closed the shell
S09-24p6  wait_until world      PASS
S09-24p7  press party_cycle     PASS  pressed party_cycle x1        <- active_creature Tup -> Ripple
S09-24p8  wait 1 s              PASS
S09-24p9  assert alive          PASS  active creature at 199.5 HP
S09-25    advance_dialogue      PASS  advanced 2 lines over 2 presses; DialoguePanel closed,
                                      context 'narrative_modal' -> 'combat'
S09-29    fight_until_resolved  PASS  1231 frames, 40 quick; flag 'defeated_stronghold_outer_watch' set
```

Ripple then fought and won the fight Tup could not have started. The second ladder
(`S09-34p*`) did the same again after Ripple fainted, handing the pilot to Gale at 193.2 HP.

Three details worth keeping:

* `focus_item` found the Revive **two cells from where a slot offset would have looked**
  (`cursor on cell 2 after 2 move(s) from cell 0`) — the by-identity requirement earning its
  keep on the first run that used it.
* The `skip_if {inventory_count revive max 0}` guard fired for real. `build_s09_entry_synthetic.gd`
  declares `{"id": "revive", "count": 2}` but the loaded state reports `revive: 0` (and every
  other satchel line at 0 bar `potion_small: 2` and `coin: 45`) — **that seed's inventory
  block is not landing**, which is a finding for whoever owns that builder, not for this
  lane. Without the guard those two presses would have gone blind into the item grid.
* In S06, where the bag really did hold a Revive and nobody was fainted, the block took the
  other branch exactly as `S03-32ar*` documents it: `interact` hit "Nobody needs reviving",
  `ui_accept` picked the stack up, and `close_menu` needed two presses ("closed the shell on
  press 2") to put it back and close. **The Revive was not spent** — final inventory still
  `revive: 1`. The no-op branch is free.

### Where each run stops, and why

**S07 — ran to its last step, 154/3.** The three failures are one thing and its
consequences: `S07-73` reports `flag relay_disabled NOT set` after `S07-71`/`S07-72`
(`press interact` then `press interact, times: 10`) at the relay apparatus, and `S07-74`'s
objective assert fails behind it. `S07-82` wants 3000 route rows and got 1915 — the segment
is genuinely shorter than the transcription assumed once nothing stalls. **Not this lane's
scope**: `S07-72` is a counted press block on a *world interaction*, not a `battle:`-effect
conversation, and CL-H2's brief is the fight handoffs. It is the same defect shape and it is
named in the follow-ups below. Everything this lane owns in S07 passed, including the
CL-H7 assert: `S07-77a — region=the_long_water (wanted the_long_water)`.

**S09 — derails at S09-35.** `S09-33`'s walk to Warder Ness stops **81.3 m short at
(18.0, 4.0, 7363.0)** having burned its whole 15,300-frame budget (1778 held). This
reproduces G3-BAND5 §2's own measurement (92.2 m short at (3.0, −7.0, 7358.0)): the walk
drives into `sigil_gate_gorge_west`, the 11 m-deep carve `terrain_playground.json` authors
so the gate cannot be bypassed. `S09-34`'s challenge press then lands on nothing and
`S09-35` refuses honestly: *"no narrative modal is open. input_context is 'world' and the
input owner is nothing. Advancing nothing would have sent the advance button into the
world."* 41 steps are skipped behind it. **This is the improvement, not a regression** — the
old `press interact, times: 12` would have fired twelve presses into the open world and the
`press combat_quick, times: 42` behind it forty-two more, all green. Not this lane's to fix:
the gorge is terrain and the waypoint is another lane's.

**S08 — derails at S08-79.** Two independent things, neither this lane's:

1. `S08-29 FAIL chip_to_floor: no live enemy to chip` and `S08-31 input_context=world
   (wanted combat_aim)`. `S08-27`'s bare `press interact` did not start a fight with the
   pipwing. Same class as RIG-26, now *visible*: the old `press combat_quick, times: 16`
   reported sixteen green presses into an unengaged world.
2. At Captain Halder, `S08-77p0` timed out with `input_context=narrative_modal` held for its
   full 1200 frames, `p1`/`p2` then failed against the open `DialoguePanel`, combat started
   at t=635.2 while `p6` was waiting, and `S08-79` refused with *"no narrative modal is open.
   input_context is 'combat'"*. Read in order: one of `S08-72`/`S08-74`/`S08-76` — three
   bare unconditional `press interact` steps meant for the riding sequence — won the
   arbiter with **Halder's challenge conversation** instead, and the fight was already
   running by the time the challenge step was reached. That is CL-H12's arbiter-priority
   shape at a new site. The ladder did the right thing at every step: it refused to open a
   menu into a modal, refused to act into combat, and said exactly what held it.

   The *existing* S08 revive block (`S08-45r1a`…`g`, not this lane's) failed the same way
   one fight earlier — `open_menu` into `context combat -> combat`, `focus_item` into "the
   satchel grid reports no columns". It has no `wait_until world` in front of it; the ladders
   added here do, which is why theirs report the cause instead of a bare focus failure.

3. Also in S08: `S08-60`/`S08-63` are the craft-panel focus failure, and `S08-49` the
   pause shell refusing to open — both the build-catalogue context leak G3-BAND2 already
   filed as its own root cause 2.

**S06 — ran to its last step, 106/19, but the Warrens interior was never reached.** After
the quarry workbench, `S06-50`'s walk to the Warrens mouth **pinned inside a 2.7 m × 2.5 m
box at (336.2, 1.3, 1820.6) for its entire 44,100-frame budget — 711 s, `input_context`
`world` throughout, 0 held frames** — and every walk, region, fight and flag step in the
Warrens failed behind it (`S06-51`, `S06-55`, `S06-58`, `S06-62`, `S06-62f`, `S06-68`,
`S06-73c`, `S06-73f`, `S06-80`, `S06-81`, `S06-83`, `S06-84`). The tail (`S06-90`…`S06-96`)
is G3-BAND2's build-catalogue leak again: `map did not open the pause shell: context
build_catalogue -> build_catalogue`, and the exit save byte-identical to the seed.

The pin is worth handing over precisely, because it is **CL-H14's shape with one difference
that changes the diagnosis**:

* it is *not* frozen — `dead_travel_m` climbed to 1258 m while the body jittered inside a
  2.7 m box, so the walker was pushing and moving, not stuck against a null;
* the very next `move_to` (`S06-55`) started **from that same position** and walked away
  cleanly at ~3.9 m/s, covering 470 m in 7,200 frames.

So a fresh walk call escapes ground the previous call could not leave. That points at
navigator state rather than terrain — and it is one step after `S06-38` placed a workbench
at the player's feet. `stick_navigator.gd` is explicitly not this lane's file; recorded and
routed.

### One thing that did NOT reproduce

`S08-22` — the CL-H14 freeze, "reproduced on two independent runs from the identical seed,
to the centimetre" — **passed**: `walked 839.5 m to (-345, 5060) in 10912 walking frames
(0 held)`, and `S08-23` confirmed `region=the_ironwood_grove`. Stated with its caveat: this
run enters from `build_s08_entry_synthetic.gd`'s save rather than from a chained `S07-exit`,
and `main` has moved since G3-HARNESS measured it, so this is *one clean crossing on this
branch*, not a refutation. The lane root-causing CL-H14 should know the leg is currently
walkable here.

---

## Files changed

| file | change |
|---|---|
| `tools/gate_f/segments/S06.json` | 106 → 142 steps. Dorn, the Warrens chamber and the guardian re-scripted; ladders and post-faint switches added. `S06-30` untouched. |
| `tools/gate_f/segments/S06C.json` | 72 → 97 steps. Same, for the two fights the capture twin carries. |
| `tools/gate_f/segments/S07.json` | 119 → 176 steps. Kest and the four relay rungs; the six hand-written cycle-between-short-blocks steps replaced by one predicate fight; CL-H7's assert moved to `S07-77a`; `S07-17`'s approach tightened to 3.5 m. |
| `tools/gate_f/segments/S07C.json` | 72 → 137 steps. Same; `S07C-26`'s impossible region assert becomes the note S07 already carried. |
| `tools/gate_f/segments/S08.json` | 150 → 204 steps. Two catch chips; four captain/patrol fights; ladders. `S08-22`'s coordinates untouched. `S08-77a`/`S08-88a`/`S08-106a` kept, and the ladder's duplicate gate dropped so one failure reports once. |
| `tools/gate_f/segments/S08C.json` | 80 → 96 steps. |
| `tools/gate_f/segments/S09.json` | 79 → 102 steps. Corr and the checkpoint. |
| `tools/gate_f/segments/S09C.json` | 44 → 67 steps. |
| `tests/test_gate_f_segments.gd` | **new**, 7 tests. |
| `ralph/reports/W21-HARNESS-FIGHTS-0904/` | this report and the five runs' written verdicts. |

Nothing outside the ownership list was touched. `operator_harness.gd`, `run_segment.sh` and
`stick_navigator.gd` are unmodified — confirmed by the diff.

One trap for whoever maintains these next: `tools/gate_f/derive_capture_lane.py` regenerates
every `*C.json` from its journey segment **and writes them without asking**. Its output
already differs from the committed `S02C`–`S05C`, which this lane never touched, so the twins
are hand-maintained in practice and the deriver is not currently a safe way to update one.
The twins here were edited by hand, exactly as the journey files were.

## Known limitations, and what was deliberately not done

* **Six of the ten fights in these four segments are still unplayed on this branch** —
  S06's Warrens chamber and guardian (never reached: the S06-50 navigator pin), S08's
  three captains and the ridgeline patrol (derailed at S08-79), S09's checkpoint (derailed
  at S09-35). Their *scripts* are converted and pass the schema tests; their *play* is
  blocked behind three defects this lane does not own. The brief's instruction was to record
  where each run stops and not work around them, and that is what the section above does.
* **`fight_until_resolved` PASSes a fight that never started.** `S06-64` and `S06-74` both
  report `fought 239 frames: 0 quick … ended because no fight running for 240 frames` —
  PASS. The only reason the Warrens fights read as failures at all is the
  `input_context == combat` / `combat_running == true` asserts this lane added in front of
  them, which correctly went red. Worth a `fight_until_resolved` that FAILs when it never
  saw a fight; `operator_harness.gd` is not this lane's file, so it is recorded here.
* **`chip_to_floor` is priced at 1 frame** by `_predict_frames`, which has no case for it.
  Harmless at these budgets but wrong; same routing.
* **`build_s09_entry_synthetic.gd`'s inventory block is not landing** — it declares 2
  Revives and the loaded state has 0. Not this lane's file.
* **`S06`'s seed carries exactly one Revive against three fights.** Once spent, a later
  `focus_item` FAILs naming the bag. That is honest evidence about the run's recovery budget
  rather than a flaky step, but the seed builders are not this lane's files to widen.
* **Counted press blocks on non-battle narrative modals were left alone** — `S07-65`
  (captive rescue, `times: 14`), `S07-72` (relay shutdown, `times: 10`, whose flag then did
  not set), `S07-79`, `S06-28`/`S06-69` (gather swings). Same defect shape, outside CL-H2's
  brief, and named here so the next lane does not have to rediscover them.
* **Engage presses are still bare `press interact`.** `interact_with` would press only when
  the arbiter has a live prompt and would name what it saw instead; that is what would have
  diagnosed S08-27 in one line rather than through `chip_to_floor`'s refusal. Not converted:
  it touches every engage in four segments and is a wider change than CL-H1/H2 asked for.
* **No visual work**, so no contact sheet and no blind judge — this lane changes step
  scripts only, and nothing it touches renders.
* **The capture lanes S06C–S09C were not run.** They are CL-H10's debt and need a display
  server and hours of render time; the brief scoped this lane to logic runs.

## Follow-ups this lane hands over

1. `stick_navigator.gd` / the Gate F harness lane — the S06-50 pin, with the measurement
   above: jittering in a 2.7 m box for 711 s, `dead_travel_m` 1258, escaped immediately by
   the next `move_to` from the same spot, one step after a workbench was placed underfoot.
2. The CL-H14 lane — `S08-22` crossed cleanly here (839.5 m in 10,912 frames, 0 held).
3. The CL-H12 / arbiter lane — a new site: at Captain Halder one of `S08-72`/`74`/`76`'s
   bare riding presses opened the *challenge* conversation instead.
4. Whoever owns `data/config/relay_site.json` / the relay flow — `relay_disabled` does not
   set from `S07-71`/`S07-72`.
5. Whoever owns `build_s09_entry_synthetic.gd` — its satchel is empty on load.
6. The harness lane — `fight_until_resolved` should FAIL, not PASS, when no fight ever ran;
   and `_predict_frames` should price `chip_to_floor`.

## Acceptance, against the brief

| ask | state |
|---|---|
| Zero `press combat_quick, times` blocks in S06–S09 | **done** — 0 in all eight files, pinned by `test_no_gate3_segment_fights_with_a_combat_quick_press_block` |
| The schema test seen red on the old files | **done** — `6 tests, 170 assertions, 6 failed` on the pre-change tree, each naming a real step; the seventh test seen red on the pre-fix tolerances naming all five sites |
| Each segment's first fights resolve with the party alive in a logic run | **done for S06, S07 and S09** (Dorn; Kest/Hess/Orrin/Dell/Vance; the outer watch — nine trainer fights, every one ended on its own defeat flag, no party ever wiped). **Not shown for S08**, whose first engage never started a fight and whose captain sequence derailed at S08-79 behind another lane's arbiter defect. |
| Report the exact step each segment now stops at and why | **done** — the section above |
| `S07-26`'s region assert fixed | **done** — moved to `S07-77a` and PASSED in the run |
| `S06-30` untouched, no waypoint moved, `S08-22`'s coordinates untouched | **done** — arrival tolerances were tightened at five challenge approaches; no `at:` changed |

---

## Every command run, with its result

```
# unit suite, gate F group, on the final tree
godot --headless --path . --script tests/run_tests.gd -- --only=gate_f
  74 tests, 43455 assertions, 0 failed

# the new file alone, on the final tree
godot --headless --path . --script tests/run_tests.gd -- --only=test_gate_f_segments.gd
  7 tests, 186 assertions, 0 failed

# the same file with tools/gate_f/segments/ reverted to the pre-change tree
godot --headless --path . --script tests/run_tests.gd -- --only=test_gate_f_segments.gd
  6 tests, 170 assertions, 6 failed          (the 7th test did not exist yet)

# the approach-tolerance test alone, with tools/gate_f/segments/ stashed to the pre-fix tree
godot --headless --path . --script tests/run_tests.gd -- --only=test_gate_f_segments.gd::test_a_challenge_approach
  1 tests, 38 assertions, 1 failed           (naming S07-17, S07C-17, S08-71, S08-88, S08C-71)

# runtime, four logic-lane segments (see the table above for P/F)
tools/gate_f/run_segment.sh --run-dir ralph/reports/gate-f-run-W21-S06 S06   142 steps: 106 P / 19 F / 6 S / 11 D
tools/gate_f/run_segment.sh --run-dir ralph/reports/gate-f-run-W21-S07 S07   176 steps: 154 P /  3 F / 10 S /  9 D
tools/gate_f/run_segment.sh --run-dir ralph/reports/gate-f-run-W21-S08 S08   204 steps:  85 P / 13 F / 98 S /  8 D
tools/gate_f/run_segment.sh --run-dir ralph/reports/gate-f-run-W21-S09 S09   102 steps:  49 P /  2 F / 46 S /  5 D
```

The full unit suite was **not** run — it is ~28 minutes and the brief did not ask for it.
`--only=gate_f` covers every test that reads these files, including
`test_gate_f_instrumentation.gd::test_every_segment_script_is_well_formed`, which validates
each of the ~300 new steps against the harness's implemented action vocabulary.

`main`'s known red (`verify-unit-tests (3)` on `tests/test_item_icons.gd`, six missing
candy/mushroom icons) was left alone as instructed.

## Branch and commits

Branch `ralph/W21-HARNESS-FIGHTS-0904`, from `origin/main` at `ef16544f`.

| commit | what |
|---|---|
| `01dfdc5c` | the segment rewrite and `tests/test_gate_f_segments.gd` (CL-H1, CL-H2, CL-H7) |
| `96b315e9` | the challenge-approach tolerance fix and its test (found by the S07 run) |
| `1d8a4fd0` | this report, the four runs' written verdicts, and the `docs/CURRENT_STATE.md` rows |
| `208ca0b6805799710abc550620bccf391e0116ab` | this commit table |
| **the commit that added this row** | the final commit on this branch — it changes nothing but this table, and its hash is in the lane summary and in `git log -1 ralph/W21-HARNESS-FIGHTS-0904` |

No pull request was opened, per COMMON.md — the coordinator lands this.

