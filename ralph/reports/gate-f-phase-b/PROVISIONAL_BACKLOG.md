# Gate F Phase B — Deliverable 2: PROVISIONAL backlog (§16.2)

**Frozen before historical reconciliation. This is the record of what Gate F
independently discovered from the evidence alone.**

Sources permitted and used: `docs/TETHERBOUND_GAME_VISION.md`,
`docs/MEADOWS_PROGRESSION_SPEC.md`, `CLAUDE.md` hard rules,
`ralph/GATE_F_PROTOCOL.md`, `ralph/GATE_F_MASTER_PROTOCOL.md`, and
`ralph/reports/gate-f-run-20260827T025303Z/` telemetry, notes, saves, frames.
Game source was read **only** to adjudicate defect-vs-artifact (§14's first
question), never to import a known issue.

Sources NOT opened: `gate-f-lane-log.md`, both `GATE_F_*HANDOVER*`,
`gate-f-historical-snapshot.md`, `ralph/BACKLOG.md`, `ralph/DONE.md`,
`ralph/BLOCKED.md`, `ralph/ACTIVE_TASKS.md`, `ralph/ASSESSMENT_2026-08-23.md`,
`ralph/OWNER_PLAYTEST_*`, and all prior gate-f run directories.

**Priority = player impact × frequency × chapter criticality × confidence.**
Not ease. Items are listed in priority order within severity.

Confidence is stated on every item because this run's history is one of
high-confidence findings withdrawn on measurement.

---

## SHIP BLOCKERS

### GF-B-001 — Pressing "New Game" freezes the game for ~50 seconds
- **Severity:** SHIP BLOCKER
- **Confidence:** HIGH (6/6 segments, reproducible, renderer-independent)
- **Player-visible problem:** The player presses Start New Game (or Load) on a
  title screen that appeared in under half a second, and the game stops
  responding for the better part of a minute with no progress indication. First
  impression of the product is a hang.
- **Violated vision requirement:** Vision §8 "acceptable target-hardware
  performance"; §18 requires boot/transition durations be acceptable.
- **Evidence:** run `gate-f-run-20260827T025303Z`, `route.csv` `frame_ms`:
  S02 t=56.2 **50,236 ms**; S03 t=57.3 **50,720 ms**; S05 t=56.6 **50,245 ms**;
  S06 t≈56 49,230 ms; S08 t=55.9 **49,443 ms**; S09 t≈56 49,917 ms. Notes
  `S02-04` "booted title in 381 ms", `S02-06` press, `S02-07` "waited 10800
  physics frames".
- **Reproduction:** boot to title; press Start New Game; measure wall time to
  player control.
- **Measured data:** one blocking frame of 49–51 s per segment, at t≈56 s, in 6
  of 8 journey segments. Against it, whole-journey CPU is healthy: 36,744
  samples, mean 15.8 ms, **p95 8.31 ms**. Measured **headless**, so this is CPU
  world stand-up, not rasterisation.
- **Root-cause cluster:** RC-2.
- **Desired outcome:** the transition from title to player control is either
  fast, or visibly progressive (loading state, streamed stand-up) and never a
  frozen process.
- **Acceptance criteria:** no single frame > 500 ms between the New Game press
  and player control on the reference box, measured headless; or, if the work
  is genuinely long, a responsive loading state with the main thread never
  blocked > 500 ms.
- **Regression coverage:** an automated boot-timing test asserting the max
  single-frame time across title→world, run headless in CI.
- **Player-path retest:** S01 + S02 opening.
- **Visual review:** required — the loading state is new player-facing UI.
- **Dependencies / file ownership:** world stand-up / streaming; title→world
  transition. Owns those files exclusively.
- **Parallel-safety:** safe; touches no gameplay data.
- **Size:** M–L (diagnosis first: which subsystem owns the 50 s).
- **Suggested role:** performance-focused developer agent.

### GF-B-002 — Gate F cannot drive the game, so the chapter is unaudited
- **Severity:** SHIP BLOCKER *(against the gate, not the build)*
- **Confidence:** HIGH
- **Player-visible problem:** none directly — this is the reason we do not know
  whether there are any. Nothing about combat, catching, gathering, crafting,
  building, care, rest, progression, the tournament, five bands or the finale
  has been exercised on the candidate.
- **Violated requirement:** §18 — "Gate F completes only when a new frozen
  candidate build survives the full authoritative protocol."
- **Evidence:** tracked objective `opening:beat:road` constant across **all
  1,456 journey events**; **zero** `combat_*` in S01–S10; party never > 1;
  S06–S10 walked **115.0 km** inside a ~25 m corridor; X01 injected **303 of 418
  (72.5%)** cells in the wrong context and never entered 12 named surfaces; X02
  armed no ghost and placed nothing.
- **Reproduction:** re-run any journey segment.
- **Measured data:** four named harness failure modes — (a) dialogue press
  counts guessed per conversation (`X01-709` interact ×6, fight staged **269 s**
  later; `S02-28` "every tap past the third can re-open the conversation the
  previous tap just closed"); (b) `move_to` compares x/z only and cannot express
  adjacency (`S02-15` "pressed `interact` 31 times through the floor"); (c) cell
  probes never re-establish their intended context between cells; (d) no step
  ever presses a station panel's documented dismissal (`menu_cancel` pressed
  **0** times during the 1,391 s SwapPanel hold).
- **Root-cause cluster:** RC-3.
- **Desired outcome:** a harness that reaches a game state and **asserts it
  before proceeding**, rather than pressing a guessed number of times and
  recording whatever follows.
- **Acceptance criteria:** every step that must reach a context blocks on that
  context (bounded, then BLOCKER); every dialogue advances to close rather than
  a fixed count; `move_to` supports "within N m of entity X"; a re-run of S02
  reaches party size 2 and advances the tracked objective off rung 1.
- **Regression coverage:** a harness self-check segment that fails loudly when
  a probe's `context_before` ≠ its declared intended context.
- **Player-path retest:** S02 first, then the full S01–S10 chain.
- **Visual review:** n/a.
- **Dependencies:** `tools/gate_f/**`. Must land **outside** a run (§13) and
  before any new candidate freeze (§1.5).
- **Parallel-safety:** blocks every other Gate F item that needs journey
  evidence. Do this first.
- **Size:** L.
- **Suggested role:** coordinator + tooling developer, not a run operator.

### GF-B-003 — No prescribed screenshot in the entire run; §11 did not execute
- **Severity:** SHIP BLOCKER *(against the gate)*
- **Confidence:** HIGH
- **Player-visible problem:** none directly; it is why roughly half of §14's
  questions are unanswerable.
- **Violated requirement:** §11 and §G — the anti-cherry-picking mechanism;
  §H continuous evidence.
- **Evidence:** **9,231 planned frames, 0 captured** across S01–S10, X01, X02,
  `overhead`, each with `reason: "headless: this process has no display server
  and cannot render a frame"`. `operator_harness.gd:1212` writes captures to
  `shots/<id>.png`; **no `shots/` directory and no `GF-*.png` exists anywhere in
  the run**; total PNGs in 921 MB = **551** (X07's 550 background frames +
  `capture_smoke.png`). X07's `WHY_INCOMPLETE.md` claims "captures completed:
  79 … Every other planned frame exists" — the files do not exist, and **23 of
  the 79 capture timestamps have no background frame within 3 s** (worst gap
  257 s), including the §E.7-required HUD-on `-gameplay` frame for **all 11
  regions**.
- **Reproduction:** `find <run> -name 'GF-*'` → empty.
- **Root-cause cluster:** RC-4.
- **Desired outcome:** journey and study segments run under xvfb per §0.1's own
  canonical invocation, and a segment that cannot capture reports a BLOCKER at
  step 1 rather than writing 9,231 `file: null` rows and continuing.
- **Acceptance criteria:** a capture pre-flight gate that BLOCKS a segment
  carrying planned captures when no display server is present; `shots/` written
  and non-empty; the inventory check §M requires actually run.
- **Regression coverage:** capture smoke as a hard gate in `run_segment.sh`.
- **Player-path retest:** all segments with planned captures.
- **Visual review:** n/a (it *enables* visual review).
- **Dependencies:** `tools/gate_f/**`, run invocation. Pairs with GF-B-002.
- **Parallel-safety:** safe alongside GF-B-002; same owner.
- **Size:** M.
- **Suggested role:** tooling developer.

### GF-B-004 — A black placeholder sphere hangs in the Meadows Hall gateway
- **Severity:** SHIP BLOCKER
- **Confidence:** HIGH (visible in frame)
- **Player-visible problem:** at the threshold of the chapter's climactic
  location, an untextured black sphere floats in mid-air in the middle of the
  gate arch the player walks through. It reads unambiguously as unfinished
  software and undermines trust exactly where the chapter should peak.
- **Violated vision requirement:** Vision §3 "Meadows Hall / Warden /
  legendary" as the chapter's payoff; §8 finished-region bar.
- **Evidence:** `X07/frames/X07/005948.91.png` (`GF-AUD-hall-arrival`,
  t=5948.9), centre of the archway.
- **Reproduction:** approach the Hall gate; look through the arch.
- **Root-cause cluster:** RC-5.
- **Desired outcome:** no placeholder geometry in the Hall approach.
- **Acceptance criteria:** the Hall gate frame contains no untextured/missing-
  material object; identify what the sphere is and either finish or remove it.
- **Regression coverage:** extend the existing X07 colour spot-check with a
  missing-material/pure-black-object detector over audit frames.
- **Player-path retest:** S09 Hall threshold; X07 hall grid.
- **Visual review:** **required**, per `ralph/conventions.md`.
- **Dependencies:** Hall/stronghold scene + materials.
- **Parallel-safety:** safe.
- **Size:** S (once identified).
- **Suggested role:** art/scene developer.

---

## QUALITY BLOCKERS

### GF-B-005 — The hotbar shows placeholder glyphs instead of item icons
- **Severity:** QUALITY BLOCKER
- **Confidence:** MEDIUM-HIGH
- **Player-visible problem:** on a controller the five hotbar slots render one
  red `B` and four identical white/red cross marks, in every region, while the
  satchel actually holds orbs, potions, berries and revives. The player cannot
  tell what is in their quick-bar — which is where the catch orb lives.
- **Violated vision requirement:** Vision §5 Catching (the orb is the verb);
  §14's "menus polished game UI rather than debug tooling".
- **Evidence:** `X07/frames/X07/000640.26.png`, `001085.26.png`,
  `002431.78.png`, `003712.84.png`, `005948.91.png` — identical strip in all.
  Contrast `000312.88.png` (KBM) which shows digits 1–5. Contents verified in
  `S03/saves/S03-exit.json`: `orb_basic ×15, potion_small ×3, berries ×5,
  revive ×2, pickaxe, knife, torch, axe`; `hotbar: [orb_basic, potion_small,
  berries, revive, ""]`.
- **Reproduction:** play to any point with a stocked hotbar on a pad; read the
  strip.
- **Root-cause cluster:** RC-5.
- **Desired outcome:** each filled hotbar slot shows its item, and the binding
  glyph is secondary to the item, not a substitute for it.
- **Acceptance criteria:** a frame of a stocked hotbar in which each of the four
  filled slots is visually distinguishable and identifiable.
- **Regression coverage:** HUD test asserting a filled slot renders a distinct
  item icon rather than a shared fallback.
- **Player-path retest:** S02 after Grandpa's gifts; S05 field play.
- **Visual review:** **required**.
- **Dependencies:** HUD hotbar + item icon assets.
- **Parallel-safety:** safe.
- **Size:** S–M (depends whether icons exist).
- **Suggested role:** UI developer + art.
- **Caveat:** the icons may be correct-but-unstyled rather than absent. A single
  1080p frame of a stocked hotbar settles it.

### GF-B-006 — The team roster block renders over the centre of the screen
- **Severity:** QUALITY BLOCKER
- **Confidence:** HIGH (visible in frame)
- **Player-visible problem:** `TEAM 0/5` and five stacked `OPEN SLOT` rows
  occupy the middle of the viewport, directly over the player's forward view and
  the ground ahead. It reads as a debug list, and on a 7" handheld it would
  cover most of what the player is walking into.
- **Violated vision requirement:** §14 "menus polished game UI rather than debug
  tooling"; ROG Ally / controller-first framing (`CLAUDE.md` hard rules).
- **Evidence:** `X07/frames/X07/000312.88.png`.
- **Reproduction:** enter the world in the state that shows the roster block.
- **Root-cause cluster:** RC-5.
- **Desired outcome:** the roster reads at a glance from screen edge furniture,
  never over the play space.
- **Acceptance criteria:** no persistent HUD element inside the central third of
  the viewport in ordinary exploration.
- **Regression coverage:** extend the handheld-legibility HUD test with a
  central-exclusion-zone assertion.
- **Player-path retest:** S02/S03 village play.
- **Visual review:** **required**.
- **Dependencies:** `playground_hud.gd` / HUD layout.
- **Parallel-safety:** conflicts with GF-B-005 (same file) — sequence them.
- **Size:** S.
- **Suggested role:** UI developer.
- **Caveat:** it appears in the KBM frame and not in the controller frames, so
  establish first whether it is state-conditional or device-conditional.

### GF-B-007 — The Old Quarry does not read as a quarry
- **Severity:** QUALITY BLOCKER
- **Confidence:** MEDIUM
- **Player-visible problem:** the arrival view of a named, story-load-bearing
  region shows ordinary meadow, a signpost, dead trees and one boulder. There is
  no pit, rock face, worked stone or excavation. A player cannot answer "what
  region am I in?" from the frame, and the band-2 material (rootstone) has no
  place that explains it.
- **Violated vision requirement:** Vision §4 "rocky quarry/warren terrain" and
  "The player should be able to answer without staring at the minimap … what
  region am I in?"; §8 "recognizable geography".
- **Evidence:** `X07/frames/X07/002431.78.png` (`GF-AUD-the_old_quarry-arrival`,
  t=2431.4). Compare `003712.84.png` (relay) for what regional identity looks
  like when it works.
- **Reproduction:** X07 quarry grid, or arrive from the bridge on RT-06.
- **Root-cause cluster:** RC-5.
- **Desired outcome:** the quarry announces itself from its approach.
- **Acceptance criteria:** the arrival frame contains excavated geometry and
  worked stone legible at a glance; visible rootstone deposits.
- **Regression coverage:** none automatable; visual-judge pass.
- **Player-path retest:** S06 RT-06.
- **Visual review:** **required** — `visual-judge` against the art board.
- **Dependencies:** quarry region scene/terrain.
- **Parallel-safety:** safe; region-scoped.
- **Size:** M–L.
- **Suggested role:** world/environment developer.
- **Caveat:** one arrival frame from a DIAG teleport, not the player's intended
  approach vector. The other five quarry frames should be reviewed with it
  before scoping.

### GF-B-008 — The Rise's arrival renders black
- **Severity:** QUALITY BLOCKER
- **Confidence:** MEDIUM (one frame; the region's other frames render)
- **Player-visible problem:** arriving at a named region, the world draws
  nothing — HUD and minimap paint normally over a black screen.
- **Violated vision requirement:** Vision §8 "recognizable geography",
  "day/night readability".
- **Evidence:** `X07/frames/X07/000640.26.png` (`GF-AUD-the_rise-arrival`,
  t=639.9). World-crop mean brightness **15.8/255**; the region's other four
  frames measure 69–94.
- **Reproduction:** X07 the_rise arrival step.
- **Root-cause cluster:** RC-5.
- **Desired outcome:** arriving at The Rise shows The Rise.
- **Acceptance criteria:** the arrival frame renders world geometry.
- **Regression coverage:** the X07 colour check should flag near-black world
  crops, not only hue-rotation artefacts.
- **Player-path retest:** X07 the_rise grid.
- **Visual review:** **required**.
- **Dependencies:** likely the audit's camera placement rather than the region —
  diagnose before scoping.
- **Parallel-safety:** safe.
- **Size:** S to diagnose.
- **Suggested role:** world developer.
- **Caveat:** most likely the DIAG probe camera landing inside geometry. If so
  this is a **harness** item, not a world one — settle it before spending art
  time.

### GF-B-009 — Untextured ground planes at the Relay and the Hall
- **Severity:** QUALITY BLOCKER
- **Confidence:** MEDIUM
- **Player-visible problem:** the two most story-critical spaces stand on flat,
  uniform, detail-free ground while ordinary meadow 200 m away has grass,
  variation and scatter. The escalation reads as "less finished", not "drained".
- **Violated vision requirement:** Vision §4 "increasingly occupied/drained land
  near Team Tether infrastructure" — drained must be *authored*, not absent.
- **Evidence:** `X07/frames/X07/003712.84.png`, `005948.91.png`.
- **Root-cause cluster:** RC-5.
- **Desired outcome:** occupied/drained ground reads as deliberately scoured —
  texture, debris, tracks, spoil — not as missing material.
- **Acceptance criteria:** relay and Hall ground frames show authored surface
  detail; a viewer can tell drained from unfinished.
- **Regression coverage:** visual-judge pass.
- **Player-path retest:** S07 relay arrival, S09 Hall approach.
- **Visual review:** **required**.
- **Dependencies:** relay + stronghold ground materials/scatter.
- **Parallel-safety:** safe.
- **Size:** M.
- **Suggested role:** environment/art developer.

### GF-B-010 — An NPC renders as an unlit silhouette in daylight
- **Severity:** QUALITY BLOCKER
- **Confidence:** MEDIUM
- **Player-visible problem:** a Team Tether figure at the relay renders as a
  near-black silhouette in full daylight, standing beside a correctly-lit
  player. Characters are the chapter's antagonists; they must read.
- **Violated vision requirement:** Vision §4 regional presentation;
  `docs/art/HUMANOID_ASSET_INVENTORY.md` reuse quality bar.
- **Evidence:** `X07/frames/X07/003712.84.png`, right edge.
- **Root-cause cluster:** RC-5.
- **Desired outcome:** humanoids light consistently with the player.
- **Acceptance criteria:** a daylight frame in which relay NPCs show material
  detail and read as the same art direction as the player.
- **Regression coverage:** none automatable; visual-judge.
- **Player-path retest:** S07 relay.
- **Visual review:** **required**.
- **Dependencies:** humanoid materials/lighting; may share a cause with the
  black sphere (GF-B-004).
- **Parallel-safety:** check against GF-B-004 before assigning separately.
- **Size:** S–M.
- **Suggested role:** art/rendering developer.

### GF-B-011 — Telemetry cannot evidence 13 of its own event types
- **Severity:** QUALITY BLOCKER *(against the gate)*
- **Confidence:** HIGH
- **Player-visible problem:** none — but it means an entire class of Gate F
  conclusions is unfalsifiable, and the run's most tempting inferences
  ("no gathering happened", "no catch was thrown") are unsupportable.
- **Violated requirement:** §C.1 schema; §C.5 instrumentation honesty.
- **Evidence:** `operator_harness.gd` has emitters only for `objective`,
  `flag_set`, `region_enter`, `combat_start`, `combat_end`, `menu_open`,
  `menu_close`, `tab_change`, `note`, `catch_result`, `level_up`, `faint`,
  `save`, `load`, `screenshot`, `input_probe`. **No emitter exists** for
  `catch_throw`, `combat_hit`, `combat_switch`, `dialogue`, `gather`, `craft`,
  `build_place`, `build_cancel`, `build_dismantle`, `rest`, `feed`,
  `landmark_discover`, `defect`. Additionally `catch_result` fires on *party
  growth*, so the one per segment is the starter loading, not a catch.
- **Also:** the `inventory` field reports `{"axe": 0, "berries": 0,
  "orb_basic": 0, …}` on S03's save event while `S03/saves/S03-exit.json`
  contains `orb_basic ×15, potion_small ×3, berries ×5, revive ×2, pickaxe,
  knife, torch, axe`. And **no `save` or `load` event in the run carries
  `duration_ms`**, so §18's required save/load timings do not exist.
- **Root-cause cluster:** RC-6.
- **Acceptance criteria:** every type in the §C.1 enum is either emitted or
  struck from the schema with a recorded reason; `inventory` matches the save it
  describes; save/load carry `duration_ms`.
- **Regression coverage:** a harness self-check asserting inventory telemetry
  equals the written save.
- **Player-path retest:** any segment.
- **Dependencies:** `tools/gate_f/**`, `scripts/debug/gate_f_probe.gd`. Pairs
  with GF-B-002/003.
- **Parallel-safety:** same owner as GF-B-002.
- **Size:** M.
- **Suggested role:** tooling developer.

---

## POLISH

### GF-B-012 — A 330 m dead-travel interval on the pond→bridge corridor
- **Severity:** POLISH
- **Confidence:** MEDIUM (measured, but from a bot that never stops)
- **Player-visible problem:** one stretch of the band-1 corridor runs 330 m with
  no point of interest within 30 m and no interaction available.
- **Violated vision requirement:** Vision §8 "no long purposeless travel
  stretch"; §D flags ≥250 m as a finding.
- **Evidence:** `S05/telemetry/route.csv`, `dead_travel_m` peak **329.8 m over
  53.9 s**, from (301.37, 960.29) to (67.69, 1195.98).
- **Measured data:** context — the same corridor's median `nearest_poi_dist_m`
  is **9.9 m** over 1,243 samples (max 98.1 m). The route is otherwise **well
  populated**; this is one gap, not a pattern.
- **Root-cause cluster:** world composition (RC-5), local.
- **Desired outcome:** the gap earns itself as breathing room (a sightline, a
  silhouette, an overlook) or gains a reason to stop.
- **Acceptance criteria:** re-measured `dead_travel_m` peak on RT-05 < 250 m, or
  a recorded decision that the interval is intentional breathing room with the
  landmark that makes it so.
- **Regression coverage:** assert RT-05's dead-travel peak in the corridor probe.
- **Player-path retest:** S05 RT-05.
- **Visual review:** recommended.
- **Dependencies:** band-1 corridor content.
- **Parallel-safety:** safe.
- **Size:** S.
- **Suggested role:** world/content developer.
- **Caveat:** an agent walking a straight line at constant speed is not a
  player. Treat as a watch item until a human traverses it.

### GF-B-013 — Signpost text clips at the frame edge
- **Severity:** POLISH
- **Confidence:** LOW-MEDIUM (single frame, camera-dependent)
- **Player-visible problem:** a trail signpost ("Trail Spoke") is cut off and the
  sign reads as a flat plank at an odd angle. Signage is named in §9/§E.5 as a
  navigation aid.
- **Evidence:** `X07/frames/X07/002431.78.png`, upper left.
- **Root-cause cluster:** RC-5.
- **Acceptance criteria:** signpost legible from the approach; geometry reads as
  a sign.
- **Regression coverage:** none.
- **Player-path retest:** S06.
- **Visual review:** required.
- **Size:** S. **Suggested role:** environment developer.

---

## UNRESOLVED — named, with the experiment that settles each

These are **not** backlog items. They are the questions this run could not
answer, recorded so they are not silently lost or silently promoted.

| # | question | settling experiment |
|---|---|---|
| U-1 | Does the Build catalogue grid accept directional focus navigation? The only failure class surviving every artifact test: X02 logs **9 consecutive** `ui_right` failures off a **real** focused Button in the **correct** `build_catalogue` context (X02-036/049/054/059/064/069/082/087/117). But `build_menu.gd:587` sets `columns = clampi(count, 1, COLUMNS)`, so a one-piece category is a single column where `ui_right` legitimately cannot move — and the player had **no wood/stone/fiber** (S03 gathered nothing). | Re-run X02 from a save carrying real materials, capture on, logging `GridContainer.columns` and focused cell index per press. |
| U-2 | Do NPC dialogues open unbidden on approach? | Walk past Bram/Oskar/Mira/Tam with zero `interact` presses and `answer_prompts` off; log `input_context` changes. |
| U-3 | Does mashing the advance button re-open a just-closed conversation? (`S02-28`: "every tap past the third can re-open the conversation the previous tap just closed") | Advance a 3-line dialogue with 10 taps; assert the panel is closed and world-owned at the end. |
| U-4 | Is a station panel's exit discoverable on screen? | One 1080p frame of the SwapPanel. None exists. |
| U-5 | Is The Rise black because of the region or the DIAG camera? | Re-capture from the player's on-foot approach. |

---

## Coverage gaps — explicitly NOT clean bills of health

Never to be reported as "not reproduced":

- **X03** (catching lab), **X04** (combat lab), **X05** (save/session
  lifecycle), **X06** (abuse sweep), **X08** (performance audit) — **never ran**.
- **X07** stopped at step 184/266 as a cost blocker (documented, legitimate).
- Journey coverage of combat, catching, gathering, crafting, building,
  care/rest/feed, level-up, evolution, riding, the tournament, all five band
  gates, the Warden, the legendary choice and the release ceremony — **never
  exercised**.
- All 22 §G screenshot classes — **no artefact produced**.
- §18's required save/load durations — **not instrumented**.
- Every **[OWNER-ONLY]** item in §K (device FPS, GPU, VRAM, thermals, controller
  feel, 7" legibility, audio, Windows export identity, first-time-human
  navigation and pacing, long-session soak) — unchanged, unclaimed.

---

## Gate verdict at provisional stage

**Gate F does not pass**, on §18's own criterion: the candidate did not survive
the full authoritative protocol. Roughly a quarter of it executed. The candidate
is very largely **unjudged**, not judged bad.

The correct next action is **GF-B-002 + GF-B-003 + GF-B-011 (fix the
instrument), then re-run** — not remediation of the game against these numbers.
GF-B-001 and GF-B-004 are real and can proceed in parallel; they do not depend
on the harness.
