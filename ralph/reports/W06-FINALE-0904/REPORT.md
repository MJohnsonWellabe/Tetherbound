# W06-FINALE-0904 — the endgame dialogue, the legendary inside the machine, the garrison's withdrawal

Branch: `ralph/W06-FINALE-0904`, from `origin/main` at `ef16544f`.
Items: **CL-W7** (owner directive A-5), **CL-O8** (owner playtest OP-0904-8), **CL-G5**.
Decision record: `docs/decisions/D74`. Status rows: `docs/CURRENT_STATE.md` §4d.

---

## 1. Files changed

| File | What |
|---|---|
| `data/dialogue/stronghold.json` | rewritten: every conversation cut to handheld length; portraits re-pointed |
| `tests/test_stronghold_dialogue_budget.gd` | **new** — the length budget and the surviving canon, on the merged dialogue table |
| `scripts/world/stronghold_climax.gd` | the legendary staged inside the machine's measured cage void; the step-out; the settled ending position; the garrison watcher |
| `data/config/stronghold_climax.json` | `legendary.stage` (how the cage void is measured), the restraint rings, the step-out/approach tunables |
| `scripts/world/stronghold_occupation.gd` | **new capability** — `watch_withdrawal()` / `withdraw()`: the Hall's garrison stands down on `legendary_freed` |
| `data/config/stronghold_occupation.json` | the `withdrawal` block (which holders leave, which go dark) |
| `tests/smoke_stronghold.gd` | asserts the bound body is inside the machine's measured void |
| `tests/smoke_gate_e_finale.gd` | asserts inside-before-lever, stepped-out-after, and the garrison withdrawn |
| `tests/smoke_finale_persistence.gd` | asserts the garrison comes back withdrawn through a real save/load |
| `tools/_capture_stronghold_climax.gd` | **new** — the chamber and gate evidence stands, bound then freed |
| `tools/_capture_stronghold_probe_machine.gd` | **new** — measures the installed machine mesh's cage void |
| `docs/decisions/D74-*.md`, `docs/CURRENT_STATE.md` | the calls, and the status rows |

Nothing outside the lane's ownership list was touched. `stronghold.gd`, `meadow_healing.gd`,
`rift_collapse.gd` and every other dialogue file are unmodified.

---

## 2. What the player gets

**The endgame reads in one glance.** The Warden used to speak eight paragraphs averaging
193 characters, peaking at 379, at the moment the player most wants to fight. He now says
it in four lines, none over 90 characters:

| Conversation | lines | chars | longest line |
|---|---|---|---|
| `stronghold_duty_board` | 4 | 172 | 55 |
| `stronghold_reveal` | 4 | 287 | 81 |
| `stronghold_warden_challenge` | 4 | 338 | 90 |
| `stronghold_warden_defeated` | 3 | 201 | 93 |
| `stronghold_chamber` | 3 | 221 | 82 |
| `stronghold_free_legendary` | 3 | 253 | 85 |
| `stronghold_legendary_joins` | 2 | 148 | 76 |
| `stronghold_machinery_fails` | 4 | 311 | 85 |
| **whole file** | | **1,931** (was 5,343) | **93** (was 379) |

§33 survives intact and is asserted, not trusted: he confirms the readout rather than
denying it ("You read the board. Good. Then you know it is true. There is no lie to
find."), he states the worldview ("Freedom without control becomes disorder"), he makes
§28's argument ("You don't understand what these barriers are holding apart"), he warns
after losing, and he does not recant. Every `flag:` hook survives — the readout still sets
`learned_legendary_is_the_source` once, the freeing still sets `legendary_freed` on the
line the cage drops on, exactly once. Portraits follow the 2026-09-04 contract: the
Warden's two conversations point at `warden.png`; the readout, duty board and chamber
narration keep `trainer.png`, which is the player's own — they are what the player reads
and sees, and the contract gives no other first-person face.

**The legendary is inside the machine.** Bound, it stands on the machine's own axis, on
the dais the installed mesh carries at 3.13 m, under its crown at 8.89 m — with the
restraint rings on its body rather than a 24-bar fence on the floor around it. The void is
*measured* off the mesh at build time, never guessed from a transform (D49's lesson): the
highest geometry within 1 m of the axis in the lower half is the dais, the lowest above it
is the crown. Pull the lever and it steps down off the dais and out across the floor,
turns to the player, and on the join offer crosses to meet them. A save taken in the freed
window comes back standing free at the mark, not caged.

**The Hall answers.** On `legendary_freed` — live, or on a load that already carries it —
the gate sentries and the garrison camp are gone and the braziers, sconces, work lamps,
relay hub, siphons and pipe runs are dark: measured in play, *2 groups gone, 5 holders
dark, 14 lights out, 45 flames out, 13 emissive surfaces unlit*. The iron, brackets and
hardware stay: an abandoned post, not a demolished one.

---

## 3. Tests and smokes

Every command below is `export PATH=$HOME/godot-bin:$PATH` then run from the repo root.
All results are from this branch's head unless a line says otherwise.

| Command | Result |
|---|---|
| `godot --headless --path . --script tests/run_tests.gd -- --only=test_stronghold_dialogue_budget.gd` | **7 tests, 69 assertions, 0 failed** |
| `godot --headless --path . --script tests/run_tests.gd -- --only=test_band_dialogue.gd` | **3 tests, 63 assertions, 0 failed** |
| `godot --headless --path . --script tests/run_tests.gd -- --only=test_dialogue_runner.gd` | **66 tests, 1013 assertions, 1 failed** — see §5 |
| `godot --headless --path . --script tests/smoke_gate_e_finale.gd` | **passed** (`gate E finale smoke test passed`) |
| `godot --headless --path . --script tests/smoke_stronghold.gd` | **passed** (`stronghold smoke test passed`) |
| `godot --headless --path . --script tests/smoke_stronghold_reload.gd` | **passed** (`stronghold reload smoke test passed`) |
| `godot --headless --path . --script tests/smoke_finale_persistence.gd` | **passed** (`finale persistence smoke test passed`) |

All five commands above were re-run together on the branch head after the last code change,
so every result in this table is reproducible from the head commit named in §6 — not
carried over from an earlier tree. The three unit files run together report
**76 tests, 1145 assertions, 1 failed**, the one failure being the `warden.png` portrait
file another lane owns (§5).

**The length test was seen red on the old file, for the right reasons**, before the cut was
written — `'stronghold_warden_challenge' has a 379-character line (budget 110)`, `the
Warden's pre-fight speech is 1547 characters; budget 350`, `the stronghold's spoken text is
5343 characters; budget 2000` — and green after. It measures the **merged dialogue table**,
not the file's source text, so no assertion can pass by grepping.

**What the smokes actually exercise** (not source greps):

- `smoke_stronghold` measures the bound body against the machine mesh's own measured void:
  `bound legendary: 0.00 m off the machine's axis, feet 3.18 m up (dais 3.13, crown 8.89,
  void 5.76 m), body top 7.57 m`.
- `smoke_gate_e_finale` plays the finale on real input — walks to the lever, presses it,
  drives the ceremony with a full belt — and then asserts:
  `the legendary is bound inside the machine: 0.00 m off axis, 3.18 m up`;
  `the freed legendary stepped out of the machine: 10.8 m off axis, 0.00 m up, clear of its
  footprint`; `the garrison withdrew: { "withdrawn": 2, "darkened": 5, "lights_out": 14,
  "flames_out": 45, "surfaces_unlit": 13 }`, with the gate sentries hidden, the camp hidden
  and zero brazier lights still visible.
- `smoke_finale_persistence` does the same across three **real save/load round trips**, and
  asserts the Hall comes back withdrawn from the saved flag:
  `settled ending: the Hall's garrison came back withdrawn ({ "withdrawn": 2, ... })`.

**Three real defects the smokes caught in this lane's own work, each fixed and re-verified:**

1. A creature body is a `CharacterBody3D` under gravity, and the machine's dais is geometry
   with no collider — so the bound creature sank 0.43 m into the dais and rested on the
   base drum's invisible top (`feet 2.70 m up; the dais is at 3.13 m`). Held, the machine
   holds it: physics is off for the staged sequence.
2. The release ceremony **pauses the tree**, which freezes the step-out tween mid-flight;
   the chapter ended with the creature measured 2.6 m off the machine's axis and 2.02 m up
   — on the plinth, in the air — through the whole last conversation. The ending position
   is now set when the roster decision resolves, not left to an animation that may be
   interrupted.
3. The smoke's own footprint test swept `VisualInstance3D`, and `Light3D` is one: the
   machine's `CoreLight` (omni, range 26) merged a 52 m cube into the "footprint" and
   reported a creature standing correctly 10.8 m clear as inside the machine.

---

## 4. Visual evidence

Captured with `tools/_capture_stronghold_climax.gd` under xvfb + `--rendering-driver
opengl3` at 1280×720 (never `--headless` with a driver). The freeing in the capture is
driven through the climax's own `_free_the_legendary()` — the lever's own path — so the
after-frames are what the game does, not a posed copy.

Three rounds, three sheets, three verdicts, each committed verbatim: `_sheet_round1.png` /
`JUDGE_ROUND1.md`, `_sheet_round2.png` / `JUDGE_ROUND2.md`, `_sheet_round3.png` /
`JUDGE_ROUND3.md`. Each round used a **fresh** code-blind sub-agent with no knowledge of the
previous rounds: it got the sheet, the frames, `docs/reference/` and the visual-judge skill,
with rows labelled by camera stand only and no hint which column was which or what had
changed. Round 1's judge identified the frames itself by matching pixels.

**On the lane's own acceptance question round 1 is unambiguous:**

> Row 1 B and Row 2 B read as inside the machine. Rows 2 A, 3 A and 3 B read as beside it.

and it names the mechanism as sound — *"the staging decisions underneath are sound — the
creature is in the right place in Rows 1 B and 2 B, the held/freed prop pass is doing the
right kind of work in Rows 4 and 5"*.

It also qualified that hard, and two of its findings were **this lane's to fix**, so they
were fixed rather than filed:

- *"the containment rings are unlit white polygons"* — correct, and the cause was already
  documented in this repo: emission that blows out loses its hue first.
  `stronghold_occupation.gd`'s work-lamp lens hit exactly this at 2.4 and fixed it at 1.15.
  The rings ran at 2.2 and clipped teal to white; they now run at 1.15, as a tunable with
  the ceiling recorded next to it.
- *"strip the two guards and one brazier flame and the pairs are indistinguishable"* — the
  withdrawal was too narrow. `TetherRetrofit` and `TetherPipes` — the siphons and pipe runs
  bolted to the Hall, each carrying a `SiphonGlow` omni and an emissive rift skin — now go
  dark with the rest. Measured effect: 11 lights → **14**, 2 emissive surfaces → **13**.

Round-2 frames of the four affected stands are under `shots/w06_round2/`. Round 2's judge
confirmed the ring change landed — *"B stops being an off-palette pure-white foreign object
and joins the room's one accent colour"* — and called the gain small, which the numbers
agree with.

**Round 3 was a failure and is recorded as one.** Round 2's top finding inside this lane's
ownership was that *nothing connects the creature to the structure, so the central premise
is not rendered*. That is the premise of the whole reveal, so it was attempted rather than
filed: a tapered column of the reserved teal from the creature's back to the machine's
crown. A third blind judge, given it against the round-2 frames and told nothing, called it
**worse than nothing** — an opaque cone whose taper points *down at* the creature ("the
shape language of a spotlight… the opposite of extraction"), which in the corner view
"terminates in mid-air above the antlers without touching anything". It was reverted
(`f28fc030`); the shipped state is the round-2 state.

**The ceiling, recorded** (COMMON's stop rule): the remaining findings that would move the
reveal are geometry this build does not have. The machine needs a socket, clamp or cable
the creature physically sits in, and a second material language saying "bolted on by Team
Tether". The installed hero mesh has neither — **D49 generated it deliberately *without* its
prisoner**, because the licence forbade the creature in the reference crops, so its cage
volume is a bare arch with nothing to attach to. Primitives placed in that arch by this lane
read as gizmos, and round 3 demonstrated that adding more of them makes the frame worse.
`stronghold.gd` and `assets/environment/team_tether/tether_machine.glb` own the rest; both
are outside this lane's ownership list. `JUDGE_ROUND3.md` carries the full ranked list and
the round-by-round table of what measured.

Numbers decided before the render, measured on fixed crops:

- Machine cage void, off the installed mesh: dais **3.13 m**, crown **8.89 m**, void
  **5.76 m**, body 4.39 m, headroom **1.37 m** (`tools/_capture_stronghold_probe_machine.gd`).
- Chamber arch-void crop, before vs after staging: **9.8%** of pixels changed (the creature
  arriving in the arch); bound vs freed at the same stand: **10.5%**.
- Old floor-ring crop, before vs after: **20.7%** of pixels changed (the 24-bar fence gone).
- Hall yard crop, held vs freed: mean luma **7.0 → 1.4** (0.20×).
- Hall causeway, gate arch + sentries crop, held vs freed: mean luma **6.3 → 4.3** (0.69×).
- Restraint-ring hue separation (G+B)/2−R, emission 2.2 → 1.15: **+6 → +35** — from
  indistinguishable-from-white to reading as the reserved teal.

---

## 5. Known limitations, and what was deliberately not done

- **`test_dialogue_runner.gd` has one red assertion, by design and by the brief.**
  `test_every_conversation_has_a_speaker_and_a_portrait_that_is_really_there` fails on
  `res://assets/ui/portraits/warden.png` for the Warden's two conversations. The brief
  fixes those names and says another lane produces the PNGs — *"Do not create the PNGs."*
  The dialogue panel already degrades correctly (a missing portrait leaves the frame empty
  rather than erroring). This goes green the moment the portrait lane lands, with no change
  to this branch. **The coordinator should land the portrait files with or before this
  branch.**
- **CL-G5's named file was not where the shipped garrison lives.**
  `stronghold_occupation.gd::build()` has been dead code since T1-HALL-REBUILD retired
  `landmark.gd`'s castle; the garrison the player sees is `stronghold.gd::_build_occupation()`'s,
  with the same node vocabulary. The withdrawal is therefore written in the occupation file
  (its owner) and targets those holders by name, hung off the Stronghold node by the climax.
  `stronghold.gd` was not edited — it is not in this lane's ownership.
- **One judge finding is outside this lane and is left for the coordinator:** *"the same NPC
  stands in exactly the same spot, in the same pose, in both frames"* of the courtyard. That
  figure is a `stronghold.gd`-placed gauntlet trainer, and withdrawing **beaten trainers** is
  `meadow_healing.gd`'s job — both files are explicitly outside this lane's ownership list.
  It is a real defect in the "the world changed" read and wants an owner.
- **All three judges' larger verdict is fair and is not this lane's to answer.** They call
  the chamber not shippable — the machine reads as a stone shrine rather than as captured
  machinery, it carries no retrofit vocabulary and no Team Tether colour, cyan light-bars
  slice the room and read as debug draws, the chamber walls show overlapping slabs and a
  black gap, the stairs are a painted texture, nothing casts a contact shadow, and both
  locations are single-key with crushed blacks. Every one of those lives in `stronghold.gd`,
  the Hall's kit, or the machine asset — none in the staging this lane changed. The three
  verdict files carry the ranked lists in full for whoever owns them.
- **Two further findings are worth a lane of their own:** the creature reads as a neutral
  standing idle rather than as something being drained (a pose/animation ask), and the
  chamber gives it no value separation, so at distance "you cannot tell there is a creature
  there at all".
- **Not done:** no new mesh, no Meshy generation, nothing shrunk, no other dialogue file
  touched, no PR opened.

---

## 6. Branch and head commit

Branch **`ralph/W06-FINALE-0904`**, head **`HEAD_PLACEHOLDER`**. No pull request was opened,
per COMMON.

## 7. Commits

```
COMMITS_PLACEHOLDER
```
