# Gate F Phase B — Deliverable 6: the six §15 summaries

Companion to `FINAL_BACKLOG.md`. Bounded by two standing rules:

- **[OWNER-ONLY]** (§K): device frame rate, GPU time, VRAM, thermals, battery,
  controller feel, 7" legibility, audio and Windows export identity are **never**
  claimed from this Linux container.
- **No §D chapter total and no 3–4 h first-clear projection against D42 exists
  from this run**, and none is inferred from elapsed wall clock.

---

## 1. Top 10 experience failures

Ordered by player impact × frequency × chapter criticality × confidence.

Ranks 1–2 are the honest top of the list: what would actually stop a player, and
the reason we cannot name what else would.

| # | failure | why it ranks here | evidence |
|---|---|---|---|
| 1 | **~50 s frozen screen on New Game / Load** | Every player, every session, at the first button pressed. The strongest impression the product currently makes is a hang. Measured with the renderer **off**, so no GPU fixes it. | `GF-B-001`; `frame_ms` 49,230–50,720 ms at t≈56 s in 6 of 8 segments |
| 2 | **The chapter is unaudited — we cannot say what else would stop a player** | Not a defect the player meets; the reason ranks 3–10 are shorter than they should be. Combat, catching, gathering, building, care, progression, the tournament, five gates and the entire finale were never exercised on this candidate. | `GF-B-002`; objective constant across 1,456 events; zero `combat_*`; party ≤ 1 |
| 3 | **A black placeholder sphere in the Meadows Hall gateway** | At the chapter's climactic threshold, in the arch the player walks through. Trust damage at the exact moment of payoff. | `GF-B-004`; frame `005948.91.png` |
| 4 | **The quickbar does not say what it holds** | Persistent, every region, every session. Four identical first-aid-cross badges over the slots — one of which is the catch orb, the chapter's first required verb. | `GF-B-005` + `HIST-018/004/156`; five frames across five regions |
| 5 | **The roster block sits over the middle of the screen** | Permanent, covers the forward view, reads as debug tooling. Owner-reported independently (OP23-09). On a 7" panel it covers most of what the player walks into. | `GF-B-006` + `HIST-136`; frame `000312.88.png` |
| 6 | **Named landmarks do not contain the thing they are named for** | The quarry has no quarry, the mill no wheel, the well no well. Directly defeats Vision §4's "what region am I in?" test. Found blind by Gate F; confirmed as a three-site pattern by history. | `GF-B-007` + `HIST-163/165`; frame `002431.78.png` |
| 7 | **Arriving at The Rise renders black** | A named region — and the landmark the opening points at — draws nothing. Independently ranked the second-biggest visual gap by a prior blind critic. | `GF-B-008` + `HIST-052`; frame `000640.26.png`, world-crop 15.8/255 |
| 8 | **The story-critical spaces have the least-finished ground** | Relay and Hall stand on flat untextured planes while ordinary meadow 200 m away is fully detailed. Escalation reads as *unfinished*, not *drained*. | `GF-B-009`; frames `003712.84.png`, `005948.91.png` |
| 9 | **Characters render as unlit silhouettes in daylight** | The chapter's antagonists do not read. Probably one lighting cause with #3 and #7. | `GF-B-010` + `HIST-180`; frame `003712.84.png` |
| 10 | **A 330 m stretch of the band-1 corridor with nothing in it** | The only §D finding the run can support. Ranked last deliberately: the same corridor's median POI distance is **9.9 m**, so this is one gap, not an empty world. | `GF-B-012`; `S05/route.csv` |

**What is not on this list, and why.** No combat, catching, progression, economy,
difficulty, tournament, care/rest or finale failure appears — not because those
systems are healthy, but because **none of them was exercised**. Absence here is
a coverage gap. It is the single most important thing to carry out of this
report.

---

## 2. Systemic root causes — fixes that eliminate multiple symptoms

| cluster | symptoms it owns | one fix, many symptoms |
|---|---|---|
| **RC-3 — the harness cannot drive the game** | ~120 of 202 journey FAILs, 118 X01 FAILs, 21 X02 FAILs, 12 never-entered surfaces, 115 km of churn, the SwapPanel "hold", the Settings sweep running inside a dialogue | **`GF-B-002`.** Three primitives — assert-context-before-proceeding, `advance_dialogue_until_closed`, `move_to_entity` — close every one. This is the highest-leverage item in the report. |
| **RC-1 — one missed catch cascades through ten segments** | 26 "objective did not advance", 10 party-size failures, every unset gate flag, the shut bridge, all of S06–S10 | Fixed **by** RC-3, not separately. Worth stating because it is the clearest demonstration in the repo's history that **the guided ladder's rung 1 is a hard gate on the entire 24-objective chain**. That is a design fact worth knowing even though it is not a defect: if a player is ever unable to complete the first catch, the game has nothing else to say to them. |
| **RC-5 — one lighting/material cause may own three visual defects** | black sphere in the Hall arch; The Rise rendering black; NPC unlit in daylight; historically, near-black distant trees **and** near-white distant LOD, never reconciled | **Check `art.json`'s sun azimuth first.** `HIST-052` records `GATE-E-STRONGHOLD-ART` finding the sun placed in the **north** sky, never re-checked. A north sun leaves south-facing approach geometry unlit — the exact symptom, three times. Cheapest possible diagnostic; would close `GF-B-004`, `GF-B-008`, `GF-B-010` and reconcile `HIST-126`/`180`/`039`/`071`/`093`. |
| **RC-5b — landmark kit has no landmark geometry** | quarry, mill, well; `HIST-164` "three named landmarks are two kits used twice"; `HIST-166` "bridges and gates are overlapped fence panels" | **`GF-B-007` as one item with three sites.** The generic structural kit cannot express a named place; the fix is landmark-specific geometry, not more kit assembly. Check `HIST-008`/`HIST-119` for owner-art blocks first. |
| **RC-5c — the HUD's permanent chrome** | roster block centre-screen; quickbar unreadable; mixed glyph languages; `HIST-136` (owner-reported), `HIST-153`, `HIST-154`, `HIST-013`, `HIST-014` | **`GF-B-006` re-proportions the corner and unblocks `HIST-036`** (`OBJECTIVE-HINT-ON-HUD`), which the register already sequences behind it. Sequence with `GF-B-005` — same file. |
| **RC-4 / RC-6 — the evidence system does not evidence** | 9,231 absent frames, no `shots/`, 13 unemitted event types, wrong inventory field, no save/load durations | **`GF-B-003` + `GF-B-011`.** Without these the next run is unjudgeable in the same way this one was. |
| **RC-2 — world stand-up blocks the main thread** | the six ~50,000 ms frames | **`GF-B-001`.** Standalone; start at the scatter/placement bake per `HIST-085`. |

---

## 3. Regional / world plan

Grounded in the only regional evidence that exists: X07's 79 frames over 11
regions. **Journey arrivals were never photographed**, so every judgment below is
from a DIAG teleport camera, not the player's intended approach vector — which is
itself a finding (`GF-B-003`).

| region | state | work |
|---|---|---|
| **Grandpa's Village** | reads as a settled place; layered, legible | none from this evidence beyond the HUD items |
| **The Rise** | **cannot be assessed — arrival renders black** | `GF-B-008`; check sun azimuth first |
| **The Pond** | lush, distinct, the approved reference quality holds | no water in the arrival frame — verify the shore frame before concluding |
| **The Old Quarry** | **no regional identity**; reads as ordinary meadow | `GF-B-007` — excavated geometry, worked stone, visible rootstone |
| **The Burrow Warrens** | renders; interior unassessed | needs the journey lane |
| **The Tether Relay** | **the run's strongest frame.** Pylons, crystals, strung teal cables, stone gate, a live challenge prompt. The occupation grammar reads at a glance. | ground plane (`GF-B-009`); NPC lighting (`GF-B-010`) |
| **The Long Water** | renders | needs the journey lane |
| **The Ironwood Grove** | renders; brightest region sampled | needs the journey lane |
| **The Ridgeline Watch** | renders; the one elevated-hue cluster in the colour check, recovering on the next region | monitor |
| **Stronghold approach** | renders | ground plane |
| **The Hall** | real castle silhouette — crenellations, towers, flag, warm-lit arch | **`GF-B-004`** placeholder sphere; ground plane |

**Sequence.** Lighting investigation (RC-5) → `GF-B-004` → `GF-B-007` (three
sites) → `GF-B-009` → `GF-B-013`. Then re-run X07 **with `shots/` actually
written** and judge the regions that this run could only sample.

**Not assessable at all from this run:** every region's *ecology cadence,
trainer presence, gathering opportunity, optional discovery, memorable encounter
and camp/recovery* — i.e. six of Vision §8's fourteen finished-region criteria.
Those need the journey lane.

---

## 4. Performance plan

**Strictly bounded.** Everything here is CPU on a Linux container with no GPU.
Device frame rate, GPU time, VRAM, thermals and battery are **[OWNER-ONLY]** and
are not claimed.

**What is measured and real:**

| measurement | value | note |
|---|---|---|
| journey CPU frame time | mean 15.8 ms, **p95 8.31 ms**, n=36,744 | healthy once the stand-up frame is excluded |
| **world stand-up** | **one frame of 49,230–50,720 ms**, 6 of 8 segments, t≈56 s | `GF-B-001`. Headless — no rasterisation involved |
| title boot | ~380 ms | fine |
| save / load durations | **not instrumented** | `GF-B-011`; §18 requires them |

**What is explicitly not a performance number.** X07's ~9,416 ms/frame is
llvmpipe software-rasterising **762,058 props** with no GPU. It says nothing
about the game's speed. The prop count itself is real and worth carrying to the
owner pass: the same measurement path recorded 466,922 props at a previous
check-in, so **placements have risen ~63%** and the software-raster cost ~3×.
That is a *scale* signal, not a frame-rate one.

**Plan.**

1. `GF-B-001` — find and fix the ~50 s blocking frame. Start at the scatter /
   placement bake (`HIST-085` traces the history: 58–60 s → ~1.3 s → roughly
   doubled again by the corridor rebuild, placements 10.4 s + batch build 8.4 s).
2. Instrument save/load `duration_ms` (`GF-B-011`) — §18 requires them and they
   do not exist.
3. Run **X08**, which never ran, once the harness is fixed.
4. Carry the 762,058-prop count and `HIST-001`/`HIST-042`/`HIST-043`/`HIST-044`
   to the **owner's device pass**. Those remain the only route to a real
   ROG Ally answer, and this run changes nothing about them.

---

## 5. Regression plan

Ordered by what would have caught the most in this run.

**Would have caught this run's own failures:**

1. **Capture pre-flight gate** — BLOCK a segment with planned captures when no
   display server is present. Would have stopped 9,231 false PASSes at step 1.
2. **Artifact inventory as code** (§M) — fail a segment when a manifest row
   claims a file that is absent. Would have caught the missing `shots/`.
3. **Probe context conformance** — fail a matrix segment when
   `intended_context ≠ context_before` on > 5% of cells. Would have caught the
   72.5% mismatch.
4. **Post-dialogue context assert** — after any dialogue step, `input_context`
   must not be `narrative_modal`. Would have caught `X01-463` and the S03 pin.
5. **Telemetry/save conformance** — assert the `inventory` snapshot equals the
   written save. Would have caught the all-zero inventory field.
6. **Schema conformance** — every §C.1 type emitted by a self-check or marked
   `not-instrumented`.

**Would catch the game defects this run found:**

7. **Boot-timing test** — assert max single-frame time across title→world,
   headless, in CI (`GF-B-001`).
8. **Missing-material detector** over audit frames — pure-black / untextured
   object detection, extending X07's existing colour spot-check (`GF-B-004`).
9. **Near-black world-crop detector** — the existing check looks for
   hue-rotation artefacts and would not have flagged The Rise (`GF-B-008`).
10. **HUD central-exclusion-zone assertion** in the handheld-legibility test
    (`GF-B-006`).
11. **Filled-hotbar-slot distinctness test** (`GF-B-005`).
12. **RT-05 dead-travel ceiling** in the corridor probe (`GF-B-012`).

**A standing rule worth more than any single test.** This run marked a step
**PASS** when it could not produce the evidence the step existed to produce
("capture skipped (headless run)"), and marked cells PASS while probing the wrong
surface. *A step that cannot gather its evidence is not a pass.* Encode that in
the harness, not only in the protocol prose.

---

## 6. Retest plan

Which Gate F segments must be replayed after each cluster lands.

| cluster | segments to re-run | gate on the re-run |
|---|---|---|
| **`GF-B-002` (harness drives the game)** | **S02 first, alone** | party reaches 2 **and** the tracked objective advances off `opening:beat:road`. If S02 does not clear this, nothing else runs. |
| | then S01–S10 in order | each segment hands off a save whose flags advance; `combat_*` events appear; a `catch_throw` resolves |
| **`GF-B-003` (captures)** | every segment with a planned capture; **X07 in full** | `shots/` non-empty; `INVENTORY.json` written; all 22 §G classes present or carrying a real reason |
| **`GF-B-011` (telemetry)** | self-check, then any journey segment | every §C.1 type emitted or marked; `inventory` equals the save; save/load carry `duration_ms` |
| **`GF-B-001` (stand-up)** | S01 + S02 | no frame > 500 ms title→control, headless |
| **`GF-B-004` / `GF-B-008` / `GF-B-010` (lighting cluster)** | X07 hall / the_rise / relay grids; S09 Hall threshold; S07 relay | frames clean; the near-black **and** near-white LOD defects reconciled together |
| **`GF-B-005` / `GF-B-006` (HUD)** | S02 after Grandpa's gifts; S03 village; X01 menu sweep | a stocked quickbar frame where contents are identifiable; no persistent HUD in the central third |
| **`GF-B-007` (landmarks)** | S06 RT-06, S03 well, S07 mill crossing; X07 quarry grid | each site contains the object it is named for, from the intended approach |
| **`GF-B-009` / `GF-B-013`** | S07, S09, S06 | visual-judge pass |
| **`GF-B-012` (pacing)** | S05 RT-05 | dead-travel peak < 250 m or a recorded breathing-room decision |

**Then, and only then, the segments that have never run at all:** **X03**
(catching lab), **X04** (combat lab), **X05** (save/session lifecycle), **X06**
(abuse sweep), **X08** (performance audit). Their absence is a coverage gap, not
a clean bill of health, and Gate F cannot be called complete while five of its
eight study segments have never executed.

---

## Gate verdict

**Gate F does not pass**, on §18's own criterion: the candidate did not survive
the full authoritative protocol. Roughly a quarter of it executed.

The candidate is very largely **unjudged**, not judged bad — and on the evidence
that does exist, the world is genuinely attractive, the Team Tether occupation
grammar reads, combat stages correctly when it is reached, the band-1 corridor is
well populated, and the only trustworthy input evidence in the run is 115 cells
of clean behaviour.

The correct next action is **Tier 0 — fix the instrument — then re-freeze a
candidate and re-run.** Tier 1 can proceed in parallel; it does not depend on the
harness.

Remediation must not be driven from this run's raw FAIL counts. Three of the
four loudest findings in it were not defects, and the §16.5 capture rate of
**8.0%** is the measure of how far Gate F still is from being able to replace the
backlog it was built to replace.
