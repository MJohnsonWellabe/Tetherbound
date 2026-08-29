# THE MEADOWS HALL — design for the merged castle + stronghold

**Lane:** T1-HALL-DESIGN (design only — a Sonnet lane builds this; a separate
Fable judges it blind). **Date:** 2026-08-30. **Base:** `main` @ `a97f3e84`.

**The directive (owner, 2026-08-29):** the castle IS the Meadows Hall and IS
the stronghold. One location, redesigned from scratch. This document is that
design: precise enough to build from, with every number either measured
against the live tree or marked TUNABLE with its target stated in words.

Everything in here was verified against current `main`, not inherited from
prose. Where this document disagrees with its own brief or with an earlier
report, the disagreement is stated in §12.

---

## 0. What is being merged, verified

| Thing | Where it is today | Evidence |
|---|---|---|
| The castle (silhouette landmark, no route) | `scripts/world/landmark.gd` `SITE` = (150.0, 7595.0); 132 kit modules via `building_prefabs.json` `castle`; plinth, ramp, occupation | read; rendered (`C-02`/`C-03`, this session) |
| The stronghold (the walkable finale route) | `data/config/stronghold.json` `site.at` = (0.0, 7560.0), `yaw_deg: 90`; five chambers, gauntlet, machine | read; rendered (`S-ext-01/02`, this session) |
| Separation | ~154 m apart, two unrelated buildings sharing every vista | both in frame in `C-02` |
| The wrong yaw | `stronghold.json` `_comment_ow5d_relocation`: yaw 90 "very likely WRONG" for the north approach — never re-derived | confirmed; re-derived in §2 |
| The reference board | `docs/reference/owner-board-2026-08-15-systems-and-castle.png`, MEADOWS CASTLE CONCEPT panel + four insets + BUILDING PIECES + CASTLE NOTES | opened and read (§1) |

Current state notes that matter (rendered this session at the judge's own
stands, post-`T1-ARCH-STRONGHOLD` — that lane's dressing IS on main):

- The stronghold flank is no longer a black box: merlon roofline, oxblood
  H-girders with teal conduit, banners and a base course all landed. It is
  still a single flat-roofline crate with ~1 m wall stones, and the H-motif
  repeats identically wall to wall (its own handover flagged this).
- The castle is still the judge's white maquette on a concrete display base:
  no coursing at any distance, no openings on any wall run, mid-wall turrets
  a third the girth of corner towers, plinth base floating over dips in the
  grass.
- The gate face of the works (`S-ext-01`) reads as real warm-lit masonry —
  the fire + sky-fill recipe works and is worth keeping where it is needed.

---

## 1. The reference reading

**Architecture** — the board's MEADOWS CASTLE CONCEPT panel: warm grey-brown
coursed stone, dark timber tower caps with gold finials, teal-green tile on
lesser roofs, layered terraces stepping down a rocky hill, timber hoardings
and walkways outside the walls, a tall heraldic banner flat against the
curtain, watchtowers with open timber tops. Insets: Gatehouse (twin towers,
arched timber gate, banners), Inner Yard (timber stalls), Wall Walk
(crenellated parapet, towers punctuating), Tower Detail (square stone shaft,
banner, timber cap). CASTLE NOTES, which §11 turns into the acceptance list:
*Uses existing Quaternius packs / Larger scale, layered walls / Multiple
elevations and walkways / Functional, military feel / Fits the Meadows (not
floating) / Extensible for siege/defense gameplay.*

**Occupation** — board 15 (`WARDEN STRONGHOLD` header) supplies the material
key: dark stone, dark metal, brass/gold, tether energy (teal), runic glow,
chain/mechanical. Boards 13/14 supply the hardware family (all three hero
meshes are installed: `tether_pylon.glb`, `relay_apparatus.glb`,
`tether_machine.glb`). The keyart's own **"TEAM TETHER STRONGHOLD (MEADOWS
HALL)"** panel shows exactly the merged reading: a weathered *Meadows-stone*
gatehouse wearing *Team Tether* red banners, wooden scaffolds and industrial
apparatus. The judge's one piece of praise at this site — the pylons read
correctly and the building lacks their language — is the same instruction.

**The approved reading:** a Meadows castle that Team Tether has seized and
industrialised. The board gives the architecture; board 15 gives the
occupation overlay; boards 13/14 give the hardware; the keyart panel shows
them combined.

---

## 2. Siting, orientation, and the re-derived approach bearing

### Measured ground truth

`tools/_probe_hall_site.gd` (this branch — same 8 m-grid method as
`_probe_stronghold.gd` and the GATE-E2 re-site) sampled x[−72,40] × z[7490,
7682] against the live heightfield, plus the trail's own last 600 m. The
full grid is reproducible with one command; the shape of the ground:

- The player arrives through a **low bowl**: the trail reads −1.1 at the
  Sigil Gate (63.6, 7400), **−6.9** at (20, 7480), −3.6 at (0, 7520), −0.65
  at the terminus (0, 7560). The Hall is approached from below.
- A **local rise peaks ≈ +4.8** around (8–16, 7586–7602) — inside what
  becomes the courtyard. The building genuinely sits on a hill.
- A **western shoulder climbs to +7…+9** across x[−72,−40], z[7546–7602],
  with samples of +5…+7 reaching x −40…−48 at z 7650–7674 — flanking
  terrain for the keep to lean against.
- A **ravine** drops to −8…−16 at z 7530–7538, x[−56,−16] — just north-west
  of the site, beside the approach. Real drama, free; dress it, don't fight it.
- Terrain ends at z ≈ 7682 (`world_perimeter.gd` `WORLD_Z_SOUTH` = 7680;
  the boundary wall stands ~3 m inside it).

### The decision

- **`site.at` → (8.0, 7560.0)** — 8 m east of today's value, on the trail's
  own terminus. The +8 shift takes the western shoulder's +5.6…+6.8 samples
  out from under the legendary chamber, which otherwise binds the shared
  floor level ~2 m higher for no visual gain; with the shift the binding
  high ground is the courtyard rise (+4.8) and the legendary west edge
  (~+5.0), so the complex-wide floor lands **≈ +5.5 absolute** (the build
  log prints the real value; `_choose_floor_level()` derives it, nothing
  hard-codes it).
- **`site.yaw_deg` 90 → 0.** With yaw 0, local +z (route depth) is world +z:
  walking deeper walks **south**, and the mouth (local −z face of
  `outer_works`) faces **north — straight up the corridor the player
  actually arrives along**. The trail's final leg (20,7480) → (0,7560)
  bears ≈ S14°W; a dead-square mouth at yaw 0 gives the player a slight
  three-quarter view on final approach, which reads *more* dimensional than
  square-on. Do not chase the extra 14° with a non-cardinal yaw; it buys
  nothing and complicates every probe.
- **`site.ramp_run` 26 → 40.** Mouth sill at floor ≈ +5.5, ramp-foot ground
  at (8, 7508) ≈ −4.8: ≈ 10.3 m of rise over 40 m ≈ **14.5°** — a real
  climb to a real fortress, comfortably under the walkable bar.
  `_build_approach_ramp()` self-derives the rise from the ground; only the
  run is authored.

Chamber world boxes after the change (derived, for collision checks — the
chambers' own local `at`/`size` values in `stronghold.json` **do not change**):

| chamber | world x | world z |
|---|---|---|
| outer_works | [−2, 18] | [7548, 7572] |
| courtyard | [−3, 19] | [7574, 7602] |
| tether_approach | [0, 16] | [7615, 7633] |
| warden_arena | [−4, 20] | [7637, 7663] |
| legendary_chamber | [−38, −10] | [7636, 7664] |

Southern clearance: deepest wall face ≈ z 7665.2 vs the boundary wall at
≈ z 7677 → ~12 m clear. Verified against the probe grid; ground exists
under every box.

Everything already authored to aim at (0,7560) keeps working: the 15-pylon
line ends at (−8, 7505), 55 m short of the mouth and now pointing at the
**west half of the works — which is where the legendary chamber and the
machine actually are**. The Sigil Gate (63.6, 7400), the waystop (−25, 7460)
and the Band 5 trail need **no edits**.

### The lighting fact nobody has put next to this yaw, and the design answer

`art.json` `sun.yaw_deg` is now **140 — the sun is in the SOUTH sky**
(VISUAL-LIGHT flipped it from −40 specifically so south-facing hero faces
front-light). The re-derived mouth faces north. **The Hall's gate face is
therefore a shaded face at the day keyframe.** The brief treats the yaw
re-derivation as a pure win; it is right about the geometry and silent
about this cost, so the design owns it explicitly rather than discovering
it in the judge's frames:

1. The gate face carries the **light end of the stone ladder** (§5) so its
   shaded render lands ~105–130, not the old near-black crush.
2. The gate face keeps the **verified fire + sky-fill recipe** (the one
   pass at this site that measurably worked) — and the occupation layer
   (§6) concentrates its self-lit vocabulary (braziers, teal conduit,
   banners) on this face, which is exactly where the story wants it: the
   held gate, lit by the holders.
3. The **east and west flanks catch real sun** at the day keyframe's
   south-sky azimuth as grazing light, and the player sees both flanks
   repeatedly on the trail's authored ±80 m swings. Golden hour
   (`times.golden` yaw −66) warms the north-west faces directly.
4. The **rear (south) faces are the sunlit ones**; they get the plain
   1-course curtain (§4) so overhead/map/far views read closed, not
   because anyone walks there.

This is "the dark fortress gate under its own firelight, sunlit flanks" —
a deliberate look, matching the keyart panel's moody stronghold, not an
accident to apologise for.

### What retires

- `landmark.gd`'s detached castle at (150, 7595): the node (prefab
  instantiation, plinth, ramp, `stronghold_occupation` build) stops being
  built. `playground_world.gd::_build_settlement` drops the LANDMARK call;
  `landmark.gd` stays in the tree as history per repo convention. Nothing
  stands at (150, 7595) afterwards — the vista the two buildings shared
  becomes one building.
- `map_landmarks.json` `stronghold` pin: position → **(8.0, 7590.0)**
  (complex centre of mass), `silhouette: true` retained, display name
  "Meadows Hall" already correct. Update the `_comment_gate_e2` note.
- `stronghold.json` `_comment_where` ("the WORKS BEHIND the castle") is
  rewritten by this design: there is no "behind" any more.
- The `EXTERIOR_FACE_TILE_MULT` facing skin in `stronghold.gd` retires with
  the material unification (§5) — the facade modules now carry the
  exterior read.

**Build ownership:** `stronghold.gd` becomes the single owner of the whole
location — it already computes the floor, the frame and the route, and it
gains one pass, `_build_hall_massing()`, which instantiates the new
`meadows_hall` facade prefab (§4) through `building_prefabs.gd` exactly the
way `landmark.gd`/`grandpa_house.gd` already do (template-holder pattern
included). One node, one frame, one floor value, no cross-builder ordering
problem. `stronghold_occupation.gd`'s brazier/flicker recipe is ported to
the causeway by this pass (§6); the file itself is not extended in place.

---

## 3. The composition from the approach

The chapter's climax is this walk. Band 5's axis (the judge's best macro
moment in the game) already does its half; this is what it must land on.

**At ~400 m (cresting into Band 5, z ≈ 7160):** a skyline, not a building.
The great tower (floor +5.5, tower caps to +27…+33 absolute, against
approach ground at −2…−7) crowns the WEST end; masses step DOWN eastward:
great tower → arena towers → hall roofs → bailey curtain → gatehouse. The
pylon line converges toward the tallest mass. Two silhouette rules at this
range: the roofline must break at least four times (tower / roof / parapet
/ tower — the current works breaks once), and the west shoulder must read
as the hill the Hall stands on, not as terrain about to swallow it. (The
known world-level "no aerial perspective" defect flattens every 400 m read
in the game; it is another lane's fix and this design does not depend on it.)

**At ~150 m (the Sigil Gate, z ≈ 7400):** the payoff for opening the gate.
Full massing left of the road; oxblood banner points on the gatehouse and
towers; the teal cable dropping from the last pylon onto the north-west
tower — the first moment the machinery and the architecture visibly join.
The three-tier read (bailey / halls / great tower) must be unambiguous
here, and the wall coursing must already read as texture, not as flat value.

**At ~50 m (ramp foot, z ≈ 7508):** the gatehouse owns the frame: twin
14 m flankers, framed gate arch reading as the darkest value on the face,
brazier pair burning, banners broadside to the player, arrow-slit rhythm
along the curtain, the causeway climbing ahead with kerbs, banners and
fire. The ravine falls away west of the causeway. Nothing on the skyline
behind the player's destination is untextured — there IS nothing behind it
any more.

**At the gate:** depth, finally — the one thing a box building cannot fake.
The player passes under the gatehouse (flankers proud of the curtain, gate
frame's jambs and lintel, the arch module overhead), through the 1.2 m
wall, and the view through the mouth stacks: sunlit yard floor → camp
clutter and the patrol trainer → the courtyard's far wall with lit conduit
climbing it → the halls and the great tower above. Four planes in one
doorway.

---

## 4. The kit plan

Both packs are inventoried on disk; every mesh named below exists. Native
extents measured this session (probe: OBJ vertex scan / glTF accessor
min-max). The castle kit is untextured colour-slot OBJ with **zero UVs**
(triplanar only); the medieval kit is **fully textured with real UVs**
(`T_UnevenBrick`/`T_RoundTiles`/`T_WoodTrim` + normal maps). Using the two
together — castle kit for military massing, medieval kit for roofs, stairs
and openings — is what the board's own BUILDING PIECES list describes.

Module arithmetic (castle kit at scale 2.6, the shipped castle's own):
`TallWallBricks` 1.52×2.35×0.42 native → 3.95 w × 6.11 h per course; the
second course seats at 1.408×2.6 = 3.66 (the `_why_course_seam` rule —
keep it, it is paid-for knowledge); two-course parapet top ≈ **9.8 m**.

### Tier 1 — gatehouse and north face (the shaded hero face)

- Curtain: `TallWallBricks` ×2 courses across x[−2,18] at z 7548, gate bay
  on the mouth centreline (x = 8): `TallWallEntrance` (arched) at 2.6.
- Flankers: 2 × `LargeSquareTowerBricks` @ 3.4 → 4.4 girth, 14.2 h,
  standing ~1.5 m proud of the curtain (the shipped castle's own gatehouse
  grammar), capped with `WatchTowerWRoof` tops? No — flankers keep their
  authored crowns; **one** `WatchTowerWRoof` @ 2.8 sits on the curtain
  east of the gate as the guard post.
- Over the gate: the works' existing `_build_gate_frame()` jambs + lintel
  stay; add `Wall_Arch` (medieval, 2×3 native) @ 2.2 as a blind arch over
  the lintel, timber-dark.
- The causeway (§2's 40 m ramp) gets kerbs, 3 brazier pairs and 2 banner
  pairs (§6), and `Prop_WoodenFence_Single` @ 2.0 runs as railing on the
  kerb tops — the board's timber approach.

### Tier 2 — bailey (outer_works + courtyard exterior)

- Curtain: `TallWallBricks` ×2 courses on every true exterior face (west
  run x ≈ −2/−3 over z[7548,7602] with a 1 m jog at the chamber joint —
  put the mid-wall tower on the jog; east run x ≈ 18/19 likewise). ~14
  modules per flank per course.
- Corner towers (NW, NE): `LargeSquareTowerBricks` @ 3.0 → 3.9–4.1 girth,
  12.5 h. **Mid-wall towers: `WatchTowerWRoof` @ 2.8 → 4.2 girth, 10.8 h —
  girth ≥ corner towers.** The skinny `SimpleTowerBricks` never appears on
  a wall run again; it may cap interior yard corners only. This is the
  direct fix for the judge's "sandcastle decoration" finding.
- The waist (the 9 m local gap between courtyard and tether_approach,
  z[7602,7615]): wrap with ONE course of `TallWallBricks` so bailey and
  keep read as one building; the built passage runs beneath it.
- Hoardings (the board's wall walk, delivered as exterior dressing): a
  timber walkway band along the outside of the west bailey curtain at
  parapet height — `Floor_WoodDark` @ 2.0 planks on `Prop_Support` @ 2.4
  brackets, `Prop_WoodenFence_*` railing, ~14 m of run, ending at the
  mid-wall tower. Dressing only, no colliders (`interior_structure.gd`'s
  own rule: structure is dressing; a ledge a player can stand on halfway
  up a wall is a bug). **Deliberate trade, stated:** the board asks for
  walkable elevations; the arena promises (`combat_arena_bounds_at`) and
  the interior camera profile make walkable interior platforms a genuine
  risk to the two yard fights, so elevation is delivered by the causeway
  climb, the terraced massing and exterior walkway dressing — not by
  walkable interior catwalks. If a later lane wants a real wall walk, it
  is an additive change outside the fight rooms, not a rework of this.
- Stairs as dressing at yard corners: `Stairs_Exterior_Straight` +
  `Stairs_Exterior_Platform` @ 2.0 against the courtyard NE interior
  corner (clear of both doorway lines and outside arena margin), reading
  as the way up to the parapet without being one.

### Tier 3 — the keep (the three roofed chambers)

- **tether_approach** (16×18, h 6.5): the low hall. One
  `Roof_RoundTiles_4x8` @ 2.1 → 11.6 w × 8.9 h × 20.3 d, ridge running
  north–south at ≈ +15.4 above floor, seated on the chamber roof with
  2 m flat parapet strips either side. Teal-green tile (§5).
- **warden_arena** (24×26, h 11): the great hall. Crenellated parapet on
  all exterior faces (the works' existing coping + merlon pass, promoted
  to this chamber), four corner towers `LargeTower` @ 3.2 → 4.0–4.2
  girth, 14.4 h; one `Roof_RoundTile_2x1_Long` @ 2.6 dormer mass on the
  east face for roofline variety.
- **legendary_chamber** (28×28, h 22): the great tower, the thing the
  pylon line points at. Four `LargeSquareTowerBricks` @ 5.2 → 6.7–7.1
  girth, 21.7 h, hugging the corners; `PointyTower` @ 5.2 → 28 h on the
  **south-west** corner (the skyline peak, backed by the west shoulder);
  `WatchTowerWRoof` @ 3.0 on the north-east corner; crenellated parapet
  between; the highest banner in the chapter (§6). Wall runs between the
  corner towers: `TallWallBricks` courses to close the box faces above
  the chamber's own 22 m walls' read.

### Openings — the "no arrow slits along entire wall runs" fix

Authored recessed slit boxes in the massing pass (same `_box` vocabulary
as the works' trim; the kit has no slit module and the medieval window
modules read domestic, not military):

- Curtain runs: one slit per second module bay (≈ every 8 m), 0.4 w ×
  1.8 h × 0.3 recess, at upper-course height, skipping the gate bay.
- Keep faces: paired taller lights (0.9 × 2.2) — two pairs on the arena
  east/west faces, three ranks up the great tower's north face.
- Colour: the `Black` slot's #332c24 on sunlit faces, #1a1613 on the
  north face (a shaded face needs the deeper value to read at all).
  Blind (the chambers behind are real interiors with their own light
  story); the 0.3 m recess gives them a real shadow line in sun.

### Grounding — the "not floating" fix

- The works' 18 m skirt is the plinth; the separate castle plinth is gone.
  The skirt gets the base-course + string-course treatment the works'
  chamber walls already have (extend `BASE_COURSE` to the skirt faces) in
  the darkest stone tier (§5).
- Rubble at the foot: 2–4 nature-pack boulders per exposed skirt face,
  seated half-buried, wearing the same granite triplanar
  (`_wear_the_cave_stone` treatment — T1-ARCH's proven Warrens fix), plus
  a grass-suppression / worn-earth ring at the ramp foot via the existing
  vegetation clearing mechanism (`props.json` clearing orders).
- The west skirt face is naturally half-buried in the shoulder; the east
  face shows tall and gets the most rubble and two buttress stubs
  (`WallBricks` @ 2.6 laid as pilasters).
- The ravine north-west of the causeway is dressed with the same granite
  boulders — it becomes the moat-like drop the approach skirts past.

**Estimated module count: ≈ 195–215** kit instances (vs 132 in today's
castle — and today's castle retires, so the net world change is well under
one castle). Colliders: prefab `colliders` entries for towers and
gatehouse flankers only; curtain runs hug the chamber walls, which already
carry the route's real collision. The gate bay collider stays open.

---

## 5. The material scheme

The diagnosis (judge, verified in this session's renders): the castle kit
exports every material at one placeholder grey; the repo retints by
material-name slot; a **flat colour at any value cannot produce coursing**,
and the T1-CASTLE metallic fix left the walls rendering off-white
(212,203,185 measured). Meanwhile the works walls already carry the real
answer — `T_UnevenBrick` triplanar at the measured `STONE_TILE` 0.28
(`stronghold.gd`, with its own hard-won mipmap/tiling notes) — just at an
albedo so dark it crushes. **One stone, one scale, one value ladder, both
kits:**

The mechanism: `_weather_castle()`'s slot walk already sets
`albedo_texture` + `uv1_triplanar` on the kit's stone materials — replace
its generated 96 px noise with the **`T_UnevenBrick` albedo + normal +
roughness maps at `uv1_scale` = 0.28** (identical to the works walls), and
retune the retint colours, which now act as tint over a real stone photo
(texture luminance ≈ 0.49, so tints move up ≈ one stop to compensate — the
arithmetic below is pre-multiplied and was checked against the measured
212 render).

| Slot / surface | Value | Expected render, lit / shaded | Reads as |
|---|---|---|---|
| `LightRock*` (curtains, towers) | **#f2e9da** + UnevenBrick @0.28 | ≈ 165–175 / 105–125 | warm coursed ashlar — the board's wall stone |
| `DarkRock*` (kit panel details) | **#c4b39e** + UnevenBrick @0.28 | ≈ 125–135 / 80–95 | one stop down; masonry, not pasted rectangles |
| Merlons/coping/string courses | **#f8f0e0** + UnevenBrick @0.28 | ≈ 180 / 130 | sky-lit dressed top course |
| Works exterior walls + skirt | modulate **#9c9083**, skirt **#8f8172** @ 0.22 tiling | ≈ 100–115 / 65–80 | the darkest stone: foundation tier (coarser 0.22 = bigger foundation blocks) |
| `Black*` (openings, iron) | **#332c24** flat (north-face slits #1a1613) | — | voids and iron |
| Causeway / yard floor | existing floor material, tile scale = STONE_TILE × 1.33 | — | ~0.3 m cobbles — SMALLER than the 0.4–0.5 m wall stones: the scale collision resolved by a stated ladder, not by luck |
| `Celing*` / `LightWood*` / `MI_WoodTrim` (timber: hoardings, stairs, arch, fences) | **#6f4f33** / tint (0.62,0.55,0.50) | ≈ 90 / 60 | dark timber — the board's beam colour |
| `MI_RoundTiles` (roofs) | tint **#2a8c94** over the terracotta texture | ≈ (45–55, 75–85, 60–70) | dark teal-green tile — the board's roof accent; green-dominant, never brighter than the walls |
| `MI_RockTrim` (stairs, borders) | baseline #b4b1a6 (already in `BASELINE_RETINT`) | — | pale dressed trim |
| `Banner` | **#7a2430** (unchanged — reserved oxblood) | — | Team Tether |
| Brass accent (occupation fittings, §6) | **#8a6f3a**, rough 0.55, metallic 0 | — | board 15's brass/gold |
| Tether girders / live conduit | existing `_tether_material` / `_live_material` (reserved oxblood / emissive teal) | — | unchanged, they already read |

All colour values TUNABLE; the **relationships** are the design: skirt
darkest → works walls → `DarkRock` → `LightRock` → coping lightest; roofs
and timber darker than every stone tier; gate mouth the darkest value on
the north face. The retint plumbing needs no code: `building_prefabs.gd`
`_apply_retint` already takes `{color, metallic}` dicts per slot, and the
medieval `MI_*` names retint the same way (`BASELINE_RETINT` precedent).

**How it reads at distance without turning to mush:** the coursing comes
from a 2048px photographic texture with mipmaps at a measured 3.6 m tile —
at 150 m that is real low-frequency variation, not per-pixel noise (the
exact failure `STONE_TILE`'s header documents and solved). The value
ladder does the rest: at 400 m the building separates into four flat
tones (skirt / wall / roof / timber) even if no course line survives —
which is how the keyart panels themselves work.

**Verification is part of the build:** pixel-sample a 64 px wall patch at
the §10 stands — lit flank in [150,185] mean, north face in [95,130],
patch std-dev ≥ 35 (T1-CASTLE's failed state measured 28.1). Kill criteria,
not vibes.

---

## 6. The occupation layer

The architecture is Meadows; everything Team Tether reads as **bolted on,
hung over, or wired through** — never as construction. Board 15's key
(dark stone, dark metal, brass, teal energy, runic glow, chains), the
pylons' proven in-game language, and the keyart panel's banners-scaffolds-
apparatus trio.

1. **The cable lands on the building.** One `severed_spokes` conduit span
   from the last pylon's head (−8, 7505, 12 m) up to a brass-and-oxblood
   anchor bracket on the **north-west bailey tower** (~+12 above floor):
   ≈ 46 m span, sag-checked against the probe (mid-span clears the ground
   by ~10 m). From the anchor, lit teal conduit runs (existing works
   vocabulary) over the west curtain, down into the courtyard junction,
   then into `tether_approach` — joining the interior conduits that
   already all point at the legendary chamber. The player walks the
   power's own path. This is the single highest-value occupation object:
   it is the moment the judge's praised pylons and the condemned building
   become one system.
2. **Banners.** Gate flankers: one oxblood banner each, broadside to the
   approach (`Banner.obj`'s cloth plane is local X-Y — yaw 0 on a ±z face
   is broadside; verified from vertex data, see §12.2). Curtain run: the
   existing rhythm, re-spaced to the new north face. Great tower: the
   chapter's highest banner. Causeway kerbs: two pairs. **And one story
   beat:** a single faded **Meadows-blue** banner (#3d4a63, per-placement
   `apply_retint` — the mechanism exists) hanging torn on the west bailey
   wall, half-height, below a fresh oxblood one. The seizure, read in one
   glance, using zero new assets.
3. **Hardware.** The works' H-motif (girder + pillars + conduit) survives
   but **varies per wall** — `_dress_exterior_wall` already takes flags;
   extend to a per-wall subset {girder, pillar-pair, conduit, banner-pair}
   so no two adjacent walls carry the identical stamp (the handover's own
   §7.4 suggestion; the current copy-paste read is visible in this
   session's S-ext-02). Brass end-caps (#8a6f3a) on girder terminations.
4. **The yard apparatus.** One `relay_apparatus.glb` instance in the
   courtyard (scaled to ~4 m — board 14 shows a squat machine, never
   taller than a hall), fenced by tether girders, as the Hall's own
   distribution hub; the outer_works yard gets the garrison camp
   (existing waystop/camp prop vocabulary: tents, crates, brazier) around
   the patrol trainer. Board's Inner Yard stalls → occupation tents: same
   composition, hostile owner.
5. **Fire.** Port `stronghold_occupation.gd`'s validated brazier/flicker
   recipe (housing/lens ratios, flicker numbers — read it for technique,
   do not extend it in place) to: 3 causeway pairs + 2 gate braziers.
   These replace, not join, the bare static fire points where they
   coincide (§7 light budget).
6. **Drain.** Extend `approach_drain.bounds` south to the skirt foot
   (z 7530 → 7548 edge) so the drained-ground skin reaches the building
   that is doing the draining.

Reserved-colour discipline holds throughout: oxblood and teal appear ONLY
on Tether elements; the Hall's own stone/timber/roof palette never uses
either; brass appears only on Tether fittings.

---

## 7. Performance budget

Target hardware: ROG Ally. Measured with `tools/perf_render_stats.gd`
(`stronghold_approach` view is built in; its header is right that llvmpipe
frame TIME is meaningless and the structural counters — draw calls,
primitives, objects — are what carry).

**Baseline (this session, `main` @ a97f3e84, `--label=main-baseline`):**
run was started; the implementer re-runs the same command before changing
anything and records both numbers in their report:

```
xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 \
  --resolution 1280x720 --script tools/perf_render_stats.gd -- --label=before
```

**The budget, in structural terms:**

- **Kit instances:** ≤ 215 modules in the `meadows_hall` prefab (vs 132 in
  the retiring castle). Since the castle's 132 disappear from the world,
  the net world-level module change is **≤ +85**, all at one site the
  player reaches once.
- **Draw calls at `stronghold_approach`:** the after number must be
  **≤ the before number + 15 %**, and the view now contains the ENTIRE
  merged location (today the same view carries the works AND the castle's
  132 modules on the skyline — merging removes a whole building from the
  scene; spending part of that back on massing is the trade, and it is
  measured, not assumed).
- **Lights:** ≤ **18 unshadowed OmniLights exterior** at the Hall (gate
  fire 4 + gate sky-fill 1 + causeway braziers 6 + flank fire 4 + flank
  sky-fill 2 + yard 1), versus **46 today across the two buildings**
  (works 28 + castle occupation ~18). The halved flank arrays are paid
  for by §5's brighter wall values; the gate keeps its proven recipe.
  Interior lights (12) unchanged — they were measured against the finale's
  readability and are not this design's to spend.
- **Materials:** everything shared — one material instance per retint
  slot (the composer already guarantees this), one triplanar stone
  texture set shared by both kits' stone, no per-instance duplicates.
  No shadowed lights anywhere. No new shaders.
- The structural members (407) and conduits inside the works are
  untouched by this design.

If the after-measurement blows the +15 % line, the cut order is: south
(rear) curtain course → hoarding walkway → per-wall slit density halved →
one keep corner tower tier down. Never cut: the gatehouse, the great
tower, the cable landing, the coursing texture.

---

## 8. The interior route, chamber by chamber

**The route's logical structure is untouched.** Five chambers, same ids,
same order, same sizes, same passages, same one door
(`defeated_stronghold_elite`), same gauntlet rows (`stronghold_patrol` /
`stronghold_courtyard` / `stronghold_elite`), same recovery bed, same
machine, same five marks (`warden_stand`, `warden_challenge`,
`reveal_stand`, `machine_foot`, `legendary_stand`), same flags. All three
smoke tests (`smoke_stronghold`, `smoke_gate_e_finale`,
`smoke_stronghold_reload`) must pass **unmodified** — they interrogate the
built node, so the re-site is invisible to them by construction.

What the redesign gives each space:

| Chamber | Was | Becomes |
|---|---|---|
| `outer_works` | bare yard | the **gatehouse yard**: garrison camp around the patrol trainer, gate passage behind, bailey curtain above, first read of Meadows masonry wearing Tether hardware |
| `courtyard` | bare yard | the **inner bailey**, standing on the hill's own +4.8 rise: courtyard trainer, relay apparatus hub, conduit descending the far wall, stair dressing to the parapet, the keep looming south |
| `tether_approach` | roofed box | the **undercroft** of the low hall: most machine per metre, elite + blast door + recovery bed unchanged; exterior gains the teal-tiled roof |
| `warden_arena` | roofed box, deliberately empty | the **great hall**: still deliberately empty (the fight owns the floor); exterior gains parapet + corner towers |
| `legendary_chamber` | roofed box | the **great tower**: machine unchanged at `machine_foot`; exterior is the chapter's skyline peak, the pylon line's visible destination |

Interior dressing stays `interior_structure.gd` (load-bearing, owner-liked
at the Warrens; its masonry vocabulary — `jitter: 0`, corbels, bays — is
already the works' config and is not reopened). The interior camera
profile, arena margins and doorway rules all hold; nothing in §4 or §6
places geometry inside a chamber except where stated (camp props, relay
hub, stair dressing), and each of those placements obeys the existing
doorway-clearance and arena-margin rules the yard trainers already impose.

---

## 9. Implementation order (bounded lanes, each shippable)

1. **Re-site** — config only: `site.at` (8,7560), `yaw_deg` 0, `ramp_run`
   40; move the map pin; re-run `_probe_hall_site.gd`, all three smoke
   tests, and a before frame. (The works now faces the corridor; the old
   castle still stands 145 m east until step 3.)
2. **Massing** — the `meadows_hall` prefab (§4) + `_build_hall_massing()`
   in `stronghold.gd` + slit pass + skirt courses/rubble. Smoke tests.
3. **Retire the castle** — unhook LANDMARK from `playground_world.gd`;
   nothing stands at (150,7595). Must land with or after 2, never before
   (the corridor must never aim at nothing).
4. **Materials** — §5's ladder on both kits + works retune + roof/timber
   tints; retire the facing skin; pixel-sample verification.
5. **Occupation** — §6: cable landing, banner set + blue relic, H-motif
   variation, relay hub, brazier port, drain extension; light budget
   enforcement (§7).
6. **Evidence** — new capture stands (§10), perf after-run, then hand the
   frames to the independent judge. Not this lane, and not the lane that
   built it, per the owner's separation.

---

## 10. Capture stands for the judge

`_judge_capture_arch_0829.gd`'s castle/stronghold stands point at retired
geometry after this lands. The evidence lane authors a successor
(`tools/_judge_capture_hall.gd`) with these stands (world coords, eye
+1.7 m above ground unless noted, all with Terrain3D handed the camera —
the tool's own streamed-ground fix):

| Stand | At | Looking | What it judges |
|---|---|---|---|
| H-01 approach-400 | (0, 7160), +8 m | S at the Hall | skyline tiers, pylon convergence |
| H-02 sigil-gate | (63.6, 7395) | SW | full massing, three tiers, cable landing |
| H-03 ramp-foot | (8, 7505) | S | gatehouse dominance, causeway, gate depth |
| H-04 gate-mouth | (8, 7551), on the ramp | S through the gate | the four-plane doorway stack |
| H-05 east-flank | (48, 7590), +6 m | W | sunlit flank: coursing, ladder, slits, waist |
| H-06 west-keep | (−60, 7630), +10 m | E | great tower vs shoulder, hoarding, blue banner |
| H-07 courtyard | inside, at the courtyard trainer | S | yard read, relay hub, conduit descent |
| H-08 wall-close | (14, 7542) | N wall at 6 m | stone scale ladder vs causeway cobbles |

Day keyframe for all; H-03 repeated at `golden` and `night` (the gate face
is the shaded face — §2 — so its dusk/night self-lit read is part of the
design and must be judged, not just the noon state).

---

## 11. Acceptance list

Derived from the board's CASTLE NOTES and the judge's named defects; each
item is checkable from the §10 frames or the tree, so "did we fix it" is
answerable.

**From the CASTLE NOTES:**
1. Uses existing Quaternius packs — the diff adds zero meshes and spends
   zero Meshy generations.
2. Larger scale, layered walls — three tiers (bailey ~10 m / halls
   11–15 m / great tower 22–33 m) legible at H-02; roofline breaks ≥ 4
   times at H-01.
3. Multiple elevations and walkways — causeway climb ≥ 8 m visible at
   H-03; hoarding + stairs read at H-06/H-07.
4. Functional, military feel — no curtain run > 12 m without an opening;
   gate has frame, reveal and depth (H-04); mid-wall tower girth ≥ 0.9×
   corner tower girth.
5. Fits the Meadows (not floating) — no open shadow gap under any face in
   any stand; rubble/shoulder transitions at H-05/H-06; the west skirt
   partially buried in real terrain.
6. Extensible for siege/defense — continuous parapet line, open yards,
   nothing blocks a future walkable wall walk.

**From the judge's defects:**
7. Coursing reads at H-02 (150 m) and H-05; wall patch std-dev ≥ 35; lit
   wall mean in [150,185] — not (212,203,185).
8. Wall stone ≥ ground cobble scale, ratio stated and ≤ 1.5:1 at H-08 —
   no 2–3× collision.
9. ONE building: no structure at (150,7595); no untextured mass anywhere
   in H-01..H-08; map pin at the Hall.
10. Occupation reads: banners + hardware + live energy all present at
    H-02; the cable physically joins the building; oxblood/teal appear
    only on Tether elements; the H-motif differs between adjacent walls.
11. The mouth faces the arriving player (gate visible in H-01/H-02/H-03
    dead ahead); `yaw_deg` is re-derived and its comment rewritten.
12. Route intact: all three smoke tests pass unmodified; the build log
    prints 5 spaces, 3 gauntlet trainers, 15 pylons.
13. Budget: ≤ 18 exterior omnis at the site; draw calls at
    `stronghold_approach` ≤ before + 15 %.
14. The night/golden gate read (H-03 variants) is self-lit and legible —
    braziers + conduit + banners, no black crush.

---

## 12. Corrections and disagreements (read before building)

1. **The brief's "re-derive the yaw" is necessary but not free.** The sun
   is now authored in the SOUTH sky (`art.json` yaw 140, flipped by
   VISUAL-LIGHT after the brief's source reports were written). The
   re-derived north-facing gate is a shaded face at the day keyframe.
   §2/§5/§6 own this deliberately (light stone + fire recipe + self-lit
   occupation on that face; sunlit flanks carry the coursing evidence).
   Do not "fix" this by flipping the sun back — every other south-facing
   hero face in the chapter depends on it.
2. **The handover's banner-rotation hypothesis (§5 of
   `handover-T1-ARCH-STRONGHOLD-2026-08-29.md`) does not hold for the
   castle.** `Banner.obj`'s cloth spans local X (arm to x 0.673) and Y,
   thin in Z — at `yaw_deg: 0` on a ±z-facing wall the cloth is BROADSIDE
   to the approach. The castle's banners were visible in the judge's own
   frames ("flags" in its C-02 read) and in this session's re-render. No
   castle banner fix is needed; the stronghold lane's fix was correct for
   its different mounting (arm along the outward normal).
3. **The state-of-tracks doc's "there is no architectural massing board
   anywhere in the repo" is wrong**, as the brief already flagged — the
   board is at `docs/reference/owner-board-2026-08-15-systems-and-castle.png`
   (not `docs/art/reference/`), and `building_prefabs.json`'s `_why`
   already cites it. Verified by opening it.
4. **"The retint is the lever" (brief §diagnosis) is half the lever.** A
   flat colour at any value cannot produce coursing; the works walls
   already prove the real fix (a textured stone triplanar at a measured
   scale). §5 uses retint AND texture. The retint alone would have been
   the fourth value-retune to fail the same way.
5. **The T1-ARCH-STRONGHOLD dressing is on main and helps** — this
   session's S-frames show crenellation, hardware, banners and a framed
   gate the judge's pre-dressing frames lack. The judge's BAD verdicts
   describe a state that has since moved; what has NOT moved is massing
   (one flat roofline), value (still dark), scale (1 m wall stones), and
   the two-building vista — which is what this design addresses.
6. **28 exterior omnis at the works confirmed** (12 `lights` + 16
   `lights_flanks`), never measured. §7 cuts the merged site to ≤ 18 and
   makes the measurement part of acceptance.

## 13. Open questions for the owner (none block the build)

- **Roof accent**: §5 commits to the board's dark teal-green tile. If the
  owner reads the board's keep caps as dark timber instead, swap
  `MI_RoundTiles`' tint for #4a3a2c and nothing else changes.
- **The blue relic banner** (§6.2) invents one story beat (a torn Meadows
  banner under the Tether ones). It is one prop and one tint; delete it if
  it oversteps.
