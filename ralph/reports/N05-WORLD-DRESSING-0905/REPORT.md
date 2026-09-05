# N05-WORLD-DRESSING-0905 — the fence behind Halda, Bram's bar wall, the courtyard's stand-down, the chamber's light

Branch `ralph/N05-WORLD-DRESSING-0905`, from `origin/main` at `f8a47ee4`. Final code commit
**`__FINAL_COMMIT__`**; the commits after it carry this report, one contact sheet, the blind
verdict and the `docs/CURRENT_STATE.md` rows, and change no behaviour. No pull request opened.

Sources: W08-DIALOGUE-CAMERA-0904 (fence, inn) and W06-FINALE-0904 (courtyard trainer, chamber).

---

## 0. A premise the wave got wrong, and what was done about it

`ralph/briefs/0905-followup/COMMON.md` says every 0904 lane has landed and their reports can
be read at `ralph/reports/<LANE>-0904/REPORT.md` on `origin/main`. **Neither source lane of
this brief is on `main`**: `git merge-base --is-ancestor` says no for both
`origin/ralph/W06-FINALE-0904` and `origin/ralph/W08-DIALOGUE-CAMERA-0904`, their reports
and judge verdicts exist only on those branches, W08's conversation camera
(`scripts/player/conversation_camera.gd`, `tools/_capture_dialogue_camera.gd`) is absent,
and W06's garrison withdrawal (`stronghold_occupation.gd::withdraw()`, the capture
`tools/_capture_stronghold_climax.gd`) does not exist on `main`. This lane read the two
reports, the three W06 judge verdicts and both contact sheets straight off the lane
branches, rebuilt the camera stands they describe in its own capture tool, and fixed the
four defects where they live on `main`. Every defect named was reproduced on `main` first
(§2), so none of this depends on W06 or W08 landing — and none of it conflicts with them:
W06 touched neither `stronghold.gd` nor `stronghold.json`, W08 touched neither the fence
nor the inn. Item 3 is the one place the missing W06 mattered, and §2.3 says how.

## 1. Files changed

| file | what |
|---|---|
| `scripts/world/village_boundary.gd` | panels fitted end to end along each outline edge (`panel_fit`) and pitched to the slope so both posts stand on the ground (`panel_pitch`); both static so a test can check them against the real outline |
| `tests/test_village_boundary.gd` | 4 new tests (the file goes 7 → 11 tests, 129 → 175 assertions) |
| `scripts/world/inn_interior.gd` | `_build_bar_dressing()`: shelves with bottles, sign, keg, bucket, stock shelf, tankards, jug, two bar stools, lantern cages over the three existing lights |
| `scripts/world/stronghold.gd` | `_lit_girder` (a lit trim band is a girder carrying a line), `_interior_live_material`, `type: spot` / `shadow: true` in `_build_lights`, `_build_tower_piers` + `_pier_span` |
| `data/config/stronghold.json` | `site.interior_conduit_energy`; three new `lights` entries for the Legendary Chamber (a warm fill, two shadowed spots) |
| `tests/smoke_stronghold_courtyard_withdrawal.gd` | **new** — the courtyard trainer withdraws when beaten and the machinery dies; the unbeaten stay |
| `tools/_capture_n05_dressing.gd` | **new** — the evidence stands for all four items, before and after |
| `tools/_probe_village_fence.gd`, `tools/_probe_legendary_chamber.gd` | **new** — the numbers behind §2.1 and §2.4 |
| `docs/CURRENT_STATE.md` | four rows in §3 |

`meadow_healing.gd` / `meadow_healing.json` were read and tested, not changed (§2.3).
Nothing outside the brief's ownership list was touched.

## 2. What the player gets, item by item

### 2.1 The fence behind Halda's stand (W08 finding 2)

**Reproduced first.** The fence in W08's frame is the village boundary
(`village_boundary.gd` laying `village_boundary.json`'s outline; `village.json` places no
fence run within 20 m of Halda). `tools/_probe_village_fence.gd` measured the 13 panels
within 40 m of her stand on `main`:

| | before (`main`) | after |
|---|---|---|
| panels with a post floating over air | **6 of 13** | **0 of 14** |
| worst float under a post | 0.476 m | 0.000 m |
| worst post buried in the ground | 1.063 m | 0.121 m (`sink_m` is 0.12) |
| every foot's height against its own ground | −1.06 … +0.48 m | −0.12 … −0.11 m |
| distance between the nearest ends of two panels, median / worst | 0.705 m / 1.536 m | 0.003 m / 0.029 m |

Two causes, both in how a panel was laid, not in the outline. Each edge was rounded to a
whole number of 6.15 m panels and the panels spaced `length / count` apart: the 14.76 m
edge behind Halda ([37,−2] → [30,11]) got two panels 7.38 m apart — 1.23 m of nothing
between them and the last rail ending 0.6 m short of the corner (the judge's *"a rail ends
in mid-air"*) — and the 3.64 m edge got a 6.15 m panel overhanging both neighbours by
1.25 m (the *"post passes bodily through the rails of another run at a different
angle"*). And every panel sat dead level at the ground height under its own centre, so on
any slope one end floated and the other sank (*"a post floats clear of the terrain with
visible ground beneath it"*).

Now `panel_fit` stretches each panel along its own edge to exactly `length / count`, the
count chosen so the stretch stays as near ×1.0 as whole panels allow (never past
×0.707/×1.414 once an edge holds two; the edge behind Halda is two panels at ×1.2, the
short edge one panel at ×0.59), so consecutive panels meet end to end and the last one
ends on the vertex where the next edge's first begins. `panel_pitch` tilts each panel to
the ground under its two end posts. Collision boxes are untouched: they were already
sized from the whole footprint's lowest and highest ground.

Tests: `test_village_boundary.gd` → **11 tests, 175 assertions, 0 failed**. Seen red for
the right reason before being kept: with `stretch` forced back to 1.0 (the old laying),
`test_the_panels_laid_along_every_edge_meet_end_to_end` fails on six edges, e.g.
*"edge 20 ((46,−63) → (54,−58), 9.43 m): 2 panels of 6.15 m × 1.000 cover 12.30 m, leaving
−2.87 m of daylight"*. The tests also caught a real flaw in the first version of
`panel_fit` (a band correction that flipped a 9 m edge to two panels at ×0.73) before any
render did.

Frames: `_sheet_dressing.png` rows 1–2 and the zoomed junction pair at the bottom (A =
`main`, B = this branch, same stands). In A the run behind Halda ends in mid-air a stride
short of the [30,11] corner, a post of the next run stands through its rails, and the
near rail floats over visible ground; in B the two runs meet end to end at the corner and
the rails follow the slope down to the ground. Pixel change at the W08 stand: 7.8% of the
frame; at the fence-run stand: 10.3%.

### 2.2 Bram's inn behind the bar (W08 finding 5)

The across-the-bar frame W08's push-in parks the player on was bare plaster from the
counter to the ceiling. Dressed with the installed prop family and the same primitives
the counter is made of — nothing generated, no new mesh: four wall shelves flanking
Bram's own stand with five bottles each (two glasses, stepped heights), a sign board over
him with a `Label3D` ("ROOMS - ALE - STOCK"), a Fantasy-kit keg and bucket at the
counter's east end, a furniture-pack `Bookcase` as the stock shelf at the west end, three
pewter tankards and a jug on the counter top toward the guest side, two furniture-pack
`Stool`s on the guest side either side of the door lane (native scale — the pack's 0.5
correction makes a 0.29 m footstool of it), and a lantern cage hung over each of the room's
three existing lights. The cages sit 0.2 m ABOVE their light on purpose: two of those omnis
cast shadows, and a shadow-casting light inside an opaque box lights nothing. Nothing
solid enters the door lane, stands where Bram does, or stands in front of the counter's
middle where the player talks to him.

Frames: `_sheet_dressing.png` row 3 (29.0% of the frame changed at the across-the-bar
stand). Judged blind in `JUDGE_DRESSING.md` (§4).

### 2.3 The courtyard gauntlet trainer after the world changes (W06 finding)

**This one was already handled on `main`, and the evidence is new.** Spec §9 /
`meadow_healing.gd` withdraws every Team Tether trainer the player has ALREADY BEATEN
when `legendary_freed` is set, and `data/config/meadow_healing.json`'s `patrols.withdraw`
already lists `stronghold_courtyard`. W06's capture set only the elite's and the Warden's
defeat flags before pulling the lever, so Warder Solene was UNBEATEN in its frames and
stayed — by §9's own rule (*"no fight the player has not yet taken is deleted by the
ending"*, the config's own comment), not by omission. The brief's instruction — add the
trainer to whatever list already reacts — was already true; what was missing was proof
that the list works for her.

`tests/smoke_stronghold_courtyard_withdrawal.gd` boots the real world, finds all three
gauntlet trainers on their marks (0.00 m off), sets Solene's defeat flag only, sets
`legendary_freed`, waits for `MeadowHealing.applied()` (1 frame), and asserts:

```
godot --headless --path . --script tests/smoke_stronghold_courtyard_withdrawal.gd
  Warder Solene stands at (4.0, 6.17, 7596.0) (0.00 m off mark)
  the Meadows answered after 1 frames: { "regrown": 1156, ..., "patrols_withdrawn": 1 }
  Warder Solene has withdrawn from the courtyard
stronghold courtyard withdrawal smoke test passed          rc=0
```

The unbeaten patrol and elite are asserted to still stand, and her defeat flag to be
untouched. **Seen red for the right reason:** with `stronghold_courtyard` removed from
`patrols.withdraw` — *"Warder Solene is still standing on her mark at (4.0, 6.17,
7596.0)"*, *"meadow_healing reports 0 patrols withdrawn"*, rc=1. (The first green run
exposed a bug in the test itself — assigning a freed instance to a `Node`-typed variable
is a script error, which is how a coroutine smoke hangs instead of quitting; fixed, and
noted because it is the shape of failure CI's `RETRIES` would hide.)

Is the courtyard fight skippable? Yes — the one door in the Hall is gated on the ELITE's
flag (`_sync_doors`), and `fight_through_the_hall` only counts the courtyard. So a player
who walks past Solene will see her still on post after the Hall stands down, exactly as
W06's judge did. Whether the Hall's own three gauntlet trainers should stand down
regardless of being beaten is a design call §9 currently answers "no" to in writing; this
lane did not overturn it. **Routed to the owner/orchestrator** as the one open question
here.

Frames: `_sheet_dressing.png` rows 4–5: the same courtyard stand before and after
`legendary_freed` with the courtyard flag set; the capture tool itself reports
`courtyard trainer body after legendary_freed (beaten): WITHDRAWN` in both the `main`
and the branch runs — because this is `main`'s behaviour, verified, not this lane's
change.

### 2.4 The Legendary Chamber's light (W06, three independent judges)

Every defect was attributed to a node before anything was changed
(`tools/_probe_legendary_chamber.gd` inventories the 264 visuals and 8 lights inside the
chamber footprint):

- **"Cyan light-bars … debug draws / unmounted floating bars"** — the two `trim` bands
  with `lit: true` on the ±x walls: 0.6 × 0.5 m boxes of `_live_material()` (emission 1.4)
  running the room's full 28 m at 15 m up, plus the two 32 m floor conduits at ±3.4 m
  (also 1.4). From the reveal stand, looking up at the machine, a horizontal bar at 15 m
  is a diagonal from the top corner of the frame to a point in mid-air.
- **"Overlapping slabs with a visible black gap"** — the exterior `HallMassing` towers
  stand ON the chamber's corners and reach INSIDE it: the 10.7 m PointyTower centred
  0.85 m from an inner corner intrudes 4.75 × 4.76 m; the two LargeTowers 3.52 × 3.8 m;
  the fourth 2.88 × 3.1 m. From inside that is the tower's outer shell in the kit's
  coarser stone, lit by nothing, overlapping the chamber's wall slabs, with the culled
  inside of the shell showing black where it crosses them.
- **"No contact shadow", "single-key, crushed blacks", "the creature is lost"** — two
  grey-blue omnis (1.05, range 30) at 12 m and the machine's teal core; every light in the
  building shadowless by design.

What changed (all data-driven, all recorded beside the number):

1. A `lit` band is now an oxblood girder (`_tether_material`, what every unlit band and
   pillar already wears) carrying a slim 0.14 m live line clipped along its room-facing
   edge, a hand shorter than the girder at each end so the line terminates inside the
   hardware. The line and the roofed floor conduits take `site.interior_conduit_energy`
   0.9 (W06 measured this teal clipping to white at 2.2 and holding its hue at 1.15), with
   the albedo pulled down a quarter. The machine's own crown and ring lamps keep 1.4 — they
   ARE the room's light source. Probe after: the emissive runs in the chamber are
   `2fae93 × 0.90`, 0.14 m and 0.20 m wide; before, `3fe8c4 × 1.40` at 0.6 m.
2. `_build_tower_piers()`: wherever a massing module's bounds reach inside a roofed
   chamber, the intrusion is enclosed in a masonry pier of the chamber's own wall stone,
   flush with the walls it stands against, floor to ceiling, snapped up to a half-metre
   course — which is what the inside of a corner tower is. Legendary Chamber: 5.05, 4.05,
   4.05 and 3.55 m. Non-solid, like the tower shell it hides: no walkable metre changes and
   `combat_arena_bounds_at` is untouched. The same rule found the same defect in the Warden Arena: its four
   corners carry the LargeTower modules at 2.6 × 3.1 m, and get 2.6 × 3.1 m piers (well
   outside the 11 m combat ring). Row 4 of `_sheet_chamber.png` shows that room before and
   after; nothing else in it changed except the floor conduits' energy.
3. Three lights in `stronghold.json`'s `lights`: a warm fill (`#d9a06a`, 1.4, range 30)
   high inside the doorway wall; a shadow-casting spot (`#ffe3bd`, 3.5) over the bound
   creature's stand, placed behind and above it relative to the reveal stand so the
   contact shadow falls toward the player and the rim lifts the body off the far wall; a
   second shadowed spot (`#ffd9a8`, 2.6) raking the machine's base from the doorway side.
   `_build_lights` grew `type: "spot"`, `aim`, `aim_y`, `angle`, `shadow`; every entry that
   does not ask is exactly the light it was. These are the first shadowed lights in the
   building — one shadow map each, not an omni's six — the same shadowed-positional setup
   the inn, cottage and shop interiors already run.

Numbers decided before the render (`tools`-side script in the lane's scratch, thresholds
fixed before any frame was seen), measured on the same stands, A = `main`, B = branch:

| stand | pixels reading as a blown pale-cyan bar (G−R>40, B−R>40, luma>160) | pixels under luma 20 | mean luma |
|---|---|---|---|
| C-01 face-on from the reveal stand | **15,659 → 3,417** (the rest is the machine's own crown and ring lamps, deliberately kept at 1.4) | 31.1% → 30.2% | 36.7 → 36.2 |
| C-03 raised three-quarter from the door corner | **11,865 → 6,032** | 44.8% → 41.1% | 33.4 → 33.9 |
| C-02 the held creature | 241 → 238 | 44.5% → 41.0% | 30.3 → 33.8 |

Creature crop (frame centre) against the ring around it, C-02: **42.0 vs 33.6 (+8.5) →
48.2 vs 38.0 (+10.3)**. Machine front crop, C-01: 41.1 → 46.0; floor in front of the
machine, C-03: 38.9 → 44.8; creature crop, C-03: 53.7 → 60.3.

**And the honest half of that table: the walls did not move.** C-01 right wall 25.2 →
25.3, C-03 far wall 25.2 → 25.2. The machine, creature and floor took the new light and
the walls took none — which is the Compatibility renderer's per-mesh cap
(`rendering/limits/opengl/max_lights_per_object`, 8) on OMNI lights: the chamber's 41 m
wall slabs already touch eight (two room omnis, the core, the containment light, the
arena pair, the siphon, the approach) and a ninth is dropped silently on exactly the
surfaces the "crushed blacks" verdict was about. Spots are budgeted separately and the
room had none, so the fill is now a wide spot (85°, 2.4, range 36) thrown from the
doorway wall across the room; that is the state committed and in `stronghold.json`'s own
comment. The four chamber/arena stands were re-rendered on it (`shots/n05_after2`, the frames in
`_sheet_chamber.png` and the ones the judge saw):

| stand | blown pale-cyan px | pixels under luma 20 | mean luma |
|---|---|---|---|
| C-01 face-on | 15,659 → 3,419 | 31.1% → **29.4%** | 36.7 → 36.8 |
| C-03 door corner | 11,865 → 6,033 | 44.8% → **39.4%** | 33.4 → 34.7 |
| C-02 creature | 241 → 238 | 44.5% → **38.9%** | 30.3 → 34.7 |

Creature crop vs surround, C-02: 42.0 vs 33.6 (+8.5) → **50.2 vs 39.3 (+10.9)**; creature
crop C-03: 53.7 → 61.0; machine front C-01: 41.1 → 47.5. **The walls still barely moved**
(C-01 right wall 25.2 → 26.0, C-03 far wall 25.2 → 25.5). So of the judges' four chamber
findings this lane's data changes answer the light-bars and the wall slabs directly, give
the machine and the creature a directional key and a shadow, and open the crushed blacks by
five to six points of the frame — not the room's walls. **That is the recorded ceiling for
this lane:** whatever keeps a 2.4-energy 85° spot from lifting a 30 m stone wall by more
than a luma point on this renderer (the weathered `hall_stone.gdshader` face at grazing
angles, a second per-object cap, or software GL itself) needs a look at the wall material
or the room's ambient, which is `world_look.gd`'s global setting and not this lane's to
reach into. Per the coordinator's 15:58 instruction no further render rounds were spent on
it; the gap is stated here rather than closed.

## 3. Runtime validation and frames

`tools/_capture_n05_dressing.gd` under xvfb + `--rendering-driver opengl3` at 1280×720
(never `--headless` with a driver). Stands: W08's Halda two-shot rebuilt from the bracket
board's position (the board is over her shoulder in W08's frame 1; her authored
`facing_deg` looks back into the square, which the first capture round proved), the fence
run behind her, W08's across-the-bar stand at the conversation camera's 3.5 m / 40°, W06's
two chamber stands verbatim (reveal stand face-on; raised three-quarter from the door
corner), a creature stand, the Warden Arena, and the courtyard trainer held then freed.
The "before" run used `main`'s versions of the four changed files checked out into the
same tree (`git checkout f8a47ee4 -- …`, then restored) so both columns share one build
of everything else.

```
xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 \
  --resolution 1280x720 --script tools/_capture_n05_dressing.gd -- --out=res://shots/n05_before2
→ wrote 9 frames, 0 failures (main's four files checked out; 21 min)
... --out=res://shots/n05_after
→ wrote 9 frames, 0 failures (this branch)
... --out=res://shots/n05_after2 --only=C-0,W-01 --skip-freed
→ the four chamber/arena stands again after the fill became a spot (§2.4, point 3)
```

A first baseline attempt ran four headless jobs alongside the render and managed one stand
in fifty minutes; it was killed, the settle was shortened indoors (one pass of 30 physics
frames instead of two of 60; the terrain is not in frame there), and both runs were
repeated alone. `^ERROR:` in the capture logs: `Parameter "material" is null` only.

## 4. Blind judge

Two code-blind sub-agents (`opus`), each given one contact sheet, the individual frames,
`docs/reference/` and `.claude/skills/visual-judge/SKILL.md`, told nothing about which
column is which build or what changed, and asked to rule only on the defects this brief
names (per the brief: one round, focused, no re-litigating the rest of the room).

- **Dressing sheet** (`_sheet_dressing.png`: Halda's stand, the fence run, the inn, the
  courtyard held/freed, the zoomed junction): verdict in `JUDGE_DRESSING.md`.
  **Fence (rows 1–2, zoom): "Column B is better, and not marginally: it is the difference
  between a fence and a pile of fence segments. Every defect below is present in A and
  absent in B."** It measured A's run with 10 px and 17 px voids at row 2 x 944–953 and
  1042–1058, a 17 px void at row 1 x 1189–1206, a 16 px hole at the corner with three
  separate posts arriving at different rail heights and angles, and a rail driven through
  a post protruding into air at (519–524, 371–377); in B one shared corner post at each
  corner, both runs' rails dying on it, the line following the slope. It could find no
  floating post in either column ("A's problem is horizontal continuity, not vertical
  seating") — which is the probe's finding too (worst float 0.48 m is a foot, not a
  visible gap at 3.5 m). **Inn (row 3):** "Column A is a greybox. Not 'sparse' — a
  greybox." B has the dressing and every object's scale is right against Bram (bar at
  belt height, bottles 20–26 cm, tankards under 20 cm), and B "is not there yet": the
  sign's lettering ran 1.8× the board's width (672 px on a 372 px board) with the overhang
  at 1.2:1 against plaster; the bottles were a fixed-pitch array (77/42/75/41 px); the
  lower-west shelf plank passed through the stock shelf's stile at (125–140, 300–312); no
  light source in frame (the lantern cages hang above the 40° conversation frame). All four
  were fixed in data after the verdict (text sized to the board and painted dark, per-shelf
  counts and uneven pitch with an empty stretch and one bottle lying down, the west shelves
  shortened to clear the stock shelf, a candle on the counter end) and confirmed in one
  render of that stand (`shots/n05_after3`, §3) — not re-judged, per the coordinator's
  15:58 instruction. **Courtyard (rows 4–5):** the figure stands in row 4 and is gone in
  row 5 in BOTH columns, byte-identical silhouette — correct, and this lane changed nothing
  there. The judge's own finding on those rows is the one routed in §2.3 and §6: "when the
  garrison stands down, the fortress does not visibly react" beyond the missing trainer.
  That is W06-FINALE's unlanded withdrawal (braziers, camp, lamps), not this lane's.
- **Chamber sheet** (`_sheet_chamber.png`: W06's two chamber stands, the creature, the
  Warden Arena): verdict in `JUDGE_CHAMBER.md`. The judge identified B as "a
  lighting/dressing pass applied in B" and ruled point by point; the brief asked for
  exactly what changed and what did not, so here it is in the judge's own numbers:

  | defect | verdict |
  |---|---|
  | **cyan light-bars** | **Row 1 "B is much better, and it is the only place in the sheet where the fix is convincing"**: the 38 px luma-220 slabs become 5–6 px strips under a housing that "reads as intentional mounted lighting". Row 2's ceiling diagonal likewise (7,301 → 1,273 cyan px). **Not fixed:** the floor conduits (row 2's floor strip and stub, row 3's stub, all three row-4 strips) are "a recolour, not a fix" — luma 218 → 166, still unmounted, still ending in mid-air; the girder housing "renders at exactly RGB (0,0,0) … it is not dark hardware, it is a hole"; the line still ends in a square cut. The nine 222-luma cage bars around the creature are "the brightest object in either frame" and read as debug draws too — those are `stronghold_climax.gd`'s (W06's file), unchanged and not this lane's. |
  | **contact shadows** | **Tie, both fail:** "Neither column has a contact shadow anywhere." Floor under the creature is equal to or brighter than beside it in both columns (B lifted the ground it stands on); the machine base meets the floor with a bright rim and no occlusion. The two shadowed spots are in the scene (`tools/_probe_legendary_chamber.gd` lists them, `shadow true`) and produced no readable shadow: the creature's own shadowless `ContainmentLight` (W06's file, 2.34 at 2 m) floods the floor under it, and the floor mesh is at the omni cap. **Not achieved.** |
  | **value / single-key** | Fill reaches "the near floor, the creature and the machine base, and does not reach the walls or the ceiling at all" (row 2 deltas: floor +8.0, machine base +8.1, torso +9.2, walls +2.0 / 0.0 / −0.2). Dead-black (luma<20 and featureless) 6.3% → 3.6% (row 2), 5.7% → 4.1% (row 3), 2.4% → 2.4% (row 1). **A second hue family is established:** teal share of saturated pixels 32→17%, 26→13%, 47→25% (rows 1–3), warm olive 32→50%, 37→63%, 17→43%. The chamber sits inside the key art's own night-panel budget in both columns; the Warden Arena (row 4, luma<5 25–29%) is the outlier and got no fill — its floor went 22.6 → 19.0 because the conduits dimmed. **Partly achieved (floor, machine, creature); walls not.** |
  | **wall slabs / black gaps** | **Row 2 "B is clearly better, and this is the single most convincing fix in the sheet"**: the 34 × 330 px slot at x 102–136 (mean luma 9.1, 69% under 5) is continuous masonry in B (21.3, 8%) — that is the PointyTower pier. Row 1: two 3 px seams gone, but overlapping slabs whose courses do not meet remain in both. **Rows 3 and 4 not fixed**: full-height slots at row 3 x 1186–1201 and row 4 x 336–352 / 896–916 render at absolute 0 in both columns and got slightly darker in B. By position those are the oxblood `trim` **pillars** (0.7 m, full height, at chamber offsets ±12/±10) — the same `_tether_material()` as the girder housing the judge called "a hole". The oxblood hardware's documented emission value-floor (0.55, `_stone_shader_material` does pass it) is not reaching the screen; that is a material finding for the whole Hall, outside what this lane could close in one round. |
  | **creature legibility** | Row 2: the creature is identifiable in both (the antler crown, Δ17–18 vs the wall); torso vs wall Δ4.5 → **Δ10.1**, torso vs floor Δ8.4 → Δ3.6 — "B trades one for the other". Row 3: the stand named for the creature shows no creature in either column (the machine occludes it) — a staging defect in W06's climax file, not lighting. **Partly achieved.** |

  Bar questions, scoped: A **no for both, "B is materially closer"**; B **no for both**.
  The judge's fixable-now list (propagate the girder treatment to the floor conduits with a
  bracket at each end, a non-black housing material, a common floor line and lower emission
  for the cage bars, extend the fill into the arena, contact darkening as a decal) is carried
  into §6 as routed work rather than attempted here, per the coordinator's instruction to
  converge.

## 5. Tests and smokes

All commands from the repo root with `export PATH=$HOME/godot-bin:$PATH`, on the tree at
`__FINAL_COMMIT__` unless stated.

| command | result |
|---|---|
| `godot --headless --path . --script tests/run_tests.gd -- --only=test_village_boundary.gd` | 11 tests, 175 assertions, 0 failed |
| `godot --headless --path . --script tests/smoke_stronghold_courtyard_withdrawal.gd` | passed (rc 0); red with the courtyard removed from the list (rc 1) |
| `godot --headless --path . --script tests/smoke_stronghold.gd` | `stronghold smoke test passed` (rc 0) — the route is still walkable with the piers and lights in place |
| `godot --headless --path . --script tests/smoke_traversal.gd` | `traversal: OK` (rc 0), on the new fence — the village gates and perimeter still hold |

`SCRIPT ERROR`: 0 in every run above. `^ERROR:`: only `Parameter "material" is null`
(1–3 per run, the known-benign creature-build line under the headless renderer, present
on `main`); the set did not grow.

## 6. Known limitations and what was deliberately not done

- **Unbeaten gauntlet trainers still stand after the Hall stands down** (§2.3) — by §9's
  written rule. Not overturned here; routed.
- **Panels stretch.** A ×1.2 panel has posts 20% thicker along the run and rails 20%
  longer; a single panel on a 3.64 m edge is squeezed to ×0.59. Judged acceptable against
  the alternative (air, or a panel through the next run); the numbers are constants at the
  top of `village_boundary.gd`.
- **Piers are non-solid** and cover the towers' axis-aligned bounds, so a round tower's
  quarter-disc is enclosed in a square pier a little larger than it.
- **Warm light in a Team Tether room** is the Hall's own fire language (the courtyard fill
  is the same colour); no teal was added anywhere and none removed from the machine.
- **What the chamber round did NOT close, in the judge's words (§4):** the floor conduits
  are recoloured, not mounted; no contact shadow registers under the machine or the creature;
  the fill does not reach the walls; the oxblood hardware (girder housings and the trim
  pillars) renders as absolute black, which is the remaining "black slab" in rows 3 and 4.
  Next owner of `stronghold.gd`: give the floor conduits the `_lit_girder` treatment with a
  bracket at each end (the pattern is written and judged); find out why `_tether_material`'s
  0.55 emission floor does not reach the screen through `hall_stone.gdshader` (the shader
  reads `emission_energy`, and it is set); add contact darkening as a floor decal under the
  machine and the `legendary_stand` mark rather than relying on a shadowed spot that a
  shadowless 2 m omni washes out; extend the fill into the Warden Arena. The cage bars and
  the creature stand are `stronghold_climax.gd` (W06's).
- **W06 and W08 are not landed.** When they land, W06's `smoke_gate_e_finale.gd` and
  `stronghold_climax.gd` staging (the creature inside the machine) will change what the
  chamber stands show; the lights here were aimed at the `legendary_stand` mark the
  creature occupies on `main`. Nothing here edits W06's or W08's files.
- Not done: no new mesh, no Meshy, no other chamber's lights touched, no PR.
- **12 untracked `.uid` sidecars were left untracked on purpose** and want routing:
  `godot --headless --import` in this container generated them for other lanes'
  Cloudreach (Biome 2) scripts and tests (`autoload/realm_heart_state.gd`,
  `scripts/world/cloudreach_world.gd`, `realm_gate.gd`, `realm_heart_shrine.gd`, seven
  `tests/*cloudreach*|realm*` files, `tools/capture_cloudreach_foundation.gd`). They are
  outside this lane's ownership; the four `.uid` files for this lane's own new scripts
  ARE committed.

## 7. Commits

```
614b9151 N05 report: frames, piers, render log, routed sidecars
b42b730e N05: the chamber fill is a spot (omnis are capped per mesh); uid sidecars; dressing contact sheet
86c13af0 N05: fence join numbers from the corrected probe; traversal smoke result
077423db N05: CURRENT_STATE rows, report draft, fence probe end-post fix
ff70d6df N05 capture: a Warden Arena stand
998bc89e N05: log each tower pier; trim the capture to the judged stands
6932968f N05 dressing: fence panels meet and sit on the ground, the inn's bar wall, the chamber's light-bars, piers, fill and shadows
<the report/sheet/verdict commits after these carry no behaviour>
```
