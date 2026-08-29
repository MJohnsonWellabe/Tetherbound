# Gate F run 3 — findings about the GAME

**Rewritten:** 2026-08-30, from `ralph/reports/gate-f-run-20260828T183531Z`'s
own `INVENTORY.json`/`events.jsonl`/`notes/*.md` files. **Branch:**
`ralph/T2-GATEF`. **Candidate:** `main@26f0db4`, unchanged for every segment.
**Lanes run:** logic only. **No pixels were captured** — see
`GATE_F_CAPTURE_LANES.md`. **Companion:** `GATE_F_RUN_3_RIG_FINDINGS.md` —
findings about the instrument; read it first if you have not, because most of
what makes this run hard to read is there, not here.

**Run state at rewrite time:** S01-S09 complete, S10 BLOCKED at step 27/121 on
a genuine cost gate, X02 complete, X03 killed mid-run (not evidence, preserved
as `X03-killed-1/`), X01/X04-X08 not yet run by this lane.

---

## The headline finding: the player has been stranded at the South Bridge since partway through S05, and it dominates everything downstream

This is not a footnote. **Every single `move_to` step in the kept S06, S07,
S08, S09, and the first 22 steps of S10 fails**, each one stopping between
1.6 km and 6.3 km short of its target, and **every failure lands within a few
metres of the same spot** — x∈[0,16], y∈[-8,-2], z∈[1314,1326], the South
Bridge carve corridor's own centre:

| segment | asked to reach | stopped at | short by |
|---|---|---|---|
| S06 | Old Quarry (403,1794) | (13,-3,1314) | 618.2 m |
| S07 | river/relay (150,3500) | (8,-3,1318) | 2186.2 m |
| S08 | ironwood grove (-345,5060) | (15,-4,1324) | 3753.0 m |
| S09 | outer watch (64,7400) | (2,-3,1321) | 6079.4 m |
| S10 | Hall (0,7560) | (8,-3,1318) | 6241.6 m |

**Read S06 through S09's FAIL counts (21, 22, 22, 12 respectively) as this one
stranding, counted once per assertion that depends on the player's location or
on a flag gated behind reaching the next region — not as 77 independent
findings about bands 2 through 5's own content.** Every band-3/4/5 objective
flag (`relay_captain_defeated`, `captive_rescued`, `relay_disabled`,
`mill_crossing_restored`, all three `defeated_captain_*` flags,
`hall_approach_open`) is unset as a direct, mechanical consequence of the
player never arriving.

**What this means for the run's coverage:** five consecutive segments (S05's
tail through S09) plus the first fifth of S10 have produced almost no new
information about bands 2 through 5's actual content — encounter design,
regional identity, pacing, difficulty curve — because the player is not
reaching any of it. This is the dominant fact this run has to report about
Track 2 for bands 2-5, and it is worth stating plainly: **this run cannot
speak to whether Stone & Root, River & Relay, Upper Meadows, or the Stronghold
approach are fun, fair, or well-paced, because the player was not there.**

**Whether this is a rig defect (the harness's straight-line `move_to`
primitive failing to navigate a real, legitimate obstacle a free-roaming
player would walk around) or a genuine game defect (the walkable path is
actually broken or absent at this exact spot) is an open question, not
settled by this run.** `ralph/GATE_F_RUN_3_RIG_FINDINGS.md`'s RIG-13 section
has the full mechanical detail and the concurrent T2-STRANDING lane is
actively diagnosing it. This document does not pre-judge which it is — but
notes that a player-facing verdict on bands 2-5 is on hold until that
question resolves, whichever way it goes.

---

## What this run DOES establish about the game, positively

### GAME-OK-1 — the front door is sound

S01, 13 of 13 steps PASS, on a fresh `user://`: process start to title
interactive in 500 ms; the title screen owns input and a real Control holds
focus (a stick moves something); no save present, Start New Game enters the
world directly with no overwrite confirmation; a new game starts with zero
creatures, as the five-creature rule requires; the quest log tracks the first
main-chain rung correctly.

### GAME-OK-2 — the opening's first encounter works, confirmed by a dedicated probe, independent of the harness's own S02 script

S02's own step script never gets a fight to start (see the companion RIG
document — this is a harness gap, `press interact` blind rather than a
resolved engage). But `DIAG-S02-ENCOUNTER/FINDING.md`, driving the same
production path with a purpose-built probe, confirmed the encounter mechanism
itself works end to end: the bed, the loft crossing, Grandpa's briefing
advanced by predicate, the starter picker (the five-creature rule's first
bite — the other two stay with Grandpa), the naming pad walked cell by cell,
and then, at the exact coordinates S02 pressed at, one `interact`:

```
director.interaction_offer = {"actionable":true,"distance":5.990,
                              "label":"Engage Bramblebun","priority":0}
pressed interact: is_fighting false -> true   >>> A FIGHT STARTED
```

Confirmed on 30 of 30 samples across 30 play-seconds at a steady 5.99 m
against a 6.00 m reach. **The chapter's opening is not a dead end.**

### GAME-OK-3 — the interaction arbiter behaves correctly under modals

While a conversation owns input, the arbiter reports no winning provider and
an empty prompt, and `interact` does nothing — even with an actionable offer
standing 1.71 m away. Correct, deliberate behavior (`interaction_arbiter.gd`).

### GAME-OK-4 — S03 produced real, if unlucky, combat

With the rig fixed to walk to a live individual and press only a real engage
prompt (see companion doc, RIG-16/17), S03 fought three real
engage/combat/throw cycles. All three throws missed the catch — ordinary
variance at whatever this species/orb combination's real chance is, not by
itself a finding about the odds (protocol §0.6) — but the fights themselves
ran, resolved, and the world state (HP, fainting, re-engage refusal against a
stale prompt) all behaved as designed.

---

## Findings

### GAME-1 — opening the pause shell on a controller can fire the destructive backpack-drop verb

**Severity: SHIP candidate.** Player-facing, on the first pause menu of the
chapter, on the primary input device. `project.godot` binds both
`game_menu` and `backpack_drop` to joypad button 6 (Start/Menu). The pause
shell opens on the Satchel tab, so the press that opens the shell also lands
on the backpack tab's destructive drop verb if focus happens to be sitting on
it. Observed in S02: `game_menu opened the shell: context world ->
menu_backpack, focus on 'Drop it'`. `tab_backpack.gd` carries a guard
(`_ignore_drop_until_release`) for exactly this symptom; the operator's own
notes record it not holding on at least one attempt. Independent of the
stranding and of any rig gap — this is a controller-first project (hard rule)
and Start is the controller's most-pressed button.

### GAME-2 — after a load, nothing is deployed, and only a low-priority interaction line says so

**Severity: recorded as an OBSERVATION for Phase B, not asserted as a
defect** — whether this needs a change is a design call this run does not
make. Loading a save restores the party but deploys no creature body;
`_sync_active_creature()` declines to summon when nothing is out. The only
on-screen indication is a non-actionable interaction line (`Call out Moss`),
which only appears when nothing else is offering anything nearby and is
restated nowhere else (quest log, HUD, party screen). Whether a real player
would notice this at all is unmeasured here — no pixels were captured.

### GAME-3 — the build catalogue's d-pad focus navigation repeatedly fails to move onto the next piece cell

**Severity: SHIP candidate.** Measured in X02 (seeded from `S03-exit`, before
the stranding — this is not a stranding artefact). Across at least seven
distinct build-catalogue cells in a single session, a `ui_right`/`ui_down`
press reported "did not move focus off" the currently-focused button:

```
X02-036  focus the floor piece    — FAIL: ui_right did not move focus off @Button@62324
X02-049  focus the wall piece (1) — FAIL: 2x ui_right did not move focus off @Button@65678
X02-054  focus the wall piece (2) — FAIL: 2x ui_right did not move focus off @Button@66152
X02-059  focus the wall piece (3) — FAIL: 2x ui_right did not move focus off @Button@66626
X02-064  focus the doorway piece  — FAIL: 3x ui_right did not move focus off @Button@67109
X02-069  focus the roof piece     — FAIL: 4x ui_right did not move focus off @Button@67655
X02-082  focus the camp           — FAIL: 5x ui_right did not move focus off @Button@69395
X02-087  focus the creature bed   — FAIL: 6x ui_right did not move focus off @Button@70067
```

Each failure still allowed the piece to be armed and placed afterward (the
`arm the * ghost` steps immediately following all PASS), so this reads as a
**focus-reporting/navigation defect rather than a hard block** — the game
still let the operator proceed, but the on-screen focus indicator a real
player relies on to know what they are about to place did not visibly move
when the input said it should. §8's own standard (a poll-only reader that
reports a working menu while the stick moves nothing) is exactly the defect
class this matches. Worth a real player test: does the highlighted piece
actually change, or does only the *placed* piece change while the highlight
stays put?

### GAME-4 — the craft panel's `input_context` never leaves `world`, even while it appears to function

**Severity: recorded as an ambiguity, not asserted as a defect** — the
underlying mechanism (does crafting actually require exclusive input
ownership, or is this by design) is not decidable from this run's telemetry
alone. In X02, interacting with the workbench (`X02-015`) is immediately
followed by an assert that the craft panel owns input, which FAILs:
`input_context=world (wanted prefix panel)`. The subsequent focus-move steps
also FAIL (`did not move focus off nothing`) — consistent with no panel
Control ever holding focus. Yet the very next step, an unconditional
`ui_accept` press, is followed by a `PASS` on "the axe costs 4 wood/3 stone/2
fiber and the satchel pays it," and the same pattern repeats for the pickaxe.
**Two readings are both consistent with this telemetry and this run cannot
distinguish them:** (a) the craft panel genuinely opened and crafted
correctly, but `input_context`'s accessor does not recognize it as a panel
owner (an instrumentation gap, RIG-8's shape, not a player-facing defect); or
(b) the panel never actually opened and the `ui_accept` press did something
else that happened to also pay for and grant the axe. Not chased further this
pass — flagged for whoever next has capture-lane or live-probe access to the
craft panel's actual `Control.has_focus()` state at this exact moment.

---

## Per-segment summary

| segment | steps | PASS | FAIL | DELEGATED | what dominates the FAILs |
|---|---:|---:|---:|---:|---|
| S01 | 14 | 13 | 0 | 1 | clean |
| S02 | 75 | 61 | 6 | 8 | first-catch engagement never fires from S02's own blind press (see companion doc); road-gate flag consequently unset |
| S03 | 338 | 284 | 47 | 7 | RIG-13/14/15/16/17/18 history (see companion doc); real combat achieved, team stayed at 1 |
| S04 | 73 | 53 | 14 | 6 | tournament ungated by team-of-1 (RIG-18); zero combat_start |
| S05 | 77 | 58 | 6 | 13 | South Bridge gate never opens (open question, see companion doc) |
| S06 | 104 | 72 | 21 | 11 | South Bridge stranding (RIG-13) |
| S07 | 99 | 68 | 22 | 9 | South Bridge stranding |
| S08 | 135 | 102 | 22 | 11 | South Bridge stranding |
| S09 | 76 | 56 | 12 | 8 | South Bridge stranding |
| S10 | 27/121 (BLOCKED) | 19 | 6 | 2 | stranding through step 22; genuine cost-gate BLOCKER at step 27 |
| X02 | 170 | 146 | 20 | 4 | build-catalogue focus defect (GAME-3), craft-panel context ambiguity (GAME-4), RIG-14 tab-cycle shape (see companion doc) |

`HANDOFF_PROVENANCE.md` in the run directory records which entry save each
segment actually had — not in every case the one §B names (RIG-10/RIG-12).

---

## S10's BLOCKER is a real capacity limit, not a pricing bug

S10 ran 27 of 121 steps (19 PASS, 6 FAIL, 2 DELEGATED) before the harness's
own cost gate refused to continue: `0.097 s/frame`, measured immediately
after a real combat exchange (`combat_quick` x38, a party switch,
`combat_quick` x24), against `40195 s` (11.2 h) predicted for the remainder
versus `13974 s` of budget left. Unlike CD-7c (RIG-2, a genuine
divide-by-a-handful-of-frames pricing artifact, already fixed), this price
jump tracks real combat-dense content (the gauntlet, elites, the Warden, the
legendary choice) and is not a rig bug to patch. No `S10-exit` save exists.
The practical fix is a faster host or splitting S10 into smaller segments
each under the 14400 s ceiling — not a shorter wait, which the protocol
itself says would just mean fights do not resolve.

---

## What this run still cannot conclude

1. **Nothing about bands 2 through 5's own content, pacing, or difficulty** —
   the player never arrived (South Bridge stranding, open question between
   rig and game).
2. **Almost nothing about combat** — zero `combat_start` events anywhere from
   S04 through S10, despite RIG-11 (the fix that was supposed to unblock this)
   being confirmed fixed. X04, not yet run, is this run's best remaining
   chance at real combat evidence.
3. **Nothing about how the game looks.** No pixels were captured; every
   prescribed §G frame is delegated and unpaid — see `GATE_F_CAPTURE_LANES.md`.
4. **Nothing about the chapter's finale, the Warden fight, or the legendary
   choice** — S10 BLOCKED at step 27/121, genuinely, on cost.
5. **Nothing about pacing or first-clear timing** past the opening — the
   journey's later segments were played in a world the player could not
   traverse.
6. **Nothing about device performance, audio, controller feel, or handheld
   legibility** — all `[OWNER-ONLY]` per §K, unchanged.

## What this run DOES conclude, positively, and should not be re-litigated

1. The front door (boot, title, new game, zero starting creatures) works.
2. The opening's core encounter mechanism works end to end, on the production
   path, independent of the harness's own scripting gap in S02.
3. The interaction arbiter correctly refuses input to the world while a modal
   owns it.
4. Real combat, once it is correctly triggered (S03, with the rig fixed),
   resolves correctly — HP tracking, fainting, re-engage refusal against a
   stale prompt all behaved as designed.
5. Two independent, player-facing UI defects exist regardless of the
   stranding or any rig gap: the Start-button drop-verb collision (GAME-1)
   and the build-catalogue focus-navigation gap (GAME-3).
