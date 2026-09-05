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
| worst post buried in the ground | 1.063 m | 0.138 m (`sink_m` is 0.12) |
| every foot's height against its own ground | −1.06 … +0.48 m | −0.14 … −0.11 m |

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

Frames: __FENCE_FRAMES__

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

Frames: __INN_FRAMES__

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

Frames: __COURTYARD_FRAMES__

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
   `combat_arena_bounds_at` is untouched. __PIERS_ELSEWHERE__
3. Three lights in `stronghold.json`'s `lights`: a warm fill (`#d9a06a`, 1.4, range 30)
   high inside the doorway wall; a shadow-casting spot (`#ffe3bd`, 3.5) over the bound
   creature's stand, placed behind and above it relative to the reveal stand so the
   contact shadow falls toward the player and the rim lifts the body off the far wall; a
   second shadowed spot (`#ffd9a8`, 2.6) raking the machine's base from the doorway side.
   `_build_lights` grew `type: "spot"`, `aim`, `aim_y`, `angle`, `shadow`; every entry that
   does not ask is exactly the light it was. These are the first shadowed lights in the
   building — one shadow map each, not an omni's six — the same shadowed-positional setup
   the inn, cottage and shop interiors already run.

Numbers decided before the render, measured on the same stands (§3): __CHAMBER_NUMBERS__

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

__RENDER_LOG__

## 4. Blind judge

__JUDGE_SECTION__

## 5. Tests and smokes

All commands from the repo root with `export PATH=$HOME/godot-bin:$PATH`, on the tree at
`__FINAL_COMMIT__` unless stated.

| command | result |
|---|---|
| `godot --headless --path . --script tests/run_tests.gd -- --only=test_village_boundary.gd` | 11 tests, 175 assertions, 0 failed |
| `godot --headless --path . --script tests/smoke_stronghold_courtyard_withdrawal.gd` | passed (rc 0); red with the courtyard removed from the list (rc 1) |
| `godot --headless --path . --script tests/smoke_stronghold.gd` | `stronghold smoke test passed` (rc 0) — the route is still walkable with the piers and lights in place |
| `godot --headless --path . --script tests/smoke_traversal.gd` | __TRAVERSAL__ |

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
- **W06 and W08 are not landed.** When they land, W06's `smoke_gate_e_finale.gd` and
  `stronghold_climax.gd` staging (the creature inside the machine) will change what the
  chamber stands show; the lights here were aimed at the `legendary_stand` mark the
  creature occupies on `main`. Nothing here edits W06's or W08's files.
- Not done: no new mesh, no Meshy, no other chamber's lights touched, no PR.
- __IMPORT_UIDS__

## 7. Commits

__COMMITS__
