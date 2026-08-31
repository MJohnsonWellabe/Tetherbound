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
