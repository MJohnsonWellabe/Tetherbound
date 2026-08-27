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

---

## Check-in 4 — deliverables 3 and 4 (quarantine broken, on the record)

Quarantine broken at commit `092c229`, after the provisional backlog was hashed.
Opened: `ralph/reports/gate-f-historical-snapshot.md` (208 items).

- `RECONCILIATION.md` — all **162 player-facing** historical items classified
  into exactly one §16.3 category, with the §16.5 capture rate.
- `COVERAGE_DEFECTS.md` — §16.4 loop, CD-1…CD-7.

**Capture rate: 13/162 = 8.0% independent rediscovery; 8.6% broader.**

| category | n |
|---|---|
| REDISCOVERED | 13 |
| STILL VALID — NOT NATURALLY ENCOUNTERED | 8 |
| COVERED BY BROADER ROOT CAUSE | 1 |
| NOT REPRODUCED | 2 |
| **MISSED BY GATE F / COVERAGE DEFECT** | **138** |

I did not soften this. The live temptation was to file misses as "not naturally
encountered" — which reads as the run's limitation rather than the gate's
failure. Category 2 is for items a comprehensive run had no path to; **these had
a path, because Phase A planned it**, and the run did not walk it. Only 8 are
genuine declared §K gaps.

Per §16.5's own rule, **the historical backlog remains operationally
authoritative**. The Gate F backlog does not replace it on this run's evidence.

The 13 rediscoveries were made blind and several are sharper than the historical
entry — notably `HIST-085` "boot time on the device", now a measured 49–51 s
blocking frame reproduced in 6 of 8 segments with the renderer switched off.

138 misses reduce to **seven** causes (CD-1…CD-7), all instrument, all to be
fixed outside a run before a new candidate is frozen.

Next: deliverables 5 and 6 — final authoritative backlog and the six §15
summaries.

---

## Check-in 5 — deliverables 5 and 6; Phase B complete

- `FINAL_BACKLOG.md` — 13 items in the §15 format across three tiers, with
  historical context merged into the 13 rediscovered items. Three merges changed
  an item materially:
  - `HIST-018` reveals the quickbar crosses are **Kenney d-pad badges** with
    *no suitable asset in any pack* — owner-art-blocked, not a missing-icon bug.
  - `HIST-052` supplies the lead I lacked for the black-render items:
    `GATE-E-STRONGHOLD-ART` found **`art.json` putting the sun in the NORTH
    sky**, never re-checked. A north sun would leave south-facing approach
    geometry unlit — plausibly one cause behind GF-B-004, GF-B-008 and GF-B-010,
    and it reconciles the historical near-black/near-white LOD pair.
  - `HIST-163`/`HIST-165` turn my single quarry finding into a **three-site
    systemic item**: the landmark kit contains no landmark geometry.
- `SUMMARIES.md` — Top 10 experience failures, systemic root causes,
  regional/world plan, performance plan (bounded by [OWNER-ONLY]), regression
  plan, retest plan.
- `README.md` — reading order and the three takeaways.

**§16.6 scope decision, stated explicitly.** I did **not** rewrite the 138
`MISSED BY GATE F` items into the §15 format. Doing so would manufacture the
appearance of evidence I do not have. They stay in the historical register,
which per §16.5's own rule remains operationally authoritative. The Gate F
backlog is additive on this run.

**Gate verdict: Gate F does not pass** (§18 — the candidate did not survive the
full authoritative protocol; roughly a quarter of it executed). The candidate is
largely **unjudged**, not judged bad.

Phase B complete. Nothing outstanding.

---

## Check-in 6 — post-publication addendum: the grass field is OFF on the candidate

Coordinator fact received 2026-08-27T13:16Z, after all six deliverables were
published. **I verified every claim against the candidate before acting on any
of it** — `git show f082bdf6:data/config/grass_field.json` (`"enabled": false`),
`grass_field.gd:82/88/97` (flag read; `suppressed_layers()` returns `{}` when
disabled; `_ready()` returns early), `playground_world.gd:709` (node never enters
the tree), and a grep of the whole run directory for any `grass_field` trace
(none). All six claims hold.

**Nothing had to be withdrawn.** I never observed and never named the procedural
field, so no item claimed it was missing, wrong or regressed. `GF-B-009` compares
plaza ground against meadow ground **inside the same frame** — both scatter — so
it stands. What was missing was scoping.

Corrections applied (`ADDENDUM_GRASS_FIELD.md` records all of them):

1. `GF-B-009` now names the scatter system explicitly and carries the reserved
   owner decision as a dependency that may moot part of it.
2. `SUMMARIES.md` §3 names which ground system each regional judgment is about.
3. `SUMMARIES.md` §4 and `GF-B-001` record that the ~50 s stand-up was measured
   in the **maximum-placement** configuration — with an explicit warning **not**
   to read that as "enabling the field fixes the freeze": it trades a measurable
   CPU cost for an unmeasurable GPU one. [OWNER-ONLY], reserved, not recommended.
4. `COVERAGE_DEFECTS.md` gains **CD-8** — the freeze record enumerates no
   `data/config/` feature flags, though §1.2 requires graphics settings. This is
   the one coverage defect the run's own evidence could never have exposed.
5. `RECONCILIATION.md` gains a caveat: `HIST-041`'s remedy (`ground_blend`) lives
   in the disabled field, so nobody may close it from these frames in either
   direction. Same caution for `HIST-169`/`190`/`191`/`192`/`193`.
6. **`PROVISIONAL_BACKLOG.md` deliberately NOT edited.** It is the hashed §16.2
   record of what Gate F found blind; a later fact does not get retconned into
   it. `sha256sum -c` still verifies OK.

**Two things I found while verifying, which the Coordinator did not raise:**

- **CD-8b — the freeze record contradicts the artifacts.**
  `RUN_METADATA.json` says `"display_server": "X11 under xvfb-run"`; 9,231
  manifest rows say *"headless: this process has no display server"*. They
  disagree about the single fact that decided whether §11 could execute, and
  nothing reconciled them for the whole run. Strengthens `GF-B-003`.
- **CD-5's confidence rises to HIGH.** `RUN_METADATA.json`'s
  `suite_state_at_freeze.known_open_defect` records, at freeze time, that
  `tests/smoke_party_count_after_catches.gd` fails intermittently with *"could
  not engage the real wild body … (stopped 23.7m away (engage range 6.0m))"* —
  **the same defect I reconstructed independently from S02 telemetry.** The run
  was launched knowing the chapter's first required player action was unreliable.
  CD-5 now has a self-diagnosing reproduction already in the suite, far cheaper
  than re-running S02. Whether that state should have blocked the freeze is a
  coordinator judgment I raise rather than answer.

**No conclusion in any deliverable is reversed by this fact.** The gate verdict,
the three refuted headline findings, the 8.0% capture rate and the Top 10 are
unchanged.
