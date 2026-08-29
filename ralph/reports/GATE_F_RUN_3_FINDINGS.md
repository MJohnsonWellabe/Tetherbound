# Gate F run 3 — findings about the GAME

**Date:** 2026-08-28. **Branch:** `ralph/GATE-F-RUN-3`.
**Run directory:** `ralph/reports/gate-f-run-20260828T183531Z`.
**Candidate:** `main@26f0db4`, unchanged for every segment of the run.
**Lanes run:** logic only. **No pixels were captured.** See
`GATE_F_CAPTURE_LANES.md` for what that costs and who can pay it.
**Companion:** `GATE_F_RUN_3_RIG_FINDINGS.md` — findings about the instrument.

> **STATUS: PROVISIONAL.** Written while the run is still executing so that the
> evidence survives the container. Sections marked *(pending)* are filled as
> segments land.

---

## Read this first: how much of this run is about the game

Not much of it, and saying so plainly is the most useful thing this document
does.

**There is not one `combat_start` event in this run.** No fight at all, across
five completed segments, including an entire tournament. The cause is measured
and it is the instrument, not the chapter — `RIG-11`, with the whole derivation
in `gate-f-run-20260828T183531Z/DIAG-S02-ENCOUNTER/FINDING.md`. In one line: a
fight requires a *deployed* creature, a loaded save deploys none, every journey
segment from S03 on begins with a load, and no journey step-script in the
protocol ever presses `creature_recall` — the button the game itself puts on
screen for exactly this.

So a large class of results in this run's artefacts are **not findings about
Tetherbound**, and would be badly misread as such:

| looks like | actually |
|---|---|
| the opening's first catch never happens | the harness never had a creature out; the encounter works — proven end to end |
| the tournament is never won (`tournament_won` unset) | it was never fought; no input could have won it |
| the South Bridge never opens (`south_bridge_open` unset) | its gate fight could not start |
| the player falls off the world 178 times at z≈1325 | the bridge gate is legitimately still shut, and the game's own recovery volume caught the player every time — the game protecting itself, working |
| the party never grows past 1 | catching requires combat |
| the objective chain never leaves *"Catch your first wild creature."* | its first rung requires the first catch |
| 26 objective assertions fail | `RIG-1`: two different id spaces compared |
| S03 fails 64 of 274 steps | 58 of them ran inside one shop panel nobody closed (`RIG-7`) |

**None of the above may be cited as evidence about the game.** They are listed
here, in the game document, precisely because that is where somebody would go
looking for them.

---

## What this run DOES establish about the game, positively

### GAME-OK-1 — the front door is sound

S01, 13 of 13 steps PASS, on a fresh `user://`:

- process start → title interactive in **500 ms** (30 settle frames);
- the title owns input (`input_context = title`) and a real Control holds focus
  (`Start New Game`), so a stick moves something — §E.4's own standard, and the
  thing that decides whether the front door is usable on a handheld at all;
- with no save present, Start New Game enters the world directly rather than
  raising an overwrite confirmation;
- the world stands up and the fresh spawn is contained in `grandpas_village`;
- a new game starts with **zero** creatures, as the five-creature rule requires;
- the quest log tracks the first main-chain rung with the right text on screen.

### GAME-OK-2 — the opening plays, beats 1 through 8, on the production path

This is the strongest positive result in the run, and it had to be established
by a purpose-built probe because the harness's own S02 could not
(`DIAG-S02-ENCOUNTER/FINDING.md`, transcript `pass3.txt`). A clean process,
nothing loaded, nothing granted, driven through the real panels with synthetic
input:

- the bed's *Get up*, the loft crossing and the stair descent;
- Grandpa's briefing, advanced **by predicate rather than by count**, with its
  three gifts landing line by line as he speaks;
- the starter picker, and the five-creature rule's first bite — the other two
  stay with him;
- the naming pad, walked cell by cell on a gamepad grid, and confirmed on Done;
- `grandpa_named` opening on the name the player typed;
- **the follower body deployed by the naming beat** (`AllyCreature`, one node);
- and then, standing at the exact coordinates S02 pressed at, `(26.78, −38.32)`,
  one `interact`:

```
director.interaction_offer = {"actionable":true,"distance":5.990,
                              "label":"Engage Bramblebun","priority":0}
arbiter.winning_provider() = encounter_director.gd
pressed interact: is_fighting false -> true   >>> A FIGHT STARTED
```

Reached a second way — the starter granted through the game's own
`adopt_starter()` — the same spot offers *"Engage Bramblebun"* on **30 of 30**
samples across 30 play-seconds, at a steady 5.99 m against a 6.00 m reach.

**The chapter's opening is not a dead end.** Any reading of this run that says
otherwise is reading the harness.

### GAME-OK-3 — the interaction arbiter behaves correctly under modals

Measured incidentally, and worth recording because it is the mechanism a lot of
this run's confusion passed through. While a conversation owns input, the
arbiter reports **no winning provider and an empty prompt**, and `interact` does
nothing — even with an actionable *"Engage Bramblebun"* offer standing 1.71 m
away from the director. That is `interaction_arbiter.gd` being deliberately deaf
to the world while a panel owns input (OF25), and it is right.

---

## Findings

### GAME-1 — opening the pause shell on a controller fires the destructive drop verb

**Severity: SHIP.** Player-facing, on the first pause menu of the chapter, on the
primary input device.

`project.godot` binds both of these to **joypad button 6** (Start / Menu):

```
game_menu      = InputEventJoypadButton button_index 6
backpack_drop  = InputEventJoypadButton button_index 6
```

The pause shell opens on the Satchel tab. So the press that opens the shell also
reaches the backpack tab's destructive drop verb on the tab it opened on, and the
player is asked whether to throw away the highlighted item because they pressed
Start.

Observed, S02-63:

```
game_menu opened the shell: context world -> menu_backpack,
focus on 'Drop it' (@Button@62560)
```

`tab_backpack.gd:1345-1370` already carries a guard for exactly this
(`_ignore_drop_until_release`) and its comment describes this symptom. **The
guard did not hold.** The operator recorded it across S02 attempts 5 and 6, where
the confirmation also ate the five tab presses that were supposed to reach the
Save tab, so no handoff save was written.

This one is independent of `RIG-11` and independent of the capture gap. It is a
controller-first project (hard rule) and this is the controller's most-pressed
button.

### GAME-2 — after a load, nothing is deployed, and only the interaction line says so

**Severity: recorded as an OBSERVATION for Phase B, not asserted as a defect.**
Whether this is a defect is a design call, and §J says the operator does not make
those.

Measured (`DIAG-S02-ENCOUNTER/pass2.txt`): loading a save restores the party and
deploys no creature. `_sync_active_creature()` declines to summon when nothing is
out, and says so in its own comment. The game's only indication is the
interaction line, which is **non-actionable** and names a different button:

```
{"actionable":false,"priority":-1,"label":"<RB glyph>   Call out Moss"}
```

What is worth Phase B's attention: this line only appears when the player is
standing where nothing else is offering anything, it is the lowest priority
offer there is, and nothing in the quest log, the HUD's tracked objective, or the
party screen restates it. A player who loads a save and walks to a creature is
shown *"Call out Moss"* only if no bush, prop or NPC outranks it.

**The run cannot say whether a real player would be confused by this**, because
the run had no player and captured no frames. It is exactly the shape of question
§K.4 reserves for the owner's own pass.

---

## Per-segment observations *(pending — filled as the chain completes)*

The journey chain is S06 → S10 and the studies X01 → X08 at the time of writing.
`HANDOFF_PROVENANCE.md` in the run directory records which entry save each
segment actually had, which is **not** in every case the one §B names — see
`RIG-10`.

---

## What this run cannot conclude

Stated here rather than left to inference:

1. **Nothing about how the game looks.** No pixels were captured; every
   prescribed §G frame is delegated and unpaid. See `GATE_F_CAPTURE_LANES.md`.
2. **Nothing about combat, catching, difficulty, or the progression that
   depends on them** — no fight occurred (`RIG-11`).
3. **Nothing about pacing or first-clear timing** past the opening, because the
   journey's later segments were played in a world whose gates could not open.
4. **Nothing about device performance, audio, controller feel, or handheld
   legibility** — all `[OWNER-ONLY]` per §K, unchanged.
