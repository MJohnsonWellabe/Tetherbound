# Gate F Phase B — Deliverable 5: FINAL authoritative backlog (§15 / §16.6)

Published after blind analysis (`ADJUDICATION.md`), the frozen provisional
backlog (`PROVISIONAL_BACKLOG.md`, sha256 `ff3d5e65…`), historical
reconciliation (`RECONCILIATION.md`) and the §16.4 loop (`COVERAGE_DEFECTS.md`).

## Scope of this backlog — read first

§16.6 normally makes this list *the* active source of truth. **On this run it
does not, and saying otherwise would be the single most damaging thing this
report could do.**

The §16.5 capture rate is **8.0%**. §16.5's own rule: *"A weak capture rate
means Gate F is not yet authoritative enough. Improve the protocol before
allowing the old backlog to lose operational importance."*

Therefore:

- **`ralph/BACKLOG.md` and `ralph/reports/gate-f-historical-snapshot.md` remain
  operationally authoritative.** They are not superseded and must not be retired.
- **This list is additive**: the 13 items Gate F earned from evidence, in the
  §15 format, with historical context merged where the two agree.
- The **138** items classified `MISSED BY GATE F / COVERAGE DEFECT` are **not**
  rewritten here. Rewriting 138 items I did not independently find into an
  evidence-oriented format would manufacture the appearance of evidence I do not
  have. They stay in the register, unchanged and authoritative, until a re-run
  either finds them or clears them. That is §16.6's spirit — no task grandfathered
  in — applied in the only direction the evidence permits.

**Prioritised by player impact × frequency × chapter criticality × confidence.**
Not by ease. Confidence is on every item; this run's history is one of
high-confidence findings withdrawn on measurement.

---

# TIER 0 — do these before anything else

These three are the instrument. Until they land, no Gate F number means anything
and no other item on this list can be verified by a re-run.

## GF-B-002 — Gate F cannot drive the game, so the chapter is unaudited
`SHIP BLOCKER` · confidence **HIGH** · cluster **RC-3** · size **L** · role: coordinator + tooling developer

- **Player-visible problem:** none directly. This is the reason we do not know
  whether there are any. Combat, catching, gathering, crafting, building, care,
  rest, progression, the tournament, five band gates, the Warden, the legendary
  choice and the release ceremony are all **unexercised on this candidate**.
- **Violated requirement:** §18 — Gate F completes only when a candidate
  *survives the full authoritative protocol*.
- **Evidence:** tracked objective `opening:beat:road` constant across **all
  1,456 journey events** (S01 e1 → S10 e196); **zero** `combat_*` in S01–S10;
  party never exceeded 1; S06–S10 walked **115.0 km** inside a ~25 m corridor
  (S07 17.3 km, S08 35.9 km, S09 11.8 km, S10 40.9 km, all x∈[−6,25],
  z≤1328); X01 injected **303/418 (72.5%)** cells in the wrong context and never
  entered 12 named surfaces; X02 armed no ghost and placed nothing.
- **Reproduction:** re-run any journey segment.
- **Measured data / root cause detail:** `COVERAGE_DEFECTS.md` CD-3, CD-4, CD-5.
  Three named mechanisms: guessed dialogue press counts (`X01-709` interact ×6,
  fight staged **269 s** later; `S02-28` "every tap past the third can re-open
  the conversation the previous tap just closed"); `move_to` compares x/z only
  (`S02-15` "pressed `interact` 31 times through the floor"; 65 `did not reach`
  failures); cell probes never re-establish their intended context.
- **Desired outcome:** a harness that reaches a state and **asserts it before
  proceeding**, instead of pressing a guessed number of times and recording
  whatever follows.
- **Acceptance criteria:** every context-reaching step blocks on that context,
  bounded, then BLOCKERs; `advance_dialogue_until_closed` replaces fixed press
  counts; `move_to_entity(id, within_m)` and `interact_with(id)` exist and assert
  the prompt; a cell whose context assert fails records `SKIPPED`, never PASS and
  never FAIL; **a re-run of S02 reaches party size 2 and advances the tracked
  objective off rung 1.**
- **Regression coverage:** harness self-check failing loudly when a probe's
  `context_before ≠ intended_context`; a walk-and-interact self-check against
  Grandpa, a harvest node and a wild creature.
- **Player-path retest:** S02 first, then the full S01–S10 chain.
- **Visual review:** n/a.
- **Dependencies / ownership:** `tools/gate_f/**`. Must land **outside** a run
  (§13) and **before** a new candidate freeze (§1.5).
- **Parallel-safety:** blocks every item needing journey evidence. Owns
  `tools/gate_f/**` exclusively alongside GF-B-003 and GF-B-011 — one agent,
  three items, or they collide.

## GF-B-003 — No prescribed screenshot exists anywhere in the run
`SHIP BLOCKER` · confidence **HIGH** · cluster **RC-4** · size **M** · role: tooling developer

- **Player-visible problem:** none directly; it is why roughly half of §14's
  questions are unanswerable in either direction.
- **Violated requirement:** §11 and §G (the anti-cherry-picking mechanism); §H
  (continuous evidence); §M (the inventory check).
- **Evidence:** **9,231 planned frames, 0 captured** across S01–S10, X01, X02
  and `overhead`, every row `reason: "headless: this process has no display
  server and cannot render a frame"` — and every one of those steps returned
  **PASS**. `operator_harness.gd:1212` writes captures to `shots/<id>.png`;
  **no `shots/` directory and no `GF-*.png` exists anywhere in the run**, and git
  has never carried one. Total PNGs in 921 MB: **551** = X07's 550 background
  frames + `capture_smoke.png`. X07's `WHY_INCOMPLETE.md` reports "captures
  completed: 79 … Every other planned frame exists"; **23 of those 79 timestamps
  have no background frame within 3 s** (worst 257 s), including the
  §E.7-required HUD-on `-gameplay` frame for **all 11 regions**.
- **Reproduction:** `find <run> -name 'GF-*'` → empty.
- **Root cause detail:** `COVERAGE_DEFECTS.md` CD-1, CD-2, CD-7.
- **Acceptance criteria:** a capture pre-flight BLOCKs at step 1 when no display
  server is present; a planned capture that cannot be taken is a **FAIL**, not a
  PASS; `shots/` written and non-empty; §M's inventory check runs as **code**
  and emits a committed `INVENTORY.json`; capture-mode segments are cost-priced
  against measured frame time before launch (CD-7).
- **Regression coverage:** capture smoke as a hard gate in `run_segment.sh`;
  post-step failure when a manifest row claims a file that is absent.
- **Player-path retest:** every segment with a planned capture; X07 in full.
- **Dependencies / ownership:** `tools/gate_f/**`, runner invocation.
- **Parallel-safety:** same owner as GF-B-002.

## GF-B-011 — Telemetry cannot evidence 13 of its own event types
`QUALITY BLOCKER` · confidence **HIGH** · cluster **RC-6** · size **M** · role: tooling developer

- **Player-visible problem:** none — but an entire class of Gate F conclusions is
  unfalsifiable, and this run's most tempting inferences ("no gathering
  happened", "no orb was thrown") are unsupportable.
- **Violated requirement:** §C.1 schema; §C.5 instrumentation honesty; §18
  (save/load results).
- **Evidence:** `operator_harness.gd` has **no emitter** for `catch_throw`,
  `combat_hit`, `combat_switch`, `dialogue`, `gather`, `craft`, `build_place`,
  `build_cancel`, `build_dismantle`, `rest`, `feed`, `landmark_discover`,
  `defect`. `catch_result` fires on party *growth*, so the one per segment is
  the starter loading, not a catch. The `inventory` field reports `{"axe": 0,
  "berries": 0, "orb_basic": 0, …}` on S03's save event while
  `S03/saves/S03-exit.json` contains `orb_basic ×15, potion_small ×3,
  berries ×5, revive ×2, pickaxe, knife, torch, axe`. **No `save` or `load`
  event in the run carries `duration_ms`.**
- **Acceptance criteria:** every §C.1 type is emitted or struck with a recorded
  reason; `inventory` telemetry equals the written save; save/load carry
  `duration_ms`.
- **Regression coverage:** schema-conformance test over a self-check segment; a
  telemetry test asserting the inventory snapshot equals the save.
- **Dependencies:** `tools/gate_f/**`, `scripts/debug/gate_f_probe.gd`.
- **Parallel-safety:** same owner as GF-B-002/003.

---

# TIER 1 — real game defects, independent of the instrument

These four do not need a working harness. They can proceed now, in parallel.

## GF-B-001 — Pressing "New Game" freezes the game for ~50 seconds
`SHIP BLOCKER` · confidence **HIGH** · cluster **RC-2** · size **M–L** · role: performance developer
**Merges `HIST-085`** (*"boot time on the device, and quitting from the menu"*).

- **Player-visible problem:** the title screen appears in under half a second;
  the player presses Start New Game and the process stops responding for the
  better part of a minute with no progress indication. The product's first
  impression is a hang.
- **Violated vision requirement:** Vision §8 "acceptable target-hardware
  performance"; §18 boot/transition durations.
- **Evidence:** `route.csv` `frame_ms`: S02 t=56.2 **50,236 ms**; S03 t=57.3
  **50,720 ms**; S05 t=56.6 **50,245 ms**; S06 ≈49,230 ms; S08 t=55.9
  **49,443 ms**; S09 ≈49,917 ms. Notes `S02-04` "booted title in 381 ms",
  `S02-07` "waited 10800 physics frames".
- **Measured data:** exactly **one** blocking frame of 49–51 s per segment at
  t≈56 s, **6 of 8** journey segments. Against it, whole-journey CPU is healthy:
  36,744 samples, mean 15.8 ms, **p95 8.31 ms**. Measured **headless** — no
  rasteriser is involved, so this is CPU world stand-up and no GPU will fix it.
- **Historical context merged:** `HIST-085` records the title-screen half as
  closed (`smoke_title_load_game`, OP21-23) and the **boot-cost half as open and
  moving** — the missing scatter bake went 58–60 s → ~1.3 s, then *"the corridor
  rebuild roughly doubled bake cost again (placements 10.4 s, batch build
  8.4 s)"*. Gate F's contribution is the **current, reproducible total** on the
  candidate. Diagnosis should start at the scatter/placement bake.
- **Reproduction:** boot to title; press Start New Game; time to player control.
- **Acceptance criteria:** no single frame > 500 ms between the New Game press
  and player control, measured headless on the reference box; **or**, if the work
  is irreducibly long, a responsive loading state with the main thread never
  blocked > 500 ms.
- **Regression coverage:** automated boot-timing test asserting max single-frame
  time across title→world, headless, in CI.
- **Player-path retest:** S01 + S02.
- **Visual review:** required if a loading state is added (new player-facing UI).
- **Dependencies / ownership:** world stand-up / scatter bake / streaming;
  title→world transition. **Related but distinct:** `HIST-001` (scatter density
  unmeasured **on device**) stays [OWNER-ONLY] and is not closed by this item.
- **Parallel-safety:** safe; touches no gameplay data.

## GF-B-004 — A black placeholder sphere hangs in the Meadows Hall gateway
`SHIP BLOCKER` · confidence **HIGH** · cluster **RC-5** · size **S** · role: art/scene developer
**Merges part of `HIST-174`** (*"whole sites are still blockout, in frame"*).

- **Player-visible problem:** at the threshold of the chapter's climactic
  location, an untextured black sphere floats in mid-air in the middle of the
  gate arch the player walks through. It reads unambiguously as unfinished
  software, at the exact moment the chapter should peak.
- **Violated vision requirement:** Vision §3 (Hall/Warden/legendary as payoff);
  §8 finished-region bar.
- **Evidence:** `X07/frames/X07/005948.91.png` (`GF-AUD-hall-arrival`, t=5948.9),
  centre of the archway.
- **Historical context merged:** `HIST-174` records the stronghold-gate half as
  *materially changed and unjudged* since (`STRONGHOLD-MAT`,
  `GATE-E-STRONGHOLD-ART`, `STRONGHOLD-R2` landed textured masonry, a retint
  ladder, garrison fires, an approach road). This frame **is** that judgment, in
  part: the masonry reads, and a placeholder survives inside it.
- **Acceptance criteria:** the Hall gate frame contains no untextured/missing-
  material object; identify what the sphere is and finish or remove it.
- **Regression coverage:** extend X07's existing colour spot-check with a
  pure-black/missing-material object detector over audit frames.
- **Player-path retest:** S09 Hall threshold; X07 hall grid.
- **Visual review:** **required** (`ralph/conventions.md`).
- **Parallel-safety:** safe. Check against GF-B-010 first — may share a cause.

## GF-B-005 — The quickbar shows d-pad badges instead of what the slot holds
`QUALITY BLOCKER` · confidence **HIGH** (raised from MEDIUM-HIGH on merge) · cluster **RC-5** · size **S–M** · role: UI developer + art
**Merges `HIST-018`, `HIST-004`, `HIST-156`.**

- **Player-visible problem:** on a controller the five hotbar slots render one
  red `B` and four identical white/red cross marks — which read as first-aid
  crosses — while the satchel actually holds orbs, potions, berries and revives.
  The player cannot tell what is in their quick-bar. That bar is where the catch
  orb lives, and catching is the chapter's first required verb.
- **Violated vision requirement:** Vision §5 Catching; §14 "menus polished game
  UI rather than debug tooling".
- **Evidence:** `X07/frames/X07/000640.26.png`, `001085.26.png`, `002431.78.png`,
  `003712.84.png`, `005948.91.png` — identical strip in all five, across five
  different regions. Contrast `000312.88.png` (KBM) showing digits 1–5. Contents
  verified in `S03/saves/S03-exit.json`: `hotbar: [orb_basic, potion_small,
  berries, revive, ""]`.
- **Historical context merged — this materially changes the item.** My blind
  read was "missing item icons". `HIST-018` identifies what they actually are:
  **Kenney d-pad badges**, checked exhaustively across the vendored and raw packs
  (Default, Double, `_outline`, `_round`, Xbox, Gamecube) — *"all use the same
  plus-sign-with-one-differentiated-arm convention, none readable at true render
  size"*, and `Generic/` has no d-pad art. The register's ruling: **no suitable
  asset exists; needs owner-supplied direction art.** `HIST-004` (icons do not
  encode item *category* — tinting reached 55.8% coloured pixels but the authored
  colours cluster earthy) and `HIST-156` (glyph *shapes* collide) are the second
  and third layers of the same strip being unreadable.
- **Acceptance criteria:** a 1080p frame of a stocked quickbar in which each
  filled slot's **contents** are identifiable, and the binding badge is secondary
  to the item rather than covering it. The d-pad art half is **owner-blocked**
  and must be raised, not invented (`CLAUDE.md`: never spend a generation without
  owner-supplied reference art).
- **Regression coverage:** HUD test asserting a filled slot renders a distinct
  item icon rather than a shared fallback.
- **Player-path retest:** S02 after Grandpa's gifts; S05 field play.
- **Visual review:** **required**.
- **Dependencies:** HUD hotbar, item icon sheet, Kenney badge set. **Owner
  decision required** on d-pad direction art.
- **Parallel-safety:** conflicts with GF-B-006 (same HUD file) — sequence them.

## GF-B-006 — The team roster block renders over the centre of the screen
`QUALITY BLOCKER` · confidence **HIGH** · cluster **RC-5** · size **S** · role: UI developer
**Merges `HIST-136` (OP23-09) and part of `HIST-017`.**

- **Player-visible problem:** `TEAM 0/5` and five stacked `OPEN SLOT` rows occupy
  the middle of the viewport, directly over the player's forward view and the
  ground ahead. It reads as a debug list. On a 7" handheld it would cover most of
  what the player is walking into. Separately, in the same frame the hint bar
  mixes glyph languages: `M` / `I` / `R` boxed, `[C]` bracketed and greyed.
- **Violated vision requirement:** §14 "menus polished game UI rather than debug
  tooling"; ROG Ally / controller-first (`CLAUDE.md` hard rules).
- **Evidence:** `X07/frames/X07/000312.88.png`.
- **Historical context merged:** `HIST-136` is **owner-reported** (OP23-09, *"the
  HUD takes up far too much screen"*) and nothing in `DONE.md` addresses it. It
  is load-bearing: `HIST-036` (`OBJECTIVE-HINT-ON-HUD`) is explicitly sequenced
  **after** OP23-09 re-proportions that corner. `HIST-017` records that prompt
  *device* and *order* are now consistent and *glyph style* is not — which is
  exactly what this frame shows.
- **Acceptance criteria:** no persistent HUD element inside the central third of
  the viewport in ordinary exploration; one glyph language per device.
- **Regression coverage:** extend the handheld-legibility HUD test with a
  central-exclusion-zone assertion.
- **Player-path retest:** S02/S03 village play.
- **Visual review:** **required**.
- **Dependencies:** `playground_hud.gd`. **Unblocks `HIST-036`.**
- **Parallel-safety:** conflicts with GF-B-005 — sequence.
- **Open question first:** the block appears in the KBM frame and not the
  controller frames. Establish whether it is state- or device-conditional before
  scoping.

---

# TIER 2 — world and presentation

## GF-B-007 — The Old Quarry does not read as a quarry
`QUALITY BLOCKER` · confidence **MEDIUM** · cluster **RC-5** · size **M–L** · role: world/environment developer
**Merges `HIST-163` (the mill has no mill) and `HIST-165` (the well has no well) as one systemic item.**

- **Player-visible problem:** the arrival view of a named, story-load-bearing
  region shows ordinary meadow, a signpost, dead trees and one boulder. No pit,
  no rock face, no worked stone, no excavation. A player cannot answer "what
  region am I in?", and band 2's material (rootstone) has no place that explains
  it.
- **Violated vision requirement:** Vision §4 "rocky quarry/warren terrain" and
  *"The player should be able to answer without staring at the minimap … what
  region am I in?"*; §8 "recognizable geography".
- **Evidence:** `X07/frames/X07/002431.78.png` (`GF-AUD-the_old_quarry-arrival`,
  t=2431.4). Compare `003712.84.png` (the relay) for what regional identity looks
  like when it works.
- **Historical context merged — the systemic reading.** Gate F found this
  instance blind; the register shows it is a **pattern**, not a one-off:
  `HIST-163` the mill has no wheel (*found twice independently*: from the recipe
  — 78 modules, every one a wall/roof/window/corner/border/fence — and blind from
  the frames, *"The shot named 'wheel' contains no wheel"*), `HIST-165` the well
  plaza composes but the well prop does not resolve. **The cause is shared:
  named landmarks are assembled from a generic structural kit that contains no
  landmark-specific geometry.** Treat as one item with three sites, not three.
- **Acceptance criteria:** each of the three sites contains the object it is
  named for, legible at a glance from the intended approach; the quarry's arrival
  frame shows excavated geometry, worked stone and visible rootstone deposits.
- **Regression coverage:** none automatable; visual-judge pass per site.
- **Player-path retest:** S06 RT-06 (quarry), S03 (well), S07 (mill crossing).
- **Visual review:** **required** — `visual-judge` against the art board.
- **Dependencies:** landmark prop set; **`HIST-008`/`HIST-119` may block on
  owner-supplied art** — check before scoping. Per `CLAUDE.md`, Meshy is reserved
  for Team Tether hero objects and needs owner reference art.
- **Caveat:** one arrival frame from a DIAG teleport, not the player's approach
  vector. Review the quarry's other five frames before scoping.

## GF-B-009 — Untextured ground planes at the Relay and the Hall
`QUALITY BLOCKER` · confidence **MEDIUM** · cluster **RC-5** · size **M** · role: environment/art developer
**Merges part of `HIST-174`** (the relay plaza slabs half, *"not addressed anywhere found"*).

- **Player-visible problem:** the two most story-critical spaces stand on flat,
  uniform, detail-free ground while ordinary meadow 200 m away has grass,
  variation and scatter. The escalation reads as *less finished*, not *drained*.
- **Violated vision requirement:** Vision §4 "increasingly occupied/drained land
  near Team Tether infrastructure" — drained must be **authored**, not absent.
- **Evidence:** `X07/frames/X07/003712.84.png`, `005948.91.png`.
- **Acceptance criteria:** relay and Hall ground show authored surface detail —
  texture, debris, tracks, spoil; a viewer can tell drained from unfinished.
- **Regression coverage:** visual-judge pass.
- **Player-path retest:** S07 relay arrival; S09 Hall approach.
- **Visual review:** **required**.
- **Parallel-safety:** safe.

## GF-B-008 — The Rise's arrival renders black
`QUALITY BLOCKER` · confidence **MEDIUM** · cluster **RC-5** · size **S to diagnose** · role: world developer
**Merges `HIST-052`** (*"the landmark the opening points at renders as a black cutout"*).

- **Player-visible problem:** arriving at a named region, the world draws nothing
  — HUD and minimap paint normally over a black screen.
- **Evidence:** `X07/frames/X07/000640.26.png` (`GF-AUD-the_rise-arrival`,
  t=639.9). World-crop mean brightness **15.8/255**; the region's other four
  frames measure 69–94.
- **Historical context merged — this supplies the lead I lacked.** `HIST-052` is
  the same landmark, independently reported by a blind critic who ranked it the
  **second-biggest gap** and read it as a bug: *"nothing else in the scene is
  that dark"*. It also names a candidate root cause never re-checked:
  `GATE-E-STRONGHOLD-ART` found **`art.json` putting the sun in the NORTH sky**.
  A north-sky sun would leave south-facing approach geometry unlit — which is
  exactly this symptom, and would also explain **GF-B-010**.
- **Acceptance criteria:** arriving at The Rise shows The Rise; the `art.json`
  sun azimuth is verified against the intended approach directions.
- **Regression coverage:** X07's colour check should flag near-black world crops,
  not only hue-rotation artefacts.
- **Player-path retest:** S02 (the opening points at it) and X07 the_rise grid.
- **Visual review:** **required**.
- **Caveat:** could still be the DIAG probe camera landing inside geometry.
  **Check the sun azimuth first — it is cheap and would close three items.**

## GF-B-010 — An NPC renders as an unlit silhouette in daylight
`QUALITY BLOCKER` · confidence **MEDIUM** · cluster **RC-5** · size **S–M** · role: art/rendering developer
**Merges `HIST-180`** (*"distant trees render near-black in daylight"*).

- **Player-visible problem:** a Team Tether figure at the relay renders as a
  near-black silhouette in full daylight beside a correctly-lit player. These are
  the chapter's antagonists; they must read.
- **Evidence:** `X07/frames/X07/003712.84.png`, right edge.
- **Historical context merged:** `HIST-180` reports the same symptom on distant
  trees in frames 02/04/05 of the corridor pass, filed in the **scene-fixable**
  half. The register also notes the opposite defect — `HIST-126`'s *"distant-LOD
  instances rendering white"* — and says **no pass has reconciled the two**
  (with `HIST-039`, `HIST-071`, `HIST-093`). Gate F adds a third instance on a
  **humanoid at close range**, which rules out a pure distance-LOD explanation
  and points at lighting. See GF-B-008's north-sun lead.
- **Acceptance criteria:** a daylight frame in which relay NPCs show material
  detail and read as the same art direction as the player; the near-black and
  near-white LOD defects are reconciled as one investigation.
- **Regression coverage:** none automatable; visual-judge.
- **Player-path retest:** S07 relay.
- **Visual review:** **required**.
- **Parallel-safety:** **investigate jointly with GF-B-004 and GF-B-008** — three
  symptoms, plausibly one lighting/material cause.

---

# TIER 3 — polish

## GF-B-012 — A 330 m dead-travel interval on the pond→bridge corridor
`POLISH` · confidence **MEDIUM** · cluster **RC-5** · size **S** · role: world/content developer
**Related to but distinct from `HIST-032`.**

- **Player-visible problem:** one stretch of the band-1 corridor runs 330 m with
  no point of interest within 30 m and nothing to do.
- **Violated vision requirement:** Vision §8 "no long purposeless travel
  stretch"; §D flags ≥250 m as a finding.
- **Evidence:** `S05/telemetry/route.csv` `dead_travel_m` peak **329.8 m over
  53.9 s**, (301.37, 960.29) → (67.69, 1195.98).
- **Measured context — this matters and cuts the other way:** the same corridor's
  median `nearest_poi_dist_m` is **9.9 m** over 1,243 samples (max 98.1 m). RT-05
  is **densely populated**. This is one gap, not a pattern, and the "empty world"
  reading is not supported by the only valid route data in the run.
- **Historical note:** `HIST-032` is the **gather route** ((−168, 312)), a
  different stretch, and the register says it *"names Gate F as the pass that
  should measure this"*. **Gate F did not measure it** — S03 was pinned at
  (22, −3) for 84% of the segment — so `HIST-032` stays open as a coverage
  defect, not closed by this item.
- **Acceptance criteria:** re-measured RT-05 dead-travel peak < 250 m, **or** a
  recorded decision that the interval is intentional breathing room, naming the
  landmark or sightline that makes it so.
- **Regression coverage:** assert RT-05's dead-travel peak in the corridor probe.
- **Player-path retest:** S05 RT-05.
- **Caveat:** an agent walking a straight line at constant speed is not a player.
  Watch item until a human traverses it.

## GF-B-013 — Signpost geometry and text do not read
`POLISH` · confidence **MEDIUM** (raised from LOW-MEDIUM on merge) · cluster **RC-5** · size **S** · role: environment developer
**Merges `HIST-177`** (*"signposts are 4.5 m telephone poles"*).

- **Player-visible problem:** a trail signpost ("Trail Spoke") is clipped at the
  frame edge and reads as a flat plank at an odd angle. Signage is named in §9
  and §E.5 as a navigation aid the player is expected to use.
- **Evidence:** `X07/frames/X07/002431.78.png`, upper left.
- **Historical context merged:** `HIST-177` puts this in the corridor pass's
  **scale** group — *"Scale is right where props are conventional — it breaks on
  the authored elements"* — and notes OP21-18 moved 18 signposts off the travel
  lane (a **siting** fix) without touching their height. Gate F's frame adds the
  legibility half.
- **Acceptance criteria:** signpost legible from the approach at walking speed;
  geometry reads as a sign at human scale.
- **Player-path retest:** S06.
- **Visual review:** required.

---

# Unresolved — not backlog items

Recorded so they are neither lost nor silently promoted. Full detail and the
settling experiment for each in `PROVISIONAL_BACKLOG.md` §UNRESOLVED.

| # | question | why it is not an item |
|---|---|---|
| U-1 | Does the Build catalogue grid accept directional focus navigation? X02 logs **9 consecutive** `ui_right` failures off a **real** focused Button in the **correct** `build_catalogue` context — the only failure class in the run surviving every artifact test. | `build_menu.gd:587` sets `columns = clampi(count, 1, COLUMNS)`, so a one-piece category is a single column where `ui_right` legitimately cannot move — and the player had **no wood/stone/fiber** because S03 gathered nothing. Cannot separate defect from step-script strategy without frames. **Overlaps `HIST-078`** ("once you pick a piece you cannot read how to place or rotate it") — check together. |
| U-2 | Do NPC dialogues open unbidden on approach? | `X01-463` held 3,601 frames in `narrative_modal` 15.8 m short of Bram. Consistent with both a proximity trigger and a harness that never pressed interact. |
| U-3 | Does mashing advance re-open a just-closed conversation? | `S02-28`, operator-recorded, never isolated. |
| U-4 | Is a station panel's exit discoverable on screen? | Needs one frame of the SwapPanel. None exists. |
| U-5 | Is The Rise black because of the region or the DIAG camera? | See GF-B-008; check the sun azimuth first. |

---

# Explicitly NOT findings

Recorded because each was reported as a defect and does not survive measurement.
Full method in `ADJUDICATION.md` §1.

- **"Input ownership is taken and never handed back."** 115 of 418 matrix cells
  were injected in the context they name; **all 115 passed**. `menu_cancel`
  closed a menu **84 times** from every tab. The `panel:SwapPanel` 1,391 s hold
  is Oskar's creature shop with `menu_cancel` pressed **zero** times against a
  panel that sets `PROCESS_MODE_ALWAYS`, grabs focus and closes on B.
- **"No fight ever stages."** X01 t=753.13 stages a real fight with
  `target_on_screen: true` and hands input back cleanly 13.3 s later.
- **"The South Bridge never opens."** True, and **correct**: the gate fight was
  never won because no fight staged. S07/S10 held `input_context = world` for
  99.8%/99.9% of their route rows — the player had control and nowhere to go.
  The crossing's real behaviour remains **untested**.
