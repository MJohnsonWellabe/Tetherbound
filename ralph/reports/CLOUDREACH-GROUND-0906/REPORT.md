# CLOUDREACH-GROUND-0906 — collision ground truth, aviary hookup, blind render verdict

Branch `claude/cloudreach-ground-0906`, off the WIP head `e9b8a6f5` (per-vertex
shoulder clamping, flat pad crowns, ground-truth probe). Owner items: OP-0905-24
("you can walk through too many spots and fall"), OP-0905-25 ("you walk half way
in the ground"), OP-0906-05 (domed aviary stronghold, rustic stone kept), and the
2026-09-06 look addendum already on the branch.

Godot 4.7-stable installed exactly as `.github/actions/setup-godot/action.yml`
does; `godot --headless --path . --import` once (0 import errors); every run
below is the Cloudreach scene on its own (30-90 s boot), never a Meadows boot.

## Part 1 — collision ground truth

### Reproduction on the WIP head (before any change)

Contrary to the brief's snapshot, both walk smokes already passed on the WIP head
as committed; the probe numbers had moved since the brief was written:

| Run on `e9b8a6f5` | Result |
|---|---|
| `tests/smoke_cloudreach_arrival_walk.gd` | `CLOUDREACH ARRIVAL WALK OK player=(-275.1383, 180.1488, 517.5167)` |
| `tests/smoke_cloudreach_summit_road.gd` | `CLOUDREACH SUMMIT ROAD PASS from=(300.0, 1080.06, 5100.0) to=(100.2746, 1160.197, 5349.655)` |
| `tests/smoke_cloudreach_ground_truth.gd` | 3,782 samples, **0 holes, 819 mismatches (21.7 %)**; 661 on pad crowns, 116 on shoulders, 40 on landmark ledges |

Diagnosis with `tests/smoke_cloudreach_stuck_probe.gd` (down-rays every metre
along both approaches, a lateral profile at the stuck radius, forward rays at six
heights, every collider named):

- Arrival, pad (-80,130,40): at 13-14 m before the pad the road ribbon
  `ArrivalGateRoad_0Ground0` sat at y 129.37-129.46 while `ArrivalGateRoad_Ledge1`'s
  eased rim and `Ridge000` sat at 128.9-129.0 — the crown and shoulder had been
  eased toward the authored centre-to-centre polyline, which is 0.5 m lower than
  the real ribbon there because `_build_routes` shortens every ribbon to the pad's
  cap edge (`_landing_join`) and so climbs a steeper straight. Forward rays at
  0.1-0.5 m hit `ArrivalGateRoad_Ledge1` with an upward normal (a slope, which is
  why the walk still passed) — a 0.4-0.5 m visible-vs-collision disagreement,
  i.e. OP-0905-25.
- Summit, pad (100,1160,5350): at 8 m out `SummitOverlookLoop_LedgeCap0` (a 13.1 m
  square) stood at 1159.98 over a ribbon at 1159.43, a 0.55 m lip on the diagonal
  approach; `LandmarkLedge` sat 1.9 m under the ribbon at 14 m out (eased to the
  polyline, not the ribbon).
- Pad-crown mismatches at large (0.2-1.3 m): the shoulder strip was pinned only at
  its 16 m stations, so the straight interpolation between a pinned station inside
  a pad disc and a free one outside carried the road's rise back over the flat
  crown.

### What changed (`scripts/world/cloudreach_world.gd`)

One road-network height model, used by ribbons, crowns and shoulders alike:

1. `_collect_all_route_lines` records the **real** walking surface: every ribbon
   section join-to-join, the flat `pad -> join` cap stubs, bridge decks with their
   own joins and stone lift, and the hidden walkable-crown boxes (observatory
   38x36, the overlook's two sloped strips, both settlement terraces) as wide
   reference lines; landing pads and collidable landmark ledges as discs with a
   flat radius and a cap radius.
2. `_nearest_route_line` / `_line_eased_height`: a vertex covered by a line
   (inside half_width + 1 m) takes the **highest** covering line's height, else
   the most-enclosing line eases it back to natural over 6 m. `_crown_height_at`:
   authored height inside the cap, then that easing — up as well as down, so a
   road leaving a pad no longer floats an invisible ribbon box above the crown.
   `_walkable_height` adds the pad-disc clamp for shoulder vertices.
3. Pad/landmark crowns (`_mesa`, `_emit_flat_crown`): apex fan plus ~3 m rings
   from the cap radius to the rim, every ring vertex from `_crown_height_at`;
   visible top and trimesh collider from the same rings (R1).
4. Shoulders (`_route_ridge`, `_emit_shoulder_top`): station centres sit on the
   route's own ribbon height; the walkable top is a seven-column grid densified
   to ~4 m rows wherever a feature can bend it, every vertex through
   `_walkable_height`; the first cliff band hangs from those rows; the collider
   is the same grid.
5. `LedgeCap` is a disc of the cap radius 0.05 m under the crown (`_disc`), never
   above it; the waterward overlook ledge now collides and follows its strips.

Interpretation of R2's "cap radius": the flat region is the 0.41 x landing_size
cap the ribbons reach at pad height (6.56 m), and the crown is eased from there
out to the 0.82 x flat rim (13.1 m). The overlook pad has no flat cap (its strips
slope through the centre).

### Probe changes (`tests/smoke_cloudreach_ground_truth.gd`)

- Names the collider under every mismatch.
- Counts a sample whose surface lies **under other visible geometry** (a region
  crown over a road, a rock shelf over a shoulder, the shrine dais, two crossing
  shoulders) separately as `buried`, since the walker stands on what they see;
  a collider **below** the rendered surface (sink) or an **invisible** collider
  above it (float) stays a mismatch.
- Passes at 0 holes and <= 1 % mismatches (regression guard; the brief's bar was
  3 %). The `UpperKeep` spot-check is now `AviaryPier`.

### Rounds

| Round | Change | Holes | Mismatches | Samples | arrival / summit / causeway |
|---|---|---|---|---|---|
| 0 (WIP head) | — | 0 | 819 (21.7 %) | 3,782 | OK / PASS / (PASS) |
| 1 | joined lines, ring crowns, grid shoulders, disc caps | 0 | 1,449 (4.75 %) | 30,486 | OK / PASS / PASS |
| 2 | crowns rise too, most-enclosing line, overlook/observatory strips, probe `buried` class | 0 | 134 (0.44 %) + 683 buried | 30,486 | OK / PASS / PASS |
| 3 | overlook ledge collides, settlement terraces as lines, cap sentinel | 0 | 222 (0.72 %) + 728 buried | 30,922 | OK / PASS / PASS |
| 4 | highest covering line wins | **0** | **26 (0.08 %)** + 793 buried | 30,922 | **OK / PASS / PASS** |

Round-4 residue (26): seven unnamed prop floors 0.24 m over the waycamp pad, two
NPC bodies standing on a pad, thirteen 0.15-0.3 m lips where another route's
ribbon crosses a shoulder near a junction, one traversal-gate node 0.55 m above
its ridge, three singletons.

Final pass lines (round 4, after the aviary hookup):

```
CLOUDREACH ARRIVAL WALK OK player=(-275.143, 180.031, 517.5059)
CLOUDREACH SUMMIT ROAD PASS from=(300.0, 1080.06, 5100.0) to=(100.1869, 1160.131, 5349.703) distance_m=331.5
CLOUDREACH CAUSEWAY CROSSING PASS at=(119.6497, 420.0309, 1829.487)
CLOUDREACH GROUND TRUTH: 30922 sample points checked, 0 holes, 26 height mismatches (>0.15m), 793 buried under visible geometry
CLOUDREACH GROUND TRUTH: mismatch rate 0.08% (holes + mismatches over samples)
CLOUDREACH FOUNDATION OK regions=6 landmarks=12 bridges=5 player=(0.0, 105.0302, -260.0)
CLOUDREACH LOOK OK bridges_rails=14 posts=798 moorings=9 cover_main=127882 cover_far=24533 cover_alpine=4194 trees=86 stones=79 settlement_overrides=420 guy_ropes=16
```

Trimesh triangles 271,551 -> 341,481 (colliders 2,017 -> 2,036).

## Part 2 — the domed aviary in the world

`_build_summit_stronghold` now drops UpperKeep + cornices, the Crenellation row,
the four SummitWatchtowers, TetherCrown, GateBridge and the SummitGatehouse piece
(and, in `_develop_stronghold_spaces`, the tower masonry courses, splayed bases,
tower banners and gatehouse buttress courses that dressed them), builds the aviary
via `cloudreach_aviary.gd` with the world's masonry / stone / wood / rope /
wind-veil materials, an iron material and an emissive lantern, and places
`OccupiedSummitPylon` (18 m) at the returned `pylon_anchor` on a new iron
`TetherMountPlate` spanning the oculus ring. Kept: both route wings (lowered
from 28 m to 14 m so they sit under the dome; portal clearance 8 m unchanged),
WingButtress, GateThreshold, the four corner pylons (now on the ground at
(+-24, +-20.5)), banners (on the wings' south gables), the rear courtyard arcade,
braziers, props, approach edges.

Drum vs wings: with the authored 22x20 ellipse the drum wall ran through the east
wing's z=7.5 portal band (wall points at 31-38 deg sit at z 10.3-12.3 inside
x 17-19). Fix in `data/config/cloudreach_aviary.json`: a 27 m circle (wall
outside the wings' x=+-26 face), throat half-angle 32 deg (opening z=+-16.6,
clearing the 7 m ribbon that leaves through the portal at z~11 by x=27), piers
at 55/125/235/305 deg, dome radius 27 (apex 36 m, 20x trainer), perches to 24 m.

```
CLOUDREACH AVIARY: drum_height=9.00m (5.0x trainer) apex_height=36.00m (20.0x trainer) oculus_height=35.32m oculus_radius=6.00m
CLOUDREACH AVIARY FIXTURE PASS
CLOUDREACH SUMMIT ROAD PASS from=(300.0, 1080.06, 5100.0) to=(100.1869, 1160.131, 5349.703) distance_m=331.5
CLOUDREACH FINALE FIXTURE PASS: body/input/collision, three relays, saved phase, aftermath, recovery
CLOUDREACH PRODUCTION INTEGRATION PASS failures=0
```

`smoke_cloudreach_production_integration` was red on the parent at "every relay
housing has actor/camera collision": it expected three `RelayHousingCollision`
bodies while `cloudreach_summit_presentation.gd` deliberately leaves the crown
relay non-colliding and `smoke_cloudreach_post_relay_exit` requires exactly that
(both landed in the same "consolidate" commit). The check now expects the two
side housings.

## Part 3 — render and judge

Render: `xvfb-run -a -s "-screen 0 1280x800x24" godot --path . --rendering-driver
opengl3 --resolution 1280x800 --script tools/capture_cloudreach_environment_correction.gd`
(twelve stands, ~45 min under software GL: ~9 min boot, 2-4 min per stand — a
25 min `timeout` wrapper killed the first attempt at four frames). Frames were
copied to scratch, one sheet per round built with `tools/sheet.py --cols 3`, the
capture directory reset with `git checkout --`/`rm`, and a code-blind sub-agent
given the sheet, the frames and `docs/reference/` only.

### Round 1 — `_sheet_after.png`, `JUDGE-after.md`

The look pass already on the branch is visible in the frames (banded cliff
strata in 01/02/03/08/12, rope rails and posts on the causeway in 02, slate
roofs and grey walls on the cliffside settlement in 02/08/12, retinted trees and
stones, thinner distant fog), and the summit approach (06) shows the lattice dome
over the drum with the tether machine in the oculus.

Verdict: A **no**, B **no** on eleven of twelve (11-aerie-ground-connection
passes). Twenty defects; the top three separations are altitude/horizon (no
drop, a hard fog plane), landform and hero finish (the summit dome "reads as a
birdcage or greenhouse frame under construction" with "flat, untextured
rust-red slabs" for its gate, the 05 cliff a blockout), and ground density /
grounding. In-scope findings taken into the fix round:

| Finding (frame) | Root cause | Fix |
|---|---|---|
| Radial seam lines fanning from the trainer's feet (05) | two routes share that pad and each built a crown at the same height; the green and dry turf crowns z-fought as alternating wedges | one crown per pad position (`_built_pad_keys`) |
| Rust-red untextured gate slabs, placeholder-glass panels (06) | the aviary drum/arches used the flat brown `stone` material; veils at alpha 0.24 | drum/arches/piers on the wings' mossy masonry family; veils alpha 0.13, emission 0.3; lit graphite iron; 3.2 m mount plate; 24 meridians / 9 rings |
| Hard-edged dark/green terrain patches in front of the gate (06) | the 18 m bare tuft lane of the approach cover exclusion against dense dark tufts | lane half-width 9 -> 5.5 m |
| Wax-white translucent boulders (03/06/11/12) | the stylised rock kit's pale base colour | `apply_stone_palette`: cool mid-grey, roughness 1, on every placed Rock_Medium_* (cached duplicate) |
| Pumpkin-orange path (04/08/12) | trail soil tint `#9b805f` | `#9a8c72` |

Not addressable inside `cloudreach_world.gd` / `cloudreach_look.gd` /
`cloudreach_look.json` / the cliff shader in one round, and left as findings:
the horizon/haze band and cloud layer below the cliff edge, sun angle and
shadow sides, the rock kit's tan banding vs the board's grey-green granite,
the floating-fragment read of the high roost (04/11), grass extent and its
cutoff line, the aerie's wisp wrap (11), the tower lids and roof guy-ropes on
the cottages (the ropes are the look lane's OP-0906-03 reading and
`smoke_cloudreach_look` counts them), creature coverage and finish, the arena
(09) reading as empty, and the survey cameras placing landmarks behind the
trainer's head.

### Round 2 — `_sheet_after2.png`, `JUDGE-after2.md`

Verdict: A **no, narrowly** (carried by the village stands, the trainer, the
oak; sunk by the one-value lime ground, the striped tan rock, the empty cyan
sky and hard noon light); B **no** (no vertical or haze, a flat lime plane past
three metres, creatures small and style-split in 11). Sixteen defects. Against
round 1, item by item on the in-scope fixes:

| Round-1 finding | Round 2 |
|---|---|
| Radial seams from the trainer's feet (05) | no longer listed; the crop still shows faint alternating wedges across the pad's apex fan (the 0.8 x 6.5 m slivers themselves), fixed after this round by near-square rings from a 2 m hub -- see the scratch capture below |
| Rust-red untextured gate slabs, placeholder glass (06) | gone: the dome now "spans a mossy stone-block curtain wall"; the remaining criticism is that the lattice is an "unbuilt planetarium frame / giant birdcage" with nothing inside it (no interior, no story) |
| Hard-edged terrain patches before the gate (06) | still listed ("dark brown paper-fold facets alternating with green triangles"): the narrower bare lane did not change the read; the dark areas are the dense dark tuft carpet against the bare-turf lane and the dry/green turf boundary, not mesh facets |
| Wax-white boulders | look-pass and route-edge rocks now read as "mid-grey round boulders" (01, 02-lower); the ones placed through `_place_local_prop` (06 left, 03 right, 12 foreground) were missed and still read as "jade or ice" -- fixed after this round |
| Pumpkin path | no longer listed |

Trajectory: A no -> no (narrowly); B no on 11/12 -> no. The judge's top three
separations did not move because none of them is in this lane's scope: no
vertical/atmosphere, a flat lime ground plane beyond the foreground, and hero
objects/creatures that do not carry the frame. The rubric's stop rule (two
rounds naming no new defect and moving no measured axis) was not reached; the
one-round budget was.

### After round 2 — scratch capture of stands 05 and 06 only

`_sheet_after3_stands05_06.png` (left column round 2, right column the scratch
two-stand capture on the final code). Two scratch captures were run: on the
ring-crown code the radial spokes in 05 were gone but a coarser pattern of
light dry-turf bands remained across the green pad -- the dry route's shoulder,
pinned exactly onto the green crown inside its disc, z-fought with it; with
shoulders 2 cm under a crown inside its disc (the committed code; collider
difference 2 cm, inside the probe's 0.15 m) the pad under the trainer is plain
turf. In 06 the drum is mossy masonry, the veils faint, the lattice denser, the
mount plate narrow, and the gate-flank boulders grey; the dark tuft carpet
either side of the bare lane is unchanged and reads as the judge described.

Final smoke set on the committed code (round 10): ground_truth PASS (0 holes,
33 of 41,219 = 0.08 %), arrival_walk OK, summit_road PASS, causeway_crossing
PASS, foundation OK, look OK, finale PASS, production_integration PASS, aviary
PASS; empty `^ERROR` / `SCRIPT ERROR` set. Sample count grew from 30,922 to
41,219 with the denser crown rings.

## Every test command run

```
godot --headless --path . --import
godot --headless --path . --check-only --script <each edited .gd>
godot --headless --path . --script tests/smoke_cloudreach_stuck_probe.gd
godot --headless --path . --script tests/smoke_cloudreach_ground_truth.gd      (rounds 0-10)
godot --headless --path . --script tests/smoke_cloudreach_arrival_walk.gd      (rounds 0-10)
godot --headless --path . --script tests/smoke_cloudreach_summit_road.gd       (rounds 0-10)
godot --headless --path . --script tests/smoke_cloudreach_causeway_crossing.gd (rounds 1-10)
godot --headless --path . --script tests/smoke_cloudreach_aviary.gd            (rounds 2, 3, 6, 7)
godot --headless --path . --script tests/smoke_cloudreach_finale.gd            (rounds 3, 6-10)
godot --headless --path . --script tests/smoke_cloudreach_production_integration.gd (rounds 3-4, 6-10)
godot --headless --path . --script tests/smoke_cloudreach_foundation.gd        (rounds 3, 6-10)
godot --headless --path . --script tests/smoke_cloudreach_look.gd              (rounds 3, 6-10)
xvfb-run -a -s "-screen 0 1280x800x24" godot --path . --rendering-driver opengl3 --resolution 1280x800 --script tools/capture_cloudreach_environment_correction.gd   (twice: rounds 1 and 2)
xvfb-run ... --script tools/_capture_two_stands_tmp.gd   (scratch, stands 05/06 only, twice; the script is not committed)
python3 tools/sheet.py --cols 3 --out ... <twelve frames>
```

An early round-0 attempt was launched before the import had finished (the world
script failed to preload unimported assets and the player fell); it was killed
and discarded, and every number above is from runs after the import completed.

## Distinct `^ERROR:` / `SCRIPT ERROR` set from the Cloudreach smokes

Empty in every committed round (1-4, 7, 9, 10) across ground_truth,
arrival_walk, summit_road, causeway_crossing, finale, production_integration,
foundation, look and aviary (grep `^ERROR|SCRIPT ERROR` over every log). Round
6, never committed, grew the set by one line -- `ERROR: Parameter "material"
is null.` x7,248 per boot from `material_get_instance_shader_parameters`
(dummy renderer) -- caused by a fresh duplicate material per placed rock; a
20-rock isolation probe showed the cached duplicate raises nothing, and the
committed code caches. The rendering runs add only the ALSA `ERR_CANT_OPEN`
(no audio device under xvfb).

## What remains and why

- **Altitude, horizon, haze and cloud layer** (the judge's top separation in both
  rounds): needs the atmosphere/fog/cloud-sea work and vantage authoring, outside
  `cloudreach_world.gd`/`cloudreach_look.gd` in one round. The look lane's fog
  thinning is in the frames; a haze band and a cloud plane below the cliff edge
  are not.
- **Rock kit and cliff language**: the banded tan hoodoos vs the board's grey-green
  granite, and the 8 m "cliffs"; a landform/asset question, not a scene tweak.
- **The dome reads as a cage/scaffold rather than a finished aviary** even at 24
  meridians / 9 rings with the wings' masonry on the drum; the owner's directive
  is an open lattice, so the next lever is dressing (more perches, nets, hanging
  cloth, birds) or a translucent membrane between ribs — a design choice to put
  to the owner, not a silent swap.
- **Boulders through `_place_local_prop`** were missed by the first stone retint
  and still render wax-white in `_sheet_after2.png` (06 foreground, 03 right);
  the retint now covers that path too (round 8 smokes green) but no third
  twelve-stand render was run — the two-stand scratch capture below is the
  evidence for 05/06 only.
- **Residual ground-truth mismatches (22 / 0.08 %)**: unnamed prop floors on the
  waycamp pad, two NPC bodies, 0.15-0.3 m lips where another route's ribbon
  crosses a shoulder near a junction, one traversal gate 0.55 m above its ridge.
- **Survey convention** places every landmark behind the trainer's head; the
  judge asked for recomposed stands. Not changed here (the capture tool is the
  shared evidence baseline for the ENV-CORRECTION rounds).
- **Cottage guy-ropes and tower lids** (judge defect 9) are the look lane's
  OP-0906-03 reading and are counted by `smoke_cloudreach_look`; left for the
  owner to rule on.
- **Creatures**: one stand in twelve shows any; scale and finish mismatches are
  content, not this lane.
- **Commit shape**: Parts 1 and 2 landed in one commit rather than two, because
  the aviary hookup was applied while round 2's ground-truth run was in flight
  and the only tested states after that carried both.
- **A third twelve-stand render was not run** after the post-round-2 fixes
  (ring crowns, shoulder z-fight, prop rocks, coverage extent); the evidence for
  those is the two-stand scratch capture and the round-10 smokes.
