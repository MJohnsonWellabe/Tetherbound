# Gate F Phase B — Deliverable 1: blind analysis and root-cause clustering

**Reviewer:** Opus, in the `GATE_F_PROTOCOL.md` §Model-roles reviewer role.
**Candidate:** `f082bdf6265760ca9835e1065361fbbf87475d69`.
**Evidence:** `ralph/reports/gate-f-run-20260827T025303Z/` only.
**Protocol judged against:** `ralph/GATE_F_MASTER_PROTOCOL.md` (Phase A).
**Quarantine:** intact at time of writing. Nothing on the §14 exclusion list was
opened before this document and the provisional backlog were committed.

---

## 0. The finding that governs every other finding

**The journey lane never played the game.**

The tracked objective — read by the probe from the same reader
`playground_hud.gd` draws its on-screen line from — reads

> `opening:beat:road` — *"Catch your first wild creature."*

in **all 1,456 journey events, from S01 event 1 to S10 event 196**. It never
advances once. Not through the tournament, not through five bands, not through
the Stronghold, not through the finale.

It never advances because the game correctly refuses to advance it: **the first
wild catch never happened.** Everything the run reports downstream — party stuck
at 1, every gate flag unset, the South Bridge shut, 26 "objective did not
advance" failures, S06–S10's 115 km of walking inside a 25-metre pocket — is
**one cause with ten segments of consequences**, not ten findings.

So the first question this analysis had to answer was not "what is broken in the
game" but "**is the game broken, or is the instrument?**"

---

## 1. First-order adjudication: game defect vs. harness artifact

A harness FAIL means only that an expected value did not match an actual. Four
sources; only one is a backlog item. Every headline finding was measured against
that fork **before** it was written up.

### 1.1 "Input ownership is taken and never handed back" — **HARNESS ARTIFACT**

This was the strongest-looking finding in the run and it does not survive
measurement.

**X01's matrix does not measure what it says it measures.** Each cell step names
its intended context in its own `expected` string ("… in `combat`:"), and each
`input_probe` records `context_before`. Comparing them:

| | |
|---|---|
| cells with a parseable intended context | **418** |
| injected in the context the step names | **115** |
| injected somewhere else entirely | **303 (72.5%)** |
| **in-context cells that FAILED** | **0** |

Eight different named surfaces were all actually probed inside `menu_map`:
`combat`, `combat_aim`, `shop_bram`, `tournament_ui`, `craft_panel`,
`storage_panel`, `creature_bed_panel`, `swap_panel`. `riding` was probed in
`world`; `build_placement` in `build_catalogue`; `pause_shell` in
`narrative_modal`. Those surfaces were, on this evidence, **never entered once**.

The "30 distinct failing `(from → wanted)` transitions across 6 surfaces" is
therefore not the game refusing to *leave* a context. It is the harness failing
to *enter* the intended one and recording the entry miss as a transition
failure.

**Positive counter-evidence in the same run, same SHA:**

- `menu_cancel` closed a menu **84 times** (`menu_close` events), from
  `menu_map`, `menu_backpack`, `menu_creatures`, `menu_settings`, `menu_save`,
  `menu_quest_log` and `menu_build` — every tab. 138 close/leave steps PASSED
  against 6 FAILs (~4%), and those 6 read as §L.6 T07's own specified behaviour
  ("B chain closes exactly one layer per press") after the previous cell had
  opened a sub-layer.
- Focus navigation works: `S03-06` and eight sibling steps move focus with
  physical events (`'Start New Game' (@Button@27) -> 'Load Game' (@Button@28)`);
  `X01-717/718` log `focus_owner -> @Button@94239 -> @Control@94398`.

**The `panel:SwapPanel` hold (S03) — the single most alarming number in the
run — is an artifact.** Measured:

- opened `t=322.6` out of `narrative_modal`, released `t=1713.8` — **1,391 s,
  83.9% of the segment**, 99.6% of route rows at the pinned cell (22, −3);
- the panel is **Oskar's creature shop** (`data/dialogue/village.json`:
  `village_oskar_trade_intro` → `effect: shop:creatures:oskar`); Oskar is the
  village's creature trader by design (D39);
- during the entire hold the harness pressed **125 inputs and `menu_cancel`
  exactly zero times** — and `menu_cancel` is the one action
  `scripts/ui/swap_panel.gd:126` listens for;
- code inspection: the panel sets `process_mode = PROCESS_MODE_ALWAYS` (so it
  processes while the tree is paused), calls `_rows[0].grab_focus()` on open,
  and `close()`s on B.

**The Settings stress case never ran.** `X01-1015 … X01-1033` — the 126-cell
walk, the rebind capture, the cancel, the panic reset — executed **entirely
inside `narrative_modal`**, an unanswered dialogue. "130 × ui_down did not move
focus off nothing" is ui_down pressed at a dialogue box. It is a coverage gap,
not a focus defect.

**Verdict: no confirmed input-ownership collision exists anywhere in this run.**
What X01 actually establishes is that **~115 of 418 planned cells (27%) were
exercised**, and all of them behaved.

### 1.2 "No fight ever stages" — **HARNESS ARTIFACT**

Refuted by the run's own data. `X01` at `t=753.133`:

```
combat_start  input_context: narrative_modal -> combat
combat: {opponent_id: "Bramblebun", opponent_species: ["bramblebun"],
         opponent_hp: [100.7], my_hp: 117.6, phase: "ready",
         target_on_screen: true}
```

and a clean `combat_end` back to `world` 13.3 s later. **Combat stages, acquires
its target on screen, takes input ownership, and hands it back.** The
dialogue→combat transition (§L.6 T05) works.

The journey lane's zero `combat_*` is the harness failing to engage:

- **S02** (first wild fight): `S02-32` pressed `interact` ×1 at a walked-to
  coordinate; `S02-34` then measured `input_context=world (wanted combat)`. The
  operator's own `S02-36` note records why the *previous* attempt failed
  differently — the catch step-script's 14 quick attacks took the bramblebun
  from `opponent_hp 124.2` to `0.0` before an orb was ever thrown, i.e. **the
  step-script killed the creature it was meant to weaken**. Retuning to 6
  attacks then produced a run in which the fight did not stage at all.
- **X01-709/710** shows the mechanism plainly: `interact` ×6 at the practice
  trainer, `input_context=world` immediately after — and the fight actually
  staged **269 s later**, out of a dialogue that had been sitting open. Trainer
  fights are reached by advancing the challenge dialogue to its end; the
  step-scripts guess a press count per conversation and under-press.

### 1.3 "The South Bridge never opens" — **CONFIRMED, but as a cascade**

The observation is exactly right and the numbers are worse than stated. Route
traces, measured:

| seg | rows | path walked | x range | z range | most-occupied cell |
|---|---|---|---|---|---|
| S05 | 1,245 | 2,232 m | −340…344 | −3…1,324 | (22,−3) 28% |
| S06 | 4,105 | 9,180 m | −239…46 | −3…1,334 | (22,172) 21% |
| S07 | 4,483 | **17,270 m** | **−5…19** | 0…1,328 | (8,1317) 17% |
| S08 | 9,127 | **35,936 m** | **−6…18** | 0…1,328 | (8,1317) 15% |
| S09 | 3,373 | **11,771 m** | **−5…18** | 0…1,327 | (8,1317) 21% |
| S10 | 10,645 | **40,881 m** | **−19…25** | −25…1,328 | (8,1317) 9% |

S06–S10 = **115.0 km walked inside a corridor ~25 m wide, never past z=1328.**
The bridge is at z=1330.

But the gate is **behaving correctly**. `S05-44` reached the Tether grunt at
(14,1314); `S05-45` pressed `interact` once; no fight staged (§1.2); `S05-55`
recorded `flag south_bridge_open NOT set`; `S05-58` measured the player 15.3 m
short of (0,1330). **A gate that stays shut because its gate fight was never won
is a gate working as designed.** This is not a backlog item against the world.
It is the §1.2 cascade, and the crossing's real behaviour is **untested**.

Critically, this is *not* an input-ownership problem: S07 and S10 hold
`input_context = world` for **99.8% and 99.9%** of their route rows. The player
had control the whole time and simply had nowhere to go.

### 1.4 What further evidence would settle what I could not

| open question | experiment that settles it |
|---|---|
| Does the Build catalogue's grid accept directional focus navigation? (X02: 9 consecutive `ui_right` failures off a **real** focused Button, in the **correct** `build_catalogue` context — the only failure class in the run that survives every artifact test) | Re-run X02 from an S03-exit save that actually carries wood/stone/fiber, **with frame capture on**, logging `GridContainer.columns` and the focused cell index per press. `build_menu.gd:587` sets `columns = clampi(count, 1, COLUMNS)`, so a category with one piece is a single column in which `ui_right` legitimately cannot move — the step-script's "walk right N times" strategy would then be wrong, not the game. |
| Do NPC dialogues open unbidden on approach, or only on `interact`? (`X01-463`: "locomotion never came back: held 3601 frames by `narrative_modal` while 15.8 m short of Bram"; `S02-28`: "every tap past the third can re-open the conversation the previous tap just closed") | Walk a scripted straight line past Bram, Oskar, Mira and Tam with **no** `interact` presses at all and `answer_prompts` off; log every `input_context` change. If a modal opens with no press, that is a real defect. |
| Is `menu_cancel`'s way out of a station panel *discoverable*? | Needs a **frame** of the SwapPanel. None exists (§2). |
| Any pacing number beyond RT-03/04/05 | Needs a journey that gets past the first catch. |

---

## 2. The second governing finding: this run produced no prescribed visual evidence

Independently of the harness's inability to drive the game, **§11/§G — the
protocol's entire anti-cherry-picking mechanism — did not execute.**

- Every segment except X07 ran `--headless` **with no display server**. Across
  S01–S10, X01, X02 and `overhead`: **9,231 planned frames, 0 captured**, each
  manifest row carrying `reason: "headless: this process has no display server
  and cannot render a frame"`.
- `operator_harness.gd:1212` writes planned captures to `shots/<shot_id>.png`.
  **No `shots/` directory exists anywhere in the run. No `GF-*.png` file exists
  anywhere in the run.** Total PNGs in the 921 MB run directory: **551** —
  X07's 550 timestamped background frames plus one `capture_smoke.png`.
- X07's `WHY_INCOMPLETE.md` states "captures completed: **79**" and "Every other
  planned frame exists." The named files do not exist. What exists is the §H
  background record, which is real, rendered and colour-verified — but it is a
  *substitute*, not the prescribed artefact, and **23 of the 79 capture
  timestamps have no background frame within 3 s** (gaps to 257 s), including
  the required HUD-on `-gameplay` frame for **all 11 regions**.

**Consequence, stated plainly.** Every §14 question that depends on seeing the
game — is the opening compelling, are menus polished game UI or debug tooling,
does the level-up announce itself, is night legible with and without torch, does
weather have identity, does the finale pay off, does the map help — has **no
evidence in this run**, in either direction. Those are coverage gaps. None of
them may be recorded as a pass.

The one exception is X07, and it is the only reason any visual judgment below
exists at all.

---

## 3. §14 judgment, question by question, with the evidence or the gap

| §14 question | verdict | basis |
|---|---|---|
| Can a new player understand the game? | **NO EVIDENCE** | The opening ran, but no frame of it exists and the objective ladder never advanced past rung 1. |
| Is the opening compelling? | **NO EVIDENCE** | GF-02-START-01/02/03 all absent. |
| Always meaningful near-term purpose? | **FAILS on the only evidence there is** | The tracked line said "Catch your first wild creature." for 100% of a ten-segment journey. Whatever the cause, no run of this game has yet demonstrated the guided ladder advancing. |
| Does exploration reward attention? | **PARTIAL PASS** | S05 is the only honest sample: median `nearest_poi_dist_m` **9.9 m**, max 98.1 m over 1,243 samples on the village→pond→bridge corridor. The world along that route is **densely populated**, not empty. |
| Routes empty, overloaded, or well paced? | **ONE FINDING** | Exactly one dead-travel interval ≥250 m in the only valid sample: **329.8 m over 53.9 s**, (301,960)→(68,1196), the last leg of the pond→bridge corridor. §D's own threshold makes that a finding. Eleven of thirteen named routes have **no measurement**. |
| Does the world feel authored? | **MIXED — see §4** | X07 frames only. |
| Are creatures worth finding/caring about? | **NO EVIDENCE** | Party never exceeded 1; no catch, no bond movement, no care/rest, no level-up ever observed. |
| Is combat fair, readable, satisfying? | **NO EVIDENCE, but it stages** | One fight in the whole run (X01 t=753). `target_on_screen: true` at start is a real positive signal. Nothing about fairness, readability or difficulty is measurable from one 13-second fight. |
| Is progression earned without grind? | **NO EVIDENCE** | Zero `level_up` events run-wide. |
| Does building matter and feel good? | **NO EVIDENCE** | X02 armed no ghost and placed no piece; S03 gathered nothing. The economy was never paid. |
| Are rest/care useful? | **NO EVIDENCE** | Zero `rest`/`feed` events — and no emitter exists for them (§5.3). |
| Are controls predictable? | **PASS, narrowly** | The only trustworthy input evidence in the run — 115 in-context cells — is 115/115 clean. That is real but it is 27% of the planned matrix. |
| Are menus polished game UI or debug tooling? | **ONE REAL FAILURE VISIBLE** | The `TEAM 0/5` roster block renders **dead centre of the viewport**, covering the player's forward view (frame `000312.88`). Everything else about menus is unphotographed. |
| Is the map genuinely useful? | **WEAK EVIDENCE** | The minimap renders and moves with the player in every X07 frame; it shows terrain, roads and pins. The full Map tab was opened but never photographed; zoom persistence untested. |
| Does every region have identity? | **MOSTLY YES, TWO FAILURES** | §4. |
| Is Team Tether/story pressure legible? | **YES** | Frame `003712.84`: pylons, crystals, strung teal cables, a stone gate and a `Challenge Captain Vance` prompt. The occupation grammar reads at a glance. This is the run's clearest artistic success. |
| Does the chapter escalate? | **PARTIAL** | Visually yes across village → relay → Hall. Mechanically unmeasurable. |
| Does the finale pay off? | **NO EVIDENCE** | Never reached. |
| Is ROG Ally performance acceptable? | **[OWNER-ONLY]** | Nothing in this envelope can answer it. But see §4.4 — there is one CPU finding that is real. |
| Would a player voluntarily keep playing? | **NO** — on the evidence that exists | A player who presses New Game waits ~50 s at a frozen screen (§4.4), and the only objective the game ever showed anyone in this run was its first one. |

---

## 4. What the 79 X07 frames actually show

The only visual evidence in the run. I read them; brightness-sampled all 79 over
a world-only crop to avoid grading HUD as world.

### 4.1 The world is genuinely attractive, and that is a real result

`000312.88` (village arrival): rolling meadow, layered mid-ground trees, rock
outcrops, distant mountains, believable sky and cloud, grass with actual
variation. `001085.26` (pond): dense mature forest, tall foreground grass,
timber-framed building. `005948.91` (Hall): crenellated walls, towers, a flag, a
warm-lit archway, barrels and crates. This does not read as programmer art.

### 4.2 Region-by-region identity

| region | reads as itself? | note |
|---|---|---|
| Grandpa's Village | **yes** | settled, layered, legible entry |
| The Rise | **cannot tell** | its arrival frame `000640.26` renders **black** (world-crop mean 15.8/255 vs 69–94 for the region's other frames) |
| The Pond | **partly** | lush and distinct, but no water in the arrival frame |
| The Old Quarry | **NO** | `002431.78` shows meadow, a signpost, dead trees, one boulder. No pit, no rock face, no excavation, no worked stone. Nothing announces "quarry". |
| The Burrow Warrens | yes | |
| The Tether Relay | **strongly yes** | best frame in the run |
| The Long Water | yes | |
| The Ironwood Grove | yes | |
| The Ridgeline Watch | yes | |
| Stronghold approach | yes | |
| The Hall | yes | but see 4.3 |

### 4.3 Visible defects, each with its frame

1. **A black sphere hangs in mid-air in the Hall's gateway arch** — `005948.91`,
   dead centre of the archway the player walks through. Untextured/missing-
   material placeholder at the chapter's climactic threshold.
2. **The Rise's arrival renders black** — `000640.26`. HUD and minimap draw
   normally; the world does not.
3. **The hotbar shows placeholder glyphs, not item icons** — four white/red
   cross marks and one red `B`, identical in **every controller frame in every
   region** (`000640.26`, `001085.26`, `002431.78`, `003712.84`, `005948.91`).
   The KBM frame `000312.88` shows plain digits 1–5 in the same strip. The
   player's satchel at this point holds `orb_basic ×15`, `potion_small ×3`,
   `berries ×5`, `revive ×2` (verified in `S03/saves/S03-exit.json`) — real
   items with no icons on screen.
4. **`TEAM 0/5` + five `OPEN SLOT` rows render dead centre of the viewport** —
   `000312.88`, directly over the player's forward view.
5. **Flat untextured ground planes** at the Tether Relay and the Hall
   (`003712.84`, `005948.91`) — uniform beige with no detail, against
   fully-detailed grass 200 m away. The two most story-critical spaces have the
   least-finished ground.
6. **An NPC renders as an unlit near-black silhouette** — `003712.84`, right
   edge, standing in full daylight beside a correctly-lit player.
7. **Signpost text clipped at the screen edge** — `002431.78`, "Trail Spoke" cut
   off; the sign is a flat plank at an odd angle.

### 4.4 The one real performance finding

Reproducible, and **not** a rendering artifact — the journey ran headless with no
rasteriser at all:

| segment | worst frame | when | context |
|---|---|---|---|
| S02 | **50,236 ms** | t=56.2 | grandpas_village |
| S03 | **50,720 ms** | t=57.3 | grandpas_village |
| S05 | **50,245 ms** | t=56.6 | grandpas_village |
| S06 | 49,230 ms | t≈56 | |
| S08 | **49,443 ms** | t=55.9 | corridor |
| S09 | 49,917 ms | t≈56 | |

**Exactly one frame per segment, at t≈56 s, takes ~50 seconds.** The title screen
boots in ~380 ms; pressing Start New Game / Load then blocks the process for
**49–51 s** while the world stands up. Six of eight segments, identical shape.

Everything else is healthy: across **36,744** route samples, CPU frame time
mean 15.8 ms, **p95 8.31 ms**. Strip the six stand-up frames and the journey's
CPU shape is fine.

**Bounding this honestly:** this is CPU time in a Linux container, not device
frame rate. Device FPS, GPU time, VRAM, thermals and battery remain
**[OWNER-ONLY]** (§K.1) and are not claimed here. X07's ~9,416 ms/frame is
llvmpipe software-rasterising 762,058 props with no GPU and **is not a game
performance number**. But a ~50-second blocking frame measured with the renderer
switched off is a CPU cost that no GPU will fix, and a player meets it at the
first button they press.

---

## 5. Root-cause clusters

Five causes account for every symptom in the run. Two are game clusters; three
are Gate F's own instrument.

### RC-1 — The journey never got past the first catch *(cascade origin)*
Owns: all 26 "objective did not advance", all 10 "party size N wanted M",
every unset gate flag, the shut South Bridge, S06–S10's 115 km of churn, and
the total absence of combat/catch/gather/craft/build/rest/care/tournament/
finale evidence. **One cause, ~120 of the 202 journey FAILs.** Its own cause is
RC-3, not the game.

### RC-2 — World stand-up blocks for ~50 s *(real game defect)*
Owns: the six ~50,000 ms frames. Player-visible as a freeze at New Game / Load.

### RC-3 — The harness cannot drive the game's own systems *(instrument)*
Owns: 72.5% of X01 cells probed in the wrong context; 12 named surfaces never
entered; the SwapPanel "hold"; the Settings sweep running inside a dialogue;
every "did not reach (x,z)" walk failure; the killed-then-uncatchable
bramblebun; X02's unarmed ghost. Failure modes are consistent and nameable:
**(a)** dialogue press-counts guessed per conversation and never verified;
**(b)** `move_to` compares x/z only and cannot express "be next to the thing";
**(c)** cell probes never re-establish their intended context between cells;
**(d)** no step ever presses the documented dismissal for a station panel.

### RC-4 — Prescribed visual evidence does not exist *(instrument)*
Owns: 9,231 absent frames, the missing `shots/` directory, all 22 §G classes,
and roughly half of §14's questions being unanswerable.

### RC-5 — World composition and UI finish *(real game defects)*
Owns: the Hall's floating black sphere, The Rise's black arrival, the Quarry's
missing identity, the untextured relay/Hall ground, the unlit NPC, the clipped
signpost, the centre-screen roster block, the placeholder hotbar glyphs.

### RC-6 — Telemetry schema partly unimplemented *(instrument)*
`operator_harness.gd` has **no emitter** for `catch_throw`, `combat_hit`,
`combat_switch`, `dialogue`, `gather`, `craft`, `build_place`, `build_cancel`,
`build_dismantle`, `rest`, `feed`, `landmark_discover` or `defect` — 13 of the
§C.1 enum's types. Their absence from the run therefore proves **nothing** about
the game and must never be cited as evidence. Additionally: the `inventory`
field reports `{"axe": 0, "berries": 0, "orb_basic": 0, …}` on save events while
the very save it describes contains `orb_basic ×15, potion_small ×3, berries ×5,
pickaxe, knife, torch, revive ×2, axe`; and **no `save`/`load` event anywhere in
the run carries `duration_ms`**, so §18's required save/load timings do not
exist.

---

## 6. The authoritative question

*If this were handed to a real player as a finished Meadows chapter, what would
make them stop playing — and what evidence proves it?*

Two things are provable from this run:

1. **They would wait ~50 seconds at a frozen screen before the game started**,
   every time, measured six times at 49–51 s with the renderer off.
2. **If anything went wrong in the first five minutes, the game would never tell
   them anything else.** The guided ladder's rung 1 is a hard gate on the entire
   24-objective chain, and this run is 1,456 events of what that looks like from
   the inside: a correct, unchanging line of text over a world with nothing left
   to say.

Everything else a player would react to — how the game feels, whether combat is
fair, whether the team is worth caring about, whether the finale lands — **this
run cannot tell us**, and the honest report of that is a coverage gap, not a
verdict.

**Gate F does not pass.** Not because the candidate is judged bad — it is very
largely *unjudged* — but because §18's exit criterion requires that a candidate
*survive the full authoritative protocol*, and this run executed roughly a
quarter of it. The correct next action is to fix the instrument (RC-3, RC-4,
RC-6) and re-run, not to fix the game against these numbers.
