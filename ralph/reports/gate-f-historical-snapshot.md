# Gate F — frozen historical unresolved-item register

**Snapshot date:** 2026-08-25
**Branch:** `ralph/GATE-F-INSTRUMENTATION`
**Commit:** `c5a84dd95f02ae51b469d9033b5167ce85640b09`
**Revised:** 2026-08-25, second pass — the three sweep gaps the first pass
named are now closed. See "Known gaps in this sweep" for what remains.

**Mandate:** `ralph/GATE_F_PROTOCOL.md` §16.1 — *"freeze a snapshot/reference of
every unresolved historical item for later reconciliation"*.

## What this file is, and who must not read it

This is the frozen enumeration of every unresolved historical item this repo
carried **before** the Gate F protocol run. It exists so that after Gate F
publishes its own independently-derived backlog, §16.3 has a complete list to
reconcile against and §16.5 has an honest denominator.

**Two people must not read it yet:**

- **The Gate F operator (Sonnet) must not read this during the run.** §16.1 is
  blind-first: the old task list must not become the run's checklist. Nothing in
  here may be handed to the operator as "look for X".
- **Fable must not read this before its provisional Gate F backlog is
  version/hashed.** §16.2 makes that provisional backlog the record of what Gate
  F found on its own. Reading this first destroys that record and makes the
  capture-rate metric meaningless.

It is safe to read after the provisional backlog is hashed, and it is required
reading at that point.

## What this file is NOT

- It does **not** classify anything into §16.3's seven categories. That ruling is
  Fable's, after the provisional backlog is frozen.
- It does **not** predict whether Gate F will find these.
- It contains **no remediation plans and no proposed fixes**. Several entries
  quote a diagnosis the repo already recorded, because the diagnosis is part of
  what is being frozen; none of them prescribes work.

## Sources swept

| file | swept | notes |
|---|---|---|
| `ralph/BACKLOG.md` (3,984 lines, 31 `##` sections) | full read | main ledger/history |
| `ralph/ACTIVE_TASKS.md` | full read | packages P1–P6 |
| `ralph/BLOCKED.md` (1,183 lines) | open entries read in full; `✅`-marked resolved entries read at heading level | see "Sweep gaps" |
| `ralph/GATE_D_REMAINDERS.md` | full read | |
| `ralph/ASSESSMENT_2026-08-23.md` | full read | evidence ground truth per gate |
| `ralph/ACTIVE_GAME_PLAN.md` | gate sections + §5/§6 read; per-gate task bullets skimmed | |
| `ralph/OWNER_PLAYTEST_2026-08-23.md` | full read | OP23-01..16 |
| `ralph/OWNER_PLAYTEST_2026-08-21.md` | full read | OP21-01..26 |
| `ralph/OWNER_PLAYTEST_2026-08-18.md` | full read | OP1..OP16 |
| `ralph/OWNER_DIRECTIVES_2026-08-23.md` / `_2026-08-22.md` | full read | |
| `ralph/GATE_F_EVIDENCE_2026-08-23.md` | full read | measurements valid as historical input; verdict is not |
| `ralph/DONE.md` (16,910 lines) | targeted: section index + every entry needed to close or contradict a candidate | never cold-read, per `START_HERE.md` §6 |
| `ralph/VISUAL_LEDGER.md` | full read of the domain table and standing findings | added beyond the brief's list; it is the only place the eight visual domains' verdicts live |
| `ralph/HANDOVER_2026-08-25_CI_GREEN_AND_TWO_LANES.md`, `ralph/HANDOVER_CONSOLIDATION_2026-08-25.md` | full read | newest state; supersedes the 08-23 assessment in places |
| `ralph/reports/VISUAL_*_2026-08-23.md` (13 files, 3,314 lines) | **read in full, second pass** | the per-frame defect lists; source of `HIST-146`–`HIST-199` |
| `ralph/lanes/` (11 files) | **read, second pass** | `VISUAL_SWEEP_LANES.md`'s settled-findings and harness-pattern lists used to refute three candidates |
| `ralph/planning/` (3 files) | **read, second pass** | source of `HIST-200`–`HIST-206`; the superseded draft read only for its own supersession note |
| `ralph/ledger/` | **opened, second pass** | a generated dashboard frozen at `395b514e` / 2026-08-12 — `HIST-207` |
| `docs/ralph-prompts/` (80 files) | **swept, second pass** | filenames + the `OP1`–`OP16` set resolved against real records; see the OP table |
| `ralph/reports/*` (non-VISUAL) | grepped for open/unresolved markers; `CHOKE_POINTS`, `CROSSINGS_IMPASSABILITY`, `PERF_ROG_REPORT`, `BAND2_WARRENS_EVIDENCE`, `GATE_C_EVIDENCE`, `GATE_D5_EVIDENCE` | one open item found (`tether_relay` flag), already carried from BACKLOG |
| working tree spot-checks | first pass: `scripts/world/tm_pickup.gd`, `data/config/tether_relay.json`, `data/config/stronghold_climax.json`, `data/config/vegetation.json`, `data/config/bands/*/trainers.json`, `.github/workflows/ci.yml`. Second pass: `scripts/world/landmark.gd`, `scripts/ui/audio_cues.gd`, `assets/ui/audio/`, `scripts/build/build_placer.gd`, `scripts/build/creature_bed.gd`, `scripts/combat/encounter_director.gd`, `data/terrain/playground/` | used to confirm or refute **twelve** entries rather than trust prose |

## ID allocation order (stable)

`HIST-###` is allocated in source order: the first pass allocated `HIST-001`–
`HIST-145` over the sources in the order of the table above, and the second pass
allocated `HIST-146`–`HIST-210` over the three sweeps it was sent to close, in
the order the coordinator listed them. Within each source, ascending line number
of the entry's own heading. IDs therefore do **not** run in section order — an ID's section is a
property of the item, not of its number. This keeps the numbering stable if an
item is later re-sectioned at reconciliation.

## How to read a row

- `player_visible_problem` is stated in player terms. Where the historical entry
  was written purely as an implementation task, it is translated and marked
  `translated: yes`.
- `status_evidence` states what the repo currently claims **and** anything that
  contradicts it. Where `DONE.md` and a newer owner playtest disagree, both are
  named; neither is silently picked.
- `likely_still_valid` is this sweep's honest judgement, not a ruling.
  `unsure` is used freely — §16.5 forbids gaming the metric, and over-inclusion
  is recoverable at reconciliation while omission is not.

---

# Section 1 — unresolved, player-facing

These are the items whose denominator §16.5 names: *genuinely valid/current
historical player-facing issues*. Inclusion here is not a claim that each is
genuinely valid — that is `likely_still_valid`'s job — only that if it is valid,
a player would feel it.

## HIST-001 — corridor scatter density has never been measured on the target device

- **source:** `ralph/BACKLOG.md:46`; restated `ralph/HANDOVER_CONSOLIDATION_2026-08-25.md:126`
- **original_id:** `SCATTER-BUDGET-REVIEW`
- **title:** Scatter density landed on an owner ruling with the device half unmeasured
- **player_visible_problem:** The game may still hitch or stutter on the ROG Ally because the world places far more scattered vegetation and rock than anyone has measured on that hardware. The owner's last report on the device was "freezes every few feet".
- **date_opened:** 2026-08-24 · **last_touched:** 2026-08-25 (density halved on the consolidation branch: grass 2.8→1.4, drygrass 2.0→1.0, flowers 1.5→0.8, rock clumps 36→12; 801,026 → 466,922 placements)
- **status_evidence:** The owner ruled "land it all" and the placement ceiling was raised 260,000 → 900,000. The entry's own second half says the important part is still owed: boot cost roughly doubled and nothing has run on an Ally. The 08-25 handover confirms the density cut is "**Not verified on device**". `OP23-01`'s CPU cause (a 837 ms map-fog repaint) is separately closed, which removes the previously-dominant explanation for the owner's report and leaves this as the named next lever.
- **owner_reported:** yes (OP23-01 lineage; owner's own "freezes every few feet")
- **system_class:** performance
- **likely_still_valid:** yes — no device evidence exists in either direction, and the entry names itself as the next lever.

## HIST-002 — creatures fight pressed against each other

- **source:** `ralph/BACKLOG.md:102`
- **original_id:** `VIS-MAKE-remainder` (combat contact distance)
- **title:** Combatants rest at collider contact; `body_clearance` is not the lever
- **player_visible_problem:** Two fighting creatures stand nose-to-nose with their bodies touching, so a fight reads as a shoving match rather than as two animals trading blows at a readable distance.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-25 (`body_clearance` 1.8 → 2.75 landed via VIS-MAKE and *changed the harness's standoff*, per `HANDOVER_CONSOLIDATION_2026-08-25.md`, but the measured centre gap is what this item is about)
- **status_evidence:** Measured and printed at every shot: centres at **1.36 m**, exactly `mine + theirs`, where `body_clearance: 2.75` should give 3.74 m. Raised twice against this defect and the measured gap did not move either time. Hypothesis recorded with a named test: the ally lunges into the opponent (`_resolve_player_strike` applies `add_impulse(facing, lunge 3.6)` per strike). The entry explicitly forbids a third `body_clearance` raise. No entry anywhere claims it fixed.
- **owner_reported:** no
- **system_class:** combat/camera
- **likely_still_valid:** yes — measured, un-actioned, and the one candidate fix is named as wrong.

## HIST-004 — item icons do not encode what kind of item they are

- **source:** `ralph/BACKLOG.md:120`
- **original_id:** `VIS-MAKE-remainder` (icon colour coding by KIND)
- **title:** 28 of 55 items share a glyph
- **player_visible_problem:** In the satchel and hotbar, a tool, a consumable and a gatherable can look like the same object, so a player scanning the bar cannot tell at a glance what a slot holds.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** Icons are now tinted from `items.json`'s authored colours (0% → 55.8% coloured pixels, 0 → 10 hue families), but the entry records the round-3 critic's point as standing: the authored colours cluster earthy, so *category* is still not encoded. Overlaps `HIST-051` and `HIST-054`'s "four near-identical hotbar icons".
- **owner_reported:** no
- **system_class:** UI architecture
- **likely_still_valid:** yes — the measured improvement is on saturation, not on category encoding.

## HIST-006 — lit windows do not follow the time of day

- **source:** `ralph/BACKLOG.md:128`
- **original_id:** `VIS-MAKE-remainder` (window emissive)
- **title:** Window emissive must follow the clock, not be turned down
- **player_visible_problem:** Village houses either glow at noon or read as black uninhabited panes at night, depending which way the value was last set — the windows never say "someone is home, and it is evening".
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** Recorded as needing `scripts/world/building_prefabs.gd`, explicitly another lane's file. The entry notes two critics hold opposite views of the same feature, which is itself the argument for clock-driven emissive. No closing evidence found.
- **owner_reported:** no
- **system_class:** art/asset
- **likely_still_valid:** yes

## HIST-007 — there is no creature bed art in the build

- **source:** `ralph/BACKLOG.md:134`
- **original_id:** `VIS-MAKE-remainder` (creature bed)
- **title:** The creature bed reads as human furniture
- **player_visible_problem:** The player is taught to build three creature beds before the tournament, and what they get looks like a person's bed. Nothing in the world says a creature sleeps there.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** Checked, not assumed: repointing from a furniture-pack twin bed to the camp set's `camp_bed.glb` did not work — the blind critic read the replacement as human furniture too. No nest, basket, cushion or straw-bed mesh exists anywhere under `assets/`. Blocked on owner-supplied reference art per `CLAUDE.md`. Note the adjacent `BLOCKED.md` precedent (2026-08-22 owner correction): *sourcing* a CC0 asset is permitted where *generating* is not — that route is not recorded as tried for this prop.
- **owner_reported:** no (but sits directly under owner directive 2026-08-23 §1, three beds)
- **system_class:** art/asset
- **likely_still_valid:** yes

## HIST-008 — seven hero objects are still untextured blockout or absent

- **source:** `ralph/BACKLOG.md:139`
- **original_id:** `VIS-MAKE-remainder` (blocked-on-art list)
- **title:** Castle, mill machinery, gate leaves, well shaft, hammer, fishing rod, Bramblebun style
- **player_visible_problem:** Several things the player looks at closely — the fortress, the mill, gates, the well, the hammer in their own hand, the fishing rod — read as grey placeholder shapes rather than as objects.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** Recorded as art not in the build. Partly contradicted since: `STRONGHOLD-MAT` landed real textured masonry (`97f4ff32`) and `GATE-E-STRONGHOLD-ART` raised the retint ladder, so "castle still untextured blockout" is stale for the castle at least. The other six are not addressed anywhere found.
- **owner_reported:** no
- **system_class:** art/asset
- **likely_still_valid:** unsure — the castle half is contradicted by `DONE.md`; the rest is not.

## HIST-009 — band 2's ironwood trees render blood-red

- **source:** `ralph/BACKLOG.md:153`
- **original_id:** `VIS-MAKE-remainder` (cross-lane flag)
- **title:** Five ironwood harvest nodes use models no vegetation layer lists
- **player_visible_problem:** The trees the player is sent to chop for ironwood have crimson canopies, in a green meadow, on a friendly gatherable.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** **Confirmed in the working tree at this SHA.** `data/config/bands/band2_stone_and_root/harvest.json` uses `TwistedTree_1/_2/_3`; `vegetation.json`'s `grove` layer lists only `TwistedTree_2` and `TwistedTree_4` (plus `CherryBlossom_3`), so `harvest_node.gd`'s by-model-path retexture fixup cannot fire for `_1`/`_3`. `vegetation.json`'s own `_comment_leaf` documents `Leaves_TwistedTree_C.png` as RGB(167,23,23), and its swap only applies inside the layer. The item capture audits and names this every run.
- **owner_reported:** no
- **system_class:** art/asset
- **likely_still_valid:** yes — verified against the shipped data, not the prose.

## HIST-010 — the second production encounter will not start

- **source:** `ralph/BACKLOG.md:156`, restated `ralph/BACKLOG.md:262`
- **original_id:** (unnamed; `smoke_combat_camera` failure)
- **title:** `smoke_combat_camera` fails at "the second production encounter would not start"
- **player_visible_problem:** After one fight resolves, the next wild encounter may fail to open — the player walks into a creature and nothing happens.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** Verified pre-existing by stashing VIS-UI's four combat-adjacent files and reproducing the identical failure without them. Named as "an EncounterDirector re-engagement path, untouched by this lane" and as **not in CI's list**. `translated: yes` — the historical entry is written as a test failure; the player-facing reading is inferred from the assertion's own wording and is not itself measured.
- **owner_reported:** no
- **system_class:** combat/camera
- **likely_still_valid:** unsure — nothing since claims to have fixed it, but nothing has re-run it either, and it may be a harness assumption rather than a game defect (this repo has six same-shaped false alarms recorded on 2026-08-25).

## HIST-013 — the combat HUD overlaps itself

- **source:** `ralph/BACKLOG.md:198`
- **original_id:** `VIS-UI-r3`
- **title:** The active-creature plate composites over the roster's fifth row
- **player_visible_problem:** In a fight, the active creature's name and level print on top of another team member's, its HP bar runs under the mini-bar, and an "Energy" label floats loose under the pile. The player cannot read their own team during combat.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** Located precisely (frames 10 and 11, bottom-left). `combat_hud.gd`'s `_party_strip_position()` now computes from AllyPanel's real `offset_top`, so the stale-constant cause is fixed and the remaining overlap is the plate's own height or the strip's row count. The VIS-UI branch merged into the consolidation and thence to `main`, but the remainder is recorded as a handover, not a convergence record.
- **owner_reported:** no (adjacent to OP23-09)
- **system_class:** UI architecture
- **likely_still_valid:** yes

## HIST-014 — the world HUD ghosts under the dialogue panel

- **source:** `ralph/BACKLOG.md:205`
- **original_id:** `VIS-UI-r4`
- **title:** `dialogue_panel.gd` was never wired to `set_world_hud_visible()`
- **player_visible_problem:** While Grandpa is talking, "RB — Call out Terrapup" shows through the top edge of his dialogue box.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** Root cause named: the five station panels were wired to `input_owner.gd::set_world_hud_visible()`; the dialogue panel was not. The entry itself flags an open design question first — a conversation is not a menu, so hiding the HUD may not be wanted.
- **owner_reported:** no
- **system_class:** UI architecture
- **likely_still_valid:** yes

## HIST-015 — text truncates mid-word with no ellipsis

- **source:** `ralph/BACKLOG.md:212`
- **original_id:** `VIS-UI-r5`
- **title:** Craft panel, shop panel and creatures menu behead their own strings
- **player_visible_problem:** "Ironwood Haft (Axe", "3 Ironwood (have 0), 1 Ro..", every TM name in the shop cut short, and a line in the creatures menu clipped mid-glyph by the bottom of the screen. The player cannot read what they are about to craft or buy.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** Four frames named (`19-craft-panel`, `20-shop-panel`, `13-menu-creatures`). The shop list's last visible row is also cut mid-icon with no scroll affordance. Cause identified for the shop: the name column lost width when prices got their own column.
- **owner_reported:** no
- **system_class:** UI architecture
- **likely_still_valid:** yes

## HIST-016 — the player's body prints through menu panels

- **source:** `ralph/BACKLOG.md:219`
- **original_id:** `VIS-UI-r6`
- **title:** The trainer reads as a dark torso inside the station UI
- **player_visible_problem:** Opening a shop, smith or trainer panel puts the player's own silhouette behind the translucent panel, so the UI has a person-shaped stain across it.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** Frames 19–22. Appeared only once these panels started being captured over the real world, i.e. it was invisible to every prior pass that shot them on a blank stage.
- **owner_reported:** no
- **system_class:** UI architecture
- **likely_still_valid:** yes

## HIST-017 — four different button-prompt languages in one game

- **source:** `ralph/BACKLOG.md:225`
- **original_id:** `VIS-UI-r7`
- **title:** Glyph style is inconsistent across title, world HUD, panels and footers
- **player_visible_problem:** The same controller button is drawn as plain text on the title, a coloured Xbox circle in some panels, a monochrome pill on the world HUD, and a keycap beside bracket-text "[C]" in another — so the player relearns the button language screen by screen.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** The entry records that the *device* and the *order* are now consistent and the *glyph style* is not. Overlaps `HIST-054`'s "[C] bracket-text beside boxed key glyphs".
- **owner_reported:** no
- **system_class:** UI architecture
- **likely_still_valid:** yes

## HIST-018 — the quickbar's d-pad badges read as red first-aid crosses

- **source:** `ralph/BACKLOG.md:225` (Needs an owner decision subsection)
- **original_id:** `VIS-UI-r8`
- **title:** No d-pad direction glyph in any vendored pack reads as a direction
- **player_visible_problem:** The hotbar slots 2–5 are badged with what looks like a red medical cross rather than a d-pad direction, and red is this project's reserved DANGER colour.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** Exhaustively checked across the vendored and raw Kenney packs (Default, Double, `_outline`, `_round`, Xbox, Gamecube) — all use the same plus-sign-with-one-differentiated-arm convention, none readable at true render size. `Generic/` has no d-pad art. Recorded as **no suitable asset exists**; needs owner-supplied direction art.
- **owner_reported:** no
- **system_class:** art/asset (blocked on owner art)
- **likely_still_valid:** yes

## HIST-019 — the declared project display font is sci-fi

- **source:** `ralph/BACKLOG.md:232`
- **original_id:** `VIS-UI-r9`
- **title:** `kenney_future` clashes with the body sans and with the fiction
- **player_visible_problem:** "DISCOVERED REGIONS" and "BOND 0/100" are set in a science-fiction display face in a cozy meadow game.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** It is the declared project font in `ui_tokens.gd`. Replacing it is art direction plus a licence entry, explicitly not a lane's call. Its capital N was already unusable at marker size (the minimap now draws a needle instead), which is corroborating evidence rather than a fix.
- **owner_reported:** no
- **system_class:** art/asset (owner decision)
- **likely_still_valid:** yes

## HIST-020 — revealed map ground comes back as a featureless black strip

- **source:** `ralph/BACKLOG.md:238`
- **original_id:** `VIS-UI-r10`
- **title:** The map renders *discovered* ground as unlit black
- **player_visible_problem:** Walking somewhere reveals it on the map and what appears is a black strip with nothing in it, so exploring does not visibly buy the player a map.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** The entry is careful: fog on *unexplored* ground is correct per spec 16 and is not the defect. Whether this is a `map_baker.gd` output problem or a missing map treatment "needs deciding before it is coded". Partly overlapping but distinct from OP23-03 (reveal *radius*), which is closed by OP23-FIXPACK.
- **owner_reported:** no (adjacent to OP23-03, which is owner-reported)
- **system_class:** navigation/objectives
- **likely_still_valid:** unsure — OP23-FIXPACK tripled `starting_reveal` radii and moved `test_map_fog`'s floor to a player-visible fraction; whether that also changed how revealed ground *renders* is not recorded either way.

## HIST-021 — a wild creature wears the starter's body

- **source:** `ralph/BACKLOG.md:244` (Belongs to other domains)
- **original_id:** VIS-UI round-3 finding, routed to D3
- **title:** "Bramblebun" renders as the player's Terrapup mesh and material
- **player_visible_problem:** The creature the player is fighting is visibly the same animal as the creature they are piloting, with an actual rabbit standing next to it — in a game named after its creatures.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** Called "the strongest single finding of the round" by a blind critic. Contradicted in part by `DONE.md`'s `CREATURE-IDENTITY-2` (2026-08-23), which regenerated the whole roster with per-species identity overlays and separated terrapup (warm earth, leaf growth) from burrowback (cold grey stone, moss). Whether the *bramblebun* case specifically was a data/spawn error or a texture error is not recorded.
- **owner_reported:** no
- **system_class:** creature attachment
- **likely_still_valid:** unsure — a later pass plausibly fixed the class; no evidence names this frame as re-checked.

## HIST-022 — the combat roster degrades creatures to flat colour chips

- **source:** `ralph/BACKLOG.md:248`
- **original_id:** VIS-UI (D2/D3 seam)
- **title:** Combat's roster still uses chips where the exploration HUD draws thumbnails
- **player_visible_problem:** In exploration the player's team is drawn as painted portraits; the moment a fight starts, the same team becomes five coloured rectangles.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** The roster fix landed for the Creatures tab; combat's own roster is recorded as still using chips. No later entry claims otherwise.
- **owner_reported:** no
- **system_class:** UI architecture
- **likely_still_valid:** yes

## HIST-023 — a hard black shadow wedge with no caster, and a black-walled pit

- **source:** `ralph/BACKLOG.md:252`
- **original_id:** VIS-UI (routed to D7 ground/lighting)
- **title:** Unlit lower third, dusk sky over daylight terrain, an unexplained rectangular pit
- **player_visible_problem:** The bottom third of the screen goes hard-edged black with nothing casting it, interiors are fully unlit, a dusk sky sits over daylight-lit ground, and there is a rectangular hole in the world with pure-black walls.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-25
- **status_evidence:** Named across frames 04-07 and 19-23. Partly addressed since by `VISUAL-LIGHT` (the sun was in the wrong sky; the day/night clock snapped) — but that lane's own `DONE.md` entry says **no blind visual pass ran and the ghost-box/dead-olive/blue-grey claims were never measured against the sun fix**. Related to `HIST-135`.
- **owner_reported:** no
- **system_class:** terrain/composition
- **likely_still_valid:** unsure — a plausible root cause landed unverified.

## HIST-024 — the world under the HUD is empty

- **source:** `ralph/BACKLOG.md:261`
- **original_id:** VIS-UI (routed to D1)
- **title:** One tree, five grass tufts, floating planter trays
- **player_visible_problem:** Behind the interface, the meadow is bare ground with a handful of props on it.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-25
- **status_evidence:** Same defect family as `HIST-041` (WORLD-GRASS) and the 2026-08-23 blind critique's #1 finding ("60–90% of most frames is one flat green terrain material"). The "floating planter trays" half is a distinct and unaddressed observation. Ground-cover density was raised by `VISUAL-GROUNDCOVER` and then **halved again** on the consolidation branch for ROG headroom, so the net direction is unclear.
- **owner_reported:** no (owner-directed at the class level via WORLD-GRASS)
- **system_class:** world density
- **likely_still_valid:** yes

## HIST-026 — the Meadows legendary's hide colour is a presentation call the owner may want reversed

- **source:** `ralph/BACKLOG.md:283`
- **original_id:** `VERIDIAN-HIDE`
- **title:** The legendary is now an ivory stag with a verdant crown
- **player_visible_problem:** The creature the whole chapter builds toward changed colour to stop it being camouflaged against grass. The alternative — keep the green hide and stage the encounter somewhere that is not green — was not tried and is the answer a field boss usually gets.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** Filed as an owner call, not a bug. Cheap and reversible (`data/creatures/shiny_colourways.json`, `veridian.vivid_rules`). Both answers described as defensible.
- **owner_reported:** no (awaiting owner)
- **system_class:** art/asset (owner decision)
- **likely_still_valid:** yes — the decision is genuinely open.

## HIST-027 — seven of seventeen creatures read blue

- **source:** `ralph/BACKLOG.md:326`
- **original_id:** `ROSTER-BLUE`
- **title:** Water and Air were handed the same half of the colour wheel
- **player_visible_problem:** At the size a creature appears in the world or on a roster row, Ripplet, Paddlenewt, Brooktail, Reedwing, Galewisp, Galecrest and Pipwing all read blue-to-white — a roster of seventeen that looks like three animals.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** Each species individually matches its own owner board; the problem is only visible laying all seventeen out. Explicitly **not** a per-species fix — needs one sitting by someone allowed to overrule an individual board. The Ground half is already warm, so this is the remaining half.
- **owner_reported:** no
- **system_class:** art/asset
- **likely_still_valid:** yes

## HIST-028 — an alpha does not own its clearing

- **source:** `ralph/BACKLOG.md:345`
- **original_id:** `ALPHA-PRESENCE`
- **title:** 1.3× reads as a bigger animal, not as a field boss
- **player_visible_problem:** A rare/alpha encounter is a slightly larger version of an ordinary creature. It does not feel like an event.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23 (CREATURE-IDENTITY-2 added alpha colourways, a rim light and a permanent mote aura)
- **status_evidence:** The presentation half is recorded as **closed** by CREATURE-IDENTITY-2. What is explicitly still open is whether the 1.3×/1.4× multiplier should rise — it grows the collider, the hit cone's reach and the catch accuracy bonus together, so it is a gameplay/balance decision plus encounter staging, filed rather than made. Related to `HIST-096` (PW2).
- **owner_reported:** no
- **system_class:** progression/economy (encounter staging)
- **likely_still_valid:** yes — as a decision, not as a defect.

## HIST-029 — a built floor steps because of where the player was standing

- **source:** `ralph/BACKLOG.md:391`
- **original_id:** `GATEB-FINDINGS` 1
- **title:** `snap_to_grid` takes height from the raw aim point, not the resolved cell centre
- **player_visible_problem:** Placing four floor pieces across the same ground produces a stepped floor, because each piece took its height from wherever the player happened to be aiming rather than from the cell it landed in.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** Found while driving Gate B for real; it forced two rebases in `gate_a_build_segment.gd`'s preflight. Named as a change to the live ghost's own maths, wanting its own task and regression pass. No closing evidence.
- **owner_reported:** no (sits under the owner's build complaints, OP21-07/08/09 lineage)
- **system_class:** input ownership / build
- **likely_still_valid:** yes

## HIST-030 — you cannot build next to a tree or an NPC

- **source:** `ralph/BACKLOG.md:400`
- **original_id:** `GATEB-FINDINGS` 2
- **title:** Build still loses Interact to a harvest node or an NPC
- **player_visible_problem:** With the hammer out, standing near a gatherable or a villager, pressing Interact chops or talks instead of placing — so a player who wants to build beside a tree has to walk away from it first.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** Owner directive 2026-08-23 §3 was implemented as written (the deployed creature and the ride prompt stand down while the hammer is out; pinned by `smoke_build_wins_while_hammer_is_out.gd`, closed as `GATEB-COORD` in `DONE.md`). It deliberately did **not** go further, because doing so would mean Grandpa no longer answers a player holding a hammer — a bigger call than the directive makes. Marked **owner ruling wanted**.
- **owner_reported:** yes — the entry names this as the likely root of the original owner "building doesn't work" report.
- **system_class:** input ownership
- **likely_still_valid:** yes

## HIST-031 — one knocked-out creature costs the player a whole night

- **source:** `ralph/BACKLOG.md:409`
- **original_id:** `GATEB-FINDINGS` 3
- **title:** "Rested, fed and happy" is three things and a bed buys only the first
- **player_visible_problem:** If a creature faints during an ordinary build session, the player has no way to cheer it up. It arrives at the tournament full, rested and unhappy, and the marshal turns the whole team away — costing another in-game night.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** Numbers recorded from `data/config/creature_condition.json`: happiness starts at 55 against a gate of 60, a completed rest is +12, a faint is −12, and `CONDITION.feed()` refuses an already-fed creature. The Gate B tail sleeps a second night, which works and reads fine. Whether petting / a favourite food / a won fight should raise happiness is filed as a **design question** (`model: fable`).
- **owner_reported:** no
- **system_class:** progression/economy (creature care)
- **likely_still_valid:** yes — as an unanswered design question with a measured cost.

## HIST-032 — the gather route is the chapter's longest dead-travel stretch

- **source:** `ralph/BACKLOG.md:419`
- **original_id:** `GATEB-FINDINGS` 4
- **title:** A 300 m round trip north for two fiber stops
- **player_visible_problem:** The first-session gathering errand sends the player 300 m out and back for two stops, which is the longest stretch of nothing in the opening.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** The wood fill closes its shortfall in ~18 scatter stops; the authored route still ends at (−168, 312). The entry names **Gate F** as the pass that should measure this against `docs/MEADOWS_PROGRESSION_CURVE.md` before it is called acceptable pacing — i.e. it is explicitly deferred to this run. Partly mitigated since: `GATEB-COORD` added eight new authored stops on the practice-path loop the first day already walks (band1 orders 1020–1027).
- **owner_reported:** no
- **system_class:** world density
- **likely_still_valid:** unsure — the budget change moved stops nearer the village, but nobody re-measured the route length.

## HIST-035 — three creature beds may not be affordable near the village

- **source:** `ralph/BACKLOG.md:515`
- **original_id:** `GATEB-BED-BUDGET`
- **title:** Fiber is the binding constraint: 18 authored against 34 needed
- **player_visible_problem:** The tutorial teaches the player to build three creature beds before the tournament, and the ground near the village pays for one.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** **`DONE.md` and `BACKLOG.md` conflict, and both are on `main`.** `BACKLOG.md:515` still reads open with the 57/42/18-vs-45/17/34 table. `DONE.md`'s `GATEB-COORD` entry says the budget was raised — eight new authored stops (+12 wood, +20 fiber, band1 orders 1020–1027) and `TARGET_STOCK` 57/42/18 → 69/42/34 — and that the tail places three beds and sleeps the team in one night. The BACKLOG entry appears to be stale prose the closing pass did not reconcile, which is exactly the failure `CLAUDE.md` warns about; it is carried here rather than deleted because the closing evidence is a harness stock target, not a walked natural-route measurement.
- **owner_reported:** yes (owner directive 2026-08-23 §1)
- **system_class:** progression/economy
- **likely_still_valid:** no — most likely closed by GATEB-COORD; the residual doubt is whether a *player* walking the natural route collects the raised budget, which only a played run answers.

## HIST-036 — the objective tells you what, never how

- **source:** `ralph/BACKLOG.md:546`
- **original_id:** `OBJECTIVE-HINT-ON-HUD` (OP23-04 / OP23-09)
- **title:** `quest_log.gd::tracked_hint()` is written, tested, and nothing draws it
- **player_visible_problem:** The opening's guidance — "`{interact}` to take the key, then `{interact}` at the gate" — only exists inside the quest-log tab, so a player who never opens the menu is told the objective and not the button.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** Measured rather than skipped: the HUD's objective block is 420 px wide at a 38 px legibility floor — about twenty characters a line — so a hint naming an action and a button takes the block from 170 px to nearly 300, on a HUD the same owner playtest (OP23-09) already calls too large. Explicitly sequenced **after** OP23-09 re-proportions that corner. Shortening the hints is named as not the fix.
- **owner_reported:** yes (OP23-04)
- **system_class:** navigation/objectives
- **likely_still_valid:** yes — and blocked behind `HIST-136`.

## HIST-038 — three merlon sizes in one castle silhouette

- **source:** `ralph/BACKLOG.md:602` (and the duplicate at `:796`)
- **original_id:** `STRONGHOLD-MERLONS`
- **title:** Crenellations are welded to tower size
- **player_visible_problem:** Looking at the fortress, the battlements are three (in one view, four) different sizes in the same frame, so the building does not read as one structure built by one people.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** Named by round 1's critique, confirmed and located by round 2 with exact module scales (curtain 2.6, flankers 3.4, keep 3.8, inner bailey ring 2.0). Not fixed because merlons are part of each module's mesh and `building_prefabs.json` carries one uniform `scale` per module — dropping the flankers costs 3.3 m of gatehouse height and moves the measured south face that banners, lamps and colliders are placed against. A massing change on the hero landmark.
- **owner_reported:** no
- **system_class:** art/asset
- **likely_still_valid:** yes

## HIST-039 — a glitch-white mesh on the band 4 ridge crest

- **source:** `ralph/BACKLOG.md:620` (and the duplicate at `:814`)
- **original_id:** `BAND4-RIDGE-WHITE`
- **title:** Untouched and unconfirmed
- **player_visible_problem:** A bright white untextured shape sits on the skyline of the Upper Meadows ridge.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** Never confirmed as real geometry. The repo's own second-path rule requires confirming it is not a capture artefact before changing anything, and the confirming render was starved out at 11 minutes on a contended box. Possibly the same family as `HIST-071` (BILLBOARD-WHITE), `HIST-093` (VEG-WHITECARD) and `GATE_D_REMAINDERS` §5's "distant-LOD instances rendering white" (`HIST-126`) — four white-artefact reports that have never been reconciled with each other.
- **owner_reported:** no
- **system_class:** art/asset
- **likely_still_valid:** unsure — may not exist.

## HIST-041 — the ground is a picture of grass, not grass

- **source:** `ralph/BACKLOG.md:635`
- **original_id:** `WORLD-GRASS`
- **title:** Grass placed in quantity and scaled to a few centimetres
- **player_visible_problem:** At eye height the player sees the terrain's painted texture rather than grass, with a bald ring around them where the scatter stops.
- **date_opened:** 2026-08-25 · **last_touched:** 2026-08-25 (active lane)
- **status_evidence:** Measured on `main`: the `grass` layer is 110 clumps × 130 plus 900 strays plus a 2400 verge, scaled **0.14–0.42** where `bushes` sit 0.6–1.5 and `trees` 0.55–1.35; `corridor_fill.density_scale` is **1.0** for grass against **6.0** for bushes and trees, so the fill covering 7.5 km outside authored clumps barely places any; `lod_range` 55 m leaves the bald ring. Owner-directed against `docs/reference/moong-*.jpg`. Binding constraint is GPU, unmeasurable in this container (`HIST-042`). This is one of the two lanes `START_HERE.md` currently routes work into.
- **owner_reported:** yes (owner brought the reference and named grass as what matters most)
- **system_class:** world density
- **likely_still_valid:** yes — open and in flight.

## HIST-042 — nobody has measured the GPU half on the device

- **source:** `ralph/BACKLOG.md:672`
- **original_id:** `PERF-ROG-GPU`
- **title:** The half of OP23-01 no container can answer
- **player_visible_problem:** The game may still be slow on the ROG Ally for reasons no test in this repo can see.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-25
- **status_evidence:** The CPU half is fixed and measured (arbiter polling 24,461 prompt providers a frame; per-frame CPU −86..−90% at six corridor sites, 33–40 ms → 3.8–4.7 ms). The GPU half cannot be measured here: under the Compatibility renderer the draw-call counters count MultiMesh *batches*, not instances, and this box rasterises in software. What is known: 22,109 MultiMeshInstance3D, 1,605 MB static, 5,789 draw calls at the worst measured view. The entry prescribes a device readout (`debug_overlay_on_boot: true`) at the village, band 4 and the stronghold. `ACTIVE_GAME_PLAN.md` §6 condition 14 and `GATE_F_EVIDENCE_2026-08-23.md` §6 both record this as the one condition unprovable without hardware.
- **owner_reported:** yes (OP23-01)
- **system_class:** performance
- **likely_still_valid:** yes

## HIST-043 — 1.6 GB of static memory for one chapter, and nothing watches it

- **source:** `ralph/BACKLOG.md:687`
- **original_id:** `PERF-ROG-MEMORY`
- **title:** No budget assertion exists for memory
- **player_visible_problem:** Nothing prevents the next density or population increase from pushing the game past what a 16 GB shared-memory handheld can hold, and the failure mode on a handheld is not a slow frame, it is a crash.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** `tools/perf_profile.gd` reports 1,605 MB static and 89,137 nodes on `main`'s bake; `VISUAL-GROUNDCOVER`'s took it to 1,755 MB / 126,037 nodes. Explicitly **not** measured as a problem and explicitly not to be optimised on suspicion — the ask is a budget assertion in the shape `test_scatter_perf_budget.gd` already uses. `translated: yes`.
- **owner_reported:** no
- **system_class:** performance
- **likely_still_valid:** yes — as a missing guardrail, not as a defect.

## HIST-044 — 909 creature bodies are built at boot and never despawned

- **source:** `ralph/BACKLOG.md:697`
- **original_id:** `PERF-ROG-WILD-BOOT`
- **title:** A boot-time and memory cost that grows with any density directive
- **player_visible_problem:** Longer startup and a bigger memory footprint than the world on screen needs.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** Not a per-frame cost — STREAM-D's cluster activation works (8–15 tick at any site; 41 of 939 AnimationPlayers advance). `encounter_director.gd::_spawn_creatures()`'s own header names it as deliberately untouched. Recorded so the next density directive is priced before it lands. `translated: yes`.
- **owner_reported:** no
- **system_class:** performance
- **likely_still_valid:** yes — as a known, priced, deliberate cost.

## HIST-045 — the vegetation LOD lever is wired, gated off, and worth little

- **source:** `ralph/BACKLOG.md:706`
- **original_id:** `PERF-ROG-LOD-REMAINDER`
- **title:** `scatter_lod_ranges` defaults false; measured effect 5–16% at absurd settings
- **player_visible_problem:** None directly; it is a performance lever that is not paying.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** Measured: at the authored 110–260 m ranges it changes draw calls by less than noise; forcing every range to 20 m removes only 5–16%. Would become worth something with a genuine low-poly LOD1 mesh per scatter model — which `CLAUDE.md` forbids generating for the Meadows. Overlaps `HIST-066` (PERF-LOD), which is the same lever from the Terrain3D side.
- **owner_reported:** no
- **system_class:** performance
- **likely_still_valid:** unsure — real but small, and the enabling asset is forbidden.

## HIST-046 — Stone & Root is the chapter's quiet band

- **source:** `ralph/BACKLOG.md:725`; measured in `ralph/GATE_F_EVIDENCE_2026-08-23.md` §3
- **original_id:** `BAND2-THIN`
- **title:** Four independent measurements agree and none of them individually fails
- **player_visible_problem:** Band 2 is the stretch a player is most likely to describe as the boring one — the fewest things per kilometre, the fewest kinds of creature, and the single longest walk in the chapter with nothing new in it.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** 36.6 POI/km against a 49.6 chapter average and band 5's 81.4; 4 distinct wild species against 8/9/6/5 elsewhere and 12 chapter-wide; seven of the chapter's eighteen 100 m+ intervals; the worst gap anywhere, 165 m at 4,782 m along, broken by a berry cluster. The entry insists 165 m is ~41 seconds and **must not** be fixed as if it were dead travel — the open question is whether it is deliberate breathing room before the Warrens.
- **owner_reported:** no
- **system_class:** world density
- **likely_still_valid:** yes — as an unanswered question, with numbers.

## HIST-048 — throwing an orb still feels bad

- **source:** `ralph/BACKLOG.md:830`
- **original_id:** `CATCH-FEEL` / OP9 / prompt 45
- **title:** Two thirds of throws miss, measured on a harness aimer
- **player_visible_problem:** The reticle sits on the creature, the orb goes somewhere else, and the orb is gone. The owner's words: *"I never know if I was close."*
- **date_opened:** 2026-08-22 (OP9 lineage from 2026-08-18) · **last_touched:** 2026-08-23
- **status_evidence:** This entry has been superseded **four times inside itself** and the surviving state is: the aim regression is fixed (`ab4ae014`), the ballistic launch is correct, the assist bounds the lead not the range, and the real root cause was that the trainer kept walking after release so nineteen consecutive orbs were spent on throws physically incapable of landing — fixed in three parts by `CATCH-BLOCKER` (`DONE.md`). `ASSESSMENT_2026-08-23.md` records the old P0 "first catch fails deterministically" as **not reproducing in three independent runs**. What the entry says remains open, in its own words: *"the strike rate is measured on a harness aimer, not on a human with a thumbstick"*, and two configs still disagree about how far away a fight is (`launch_assist_max_distance: 2.6` vs `flow.engage_range: 6.0`). The owner has not re-played catching since.
- **owner_reported:** yes (OP9)
- **system_class:** combat/camera (catching)
- **likely_still_valid:** unsure — the measured defects are fixed; the owner's original feel complaint has never been re-tested by a human.

## HIST-049 — your own creature eats your orbs, silently

- **source:** `ralph/BACKLOG.md:863`
- **original_id:** `ORB-BLOCKED`
- **title:** The orb is spent before flight resolves, and the refusal does not name the blocker
- **player_visible_problem:** The player throws, their own creature or their own body intercepts the orb, the orb is consumed, and the only feedback is "the orb went wide" — so catching reads as random.
- **date_opened:** 2026-08-22 · **last_touched:** 2026-08-23
- **status_evidence:** Three of eight throws in the blind playtest logged `first_hit=AllyCreature` or `first_hit=Body`. **Contradicted by a later line in the same file**: `CATCH-FEEL measured` ends with *"BP2's interception fix already in (orbs now pass through your own creature)"*. Whether the refusal now **names** the blocker, and whether the orb is refunded (an open design call in the entry), is not recorded either way. `CATCH-BLOCKER` did add a miss message reporting how near the orb came and what ended the flight.
- **owner_reported:** no (compounds OP9)
- **system_class:** combat/camera (catching)
- **likely_still_valid:** unsure — the interception half looks closed; the feedback and refund halves are not recorded as answered.

## HIST-050 — landmarks an NPC told you about do not appear on the map

- **source:** `ralph/BACKLOG.md:875`
- **original_id:** `MAP-FOG-LANDMARKS`
- **title:** The other half of owner directive 2026-08-22 §3
- **player_visible_problem:** A villager tells the player about the Old Quarry and the map still shows nothing there until they walk to it, so being told about a place buys the player nothing.
- **date_opened:** 2026-08-22 · **last_touched:** 2026-08-23
- **status_evidence:** §3's first half ("the village and the roads out of it start revealed") shipped in `GATES-ABC-VERIFY` and was strengthened by OP23-FIXPACK. The second half was **filed rather than half-built**: it needs a "somebody told me about this" state distinct from `map_state.gd`'s existing `_discovered` ("I have stood next to it"), plus the dialogue hooks that set it. The entry warns explicitly against conflating the two states.
- **owner_reported:** yes (owner directive 2026-08-22 §3)
- **system_class:** navigation/objectives
- **likely_still_valid:** yes

## HIST-051 — five HUD defects a blind critic named at the Ally's own resolution

- **source:** `ralph/BACKLOG.md:886`
- **original_id:** `HUD-JUDGE-5`
- **title:** Party panel transparency, ragged objective wrap, clipped satiety, phantom hotbar icons, an unexplained underline
- **player_visible_problem:** "Ripplet Lv 1" loses contrast over dark scenery; the objective text wraps with "creature." alone on its own line; "FOOD" and "100%" run to the panel edge, amber on amber; four empty hotbar slots each hold a near-identical white-cross icon so they do not look empty; and an unexplained strip under the bottom legend reads as a progress bar stuck at 0%.
- **date_opened:** 2026-08-22 · **last_touched:** 2026-08-22
- **status_evidence:** Judged at 1280×800, the Ally's own panel resolution. A sixth defect from the same pass (the same button labelled twice) is recorded fixed; these five are not. The entry also records what **works** and must not be undone: the trainer's silhouette and ground contact, and the party panel's information hierarchy. Overlaps `HIST-054` (a second judge, different frames, four of five findings distinct) and `HIST-004`/`HIST-136`.
- **owner_reported:** no
- **system_class:** UI architecture
- **likely_still_valid:** unsure — several HUD lanes have landed since (HUD-EMPHASIS lineage, VIS-UI), and no pass records re-checking these five specifically.

## HIST-052 — the landmark the opening points at renders as a black cutout

- **source:** `ralph/BACKLOG.md:908`
- **original_id:** `LANDMARK-BLACK`
- **title:** The hilltop rock-and-tree cluster renders unlit in all four weather states
- **player_visible_problem:** The thing the opening composition aims the player at is a near-black silhouette with no internal form, with stair-stepped alpha edges, while the grass beside it is fully lit.
- **date_opened:** 2026-08-22 · **last_touched:** 2026-08-25
- **status_evidence:** A blind critic ranked it the second-biggest gap from the references and read it as a bug, not a choice: *"nothing else in the scene is that dark"*. Possibly a material or LOD/billboard fault. **Plausibly root-caused since without being re-checked:** `GATE-E-STRONGHOLD-ART` found `art.json` putting the sun in the NORTH sky while the stronghold's hero face is SOUTH, and `VISUAL-LIGHT` then flipped the sun — the same defect shape. `WEATHER-2` (`HIST-060`) independently records "the crest tree/rock cluster renders near-black even under full sun" as present in all four states.
- **owner_reported:** no
- **system_class:** terrain/composition
- **likely_still_valid:** unsure — a plausible root cause landed; nobody re-rendered this frame.

## HIST-053 — levelling up is never announced on screen

- **source:** `ralph/BACKLOG.md:919`
- **original_id:** `OBJECTIVE-LEVEL-UP` / OP11
- **title:** Nothing has ever driven a level-up and read the resulting text
- **player_visible_problem:** A creature levels up and the player is not told which creature, what level it reached, or what it unlocked — in a game whose central motivation is team progression.
- **date_opened:** 2026-08-22 · **last_touched:** 2026-08-22
- **status_evidence:** Recorded **NOT VERIFIED rather than assumed** — the verification pass never drove a level-up. `smoke_tournament_bracket.gd` fights real rounds and is named as a cheap place to assert it. OP11 (2026-08-18) is the owner's original ask.
- **owner_reported:** yes (OP11)
- **system_class:** progression/economy
- **likely_still_valid:** unsure — it may well work and simply never have been read off screen.

## HIST-054 — five more UI defects, from a second blind judge

- **source:** `ralph/BACKLOG.md:926`
- **original_id:** `HUD-JUDGE-2`
- **title:** Legend out-shouts the prompt; hotbar leaks past the dialogue panel; orphaned words; repeated icons; two glyph grammars in one line
- **player_visible_problem:** The always-on legend is louder than the contextual prompt above it; a stray hotbar slot pokes out beside the dialogue panel; "Catch your first wild / creature." orphans its last word in all seven UI frames; four of five hotbar slots draw near-identical icons; and "[C]" bracket-text sits beside boxed key glyphs, greyed enough to read as disabled.
- **date_opened:** 2026-08-22 · **last_touched:** 2026-08-22
- **status_evidence:** Read off frames rendered **after** the HUD lineage landed, so recorded as current at filing. Deliberately not taken on the verification branch: re-tuning widths, alignment and z-order at the end of a verification pass risked regressing what those blind rounds bought, for defects costing the player nothing functional. Two findings from the same report are explicitly **not** here and must not be re-added: the combat-prompt "text collides with text" (capture artefact) and "RB named twice" (fixed 40 minutes before the frames were shot).
- **owner_reported:** no
- **system_class:** UI architecture
- **likely_still_valid:** unsure — same reason as `HIST-051`; overlaps `HIST-017` and `HIST-004`.

## HIST-055 — the tournament board reads as drawn wrong

- **source:** `ralph/BACKLOG.md:955`
- **original_id:** `BOARD-BRACKET`
- **title:** Round-two joins float and never meet the semifinal; the final dangles into empty panel
- **player_visible_problem:** Anyone who has seen a tournament bracket reads this one as broken: lines that do not join, a final with no slot label, and the right half of the board empty grey. The board face is also a flat untextured panel inside a frame that does read as carpentry.
- **date_opened:** 2026-08-22 · **last_touched:** 2026-08-22
- **status_evidence:** The names are legible and read as real village record-keeping, which is what the owner directive asked for — this is about the plumbing and the surface, not the content. Judge's summary: *"carpentry frame, UI panel face."* Needs a texture pass, small art rather than scene work.
- **owner_reported:** no (the tournament itself is an owner directive)
- **system_class:** UI architecture / art
- **likely_still_valid:** yes

## HIST-056 — two of three starters face away from the camera

- **source:** `ralph/BACKLOG.md:968`
- **original_id:** `STARTER-PORTRAITS`
- **title:** The one moment the game asks a player to choose by appearance hides two of the choices
- **player_visible_problem:** At the starter picker, Terrapup presents a readable 3/4 view, Ripplet is side-on with its face barely resolved, and Galewisp shows its back.
- **date_opened:** 2026-08-22 · **last_touched:** 2026-08-22
- **status_evidence:** The poses differ again in `name-prompt.png`, so these are live renders with uncontrolled framing rather than authored portraits — the fix is camera control on the picker, not new art. The judge rated the creature designs themselves the strongest thing in the whole frame set, which makes the framing the only thing in the way. This is the permanent-companion decision, so it sits directly on the five-creature rule.
- **owner_reported:** no
- **system_class:** creature attachment
- **likely_still_valid:** yes

## HIST-060 — one lighting rig with a dimmer and a sky swap, not four weathers

- **source:** `ralph/BACKLOG.md:1519`
- **original_id:** `WEATHER-2`
- **title:** Cloudy is crushed rather than washed out; the sun shadow is identical in all four states; weather never touches the ground
- **player_visible_problem:** `cloudy` is the darkest of the four states with no clouds in it — a critic's read was *"did my brightness setting break?"* Rain has no wet ground or specular response and its streaks are invisible against terrain. Fog sits at the horizon only, so it reads as a backdrop rather than atmosphere you stand in. Foreground greens go near-black in the dark states, in exactly the screen region the player watches, on a seven-inch panel.
- **date_opened:** 2026-08-22 · **last_touched:** 2026-08-25
- **status_evidence:** OP21-21's washed-out grey is separately fixed and independently confirmed (saturation 0.18 → 0.36, `clear` weighted 3.0, `max_consecutive_non_clear: 2`). This entry is what the same critic found *instead*. All fixes named as in-scene grade/lighting work needing no new art. `VISUAL-LIGHT` has since flipped the sun and made the day/night clock continuous, which touches the same file (`art.json`) — with **no blind pass run**.
- **owner_reported:** no (OP21-21 lineage is owner-reported and is closed)
- **system_class:** terrain/composition (lighting)
- **likely_still_valid:** unsure — the file moved under it, unjudged.

## HIST-062 — what a blind pass found across the whole committed frame set

- **source:** `ralph/BACKLOG.md:1560`
- **original_id:** `SITE-ART-DEBT`
- **title:** Bare gradient skies, one green to the horizon, a white floating quad in four frames, cube architecture, absent Team Tether colour
- **player_visible_problem:** The sky is a bare vertical gradient in every daylight frame where the key art has cumulus in all seven panels; the ground is one green from foreground to horizon with mown-lawn striping; a white floating quad appears in four separate frames; the gate and the relay read as cubes with a rock texture, with human figures dwarfed 4–5× by the pylons; and Team Tether's oxblood — the danger colour on their banners in the key art — has not landed in the build, whose only faction signature is a teal glow line that reads as a friendly waypoint.
- **date_opened:** 2026-08-22 · **last_touched:** 2026-08-23
- **status_evidence:** Judged against `docs/reference/tetherbound-meadows-keyart.png` blind. Six frames were pulled outright. Verdict on the two bar questions: keyart-world **no**; Palworld-kind **no from the whole set**. Partly moved since: `VISUAL_LEDGER.md`'s oxblood entry records the reserved hex lifting to `#5a3742` precisely because it failed legibility twice, and `GATE-E-STRONGHOLD-ART` hung nine banners on the castle. The sky, the single green, and the white quad are not recorded as addressed.
- **owner_reported:** no
- **system_class:** terrain/composition
- **likely_still_valid:** yes — in part; the oxblood half has moved.

## HIST-064 — the legendary's containment VFX renders as flat white slabs

- **source:** `ralph/BACKLOG.md:1601`
- **original_id:** `LEGENDARY-CAGE`
- **title:** The emissive clamps under GL Compatibility
- **player_visible_problem:** The chapter's climactic image — the legendary held inside Team Tether's machine — shows a dozen opaque white bars across the animal instead of a cold teal containment ring.
- **date_opened:** 2026-08-22 · **last_touched:** 2026-08-22
- **status_evidence:** `stronghold_climax.gd::_build_cage()` asks for `#7fd8c4` at energy 2.2; under this project's own renderer the emissive clamps. Evidence is `site/img/legendary-bound.jpg`, named as the chapter's last image and its worst-looking one. The stag behind the bars is fine. Same root pattern as `VISUAL_LEDGER.md`'s "metallic in this renderer" entry, which has now been diagnosed from scratch four times.
- **owner_reported:** no
- **system_class:** art/asset (VFX)
- **likely_still_valid:** yes

## HIST-066 — the Terrain3D vegetation LOD is written, tested, and switched off

- **source:** `ralph/BACKLOG.md:1710`
- **original_id:** `PERF-LOD`
- **title:** Two `asset.set()` calls commented out behind a `TODO(PERF-2)`
- **player_visible_problem:** ~130k vegetation instances render at full detail regardless of distance, which is spent frame budget on a handheld.
- **date_opened:** before 2026-08-22 · **last_touched:** 2026-08-22
- **status_evidence:** Off **on purpose**: `conventions.md` requires a blind pass for visual-affecting work and no before/after frames have ever been produced, so activating it would ship an unverified change to the approved lush pond pocket. Two lanes independently reached that judgement. Four capture attempts failed; the diagnosis was **corrected** — `--headless` combined with `--rendering-driver opengl3` hangs forever, and the entry now says the capture *very likely just works* once the invocation is fixed. Overlaps `HIST-045`.
- **owner_reported:** no
- **system_class:** performance
- **likely_still_valid:** yes — as an unmeasured, blocked-on-one-render lever.

## HIST-067 — what a player-built house still gets wrong up close

- **source:** `ralph/BACKLOG.md:1751`; detail in `ralph/BLOCKED.md:442`
- **original_id:** `BUILD-KIT-4`
- **title:** Interior cross-braces, unverified corner seam, proud door leaf, a stray grey brick
- **player_visible_problem:** From inside their own house the player sees scaffolding-like braces in the walls and a stray grey brick block behind them; the door leaf sits proud of its frame at the top hinge.
- **date_opened:** 2026-08-22 · **last_touched:** 2026-08-22
- **status_evidence:** Explicitly the **not-blocked** half of the roof/kit problem — `BLOCKED.md` separates these from the missing roof modules (`HIST-119`). The braces are real geometry within the 0.4 m wall thickness, not a double-sided plane, investigated with a scoped `cull_mode` probe. Also listed there: ridge caps reading as plastic against clay tile, inconsistent per-wall timber articulation, and a door threshold light leak.
- **owner_reported:** yes (OP21-08 / OP2 lineage)
- **system_class:** art/asset (build kit)
- **likely_still_valid:** yes

## HIST-068 — the storm road gorge still stops nothing

- **source:** `ralph/BACKLOG.md:1875`
- **original_id:** `STORM-GATE` (from `RG24` / `RG24-CONFIRMED`)
- **title:** The owner asked for a bridge guarded by two Team Tether grunts; it is not built
- **player_visible_problem:** There is a trench across a road that a player walks around in fifteen seconds. The owner's words: *"if I can walk around it in 15 seconds, what's the point."*
- **date_opened:** 2026-08-18 · **last_touched:** 2026-08-18
- **status_evidence:** The owner was shown the frame and answered: *"maybe a bridge that is protected by two team tether grunts. you beat them then go across."* The design is fully worked out in the entry (a third `gated_crossing.gd` subclass; `item_gate.gd` reading a `defeat_flag` a battle already writes; §36's grunt palette on the existing rig) and one real decision is named: the far side leads to ~61 m of empty field before the world boundary, with two honest options recorded and option 2 recommended. **Confirmed unbuilt at this SHA:** no `storm` entry exists in any `data/config/bands/*/trainers.json`.
- **owner_reported:** yes (RG24, then a verbatim owner ruling)
- **system_class:** navigation/objectives (world gating)
- **likely_still_valid:** yes — verified against the shipped data.

## HIST-070 — the fortress Team Tether holds has none of their apparatus on it

- **source:** `ralph/BACKLOG.md:1995`
- **original_id:** `STRONGHOLD-TETHER-HERO-PROPS`
- **title:** Brazier, gate pylon/relay mast, barbican, real cloth banner
- **player_visible_problem:** The braziers read as a dark cup on a stem at 26 m; the gatehouse's "Team Tether apparatus" is an emissive sphere in a cylinder; the ramp foot reads as a camp beside a ramp rather than a controlled entry; and the nine banners read as small red flags rather than an occupying army's colours.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** Recorded rather than generated: `CLAUDE.md` reserves Meshy for Team Tether hero objects **and never without owner-supplied reference art**, and there is none for any of these. Everything the lane shipped is installed-asset kit-bash; these are the places where that is visibly the ceiling. A terrain bound is recorded for whoever designs the barbican (the Rise climbs +34 m twenty metres west; the heightfield ends ~30 m east; a sprawl has to go south).
- **owner_reported:** no
- **system_class:** art/asset (blocked on owner art)
- **likely_still_valid:** yes

## HIST-071 — untextured white cards standing among the trees

- **source:** `ralph/BACKLOG.md:2020`
- **original_id:** `BILLBOARD-WHITE`
- **title:** Plain white rectangles upright in the grass among a copse
- **player_visible_problem:** Blank white cards stand in the world where trees or bushes should be.
- **date_opened:** 2026-08-18 · **last_touched:** 2026-08-18
- **status_evidence:** Seen in `shots/storm_pass/01-road-approach.png`. The entry names `EV2-landmark-oak` as precedent — a config bug that made `CherryBlossom_3` render in its native pink looked like an asset limitation and was not one. Almost certainly the same report as `HIST-093` (`VEG-WHITECARD`, filed independently from `MQ2B` round 6 on the same day) and possibly `HIST-039` and `HIST-126`; **no pass has ever reconciled the four white-artefact reports.**
- **owner_reported:** no
- **system_class:** art/asset
- **likely_still_valid:** unsure — real or a capture artefact; four reports, zero repros.

## HIST-072 — nothing on screen tells you what any button does

- **source:** `ralph/BACKLOG.md:2106`
- **original_id:** `RG3`
- **title:** A controller-first game with no button legend
- **player_visible_problem:** The verbs exist and work and the player cannot discover them.
- **date_opened:** 2026-08-18 · **last_touched:** 2026-08-18
- **status_evidence:** Contradicted by later work: an exploration legend exists and is repeatedly discussed (`HIST-054` complains it *out-shouts* the contextual prompt; `GATEB-COORD` describes the legend taking a verb back "beside Change Creature"), and `CONTROLLER-MAP` shipped the owner's authored pad map. Carried because the entry itself was never closed in `BACKLOG.md`.
- **owner_reported:** yes (RG3)
- **system_class:** UI architecture
- **likely_still_valid:** no — superseded in practice by the legend and the controller map; the residual is `HIST-017`'s glyph inconsistency and `HIST-078`'s missing build legend.

## HIST-073 — menus still do not read every input

- **source:** `ralph/BACKLOG.md:2143`
- **original_id:** `RG6`
- **title:** Third report of the class (`OW10`, `UI-PAD1`, then this)
- **player_visible_problem:** Some button on some menu does nothing, and the player cannot tell whether it is broken or whether they are pressing the wrong thing.
- **date_opened:** 2026-08-18 · **last_touched:** 2026-08-18
- **status_evidence:** The entry says it needs the owner's exact screen and button to be actionable — *"ask before guessing"* — or instrumenting every menu to log which action it saw. Substantial work has landed since across the class: `UI-PAD1`/`UI-PAD3` (pad `ui_accept`, with a trap-guard test), `CONTROLLER-MAP` (no held chords, a full authored map), `SETTINGS-SCROLL` (OP21-04), and `ASSESSMENT_2026-08-23.md` records `smoke_settings` PASS at 138 bindings / 22 destinations plus a static binding-collision enforcement test. No owner reproduction since 2026-08-18.
- **owner_reported:** yes (RG6)
- **system_class:** input ownership
- **likely_still_valid:** unsure — a whole class of fixes landed, but the item was never closed and never re-reported either way.

## HIST-074 — reloading a save does not restore your game

- **source:** `ralph/BACKLOG.md:2151`
- **original_id:** `RG7`
- **title:** Position and story flags do not survive a reload; one-time gifts can be taken twice
- **player_visible_problem:** The player reloads and finds themselves back through Grandpa's dialogue, able to collect a second starter and second villager gifts, and able to pick up a TM again.
- **date_opened:** 2026-08-18 · **last_touched:** 2026-08-23
- **status_evidence:** Contradicted by newer evidence: `ASSESSMENT_2026-08-23.md` records OP21-23 (Load Game dead end) as FIXED with `smoke_title_load_game` PASS on a physical pad and a **full restore**, and OP21-14 (team count) as FIXED "incl. save/reload". `tm_pickup.gd`'s header documents the one-time `tm:<id>` flag and `playground_world.gd::_place_tms()` skipping an already-taken TM. Carried because the RG7 entry itself was never closed and because "second things from the villagers" is a distinct claim nothing found addresses by name.
- **owner_reported:** yes (RG7)
- **system_class:** save/session
- **likely_still_valid:** unsure — the save half looks closed; the duplicate-gift half is unverified.

## HIST-076 — TMs look like cards on the ground, not orbs

- **source:** `ralph/BACKLOG.md:2214`; re-reported `ralph/OWNER_PLAYTEST_2026-08-23.md` OP23-07
- **original_id:** `RG12` / `OP23-07`
- **title:** Reported twice, five days apart, by the owner
- **player_visible_problem:** A TM lying in the world reads as a little card, where the owner asked for an orb in a colour distinct from a capture orb.
- **date_opened:** 2026-08-18 · **last_touched:** 2026-08-23
- **status_evidence:** **Confirmed in the working tree at this SHA:** `scripts/world/tm_pickup.gd` builds a `slab` MeshInstance3D plus a `rune`. No orb geometry. Nothing in `DONE.md` references OP23-07. The owner reported it once before OP23 and again in OP23, which under `START_HERE.md` §3 makes it a reopened item regardless of anything else.
- **owner_reported:** yes (twice)
- **system_class:** art/asset (items)
- **likely_still_valid:** yes — verified in code.

## HIST-077 — too many recipes are available at the start

- **source:** `ralph/BACKLOG.md:2219`
- **original_id:** `RG13`
- **title:** A gate, not a deletion — most should unlock through play
- **player_visible_problem:** The crafting list opens full at the beginning, so unlocking a recipe later means nothing.
- **date_opened:** 2026-08-18 · **last_touched:** 2026-08-18
- **status_evidence:** No closing evidence found in `DONE.md`, `ACTIVE_TASKS.md` or the gate evidence files. Adjacent work exists that could have addressed it incidentally: prompt 58 (`REWARD-resource-economy`), `test_recipes`'s free-build/free-craft contract test (OP21-10), and `chapter_rewards.json`'s invariants — none of which is about start-state recipe gating.
- **owner_reported:** yes (RG13)
- **system_class:** progression/economy
- **likely_still_valid:** unsure — no evidence either way.

## HIST-078 — once you pick a piece you cannot read how to place or rotate it

- **source:** `ralph/BACKLOG.md:2224`
- **original_id:** `RG14`
- **title:** The placement control legend does not survive the menu closing
- **player_visible_problem:** The player chooses what to build, the menu correctly gets out of the way, and with it goes the only thing that told them which button rotates and which places.
- **date_opened:** 2026-08-18 · **last_touched:** 2026-08-18
- **status_evidence:** `OW11` deliberately made the menu close on pick so the world is visible — the entry says that is right and stays. What is missing is the legend. Owner directive 2026-08-22 §1 later specified build-mode controls in full (X place, B exit, LT/RT rotate, d-pad snap/piece cycle, LB/RB category, Y dismantle), which is what a legend would have to show. No entry records a build-mode legend being drawn. Same family as `HIST-072`.
- **owner_reported:** yes (RG14)
- **system_class:** UI architecture
- **likely_still_valid:** unsure

## HIST-079 — the map does not show every authored trail

- **source:** `ralph/BACKLOG.md:2235` (`RG15`); `ralph/OWNER_PLAYTEST_2026-08-18.md` OP15
- **original_id:** `RG15` / `OP15`
- **title:** Rotate-to-heading and world-scale fit are done; trail completeness is not
- **player_visible_problem:** Routes the player can visibly follow in the world do not appear on the map, so the map disagrees with the ground.
- **date_opened:** 2026-08-18 · **last_touched:** 2026-08-23
- **status_evidence:** OP15 explicitly narrows RG15: *"movement-up behavior now seems to be working — verify-first, not rewrite-first"*, and names the **fresh remaining defect** as the map bake not representing all authored trails (prompt `52-MAP-all-authored-trails-visible.md`). `MAP-EXTENT` closed the world-scale half; OP21-15 (map unusable) is recorded FIXED in the assessment with `tab_map` follow/zoom. No evidence found for the trail-completeness half.
- **owner_reported:** yes (RG15, then OP15)
- **system_class:** navigation/objectives
- **likely_still_valid:** unsure — the named remaining half has no closing evidence; the rest is closed.

## HIST-081 — the tether pylons are not a continuous navigation line

- **source:** `ralph/BACKLOG.md:2255`
- **original_id:** `RG17`
- **title:** An NPC at the first pylon, and a continuous line of them to the stronghold
- **player_visible_problem:** The owner asked for the pylons to be the thing you navigate by — an unbroken line from the first one to the fortress, with someone at the first one explaining that Team Tether is draining the land. Without it there is no visible spine to follow.
- **date_opened:** 2026-08-18 · **last_touched:** 2026-08-18
- **status_evidence:** The entry calls this cheap and strong: the pylons already exist as Team Tether hero objects and the drained-ground grammar (`D45`) needs something to follow. Relay pylons and tether cables are confirmed present in the build (the 2026-08-23 blind critique lists them as a positive). Whether they form a **continuous line to the stronghold**, and whether an NPC stands at the first one, is not recorded anywhere found.
- **owner_reported:** yes (RG17)
- **system_class:** navigation/objectives
- **likely_still_valid:** unsure

## HIST-082 — day and night should be progressive and unequal

- **source:** `ralph/BACKLOG.md:2350`; reopened `ralph/OWNER_PLAYTEST_2026-08-23.md` OP23-05/06
- **original_id:** `RG21` / `OP23-05` / `OP23-06`
- **title:** Two asks — a continuous transition, and a short night relative to day
- **player_visible_problem:** Day flips to night in one frame instead of progressing, and the owner separately says *"night is forever"* and asks for a short night as in Valheim.
- **date_opened:** 2026-08-18 · **last_touched:** 2026-08-23
- **status_evidence:** The **transition** half was root-caused and fixed by `VISUAL-LIGHT` (`day_cycle.gd::interpolate_at()`, a continuous blend in `world_look.gd::_process()` throttled to 0.2 s, `_lerp_degrees` for sun yaw) — and that entry states plainly that the fix is **not render-verified**: the capture tool was written and killed mid-render, so *"no visual confirmation that the transition actually reads as progressive darkening, and no confirmation of a navigable night floor, exist yet."* The **night-length** half is not addressed by that work and no entry records it. See `HIST-135`.
- **owner_reported:** yes (RG21, then OP23-05/06)
- **system_class:** terrain/composition (world clock)
- **likely_still_valid:** yes — the length half outright, the transition half as unverified.

## HIST-083 — the torch is too dim, and held wrong

- **source:** `ralph/BACKLOG.md:2359` (`RG22` brightness half); `ralph/OWNER_PLAYTEST_2026-08-23.md` OP23-10
- **original_id:** `RG22`-brightness / `OP23-10`
- **title:** The hand-attach shipped; brightness was deliberately gated and the pose was re-reported
- **player_visible_problem:** At night the torch does not light enough of the world to be worth drawing, and the way the trainer holds it does not look natural.
- **date_opened:** 2026-08-18 · **last_touched:** 2026-08-23
- **status_evidence:** The hand-attach half landed (`210c1ae5`) and the torch now gates on equip state. The brightness half was **deliberately parked** until the night rounds settled, because night's own ambient floor moved a long way in the same session (`near_luma` 0.000–0.015 → 0.028–0.107) and the torch's relative contribution had not been re-checked. The night rounds have since moved again (`VISUAL-LIGHT`, unverified — `HIST-135`), so the dependency this item waits on is still not settled. OP23-10 is a fresh owner reproduction of the *pose*, which OP4 (2026-08-18) also reported as "anatomically wrong, flame/top must be upright".
- **owner_reported:** yes (RG22, OP4, OP23-10)
- **system_class:** art/asset + world clock
- **likely_still_valid:** yes

## HIST-084 — rocks you walk through, and invisible things you get stuck on

- **source:** `ralph/BACKLOG.md:2389`
- **original_id:** `RG23`
- **title:** The missing-collision half is genuinely new
- **player_visible_problem:** Some rocks have no collision and the player walks straight through them; elsewhere they get stuck on something invisible. The owner: *"It makes no sense."*
- **date_opened:** 2026-08-18 · **last_touched:** 2026-08-25
- **status_evidence:** The **invisible-blocker** half is the `WALL1`/`SPINE-WEDGE` family, both root-caused (a `CarveFailsafe` `Area3D` volume; a spoke's 146 m severing trench) and both fixed. The **missing-collision** half is recorded as new: scattered rocks are `MultiMesh` instances and only some carry colliders — *"establish which"*, never done. Note the 2026-08-25 handover independently found a live wedge at (53,−65) which turned out to be a rock (`HIST-090`), i.e. rocks around the player are still doing unexpected things.
- **owner_reported:** yes (RG23)
- **system_class:** terrain/composition (collision)
- **likely_still_valid:** yes — for the missing-collision half.

## HIST-085 — boot time on the device, and quitting from the menu

- **source:** `ralph/BACKLOG.md:2411`
- **original_id:** `RG25`
- **title:** Three things: boot cost on target hardware, a title/save-select screen, and quit
- **player_visible_problem:** The game takes a long time to start on a ROG Ally, and the owner asked to be able to quit from the menus.
- **date_opened:** 2026-08-18 · **last_touched:** 2026-08-25
- **status_evidence:** The **title screen** half is closed — `smoke_title_load_game` passes with a physical pad and a full restore (OP21-23 FIXED). The **boot cost** half has moved several times (the missing scatter bake: 58–60 s → ~1.3 s per the assessment) but the corridor rebuild roughly doubled bake cost again (placements 10.4 s, batch build 8.4 s), and none of it is measured on an Ally — same evidence gap as `HIST-001`/`HIST-042`. **Quit from the menu** is not recorded as done anywhere found.
- **owner_reported:** yes (RG25, OP5)
- **system_class:** performance / UI architecture
- **likely_still_valid:** unsure — one third closed, one third folded into the device-evidence gap, one third with no evidence at all.

## HIST-090 — the player can still wedge on a slope beside a rock

- **source:** `ralph/BACKLOG.md:3199` (`OF15`, marked CLOSED); reopened in `ralph/HANDOVER_2026-08-25_CI_GREEN_AND_TWO_LANES.md:26`
- **original_id:** `OF15`
- **title:** A real, pre-existing, still-unfixed slide wedge at world (53,−65)
- **player_visible_problem:** Walking normally, the player sticks against a rock on a shallow slope and cannot get free by walking.
- **date_opened:** 2026-08-15 · **last_touched:** 2026-08-25
- **status_evidence:** **`BACKLOG.md` says CLOSED; the newest handover says otherwise, and this is the sharpest DONE-vs-current conflict in the register.** The 08-25 session diagnosed it with a purpose-built probe (`tools/_probe_wedge_53_neg65.gd`) on a ~10–15° slope near a rock, matched it to the documented OF15 defect, and **mitigated rather than fixed it** — a third flake-retry attempt on `smoke_traversal.gd` matching its observed ~2-in-a-row rate. The underlying physics fix was deliberately not attempted because it is a traversal-philosophy change, which `CLAUDE.md` requires flagging rather than inventing. The handover's own instruction: *"Whoever next touches player slope/slide physics should look at this before assuming it's new."* Related: `db326f3d` "OF15: a deflection must not walk you off a ledge", and `bbbf3bce` "Thin rock clumps 36 → 12 per clump; this did NOT fix the wedge".
- **owner_reported:** yes (OF15 was owner-reported 2026-08-15)
- **system_class:** terrain/composition (collision)
- **likely_still_valid:** yes — explicitly mitigated, not fixed, three days ago.

## HIST-093 — blank white billboard cards in the ground or floating

- **source:** `ralph/BACKLOG.md:3529`
- **original_id:** `VEG-WHITECARD`
- **title:** Four of eight Band-2 day frames
- **player_visible_problem:** Flat blank white cross-quad cards planted in the ground or hanging in the air, one large in the foreground and several strung along tree lines at range.
- **date_opened:** 2026-08-18 · **last_touched:** 2026-08-18
- **status_evidence:** New to `MQ2B` round 6; every prior round's README was grepped for white/billboard/impostor/blank with no hits. **Already ruled out** by that lane: a missing texture on `Grass_Wide_Short`/`Wide_Tall.gltf` (both correctly reference `Grass.png`, file and `.import` present). **Not yet investigated:** runtime material binding — possibly Godot auto-LOD dropping an alpha-cutout material on a MultiMesh instance. Named as the remaining thing between `MQ2B` and closing. Almost certainly the same defect as `HIST-071`.
- **owner_reported:** no
- **system_class:** art/asset
- **likely_still_valid:** unsure — same reason as `HIST-071`; never reproduced since.

## HIST-094 — no region has been finished to the standard the owner's stopping rule defines

- **source:** `ralph/BACKLOG.md:3551`
- **original_id:** `MQ2B`
- **title:** A band is a loop that a blind critic ends, not one authoring pass
- **player_visible_problem:** No region of the Meadows has yet been iterated until an independent critic says nothing more can be done with the current terrain system and assets, so no region is proven to hold the quality bar the rest are meant to copy.
- **date_opened:** before 2026-08-17 · **last_touched:** 2026-08-23
- **status_evidence:** The stopping rule is a verbatim owner directive (2026-08-17): *"the current band we are working on should work until a blind review agent determines there's nothing else we can do."* Convergence is two consecutive rounds naming no new defect and moving no measured axis. `VISUAL_LEDGER.md` records that **no visual domain has converged** — every round so far has named new defects — and `GATE_D_REMAINDERS.md` §4 records D5's lane assessing its own ceiling, which it says should be confirmed by the full-corridor pass rather than accepted. Overlaps `HIST-144`.
- **owner_reported:** yes (the stopping rule is an owner directive)
- **system_class:** terrain/composition (process)
- **likely_still_valid:** yes

## HIST-095 — the Meadows content umbrella

- **source:** `ralph/BACKLOG.md:3614`
- **original_id:** `MQ3`
- **title:** Each region owes a clear entry, purpose, geography, objective, discovery, encounter, navigation, day/night usability and transition
- **player_visible_problem:** Regions that are traversed rather than visited.
- **date_opened:** before 2026-08-17 · **last_touched:** 2026-08-17
- **status_evidence:** Largely delivered since by the D1–D5 packages and measured by `GATE_F_EVIDENCE_2026-08-23.md` (571 points of interest, 12 species, five regional milestone smokes passing, a 22-entry objective chain). Carried because the umbrella entry was never closed and because its per-region checklist is not the same as the Gate F corridor's density numbers.
- **owner_reported:** no
- **system_class:** world density (content)
- **likely_still_valid:** no — most likely satisfied by D1–D5; the residual is `HIST-046` (band 2) and `HIST-105`/`HIST-106`.

## HIST-096 — an alpha must be more than a bigger creature

- **source:** `ralph/BACKLOG.md:3636`
- **original_id:** `PW2`
- **title:** Explicitly not "normal creature, larger scale, more HP"
- **player_visible_problem:** A rare encounter that is supposed to make an optional path worth taking plays exactly like an ordinary fight.
- **date_opened:** before 2026-08-17 · **last_touched:** 2026-08-17
- **status_evidence:** The requirement is at least one real behavioural or encounter difference per variant — aggression pattern, cadence, group behaviour, habitat, environmental advantage, a move variant, a special arena, or unusual time-of-day presence. Four alpha clusters exist (Gate F measured z=2900, 3890, 5150, 7255) with a `level_bonus` and, since `CREATURE-IDENTITY-2`, a colourway, a rim light and an aura. No behavioural difference is recorded anywhere. Directly related to `HIST-028` and `HIST-116`.
- **owner_reported:** no
- **system_class:** creature attachment (encounter design)
- **likely_still_valid:** yes

## HIST-097 — the HUD's branded half was never built

- **source:** `ralph/BACKLOG.md:3648`
- **original_id:** `EV9`-remainder
- **title:** Orb-count panel, wordmark, gradient bar fills, compass
- **player_visible_problem:** The game has no wordmark anywhere, the `orb_capture` icon has nowhere to live, and bar fills are flat where the owner's style board shows gradient/bevel.
- **date_opened:** before 2026-08-18 · **last_touched:** 2026-08-18
- **status_evidence:** The entry was blocked because `D18` booted straight into the world and there was nothing to mount a wordmark on. The owner approved a title screen 2026-08-18 and one now exists (`smoke_title_load_game` passes), which **unblocks** this rather than closing it. Whether the wordmark, the orb panel or the bar fills were then done is not recorded. The compass half is explicitly not this item's job to invent.
- **owner_reported:** yes (RG25/OP5 lineage; the style board is owner-supplied)
- **system_class:** UI architecture / art
- **likely_still_valid:** unsure — unblocked, with no evidence of being taken.

## HIST-099 — the three polish-phase scopes were never run as passes

- **source:** `ralph/BACKLOG.md:3694`
- **original_id:** `R9.1` / `R9.2` / `R9.3`
- **title:** Input feel and combat cadence; Ally controller UI readability; target-hardware performance
- **player_visible_problem:** The three things a player judges a finished game by on a handheld — how it feels, whether they can read it, and whether it runs.
- **date_opened:** before 2026-08-17 · **last_touched:** 2026-08-17
- **status_evidence:** `ACTIVE_GAME_PLAN.md` names all three as **Gate F children** (prompts 36/37/38), i.e. they are this run's own scope. Substantial parts have been attacked piecemeal (`CONTROLLER-MAP`, `SETTINGS-SCROLL`, HUD legibility rounds, `PERF-ROG`), but no pass has judged any of the three as a whole.
- **owner_reported:** no
- **system_class:** other (umbrella)
- **likely_still_valid:** yes — by the plan's own routing.

## HIST-103 — the Warden's fallback position is 7.7 km from his own room

- **source:** `ralph/BACKLOG.md:3749`
- **original_id:** (unnamed, "Found along the way")
- **title:** `stronghold_climax.json`'s `warden.fallback` is pre-OW5D
- **player_visible_problem:** If the stronghold ever fails to build, the chapter's final fight is staged in an empty field seven kilometres from where it belongs — and a fallback is read exactly when something has already gone wrong.
- **date_opened:** 2026-08-22 · **last_touched:** 2026-08-22
- **status_evidence:** **Confirmed in the working tree at this SHA:** `data/config/stronghold_climax.json` still carries `"fallback": [232.0, -206.0]` (and `[232.0, -222.0]`, `[232.0, -177.0]`), with a `fallback_comment` describing arena boxes at z −227..−169 — all pre-corridor coordinates. `bands/band5.../trainers.json` carries the relocated `[90.2, 7569.4]`. Fallback-only, so it bites solely when the marker path fails.
- **owner_reported:** no
- **system_class:** other (world data robustness)
- **likely_still_valid:** yes — verified in the shipped data.

## HIST-104 — the three Sigil captains do not escalate along the route

- **source:** `ralph/BACKLOG.md:3756`
- **original_id:** (unnamed, "Found along the way")
- **title:** In route order: Riverwatch 16, Field 15, Ridge 16
- **player_visible_problem:** The first of three optional captains a player meets is the joint-hardest, so the sequence does not read as getting harder.
- **date_opened:** 2026-08-22 · **last_touched:** 2026-08-22
- **status_evidence:** Any order opens the Sigil gate, so no order is *wrong*. `GATEC-CURVE` retuned two of the three, so the entry records this as a deliberate leave-alone **pending owner play** — i.e. it is waiting on exactly the kind of run Gate F is.
- **owner_reported:** no
- **system_class:** progression/economy
- **likely_still_valid:** yes — as a pending-play question.

## HIST-105 — the chapter's optional activities are a list, not content

- **source:** `ralph/BACKLOG.md:3763`
- **original_id:** Spec §6
- **title:** Lost Pal, Broken Cart, Night Watch, The Old Champion, Deep Warren, River Nest, Team Tether patrols, Meadowhart Herd
- **player_visible_problem:** The spec asks for 6–10 optional activities rather than forty shallow quests, and names eight; a player looking for something to do off the critical path finds whatever the regional packages happened to build.
- **date_opened:** before 2026-08-17 · **last_touched:** 2026-08-17
- **status_evidence:** The entry's own instruction is to give each a home in a band rather than a list of its own, promoting individually when that band is built. All five bands have since been built (D1–D5). Whether each named activity landed is not tracked anywhere found; Gate F measured 571 points of interest but did not check them against this list.
- **owner_reported:** no
- **system_class:** world density (content)
- **likely_still_valid:** unsure — untracked in either direction.

## HIST-106 — home must stay relevant after the first twenty minutes

- **source:** `ralph/BACKLOG.md:3770`
- **original_id:** Spec §14
- **title:** Grandpa's dialogue per band, beds and recovery, storage and crafting, villagers updating, the rescued NPC returning, story check-ins
- **player_visible_problem:** The farmhouse becomes a room the player never re-enters after the opening.
- **date_opened:** before 2026-08-17 · **last_touched:** 2026-08-17
- **status_evidence:** `R7.6`'s berry farm is recorded as the first answer. Several of the named pieces exist (creature beds, recovery, the rescued captive in D3), but nothing records whether Grandpa's dialogue evolves per band or whether villagers update what they know. A 3–4 hour chapter with a fixed home is exactly what a Gate F run would surface.
- **owner_reported:** no
- **system_class:** world density (content)
- **likely_still_valid:** unsure

## HIST-107 — the visual-bar push, as scheduled work

- **source:** `ralph/ACTIVE_TASKS.md:68` (package P4)
- **original_id:** `P4 — VISUAL-BAR`
- **title:** Ground cover, one daylight colour script, dressing the greybox sites, making the stronghold read as occupied
- **player_visible_problem:** The blind critique answered **NO to both bar questions** (does this read as the key art's world; does it read as the same kind of game as Palworld). The three separating gaps, ranked: emptiness, palette incoherence between regions, and creatures/stronghold not carrying the frame.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-25
- **status_evidence:** Much of the programme ran (`VISUAL-GROUNDCOVER`, `VISUAL-LIGHT`, `CREATURE-IDENTITY-2`, `CREATURE-PRESENTATION`, `STRONGHOLD-R2`, `GATE-E-STRONGHOLD-ART`, `SITE-DRESSING`, `BAND2-FLOOR`, `VIS-MAKE`, `VIS-UI`) and all of it is now on `main`. **What has not happened is a re-judgement:** no blind pass has re-answered the two bar questions since, `VISUAL_LEDGER.md` records no domain converged, and the ground-cover density that P4 raised was subsequently **halved** on the consolidation branch for ROG headroom. Kept as the umbrella; its named parts are `HIST-024`, `HIST-041`, `HIST-060`, `HIST-062`, `HIST-070`, `HIST-144`.
- **owner_reported:** no (the bar itself is the owner's)
- **system_class:** terrain/composition
- **likely_still_valid:** yes — the work moved; the verdict did not.

## HIST-108 — three Gate E children were never separately verified

- **source:** `ralph/ACTIVE_TASKS.md:83` (package P5)
- **original_id:** prompts `46-CREATURE-release-ceremony`, `67-FIVE-creature-pressure-and-bond`, `68-CHAPTER-complete-objective-chain`
- **title:** Release ceremony, five-creature bond pressure, complete objective chain
- **player_visible_problem:** Whether breaking a five-creature bond feels consequential, whether the roster cap creates real pressure, and whether the objective chain holds from first catch to post-win.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** Largely evidenced since by `GATE_F_EVIDENCE_2026-08-23.md`: the finale ran live, the belt was full when the legendary was freed, R4.10's release ceremony took the decision and 'Kettle' was released; 12 distinct species against 5 slots; a 22-entry objective chain unbroken across all three segments and terminating after post-win. What is **not** evidenced is whether the ceremony *reads* as consequential to a player — that is a felt quality, not a log line — nor whether the bond curve (retuned by OP23-FIXPACK for OP23-14) now feels meaningful.
- **owner_reported:** yes in part (OP10 release ceremony; OP23-14 bond curve)
- **system_class:** creature attachment
- **likely_still_valid:** unsure — mechanically demonstrated, experientially unjudged.

## HIST-111 — are the villagers adults or youths?

- **source:** `ralph/BLOCKED.md:37`
- **original_id:** `VIS-CAST` villager proportions
- **title:** 4.9 heads with 36 cm heads on 1.75–1.78 m bodies
- **player_visible_problem:** A blind round read the villagers as *"1.78 m children — child faces and head ratios at adult height"*.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** Measured off an identical-framing cast capture: villager female 1.75 m / 4.87 heads, villager male 1.78 m / 4.98, grandpa 1.72 m / 5.08, trainer (style anchor) 1.80 m / 5.21. An adult is ~7.5 heads. Both fixes are one number and they point in **opposite directions**, so guessing means inventing a fact about who lives in this village — `CLAUDE.md` forbids it. *What would clear it:* the owner saying whether the two villager rigs are adults or youths.
- **owner_reported:** no (awaiting owner)
- **system_class:** art/asset (owner decision)
- **likely_still_valid:** yes

## HIST-112 — Team Tether are built in a different proportion language from everyone else

- **source:** `ralph/BLOCKED.md:37` (the not-blocked half)
- **original_id:** `VIS-CAST` grunt rig proportions
- **title:** The grunt rig is 6.5 heads against the game's 5.2-head style anchor
- **player_visible_problem:** The faction the player fights for a whole chapter is a quarter longer-limbed than every other human in the game.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** Measured on the same cast capture. The cause is recorded and was correct: `NP2-grunt-wire` put three of the four antagonist ranks on the grunt rig, which stopped the rank ladder being the Warden's mesh four times. Explicitly **not blocked** — ordinary art-direction work belonging to the visual sweep, filed in `BLOCKED.md` only because that is where it was found. Also noted: the Warden's own rig could not be measured this way (his fur collar is wider than his neck).
- **owner_reported:** no
- **system_class:** art/asset
- **likely_still_valid:** yes

## HIST-113 — the starter and the tank read as the same kind of animal

- **source:** `ralph/BLOCKED.md:114`
- **original_id:** `VIS-CAST` creature roster 1
- **title:** Two different meshes of the same archetype
- **player_visible_problem:** At the size a creature appears on screen, terrapup and burrowback are both badger-shaped quadrupeds of similar mass, so the starter and the tank read as one animal in two colours.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** The entry **corrects its own briefing**, which had said the two share a mesh: they do not (different files, vertex counts 15,616 vs 17,204, different POSITION accessors; no two of the seventeen species share a mesh). They share a *skeleton template*, which is the rig pipeline working. VIS-CAST's divergence pass (terrapup to warm earth with leaf growth, burrowback to cold grey stone with moss) visibly separates them, so paint was **not** powerless. What paint cannot do is make one silhouette a leafy puppy and the other a plated tank, which is what the owner's board draws. *What would clear it:* an owner decision on whether either is worth new geometry.
- **owner_reported:** no (awaiting owner; the board is owner-supplied)
- **system_class:** creature attachment
- **likely_still_valid:** yes — as an owner decision, at lower priority than originally framed.

## HIST-114 — four species where the owner's board paints a different animal from the mesh

- **source:** `ralph/BLOCKED.md:153`
- **original_id:** `VIS-CAST` creature roster 2
- **title:** Burrowback, brooktail, ripplet, reedwing
- **player_visible_problem:** The board draws burrowback with stacked rock-plate shell armour (the mesh is a badger with a moss strip), brooktail with a signature cyan water-swirl tail (the mesh has a plain flat beaver tail), ripplet as a quadruped axolotl-dragon with fin frills (the mesh is a glossy bipedal chipmunk), and reedwing as an elegant blue crane (the mesh is a domestic duck). Reedwing is the most visible because it is also 1.80 m — eye to eye with the player, which a duck should never be.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** Paint reached the colour in every case and cannot reach the shape in any. The board's own header says *"Same creatures. Better colors, materials, and visual identity. Use existing meshes/rigs/animations"* and *"Keep silhouettes and anatomy the same"* — the entry is explicit that these findings must **not** be read as the owner asking for regeneration. *What would clear it:* a per-species owner decision plus reference art.
- **owner_reported:** no (awaiting owner)
- **system_class:** creature attachment
- **likely_still_valid:** yes

## HIST-116 — thirteen of seventeen species have no alpha treatment at all

- **source:** `ralph/BLOCKED.md:195`
- **original_id:** `VIS-CAST` creature roster 4
- **title:** "Alpha" is a size multiplier and nothing else for most of the roster
- **player_visible_problem:** An alpha of most species is an ordinary creature that is bigger.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** Confirmed by grep and two independent blind rounds. `shiny_colourways.json` now carries `overlays_alpha` for burrowback and galecrest — heavier plates, darker storm tips — named as the pattern to extend. Explicitly **not blocked**: ordinary work, listed in `BLOCKED.md` only so it is not lost. Related to `HIST-028` and `HIST-096`.
- **owner_reported:** no
- **system_class:** creature attachment
- **likely_still_valid:** yes

## HIST-117 — camps have no worn ground under them

- **source:** `ralph/BLOCKED.md:209` (the still-open half)
- **original_id:** trail-camp ground wear
- **title:** A dirt patch or scorch under the fire needs a terrain-path capability no lane may edit
- **player_visible_problem:** A roadside camp reads as objects arranged on untouched lawn rather than as a place people have repeatedly stopped.
- **date_opened:** 2026-08-22 · **last_touched:** 2026-08-22
- **status_evidence:** The tent/bedroll half was **resolved** by an owner correction — sourcing a CC0 asset is permitted where generating is not — and Kenney's Survival Kit 2.0 was vendored with a ledger row. The ground-wear half is explicitly different: not a missing asset but a terrain-path capability living in `terrain_playground.json`, which no Gate-D lane may edit, so it stays with the coordinator. A round-2 attempt to fake it with `RockPath_Round_*` stones was read by the critic as litter and removed. The 2026-08-23 blind critique independently names camps "reading as props-on-lawn (no fire ring/tent/wear/arriving path)".
- **owner_reported:** no
- **system_class:** terrain/composition
- **likely_still_valid:** yes — the tent half landed (`BAND1-D1` rounds 5/6); the wear half has no owner.

## HIST-118 — flat cyan shards in the open field

- **source:** `ralph/BLOCKED.md:273`
- **original_id:** `BAND1-D1 → coordinator`
- **title:** `environment/nature` models carry materials with no albedo texture
- **player_visible_problem:** Bright flat cyan and near-white shapes appear in open meadow, far from any camp, where bushes and small rocks should be.
- **date_opened:** 2026-08-22 · **last_touched:** 2026-08-22
- **status_evidence:** Measured by `tools/_probe_camp_materials.gd`: the `grass` material's albedo is (0.45, 0.93, 0.87) — flat cyan; `dirt` is (0.95, 0.74, 0.62) — near-white; `woodBark` passes by luck. The pack is authored against a palette atlas the glTF import does not apply. D1 solved its own case by moving the camp's scenery to `stylized_nature`, **but the shared scatter layers still use the same pack**, so the shards appear well outside the camp (visible in `shots/trail_camp/02-camp-from-spine.png` and `03-camp-from-road.png`). Filed as *"not a design decision — a defect in a file no lane may edit"* (`vegetation.json` is coordinator-owned). The entry also suggests this is likely the same defect behind a blind critic's *"pale white-stone scatter… reads as litter or snow patches"*.
- **owner_reported:** no
- **system_class:** art/asset
- **likely_still_valid:** unsure — a genuine measured defect, but `vegetation.json` has been rewritten repeatedly since (VISUAL-GROUNDCOVER, SITE-DRESSING, the consolidation density cut) and nobody re-probed.

## HIST-119 — the player-built roof needs modules this kit does not have

- **source:** `ralph/BLOCKED.md:399` and `:442`; reopened `ralph/OWNER_PLAYTEST_2026-08-23.md` OP23-12
- **original_id:** roof kit ceiling / `OP23-12`
- **title:** No mid-run module, no valley piece, no corner closure, no eave course
- **player_visible_problem:** A house the player builds reads as *"three separate tents, not one roof"* — gable faces back to back at every seam, an open trough down the middle of any building deeper than one module, open rectangles at the rear top corners, and tiles terminating flush with the wall so the whole thing reads as a toy block.
- **date_opened:** 2026-08-22 · **last_touched:** 2026-08-23
- **status_evidence:** Three separate blind critics, each judging fresh frames with no knowledge of what changed and no sight of the previous critiques, **independently ranked the roof first of all defects** and called the building "not something a player would be pleased to have built." Cap suppression was verified impossible against raw vertex data (two primitives, each spanning the full local-X range). The owner ruled 2026-08-22 that *"the roof doesn't need a continuous edge, it just needs to look like the buildings in the game"*, which unblocked the ridge question — and then reported OP23-12, *"player-built roofs don't plane in the right spots"*, on 2026-08-23. One cheap thing is named as unruled-out first: round 3's critic reported a bright slot running the **full length** of the wall-top line, which if it is a seat/offset bug is fixable in data and is the single largest contributor.
- **owner_reported:** yes (OP21-09, then OP23-12)
- **system_class:** art/asset (build kit)
- **likely_still_valid:** yes

## HIST-121 — no tree in the pack reaches the key art's landmark oak

- **source:** `ralph/BLOCKED.md:984`
- **original_id:** `EV2-landmark-ceiling`
- **title:** `CherryBlossom_3` is the pack's ceiling, confirmed by render
- **player_visible_problem:** The key art's hero trees are broad, flat-topped, multi-lobed, forking oaks 15–20 m tall. What stands in the world is 1.5:1 wide with a leaning but unforked trunk, at orchard scale.
- **date_opened:** 2026-08-14 · **last_touched:** 2026-08-14
- **status_evidence:** Measured across the full 270-file Stylized Nature MegaKit: `CherryBlossom_3` (16.59w × 14.49h) is the **only** form genuinely wider than tall. A real config bug that kept it rendering native pink was found and fixed; a fresh blind close-up confirmed the fix and still answered *"not yet"* to the item's own question. Two paths, neither a firing's call: accept it, or name landmark-oak geometry as content the pack does not have — the latter requiring an explicit owner exception to the no-new-Meadows-meshes rule. The 2026-08-23 blind critique independently reports "trees at orchard scale (6–9 m) where the keyart draws 15–20 m landmarks", so the gap is still being seen.
- **owner_reported:** no (owner purchase/exception decision)
- **system_class:** art/asset
- **likely_still_valid:** yes

## HIST-122 — a dark band across the Band 3 checkpoint view

- **source:** `ralph/GATE_D_REMAINDERS.md:18`; also `ralph/ACTIVE_TASKS.md:101`
- **original_id:** D3 checkpoint rendering artefact
- **title:** Positional, not a height effect; two explanations tested and both wrong
- **player_visible_problem:** From one spot on the Band 3 route, a hard-edged dark band lies across the view with terrain ending in mid-air at the seam and props inside it at full brightness.
- **date_opened:** 2026-08-22 · **last_touched:** 2026-08-23
- **status_evidence:** Measured, not impressioned: constant RGB within three levels across 700 px, a dead-straight horizon-parallel top edge. **Not the camera underground** (the raycast returns the analytic height unchanged at this viewpoint; the eye is identical before and after; the fix that came out of testing it was kept anyway). **Not water** (global level −17.0, river −9.0, eye −2). The same 1.7 m eye 19 m further back renders clean. D3 raised that frame's eye to 3.0 m so the checkpoint stays judgeable — *"so a later reader will see a workaround, not a fix."* Owner: terrain/rendering; nothing in a band's config can cause or fix it.
- **owner_reported:** no
- **system_class:** terrain/composition (rendering)
- **likely_still_valid:** yes — never explained.

## HIST-125 — D5's bar question A is still "no", on the lane's own say-so

- **source:** `ralph/GATE_D_REMAINDERS.md:124`
- **original_id:** Gate D remainder 4
- **title:** The lane assessing its own ceiling
- **player_visible_problem:** The final approach to the stronghold does not read as belonging to the key art's world.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** D5's round-2 blind critic answered A **no** (unchanged), B **yes** (was no). D5's position is that every remaining defect needs a file, system or asset outside D5 — the stronghold's own art (the critic's #1, explicitly "needs art not in the build"), storm slabs, ground scatter density, night ambient and moonlight, tree shading, clouds. The remainders file itself flags the structural problem: *"That is plausible and it is also the lane assessing its own ceiling. It should be confirmed by the full-corridor pass rather than accepted on the lane's say-so."* `GATE-E-STRONGHOLD-ART` and `STRONGHOLD-R2` have since landed real masonry and a road, unjudged (`HIST-037`).
- **owner_reported:** no
- **system_class:** terrain/composition
- **likely_still_valid:** yes — the confirmation it asks for has not happened.

## HIST-126 — D4's round-4 leftovers

- **source:** `ralph/GATE_D_REMAINDERS.md:136`
- **original_id:** Gate D remainder 5
- **title:** Ambient light and exposure, a cloudless sky, distant-LOD instances rendering white, storm wall viewing angles
- **player_visible_problem:** In the Upper Meadows the light and exposure read wrong, the sky has no clouds, distant vegetation renders as white blobs, and the storm wall is visible from angles it was never authored for.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** Named by D4's critic and not band content, so not fixed in-lane. The **storm wall** half was subsequently root-caused and fixed by `GATE-E-STRONGHOLD-ART` (`rift_collapse.gd`'s `StormWall_0/1/2`, fixed with a `visible_within_metres` viewing band). The remainders file gives the **distant-LOD-white** one the item-2 treatment — reproduce through a second path first, because it has the shape of a capture artefact. Fourth member of the unreconciled white-artefact family (`HIST-039`, `HIST-071`, `HIST-093`).
- **owner_reported:** no
- **system_class:** terrain/composition
- **likely_still_valid:** unsure — one of four parts is closed; the rest were never re-checked.

## HIST-127 — the bark retint, deliberately not changed

- **source:** `ralph/GATE_D_REMAINDERS.md:169`
- **original_id:** Gate D remainder 7
- **title:** Bone-grey twisted-oak trunks, deferred to the full-corridor visual pass
- **player_visible_problem:** Twisted-oak trunks read bone-grey rather than as bark.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** D4 correctly identified `vegetation.json`'s **top-level** `Bark_TwistedTree` retint (`#918178`), which no band file can reach. **Not changed on purpose:** `_comment_retint_bark_ev2` records that value as solved from a measured per-channel gain against a target of ~RGB(95,82,72), chosen so bark survives the cool ambient that the ground-legibility fix depends on. Changing it moves every twisted oak in the chapter on the evidence of one blind critique of one ironwood stand. Explicitly deferred to *"the full-corridor visual pass, where it can be judged against the chapter"* — which is this run.
- **owner_reported:** no
- **system_class:** art/asset
- **likely_still_valid:** yes — as a deferred judgement, correctly parked.

## HIST-128 — wild creatures are sited without checking the routes they block

- **source:** `ralph/GATE_D_REMAINDERS.md:180` (§8)
- **original_id:** (unnamed; the `STRANDED-P3` spawn-siting class)
- **title:** "Two for two — a third may exist unfound"
- **player_visible_problem:** A wild creature standing on a bridge or across a path can physically block the player, which on the chapter's only river crossing is a softlock risk, not a test flake.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** Two instances found and fixed **in the spawn table, not the test**: band 3 order 3037 (a 4-galecrest cluster whose 18 m disc reached past the Old Mill Crossing's centreline before wander was even added — caught by `tools/_probe_mill_stall.gd` naming `Wild_galecrest_3037_1` as the collider) and band 1 order 1006 (a bramblebun cluster reaching to z=49.4 across `smoke_traversal`'s own walk line). Both were sited by 2026-08-22 density passes whose own text says every cluster was kept 20 m+ clear of trainer arenas and other clusters — *"the same rule, just never applied to this one crossing."* The file's own conclusion: *"a third may exist unfound. `smoke_traversal.gd`'s four-direction walk and both crossing walks are the only routes verified clear so far."*
- **owner_reported:** no
- **system_class:** terrain/composition (collision) / world density
- **likely_still_valid:** yes — the two known instances are fixed; the class is explicitly open and unswept.

## HIST-130 — the village layout does not read as a place

- **source:** `ralph/ASSESSMENT_2026-08-23.md:51`; `ralph/OWNER_PLAYTEST_2026-08-21.md` OP21-17; `ralph/OWNER_PLAYTEST_2026-08-23.md` OP23-08
- **original_id:** `OP21-17` / `OP23-08`
- **title:** Reported by the owner twice; the assessment's only OP21 row still marked OPEN alongside the chop swing
- **player_visible_problem:** The opening village's roads, building fronts, paths, signs and gathering spaces do not have understandable spatial logic; and Grandpa's house sits outside the town centre but not far enough to read as deliberate — *"placeless"*.
- **date_opened:** 2026-08-21 · **last_touched:** 2026-08-23
- **status_evidence:** `ASSESSMENT_2026-08-23.md` records OP21-17 as **OPEN — "no reshape landed; visual-judge scope."** OP23-08 is the owner's second report, explicitly extending it. Adjacent work landed since (`SITE-DRESSING`, signposts offset off the road for OP21-18, the village road gate seal), none of which reshapes the settlement. This is a Gate A readability blocker in the very first area a player sees.
- **owner_reported:** yes (twice)
- **system_class:** terrain/composition
- **likely_still_valid:** yes

## HIST-131 — party cycling presentation was fixed in code and never looked at

- **source:** `ralph/ASSESSMENT_2026-08-23.md:46`
- **original_id:** `OP21-12`
- **title:** LIKELY FIXED — "code landed (`d066c39b`, `02d7e109`); needs visual confirm"
- **player_visible_problem:** The owner could not tell what was happening when cycling active companions; the UI *"looked strange"* and resembled broken menu state.
- **date_opened:** 2026-08-21 · **last_touched:** 2026-08-23
- **status_evidence:** The assessment's own verdict is conditional. Complicating it: `VIS-UI-r1` (`HIST-011`) records that `08-party-strip` **renders an empty frame** in the capture tool, so the one surface that would confirm this could not be photographed. Owner directive 2026-08-22 §1 also merged "cycle party" and "switch the creature you are piloting" onto one button (LB), which changes what the presentation has to communicate.
- **owner_reported:** yes (OP21-12)
- **system_class:** UI architecture
- **likely_still_valid:** unsure — the named confirmation has never been possible.

## HIST-132 — the pond-to-village route has no regression lock

- **source:** `ralph/ASSESSMENT_2026-08-23.md:60`
- **original_id:** `OP21-26`
- **title:** LIKELY FIXED — 1600 m gap → 84 m, 56 wild clusters, "no CI regression lock"
- **player_visible_problem:** The owner reported the pond-to-village stretch as empty traversal. It was filled, and nothing prevents it emptying again.
- **date_opened:** 2026-08-21 · **last_touched:** 2026-08-23
- **status_evidence:** The fill is real and measured (longest gap 84 m; Gate F later measured the whole corridor's worst gap at 165 m in band 2, with zero intervals of 250 m+). The gap is the **guard**: no test asserts the route's density, so a future siting change can silently undo it. Same shape as `HIST-043` (memory) — a missing budget assertion rather than a defect.
- **owner_reported:** yes (OP21-26)
- **system_class:** world density
- **likely_still_valid:** yes — as a missing guardrail.

## HIST-134 — the projected first completion is 2% over the four-hour ceiling

- **source:** `ralph/GATE_F_EVIDENCE_2026-08-23.md` §3; `ralph/ACTIVE_GAME_PLAN.md` §6 condition 13
- **original_id:** Gate F condition 13 / `D42`
- **title:** Floor 2.04 h, projection 4.08 h against a 3–4 h target
- **player_visible_problem:** The chapter may run slightly long for a focused first clear.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** Measured after fixing a real probe defect that had charged the chapter a 13,934 m phantom detour (`_probe_pacing.py` kept the last-matching Meadowhart cluster in the merged spawn table rather than the nearest; fix took the saddle detour to 1,343 m and the floor from 2.53 h to 2.04 h). Forced grinding is 0.07 h across six fights. The entry is explicit that this **is not a measured playthrough** — it sits on a ×2.0 first-timer multiplier that nothing in the repo derives — and refuses to tune it away, *"because tuning the chapter to beat a projection multiplier would be fitting the game to the instrument."* A real Gate F playtest is exactly what would replace it.
- **owner_reported:** no
- **system_class:** progression/economy (pacing)
- **likely_still_valid:** yes — as an open modelled number awaiting a real measurement.

## HIST-135 — the day/night fix has never been looked at

- **source:** `ralph/DONE.md:348` (`VISUAL-LIGHT`, "WIND-DOWN, partially verified"); `ralph/OWNER_PLAYTEST_2026-08-23.md` OP23-05/06
- **original_id:** `OP23-05` / `OP23-06`
- **title:** Landed, unit-tested, and never rendered
- **player_visible_problem:** The owner reported day flashing straight to night, and night too dark immediately after nightfall. A fix landed. Nobody has confirmed the transition reads as progressive darkening or that a player can see the ground at night.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** The `DONE.md` entry is unusually candid: the capture tool (`tools/_capture_day_night_transition.gd`) was written and committed, launched, and **killed mid-render on the wind-down order before producing a single frame** — *"no visual confirmation… and no confirmation of a navigable night floor, exist yet."* It also names the exact commands and the exact acceptance (`near_luma` decreasing monotonically-ish with no jump at 17.9→18.1 or 23.9→0.1; night-floor frames at 20.5/22.0/0.1/2.0 above a see-the-ground floor). The full suite was **not** re-run that session; `test_world_weather.gd`, which the task's own brief required to stay green, was read and reasoned about but not executed after the change.
- **owner_reported:** yes (OP23-05, OP23-06)
- **system_class:** terrain/composition (world clock)
- **likely_still_valid:** yes — the verification is genuinely absent.

## HIST-136 — the HUD takes up far too much screen

- **source:** `ralph/OWNER_PLAYTEST_2026-08-23.md` OP23-09
- **original_id:** `OP23-09`
- **title:** No entry anywhere records this being taken
- **player_visible_problem:** On a seven-inch handheld the interface eats the game.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** Nothing in `DONE.md` addresses OP23-09 (grepped by ID; the only hits are other items citing it as a constraint). It is load-bearing for at least one other item: `OBJECTIVE-HINT-ON-HUD` (`HIST-036`) is explicitly sequenced **after** OP23-09 re-proportions that corner, because the hint would take the objective block from 170 px to nearly 300. Tension worth naming: several blind-judge findings (`HIST-051`) push toward *more* contrast and padding, which usually means more area.
- **owner_reported:** yes
- **system_class:** UI architecture
- **likely_still_valid:** yes

## HIST-138 — there is no body in the bed at the opening wake-up

- **source:** `ralph/OWNER_PLAYTEST_2026-08-23.md` OP23-11
- **original_id:** `OP23-11`
- **title:** The chapter's first frame
- **player_visible_problem:** The game opens on the player waking up and the bed is empty — the player is not in it.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** No entry found anywhere that addresses it. Adjacent: `SITE-SHOTS`' third pass re-verified `opening-bedroom.jpg` and found the loft already has a real `BedTwin` and nightstand, i.e. the room is dressed — which makes this specifically about the player's own body at the wake beat, not about the room.
- **owner_reported:** yes
- **system_class:** other (opening presentation)
- **likely_still_valid:** yes

## HIST-140 — the map does not show all authored trails

- **source:** `ralph/OWNER_PLAYTEST_2026-08-18.md` OP15; prompt `52-MAP-all-authored-trails-visible.md`
- **original_id:** `OP15`
- **title:** The fresh remaining defect after movement-up was verified working
- **player_visible_problem:** Routes the player can visibly follow on the ground are missing from the map, so the map cannot be used to plan a route.
- **date_opened:** 2026-08-18 · **last_touched:** 2026-08-18
- **status_evidence:** Same item as `HIST-079`'s remaining half; kept as a separate row because OP15 is the owner's own narrowing of RG15 and carries its own prompt. Note the map has since been rebuilt twice (`MAP-EXTENT`; OP23-03's reveal work), neither of which is about trail representation in the bake.
- **owner_reported:** yes
- **system_class:** navigation/objectives
- **likely_still_valid:** unsure — see `HIST-079`.

## HIST-141 — does the tutorial teach the player to feed the team?

- **source:** `ralph/OWNER_DIRECTIVES_2026-08-23.md` §2
- **original_id:** owner directive 2026-08-23 §2
- **title:** Keep the satiety drain rate; teach it
- **player_visible_problem:** The ~1.1/min satiety drain stays, so arriving at the tournament hungry must read as a care ritual the player was taught, not as a trap they walked into.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** The directive asks for an explicit "feed your team" step in the guided chain before tournament sign-up. `GATEB-COORD` records *"the tail feeds the entrants before sign-up and now after every night"* — which is the harness doing it, not necessarily the chain teaching it. `TUTORIAL-CHAIN`'s own `DONE.md` entry is about the guided one-step-at-a-time chain; whether a feed rung exists in it is not stated in anything found.
- **owner_reported:** yes (owner directive)
- **system_class:** progression/economy (creature care)
- **likely_still_valid:** unsure

## HIST-144 — no visual domain has converged

- **source:** `ralph/VISUAL_LEDGER.md:45`
- **original_id:** (the ledger's domain table, D1–D8)
- **title:** Eight domains, every one judged at least once, every round naming new defects
- **player_visible_problem:** Regions, HUD and menus, creatures, characters, buildings, items, ground/terrain/water/weather, and combat presentation have each been judged blind and none has reached the point where a critic runs out of things to name.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** The ledger's own table: D1 regions 2 rounds (A no·no / B yes-narrow·yes-"trying"), D2 HUD+menus 1 round (no/no), D3 creatures 3 rounds (A yes-narrow·no·no / B no·no·yes-"trying"), D4 characters 2 rounds (no/no both), D5 buildings 1 round (no/no), D6 items 1 round (no/no), D7 ground/terrain/water/weather 1 round (no/no), D8 combat 1 round (no/no). Under `conventions.md` a round that names new defects is a round that improved, so **none is near its stopping rule** — this is the state, not a failure. This entry is the umbrella over `HIST-002`–`HIST-024`, `HIST-026`–`HIST-028`, `HIST-038`, `HIST-051`–`HIST-056`, `HIST-060`, `HIST-062`, `HIST-064`, `HIST-070`, `HIST-107`, `HIST-111`–`HIST-116`, `HIST-125`–`HIST-127`.
- **owner_reported:** no (the mandate is an owner directive: *"The whole game relies on all of this looking great. This is the most important ongoing task."*)
- **system_class:** terrain/composition (process umbrella)
- **likely_still_valid:** yes

## HIST-145 — the village road gate has no authored flanking

- **source:** `ralph/HANDOVER_CONSOLIDATION_2026-08-25.md:44`
- **original_id:** SIGIL-SEAL fallout / village road gate
- **title:** A programmatic fence, or a gate that does not gate
- **player_visible_problem:** The owner ruled 2026-08-25 that *"gates have to be physically sealed — there needs to actually be something keeping a player from walking around it."* The village road gate stands in open meadow with nothing to terminate a fence against, so either it fences in its own key or a sliding player walks round it.
- **date_opened:** 2026-08-25 · **last_touched:** 2026-08-25
- **status_evidence:** The blocker itself was resolved for CI by moving `GATE_KEY_AT` off the seal's fence line (`b6fdbd32`, computed via `tools/_probe_key_site.gd`), and the branch landed green. What the handover says is still owed is the **content** answer: fence running to `cottage_b` (21,−14) on one side and to `village.json`'s existing `fence_run` at (19.5,−25.5) on the other — which `road_gate.gd`'s own header has always claimed is there and is not. *"That is content work needing eyes on it; picking another constant is how the fence ended up around the key."* The Sigil Gate is a different case and is correct (its 16.0 m wings terminate in flanking gorges).
- **owner_reported:** yes (owner ruling 2026-08-25)
- **system_class:** navigation/objectives (world gating)
- **likely_still_valid:** unsure — the immediate defect is fixed; whether the gate now reads as sealed to a player is unmeasured.

## HIST-075 — you lose camera control during a creature fight

- **source:** `ralph/BACKLOG.md:2167`
- **original_id:** `RG8`
- **title:** Combat is the centrepiece and you cannot look around in it
- **player_visible_problem:** A fight starts and the camera stops answering the right stick.
- **date_opened:** 2026-08-18 · **last_touched:** 2026-08-23
- **status_evidence:** Reported three times (RG8, OP21-05, OP23-02) and closed twice. `ASSESSMENT_2026-08-23.md` records OP21-05 FIXED with `smoke_trainer_battle_camera` PASS on the real Mira path; OP23-02 reopened it for the *stronghold/gauntlet* path, which OP23-FIXPACK then root-caused to two independent bugs (`stronghold.gd`/`burrow_warrens.gd`'s Interior `Area3D` handing the camera back unconditionally on `body_entered`/`exited`, racing `combat_manager`'s hand-off; and `sequence_director.gd`'s per-frame lockout leaving the camera rig disabled for a whole fight when dialogue closes and the battle opens on the same frame — the production path every non-Mira trainer uses) and closed with `smoke_stronghold_battle_camera.gd`. The `RG8` entry in `BACKLOG.md` was never marked.
- **owner_reported:** yes (RG8, OP21-05, OP23-02)
- **system_class:** combat/camera
- **likely_still_valid:** no — closed twice with named root causes and new coverage; carried only because a symptom that returns twice in this repo has usually meant the mechanism was never fixed, and this one has now returned twice.

## HIST-080 — the player has no idea which way to go

- **source:** `ralph/BACKLOG.md:2245`
- **original_id:** `RG16`
- **title:** An objective the player can hold in their head, spoken by an NPC, reflected on the map
- **player_visible_problem:** *"I have no idea if I'm going the right way."*
- **date_opened:** 2026-08-18 · **last_touched:** 2026-08-23
- **status_evidence:** Largely answered since: `TUTORIAL-CHAIN` shipped OP23-04's guided one-step-at-a-time chain, `objectives.json` carries a 22-entry main chain Gate F measured as unbroken and terminating, and OP23-03's map reveal now shows the village and its roads. What is **not** answered is the map half of RG16's own sentence — being told a direction and confirming it on the map — which is `HIST-050` (landmarks through fog) and `HIST-140` (authored trails), both open.
- **owner_reported:** yes (RG16)
- **system_class:** navigation/objectives
- **likely_still_valid:** no — as written; its two surviving halves are carried separately.

---

# Section 2 — unresolved, NOT player-facing

Tooling, CI, test integrity, process and bookkeeping. **These are excluded from
§16.5's denominator**, which is stated as *"genuinely valid/current historical
player-facing issues"*. They are listed, not deleted, because several of them are
the reason a player-facing item is unverifiable — a capture tool that cannot
photograph a widget is why `HIST-131` has never been confirmed — and because
retiring them silently would be the same bookkeeping failure the protocol exists
to correct.

## HIST-003 — the structures survey stage is a blank plane under a flat sky
- **source:** `ralph/BACKLOG.md:115` · **original_id:** `VIS-MAKE-remainder`
- **player_visible_problem:** none directly — this is the capture stage, not the world. It blocks judging 56 building frames: the blind critic's own words were *"a grounded terrain material, a real sky, and killing the black horizon band — this alone changes all 56 frames."* `translated: yes`
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** Named as the cheapest large win in D5; tool is `tools/_capture_structures.gd`. No closing evidence.
- **owner_reported:** no · **system_class:** tooling/CI · **likely_still_valid:** yes

## HIST-005 — two structure close-shots fail their own brief
- **source:** `ralph/BACKLOG.md:125` · **original_id:** `VIS-MAKE-remainder`
- **player_visible_problem:** none — `22-door-close` crops the 1.80 m scale ruler to a sliver and `11-castle-close` is a featureless plane, so about a fifth of the reframed close shots document nothing. `translated: yes`
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** No closing evidence. · **owner_reported:** no · **system_class:** tooling/CI · **likely_still_valid:** yes

## HIST-011 — the party strip cannot be photographed
- **source:** `ralph/BACKLOG.md:175` · **original_id:** `VIS-UI-r1`
- **player_visible_problem:** none — `08-party-strip` renders an empty frame, so the party strip has never been judged. This is why `HIST-131` (OP21-12, party cycling presentation) has no visual confirmation. `translated: yes`
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** **Root cause found, fix not applied:** `party_strip.gd::_ready()` captures `_rest_position = position` at mount, and every later `_reveal()` (which `set_pinned(true)` calls) snaps `position` back to it, so the capture tool's own assignment lasts until the strip reveals. The tool must call `set_rest_position()` instead. An earlier commit on the same branch blamed `Control.scale` pivot maths — **that diagnosis is recorded as wrong; do not re-derive from it.**
- **owner_reported:** no · **system_class:** tooling/CI · **likely_still_valid:** yes

## HIST-012 — the widget close-up backdrop hides half of what the widget draws
- **source:** `ralph/BACKLOG.md:182` · **original_id:** `VIS-UI-r2`
- **player_visible_problem:** none — `09-stamina-arc` reads as a bracket rather than a meter because the capture backdrop is near-black (0.08) and the arc's unfilled track is a dark neutral designed to sit over the lit world. The instrument is fine; the stage is wrong. `translated: yes`
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** Fix named (lift the two widget-closeup backdrops to a mid value). No closing evidence.
- **owner_reported:** no · **system_class:** tooling/CI · **likely_still_valid:** yes

## HIST-025 — the contact-sheet harness makes whole-set comparison harder than it should be
- **source:** `ralph/BACKLOG.md:265` · **original_id:** `VIS-UI-remainder` harness notes
- **player_visible_problem:** none. `tools/contact_sheet.gd` lays 23 frames into a grid with entire empty rows between them, which is exactly what the visual-judge skill asks not to happen; frames 05/06/07 are near-identical camera duplicates spending three slots on one screen; and the survey runs ~26 minutes, with a recorded discipline that three renders were discarded because code landed after the shutter. `translated: yes`
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** No closing evidence. The re-render discipline is the useful half: *"judging a stale set corrupts the convergence measurement."*
- **owner_reported:** no · **system_class:** tooling/CI · **likely_still_valid:** yes

## HIST-033 — Oskar's village-visit segment is a real reproducible flake
- **source:** `ralph/BACKLOG.md:429` · **original_id:** `GATEB-FINDINGS` 5
- **player_visible_problem:** none directly — but the shape (the player stranded outside an NPC's prompt radius so the EncounterDirector fallback wins by being the only offer) has twice turned out to be a real reachability problem rather than a harness one. `translated: yes`
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** `_visit_villager("Oskar", ...)` intermittently fails *"could not activate Oskar cycle 1 (29.3m away, arbiter winner=EncounterDirector)"*. Confirmed **not branch-specific**: reproduced identically on an unmodified call order and on `TUTORIAL-CHAIN`'s reordered visit, once at Oskar and once at the Quarry Foreman in back-to-back runs. `_one_approach()`'s sidestep-retry budget (10 pushes, 3 attempts) is not enough at Oskar's stand-off distance. Gate B has since passed continuously twice (`GATEB-COORD`), which does not disprove an intermittent.
- **owner_reported:** no · **system_class:** tooling/CI · **likely_still_valid:** unsure

## HIST-034 — 31 smoke tests exist that no CI job runs
- **source:** `ralph/BACKLOG.md:480` · **original_id:** `CI-COVERAGE-1`
- **player_visible_problem:** none directly; it is why a regression in any of those thirty-one paths would ship silently. `translated: yes`
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** Six named from `a9215a1b`'s superseded CI-wiring commit (`smoke_title_new_game`, `smoke_save_persistence`, `smoke_gate_a_build_segment_meadows`, `smoke_gate_a_map_cycle`, `smoke_no_double_prompt`, `smoke_collision_streaming`) plus 25 more found by sweeping `tests/smoke_*.gd` against `ci.yml`. Deliberately not wired in that pass, with a stated reason: *"a red job added blind is worse than an unwired test — it wedges every branch behind a check nobody has seen pass."*
- **owner_reported:** no · **system_class:** tooling/CI · **likely_still_valid:** unsure — CI has been restructured twice since (six unit shards, new verb/region/owner-regression/gate-evidence/combat shards); nobody re-swept.

## HIST-037 — the stronghold's blind critique has still never run
- **source:** `ralph/BACKLOG.md:569` and `:763` · **original_id:** `STRONGHOLD-BLIND-PASS`
- **player_visible_problem:** none directly. It is why the biggest structure in the game is "improved and unjudged". `translated: yes`
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** Called *"the blocking one, and it is infrastructure, not art."* Two consecutive lanes could not spawn a critic — `create_session` returned "the service is temporarily unavailable" on every attempt, round 2 across six tries in a whole session. Invoking the `visual-judge` skill inline is explicitly **not** a substitute, because it loads into a context that already knows what changed. Everything a critic needs is staged: run `tools/capture_stronghold_approach.gd`, judge `shots/wayfinding_full/` (not `shots/wayfinding/` — `capture_castle_lite.gd` skips vegetation, so a critic would correctly rank "the field is empty" while describing the capture), sheet them, and push the PNGs to a scratch branch since `shots/` is gitignored. `STRONGHOLD-MAT` separately records the same debt: *"the blind visual-judge pass could not be spawned during that lane — the frames are improved and unjudged."*
- **owner_reported:** no · **system_class:** tooling/CI (process) · **likely_still_valid:** yes

## HIST-040 — `STRONGHOLD-R2-remainder` is duplicated verbatim in the backlog
- **source:** `ralph/BACKLOG.md:564` and `ralph/BACKLOG.md:758`
- **player_visible_problem:** none. Two byte-similar copies of the same three-item section exist ~190 lines apart, so a lane closing one leaves the other reading open — the exact failure mode `CLAUDE.md` warns about. `translated: yes`
- **date_opened:** 2026-08-23 (duplication introduced) · **last_touched:** 2026-08-23
- **status_evidence:** Found by this sweep; not recorded anywhere. Affects `HIST-037`, `HIST-038`, `HIST-039`.
- **owner_reported:** no · **system_class:** other (doc hygiene) · **likely_still_valid:** yes

## HIST-047 — the progression curve doc plans against a corridor that no longer exists
- **source:** `ralph/BACKLOG.md:744`; `ralph/GATE_F_EVIDENCE_2026-08-23.md` §4 · **original_id:** `CURVE-DOC-STALE`
- **player_visible_problem:** none yet — but the doc is stale **in the project's favour**, which is the dangerous direction: a future lane reading it would plan to build content that already exists. `translated: yes`
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** `docs/MEADOWS_PROGRESSION_CURVE.md` §6 still says *"Band 3 and Band 5 have zero wild spawns; Band 4 has one Meadowhart cluster… Half the corridor has no creatures in it"* and *"Band 2 has no trainers at all"*. Measured by walking the corridor 2026-08-23: band 3 has 91 wilds and 5 trainers, band 4 has 184 and 2, band 5 has 48 and 3, band 2 has 2 trainers.
- **owner_reported:** no · **system_class:** other (doc hygiene) · **likely_still_valid:** yes

## HIST-057 — a rest function nothing calls, asserted by two test suites
- **source:** `ralph/BACKLOG.md:1158` · **original_id:** `DEAD-REST`
- **player_visible_problem:** none today. The risk is inverted coverage: `smoke_stronghold.gd:254` calls `HOME_RECOVERY.rest()` directly to simulate the stronghold's recovery, **so it would keep passing if the real bed recovery broke.** `translated: yes`
- **date_opened:** 2026-08-22 · **last_touched:** 2026-08-22
- **status_evidence:** `scripts/creatures/home_recovery.gd::rest()` is preloaded once (`creature_bed_panel.gd:25`) and invoked never across `scripts/` and `autoload/`; its only callers are `tests/test_fainting.gd` (8 sites) and `smoke_stronghold.gd`. The live path is `game_state.gd::_tick_creature_bed_recovery()` (gradual, per `progression.json`'s `creature_bed.full_heal_seconds`) plus `complete_creature_bed_rests()` overnight. `conventions.md`'s own rule — *"a test that passes because the feature is absent is worse than no test"* — covers this from the other side. The work is a decision: delete and retarget eight test sites, or give it a real caller.
- **owner_reported:** no · **system_class:** tooling/CI (test integrity) · **likely_still_valid:** yes

## HIST-058 — `verify-continuous-core-known-red` is red by design and still red
- **source:** `ralph/BACKLOG.md:1195`; `.github/workflows/ci.yml:1761-1793` · **original_id:** `CONTINUOUS-CORE`
- **player_visible_problem:** none directly. It is one of two evidence paths through the opening, and the one CI reports on every run without blocking. `translated: yes`
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-25
- **status_evidence:** **Confirmed present at this SHA:** `ci.yml` still carries `continue-on-error: true` on the job, with its own comment saying the flag is deliberate and temporary and *"Remove `continue-on-error` the moment CONTINUOUS-CORE is fixed."* This is **not** the same path as Gate B's continuous run, which now passes (`GATEB-COORD`, two consecutive fresh-save walks of all ten objectives) — this is `smoke_gate_a_opening_segment.gd --gate-a-continuous-core`, which no CI shard has ever passed. The 08-25 handover warns explicitly that this job's red *is not a verdict* and cost that session hours of misreading. The entry's own closing line is worth preserving: *"`ralph/DONE.md` described this path as working. It has never run."*
- **owner_reported:** no · **system_class:** tooling/CI · **likely_still_valid:** yes

## HIST-059 — the ground-cover change was never rendered
- **source:** `ralph/BACKLOG.md:1494` · **original_id:** `VISUAL-GROUNDCOVER-remainder`
- **player_visible_problem:** none directly — it is a `conventions.md` violation carried knowingly: a chapter-wide density raise, a flower/bush rescale and two landmark-scaled hero trees shipped verified against four scatter/veg tests only. *"The rendered result has never been looked at"*, by a human or a critic. `translated: yes`
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-25
- **status_evidence:** Three `tools/survey.sh` attempts were OOM-killed (a 14.3 GB session memory-cgroup ceiling, confirmed via `dmesg`) or hit a one-frame renderer flake, under 15–35 one-minute load from five-plus sibling lanes. The remainder names exactly what is owed, including `tools/_capture_band4_sites.gd`'s `ironwood-grove` shot for the two rescaled hero trees. **Complicated since:** the consolidation branch halved the same carpet layers again, so any render now judges a different number.
- **owner_reported:** no · **system_class:** tooling/CI (process) · **likely_still_valid:** yes

## HIST-063 — the spokes capture tool photographs empty meadow and reports success
- **source:** `ralph/BACKLOG.md:1590` · **original_id:** `SPOKE-VIEWS`
- **player_visible_problem:** none. `tools/capture_severed_spokes.gd`'s seven viewpoints are pre-`OW5B`/`OW5D` and put the eye ~700 m from where those roads now are (`stone_gate`'s eye at `[-164, -1.3]`; the sealed gate at `[-688.9, 2517.9]`). *"Nothing is wrong with the spokes themselves — shot from the right place they read exactly as intended."* `translated: yes`
- **date_opened:** 2026-08-22 · **last_touched:** 2026-08-22
- **status_evidence:** The live numbers are in `terrain_playground.json`'s `spokes.routes` and `tools/capture_site_story.gd` already reads them; the spokes tool holds a second copy. A tool that renders open grass and reports success is the most dangerous shape of test in this repo.
- **owner_reported:** no · **system_class:** tooling/CI · **likely_still_valid:** yes

## HIST-065 — the story page's last two capture gaps
- **source:** `ralph/BACKLOG.md:1610`; `ralph/ACTIVE_TASKS.md:99` · **original_id:** `SITE-SHOTS`
- **player_visible_problem:** none — this is the website, not the game.
- **date_opened:** 2026-08-22 · **last_touched:** 2026-08-23
- **status_evidence:** Mostly closed: the third pass landed all four wanted captures and `site/README.md` now carries the per-frame detail. Two residuals. (1) **Meadows Hall approach (`.s-hall`) stays gated** and the reason changed — `STRONGHOLD-MAT` landed so the masonry is real, but a fresh capture from the approach shows several large translucent quads behind the hall; `SKY-PLANES`' root cause was fixed with a viewing band, and the entry warns not to re-wire this figure on the strength of the root-cause location alone without re-rendering the approach. (2) `tools/capture_site_shots.gd`'s `village-square` viewpoint puts the camera inside a roof and is **deliberately left broken and commented**; `capture_site_story.gd`'s own viewpoint is the one that works. `ACTIVE_TASKS.md`'s "3 remaining frames; stale CSS comment" is stale — the third pass reconciled the CSS comment against the real committed image.
- **owner_reported:** yes originally (OP21-22) · **system_class:** tooling/CI (website) · **likely_still_valid:** unsure — mostly closed; the `.s-hall` gate is real.

## HIST-069 — `STRONGHOLD-MAT` still owes its blind pass
- **source:** `ralph/BACKLOG.md:1946` · **original_id:** `STRONGHOLD-MAT` remainder
- **player_visible_problem:** none directly; same debt as `HIST-037` from a different lane. `translated: yes`
- **date_opened:** 2026-08-18 · **last_touched:** 2026-08-23
- **status_evidence:** The original diagnosis (a `D63` shared-model material drift) is recorded as **wrong** — `building_prefabs.gd` retints every castle module correctly and always has. The real cause: `art.json` puts the sun in the NORTH sky (pitch −44, yaw −40) while `landmark.gd` puts the gate, ramp and whole approach on the SOUTH side, so the hero face is backlit at every hour the chapter is played, measured near luma 0.012 against a 0.49–0.60 reference range. Fixed by raising the retint ladder and giving the garrison its own fires. **Remaining:** the blind pass could not be spawned (session service unavailable).
- **owner_reported:** no · **system_class:** tooling/CI (process) · **likely_still_valid:** yes

## HIST-086 — the rename flow has no test for its own trigger path
- **source:** `ralph/BACKLOG.md:3090` · **original_id:** `PT-17-test`
- **player_visible_problem:** none. Existing tests cover the nickname mechanism generically, not H-key → prefilled `name_prompt` → `set_nickname`. `translated: yes`
- **date_opened:** 2026-08-17 · **last_touched:** 2026-08-17
- **status_evidence:** Flagged by the lane that rebased `PT-17`, about work it did not write; the gap predates the rebase and was correctly judged outside "make it landable". `test_name_entry.gd` and `smoke_rename_pad_trigger.gd` both exist (the latter is on `HIST-034`'s unwired list), which may or may not close it.
- **owner_reported:** no · **system_class:** tooling/CI · **likely_still_valid:** unsure

## HIST-087 — the unit suite is slow enough to look hung
- **source:** `ralph/BACKLOG.md:3098` · **original_id:** `OPS3`
- **player_visible_problem:** none. It cost one lane a killed run on the belief that a global input change had deadlocked it; it had not. `translated: yes`
- **date_opened:** 2026-08-17 · **last_touched:** 2026-08-25
- **status_evidence:** Recorded at >500 s under load. Since improved twice: `RUNTESTS-FILTER` added a `--only=` selector, and the 08-25 session root-caused shard timeouts to individual test methods paying for a full `RULES.all_placements()` (~200 s, all ten vegetation layers against the real corridor) when they only read one or two layers back — fixed at the test level in three files, and the unit suite went to six shards for margin. The standing advice survives: give the suite room before concluding it hung, and serialise runs.
- **owner_reported:** no · **system_class:** tooling/CI · **likely_still_valid:** no — largely addressed; carried because the entry was never closed.

## HIST-088 — four tests that pass while the thing they name is broken
- **source:** `ralph/BACKLOG.md:3118` · **original_id:** `TEST2`
- **player_visible_problem:** none directly; this is the class that let a build menu no controller could operate stay green. `translated: yes`
- **date_opened:** 2026-08-16 · **last_touched:** 2026-08-17
- **status_evidence:** Four distinct shapes recorded: (1) no test chooses a build piece **through input** — `smoke_free_build.gd` arms `pending_build` directly and `smoke_build_menu_footprint.gd` calls `_select_category` directly; (2) `InputEventAction` names the action and never travels the `InputMap`, so any test asserting "the player can do X" with one asserts something weaker than it reads — `smoke_backpack_pad_target.gd` is the pattern to copy; (3) `test_controls.gd`'s collision check only sees keyboard; (4) `OW8`'s own test is weaker than it looks, and its structural assertion is the load-bearing one — *"that is why the two previous OW8 fixes tested green and still failed on the owner's hardware, twice."* Item (3) is recorded elsewhere as widened (`UI-PAD3` names `test_no_two_menu_context_actions_share_a_button` widened past keyboard); the others have no closing evidence.
- **owner_reported:** no · **system_class:** tooling/CI (test integrity) · **likely_still_valid:** yes — partly.

## HIST-089 — two concurrent headless Godot runs corrupt each other's script loading
- **source:** `ralph/BACKLOG.md:3149` · **original_id:** `OPS2`
- **player_visible_problem:** none. It is a plausible source of "flaky" CI that is not flaky at all. `translated: yes`
- **date_opened:** 2026-08-16 · **last_touched:** 2026-08-16
- **status_evidence:** Two concurrent runs on a four-core container produced `Attempt to open script … resulted in error 'File not found'` for a file present on disk; serially it passed. Every lane brief says serialise your runs, *"but that is instruction, not enforcement."* Corroborated by `VISUAL_LEDGER.md`'s finding that llvmpipe takes every core, so a second render does not halve the wall clock, it doubles both.
- **owner_reported:** no · **system_class:** tooling/CI · **likely_still_valid:** yes

## HIST-091 — `verify-boss` is intermittent and has cost innocent branches
- **source:** `ralph/BACKLOG.md:3313`; `ralph/ACTIVE_GAME_PLAN.md` Gate E child prompt 34 · **original_id:** `CI-BOSS`
- **player_visible_problem:** none directly — but an intermittent gating job silently stops healthy work from shipping and leaves no trace saying so. `translated: yes`
- **date_opened:** 2026-08-17 · **last_touched:** 2026-08-17
- **status_evidence:** Two branches (`ralph/TEST2`, `ralph/PT-17-test`) green on all 19 jobs on their own push and red only on the `ralph-merge` dispatch of the same tree. The root failure is one line — *"the boss fight never resolved inside 9000 frames"* — and the six FAILs after it are consequences. `TEST1`'s question answered by a second example after `verify-aggression`. **Explicitly: do not just raise the frame budget.** The 2026-08-25 handover independently names this exact anti-pattern six more times (*"a budget or a bounded search that could never succeed, filed as an intermittent flake"*), which is strong outside corroboration.
- **owner_reported:** no · **system_class:** tooling/CI · **likely_still_valid:** unsure — CI has been rebuilt since; `verify-boss` no longer appears by that name in the 08-25 shard list.

## HIST-098 — nobody has audited the chapter against the creature-mesh budget
- **source:** `ralph/BACKLOG.md:3683` · **original_id:** `SH54`
- **player_visible_problem:** none. `translated: yes`
- **date_opened:** before 2026-08-17 · **last_touched:** 2026-08-17
- **status_evidence:** Spec §38 step 54 / §20: walk every item shipped for this chapter and confirm none installed, requested or planned a new creature mesh. *"Cheap, and worth doing once at the end, because the constraint is a budget the owner holds and a single quiet violation spends it."* Relevant: `BLOCKED.md` records at least one near-miss the rule caught (the tether-machine board contains a bound legendary, and generating the board as one asset would break the rule while believing it was following one).
- **owner_reported:** no (the constraint is the owner's) · **system_class:** other (bookkeeping) · **likely_still_valid:** yes

## HIST-100 — the DONE-on-ship contract has broken before and the fix was never landed
- **source:** `ralph/BACKLOG.md:3702` · **original_id:** `OPS1`
- **player_visible_problem:** none. `translated: yes`
- **date_opened:** before 2026-08-17 · **last_touched:** 2026-08-17
- **status_evidence:** Largely executed — the `RECONCILED 2026-08-17 (OPS1)` note records 35 items closed in one pass and states the rule that made the difference (*"a shipped item is one whose content is an ancestor of `main`. Check the tree."*). The drift it names is nonetheless still visible in this sweep: `HIST-035`, `HIST-072`, `HIST-074`, `HIST-075`, `HIST-080` and `HIST-101` all read open in `BACKLOG.md` while `DONE.md` or the shipped data says otherwise, and `HIST-040` is a verbatim duplicated section.
- **owner_reported:** no · **system_class:** other (bookkeeping) · **likely_still_valid:** yes — as a recurring failure mode, evidenced by this register.

## HIST-110 — a redundant remote branch nobody has permission to delete
- **source:** `ralph/ACTIVE_TASKS.md:103`; `ralph/HANDOVER_2026-08-25_CI_GREEN_AND_TWO_LANES.md:78`
- **original_id:** branch cleanup / `SUPERSESSION-2026-08-23`
- **player_visible_problem:** none. `translated: yes`
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-25
- **status_evidence:** Sixteen branches were verified deletable on 2026-08-23 and deletion needed owner/ChatGPT credentials (403 from sessions). Most are gone. `ralph/WORLD-GRASS` is now redundant too — every file it uniquely carried is byte-identical on `main` — and the 08-25 session's permission scope did not allow deleting it. `ralph-status` must never be deleted. Non-trivial only because a stale local ref briefly made it look as though real unlanded work existed, which cost that session time.
- **owner_reported:** no · **system_class:** tooling/CI (ops) · **likely_still_valid:** yes

## HIST-123 — five defects reported as game bugs were capture-path bugs
- **source:** `ralph/GATE_D_REMAINDERS.md:84` · **original_id:** Gate D remainder 2
- **player_visible_problem:** none — **and that is the point.** Three lanes independently lost time to this. `translated: yes`
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** The five: bushes reading crimson (a probe loading models raw and skipping the layer's `retexture`); a campfire with no flame/glow/smoke (embers survive the headless renderer, flame billboards and the omni light do not — *the scene may be correct and the capture lying*); the trainer as "a solid black cut-out" (disproved by `tools/_capture_char_black.gd` with a wooden crate as the critic's own control); a day/weather clock racing a multi-viewpoint pass; and the camera rig's parked player tripping the water-hazard overlay. D3 fixed the last two inside its own tools and correctly did not fix the same conventions in `capture_prop_clusters.gd` and friends. **The standing rule it produced is the durable output:** a defect seen only in a survey frame must be reproduced through a second path before acting on it. Directly relevant to `HIST-039`, `HIST-071`, `HIST-093`, `HIST-126`.
- **owner_reported:** no · **system_class:** tooling/CI · **likely_still_valid:** yes — the class, if not each instance.

## HIST-124 — two regions' visual verdicts were reached against different foliage than ships
- **source:** `ralph/GATE_D_REMAINDERS.md:113` · **original_id:** Gate D remainder 3
- **player_visible_problem:** none directly; it means two regional "pass" verdicts are not about the shipped world. `translated: yes`
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-25
- **status_evidence:** `density_scale` was raised for band 4 and band 5 (0.03 → 0.05) **after** those lanes' blind rounds concluded, and neither region has been re-judged since the re-bake. Worse since: `corridor_fill.density_scale` then went 1.0 → 1.6 → 2.8 across VIS-WORLD and B11, and the consolidation branch halved the carpet layers again. Every regional verdict on file predates at least two density changes.
- **owner_reported:** no · **system_class:** tooling/CI (process) · **likely_still_valid:** yes

## HIST-133 — `ACTIVE_TASKS.md`'s gate tables were stale against the evidence
- **source:** `ralph/ASSESSMENT_2026-08-23.md:190`
- **player_visible_problem:** none. `translated: yes`
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-25
- **status_evidence:** Largely fixed — `ACTIVE_TASKS.md` was rewritten around the assessment and now names it as superseding the RECONCILE tables. The staleness has since **recurred one level up**: `ACTIVE_TASKS.md`'s own P1/P2/P3 packages are closed (Gate B passes; the four red tests are green; `STRANDED-P3` landed the chop clip, the NPC palette and the survey_band2 fix), and `ASSESSMENT_2026-08-23.md` is itself wrong in the project's favour on four points, as `GATE_F_EVIDENCE_2026-08-23.md` §5 records. The 08-25 handover instructs reading it **before** those two files for this reason.
- **owner_reported:** no · **system_class:** other (doc hygiene) · **likely_still_valid:** yes — as a recurring pattern.

## HIST-142 — the chapter run does not carry a save between its three segments
- **source:** `ralph/GATE_F_EVIDENCE_2026-08-23.md` §1 and §7
- **player_visible_problem:** none — but it means "the chapter has been run continuously" is a claim about a *record*, not about a *save*. `translated: yes`
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** Stated plainly rather than implied: the record is continuous and the world is continuous inside each segment (the corridor's 11.5 km is genuinely one boot with one counter), but each of the three segments is its own process — the head starts a real fresh game at the title, the tail grants a finale-level five. Closing it means having the head write a South Bridge save for the tail to load, which edits `smoke_gate_b_continuous.gd`; that file was owned by `ralph/GATEB-PATH` at the time and that branch has since landed, so the ownership block is gone.
- **owner_reported:** no · **system_class:** tooling/CI · **likely_still_valid:** yes

## HIST-143 — the full-corridor blind visual pass has never run
- **source:** `ralph/GATE_F_EVIDENCE_2026-08-23.md` §7; `ralph/GATE_D_REMAINDERS.md:124`
- **player_visible_problem:** none directly. It is the second of the two conditions Prompt 70's pass requires, and the one nobody has produced. `translated: yes`
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-25
- **status_evidence:** The 2026-08-23 blind critique answered **NO to both bar questions**; whether the density re-bake and the branches then in flight moved it was explicitly not that lane's call. All those branches have since landed on `main` and the density was then cut again. No pass since has re-answered either bar question. This is the umbrella under which `HIST-037`, `HIST-059`, `HIST-069`, `HIST-124`, `HIST-125` and `HIST-144` all sit.
- **owner_reported:** no · **system_class:** tooling/CI (process) · **likely_still_valid:** yes

---

# Section 3 — candidates for SUPERSEDED / OBSOLETE

**These are candidates only.** The §16.3 category-4 (SUPERSEDED) and category-6
(OBSOLETE) rulings are Fable's at reconciliation. Each row names the superseding
decision or the evidence that the system it describes no longer exists. This
section is deliberately small: §16.5 forbids calling difficult misses obsolete,
so nothing hard is parked here — every entry below is retired by a *named
decision or a verified code/data fact*, not by being awkward.

## HIST-061 — two suns in the sky at golden hour
- **source:** `ralph/BACKLOG.md:1551` · **original_id:** `TWO-SUNS`
- **superseding evidence:** Re-verified 2026-08-23 during `SITE-SHOTS`' third pass: *"a fresh capture's sky is clean; whatever produced the 'two orange discs' this item originally described does not reproduce now. No second `DirectionalLight3D` or second sky material exists in the scene or the tool, so there was no code path to fix even if it had reproduced."* The frame it was found in (`site/img/camp-dusk.jpg`) was deleted.
- **caveat:** an independent blind critic found it in the first second of looking, so "does not reproduce" is weaker than "was never there".
- **candidate category:** OBSOLETE

## HIST-092 — the scatter only dresses a 512 m square at the origin
- **source:** `ralph/BACKLOG.md:3384` · **original_id:** `VEG-CORRIDOR`
- **superseding evidence:** The bound it describes no longer exists. `WORLD-GRASS`'s measurement on `main` records `corridor_fill` covering *"the 7.5 km outside authored clumps"* with per-layer `density_scale`, and `SCATTER-BUDGET-REVIEW` measures 789,511 placements across the corridor against the ~23.7k in z −256..+256 this entry describes. The per-band authored density it asks for exists (`corridor_bands`).
- **candidate category:** OBSOLETE (the system it names was replaced)

## HIST-101 — the relay console can be shut down without beating its captain
- **source:** `ralph/BACKLOG.md:3720` · **original_id:** (unnamed, "Found along the way")
- **superseding evidence:** **Refuted in the working tree at this SHA.** `data/config/tether_relay.json:194` reads `"requires_flag": "relay_captain_defeated"`, and its `_comment_requires_flag` records *"CLOSED 2026-08-22 (gates-abc-verification)"* with the full reasoning. The BACKLOG entry describing it as `""` is stale prose.
- **candidate category:** OBSOLETE (already fixed; bookkeeping only)

## HIST-102 — Band 4 has no harvest nodes of its own
- **source:** `ralph/BACKLOG.md:3742` · **original_id:** (unnamed, "Found along the way")
- **superseding evidence:** `GATE_F_EVIDENCE_2026-08-23.md` §5: *"SHIP BLOCKER 2 (band 4 harvest) is closed. Band 4 fields wood, stone and fiber alongside its ironwood; every band pays for its own rest point."* `test_camp_supply_reaches_every_band` passes in all five bands, having been red on band 4 at the assessment. Landed by `ASSESS-REDS`.
- **candidate category:** OBSOLETE (already fixed)

## HIST-109 — lanes edit a fixture that exists to be frozen
- **source:** `ralph/GATE_D_REMAINDERS.md:145`; `ralph/ACTIVE_TASKS.md:100` · **original_id:** `tests/fixtures/band_split_baseline/`
- **superseding decision:** **Coordinator ruling 2026-08-23**, recorded in the remainders file and in the test header: the fixture is redefined as a **tracked mirror**, not a frozen original. The "pinned forever" reading died when the corridor itself was re-laid (OW5D spine) — the pre-split world no longer exists as a target and re-freezing would mean reverting owner-directed sitings. What the test still claims is that live band configs and the mirror agree entry-for-entry, so a dropped, duplicated or reordered entry still fails; a deliberate identity move costs a double write with a `_why_*` rationale, and that friction is the mechanism.
- **candidate category:** SUPERSEDED (by a recorded ruling)

## HIST-115 — there is no small creature tier
- **source:** `ralph/BLOCKED.md:171` · **original_id:** `VIS-CAST` creature roster 3
- **player_visible_problem (for the record):** the roster spans 1.35 m to 2.60 m over seventeen species; ten of seventeen stand at or above the player's height; the smallest creature is a metre-and-a-third songbird chick.
- **superseding decision:** `docs/decisions/D19-starters-are-boar-sized.md` set exactly these numbers, **by the owner, after he played the build**, on the finding that *"your creature felt small"* — deliberately raising the whole band and giving the starters a bigger jump. `CLAUDE.md`'s canon precedence puts owner-play evidence first, and nothing in the 2026-08-18, 08-21 or 08-23 playtests reopens it. The entry's own words: *"A visual critic's aesthetic reading does not outrank a decision the owner made at the controller."*
- **caveat:** the entry offers a way back — the owner seeing the roster photographed against the ruler and saying whether he still wants the D19 band. That is an owner question, not a defect.
- **candidate category:** SUPERSEDED (by D19)

## HIST-120 — three creature reads need geometry the hard rule forbids
- **source:** `ralph/BLOCKED.md:936` · **original_id:** `CREATURE-MESH-FLOURISH`
- **player_visible_problem (for the record):** brooktail's water-crest tail, ripplet's proportions, and meadowhart/veridian antler geometry are silhouette, and a texture cannot change a silhouette.
- **superseding decision:** `docs/MEADOWS_PROGRESSION_SPEC.md`'s "Creature art rule" — *"Do not reopen creature concept design because a silhouette is imperfect"* — and `CLAUDE.md`'s unconditional no-new-Meadows-creature-mesh rule, reaffirmed by the owner on 2026-08-11 *with 5000 Meshy credits in the account*, so a healthy balance does not lift it. The entry itself says it is **not** a request for a decision the owner has not made; it is a record that the decision has a visible cost, filed so future lanes stop re-arguing it. *"Nothing in the roster is blocked on this. The paint layer shipped."*
- **candidate category:** SUPERSEDED (by the spec's own creature art rule)

## HIST-129 — the Old Mill Crossing is impassable
- **source:** `ralph/GATE_D_REMAINDERS.md:47` · **original_id:** Gate D remainder 1b
- **superseding evidence:** Root-caused and fixed **in the same file**, §8: a four-galecrest cluster (band 3 order 3037) centred 17.5 m from the crossing's own centreline, whose 18 m spawn disc plus a 7 m wander radius put a body on the deck. Caught by `tools/_probe_mill_stall.gd` naming `Wild_galecrest_3037_1` as the collider. Fixed in the spawn table (4220.5 → 4235.0, radius 18.0 → 8.0); three consecutive local runs reached the historical +23.5–23.6 m margin. `_walk_at_the_bridge` was reverted to its pre-investigation form.
- **caveat:** the item's *class* survives as `HIST-128` and must not be retired with it.
- **candidate category:** OBSOLETE (already fixed, with the class carried forward separately)

---

---

# Section 1 (continued) — player-facing items added by the second sweep

`HIST-146` onward. Allocated 2026-08-25 after the coordinator directed that the
three gaps the first pass named be closed. Order within this block: the
`ralph/reports/VISUAL_*_2026-08-23.md` set first (read in full, not grepped),
then `ralph/lanes/` + `ralph/ledger/` + `ralph/planning/`, then
`docs/ralph-prompts/`.

**A note on this block's status evidence.** The visual reports are lane records
written mid-sweep, and several of them fix, refute or supersede findings inside
their own text. Every row below was checked against the later rounds in the same
file before being carried, and where a later round closed it, it is not here.

## HIST-146 — the camera watches the fight from behind your own creature's rear

- **source:** `ralph/reports/VISUAL_COMBAT_AND_ITEMS_2026-08-23.md`; root-caused in `ralph/reports/VISUAL_MAKE_LANE_FINDINGS_2026-08-23.md` §1
- **original_id:** (unnamed; D8 round 1 combat camera)
- **title:** `enemy.preferred_range` 2.1 m against `camera.distance` 4.6 m
- **player_visible_problem:** *"The fight happens between a large rump and a distant dot."* The piloted creature fills the bottom-centre of the screen with its back to the camera, face never visible, while the opponent is a ~40 px speck at mid-distance.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** Not a camera-placement taste call — it falls out of three config numbers that were each reasonable alone. The ally sits ~69% of the way along the camera's sight line (4.6 of 6.7 m), dead centre, and at 4.6 m a creature-sized body subtends more angle than a 1.5 m shoulder offset moves it. Measured, not inferred: `_aim_camera_clear()` fires a real physics ray and tries five lateral yaw nudges before giving up, printing *"every camera nudge tried toward this target was still blocked by the ally's own body"* in **both** encounters of the latest run. `_aim_camera()` never moves the camera, so these are the real `CameraRig` a player looks through. Also named separately: `arena.separation` is 5.0 m while the AI holds 2.1 m — *"the arena is authored for a fight at roughly twice the distance the fight is actually had at."* Recorded as *"the first fix queued behind the round-2 verdict"* and, four rounds later, still not made. **Distinct from `HIST-002`**, which is the body-spacing half.
- **owner_reported:** no
- **system_class:** combat/camera
- **likely_still_valid:** yes

## HIST-147 — the danger telegraph is drawn where the player cannot see it

- **source:** `ralph/reports/VISUAL_COMBAT_AND_ITEMS_2026-08-23.md`
- **original_id:** (unnamed; D8 round 1)
- **title:** The "incoming — move" ring is stamped on the player creature's own back shell
- **player_visible_problem:** The red ring that warns the player to move is drawn on their own creature's back and occluded by its body — and given `HIST-146`, the camera is looking at exactly that back. *"A danger telegraph the player physically cannot see is worse than none."*
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** `telegraph_glow.gd` is built, wired at `combat_manager.gd:29`, and was itself built against an earlier critic's *"the wind-up frame is indistinguishable from standing"* — so the feature exists and its placement is the defect. No later round records it moved. Compounds with `HIST-146` and `HIST-002`: the ring is on the back, the camera faces the back, and the two bodies are touching.
- **owner_reported:** no
- **system_class:** combat/camera
- **likely_still_valid:** yes

## HIST-148 — a ranged move produces nothing visible in the world

- **source:** `ralph/reports/VISUAL_MAKE_ROUND4_2026-08-23.md`; mechanism in `ralph/reports/VISUAL_COMBAT_CAPTURE_MECHANISM_2026-08-23.md`
- **original_id:** (unnamed; the projectile finding, rounds 1–4)
- **title:** *"The move exists in the UI and nowhere in the world"*
- **player_visible_problem:** Using a ranged move shows no projectile, no muzzle or cast flash, no trail and no dust — the move happens in the interface and not on screen.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** **Three separate things wore this one symptom and only two are resolved.** (1) The harness could never photograph it — `move_projectile.gd` clamps its flight to `MAX_TRAVEL` 0.42 s while one rendered frame costs ~2.4 s under llvmpipe, so the node is freed roughly two rendered frames before the shutter opens; that is a capture defect and is `HIST-195`. (2) A real material bug — the bolt was drawn with additive blend *and* vertex-colour alpha, both of which `impact_flash.gd` rules out by name, and rendered as literally nothing; fixed, and the bolt now produces a measurable cream cluster at the muzzle. (3) **The bolt has nowhere to fly**, because the target is inside the caster (`HIST-002`) — *"a ranged move has never had a visible distance to travel in any survey this sweep has run."* Round 4's verdict is explicit that the fix for (2) *"does not rescue it"* and the frame still fails.
- **owner_reported:** no
- **system_class:** combat/camera
- **likely_still_valid:** yes — gated behind `HIST-002`.

## HIST-149 — the impact burst reads as a flat decal

- **source:** `ralph/reports/VISUAL_MAKE_ROUND2_2026-08-23.md`
- **original_id:** (unnamed; D8 round 2)
- **title:** *"a flat beige starburst decal"*
- **player_visible_problem:** A landed hit produces a flat pale starburst pasted over the scene rather than an impact.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** Recorded as the correct outcome of round 1's open question: the effect was always there and the shutter was late, so it is *"now judged, and judged harshly, which is the correct outcome."* `impact_flash.gd`'s own header records the measurement that caused it to be built — 10 warm pixels at contact against `palworld-01`'s 24,623. No later round records it re-authored. This is criticism of the effect, not a report that it is missing, which is why it is a distinct row from `HIST-148`.
- **owner_reported:** no
- **system_class:** combat/camera
- **likely_still_valid:** yes

## HIST-150 — a fight carries the previous fight's toast and target plate

- **source:** `ralph/reports/VISUAL_MAKE_ROUND2_2026-08-23.md`
- **original_id:** (unnamed; `05-trainer-battle`)
- **title:** *"You backed off."* over a target plate naming the last encounter's creature
- **player_visible_problem:** A trainer battle opens showing a message from the previous encounter and a target plate reading the wild creature the player just left.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** `is_fighting()` is true and `enemy_body()` is non-null, so a fight is genuinely open — the frame carries a stale toast and a stale target from the previous encounter, and the trainer's own creature is not in shot. **Explicitly left unresolved by its own lane:** *"Whether the stale plate is a capture-sequencing problem or a real HUD defect is not yet established and is NOT recorded as either."* No later round settles it.
- **owner_reported:** no
- **system_class:** UI architecture / combat
- **likely_still_valid:** unsure — genuinely undetermined, by the lane's own statement.

## HIST-151 — a hard-edged band across the hillside that follows nothing

- **source:** `ralph/reports/VISUAL_MAKE_LANE_FINDINGS_2026-08-23.md` §6
- **original_id:** (unnamed; the teal ground band)
- **title:** Measured — it is a shape, not a light
- **player_visible_problem:** A large region of hillside carries a hard curved boundary that follows no terrain feature and no sun direction. The blind critic: *"the single most artificial thing in the combat set."*
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** Measured rather than eyeballed, because the description and the numbers disagree: inside the band `(38, 51, 10)` against adjacent grass `(35, 46, 3)` — about +8% luminance with the blue channel lifted 3 → 10. So it is **not** a bright light and nobody should go looking for a stray `SpotLight3D`; it *"measures like a ground-material or splat boundary."* Still present in round 3 and *"very prominent"*. Routed to D7/VIS-WORLD and not touched by the lane that measured it. Plausibly the same family as `HIST-193` (the 2 m control-map cell), which VIS-WORLD later measured from the other side.
- **owner_reported:** no
- **system_class:** terrain/composition
- **likely_still_valid:** yes

## HIST-152 — the HUD says no creature is out while the player is piloting one

- **source:** `ralph/reports/VISUAL_COMBAT_AND_ITEMS_2026-08-23.md`
- **original_id:** (unnamed; D8 round 1 HUD)
- **title:** *"ACTIVE COMPANION — No creature out"* during a fight
- **player_visible_problem:** The interface contradicts the game state the player is looking at.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** Reported alongside two findings from the same frame that were later shown to be capture artefacts (the keyboard glyphs; the empty TEAM panel, which *"points the same way: the capture probably never seeded a party"*). This one is not named in D2's list of eight resolved artefacts, and no round records it fixed. `translated: no` — the string is what the player reads.
- **owner_reported:** no
- **system_class:** UI architecture
- **likely_still_valid:** unsure — sits in a frame whose neighbours were artefacts, and was never separately cleared.

## HIST-153 — the exploration HUD draws over every station panel

- **source:** `ralph/reports/VISUAL_UI_2026-08-23-round2.md` (round 3 section)
- **original_id:** (unnamed)
- **title:** A real shipping bug the dishonest capture hid for the whole sweep
- **player_visible_problem:** Opening a bench, chest, shop, bed or any of the five station panels leaves the world HUD drawing straight over it.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** Found the moment the capture started shooting panels over a real world: *"There was never a frame of it because those panels had only ever been photographed with no world, and therefore no HUD, behind them."* The round-3 text records it as **found**, not as fixed, and it does not appear in that round's own "what round 3 fixed" list. Related but distinct from `HIST-016` (`VIS-UI-r6`, the player's body printing through the panels) and from the round-2 fix that made the *pause menu* hide both HUD layers.
- **owner_reported:** no
- **system_class:** UI architecture
- **likely_still_valid:** yes

## HIST-154 — the hotbar is not drawn during a fight

- **source:** `ralph/reports/VISUAL_UI_2026-08-23-round2.md` ("Deliberate trade-off, recorded rather than buried")
- **original_id:** (unnamed)
- **title:** A deliberate trade-off with a stated revisit condition
- **player_visible_problem:** When combat starts the exploration legend, the prompt and the hotbar panel all vanish, so a player who wants food or an orb mid-fight has no visible bar to find it on — *"a bar the player cannot see is harder to use than one they can."*
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** Recorded honestly by the lane that did it, with the reason: combat's own move grid and orb readout are anchored bottom-right and neither can move without taking the central focus lane `smoke_prompt_hotbar_dock.gd` guards. **The bindings are untouched** — owner directive 2026-08-22 §1 keeps the d-pad on hotbar 2–5 in every context *"so food and orbs stay reachable mid-fight"*, and `_read_hotbar_input()` still polls through a fight. The lane names its own revisit condition: *"If a later blind round says the fight gives no way to find a potion, the fix is to move combat's grid, not to restore this panel where it is."* A Gate F playtest is exactly that round.
- **owner_reported:** no (but it sits directly against an owner directive's stated intent)
- **system_class:** UI architecture
- **likely_still_valid:** yes — as a live trade-off awaiting the evidence it names.

## HIST-155 — the title, the portraits and the picker are three more art languages

- **source:** `ralph/reports/VISUAL_UI_2026-08-23.md` ("Five visual languages"); carried as "not acted on" in `ralph/reports/VISUAL_UI_2026-08-23-round2.md`
- **original_id:** (unnamed; D2 round 1)
- **title:** Flat vector poster art, an anime portrait on an uncropped light-grey square, and the starter-picker staging
- **player_visible_problem:** The panel system is judged *"a real, coherent system"*; against it sit a title screen in flat vector poster art, a character portrait pasted on an uncropped light-grey square, and a starter picker staged differently from both.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** Round 2 lists these among *"Not acted on, with reasons… the starter-picker staging, the portrait art style and the title illustration (other domains, and partly art that is not in the build)."* The critic's verdict on the panel system itself is worth preserving: *"Nothing in the panel language says 'meadow', 'cozy', or 'hand-made'; it says 'dark-mode tool'"* — with the bones judged compatible with a reskin. Overlaps `HIST-019` (the display font), which is the fourth language.
- **owner_reported:** no
- **system_class:** art/asset
- **likely_still_valid:** yes

## HIST-156 — unrelated items share one glyph

- **source:** `ralph/reports/VISUAL_COMBAT_AND_ITEMS_2026-08-23.md`
- **original_id:** (unnamed; D6 round 1)
- **title:** axe = hoe = pickaxe; four of six consumables are one flask; heartstone = rootstone = stone
- **player_visible_problem:** On the screen the player opens most, three different tools draw the same T-mattock, most consumables draw the same flask, and three different stones draw the same fractured hex. The torch is *"a two-pixel vertical line with a dot — invisible at any zoom."*
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** **Distinct from `HIST-004`**, which is about colour encoding category; this is the glyph shapes themselves colliding. The icon sheet's own SHARED-ICON flagging is called *"honest and well-organized bookkeeping — the flags just haven't been acted on."* Complicated by `HIST-196`: every icon finding in rounds 1 and 2 covers less than half the set, because the sheet was cropped both times.
- **owner_reported:** no
- **system_class:** UI architecture / art
- **likely_still_valid:** yes

## HIST-157 — the berry bush has no berries

- **source:** `ralph/reports/VISUAL_COMBAT_AND_ITEMS_2026-08-23.md`
- **original_id:** (unnamed; `world-berries`)
- **title:** A green bush with purple trumpet flowers
- **player_visible_problem:** The node the game calls berries, and which the corridor relies on to break its longest gaps, has no berries on it.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** Judged blind from the item-art survey. Worth cross-reading with `GATE_F_EVIDENCE_2026-08-23.md`, which records the chapter's single worst gap (165 m in band 2) as *"broken by a berry cluster"* — i.e. the pacing argument leans on a prop a player may not recognise.
- **owner_reported:** no
- **system_class:** art/asset
- **likely_still_valid:** yes

## HIST-158 — the two most-gathered plant nodes share one identity

- **source:** `ralph/reports/VISUAL_COMBAT_AND_ITEMS_2026-08-23.md`
- **original_id:** (unnamed; `world-fiber`)
- **title:** Neon-violet flowers at ~3× scale, a colour-twin of the berry bush
- **player_visible_problem:** Fiber and berries — the two things the player gathers most — look like the same plant.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-25
- **status_evidence:** The **~3× scale** half is plausibly addressed: `VISUAL-GROUNDCOVER` rescaled `flowers` 0.07–0.26 → 0.025–0.09, and the 2026-08-23 blind critique's "violet flowers ~3× oversize (0.5–0.8 m blossoms)" was that lane's target. The **colour-twin** half is not addressed anywhere found. The consolidation branch then cut the flowers layer's density again (1.5 → 0.8), which changes how often the pair appear together but not whether they are distinguishable.
- **owner_reported:** no
- **system_class:** art/asset
- **likely_still_valid:** unsure — one half plausibly closed, the other untouched.

## HIST-159 — the friendliest gathering verb points at a burnt tree

- **source:** `ralph/reports/VISUAL_COMBAT_AND_ITEMS_2026-08-23.md`
- **original_id:** (unnamed; `world-wood`)
- **title:** *"a dead, leafless, charcoal-black tree"*
- **player_visible_problem:** The wood node — the first thing the tutorial sends the player to chop — is a dead black tree. *"In a biome sold as cozy-and-inviting, the friendliest gathering verb in the game points at a burnt, haunted prop."*
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** No closing evidence found. Note the neighbouring `HIST-009`: band 2's ironwood nodes have the opposite defect (raw crimson) from the same root cause class — harvest nodes taking their material from a path no scatter layer covers.
- **owner_reported:** no
- **system_class:** art/asset
- **likely_still_valid:** yes

## HIST-160 — the common stone wears the exotic look

- **source:** `ralph/reports/VISUAL_COMBAT_AND_ITEMS_2026-08-23.md`
- **original_id:** (unnamed; stone vs rootstone)
- **title:** Stone and rootstone read reversed
- **player_visible_problem:** Ordinary stone is exotic coal-black while rootstone — the special material the saddle recipe is gated behind — is ordinary granite. The player learns the wrong signal for what is rare.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** From the same blind pass that called `world-rootstone` *"the best prop in either set"*, so the prop is not bad — the pairing is inverted. Same shape as the galecrest rarity inversion D3 found and fixed, which is precedent that this class is fixable without new art.
- **owner_reported:** no
- **system_class:** art/asset / progression legibility
- **likely_still_valid:** yes

## HIST-161 — no tool is gripped

- **source:** `ralph/reports/VISUAL_MAKE_ROUND2_2026-08-23.md`
- **original_id:** (unnamed; held-tool set, round 2)
- **title:** *"the right hand is open, fingers splayed, and the shaft passes behind/through the hand"*
- **player_visible_problem:** Every tool the player holds floats through an open hand. There is no grip pose anywhere in the set.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** Round 1 could not have seen this — its camera faced the trainer's back and every tool rendered stowed. Round 2's reframe made the held-tool set valid for the first time, and this is what it showed. Adjacent to the owner's OP21-24 (*"the trainer does not hold the axe in a believable expected grip/pose"*), which `ASSESSMENT_2026-08-23.md` records as fixed for the **swing clip** by `STRANDED-P3`; the grip pose is a different half and is not recorded as addressed.
- **owner_reported:** yes — OP21-24 names the grip explicitly, and OP23-10 re-reports the torch pose.
- **system_class:** art/asset (animation)
- **likely_still_valid:** yes

## HIST-162 — held tools are two to three times too large, and cannot be scaled from data

- **source:** `ralph/reports/VISUAL_MAKE_ROUND2_2026-08-23.md`; `ralph/reports/VISUAL_MAKE_LANE_FINDINGS_2026-08-23.md` §3
- **original_id:** (unnamed)
- **title:** `tool_hold.gd` has `held_offset` and `held_rotation_deg` but no `held_scale`
- **player_visible_problem:** The knife reads ~1.4 m, the pickaxe head ~1.4 m and the hammer ~2.1 m against a 1.80 m person. The hammer is also the *survival* pack's axe while every other tool is the *fantasy* pack's — a different art family in the same hand.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** Corroborated by the capture's own measurement (`held/hoe … 78% of a 1.80 m trainer`). The missing `held_scale` is the load-bearing part: *"the size cannot currently be corrected from data at all."* Also settled in the same pass and worth not re-deriving: a repo-wide search for `*hammer*`, `*mallet*`, `*sledge*`, `*rod*`, `*fish*` returns **icons only**, so the hammer is not a lazy pick from a set that had a hammer in it, and `fishing_rod` has `held_model: ""` deliberately — *"For water that doesn't exist yet"* — so `held-fishing_rod` containing no rod is the capture being correct, not a defect.
- **owner_reported:** no
- **system_class:** art/asset
- **likely_still_valid:** yes

## HIST-163 — the mill has no mill in it

- **source:** `ralph/reports/VISUAL_LOCATIONS_2026-08-23.md`; independently in `ralph/reports/VISUAL_STRUCTURES_AND_GROUND_2026-08-23.md` and `VISUAL_MAKE_ROUND4`
- **original_id:** (unnamed)
- **title:** 78 modules, not one of them a wheel
- **player_visible_problem:** A named landmark the player is sent to, and which a Band 3 progression gate is named after, has no wheel, sails, hopper, race or axle — it is a three-storey townhouse with a landmark's name.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** **Found twice independently and agreeing** — from the recipe (78 modules enumerated, every one a wall, roof, window, corner, border or fence) and blind from the frames (*"The shot named 'wheel' contains no wheel"*). `village.json`'s own placement comment states the wheel hangs at local x −4.0 with its paddles meeting the stream, and the same file already records why there is none: the Medieval Village MegaKit has no mill machinery, which is why the old `TowerWindmill` was removed **and not replaced**. So a named landmark is being grounded `"highest"` so that a wheel which does not exist clears a streambed.
- **owner_reported:** no
- **system_class:** art/asset
- **likely_still_valid:** yes

## HIST-164 — three named landmarks are two kits used twice

- **source:** `ralph/reports/VISUAL_LOCATIONS_2026-08-23.md`; `ralph/reports/VISUAL_STRUCTURES_AND_GROUND_2026-08-23.md`
- **original_id:** (unnamed)
- **title:** The inn is `farmhouse_shell` plus one retint; the ranger station is a bigger `cottage_b`
- **player_visible_problem:** *"The world cannot be navigated by looking at it."* The inn and the farmhouse stand side by side as visible twins in the same frame.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** Measured from the recipes, and the locations pass **narrows the structures critic's claim** in a way that changes the fix: the inn is 75 modules against `farmhouse_shell`'s 74 with identical module histograms and exactly one extra `retint` (`MI_RoundTiles: #8a5a3a`) — everything else it adds is colliders, a door leaf and an interior, real work, none of it visible from outside. The ranger station is **not** the same mesh: 34 modules against `cottage_b`'s 29, a `Roof_RoundTiles_4x6` instead of a `4x4`, seven straight walls instead of five. *"'It is the same model' and 'it is the same kit used the same way twice' have different fixes."* Round 4 records both as unmoved.
- **owner_reported:** no
- **system_class:** art/asset
- **likely_still_valid:** yes

## HIST-165 — the well has no well

- **source:** `ralph/reports/VISUAL_MAKE_ROUND2_2026-08-23.md`
- **original_id:** (unnamed)
- **title:** *"a hollow, open-sided frame you can see straight through"*
- **player_visible_problem:** The village well has no hole, no water, no winch and no rope.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** From the same round that found `HIST-166`. Note the tension with the locations pass, which names the well plaza as part of *"the one frame with genuine site grammar"* — so the plaza composes and the prop itself does not resolve. `VIS-MAKE-remainder` lists "a well shaft" among its blocked-on-art items (`HIST-008`); this row is the player-facing statement of the same gap.
- **owner_reported:** no
- **system_class:** art/asset
- **likely_still_valid:** yes

## HIST-166 — bridges and gates are overlapped fence panels

- **source:** `ralph/reports/VISUAL_MAKE_ROUND2_2026-08-23.md`
- **original_id:** (unnamed; `18-south_bridge_gate`)
- **title:** *"visibly two fence pieces overlapped"* with a stacked double post
- **player_visible_problem:** The South Bridge gate — the chapter's first hard progression gate, the one Oskar's key opens — is two fence pieces laid over each other.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-25
- **status_evidence:** No closing evidence found in the visual reports. Adjacent and complicating: the 2026-08-25 owner ruling that gates must be *physically* sealed produced `road_gate.gd`'s `seal_half_width`, which builds wing panels **from the same prefab as the leaf** — i.e. the fix for the gating problem propagates this prop further along the fence line. See `HIST-145`.
- **owner_reported:** no (the gating behaviour is owner-ruled; the prop's read is not)
- **system_class:** art/asset
- **likely_still_valid:** yes

## HIST-167 — there are no clouds anywhere, and no cloud layer exists

- **source:** `ralph/reports/VISUAL_WORLD_SURFACE_2026-08-23.md`; reported blind in `VISUAL_STRUCTURES_AND_GROUND` and `VISUAL_CORRIDOR_PASS`
- **original_id:** (unnamed)
- **title:** Established by reading, not by looking at frames
- **player_visible_problem:** Every sky in the game is a flat vertical gradient. The key art has cumulus in all seven panels, and no day frame in 24 surveyed shows a single cloud form. Named by critics as the main reason the wide shots read as empty.
- **date_opened:** 2026-08-22 · **last_touched:** 2026-08-23
- **status_evidence:** The sky is a `ProceduralSkyMaterial` — a vertical gradient and a soft sun blob — and `art.json`'s own comment states the limit: *"No amount of tuning puts a cloud in it."* A `PanoramaSkyMaterial` path exists and once used `day.hdr`/`golden.hdr`, which **did** carry cloud form; **EV8 pulled it deliberately** because a static equirect has a baked-in sun position that cannot track `sun.pitch_deg`/`yaw_deg`, so one viewpoint read as dusk over midday ground, and golden hour blew out two-thirds of the frame at every energy tried. The `cloudy` preset is explicitly *"a stylised flat-overcast look, not literal cloud shapes."* Recorded as **needs-implementation, not needs-tuning, and not something to fake**, with two honest routes named. **Distinct from `HIST-060`/`HIST-126`**, which are about how weather lights the ground.
- **owner_reported:** no
- **system_class:** art/asset (renderer capability)
- **likely_still_valid:** yes

## HIST-168 — three water bodies read as three unrelated colours

- **source:** `ralph/reports/VISUAL_WORLD_SURFACE_2026-08-23.md`; reported blind in `VISUAL_STRUCTURES_AND_GROUND`
- **original_id:** (unnamed)
- **title:** The palette is already unified; the divergence is depth and alpha
- **player_visible_problem:** The pond, the river and the stream read as pool cyan, dark navy and pale grey-blue — three unrelated liquids in one chapter.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** Root-caused rather than repainted, and the finding **corrects the prescription**: all three already share `surface.deep_colour` #17494a and `surface.shallow_colour` #6fa384, and the only per-body override is `alpha_shallow` (pond 0.48, river 0.70, stream 0.78). Depth decides how much resolves toward `deep_colour`, alpha decides how much bed shows through, and a grazing angle adds a fresnel of pale sky. *"So the fix is not 'give them one colour' — they have one."* Recorded as **not yet acted on**. Related: the 2026-08-23 blind critique's separate "resort-turquoise pond water against a dusk sky", which `VISUAL-LIGHT` inspected and deliberately did not touch.
- **owner_reported:** no
- **system_class:** art/asset
- **likely_still_valid:** yes

## HIST-169 — half of every grass blade renders black

- **source:** `ralph/reports/VISUAL_WORLD_SURFACE_2026-08-23.md`
- **original_id:** (unnamed; "the black grass")
- **title:** Not a backface bug — a baked-AO vertex colour forced into albedo by colour jitter
- **player_visible_problem:** The lower third of every grass blade is solid black, following the blade geometry rather than any light direction. On a ground plane that is already the game's weakest surface, half of every tuft is a black spike.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** **The briefed diagnosis was wrong and acting on it would have fixed nothing.** Culling is correct: every grass, flower and bush source declares `doubleSided: true` and `vegetation.gd` copies `cull_mode` faithfully. Traced end to end instead: the pack's meshes carry a `COLOR_0` baked-AO gradient (`Grass_Common_Tall.gltf` measures **0.001 at the lowest 15% of vertices, 0.962 at the highest**); the pack's material does not ask for it as albedo; but `vegetation.gd::_tint_for` sets `vertex_color_use_as_albedo = standard.vertex_color_use_as_albedo or needs_instance_colour`, and `needs_instance_colour` is just `colour_jitter > 0.0` — grass 0.22, drygrass 0.20, rocks 0.16. So asking for jitter force-enables the channel and `albedo_color` multiplies 0.001 to black. The two cannot simply be separated — Godot's per-instance MultiMesh colour reaches albedo through the same switch, so disabling it would silently kill the jitter, *"the exact 'set a value, nothing happens, nobody notices' failure class this repo has already paid for twice."* Recorded as **not applied yet**, queued behind the then-current blind round. Directly relevant to `HIST-041` (WORLD-GRASS), which raises grass scale on top of this.
- **owner_reported:** no
- **system_class:** art/asset
- **likely_still_valid:** yes

## HIST-170 — golden hour reads as mud

- **source:** `ralph/reports/VISUAL_STRUCTURES_AND_GROUND_2026-08-23.md`
- **original_id:** (unnamed; D7 round 1)
- **title:** The one preset the key art most depends on
- **player_visible_problem:** The warmest, most flattering hour of the day grade reads brown rather than gold.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-25
- **status_evidence:** Reported blind. Complicated since: `VISUAL-LIGHT` flipped the sun's hemisphere and made the clock continuous, and `TWO-SUNS` (`HIST-061`) records the `golden` preset's own frame being re-shot clean — but neither pass re-judged the grade, and `VISUAL-LIGHT`'s own entry says no blind pass ran. Also relevant: `HIST-167`'s note that golden hour *"blew out two-thirds of the frame at every energy tried"* under the panorama path.
- **owner_reported:** no
- **system_class:** terrain/composition (lighting)
- **likely_still_valid:** unsure — the preset moved under the finding, unjudged.

## HIST-171 — night has no moon, no horizon, and a character lit by a different rig

- **source:** `ralph/reports/VISUAL_CORRIDOR_PASS_2026-08-23.md`; `ralph/reports/VISUAL_WORLD_SURFACE_2026-08-23.md`; `ralph/reports/VISUAL_STRUCTURES_AND_GROUND_2026-08-23.md`
- **original_id:** (unnamed; three independent reports)
- **title:** *"Night is an absence, not a mood"* — and the character is exempt from it
- **player_visible_problem:** There is no moon disc in any night frame; the sky is indistinguishable from the ground so there is no horizon at all; and the trainer renders at near-daylight brightness against pitch black, *"pasted onto black paper"*, casting two divergent shadows with no visible source.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** Measured across all night frames before any change: **sky 0.0% and horizon 0.00 in every one**; near-field luminance 0.012–0.140 against 0.115–0.301 in daylight. Arithmetic account recorded rather than guessed: the night preset runs `exposure` 2.0 against day's 0.6 with `ambient_energy` 2.3, and a uniform ambient lift multiplies albedo — so it raises the trainer's bright albedo far more than a terrain whose grass albedo R9.4 deliberately darkened to value 0.199. The world-surface lane later root-caused the character half further as **an emissive material, not a lighting bug**. Recorded as **not acted on**. Distinct from `HIST-135` (whether the *transition into* night reads) and from `HIST-083` (whether the torch helps once there).
- **owner_reported:** yes in origin — `RG21`/OP23-06 are the owner's "night is too dark"; this row is the mechanism three critics named independently.
- **system_class:** terrain/composition (lighting)
- **likely_still_valid:** yes

## HIST-172 — the fires emit no light

- **source:** `ralph/reports/VISUAL_LOCATIONS_2026-08-23.md`
- **original_id:** (unnamed; locations round 1, ranked gap 3)
- **title:** *"the single cheapest coziness instrument in the toolbox is switched off"*
- **player_visible_problem:** `08-ridge-camp-fire-night` is *"pure black with an unlit campfire"*; `05-relay-camp-fire-night`'s fire is *"a faint smudge behind crates; the scene is lit by nothing."* A camp at night gives no light.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** Judged blind, against a brief whose own words are "cozy and inviting". Partly complicated by a known capture defect in a *different* pass: `GATE_D_REMAINDERS.md` §2.2 records *"a campfire with no flame, glow or smoke — embers survived the headless renderer, flame billboards and the omni light did not"*, i.e. the same symptom has a documented capture explanation. The locations critic saw it at **night**, where an omni light is exactly what would show, which is evidence the other way. **Not resolved by either pass.** `GATE-E-STRONGHOLD-ART` separately gave the stronghold garrison its own fires, which is precedent that lit fires are achievable.
- **owner_reported:** no
- **system_class:** terrain/composition (lighting)
- **likely_still_valid:** unsure — a real finding with a competing capture explanation on record.

## HIST-173 — the ground does not respond to anything standing on it

- **source:** `ralph/reports/VISUAL_LOCATIONS_2026-08-23.md` (round 1, ranked gap 1)
- **original_id:** (unnamed)
- **title:** *"Until a path enters a site and the grass dies where feet go, no site will read as a place"*
- **player_visible_problem:** Buildings and props sit on untouched uniform lawn with no path in, no wear, no enclosure and no ground-material response — in the village and at the stronghold alike.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** The locations-lane form of the standing density finding, and **sharper than it**: *"the problem is not how much grass there is, it is that the ground does not respond to the site standing on it."* That distinction matters because `HIST-041`/`HIST-024` are about quantity and this is about the terrain's own surface. Broader than `HIST-117` (the trail camp's ground-wear decal), which is one site's instance of it and is blocked on a `terrain_playground.json` capability no lane may edit.
- **owner_reported:** no
- **system_class:** terrain/composition
- **likely_still_valid:** yes

## HIST-174 — whole sites are still blockout, in frame

- **source:** `ralph/reports/VISUAL_LOCATIONS_2026-08-23.md` (round 1, ranked gap 2)
- **original_id:** (unnamed)
- **title:** The stronghold gate, the waystop's raw grey cliff, the relay plaza's tiling brick slabs
- **player_visible_problem:** *"No Palworld reference contains a single unfinished surface. The bar images are finished pictures; a third of this survey is not."*
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** The **stronghold gate** half is materially changed since: `STRONGHOLD-MAT`, `GATE-E-STRONGHOLD-ART` and `STRONGHOLD-R2` landed real textured masonry, a retint ladder, garrison fires and an approach road — all unjudged (`HIST-037`, `HIST-069`). The **waystop cliff** and the **relay plaza slabs** are not addressed anywhere found. `ACTIVE_TASKS.md`'s P4 named "dress the relay-yard greybox" as scheduled work.
- **owner_reported:** no
- **system_class:** art/asset
- **likely_still_valid:** yes — for the two sites the stronghold work did not touch.

## HIST-175 — the player renders standing on an NPC's head

- **source:** `ralph/reports/VISUAL_CORRIDOR_PASS_2026-08-23.md`
- **original_id:** (unnamed; "the finding that outranks the verdict")
- **title:** *"a ~3.5 m totem pole"*, in three of sixteen frames, across a day and a night capture in the same band
- **player_visible_problem:** The player character stands on top of a cloaked NPC, both feet planted on its crown.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** Reached blind, with no knowledge that anything was being tested, in `08-band4-ironwood-day`, `08-band4-ironwood-night` and `09-band4-ridge-day` — *"a state that survives along the route, not a one-frame fluke."* **Explicitly left undetermined:** whether a walking player can do this, or whether the capture's teleport-to-authored-coordinate drops the body onto an NPC a walking player would never land on. `VISUAL_SWEEP_LANES.md` lists "the player seated inside two captains' colliders" first among this sweep's six harness defects, which is evidence for the capture explanation — but the corridor lane that owns both did not close it. Adjacent and unresolved from a different direction: `HIST-128`, wild clusters sited without checking the routes they block.
- **owner_reported:** no
- **system_class:** terrain/composition (collision) / tooling
- **likely_still_valid:** unsure — one of two opposite answers, neither established.

## HIST-176 — the trail is ten trainer-heights wide

- **source:** `ralph/reports/VISUAL_CORRIDOR_PASS_2026-08-23.md`; re-measured in `ralph/reports/VISUAL_WORLD_SURFACE_2026-08-23.md`
- **original_id:** (unnamed)
- **title:** *"ten trainer-heights… not a footpath"*
- **player_visible_problem:** The path the player walks for 11.5 km reads as a road-width strip rather than a trail, against Palworld's 3–4 m.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** Round 1 judged 10–20 m from frames. The world-surface lane then measured it directly and **partly corrects the number**: *"The path is 6 m wide. The bald strip around it is 20 m."* So the painted path is closer to right than the critique implied, and what reads as width is the unvegetated verge — which routes it into `HIST-041`/`HIST-169` rather than into re-authoring the spine. That lane later *"narrowed paths so the verge shoulder is a real texel-wide strip for the first time"*, and **has not been rendered since** (`HIST-190`).
- **owner_reported:** no
- **system_class:** terrain/composition
- **likely_still_valid:** unsure — the diagnosis moved and the fix is unjudged.

## HIST-177 — signposts are 4.5 m telephone poles

- **source:** `ralph/reports/VISUAL_CORRIDOR_PASS_2026-08-23.md`
- **original_id:** (unnamed)
- **title:** With the plank at the very top
- **player_visible_problem:** The objects the player is meant to read for directions are twice human height with the readable part at the top, out of eyeline.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** Part of the round's scale group — *"Scale is right where props are conventional — it breaks on the authored elements."* Listed by the critic itself in the **scene-fixable** half of the split. Relevant history: OP21-18 moved signs off the travel lane (18 signposts offset), which is a siting fix and did not touch their height.
- **owner_reported:** no
- **system_class:** navigation/objectives / art
- **likely_still_valid:** yes

## HIST-178 — a text label floats in mid-air with nothing behind it

- **source:** `ralph/reports/VISUAL_CORRIDOR_PASS_2026-08-23.md`
- **original_id:** (unnamed; `09-day`)
- **title:** No signboard behind the text
- **player_visible_problem:** Words hang in the air over the meadow with no object holding them.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** Named by the critic in the scene-fixable half. No closing evidence. Possibly the same object family as `HIST-177` (a signpost whose plank did not render) but the report does not say so and neither does anything else.
- **owner_reported:** no
- **system_class:** art/asset
- **likely_still_valid:** unsure — never diagnosed.

## HIST-179 — photo-real gravel on faceted low-poly rock, beside toon trees

- **source:** `ralph/reports/VISUAL_CORRIDOR_PASS_2026-08-23.md`
- **original_id:** (unnamed; `04`)
- **title:** Two texture languages on one object
- **player_visible_problem:** A rock outcrop carries a photographic gravel texture stretched over visibly faceted low-poly triangles, standing next to painted toon trees.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** Partly addressed by a later lane from the other end: the world-surface rebuild removed every photographic scan from the terrain texture list (*"no photographic scan remains"*), but that is the **ground**, not the rock props. No pass records the rock material re-judged.
- **owner_reported:** no
- **system_class:** art/asset
- **likely_still_valid:** unsure

## HIST-180 — distant trees render near-black in daylight

- **source:** `ralph/reports/VISUAL_CORRIDOR_PASS_2026-08-23.md`
- **original_id:** (unnamed)
- **title:** The same trees are bright kelly green close up
- **player_visible_problem:** The middle distance of every wide shot is a band of near-black shapes while the foreground is bright green — so the world reads as receding into shadow on a clear day.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** Seen in frames `02`, `04` and `05`. Named by the critic in the **scene-fixable** half. Same family as, and the opposite symptom to, `GATE_D_REMAINDERS.md` §5's *"distant-LOD instances rendering white"* (`HIST-126`) — two LOD colour defects in opposite directions that no pass has reconciled, alongside `HIST-039`, `HIST-071` and `HIST-093`. Note `HIST-052`'s landmark-black finding may be a third instance of the same mechanism.
- **owner_reported:** no
- **system_class:** art/asset
- **likely_still_valid:** unsure — one of five unreconciled distant-rendering reports.

## HIST-181 — stark white unshaded terrain around the gate pylon

- **source:** `ralph/reports/VISUAL_CORRIDOR_PASS_2026-08-23.md`
- **original_id:** (unnamed; `12-day`)
- **title:** *"an unshaded patch"*, glowing again at night
- **player_visible_problem:** The ground around the Sigil gate pylon is stark white with no edge treatment, and it glows at night.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** Reported in the same frame group as the grey blockout slabs, most of which were the stronghold and have since been addressed. This one is terrain, not the stronghold, and no pass records it. Adjacent: the ground rebuild's engine limit that *"the colour map can only darken"*, which means anything reading lighter than the meadow must be a real splat surface — so a white patch is likely a surface assignment rather than a light.
- **owner_reported:** no
- **system_class:** terrain/composition
- **likely_still_valid:** unsure

## HIST-182 — eleven of twelve day frames carry the same three hue families

- **source:** `ralph/reports/VISUAL_CORRIDOR_PASS_2026-08-23.md`
- **original_id:** (unnamed; the measured palette baseline)
- **title:** Blue, chartreuse, yellow — every time
- **player_visible_problem:** The chapter's colour range does not change as the player travels, so five regions do not read as five places.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** *"That is the numeric form of the standing 'palette incoherence' finding and the baseline any groundcover or lighting change has to move."* Full table in `shots/corridor_pre/`. Corroborated from a different lane: `VISUAL_MAKE_LANE_FINDINGS` measures round-3 combat frames at **two** hue families (chartreuse 79–90%). Carried as its own row rather than folded into `HIST-107` because it is the one item in the visual programme with a stated number Gate F could re-measure rather than re-argue. The per-band ground identity that would move it is specified and unimplemented (`HIST-191`).
- **owner_reported:** no
- **system_class:** terrain/composition
- **likely_still_valid:** yes

## HIST-183 — the relay camp is props at even spacing

- **source:** `ralph/reports/VISUAL_CORRIDOR_PASS_2026-08-23.md`
- **original_id:** (unnamed; `05`)
- **title:** *"a campfire with no camp around it, a banner and a grunt with nothing to guard"*
- **player_visible_problem:** A Team Tether site on the route reads as objects placed at regular intervals on open grass rather than as somewhere an enemy is stationed.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** Set against `03-day`, which the same critic calls *"the one composed frame in the set… it proves the team can do it."* `SITE-DRESSING` landed since (bands 2/3/4 `props.json`), and `ACTIVE_TASKS.md`'s P4 named "cluster/de-symmetrise picket, quarry and mill props" as scheduled work — neither is recorded as re-judged against this frame.
- **owner_reported:** no
- **system_class:** terrain/composition
- **likely_still_valid:** unsure — plausibly addressed by SITE-DRESSING, unjudged.

## HIST-184 — faces do not survive meeting distance

- **source:** `ralph/reports/VISUAL_VIS_CAST_2026-08-23.md` (D4 round 2, ranked 2)
- **original_id:** (unnamed)
- **title:** The Warden's eyes read as two dark hollows; everyone else wears the same vinyl-doll face
- **player_visible_problem:** At the distance a player actually stands to talk to someone, the antagonist reads as eyeless and the villagers and Team Tether bodies share one blank face.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** Reported in round 1 (*"at gameplay distance he reads as eyeless"*) and again in round 2 after a full material pass. The round-2 critic calls the facial language **a mesh gap, not a paint gap**, which places it against `CLAUDE.md`'s humanoid rules — `docs/art/HUMANOID_ASSET_INVENTORY.md` is authoritative, a new humanoid mesh is exceptional, and any generation needs owner-supplied reference art. `CLAUDE.md` also states the Warden was already rebuilt from the owner's board-16 sheet and that historical claims his face is unmodelled must not be reopened — so this row is deliberately about the **rendered read at distance**, not about whether the face is modelled.
- **owner_reported:** no
- **system_class:** art/asset
- **likely_still_valid:** yes

## HIST-185 — the villager male has orange streaks on one sock

- **source:** `ralph/reports/VISUAL_VIS_CAST_2026-08-23.md` (D4 round 2, item 5)
- **original_id:** (unnamed)
- **title:** A mesh interpenetration, not a texture bug — diagnosed, not fixed
- **player_visible_problem:** Bright flame-like orange streaks across one of a villager's socks.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** **Diagnosed precisely because two rounds had called it "an orange emissive scribble" and a repaint would not have touched it.** `villager_male_lod0.glb` carries two meshes — `char1` (body, 14,257 verts, `Material_1`/`texture_0`) and a separate `trousers` (3,741 verts, `Trousers`/`trousers_tex`). The sock belongs to the body. `texture_0` contains **zero** orange pixels (0 of 4,194,304 by a stated filter), so nothing painted on the sock is orange — but the streaks measure (191,127,64) against the trousers leather's own (204,132,67). It is the trouser hem showing through the sock; both materials are self-lit (`emissiveFactor [1,1,1]` with an emissive texture each), which is why it reads as bright streaks rather than a dull clip; and it appears on one leg only, which points at the idle pose. *"Fix is a mesh or skinning correction on the trousers hem, or a depth/priority change on that material — not a repaint."* Recorded as diagnosed; no entry records it fixed.
- **owner_reported:** no
- **system_class:** art/asset
- **likely_still_valid:** yes

## HIST-186 — the Warden's cape lining renders as a translucent membrane

- **source:** `ralph/reports/VISUAL_VIS_CAST_2026-08-23.md` (D4 round 2, item 4)
- **original_id:** (unnamed)
- **title:** An alpha/material artefact on the chapter's antagonist
- **player_visible_problem:** The Warden's cape lining is see-through.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** Listed as still open in the round's own ranked verdict, below the three-art-languages and faces findings. No later entry records it. Adjacent precedent worth having: `VISUAL_LEDGER.md`'s standing "metallic in this renderer" entry, which records four separate defects diagnosed as colour problems that were all a missing or wrong material factor — *"check for a metallic value before treating any 'wrong colour' as a colour."*
- **owner_reported:** no
- **system_class:** art/asset
- **likely_still_valid:** yes

## HIST-187 — the three named captains are one person three times

- **source:** `ralph/reports/VISUAL_VIS_CAST_2026-08-23.md` (D4 round 2, item 3)
- **original_id:** (unnamed)
- **title:** Deliberate, recorded, and needing a dial that is not the faction colour
- **player_visible_problem:** Riverwatch, Field and Ridge — three separate captain fights the player travels between — are visually the same person.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** Recorded as **deliberate and documented in the band files**: the rigs carry one fused material, so the body palette is the only dial, and it is spent on faction identity. Measured: three accents held inside one reserved colour at one luminance moved the rendered torso by **1–5 points per channel** — *"not a difference a player can see."* So the lane did the work and the work cannot land. *"Real per-site separation needs a dial that is not the faction colour."* Pairs with `HIST-104`, which records the same three captains not escalating in difficulty — so they are neither visually nor mechanically distinguished.
- **owner_reported:** no
- **system_class:** art/asset / creature attachment
- **likely_still_valid:** yes

## HIST-188 — the roster is two art packs wearing one logo

- **source:** `ralph/reports/VISUAL_CAST_AND_ROSTER_2026-08-23.md` (D3 round 1); still the top-three item in round 3 per `ralph/reports/VISUAL_VIS_CAST_2026-08-23.md`
- **original_id:** (unnamed)
- **title:** Photoreal wildlife recolours beside glossy chibi toys
- **player_visible_problem:** About twelve species are a cohesive mascot family; five — bramblebun, trailpup, duskhush, galecrest, brooktail — are realistic wildlife with a green tint and read as **sourced**: *"Bramblebun is 'a rabbit, but the ears are green'."* Paddlenewt reads as *"a baby Toothless — a player will name the reference before they name the species."*
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** Named in round 1 and still the round-3 verdict's own top-three item, *"called not fixable by paint."* Round 4's structures/combat critic reported the same thing independently: *"The Bramblebun is a different game's art… a near-photoreal brown rabbit with leaf ears added"* beside the painterly Terrapup. VIS-CAST's summary says *"See `ralph/BLOCKED.md`"* — **but `BLOCKED.md`'s VIS-CAST section carries four numbered roster items and this is not one of them**, so the pointer leads nowhere and this item has had no home until now. The critic also insisted the good news be stated plainly: the twelve-species core *"holds up beside Palworld, and I want that said clearly, because it is the best news in the survey."*
- **owner_reported:** no
- **system_class:** creature attachment / art
- **likely_still_valid:** yes — and it is the clearest instance this sweep found of a finding that fell through a cross-reference.

## HIST-189 — the same species renders at two sizes in one scene

- **source:** `ralph/reports/VISUAL_MAKE_ROUND2_2026-08-23.md`
- **original_id:** (unnamed)
- **title:** The engaged Bramblebun and the roaming one differ by ~2×
- **player_visible_problem:** A creature the player is fighting is twice the size of the same creature standing behind it.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** One line in round 2's new-defects list, never followed up. Candidate mechanisms exist in the repo and neither is confirmed: `creature_body.apply_size_multiplier()` (the alpha path, 1.3×/1.4×) and the round-1 finding that species models disagree about where their origin sits. Not the same as `HIST-115`'s roster-span question, which is about the authored heights.
- **owner_reported:** no
- **system_class:** creature attachment
- **likely_still_valid:** unsure — one observation, never reproduced.

## HIST-190 — the ground rebuild's last round has never been rendered

- **source:** `ralph/reports/VISUAL_WORLD_SURFACE_2026-08-23.md` ("State at handover", and the partial-bake warning)
- **original_id:** (unnamed; VIS-WORLD handover)
- **title:** *"First action next session: capture band 1 and look, before anything else is changed"*
- **player_visible_problem:** The ground the player walks on for the whole chapter was rebuilt from scratch on six generated surfaces and the last set of changes has never been looked at — including a `verge_cut` correction whose predecessor is visible in the last committed frames as a sandy overshoot.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-25
- **status_evidence:** The lane hands over explicitly mid-pass. It also warns that **the committed terrain was a PARTIAL bake** — 4 (later 10) of 64 regions on the new material, the rest on the old, with *"a hard material seam at every boundary between them"* — and gives the exact commands and the 43-minute cost of the full bake before the branch is merged or judged. **Partly refuted at this SHA:** `data/terrain/playground/` holds 64 region files and the branch landed through the consolidation with the scatter/veg tests green, which is consistent with a full bake having been run; a file count does not prove every region carries the new material, and nothing found states it either way. The *unrendered* half is not refuted at all.
- **owner_reported:** no
- **system_class:** terrain/composition
- **likely_still_valid:** yes — for the unrendered half; unsure for the partial bake.

## HIST-191 — per-band ground identity is specified and not implemented

- **source:** `ralph/reports/VISUAL_WORLD_SURFACE_2026-08-23.md` ("State at handover", item 2)
- **original_id:** (unnamed; work-order item C3)
- **title:** Five z-ranged colour grades with 150 m feathering
- **player_visible_problem:** Every band's ground is the same ground, so travelling from the Lower Meadows to the Ironwood does not change what the player is walking on. This is the mechanism behind `HIST-182`'s three-hue measurement.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** *"specified in full… and not implemented."* Deliberately designed as a colour-map grade rather than five more splat surfaces, *"because every surface added multiplies the 2 m boundary problem"* (`HIST-193`). Bounded by a measured engine limit recorded in the same file: **the colour map can only darken**, because Terrain3D multiplies by it — so anything that must read lighter than the meadow has to be a real splat surface.
- **owner_reported:** no
- **system_class:** terrain/composition
- **likely_still_valid:** yes

## HIST-192 — `forest_floor` is generated, wired and unplaced

- **source:** `ralph/reports/VISUAL_WORLD_SURFACE_2026-08-23.md` ("State at handover", item 3)
- **original_id:** (unnamed)
- **title:** A surface that exists and appears nowhere
- **player_visible_problem:** Under the canopy the ground is the same open-meadow grass as the fields, so woodland does not read as woodland.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** *"It needs canopy-driven placement, which needs the terrain bake to know where the oaks are — the scatter runs in a separate pass, so this is real integration work, not a number."* Third instance in this register of the repo's recurring "written, tested, and inert" pattern, after `HIST-066` (PERF-LOD) and the `GATEC-CURVE` wild-band note. `BAND2-FLOOR` landed hand-sited forest-floor dressing for band 2, which is the content half of the same gap by a different route.
- **owner_reported:** no
- **system_class:** terrain/composition
- **likely_still_valid:** yes

## HIST-193 — the 2 m control-map cell is visible on long diagonals

- **source:** `ralph/reports/VISUAL_WORLD_SURFACE_2026-08-23.md` ("State at handover", item 4 and the engine limits)
- **original_id:** (unnamed)
- **title:** A partial control blend does not draw — verified three ways
- **player_visible_problem:** Where two ground surfaces meet, the boundary is a stair of 2 m squares rather than a blend, and steep rock/verge faces still read as blocky.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** Verified three ways with a magenta test texture. *"This is why the ground is built from hard 2 m assignments with dithered thresholds instead of blended transitions, and it is what defeated four rounds of EV4-hillside-seam-remainder before this sweep."* Reduced by a hash dither, not eliminated: *"A viewer looking for the 2 m cell will still find it on long diagonals."* Removing it needs a higher-resolution control map or shader-level boundary blending. Recorded here as a **bound with a visible consequence**, not as a defect with a fix. Plausibly the same thing `HIST-151` measured from the combat lane's side.
- **owner_reported:** no
- **system_class:** terrain/composition (engine bound)
- **likely_still_valid:** yes

## HIST-194 — the oaks are the wrong colour in three ways

- **source:** `ralph/reports/VISUAL_STRUCTURES_AND_GROUND_2026-08-23.md`
- **original_id:** (unnamed; D5 round 1)
- **title:** Near-black canopies, blue and maroon leaf cards, salmon-pink trunks
- **player_visible_problem:** The hero trees have near-black canopies with individual blue and maroon leaf cards in them, on salmon-pink trunks, at 6–7 m.
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** Three distinct claims, differently supported. **Trunk colour** is partly explained and deliberately parked — `GATE_D_REMAINDERS.md` §7 records the bone-grey `Bark_TwistedTree` retint (`#918178`) as solved from a measured per-channel gain and explicitly not to be changed on one band's evidence (`HIST-127`); "salmon-pink" is a different reading of the same value. **Height** is `HIST-121`'s asset ceiling, and `VISUAL-GROUNDCOVER` landmark-scaled two band-4 hero trees. **Blue and maroon leaf cards** is not addressed anywhere and is the one that reads as a straightforward material or variant bug — `vegetation.json`'s `grove` layer carries a three-step green variant family and a documented history of the crimson `Leaves_TwistedTree_C` leaking through unswapped keys (see `HIST-009`).
- **owner_reported:** no
- **system_class:** art/asset
- **likely_still_valid:** unsure — one of three claims is live and unexamined; the other two are parked with reasons.

## HIST-200 — partnered traversal abilities: an owner decision nothing tracks

- **source:** `ralph/planning/MEADOWS_QUALITY_REBUILD_PLAN.md` §10
- **original_id:** `PW1`
- **title:** **OWNER DECISION REQUIRED BEFORE BUILDING** — and no queue entry anywhere
- **player_visible_problem:** Whether a creature in the party can open shortcuts, secrets, alternate routes, optional resource areas, optional alpha encounters or alternate dungeon entrances — i.e. whether the five-creature roster choice affects exploration at all, or only combat.
- **date_opened:** before 2026-08-17 · **last_touched:** unchanged since the owner revised the plan
- **status_evidence:** **`PW1` returns zero hits across `ralph/BACKLOG.md`, `ralph/DONE.md`, `ralph/ACTIVE_TASKS.md` and `ralph/ACTIVE_GAME_PLAN.md`** — grepped at this SHA. It exists only in the planning document, which is exactly the failure the backlog's own Phase 6.5 header records happening to `MQ2B`/`MQ3`/`PW2` (*"the largest block of remaining work on the project sat in a planning document with no entry anywhere in the queue"*). The plan carries a worked recommended direction if approved (shortcuts, secrets, alternate routes; glide from a ridge, cross a small optional water route, dig a shortcut, reach a ledge, bypass a long return) and one hard constraint: *"Do not make the critical Meadows storyline permanently depend on owning a specific pal unless the design also guarantees the player cannot softlock themselves through the five-pal permanent-roster rule."*
- **owner_reported:** no — it is a decision **awaiting** the owner, which is a different thing and is why it must not be quietly dropped.
- **system_class:** progression/economy (traversal design)
- **likely_still_valid:** yes — undecided, untracked, and named in the plan's §18 as still required.

## HIST-201 — the sixth-creature release has a direction and no lasting meaning

- **source:** `ralph/planning/MEADOWS_QUALITY_REBUILD_PLAN.md` §11
- **original_id:** `PW3`
- **title:** **DO NOT IMPLEMENT A STAT-TRIBUTE SYSTEM** — and no queue entry anywhere
- **player_visible_problem:** Releasing a creature to make room for a sixth is described as *"one of Tetherbound's distinctive emotional mechanics"*, and once the array slot is cleared nothing in the world remembers it happened.
- **date_opened:** before 2026-08-17 · **last_touched:** unchanged since the owner revised the plan
- **status_evidence:** **`PW3` returns zero hits** across the four queue files, same as `HIST-200`. The plan sets a firm negative direction — do not convert released creatures into permanent combat statistics or upgrade fuel, because *"that would incentivize catching creatures specifically to sacrifice them and undermine the intended emotional release choice"* — and names the preferred non-power alternatives: journal/memory entry, camp keepsake, record of name and release location, a later sighting, relationship history, cosmetic remembrance. The superseded draft plan is explicit that the owner **overrode** an earlier AI proposal for a tribute mechanic, so the negative half is a recorded owner decision. What is untracked is the positive half. Partly related: `R4.10`'s ceremony exists and ran live in the Gate F finale (`HIST-108`), and `DONE.md` records *"No per-creature history, so the release ceremony had nothing to surface"* — which is this gap seen from the ceremony's side.
- **owner_reported:** yes in part — the negative direction is an owner override on record.
- **system_class:** creature attachment
- **likely_still_valid:** yes

## HIST-202 — no rule stops a captain fight being the same fight in a different room

- **source:** `ralph/planning/MEADOWS_QUALITY_REBUILD_PLAN.md` §9
- **original_id:** `PW4`
- **title:** Signature dungeon and captain encounters — and no queue entry anywhere
- **player_visible_problem:** *"No major dungeon or captain fight should reduce to: same standard fight in a different room with more HP."* Each major encounter is supposed to have one strong identity.
- **date_opened:** before 2026-08-17 · **last_touched:** unchanged
- **status_evidence:** **`PW4` returns zero hits** across the four queue files. The plan gives a scope discipline that makes it cheap — prefer recombining mechanics the player already understands (terrain forcing repositioning, attack windows tied to cover, environmental hazards, vertical arena structure, changing safe zones, adds/priority targets, destructible elements, movement timing, type interaction expressed spatially) and *"avoid building an entire bespoke system used once"* — and an acceptance test in player terms: *"A blind player can describe what made each captain/dungeon mechanically memorable without answering only 'it was harder', 'it had more health', 'it looked different'."* Directly compounds two rows already in this register: `HIST-104` (the three Sigil captains do not escalate) and `HIST-187` (they are visually one person three times).
- **owner_reported:** no
- **system_class:** combat/camera (encounter design)
- **likely_still_valid:** yes

## HIST-203 — four owner decisions the plan says are still required

- **source:** `ralph/planning/MEADOWS_QUALITY_REBUILD_PLAN.md` §18
- **original_id:** (unnamed; the plan's own owner-decision block)
- **title:** *"Do not invent answers to these"*
- **player_visible_problem:** Four questions that shape what the chapter is: whether partnered traversal exists at all and whether it may gate critical progress; whether catching gets a probability floor; and whether the release mechanic gets any mechanical reinterpretation.
- **date_opened:** before 2026-08-17 · **last_touched:** unchanged
- **status_evidence:** Verbatim: (1) approve/reject `PW1`; (2) if approved, define whether Meadows traversal abilities are optional/shortcut-only or can gate critical progress; (3) any future catch-floor mechanic after fresh play evidence; (4) any mechanical reinterpretation of the sixth-pal release beyond the non-power remembrance direction. **None appears in `ralph/BLOCKED.md`**, which is the repo's designated home for owner-blocking questions and which `CLAUDE.md` says a firing has done its job by adding to. (1) and (2) are `HIST-200`; (4) is `HIST-201`. **(3) is the one this row exists for**, and the plan is precise about it in a way that matters to Gate F: do not implement a catch floor because an older complaint asked for one — first determine whether the frustration is aim, trajectory readability, odds, odds communication, early orb supply, practice-creature tuning, HP tuning or feedback, and *"a global catch floor becomes an owner decision only if fresh evidence shows the existing design still creates a bad early-game experience."* That is `HIST-048`'s open question with a decision procedure attached.
- **owner_reported:** no — awaiting the owner.
- **system_class:** other (decisions)
- **likely_still_valid:** yes

## HIST-204 — the game has essentially no world audio

- **source:** `ralph/planning/TETHERBOUND_OWNER_ONLY_FULL_BLIND_PLAYTEST.md` §30; verified in the working tree
- **original_id:** (none — this item has no ID anywhere in the repo)
- **title:** Nine UI cues exist; footsteps, gathering, combat, hits, catches, crafting, building, dialogue, ambience and music do not
- **player_visible_problem:** Actions occur on screen and make no sound. The owner's own manual playtest protocol lists fourteen audio surfaces to evaluate and instructs *"Look for actions that visually occur but feel dead because they lack sound or feedback."*
- **date_opened:** never opened · **last_touched:** n/a
- **status_evidence:** **Verified at this SHA rather than inferred.** `scripts/ui/audio_cues.gd` is the only file in the project that touches `AudioStreamPlayer`; it implements spec 20's *"small UI audio set. One shared player, nine short cues"* and is called from `game_menu.gd`, `build_menu.gd`, `build_placer.gd` and `playground_hud.gd`. The nine `.wav` files under `assets/ui/audio/` (`ui_focus`, `ui_accept`, `ui_cancel`, `ui_tab`, `ui_error`, `build_place`, `build_snap`, `capture_success`, `aim_enter`) are the **only** audio files anywhere under `assets/`. Separately: **`grep -in "audio|sound effect|music"` over `ralph/BACKLOG.md` and `ralph/ACTIVE_GAME_PLAN.md` returns nothing at all** — the active ledger and the gate plan do not mention audio in any form, so this is not a deprioritised item, it is an unenumerated one. `ralph/VISUAL_LEDGER.md`'s eight domains are all visual by construction, so the standing whole-game sweep does not cover it either.
- **owner_reported:** no directly — but the owner authored the protocol that lists it, and `GATE_F_PROTOCOL.md`'s §18 exit question (*"what would make them confused, bored, frustrated, distrust the game, or stop playing"*) is the kind a silent game answers badly.
- **system_class:** other (audio)
- **likely_still_valid:** yes — and it is the single largest wholly-unenumerated gap this sweep found.

## HIST-205 — the macro-world redesign has no queue entry of its own

- **source:** `ralph/planning/MEADOWS_QUALITY_REBUILD_PLAN.md` §5
- **original_id:** `MQ2A`
- **title:** Referenced as a pointer, never transcribed as an item
- **player_visible_problem:** The plan's world-shape brief — core structure, scale philosophy, interesting-decision density, regional identity, navigation, camps, day span — is what decides whether the corridor reads as a journey rather than a long walk.
- **date_opened:** before 2026-08-17 · **last_touched:** 2026-08-17
- **status_evidence:** Unlike `PW1`/`PW3`/`PW4` this one is not invisible — but it has never been an item. `BACKLOG.md:2518` cites it only as a *"read §5 before starting"* pointer under `OW5`, and `DONE.md:4845` records a lane authoring *"the corridor plan `MQ2A` §5 asks for"*. So the layout was executed through `OW5A`–`OW5E` and the plan section itself was never converted into an entry with acceptance criteria. Its per-section content (regional identity, interesting-decision density, camps, day span) is the direct ancestor of several rows already here — `HIST-046`, `HIST-105`, `HIST-182`, `HIST-191` — which is evidence the section is still describing live gaps rather than finished work.
- **owner_reported:** no
- **system_class:** terrain/composition (content)
- **likely_still_valid:** unsure — substantially executed by a different route; never checked against its own criteria.

## HIST-208 — picking something up says nothing

- **source:** `ralph/OWNER_PLAYTEST_2026-08-18.md` OP3; prompt `docs/ralph-prompts/44-GATHER-equipped-tool-swing-and-pickup-feedback.md`
- **original_id:** `OP3` (second half)
- **title:** *"Picking up harvested resources must show concise gain feedback such as `+3 Wood`"*
- **player_visible_problem:** The player chops, gathers, and the only way to know what they got is to open the satchel.
- **date_opened:** 2026-08-18 · **last_touched:** 2026-08-18
- **status_evidence:** **The first half of OP3 has a closing record and this half does not.** The swing half is closed: `RG2` landed the hit cone fix (`c9870df7`), `RG9`/`RG10` split chop-then-gather (`210c1ae5`), and `STRANDED-P3` landed the OP21-24 chop clip. For the gain feedback, a working-tree search at this SHA for `+%d`-style gain strings, `picked up`, `gained`, and for any notice/toast/announce entry point on `playground_hud.gd` returns **nothing**. `PROMPT_COMPATIBILITY_MAP.md` routes the legacy `41-OP-HARVEST-*` brief into prompt 44 *"+ Gate A/B evidence"*, and Gate A/B evidence asserts that gathering *succeeds*, not that the player is told.
- **owner_reported:** yes (OP3)
- **system_class:** UI architecture
- **likely_still_valid:** yes — verified absent in code, not inferred from prose.

---

# Section 2 (continued) — not player-facing, added by the second sweep

## HIST-195 — the combat capture cannot photograph any sub-second event
- **source:** `ralph/reports/VISUAL_COMBAT_CAPTURE_MECHANISM_2026-08-23.md` · **original_id:** (unnamed; "the seventh harness failure")
- **player_visible_problem:** none — but it cost three blind rounds their headline finding, and its verdict is that *"nothing in the round-1 combat critique's headline should be actioned as art or gameplay work. The frames were honest; the labels on them were not."* `translated: yes`
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** Arithmetic, not timing luck. Physics runs at 60 Hz with `max_physics_steps_per_frame` 8, and one rendered frame costs ~2.4 s under llvmpipe — so one rendered frame is 2.4 s of `_process` time but at most 0.133 s of simulated time. `_shoot_pair()` waits two **process** frames, a ~4.8 s floor on every shot. Against that, `move_projectile.gd` runs on `_process` and clamps its whole flight to `MAX_TRAVEL` 0.42 s, so its first tick lands `t = 2.4/0.42 = 5.7`, clamps to 1.0, emits `arrived` and frees itself — *"the node has been freed for roughly two rendered frames before the shutter opens. No wait value could have saved it."* The attack pose and flinch fail on the same clock. Every element the critic missed (`move_projectile.gd`, `impact_flash.gd`, `telegraph_glow.gd`, `play_attack()`, `play_hit()`) is built, wired and fires in a real fight. Not recorded as fixed.
- **owner_reported:** no · **system_class:** tooling/CI · **likely_still_valid:** yes

## HIST-196 — the icon sheet has been cropped in every round that judged it
- **source:** `ralph/reports/VISUAL_MAKE_ROUND2_2026-08-23.md` · **original_id:** (unnamed)
- **player_visible_problem:** none — but *"every icon finding in rounds 1 and 2 covers less than half the set"*, on the screen the player opens most. `translated: yes`
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** *"Header claims 55 items; roughly 26 tiles are visible and the sheet is cut off mid-way through the GEAR row."* Round 1 hit it, a viewport-height fix went in the same day (2200 → 2800 px), `VISUAL_LEDGER.md` records the crop as fixed, **and round 2 hit it again** — *"It was not enough."* Directly bounds `HIST-004` and `HIST-156`: both are conclusions about an item set half of which has never been photographed.
- **owner_reported:** no · **system_class:** tooling/CI · **likely_still_valid:** unsure — one fix landed and was insufficient; no round since has confirmed the full sheet.

## HIST-197 — the locations `detail` rig composes shots about the dirt
- **source:** `ralph/reports/VISUAL_LOCATIONS_2026-08-23.md` · **original_id:** (unnamed)
- **player_visible_problem:** none. Five of forty-five frames do not show their subject: a mill-crossing yard shot at a grazing angle to bare terrain, a "fire" detail shot with the fire cut off the bottom edge, two frames ~70% empty sky, and one where an NPC interpenetrates the trainer. `translated: yes`
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** Root-caused: *"The `detail` rig aims 1.6 m above the target's ground from 5 m back, which composes a shot about the dirt when the subject is a fire on the ground or an apparatus on a 10 m deck."* The lane's own instruction: *"Round 2 must fix the rig before it re-judges the sites, or it will re-photograph its own framing."* Round 2 of that lane is not in evidence. Also recorded from the same pass: `_clear_of_bodies()` protects the player's seat but does not stop an NPC standing where the player was put afterwards.
- **owner_reported:** no · **system_class:** tooling/CI · **likely_still_valid:** yes

## HIST-198 — the standing count of capture artefacts, and the discipline it implies
- **source:** `ralph/reports/VISUAL_UI_2026-08-23-round2.md`; `ralph/VISUAL_LEDGER.md`; `ralph/lanes/VISUAL_SWEEP_LANES.md`; `ralph/GATE_D_REMAINDERS.md` §2
- **original_id:** (unnamed)
- **player_visible_problem:** none directly. This row exists because the ratio is the most decision-relevant number the visual programme produced and it lives in four files with four different counts. `translated: yes`
- **date_opened:** 2026-08-22 · **last_touched:** 2026-08-23
- **status_evidence:** D2 alone reached **eight** diagnosed artefacts (the layer-0 backdrop painting over the widget; the keyboard-pinned device; a null `current_scene` taking out the minimap, the world map, the combat-state check and the pause menu's own HUD hiding at once; the combat camera never following the player into the fight; eleven screens shot with no world behind them; the creature turntables spinning ~69° per awaited frame). `VISUAL_LEDGER.md` counts six across all domains; `GATE_D_REMAINDERS.md` §2 counts five more in the Gate D lanes; `VIS-CAST` adds a seventh *shape* — photographing the right subject **wrongly**, a stage over-exposing every creature by a measured 2.3× that three consecutive blind rounds spent their top finding on. **The durable output is the rule, and it is already written down twice:** a defect seen only in a survey frame must be reproduced through a second path before acting on it, and *"a fix that lives in one tool does not protect the next tool that does the same thing."* Carried because §16.4's coverage-defect loop will need it: several rows in Section 1 are one reproduction away from being retired.
- **owner_reported:** no · **system_class:** tooling/CI · **likely_still_valid:** yes

## HIST-199 — `--check-only` proves syntax, not behaviour
- **source:** `ralph/reports/VISUAL_UI_2026-08-23-round2.md` · **original_id:** (unnamed)
- **player_visible_problem:** none directly — but it shipped an empty crafting list to a blind critic, who reported it as a design defect two rounds later. `translated: yes`
- **date_opened:** 2026-08-23 · **last_touched:** 2026-08-23
- **status_evidence:** A fix set `cost_label.text_overflow_behavior`; Godot 4 spells it `text_overrun_behavior`. The file parse-checked clean, shipped, and the unknown property threw mid-`_make_row()`, which aborted the function, returned null, and **silently emptied the entire craft recipe list**. The lane's conclusion: *"the only things that would have caught this were a test asserting the property took effect, or a render. Treat `--check-only` as necessary and never sufficient for anything that sets a property by name."* Same family as `HIST-088` (`TEST2`) and as the lane's other recorded error — a confidently-published wrong diagnosis (`Control.scale` pivot maths) that `HIST-011` corrects. Nothing enforces either lesson.
- **owner_reported:** no · **system_class:** tooling/CI (test integrity) · **likely_still_valid:** yes

## HIST-206 — the plan's per-region quality gates have never been applied as a gate
- **source:** `ralph/planning/MEADOWS_QUALITY_REBUILD_PLAN.md` §13 · **original_id:** (unnamed)
- **player_visible_problem:** none directly; it is the readiness bar the five D regions were meant to clear. `translated: yes`
- **date_opened:** before 2026-08-17 · **last_touched:** 2026-08-17
- **status_evidence:** §13 lists six categories every region should pass before being considered production-ready — geography, navigation, content density, visual quality, gameplay, blind test. The D1–D5 packages each ran their own evidence criteria from `ACTIVE_GAME_PLAN.md` instead, and `GATE_D_REMAINDERS.md` §4 records the resulting shape: *"That is plausible and it is also the lane assessing its own ceiling."* No document records any region checked against §13's list. Distinct from `HIST-094` (`MQ2B`, the blind-critic stopping rule), which is one of §13's six categories rather than the whole gate.
- **owner_reported:** yes in origin — it is the owner's own revised plan.
- **system_class:** other (process) · **likely_still_valid:** unsure — plausibly satisfied piecemeal; never checked as a gate.

## HIST-207 — `ralph/ledger/` is a dashboard frozen at a two-week-old commit
- **source:** `ralph/ledger/data/meta.json`, `ralph/ledger/dashboard.html` · **original_id:** (unnamed)
- **player_visible_problem:** none. `translated: yes`
- **date_opened:** 2026-08-12 (the snapshot) · **last_touched:** 2026-08-12
- **status_evidence:** `meta.json` reads `{"sha": "395b514e", "snapshot": "2026-08-12 10:57 UTC"}`. The generated `dashboard.html` (52 KB) and its `data/*.json` therefore describe a project state thirteen days stale at this SHA, including a `blocked.json` whose entries are largely `✅`-resolved in `BLOCKED.md` and a `gates.json` listing play gates the owner **retired on 2026-08-16**. `REGENERATE.md` and `generate_ledger.py` exist, so it is regenerable and nobody has. Carried because a stale dashboard that looks authoritative is the same hazard as stale backlog prose, which is what `HIST-100` and `HIST-133` are about — and because this sweep opened the directory only after the coordinator insisted, which is itself the evidence that it is not being read.
- **owner_reported:** no · **system_class:** other (bookkeeping) · **likely_still_valid:** yes

---

# Section 3 (continued) — superseded/obsolete candidates from the second sweep

## HIST-209 — the stronghold's art is standing 7,708 metres from the stronghold
- **source:** `ralph/reports/VISUAL_LOCATIONS_2026-08-23.md`; `ralph/reports/VISUAL_STRUCTURES_AND_GROUND_2026-08-23.md` ("RULED — a siting bug, not a material bug")
- **player_visible_problem (for the record):** two buildings answered to "the stronghold" and the good one was not the one the player walks to. `landmark.gd` built a 132-module assembled castle — crenellated curtain walls, four corner towers, a two-module gate with a door leaf, nine oxblood banners, warm cream masonry — at `RISE_CENTRE + OFFSET` = **(229.8, −144.4)**, while the stronghold the player reaches was five `BoxMesh` chambers under three flat colours at **(0, 7560)**. `stronghold_occupation.json`'s 14 braziers, 4 tether lamps, 5 sky-fill lights and 21-prop camp were attached to the legacy castle too. Frames from the same afternoon, same renderer, showed both.
- **superseding evidence:** **Refuted in the working tree at this SHA.** `scripts/world/landmark.gd` now carries `const SITE := Vector2(150.0, 7595.0)` — beside the real stronghold — with its own header recording the history block *"for why the old `RISE_CENTRE + OFFSET` site stopped"* and stating that `RISE_CENTRE`/`OFFSET` *"no longer drive anything"*. `scripts/world/stronghold_occupation.gd` is now referenced by `stronghold.gd` as well as `landmark.gd`, so the dressing is no longer attached only to the legacy site. Landed through the `GATE-E2` / `STRONGHOLD-R2` / `GATE-E-STRONGHOLD-ART` lineage.
- **caveat:** the re-sited silhouette has **never been blind-judged** — that is `HIST-037`, which stays open. This row retires the siting bug, not the question of whether the result looks right.
- **candidate category:** OBSOLETE (already fixed)

## HIST-210 — "nothing populates the open corridor"
- **source:** `ralph/reports/VISUAL_WORLD_SURFACE_2026-08-23.md` ("Outside this lane, unfixed, and worth routing")
- **claim (for the record):** *"`spawn_wild()`'s only caller in `scripts/` is the Burrow Warrens dungeon, so a survey that stands the player on the trail has nothing to photograph. Two blind critics have ranked the resulting emptiness second overall."*
- **superseding evidence:** **The premise is true and the conclusion is wrong.** `spawn_wild()` genuinely has one caller (`burrow_warrens.gd`, which uses it because a dungeon should not stream) — but that is not the path that populates the corridor. `encounter_director.gd::_spawn_creatures()` builds the world's wild population from the band `spawns.json` files, and `GATE_F_EVIDENCE_2026-08-23.md` measured the result three times byte-identically: **909 wild bodies in the world, 503 within 30 m of the route, 12 distinct species, 0 underground.** So the corridor is populated and a survey standing on the trail has plenty to photograph.
- **caveat:** the **perceived** emptiness two critics ranked second is real and is not retired by this — it is `HIST-024`, `HIST-041` and `HIST-173`, none of which is about creature count. What is retired is the proposed mechanism.
- **candidate category:** OBSOLETE (refuted by measurement; the symptom is carried elsewhere)

---

# Amendments to rows written in the first pass

Two rows are contradicted by evidence found in this sweep. Both are amended in
place below rather than edited silently, per the coordinator's instruction.

## Amendment to HIST-053 — AMENDED 2026-08-25: it was worse than recorded, and it is fixed

The first pass wrote `likely_still_valid: unsure`, with the reason *"it may well
work and simply never have been read off screen."* **Both halves of that are
wrong.** A targeted grep of `DONE.md` for this item's own subject — not a cold
read — found `GATE-E-LOGIC`'s entry:

> **Every level-up in the chapter aborted its own announcement.**
> `combat_hud.gd::_set_xp_line` read `creature.get("bond_nodes")`; that is a
> METHOD, so `get()` returned a Callable and `int(Callable)` killed the function
> with "Nonexistent 'int' constructor" — the player never saw the line.
> `test_level_up_announcement.gd` asserted on the SOURCE TEXT of that function
> and stayed green through all of it (prompt 33's exact shape). Fixed, and the
> test now also executes the builder.

So the defect was real and total across the whole chapter, and it is closed with
a named root cause and a strengthened test. **Revised `likely_still_valid`: no.**

Two things survive the amendment and are why the row is not deleted. First, OP11
asks for three things — identity, new level, **and any meaningful unlock** — and
the fix is described as restoring the XP line; whether the unlock half is
announced is not stated. Second, this is a textbook instance of `HIST-088`
(`TEST2`): a test that asserted on source text and stayed green through a total
failure of the thing it names. That pattern is not retired by fixing one
instance of it.

## Amendment to HIST-091 — AMENDED 2026-08-25: reproduced, root-caused and fixed

The first pass wrote `likely_still_valid: unsure`, reasoning that CI had been
rebuilt and `verify-boss` no longer appears by that name. The real answer is in
`DONE.md`'s `GATE-E-LOGIC` entry, under the heading **"Prompt 34 (boss
verification flake) — REPRODUCED, root-caused, fixed"**: a push was green
locally and red on GitHub's runner (CI 2169) with *"the elite's fight never
resolved inside 9000 frames (5 quick attacks landed, 0 missed)"*. **Zero misses
is the tell** — the swing was never attempted, so it was never a whiff and never
a budget — and it was root-caused on a probe of the elite fight alone to bodies
being held above the terrain (`elite body y=8.56, floor y=8.56, terrain y=1.37`),
the same defect that produced the owner's OP21-25 report about fights phasing
outside reachable arena bounds.

**Revised `likely_still_valid`: no.** What survives: the entry's standing
instruction — *"Do not just raise the frame budget"* — is corroborated six more
times by the 2026-08-25 handover's pattern (*"a budget or a bounded search that
could never succeed, filed as an intermittent flake"*), and nothing enforces it.
That lesson is carried by `HIST-088` and `HIST-198`, not by this row.

---

# `OP1`–`OP16`: the inference resolved

The first pass carried eleven of the sixteen 2026-08-18 owner items as closed
**by inference from `PROMPT_COMPATIBILITY_MAP.md`**, and named that as its most
expensive possible error because owner-reported items weigh most in §16.5's
denominator. Resolved against real records and the working tree:

| item | resolution | evidence |
|---|---|---|
| `OP1` modal freeze | **closed, record found** | `RG-INPUT` built a real repro rather than eyeballing it; `tests/smoke_post_modal_control.gd` exists at this SHA (28 declarations). The backlog's own note: *"Do not re-chase these two freezes."* |
| `OP2` build snap/grid | **closed, with a carried residual** | `GATEB-COORD` built the real twelve-piece controller house end to end; the stance-dependent floor height is carried as `HIST-029`. |
| `OP3` tool swing + pickup feedback | **half closed, half open** | swing: `c9870df7`, `210c1ae5`, `STRANDED-P3`. Gain feedback: **not present in the working tree** → `HIST-208`. |
| `OP4` torch hand + re-equip | **carried** | `HIST-083`. |
| `OP5` title screen | **carried** | `HIST-085` (title half closed; boot cost and quit open). |
| `OP6` repeat placement | **closed, verified in code** | `build_placer.gd::_place()` carries a `BUILD-FLOW (owner 2026-08-18)` comment: *"selection persists after a successful placement… Only explicit Cancel or choosing another catalogue entry clears/replaces it."* |
| `OP7` dismantle + full refund | **closed, verified in code** | `build_placer.gd` carries `DISMANTLE_ACTION`, a dismantle target and a refund path; `GATEB-COORD` separately fixed the screen-centre ray that made it unable to target anything. |
| `OP8` gradual overnight bed rest | **closed, verified in code** | `creature_bed.gd`'s header names *"the assignment UI, and the visible sleeping body"*; `occupant_index()` gates assignment; `game_state.gd::_tick_creature_bed_recovery()` heals gradually and `complete_creature_bed_rests()` pays the overnight bonus (recorded in `HIST-057`). |
| `OP9` catch aim/throw | **carried** | `HIST-048`, with `HIST-203`'s decision procedure attached. |
| `OP10` release ceremony | **closed, record found** | `R4.10` in `DONE.md`; the Gate F finale ran it live with a full belt and a named release. Experiential half carried as `HIST-108`. |
| `OP11` level-up feedback | **closed — and it amends `HIST-053`** | see the amendment above. |
| `OP12` cycle creatures in exploration | **closed, record found** | `CONTROLLER-MAP`'s authored map: LB cycles party member, RB calls out / puts away. |
| `OP13` pond real water | **closed, record found** | OP21-19/20 both FIXED per `ASSESSMENT_2026-08-23.md` (waterline re-anchor, `water.gd` + 8 tests); `smoke_pond_water.gd` exists. |
| `OP14` usable building doors | **closed, record found** | `R7.8` (`eed123a6`): `village_door.gd`, real doorway colliders on `cottage_b` and `ranger_station`, three new door checks in `smoke_traversal`. |
| `OP15` map trails | **carried** | `HIST-079` / `HIST-140`. |
| `OP16` core-loop density | **closed, with carried residuals** | Gate F measured 571 POI, 49.6/km, 12 species, zero 250 m+ intervals. Residuals: `HIST-046` (band 2), `HIST-032` (the gather route). |

**Net: one new open item (`HIST-208`), one amendment (`HIST-053`), and no
inference found to have hidden a second missed owner item.** Ten of the eleven
inferences were correct; the eleventh (`OP11`) was wrong in the safe direction —
it was carried as possibly-open when it was closed.

# IDs merged rather than allocated separately

Two owner-reported items from `OWNER_PLAYTEST_2026-08-23.md` describe the same
unresolved item as an existing row and are carried there rather than duplicated.
Recorded so the numbering has no unexplained holes and so neither owner report is
lost at reconciliation:

| owner item | carried as | why |
|---|---|---|
| `OP23-10` — torch hold still looks unnatural | `HIST-083` | same torch equip/pose/brightness item; OP4 (2026-08-18) reported the orientation half first |
| `OP23-12` — player-built roofs don't plane in the right spots | `HIST-119` | same roof-module ceiling; OP21-09 reported the size half first |

`OP23-07` (TMs as cards, = `RG12`) is carried as `HIST-076`, and `OP23-08`
(Grandpa's house placeless, = `OP21-17`) as `HIST-130`, both with the owner's
double report recorded in the row.

---

# Counts

Revised after the second pass. Every number below is derived from the file
itself, not carried forward by hand.

| | count |
|---|---|
| **Total unresolved historical items enumerated** | **210** |
| — Section 1, player-facing | 162 |
| — Section 2, not player-facing | 36 |
| — Section 3, superseded/obsolete candidates | 10 |
| — merged into another row (no separate ID) | 2 |
| **Owner-reported** (sections 1+2) | 45 |
| — of which player-facing (Section 1) | 43 |

`likely_still_valid`, across the 198 rows in sections 1 and 2. Two rows carry a
dated amendment that revises the field; both figures are given so neither is
hidden:

| | Section 1 | Section 2 | total |
|---|---|---|---|
| `yes` | 108 | 28 | 136 |
| `unsure` (as filed) | 49 | 7 | 56 |
| `no` (as filed) | 5 | 1 | 6 |
| `unsure` (after the two amendments) | 48 | 6 | 54 |
| `no` (after the two amendments) | 6 | 2 | 8 |
| **total** | **162** | **36** | **198** |

The two amendments are `HIST-053` (level-up feedback) and `HIST-091`
(`CI-BOSS`), both revised from `unsure` to `no` on closing records found in this
pass. Both rows are kept, with the contradicting evidence quoted, because each
carries a live sub-finding the fix did not retire.

Section 3's 10 rows carry no `likely_still_valid` field: each is retired by a
named superseding decision or a verified code/data refutation, and the ruling is
Fable's. One of them (`HIST-115`) is owner-reported in origin and is not counted
in the 45.

**The §16.5 denominator is not 210 and is not 162.** It is whatever subset of
Section 1 Fable rules genuinely valid and current at reconciliation. This
snapshot's own bracket is **108 to 156** — the lower bound is Section 1's `yes`
rows alone, the upper is Section 1 minus its 6 `no` rows, with the 48 `unsure`
rows falling somewhere between. Stating the bracket rather than a number is
deliberate: picking the low end would inflate the capture rate, which is exactly
what §16.5 forbids.

## What the second pass changed, in one line each

| sweep | new items | of which player-facing | contradicted an existing row? |
|---|---|---|---|
| `ralph/reports/VISUAL_*` (13 files, read in full) | 55 (`HIST-146`–`HIST-199`, `HIST-209`) | 49 | yes — `HIST-209` refutes the stronghold-siting finding those same reports rank highest |
| `ralph/lanes/` + `ralph/ledger/` + `ralph/planning/` | 9 (`HIST-200`–`HIST-207`, `HIST-210`) | 6 | yes — `HIST-210` refutes a routing claim `VISUAL_WORLD_SURFACE` handed onward |
| `docs/ralph-prompts/` (`OP1`–`OP16` resolved) | 1 (`HIST-208`) | 1 | yes — `OP11` amends `HIST-053` |

The first pass's judgement that the visual reports were the most likely hiding
place was correct by a wide margin: they account for 55 of the 65 new items, and
49 of the 56 new player-facing ones. The prompts sweep was the least productive
in raw count and still worth doing — it converted eleven inferences into ten
cited closing records and one genuinely open owner item.

# Known gaps in this sweep

Revised after the second pass. Gaps 1–3 of the first pass are **closed**; what
follows is what genuinely remains.

## Closed by the second pass

1. **`ralph/reports/VISUAL_*_2026-08-23.md`** — all 13 files, 3,314 lines, read
   in full rather than grepped. The individual per-frame defects are now
   enumerated (`HIST-146`–`HIST-199`) instead of standing behind the
   `VIS-MAKE-remainder` / `VIS-UI-remainder` summaries. Where a later round in
   the same file fixed, refuted or superseded a finding, it is not carried; the
   refutations that matter are recorded as `HIST-209`, `HIST-210` and inside
   `HIST-148`, `HIST-169`, `HIST-176` and `HIST-194`.
2. **`ralph/lanes/`, `ralph/ledger/`, `ralph/planning/`** — opened. The failure
   mode the first pass predicted was live: `PW1`, `PW3` and `PW4` return **zero
   hits** across `BACKLOG.md`, `DONE.md`, `ACTIVE_TASKS.md` and
   `ACTIVE_GAME_PLAN.md`, and the plan's §18 owner-decision block appears in no
   queue file and in no `BLOCKED.md` entry. `ralph/ledger/` turned out to be a
   generated dashboard frozen at a 2026-08-12 commit (`HIST-207`).
3. **`docs/ralph-prompts/`** — swept, and the `OP1`–`OP16` inference resolved
   item by item against real records and the working tree. Ten of eleven
   inferences were correct; one (`OP11`) was wrong, in the safe direction. See
   the OP table.

## What still remains, and why

1. **`ralph/DONE.md` is still not read end to end**, by design —
   `START_HERE.md` §6 forbids it and the coordinator confirmed it stays
   cold-read-forbidden. Targeted greps by item ID and by subject were used
   throughout, and that is how `HIST-053` and `HIST-091` were found to be
   closed. **The residual risk is unchanged in kind and smaller in size:** an
   item closed in `DONE.md` under a name this register does not know would still
   not be caught. Two of the 208 rows turned out that way, which is the only
   measurement available of how often it happens.
2. **`docs/ralph-prompts/` was swept, not read in full.** All 80 filenames were
   listed and the `OP1`–`OP16` set was resolved individually. The 55–72
   gameplay-package prompts (`55-MEADOWS-gameplay-assembly-master` through
   `72-WORLD-ground-cover-and-mid-layer`) were **not** read line by line, and
   several carry acceptance detail no backlog entry restates. `HIST-099` and
   `HIST-108` are the umbrella rows for that surface; a genuinely missed
   requirement inside one of those prompts would sit under them unnamed.
3. **The `ralph/reports/VISUAL_*` rows are lane records, not verified state.**
   Each was checked against the later rounds in its own file, and twelve were
   checked against the working tree — but most were **not**, because doing so
   for all 54 would mean rendering the game, which is the Gate F operator's job
   and not this register's. `HIST-198` is the standing reason this matters: the
   sweep that produced these reports diagnosed **eight capture artefacts in one
   domain alone**, so some share of these rows will retire on a single
   reproduction. That is expected and is what §16.3 category 5 (NOT REPRODUCED)
   exists for; it is not a reason to have omitted them.
4. **`docs/decisions/` was not swept.** `CLAUDE.md` puts settled decisions at
   precedence level 2, and this register reads them only where another document
   cited one (`D19`, `D23`, `D42`, `D46`, `D63`). A decision that records an
   open consequence would not have been caught.
5. **`ralph/GATE_F_MASTER_PROTOCOL.md` (935 lines) was not read.** It is Fable's
   Phase A output for this run — the coverage matrix the operator will execute —
   and reading it would risk exactly the contamination §16.1 and §16.2 forbid,
   since this register must not be shaped by what Gate F plans to look for. Left
   unread deliberately.
6. **Per-gate evidence files remain grepped, not read**: `GATE_C_EVIDENCE.md`,
   `GATE_D3_EVIDENCE_2026-08-22.md`, `GATE_D5_EVIDENCE.md`,
   `GATE_D5_VISUAL_PASS_2026-08-22.md`, `GATEB_TOURNAMENT_EVIDENCE_2026-08-22.md`,
   `BAND2_WARRENS_EVIDENCE_2026-08-23.md`, `PERF_ROG_REPORT.md`. One open item
   surfaced that way in the first pass and was already refuted. These are the
   most likely remaining hiding place, and they are smaller and less
   defect-dense than the `VISUAL_*` set that gap 1 replaced.

**Honest summary: the register is now complete for the primary ledger, the owner
evidence, the visual programme, the lane/planning directories and the owner-item
prompt set; and partial for the gameplay-package prompts, `docs/decisions/` and
the per-gate evidence files.** The largest single class of residual error is no
longer omission — it is over-inclusion of visual-report rows that a single
reproduction will retire, which reconciliation handles and which was the
deliberate trade.
