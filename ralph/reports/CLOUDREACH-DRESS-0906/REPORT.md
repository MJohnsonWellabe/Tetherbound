# CLOUDREACH-DRESS-0906 — C6, C7, C8, X3 and the stand-11 blobs

Lane: Cloudreach dressing. Branch `claude/art-cloudreach-dressing-0906`, based on
`claude/second-biome-art-plan-470zru` (which already carried the main merge,
cliff option A, the realm-wide turf fill and crown relief). No pull request.

**Read §2 first if you only read one section.** The stated bar for this round was
"done is the blind judge no longer naming the gap". By that bar **C6, C7 and C8
are NOT closed.** `JUDGE-after.md` was asked the three questions directly and
answered no to all three. What follows separates what measurably changed, what
did not, and which of the remaining reasons belong to this lane at all.

---

## 1. One correction to the brief, on a point of fact

The standing brief lists `Torch_Metal`, `Cage_Small`, `Chain_Coil`,
`Lantern_Wall`, `Banner_1/2`, `CandleStick_Stand`, `Barrel_Holder`, `Rope_2/3`,
`WeaponStand`, `Dummy`, `Cauldron` and the `Stall_*` pieces as already installed.
None were. The installed prop set was a *different* sixteen — Anvil_Log,
Axe_Bronze, Bag, Barrel, Barrel_Apples, Bed_Twin1, Bench, Bucket_Wooden_1,
Cabinet, Crate_Wooden, FarmCrate_Apple, FarmCrate_Empty, Pickaxe_Bronze, Rope_1,
Whetstone, Workbench — which is why the count matched while the contents did not.
Of the medieval modules the brief named, only `Prop_Support`, `Stairs_Exterior_*`
and `WindowShutters_*` were installed.

The brief's conclusion was still right and is what this round did: the art was
already in the repo under `assets_raw/vendor/`. **Nothing was downloaded and
Meshy was not used.** All 34 files needed only their `.gltf` + `.bin`; every
material resolves against shared trim textures already installed, so not one
texture file was added.

**Ledger rows landed** — confirmed in `docs/specs/ASSET_LEDGER.md`, two new rows
committed in the same commit as the files (`0d25491e`), citing the two existing
vendored megakit rows they were installed from. Audited on install for the
absent-`metallicFactor` glTF defect that renders a prop as a black silhouette:
**0 of 34** are exposed to it — every material carries an ORM
`metallicRoughnessTexture`.

---

## 2. Status of each gap, against the judge

| Gap | Closed? | The judge's own words, after |
|---|---|---|
| **C6** arena / summit | **No** | "It reads as a village square that has been swept, not as an arena ... no lip, no step, no excavation, no rim, no barrier, no seating, no scuffing, no cracks, no hazards" |
| **C7** aviary | **No** | "It reads as an unfinished frame ... sampling through it at two points returns sky colour, so you are looking straight through to the sky, not at glazing" |
| **C8** cottages | **No** | "Generic alpine/European village houses that could be anywhere ... no bracing, no guy ropes, no stones weighting the roofs, no shutters" |
| **X3** bird in the aviary | **Yes, in the object sense** | 14 static birds are placed and were verified in-scene. The judge sees them but reads them as "a few unsupported salmon-pink blobs" — present, not yet reading as birds |
| **stand-11 near-black blobs** | **Yes, measured** | 0.059 → 0.271 Rec.709 median on the same rectangle, frame median unmoved at 0.387→0.388 (`MEASUREMENTS.md` §7) |

On C8 the judge lists as *absent* several things this round demonstrably added —
bracing, guy ropes, shutters — and an in-scene probe counts 66 modules and 24
ridge lashings across the eight buildings. Both can be true: they are placed, and
they are too small and too low-contrast to read at the stand distance. Treat
"the judge cannot see them" as the finding, not "they are missing".

---

## 3. What measurably changed

* **Two rock defects, both real, both fixed and measured.**
  `apply_stone_palette` set the albedo COLOUR and left the source
  `albedo_texture` in place, so the result was the product of the two — and the
  nature kit's `Rocks_Diffuse.png` is dark (Rec.709 median 0.324, RGB with no
  alpha channel, so that is genuine surface colour). A 0.557 grey multiplied
  onto it lands near 0.18. The tint now replaces the texture, at a value chosen
  by measurement in both directions (see §6 of `MEASUREMENTS.md`: dropping the
  texture alone overshot to 0.809, brighter than the plaster beside it).
  Separately, `_build_authored_route_details` is a SECOND rock placer that never
  got C9's line at all — its rocks probed at albedo luminance 1.000, the "pale
  jade cubes" half of the same judge defect.
* **Stand 08's "flat yellow-green rectangle for a banner" is gone**, replaced by
  cloth on the existing banner shader. Verified in the frame.
* **The arena banners** moved from a mid brown-red that rode into pink under the
  noon key and the cloth shader's 1.15 fold term, to a true oxblood.
* **The "bare lumber stack and plank shed half over the edge of the plateau"**
  was two separate instances of the same mistake: the stronghold's own approach
  props at |x| = 18.0/20.0/21.3, outside their own retaining edge at 15.0–17.4;
  and the `SummitSupplyPosition` route-detail pocket, which the camera probe
  identified as the object actually filling that part of the frame. Both moved
  inside and given footings.
* **Frame time held**: 16.665–16.669 ms mean, 17.4–18.2 ms p99, **0 failures**.

---

## 4. What I did NOT get to, and why

* **C6/C7/C8 to the judge's satisfaction.** Four render rounds went into this
  and the last verdict still names all three. The remaining work is stated in
  §5 as a concrete list. I ran out of round, not out of diagnosis.
* **A re-judge of the last two fixes.** The membrane opacity (0.62 → 0.82,
  band extended to 0.78 of the rib, one gap in six left open instead of one in
  four) and the removal of the arena market stalls were made in response to
  `JUDGE-after.md` and are committed, but they are **not** in the frames that
  verdict was written against. Nobody has judged them. Say so.
* **The oak canopy, the exposure/value range, aerial perspective, the creature
  roster and cliff darkness.** Not this lane — see `VERDICT-TRIAGE.md`.

---

## 5. For whoever picks this up — the concrete remaining list

Ordered by how much the judge weighted it.

1. **The arena needs GEOMETRY, not tone.** The swept circle is a texture blend
   on a level plane and the judge said so precisely: "no lip, no step, no
   excavation, no rim, no barrier, no seating". A raised kerb ring, a shallow
   step down into the fight floor, and a spectator tier on the perimeter wall
   would each do more than any further tinting. The banding is in
   `cloudreach_summit_presentation.gd::_build_arena_dressing`, the three zone
   discs; the hazard inlays are now flat tori and are seated too deep to read —
   raise them.
2. **The aviary interior is invisible from the one stand it is judged at.**
   Stand 06 looks UP at the dome from outside a 9 m drum wall, so everything on
   the floor is hidden by construction. Only things above 9 m read. The perch
   heights already straddle that line; the cables, cloth, stores and floor do
   not and cannot from this camera. Either judge the aviary from a stand inside
   it, or move the dressing up.
3. **The cottage dressing is placed but does not read.** 66 modules, 24
   lashings, 8 balconies, shutters on every window — all verified in-scene, all
   invisible to the judge. They need to be bigger, darker against the plaster,
   or both. The lean the judge asked for ("standing perfectly upright, no lean")
   is not something this pass attempted and is the strongest single lever left.
4. **The birds read as pink blobs, not birds.** Recoloured off plumberry pink to
   a neutral roost palette and verified reaching all seven surfaces of each
   copy, but at 0.85 m and ~55 m they are shapes. Larger, or fewer and closer.
5. **Not this lane, but it dominates the verdict**: no sunlight (the frames'
   95th percentile reaches 168 where the references reach 215–240), no aerial
   perspective, tree canopies half a cottage tall, and five of six frames with
   no creature in them.

---

## 6. Things this round got wrong first, kept so the next one does not repeat them

1. **Kit modules are authored around a wall CELL, not around themselves.**
   `Balcony_Simple_Straight` is 2.00 × 1.23 sitting at z 0.90–1.10;
   `Prop_Support` braces from z −0.12 out to 1.92 at y 1.21–2.92;
   `WindowShutters_Wide_Flat_Open` already sits at y 1.09–2.52. Placed at a
   point interpolated on the building's bounding box they float; "fixed" by
   seating them on their own AABB they are equally wrong, because that discards
   the authored offset. Read the prefab's own recipe and use a wall cell.
2. **`Roof_Log` is a roof-structure module spanning a whole roof.** As a ridge
   weight it left five timbers hanging in the sky over stand 08.
3. **`Prop_MetalFence_*` at 1:1 kit scale is a ~4 m gate.**
4. **Godot renames colliding siblings to `@ClassName@N`** — the label is
   discarded, not suffixed. This bit twice: once making a working pass look like
   it had done nothing, and once for real, when `_box(root, "WindBanner", …)`
   called twice under one root meant a name search hid only one of the two
   slabs and left the other yellow rectangle standing. Match on something the
   rename cannot touch (material identity) or count with an explicit counter.
5. **Measure the camera, do not assume it.** Stand 09's lens sits at arena-local
   z = −28.8 and `fov` 70 is VERTICAL, so at 1280×800 the horizontal half-angle
   is 48.2° and a prop is only in frame while |x| / (z + 28.8) < ~1.1. Two prop
   groups were authored out of frame before this was worked out.
6. **Trading black for white is not a fix**, and neither is trading a flat plane
   for an artefact: 26 scuff discs and a pair of overlapping co-planar inlay
   discs each produced a field of pale chevrons across the deck that was worse
   than the emptiness they were meant to break.
7. **Read a verdict's numbers the way you would ask it to read yours.**
   `JUDGE-after.md` answer D rests on single pixels; region medians do not
   support two of its claims (`MEASUREMENTS.md` §8). That does not make the
   verdict wrong overall — it means answer D is not evidence the rock work
   failed, and the rock work has its own before/after medians instead.

---

## 7. Evidence

* `JUDGE-before.md`, `JUDGE-after.md` — blind verdicts, both written by a
  sub-agent given only the frames, the sheet and `docs/reference/`.
* `MEASUREMENTS.md` — every Rec.709 median quoted here, including the two
  corrections to the after-verdict.
* `VERDICT-TRIAGE.md` — the before-verdict split by lane ownership.
* Probes committed with the code: `tools/_probe_cloudreach_dark_props.gd`
  (reconstructs a capture view's exact production camera and ranks in-frame
  surfaces by screen area × darkness), `tools/_probe_cloudreach_dressing_counts.gd`
  (proves each half of the round placed geometry), and
  `tools/_probe_cloudreach_aviary_birds.gd` (proves the bird recolour reaches
  all seven surfaces of each copy).
* Frames are under `shots/` and are gitignored, per the brief. Only verdicts and
  measurements are committed.

## 8. Test output, verbatim

Last run, on the tree at this branch head:

```
--------- smoke_cloudreach_foundation
CLOUDREACH FOUNDATION OK regions=6 landmarks=12 bridges=5 player=(0.0, 105.0302, -260.0)
--------- smoke_cloudreach_look
CLOUDREACH LOOK OK bridges_rails=14 posts=798 moorings=9 cover_main=127697 cover_far=24515 cover_alpine=4194 cover_fill=170382 trees=86 stones=79 settlement_overrides=606 guy_ropes=16
--------- smoke_cloudreach_ground_truth
CLOUDREACH GROUND TRUTH: PASS
```

Frame time, `tools/probe_cloudreach_wild_performance.gd`, headless:

```
CLOUDREACH WILD PERFORMANCE COMPLETE: 12 phases, 0 failures
```

Worst three phases of the twelve, `frame_interval_ms`: mean 16.669 / p99 18.180
(ravine_wind roaming_instrumented), mean 16.669 / p99 17.999 (ravine_wind
roaming_uninstrumented), mean 16.667 / p99 17.492 (causeway_watch
roaming_uninstrumented). The handoff baseline is 16.67 ms mean / ~18 ms p99,
0 failures — held.

**Caveat, stated plainly:** those smoke lines and the performance run were taken
before the last two commits' membrane-opacity and arena-stall changes, which are
data and prop-placement only and touch no counter any of those tests assert. I
did not get a further run in before wrap-up. Nobody has judged those two changes.
