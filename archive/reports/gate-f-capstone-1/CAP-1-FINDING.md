# CAP-1 — the mandatory tutorial catch can end with a dead solo party, and the chapter lets the player walk on

**Run:** `ralph/reports/gate-f-capstone-1` (GATE-F-CAPSTONE-1)
**Candidate:** `88df9f47` — nine Gate F leg lanes consolidated on `main`, CI green, 1675 tests, 0 failed
**Segment:** S02, steps S02-32 … S02-46. **Main-chain rung 4 of 27** (`opening_first_catch`)
**Severity candidate:** SHIP / BLOCKER-for-the-chapter. Phase B rules (protocol §C.1).
**Reproduced:** 4 independent fresh runs — **2 of 4 end in the unrecoverable state.**

---

## 1. The one-paragraph version

The opening's mandatory first catch is a real fight in which your creature is
undefended while you aim — that is the design, and it is stated as such in
`data/config/catching.json`. The tutorial is protected against two ways of
failing it: `max_catch_failures: 1` guarantees the catch on the second **landed**
throw, and `catch_orb_floor: 5` guarantees you never run out of orbs. **It is not
protected against the third way: missing repeatedly while the wild creature kills
your only creature.** When that happens the fight ends with a party of one
fainted creature — and nothing stops the player continuing. The road gate is not
gated on the catch, so rung 5 completes while rung 4 stays open, and from that
state `can_challenge()` refuses every engagement in the game. The chapter is over
at rung 4 of 27 and never says so.

---

## 2. Exact reproduction

No special state. This is a fresh new game on production paths, `free_build` off.

```bash
GODOT=~/.cache/tetherbound-art/godot
$GODOT --headless --path . --import          # once
tools/gate_f/run_segment.sh --run-dir <a fresh dir> S02
```

`tools/gate_f/segments/S02.json` is the script. In player terms, S02 is: wake
upstairs, hear Grandpa out, take and name the starter, walk out to the practice
meadow at ~(30,-40), engage the grazing bramblebun, open with a charged attack
and three quick attacks, then aim and throw basic orbs.

Then read the outcome out of the segment's own exit save:

```bash
python3 -c "
import json,sys
d=json.load(open(sys.argv[1]))
print('party', [(c['nickname'], c['species_id'], c['fainted'], round(c['hp'],1)) for c in d['party']])
print('first_catch rung done:', 'opening:beat:road' in d['progression']['flags'])
print('road gate open:',        'road_gate_open'    in d['progression']['flags'])
" <dir>/S02/saves/S02-exit.json
```

### The four runs

| run | throws | **landed** (a `catch_result` verdict) | caught? | starter | rung 4 flag | rung 5 flag |
|---|---|---|---|---|---|---|
| capstone S02 | 4 | **0** | no | **fainted, hp 0** | **not set** | **set** |
| repro attempt-1 | 2 | 1 | **yes**, on the 2nd throw | ok, 79.6 hp | set | set |
| repro attempt-2 | 4 | **0** | no | **fainted, hp 0** | **not set** | **set** |
| repro attempt-3 | 2 (+2 after) | 2 | **yes**, on the 2nd **landed** throw | ok at that point | set | set |

Reproduction artefacts: `ralph/reports/gate-f-capstone-1-repro/attempt-{1,2,3}/`.

**The bound is not broken.** In both runs where throws landed, the catch happened
on the second landed throw — attempt-3 shows it exactly: throw 1 landed and
failed (t=233.18 → verdict t=237.62), throw 2 landed and caught (t=239.75 →
verdict t=244.23 → `party grew 1 -> 2` t=246.75). That is `max_catch_failures: 1`
behaving precisely as documented.

**The failure mode is the miss.** In the two failing runs, four throws produced
**no `catch_result` verdict at all**. Across all four runs only **3 of 12**
tutorial throws produced a verdict.

---

## 3. What the failure actually looks like, frame by frame

From `S02/telemetry/events.jsonl`, play-clock seconds (capstone run):

| t | event |
|---|---|
| 224.02 | `combat_start` — Ripplet "Moss", L3, 117.6 hp vs bramblebun 106.2 hp |
| 229.32–230.45 | charged + quick land: bramblebun 106.2 → **63.5** |
| 234.07 | throw 1 — `lost [orb_basic -1]` — **no verdict** |
| 240.65 | throw 2 — `lost [orb_basic -1]` — **no verdict** |
| 247.18 | throw 3 — `lost [orb_basic -1]` — **no verdict** |
| 253.65 | throw 4 — `lost [orb_basic -1]` — **no verdict** |
| 230.83 → 270.60 | **18 consecutive unanswered hits**, ~6.5 dmg each, over 40 s |
| 270.60 | `faint` — "Moss fainted". Bramblebun still at 63.5 hp |
| 272.22 | `combat_end`, `input_context` combat → world. **No defeat beat, no consequence, no recovery prompt.** |

The 40 seconds of unanswered damage are not a bug in isolation —
`catching.json` says so outright: *"Your creature is undefended while you aim and
the opponent does not stop attacking it. That cost is the whole design."* The
defect is that nothing bounds the cost when the throws keep missing.

---

## 4. The save state at failure, and exactly what was and was not gated

`S02/saves/S02-exit.json` — the real exit save the next segment chained from:

```
party:      1 creature — "Moss" (ripplet), level 3, hp 0.0 / 117.6, fainted: true
inventory:  orb_basic x11  (15 given, 4 spent)
flags (11): opening:beat:wake, opening:beat:house, opening:beat:choose,
            opening:starter_granted, opening:beat:name, opening:beat:return_starter,
            tournament_team_fed, opening:beat:walk_out, opening:beat:encounter,
            pickup:castle_gate_key, road_gate_open
```

Against `data/progression/objectives.json`:

| rung | id | flag | state |
|---|---|---|---|
| 1–3 | `opening_hear_grandpa` … `opening_show_grandpa` | beat:choose / return_starter / walk_out | done |
| **4** | **`opening_first_catch`** | **`opening:beat:road`** | **NOT SET** |
| **5** | **`open_road_gate`** | **`road_gate_open`** | **SET** |

**Rung 5 completed while rung 4 stayed open.** Neither the key pickup nor the
gate conversation is gated on the catch, so a player who loses the tutorial fight
takes the key, opens the gate, and walks into the village behind a tracked line
that still reads *"Catch your first wild creature."* It never changes again.

### The downstream lock, measured

S03 booted this save and the fainted state restored faithfully. From it:

- **10 consecutive attempts to engage a wild bramblebun found no prompt at all**
  (S03-32a2 … j2, all in `world` context, *"no interact prompt is live"*). The
  walk reached a live creature each time; the offer was not there.
- Team never grew: `party size 1 (wanted >= 5)`.
- Seven separate rung assertions all read back rung 4.
- S04 reached the tournament with 1 fainted creature against
  `tournament.json`'s `min_party_size: 5`; `input_context` never became
  `narrative_modal` or `combat` anywhere in the segment.

**The game does explain the lock**, and this is worth recording because
`S03.json`'s own expected-text says it does not: at t=318.20 the trainer says
*"Your creature can't fight like this. Get it back on its feet first — a bed will
do it, or s…"* and *"Come find me again once you've got something to send out."*
That is a specific, correct, actionable line. The lock is legible; what is
missing is a way out of it that this run could confirm.

---

## 5. Best diagnosis — flagged as outside the operator role

Protocol §J says the operator does not diagnose root causes; Phase B does. This
section is written because the coordinator asked for it, and it is labelled a
**hypothesis** so it cannot be mistaken for a measurement.

**Why the player is allowed past.** The opening's protections are attached to the
*catch*, not to the *encounter's outcome*. `sequence_director.gd` opts the
encounter into the landed-throw bound and hangs an orb floor off the refusal
path; both answer "the player cannot get the catch". Neither answers "the
player's only creature died trying". And the road-gate beat is driven by the key
and the Grandpa conversation, which have no dependency on `opening:beat:road`, so
the ladder can be overtaken. My reading is that the three systems are individually
correct and the gap is between them: **there is no owner of the question "the
mandatory encounter ended badly — now what?"**

**Why the throws miss.** I can bound this only weakly and will not assert it.
Three quarters of the tutorial throws in these runs produced no verdict.
`catching.json`'s own comments record that this area is already known-fragile:
OP-0830-5 ("catching is way too hard"), `tools/_probe_catch_rate.gd` measuring a
median placement of 0.375 m against a 0.325 m bramblebun body radius over 47
landed throws, and the explicit note that the residual is *"the target moving
during the orb's flight, which the launch prediction leads but cannot cancel; it
is not player error"*. **But the aim here is synthetic** — protocol §0.1 marks
input ENV-PARTIAL, and an agent's scripted aim is not a human's. A 25 % land rate
may be substantially the harness's aim, not the game's. **Whether a human misses
this often is [OWNER-ONLY] and this run does not claim it.**

**Why that caveat does not weaken the finding.** The gating defect in §4 does not
depend on the miss rate at all. Whatever makes the encounter go badly — misses, a
bad matchup, a distracted player — the outcome is the same: the chapter continues
past an ungated rung into a state where nothing can be engaged.

### What a fix probably has to decide

Not the operator's call, listed so the fix lane has the question, not the answer:

1. Does the tutorial encounter guarantee the *outcome* (revive/restore on a lost
   practice fight) as well as the catch?
2. Or does rung 5 become gated on rung 4, so a lost fight blocks rather than
   strands?
3. Or is the recovery path (bed / Revive draught) made reliable and pointed at?
   **This run never confirmed any recovery path works** — see the open question
   below, which is the single most valuable thing to settle next.

---

## 6. The open question this run did NOT answer

**The trainer promises "a bed will do it". Does it?**

Not established. All three recovery paths came back unproven, and two of the
three failures are my instrument's fault, not the game's:

| path | result | trustworthy? |
|---|---|---|
| Revive draught from the Satchel | S03-51e/51f FAIL | **No.** A fixed ×10 `interact` (CD-3) held a `DialoguePanel` open from t=321.15 to t=358.45 — 37 play-seconds spanning exactly these steps. The harness was driving a menu a dialogue owned. |
| Creature bed | S03-205b/c FAIL — live prompt was *"Rest until morning"*, not a creature-bed prompt; the rest panel never opened | unproven |
| Sleep at home | S03-228 FAIL — `player_slept_at_home` never set | unproven |

Whether CAP-1 is a severe setback or an unrecoverable chapter turns entirely on
this, and **this lane declines to grade it from derailed steps.**

---

## 7. Independent defects that are NOT downstream of CAP-1

Recorded here because a fix lane that fixes only CAP-1 will meet these again in
the restarted capstone. Both are **rig**, both are live in the current segment
scripts, and both silently corrupt evidence rather than failing loudly:

- **CAP-5 / CD-3 — fixed press counts are still in the scripts.** S03-32 presses
  `interact` ×10 at a two-line conversation and re-opens it; the telemetry shows
  the modal cycling open/closed four times and then sticking for 37 play-seconds.
  This is the exact defect CD-3 was written about and
  `advance_dialogue_until_closed` exists to prevent. It invalidated the only test
  of the Revive path in the whole run.
- **CAP-6 / CD-5 — coordinate reach plus unchecked press.** S04 reaches the
  tournament marshal with `move_to (20,12)` and presses with a plain `press` that
  never asserts a live prompt, so §E.6.12's "record the exact line shown for each
  unmet state" is **unsatisfiable by that segment as written** — 23 presses
  produced no dialogue and no `narrative_modal`, and the run cannot tell a silent
  marshal from a player standing out of range. S03's catch loop already uses the
  entity-resolving form that fails loudly; S04's sign-up path does not.

Also, and smaller: **`catch_throw` is never emitted**. `catch_result` *is*
emitted, on a landed throw — which is how the landed/missed column in §2 was
derived. But that derivation is an inference **from absence**, which is precisely
the hazard CD-6 warns about, and it would have been a direct measurement if each
throw emitted its own event with the per-throw record §E.2 asks for (distance,
placement, shown percent, hit/miss and stated reason).

---

## 8. Status of the two questions this lane was sent to answer

- **TOURNAMENT-SEMI-DIFFICULTY — NOT REACHED. No evidence in either direction.**
  S04 never passed the entry gate (party of 1 against `min_party_size: 5`), so no
  tournament round was fought. Nothing in this run supports or refutes the
  reported one-shot behaviour of the semi-final Mosshell.
- **Burrow Warrens guardian (Band 2 completion) — NOT REACHED.** The chain was
  stopped at S05 by recorded operator decision; the South Bridge gate ahead of it
  refuses a fainted-only party outright.
