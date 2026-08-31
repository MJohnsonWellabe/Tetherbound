# FINDING — CAP-2: the village tutorial ladder cannot be completed

**Reported by:** Gate F capstone-2 operator (tester role; no code, data or config
changed — `GATE_F_MASTER_PROTOCOL.md` §J).
**Candidate:** `679f990c` on `ralph/GATE-F-CAPSTONE-2`, branched from `main` @
`721893a4` (carries the CAP-1 fix `cf4c5ab1`).
**Run:** `ralph/reports/gate-f-run-20260831T185555Z/S03/`
**Severity candidate:** BLOCKER. Fable rules in Phase B.

**This is not CAP-1 recurring.** CAP-1 is fixed and verified — see §1. This is a
different dead end reached further down the same ladder, and it is load-bearing:
S03 is `complete: false`, and it hands S04 a degraded save.

---

## 1. First, the good news: CAP-1 is genuinely fixed

S02 closed 78 PASS / 3 FAIL, and the production exit save the chapter chains
from carries what capstone 1's could not:

| | capstone 1 | this run (`S02-exit.json`) |
|---|---|---|
| party | 1 creature, fainted | 2 creatures, both `fainted: false` |
| inventory | `orb_basic x11`, nothing else | `orb_basic x12`, **`revive x2`** |

The restored `give:revive:2` is present in a save produced by real play. The
starter finished the tutorial fight up rather than down.

---

## 2. What happens in S03

`315 PASS · 29 FAIL · 9 SKIP · complete=false · no derail · no harness errors`

Three fights, all lost.

| fight | t (play s) | who fought | entered at | ended |
|---|---|---|---|---|
| 1 | 203.70 – 226.78 | Moss (ripplet) | **53.0 / 117.6** | faint t=225.17, opponent left at 51.7 / 93.7 |
| 2 | 349.25 – 371.62 | Bramblebun | **66.2 / 106.2** | faint t=370.50, opponent left at **10.2 / 100.7** |
| 3 | 544.42 – 571.45 | Moss, revived to 58.8 | **58.8 / 117.6** | faint t=571.45, opponent at **106.19 — untouched** |

Fight 2 is the near miss: the opponent was taken to 10.2 of 100.7 and the fight
was still lost.

### The cascade

`S03-32a2` (attempt 1) pressed a **real** engage prompt — the note records
`pressed 'interact' on "… Engage Bramblebun"` — and PASSed. Fight 1 followed and
the starter went down. From attempt 2 onward the live prompt is:

> **"Ripplet is out of the fight."**

and `S03-32b2` … `S03-32j2` — **nine consecutive attempts** — each correctly
REFUSED to press, because the step is built to refuse misfiring into a
fainted-ally message rather than mash into a different provider (RIG-17). The
nine `S03-36b…36j` "begin the aim" steps are the 9 SKIPs: the aim never had a
challenge to follow.

The team therefore never grows, and every rung after it fails in sequence:

| step | assertion | actual |
|---|---|---|
| `S03-39` | the team is five | `party size 2` |
| `S03-105` | village budget covered the home | `flag home_materials_gathered NOT set` |
| `S03-173` | the home stands | `flag home_built NOT set` |
| `S03-205` | the creature bed stands | `flag creature_bed_built NOT set` |
| `S03-228` | the player slept at home | `flag player_slept_at_home NOT set` |
| `S03-260` | the whole team is fed | `flag tournament_team_fed NOT set` |

and the tracked objective never leaves `tournament_team_ready` — *"Build your
full team of five for the village tournament."* — which is the correct
instruction for a player who genuinely has two.

### The handoff S04 inherits

`saves/S03-exit.json`:

```
party      Moss  (ripplet,   lvl 3)  hp 0.0   / 117.6   fainted: TRUE
           Bramblebun (lvl 2)        hp 53.1  / 106.2   fainted: false
inventory  orb_basic x8, axe, pickaxe, knife, torch, stone x8, wood x12,
           berries x6, coin x30      -- NO revive
```

Both Revives are spent (present at t=185.85, gone by t=423.85). The tournament
segment is entered with a fainted starter, a team of two against a required five,
no revive, and not one tutorial rung complete.

---

## 3. Two things the evidence shows that the operator is NOT diagnosing

Recorded because they are facts in the telemetry, and left for Phase B:

1. **The party enters S03 at 45% HP with no healing item.** Moss starts fight 1
   at 53.0 / 117.6 — the damage from S02's tutorial catch, never healed. CAP-1's
   fix deliberately restored Revives but *not* potions or berries ("a pacing
   question about the opening's supply"). A Revive returns a fainted creature at
   50% (`58.8 = 117.6 x 0.5`); nothing in the player's possession heals a
   *living* one. Berries are gathered at t=457 but the team-feed rung never runs.

2. **Zero `catch_throw` events in the whole of S03, while four orbs are
   consumed** (`orb_basic` 12 → 11 → 8). Fight 3 sits in `input_context =
   combat_aim` from t=548.12 to t=571.45 — the entire fight — and the opponent's
   HP never moves off `106.191112967968` across ten hits taken. Whether that is
   an unemitted event (a CD-6-class instrumentation gap: the type is in the §C.1
   enum), a throw that does not register, or a rig that armed the aim and never
   released it, is not the operator's call.

**Relationship to `TOURNAMENT-SEMI-DIFFICULTY`:** unknown and not asserted. That
item is at the tournament (S04); this is the S03 village training fights. They
may or may not be the same family.

---

## 4. Reproduction

```
git checkout -B ralph/GATE-F-CAPSTONE-2 origin/main
godot --headless --path . --import                      # ~25 min
tools/gate_f/run_chain.sh --run-dir <fresh-dir> S01 S02 S03
```

`S01` and `S02` pass; `S03` reproduces the above. A run directory must carry its
own §A.2 `RUN_METADATA.json` with a `lanes` block or every segment refuses at
pre-flight — see `ralph/reports/gate-f-run-20260831T185309Z/BLOCKER_RUN.md`.

Primary evidence, all committed:

- `gate-f-run-20260831T185555Z/S03/telemetry/events.jsonl` — the three fights
- `.../S03/notes/S03.md` — 29 FAIL blocks with expected/actual
- `.../S03/saves/S03-exit.json` — the degraded handoff
- `.../S02/saves/S02-exit.json` — CAP-1 confirmed fixed

---

## 5. Operator disposition

Recorded, not patched (§J). The chain was allowed to continue into S04 so the run
produces a full account rather than stopping at the first red (§1.6), **but every
segment from S04 on is downstream of the degraded handoff in §2 and must be read
with that caveat** — the same shape of contamination CAP-1 produced in capstone 1,
where S03 alone showed 28 failures cascading from one root cause.

---

## 6. S04 confirms the contamination — and it is NOT `TOURNAMENT-SEMI-DIFFICULTY`

`53 PASS · 18 FAIL · 0 SKIP · complete=true · no derail`

Every one of the eighteen failures is downstream of §2's handoff. The gate that
stops it is the entry requirement, not any fight:

| step | actual |
|---|---|
| `S04-10` the team travelled | `party size 2 (wanted >= 3)` |
| `S04-21` the team met the entry size | `flag tournament_team_ready NOT set` |
| `S04-22` the team met the training bar | `flag tournament_training_ready NOT set` |
| `S04-23` the team is in condition | `flag tournament_condition_ready NOT set` |
| `S04-24` the sign-up took | `flag tournament_entered NOT set` |

and then, for all three matches alike:

| step | actual |
|---|---|
| `S04-28f` a fight is actually running (quarter) | `combat_running=false` |
| `S04-36f` a fight is actually running (**semi**) | `combat_running=false` |
| `S04-43f` a fight is actually running (final) | `combat_running=false` |

**No tournament match ever started.** `input_context` stays `world` through the
quarter, the semi and the final; the objective never leaves *"Build your full
team of five for the village tournament."*

Two consequences worth stating plainly:

1. **`TOURNAMENT-SEMI-DIFFICULTY` did not resurface here and this run says
   nothing about it.** That item is about the difficulty of a semi-final that is
   fought. This run never signed up, so no semi-final existed to be hard. The
   backlog item is neither confirmed nor cleared by this evidence, and must not
   be read as either.
2. **S04 is uninformative about the tournament as a player experience.** Its 53
   PASSes are the walk to the ground and the surrounding scaffolding, not the
   event. Nothing about tournament pacing, difficulty, or presentation can be
   sourced from this segment.

This is the same shape of downstream contamination CAP-1 produced in capstone 1.
The correct disposition once CAP-2 is fixed is a restart from the last clean
handoff — `S02-exit.json`, which is good — **not** a continuation from any save
at or after S03.

---

## 7. S06: the chapter is walled at the South Bridge — bands 2–5 are unreachable

`76 PASS · 19 FAIL · complete=true · no derail · no harness errors · 2469 s wall`

Ten of S06's nineteen failures are `did not reach` on a walk. Their stop
positions are the finding:

| step | target | stopped at |
|---|---|---|
| `S06-17` quarry picket | (315, 1668) | (8.0, **-2.0**, **1317.0**) — 466.3 m short |
| `S06-24` Old Quarry | (403, 1794) | (5.0, -3.0, **1322.0**) — 617.7 m short |
| `S06-50` Warrens mouth | (-420, 2470) | (8.0, -3.0, **1318.0**) — 1229.2 m short |
| `S06-55` mouth chamber | (-357, 2616) | (8.0, -3.0, **1317.0**) — 1349.1 m short |
| `S06-58` hall chamber | (-357, 2632) | (8.0, -2.0, **1317.0**) — 1364.7 m short |
| `S06-68` side chamber | (-373, 2632) | (14.0, -3.0, **1323.0**) — 1365.0 m short |
| `S06-70` the den | (-357, 2650) | (10.0, -3.0, **1320.0**) — 1380.2 m short |
| `S06-81` the vault | (-342, 2650) | (15.0, -6.0, **1325.0**) — 1371.9 m short |
| `S06-83` back out | (-357, 2616) | (15.0, -3.0, **1321.0**) — 1347.2 m short |
| `S06-84` ranger camp | (-259, 2256) | (12.0, -5.0, **1324.0**) — 971.2 m short |

**Every one stops in the same place: x ≈ 8–15, z ≈ 1317–1325.** The South Bridge
is at z = 1330. `S05-56` failed at (3.0, -3.0, 1319.0), the same spot.

`route.csv` settles it. Across 4,340 rows and **10,031.7 m walked**:

```
z range        0.0 .. 1327.8      (the bridge is at 1330)
regions        corridor 4338 rows, grandpas_village 2 rows
band-2 regions the_old_quarry 0, the_burrow_warrens 0
```

The player walked ten kilometres and never crossed. `S06-88` records the
consequence exactly: *"dead_travel peaked at 0.6 m this segment (wanted >=
150.0); 10031.7 m walked in total"* — ten kilometres of walking into a shut gate
registers as no dead travel at all, because the player never got far enough from
a POI for the counter to start.

### Reading

This is consistent with **inherited CAP-2 contamination, not a new pathing
defect**: `south_bridge_open` is NOT set (`S05-55`), because the bridge gate
fight never ran (`S05-48f` `combat_running=false`), because the party cannot
fight. A shut gate that will not let the player through is the game behaving
correctly given the state §2 put it in. The alternative reading offered for
`S05-56` in the operator log — that the walk fails on its own terms — is now the
less likely of the two, though the operator still does not choose.

### What this costs the run

**Bands 2, 3, 4 and 5 have no evidence in this run, and cannot.** S07 (River &
Relay), S08 (Upper Meadows), S09 (Stronghold approach) and S10a–e (the finale)
all begin north of a crossing this save cannot make. Nothing about those regions'
pacing, navigation, combat, encounters or presentation may be sourced from this
run's remaining segments — the same way §6 makes S04 uninformative about the
tournament.

The 2,469 s S06 spent is largely a navigator retrying unreachable targets —
`S06-50` alone burned **44,100 walking frames**. That is a cost observation about
the rig, not a game defect.
