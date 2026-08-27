# Gate F Phase B — reviewer log

Reviewer: Opus, performing the `ralph/GATE_F_PROTOCOL.md` §Model-roles "Fable"
role (Playtest Director / Product Reviewer). Role defined by isolation and
inputs, not by model.

Candidate under test: `f082bdf6265760ca9835e1065361fbbf87475d69`.
Evidence: `ralph/reports/gate-f-run-20260827T025303Z/`.
Branch: `ralph/GATE-F-PHASE-B`.

Quarantine held: I have not opened `gate-f-lane-log.md`, either
`GATE_F_RUN_HANDOVER_*`, `gate-f-historical-snapshot.md`, `ralph/BACKLOG.md`,
`ralph/DONE.md`, `ralph/BLOCKED.md`, `ralph/ACTIVE_TASKS.md`,
`ralph/ASSESSMENT_2026-08-23.md`, `ralph/OWNER_PLAYTEST_*`, or any prior
gate-f run directory. This log records the moment quarantine is broken.

---

## Check-in 1 — inputs read, evidence inventoried

Read in full: `ralph/GATE_F_PROTOCOL.md`, `ralph/GATE_F_MASTER_PROTOCOL.md`,
`SHA_PROVENANCE.md`.

Two corrections to the brief I was given, both in the evidence's favour and
both recorded before analysis:

1. **X02 did run.** My brief listed X02 among "not run". `HEAD` (`b898182`)
   carries `Gate F: X02 evidence -- 149 PASS / 21 FAIL; the build lab builds
   nothing`, and `X02/telemetry/events.jsonl` has 226 events. X02 is
   therefore live evidence and I judge it. X03–X06 and X08 remain not run.
2. **The run captured no journey frames at all.** Every segment except X07
   ran `--headless` with no display server. Across S01–S10, X01, X02 and
   `overhead`: **9,231 planned frames, 0 captured**, every one carrying
   `reason: "headless: this process has no display server and cannot render
   a frame"`. X07 is the sole lane with images.

Consequence, stated before I analyse anything: the entire §11/§G prescribed
screenshot plan and the §H continuous-evidence plan are unexecuted outside
X07. Every §14 judgment question that depends on seeing the game — opening
presentation, dialogue UI, HUD, menus-as-game-UI, level-up announcement,
night/torch legibility, weather identity, world authorship along the route,
finale staging — has **no evidence in this run** and cannot be answered
either way. That is a coverage gap, not a pass.

Next: journey telemetry and operator notes, S01→S10.

---

## Check-in 2 — first-order adjudication complete (game defect vs. harness artifact)

The brief named three findings that would dominate my reading. I measured all
three before writing a single backlog item. **All three are harness artifacts.**
Detail and method in `ADJUDICATION.md`; headline results:

**Finding 1 — "input ownership taken and never handed back."** Refuted.
- X01's matrix: of 418 (control, context) cells, only **115 were injected in
  the context the step names**. 303 (72.5%) were injected somewhere else
  entirely — 8 different named surfaces were all actually probed in
  `menu_map`. **All 115 in-context cells PASSED. Zero confirmed collisions.**
- `menu_cancel` closed a menu successfully **84 times** in X01 (from every tab
  including Settings, Save, Quests, Build); 138 close/leave steps passed
  against 6 failures, and those 6 read as T07's own "one layer per press".
- The `panel:SwapPanel` hold in S03 — 1,391 s, 83.9% of the segment, the
  strongest-looking defect in the whole run — is an artifact. The panel is
  Oskar's creature shop (`shop:creatures:oskar`). During the entire hold the
  harness pressed 125 inputs and **`menu_cancel` zero times**, which is the
  one action `swap_panel.gd:126` listens for. Code inspection confirms the
  panel sets `PROCESS_MODE_ALWAYS`, grabs focus on open, and closes on B.
- The Settings 126-cell stress case, rebind and panic reset (X01-1015…1033)
  ran **entirely inside `narrative_modal`** — an unanswered dialogue. "130 ×
  ui_down did not move focus" is ui_down against a dialogue box. Focus works:
  the same run logs `focus_owner -> @Button@94239`.

**Finding 2 — "no fight ever stages."** Refuted, by this run's own data.
X01 t=753.13 stages a real fight: opponent Bramblebun, `opponent_hp 100.7`,
`my_hp 117.6`, **`target_on_screen: true`**, `narrative_modal → combat`, clean
`combat_end` back to `world` 13.3 s later. Combat stages, acquires its target,
owns input and hands it back. The journey lane's zero `combat_*` is the
harness failing to engage, not the game failing to fight.

**Finding 3 — "the South Bridge never opens."** Confirmed as an observation,
but as a **cascade**, not an independent defect — see check-in 3.

**The root cause of the journey lane is a single one.** The tracked objective
reads `opening:beat:road` / "Catch your first wild creature." in **all 1,456
journey events, S01 event 1 through S10 event 196.** It never advances because
the first wild catch never happens; the operator's own S02-36 note measures
why (the catch step-script killed the bramblebun — hp 124.2 → 0.0 — before the
orb was thrown, and the retuned attempt then never staged the fight at all).
Every downstream symptom — party stuck at 1, all gate flags unset, the bridge
shut, 26 "objective did not advance" failures, S06–S10's 115 km of churn — is
one cause with ten segments of consequences.

**What this costs the run.** The journey lane cannot support conclusions about
combat, catching, gathering, crafting, building, care/rest, progression,
economy, difficulty, tournament, story or the finale. Those are **coverage
gaps**, not clean bills of health.

Quarantine still held.

---

## Check-in 3 — deliverables 1 and 2 frozen (§16.2 discharged)

Written and committed **before** any quarantine break:

- `ADJUDICATION.md` — §14 blind analysis, §14 root-cause clustering, the
  defect-vs-artifact adjudication, the X07 visual read.
- `PROVISIONAL_BACKLOG.md` — 13 items (4 SHIP BLOCKER, 7 QUALITY BLOCKER,
  2 POLISH), 5 named unresolved questions with settling experiments, and an
  explicit coverage-gap list.
- `PROVISIONAL_BACKLOG.sha256` — the §16.2 version hash.

```
ff3d5e6594196b64e13e71efead885edd61f8f558ef080311c9807bee5a6b23d  PROVISIONAL_BACKLOG.md
9f8266ee2502a758351b6d40334ca4770759301c743e087f96bcbb585e5e1db5  ADJUDICATION.md
```

Additional findings since check-in 2, all in the provisional backlog:

- **~50 s blocking frame at world stand-up**, 6/8 segments, t≈56 s, 49–51 s,
  measured **headless** so no rasteriser is involved. Whole-journey CPU p95 is
  8.31 ms over 36,744 samples — the shape is otherwise healthy. This is the
  run's clearest real game defect.
- **No prescribed screenshot exists anywhere in the run.**
  `operator_harness.gd:1212` writes captures to `shots/<id>.png`; there is no
  `shots/` directory and no `GF-*.png` file in the run, and git has never
  carried one. 551 PNGs total in 921 MB = X07's 550 background frames plus
  `capture_smoke.png`. X07's `WHY_INCOMPLETE.md` claims 79 completed captures;
  23 of those 79 timestamps have no background frame within 3 s, including the
  §E.7-required HUD-on `-gameplay` frame for all 11 regions.
- **13 of the §C.1 event types have no emitter at all** — so their absence
  proves nothing, and `catch_result` fires on party growth (the starter
  loading), not on a catch.
- **The `inventory` telemetry field is wrong**: it reports all-zero against a
  save containing 15 orbs. No `save`/`load` event carries `duration_ms`.
- **X07 visual read**: the world is genuinely attractive; the Tether Relay is
  the run's strongest frame; but a **black placeholder sphere hangs in the Hall
  gateway**, The Rise's arrival renders black, the Old Quarry does not read as a
  quarry, relay/Hall ground is untextured, an NPC renders as an unlit
  silhouette, the hotbar shows placeholder glyphs, and the `TEAM 0/5` roster
  draws over the centre of the screen.
- **S05 pacing** (the only valid sample): one dead-travel interval ≥250 m —
  **329.8 m over 53.9 s** — against a corridor whose median
  `nearest_poi_dist_m` is **9.9 m**. The route is well populated; this is one
  gap, not a pattern. **No chapter total and no 3–4 h D42 projection exists from
  this run**, and none can be inferred from elapsed wall clock.

**Quarantine breaks now**, deliberately and on the record, to begin §16.3
historical reconciliation. Everything above is frozen and hashed.
