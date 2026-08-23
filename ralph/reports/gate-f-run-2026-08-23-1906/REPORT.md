# Gate F — full-chapter run, 2026-08-23 19:06

Produced by `tools/gate_f_chapter_run.py` on `/root/godot-bin/Godot_v4.7-stable_linux.x86_64`.

**Continuity of this record.** One report, three processes. The world is continuous inside each segment — in particular the corridor walks band 1 through band 5 in a single boot with one dead-walk counter carried across the band handoffs. The save is not yet carried between segments: the head starts a genuine fresh game at the title, the tail grants a finale-level five. That seam closes when `ralph/GATEB-PATH` lands and the head can write a South Bridge save for the tail to load.

## Segments

| # | segment | verdict | wall time | covers |
|---|---------|---------|-----------|--------|
| 1 | Gate B — title through the village tournament to South Bridge | **FAIL** (exit 1) | 3.7 min | title, fresh save, opening, first catch, team, tools, gathering, villagers, home, creature bed, sleep, tournament, South Bridge |
| 2 | D corridor — South Bridge through band 1..5 to the Hall approach | recorded | 1.3 min | band1 Lower Meadows, band2 Quarry/Warrens, band3 River/Relay, band4 Upper Meadows, band5 Stronghold approach |
| 3 | Gate E — Hall entry through the Warden, legendary and world healing | PASS | 5.6 min | patrol, courtyard, recovery point, elite, shutter, Warden, lever, legendary offer, release ceremony, region answer, post-win chain end |

Harness wall time: **10.5 min**.

Harness wall time is not the player's 3–4 hours and must never be reported as it: the head grants the tournament's team rather than grinding six levels, the corridor steps its route instead of walking it at 4 m/s, and the tail tops fighters up. The player-time estimate is built from the corridor's own metres and the beat table below, not from this clock.

## head — Gate B — title through the village tournament to South Bridge

`tests/smoke_gate_b_continuous.gd` → `head.log`

From the segment's own output:

```
GATE B +143.40s — opening | title interactive
GATE B +143.40s — opening | new game world entered
GATE B +143.40s — opening | wake/Get Up complete
GATE B +143.40s — opening | Grandpa briefing and pack complete
GATE B +143.40s — opening | starter selected and named
GATE B +143.40s — opening | usable house/front doorway exited
GATE B +143.40s — opening | tutorial Bramblebun combat entered
GATE B +143.40s — opening | Bramblebun naturally weakened to 33/124 HP
GATE B +143.40s — opening | satchel drained to 1 orb(s) so the empty case is on the real path
GATE B +143.40s — opening | running dry restocked the tutorial satchel to 5 orb(s)
GATE B +143.40s — opening | physical landed throw caught Bramblebun on launch 2 (2 strike(s), 0 miss(es))
GATE B +143.40s — opening | catch complete; exploration resumed with two-creature party
GATE B +143.40s — opening played; player stands where the game left them, at (20.0, 1.0, -29.0)
GATE B +143.49s — team of 3 at level 6 qualifies for the tournament
GATE A NPC/GATHER +12.90s — Tam cycle 1 exited and movement resumed
GATE A NPC/GATHER +12.90s — Tam handed over axe, pickaxe, knife and torch through dialogue
GATE A NPC/GATHER +16.28s — Satchel assigned four tools by focused controller input
GATE A NPC/GATHER +18.73s — axe equipped, swung, gathered +4 Wood
GATE A NPC/GATHER +21.16s — pickaxe equipped, swung, gathered +3 Stone
GATE A NPC/GATHER +24.60s — knife equipped, swung, gathered +4 Fiber
GATE A NPC/GATHER +42.68s — Oskar cycle 1 exited and movement resumed
gate B continuous FAIL: village tools: could not reach or activate door 'Door' in 1200 frames (player 3.6m away at (18.0, 1.0, -6.0), door at (15.0, 1.0, -3.0), prompt enabled=true, arbiter winner=EncounterDirector). A distance that does not shrink across runs is the player walking into geometry, not walking slowly.
gate B continuous FAIL: village tools: could not naturally enter Mira's building
ERROR: could not reach or activate door 'Door' in 1200 frames (player 3.6m away at (18.0, 1.0, -6.0), door at (15.0, 1.0, -3.0), prompt enabled=true, arbiter winner=EncounterDirector). A distance that does not shrink across runs is the player walking into geometry, not walking slowly.
ERROR: could not naturally enter Mira's building
ERROR: village tools: could not reach or activate door 'Door' in 1200 frames (player 3.6m away at (18.0, 1.0, -6.0), door at (15.0, 1.0, -3.0), prompt enabled=true, arbiter winner=EncounterDirector). A distance that does not shrink across runs is the player walking into geometry, not walking slowly.
ERROR: village tools: could not naturally enter Mira's building
```

## corridor — D corridor — South Bridge through band 1..5 to the Hall approach

`tools/_probe_gate_f_corridor.gd` → `corridor.log`

Measurements:

```
band=band1_lower_meadows metres=2403 minutes=10.0 met=126 worst_gap_m=100 gather=17 key=1 tm=2 trainer=2 wild=104
band=band2_stone_and_root metres=2653 minutes=11.1 met=97 worst_gap_m=165 gather=19 trainer=2 wild=76
band=band3_the_river_lock metres=2375 minutes=9.9 met=100 worst_gap_m=163 gather=4 trainer=5 wild=91
band=band4_upper_meadows_ironwood metres=3436 minutes=14.3 met=195 worst_gap_m=156 gather=9 trainer=2 wild=184
band=band5_stronghold_approach metres=651 minutes=2.7 met=53 worst_gap_m=64 gather=2 trainer=3 wild=48
band=CHAPTER metres=11519 minutes=48.0 met=571 worst_gap_m=165 worst_gap_at_m=4782 worst_gap_band=band2_stone_and_root tail_m=21 gather=51 key=1 tm=2 trainer=14 wild=503
band=GROUNDING wilds=909 underground=0 pct=0.0 worst_m=0
```

From the segment's own output:

```
  longest stretch meeting nothing new, inside this band: 100 m
  longest stretch meeting nothing new, inside this band: 165 m
  longest stretch meeting nothing new, inside this band: 163 m
  longest stretch meeting nothing new, inside this band: 156 m
  longest stretch meeting nothing new, inside this band: 64 m
corridor walked: 11519 m  (~48.0 min at 4.0 m/s)
things met within 30 m of the route: 571
by kind: gather 51, key 1, tm 2, trainer 14, wild 503
longest stretch meeting nothing new: 165 m (~0.7 min), ending at 4782 m along, in band2_stone_and_root
dead-walk intervals >= 250 m (0):
grounding: 0 of 909 wild bodies are >2m under their terrain (0.0%), worst 0m
```

## tail — Gate E — Hall entry through the Warden, legendary and world healing

`tests/smoke_gate_e_finale.gd` → `tail.log`

From the segment's own output:

```
arrived at the Hall with 5 creatures
walked in from the entrance; 13.5m from the Outer Works' centre
  beat stronghold_patrol; tracked objective now 'Fight through the guard inside Meadows Hall. 1/3'
  beat stronghold_courtyard; tracked objective now 'Fight through the guard inside Meadows Hall. 2/3'
  rested a fainted creature at the recovery point: 16.4/196 hp back
  beat stronghold_elite; tracked objective now 'Defeat the Meadows Warden.'
the shutter lifted once the elite fell
read the reveal on the threshold, before the Warden
[meadow] the tether let go: 115 plants back, 17 tether lights out, 0 barriers open, 4 beaten patrols withdrawn
[climax] the belt is full; R4.10's release ceremony has the decision
the legendary is freed and 'legendary_freed' is set once
the decision resolved: 'Kettle' released, the legendary on a belt of five
the roster decision is recorded; tracked objective now 'Go back through the Meadows and see what changed.'
the region answered: 115 plants back, 17 tether lights out, 0 barriers open, 4 patrols withdrawn
the Meadows acknowledged the victory and the objective chain terminated
gate E finale smoke test passed
```

