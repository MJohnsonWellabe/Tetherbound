# CLOUDREACH-DRESS-0906 — closing C6, C7, C8 and X3

Lane: Cloudreach dressing. Branch `claude/art-cloudreach-dressing-0906`, based on
`claude/second-biome-art-plan-470zru` (which already carried the main merge,
cliff option A, the realm-wide turf fill and crown relief).

The bar is the blind visual judge (`.claude/skills/visual-judge/SKILL.md`):
done is the judge no longer naming the gap. Stands judged: 02, 06, 08, 09, 11, 12.

## 0. One correction to the brief, on a point of fact

The standing brief lists `Torch_Metal`, `Cage_Small`, `Chain_Coil`,
`Lantern_Wall`, `Banner_1/2`, `CandleStick_Stand`, `Barrel_Holder`, `Rope_2/3`,
`WeaponStand`, `Dummy`, `Cauldron` and the `Stall_*` pieces as already installed
in `assets/props/quaternius_fantasy/`. None of them were. The installed set was
a *different* sixteen — Anvil_Log, Axe_Bronze, Bag, Barrel, Barrel_Apples,
Bed_Twin1, Bench, Bucket_Wooden_1, Cabinet, Crate_Wooden, FarmCrate_Apple,
FarmCrate_Empty, Pickaxe_Bronze, Rope_1, Whetstone, Workbench — which is why the
count matched while the contents did not. Same for the medieval kit: of the
modules the brief named, only `Prop_Support`, `Stairs_Exterior_*` and
`WindowShutters_*` were installed.

The conclusion the brief drew was still right, and is what this round did: the
art is in the repo, under `assets_raw/vendor/`, and installing it is a copy plus
a ledger row. **Nothing was downloaded and Meshy was not used.** All 34 files
needed only their `.gltf` + `.bin`; every material resolves against shared trim
textures that were already installed, so not one texture file was added.

Audited on install for the absent-`metallicFactor` glTF defect that renders a
prop as a black silhouette in daylight: **0 of 34** are exposed to it.

## 1. What changed

### C7 — the aviary (both levers, so the judge picks)

The handoff posed this as an owner decision. The owner asked for both.

* **Membrane.** `cloudreach_aviary.gd::_build_membrane` skins a band of the
  meridian gaps — rim to 0.62 up each rib — on the same sphere the ribs use, so
  the ribs read as the structure of something rather than as the whole object.
  One gap in four is left bare and the crown and oculus stay open, so it is
  still an aviary and not a roof.
* **Dressed lattice.** `_build_interior` answers the verdict item by item:
  log perches (installed Kenney logs) straddling the drum crown, handling
  cables from the oculus ring landing on installed rope and chain coils, the
  installed `Lantern_Wall` with a real OmniLight, hanging wind cloth on the
  existing banner shader, keeper's stores, and a swept floor with straw banked
  toward the wall. Nothing added collides.

### X3 — the bird

The handoff calls a static bird "not found licence-clean". It was already in
the repo: `assets/creatures/plumberry/ollie-the-songbird.glb`. Fourteen static
copies roost on the new perches and the drum crown. Reusing an existing
creature mesh as scenery is not a new creature mesh (D23 §20), and nothing was
generated. Each copy is flattened to one colour from a highland roost palette —
the source is a *plumberry* bird and its own pink plumage rendered as a salmon
blob at 0.85 m against grey stone in this round's first frame.

### C6 — the final arena and the summit approach

* **Floor.** The first attempt put a `worn_ground` disc and scuffs on the deck
  and they all but vanished: worn ground is a dirt tone and the deck is a
  dirt-toned cobble, so the treatment had no value contrast to work with. The
  deck is now *banded* — a pale swept fight circle, the base cobble, a darker
  weathered outer court — with an inlaid band at each radius the fight is
  actually authored around (the relay arc's 14 m and 33 m), and loose rubble.
* **Occupation.** Cages and chains, braziers with real fire, stores, weapon
  stands and dummies, banners and Team Tether's own pylons.
  `_arena_spot_is_free` keeps every one of them off the three lee pockets, the
  relay interaction sites and the fight centre; the southern entry and northern
  recovery lanes stay clear; nothing added collides.
* **Banners.** "Pinkish crimson, not the board's oxblood ... festival bunting
  rather than a threat." `#66362c` is a mid brown-red, and under this realm's
  noon key plus the ACES shoulder a mid red rides into pink, with the cloth
  shader's fold term reaching 1.15 on the lit side. Dropped to `#4a2018` so the
  *lit* value lands where `#66362c` was only ever the unlit value. Cloudreach
  only; the Hall keeps its own colour.
* **The lumber over the edge.** "A bare lumber stack and a plank shed sit half
  over the edge of the plateau." They did. The approach's own
  `ApproachRetainingEdge` runs from |x| = 15.0 to 17.4, and the wagon and
  crates stood at 18.0, 20.0 and 21.3 — every one outside it, with nothing
  underneath. Moved inside onto a masonry footing and made a manned gate post.

### C8 — the cliffside cottages

* **The lattice.** `timber_colour` moves from `#8a7d6a` to `#4b3a2b`.
  `Wall_Plaster_WoodGrid` is a half-timbered wall, not an opening — probed
  against the kit, both its primitives span the full 0.00–3.12 m wall height —
  but at `#8a7d6a` the timber sat about 0.11 luminance from the `#b9b4a8`
  plaster behind it, so the infill stopped reading and the eye filled the grid
  cells with shadow. Shutters were added on every window the prefab authors,
  because the face the judge actually called a lattice is a *wide window*.
* **The pole.** The lone guy rope becomes a real ridge lashing: three lines
  over the roof, staked both sides.
* **The sameness.** Balconies, diagonal braces, brick footings and vines from
  the medieval kit's own previously-unused modules — placed from each prefab's
  **own recipe wall cells**, not from points interpolated on a bounding box.
  See §3: getting that wrong is what floated balconies over roof ridges.
* Applied to both cliff settlements only. The Meadows village is untouched.

## 2. Two real bugs found on the way

**The stand-11 "near-black matte blobs."** Not the absent-`metallicFactor`
defect (already ruled out on the base branch) and not a missed retint: C9's
routing fix is real and every rock does reach `apply_stone_palette`. *The
palette itself was the defect.* It set the albedo colour and left the source
`albedo_texture` in place, so the rendered result was the product of the two —
and the nature kit's shared `Rocks_Diffuse.png` is dark (Rec.709 median 0.324;
most common colours the dark olives (45,61,0) and (53,65,31)). A 0.557 grey
multiplied onto that lands near 0.18. The function's own comment promised "a
cool mid-grey"; it could not produce one while it was multiplying. Numbers in
`MEASUREMENTS.md`.

**A second rock placer that never got C9's line.**
`_build_authored_route_details` retints `bush` and `flowers` and nothing else,
so its rocks kept the kit's raw material and probed at albedo luminance
**1.000** — the other half of the judge's defect 6, the "pale translucent green
cubes that read as jade or ice". Fixed with the same line.

**A third, smaller one:** `_dress_settlement_surrounds` filtered the WindBanner
slabs on `MeshInstance3D`, but `_box` returns a `Node3D` wrapper, so the search
matched nothing and stand 08's "flat yellow-green rectangle" stayed up.

## 3. Things this round got wrong first, and what the frames showed

Kept because the next lane will otherwise repeat them.

1. **Kit modules are authored around a wall CELL, not around themselves.**
   `Balcony_Simple_Straight` is 2.00 × 1.23 sitting at z 0.90–1.10;
   `Prop_Support` braces from z −0.12 out to 1.92 at y 1.21–2.92;
   `WindowShutters_Wide_Flat_Open` already sits at y 1.09–2.52. Placed at a
   point interpolated on the building's bounding box they float; "fixed" by
   seating them on their own AABB they are equally wrong, because that discards
   the authored offset they depend on. The right answer is to read the prefab's
   own recipe and place them at a wall cell's position and yaw.
2. **`Roof_Log` is a roof-structure module spanning a whole roof**, not a loose
   weight log. Used as a ridge weight it left five timbers hanging in the sky
   over stand 08.
3. **`Prop_MetalFence_*` at 1:1 kit scale is a ~4 m gate.** Dropped: it was the
   most prominent object in the stand-02 frame and read as an artefact.
4. **Godot renames colliding siblings to `@ClassName@N`,** discarding the label
   entirely — so `find_children("MyProp*")` reports 1 where there are 20. A
   probe written that way will tell you a whole pass silently did nothing when
   it is working perfectly. Count with an explicit counter, not by name.
5. **Measure the camera, do not assume it.** The stand-09 capture camera stands
   at arena-local z = −23 and the SpringArm pulls it 5.8 m further back, so two
   prop groups first authored at z = −29.5 were behind the lens.
6. **Trading black for white is not a fix.** With the dark texture removed,
   `#8e918c` rendered its sunlit rock faces at 0.809 — brighter than the cottage
   plaster beside them at 0.711, against a 0.420 frame median. The final value
   was chosen by measurement.

## 4. Evidence

* Blind judge verdicts: `JUDGE-before.md`, `JUDGE-after.md` (this directory).
* Measurements taken off the PNGs before and after: `MEASUREMENTS.md`.
* Probes committed with the code:
  * `tools/_probe_cloudreach_dark_props.gd` — reconstructs a capture view's
    exact production camera, projects every drawn surface into it and ranks
    them by screen area × darkness, then reports what draws inside a rectangle
    measured off the rendered PNG.
  * `tools/_probe_cloudreach_dressing_counts.gd` — proves each half of the
    round actually placed geometry rather than silently skipping.
* Test output is quoted verbatim in §5.
