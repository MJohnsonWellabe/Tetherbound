# GATE-F-CAPSTONE-1 — defects, live log

Run: `ralph/reports/gate-f-capstone-1`, branch `ralph/GATE-F-CAPSTONE-1`,
candidate `88df9f47` (nine Gate F leg lanes consolidated onto `main`,
CI green, 1675 tests).

Severity words follow the Gate F protocol: **BLOCKER** (the chain cannot
proceed), **SHIP** (a player-facing defect a real player would report),
**QUALITY** / **POLISH**, and **RIG** (the instrument, not the game).
Severity here is a *candidate* only — section C.1 gives the final call to Phase B.

Per protocol section 13 / section J this lane changes **no game code, data or
config** and does not diagnose root causes. Every entry is what happened, with
the evidence that shows it.

---

## CAP-1 — the opening's "cannot fail twice" catch failed four times, the starter fainted, and the chapter carried on regardless

**Severity candidate:** SHIP. **Segment:** S02. **Steps:** S02-42 … S02-46.
**Status:** recorded, not fixed (game frozen for this lane).

### What the game promises

`data/config/opening.json` -> `encounter`:

```json
"species": "bramblebun",
"max_catch_failures": 1,
"_comment_catch_bound": "docs/OPENING_SEQUENCE.md says the tutorial catch
  cannot fail twice. This bounds only landed, otherwise-legal throws at this
  configured species while the opening is on its encounter beat."
```

`scripts/story/sequence_director.gd:1171-1180` opts this exact encounter into
`CombatManager.configure_tutorial_catch_assist()` on combat entry, behind an
`_is_tutorial_catch()` beat-and-species predicate.

### What happened

From `S02/telemetry/events.jsonl`, play-clock seconds:

| t | event |
|---|---|
| 224.02 | `combat_start` — Ripplet "Moss" L3, 117.6 HP vs bramblebun 106.2 HP |
| 229.32–230.45 | charged + quick attacks land: opponent 106.2 -> **63.5** |
| 234.07 | throw 1 — `lost [orb_basic -1]`, no catch |
| 240.65 | throw 2 — `lost [orb_basic -1]`, no catch |
| 247.18 | throw 3 — `lost [orb_basic -1]`, no catch |
| 253.65 | throw 4 — `lost [orb_basic -1]`, no catch |
| 230.83–270.60 | **18 consecutive unanswered hits** on Moss, ~6.5 dmg each |
| 270.60 | `faint` — "Moss fainted", opponent still at 63.5 HP |
| 272.22 | `combat_end`, `input_context` combat -> world |

Four landed-or-missed throws, no catch, against a documented bound of one
failure. Orb stock 15 -> 11 confirms four throws were actually spent.

### RESOLVED BY REPRODUCTION — the bound is intact; the miss is the failure mode

The first draft of this entry could not tell a landed throw from a miss and said
so. Three independent fresh S02 runs
(`ralph/reports/gate-f-capstone-1-repro/attempt-{1,2,3}/`) resolved it:

| run | throws | landed (a `catch_result` verdict) | caught? | starter | rung 4 |
|---|---|---|---|---|---|
| capstone | 4 | **0** | no | fainted | not set |
| attempt-1 | 2 | 1 | **yes**, 2nd throw | ok | set |
| attempt-2 | 4 | **0** | no | fainted | not set |
| attempt-3 | 2 | 2 | **yes**, 2nd landed throw | ok | set |

**`max_catch_failures: 1` is NOT broken.** Wherever throws landed, the catch came
on the second landed throw, exactly as documented. Only **3 of 12** tutorial
throws produced a verdict at all, and the two runs that lost the starter landed
none. The uncovered failure is the **miss** — which `opening.json`'s own comment
says the bound deliberately does not cover, while `catch_orb_floor` covers the
other uncovered case (running dry). Missing until your starter dies is the one
way to fail the tutorial that nothing protects against.

**2 of 4 runs end in the unrecoverable state.** This is not a rare path.

Caveat carried forward: the aim is **synthetic** (§0.1, ENV-PARTIAL). A 25 % land
rate may be substantially the harness's aim rather than the game's, and a human
miss rate is [OWNER-ONLY]. The gating defect below does not depend on it.

### What it costs the player, and why the consequence is worse than the fight

The consequence is not the lost fight. It is the state the chapter then carried
forward. `S02/saves/S02-exit.json` — the real exit save S03 is chained from:

- party of **1**, `"fainted": true`, `"hp": 0.0`
- progression flags **without** `opening:beat:road`
- progression flags **with** `road_gate_open`

`data/progression/objectives.json` gives `opening_first_catch` the flag
`opening:beat:road`. So **main-chain rung 4 of 27 is still open while rung 5 is
complete**: losing the tutorial fight gates neither the key nor the gate, and the
player walks into the village behind a tracked line that still reads *"Catch your
first wild creature."* Nothing in the run offered a defeat, consequence or
recovery beat — `combat_end` handed world control straight back with a 0 HP
creature (protocol section E.1 CB-07 expects a defeat -> consequence -> recovery
loop; none ran here because the loss was not the scripted one).

S03's span requires a team of three and a training ladder. It is entered here
with one fainted creature.

### Not a defect, checked and discarded

The harness line `tracked objective id=opening:beat:road text=Catch your first
wild creature.` is **not** an id/text mismatch. The harness reports the
objective's `flag_id`, and `opening_first_catch` legitimately carries
`flag_id: "opening:beat:road"`. Recorded here because it looks like a defect and
is not.

---

## CAP-2 — `catch_throw` is never emitted, so landed-vs-missed is only knowable by absence

**Severity candidate:** RIG. **Segment:** all. **Status:** recorded, not fixed.

**CORRECTED.** This entry first claimed no `catch_result` is emitted for an
in-combat throw. That is wrong: `catch_result` **is** emitted when a throw
resolves to a verdict, and the reproduction above depends on it. The real gap is
narrower and still real:

- **`catch_throw` is never emitted at all** — it is in the §C.1 enum and nothing
  writes it. A throw's only direct trace is an `inventory` delta on a `note`.
- Because of that, "did this throw land?" can only be answered by **the absence
  of a following `catch_result`** — which is exactly the inference CD-6 forbids
  treating as evidence, and which the reproduction table above nonetheless has to
  rely on.
- §E.2's required per-throw record (aim time, distance, target species/size,
  hit/miss **and stated reason**, shown percent, result, party count after) has no
  source. A single `catch_throw` carrying placement and the miss reason would have
  turned this whole investigation into one query.

## CAP-3 — section H's continuous record for S01/S02 has no implementing action

**Severity candidate:** RIG. **Segments:** S01, S02. **Status:** recorded.

Section H makes S01+S02 mandatory continuous-evidence segments ("PNG every 2 s
(0.5 Hz) plus a forced frame on every JSONL event"). The step vocabulary in
`tools/gate_f/SEGMENT_SCHEMA.md` has no background-recorder action —
`capture_seq` is a bounded, blocking run of frames, not a recorder that runs
while other steps play. S01's own step S01-01 records the gap rather than
claiming the record exists, which is the right behaviour; the consequence is
that section H's continuous-evidence clause is **unpaid on this run**, as it was
on previous ones.

---

---

## CAP-4 — a one-creature party that faints is locked out of every engagement; the run could not confirm any recovery path works

**Severity candidate:** SHIP (pending the recovery probe below). **Segment:** S03.
**Status:** recorded, not fixed. **Downstream of CAP-1.**

S03 booted `S02-exit` through the production Load path and the fainted state
restored faithfully (`t=1.05 faint "Moss fainted"`, party 1). From there:

- **Ten consecutive attempts to engage a wild bramblebun found no prompt at
  all.** S03-32a…j2, all at `input_context=world` (t=199.22), all
  *"no interact prompt is live … there is nothing here to interact with"*. The
  walk itself succeeded each time (RIG-16 tracks a live creature's own
  position), so the creature was there and the offer was not.
- The team never grew: S03-39 `party size 1 (wanted >= 5)`.
- **The guided ladder never advanced past rung 4 for the whole segment.** Seven
  separate rung assertions (S03-12, -28, -41, -106, -174, -206, -229) each read
  back `opening_first_catch` / "Catch your first wild creature." `S03-exit.json`
  confirms it: 19 flags, and `opening:beat:road` is not among them.

### What the game gets RIGHT here, recorded because a prior lane's text says otherwise

`tools/gate_f/segments/S03.json`'s own S03-205b expected-text asserts that
`can_challenge()` refuses every fight *"with no error and no on-screen
explanation"*, falling back to the trainer's `defeated` line. **That is not what
this candidate does.** At t=318.20 the trainer says:

> "Your creature can't fight like this. Get it back on its feet first — a bed
>  will do it, or s…"
> "Come find me again once you've got something to send out."

A specific, diagnostic line that names the remedy. The stale claim is recorded
here so the next reader does not inherit it.

### What this run could NOT establish, and why

Whether a player in this state can actually recover. All three paths the game
points at came back unproven:

| path | outcome | trustworthy? |
|---|---|---|
| Revive draught from the Satchel | S03-51e/51f FAIL | **No — rig-caused, see CAP-5** |
| Creature bed | S03-205b/c FAIL: live prompt was *"Rest until morning"*, not a creature-bed prompt; rest panel never opened | needs a probe |
| Sleep at home | S03-228 FAIL: `player_slept_at_home` never set | needs a probe |

Because the trainer explicitly promises *"a bed will do it"*, whether a bed
actually does it is the question that decides this entry's severity — a setback
versus an unrecoverable chapter. **A dedicated recovery probe is owed before
this is graded**, and this lane will not grade it from the journey evidence
alone.

---

## CAP-5 — CD-3's fixed-press-count trap is still live in S03, and it invalidated the revive test

**Severity candidate:** RIG. **Segment:** S03. **Status:** recorded, not fixed
(rig frozen during the run, section J).

Protocol section J, CD-3: *"No step may encode a guessed repetition count for a
state-changing UI. Reach a state, then assert it."* S03-32 presses `interact`
**x10** at a two-line trainer conversation. The telemetry shows the exact
documented consequence — the modal re-opening the conversation the previous tap
closed:

```
t=318.07 world -> narrative_modal      t=319.67 narrative_modal -> world
t=318.88 world -> narrative_modal      t=320.78 narrative_modal -> world
t=320.05 world -> narrative_modal
t=321.15 world -> narrative_modal   <-- stays open
t=321.80 pressed interact x10 (tap)
t=358.45 narrative_modal -> world   <-- 37 play-seconds later
```

S03-51e (t=358.12) then failed with *"inventory did not open the pause shell:
context narrative_modal -> narrative_modal (owner=DialoguePanel)"* and S03-51f
with *"3 x ui_right did not move focus off nothing"*. **Both are the harness
driving a menu that a dialogue owned, not the game refusing to open one** — so
neither is evidence about the Satchel or the Revive draught, and CAP-4 does not
claim them as such.

Section J's own rule is that a step which could not be PERFORMED invalidates the
ones after it. The harness recorded these as FAIL rather than SKIP-with-derail,
which is why the raw 28-FAIL count for S03 overstates the game's fault.

---

## CAP-6 — 23 `interact` presses at the tournament ground with an unready team opened nothing at all

**Severity candidate:** SHIP (with a stated limit). **Segment:** S04.
**Status:** recorded, not fixed.

Protocol section E.6.12 requires: *"Attempt tournament interactions before
requirements met (unrested/unfed/short team): the guided chain should point at
the next missing prerequisite; **record the exact line shown for each unmet
state**."*

S04 arrived at the tournament ground with a party of 1 fainted creature against
`tournament.json`'s `min_party_size: 5`, pressed `interact` at the tournament
board (1 + 8 presses) and at the marshal (1 + 14 presses) — **23 presses** — and:

- **no `dialogue` event fired anywhere in the segment**, though the same
  instrumentation emitted eleven of them in S03 for Tam, Mira, Oskar and Lark;
- `input_context` over the whole of S04 was only ever
  `no_scene -> title -> world -> menu_map -> menu_quest_log -> menu_build ->
  menu_save -> world`. **It never became `narrative_modal` and never became
  `combat`.**

So the exact line shown for this unmet state, as far as this run can see, is
**nothing at all** — no refusal, no prerequisite named, no acknowledgement. That
contrasts sharply with the trainer in S03, which for the *same* underlying cause
gave a specific, actionable line ("a bed will do it").

### The limit on this claim, stated rather than papered over

`S04-17` reached the marshal with `move_to` **(20, 12)** — literal coordinates —
and `S04-18`/`S04-20` used a plain `press`, which does not assert that an
interact prompt is live. That is precisely the CD-5 trap ("**Reached** means
within interaction range of the **entity**, with its prompt live. **Not** within
a radius of a literal coordinate"). So this run **cannot** separate:

- the marshal refusing to speak to an unready team while showing nothing, from
- the player never being in the marshal's interaction range at all.

Both are consistent with the evidence. **This entry does not choose between
them.** What it does establish is a coverage defect in its own right: section
E.6.12's requirement is **unsatisfiable by S04 as scripted**, because
coordinate-`move_to` plus unchecked `press` cannot produce "the exact line shown"
either way. S03's own catch loop already uses the entity-resolving form
(`move_to_entity` + a prompt-matching press, RIG-16/RIG-17) and fails loudly
when no prompt is live; S04's sign-up path does not.
