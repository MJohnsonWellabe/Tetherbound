# TETHER-MACHINE-0906 — Legendary Tether Machine restyle (H6)

Branch `claude/art-tether-machine-0906`, off `claude/second-biome-art-plan-470zru`.
No pull request opened.

## Outcome in one line

**The style-mismatch half of H6 is closed. The unreadable-silhouette half is not,
and three measured rounds show it is not closeable from this asset's textures.**

## What the brief got wrong, verified in the repo

`docs/HANDOFF_2026-09-06.md` §4.2 row H6 reads "**Meshy hero object — owner
reference art required**", and its Work column says the emissive cap "plus a warm
rake spot are the only levers". Three of those four claims are wrong:

1. **The board is not missing.** `docs/art/reference/15_Legendary_Tether_Machine.png`
   is in the repo, with its own 0-20 m scale bar, four orthographic views and a KEY
   MATERIALS strip. `ASSET_LEDGER.md` line 67 records the shipped mesh as generated
   from four crops of exactly that board.
2. **There is no emissive to cap.** The GLB carries ONE material:
   `metallicFactor 0`, `roughnessFactor 0.8` (now 0.93), a base-colour texture, and
   **no `emissiveFactor` and no emissive texture**. The chamber's teal key is
   `stronghold.gd::_machine_shell`'s CoreLight omni (`machine.core_light`) plus the
   room's own conduits. The albedo-carried read that ledger line 62 settled on for
   the pylon — after a baked emission mask was built and REMOVED because
   gl_compatibility (D01) ignores the mask and floods the mesh — is already what
   this mesh does.
3. **The warm rake spot is not available to this lane.** `_machine_shell` reads
   only `energy` and `range` from `machine.core_light` and hard-codes the colour to
   `palette.tether_teal`. Adding a second light needs `stronghold.gd`, which the
   Hall dressing lane owns. It is also NOT safely addable inside the GLB:
   `Light3D` extends `VisualInstance3D`, so `stronghold.gd::_visual_bounds` —
   which walks `find_children("*", "VisualInstance3D")` and calls `get_aabb()` —
   would fold the light's range into the bounds that `_fit_to_height` divides
   `machine.height` by, silently rescaling the whole machine. Not done.

## What was done

`tools/art_pipeline/regrade_tether_machine.py` (new). A value-keyed albedo ramp,
plus a roughness match. Geometry, UVs and vertex count are untouched, and no Meshy
call was made.

The ramp is value-keyed because nothing else is available: the atlas is 8,186 verts
across thousands of disconnected Meshy islands with no contiguous trim or ring
region to paint. The mesh's own baked shading is the only region signal it carries.

Three grades, each applied to the pristine asset (the ramp is not idempotent; the
GLB carries `extras.tetherbound_albedo_regrade` to enforce that):

| | albedo medY | machine rendered medL, C-02 | wall medL | blind verdict |
|---|---|---|---|---|
| shipped | 64.8 | 43.9 | ~28-34 | "grey-green mass in an orange room... lit by a different scene" (round 5) |
| round 1 | 80.7 | 64.9 | ~28-34 | "an asset carrying its own ambient dropped into a lit room" |
| round 2 | 45.6 | 32.7 | ~28-34 | "not a style mismatch. **The opposite, and it is worse**" — d 0.025-0.101 |
| **round 3 (ships)** | **44.3** | **32.5** | ~28-34 | palette matched; silhouette is a lighting failure |

Round 3 is the only grade holding the board's dark-stone mass (78.9% below luma 70
against the board's 64.3%) while restoring a highlight end (machine p90/p95
93.3/134.9 against round 2's 75.4/101.2), with hue held in the wall family at
G/R 0.894. Plus `roughnessFactor` 0.80 -> 0.93, matching `stronghold.gd::_material`.

## Before and after, judged blind

**Before** — `ralph/reports/HALL-STAGING-0906/JUDGE-rooms-round5.md`:

> "**The legendary machine is the problem asset.** Median Y 26, mean RGB 50/37/34 —
> a **grey-green** mass in an orange room, receiving no warm light and reading as if
> it were lit by a different scene... **At 30% zoom it is a dark blob you cannot
> name**... The single most story-critical object in the chapter has the least
> readable silhouette in the set."

**After** — rounds 2 and 3, two independent judges, same opening sentence:

> "Plainly: **not a palette mismatch. The opposite.**"

Machine median hue 35.5 deg (C-02) / 32.3 deg (C-03) against wall 27.7 / 26.7 — the
same orange-brown band. Surface churn down ~30% (gradient energy 13.32 -> 9.37
against the wall's 3.98); highlight saturation up 0.368 -> 0.425 toward the wall's
0.590.

**But both rounds are still NO on the silhouette**, and round 3 proved why inside a
single frame set. Same mesh, same albedo, three cameras:

| frame | machine medL | wall medL | mean Michelson |
|---|---|---|---|
| C-02 | 31.6 | 34.0 | 0.234 — sign flips, brighter in 6 of 10 samples |
| C-03 | 32.6 | **32.6** | 0.303 |
| T-03 | 15.6 | 17.0 | **0.652** — consistent dark-on-light, 4 of 5 |

> "T-03 puts it against a lit wall and immediately gets a 2.5x-better Michelson
> figure — **proving the object can silhouette, and that the failure in the other
> two is a lighting/staging failure, not only a mesh failure.**"

C-02 and C-03 aim at UNLIT wall. That is chamber lighting and staging, owned by the
Hall dressing lane, and no albedo value substitutes for it — rounds 1/2/3 put the
machine at medL 64.9 / 32.7 / 32.5 against the same wall and none produced a stable
figure-ground in those two frames.

## A negative result, recorded as evidence

`roughnessFactor` 0.80 -> 0.93 **did not move the surface read**: C-03 machine
top-5% saturation 0.426 -> 0.425, gradient energy 9.36 -> 9.37. Under
gl_compatibility there are no reflection probes and the runtime specular lobe is
negligible; the blown desaturated highlights are baked in the Meshy albedo. The
change is kept because 0.93 is the correct value, not because it fixed anything.

## Step 3 was not taken, and why

The brief's step 3 was to re-author the machine with `build_hall_props.py`'s method.
It was prototyped — 3,974 tris, modular, the containment ring on its own material,
authored to the board's own scale bar and to the same local yaw so `facing_deg`
-101.2 would keep working untouched — and the **owner rejected it on sight**
(2026-09-06): *"I prefer the original 3d asset version compared to this cubes
stacked together version unless there's a lot of improvement left to make there."*
The prototype was deleted and the installed mesh kept. That is why this lane ends
with the silhouette half open rather than re-authored.

## Defects found that belong to OTHER lanes

None of these is albedo and none is this lane's. Measured by the blind judges:

- **The Team Tether oxblood has leaked into the architecture.** Oxblood-band pixels
  cover **11.11 / 13.36 / 14.41%** of the three frames; the keyart's own stronghold
  panel confines the same band to **0.63%**, on hanging banners only. `palette.json`'s
  `_reserved` note exists precisely to prevent this: "a reserved colour is what lets
  a player read threat at distance without a marker."
- **The walls' albedo is brown, not grey.** Wall R/B 2.33-2.60 against the keyart
  stronghold's 1.060, at ~2x the chroma and 1/3 the value. Round 5 named this too.
- **Value collapse.** Frame medians 28.0 / 29.4 / **14.0**; below L=32
  **58.2 / 56.4 / 76.9%**; above L=200 0.3-0.4%. Palworld: medians 104.7-133.3,
  below-32 0.6-11.8%, above-200 14.3-21.8%.
- **Flat unlit cyan conduit ribbons terminating in mid-air**, square-cut, no fitting
  — C-02 y~178 x540-720; C-03 (195,80)-(580,165) floating across the upper wall.
  "These read as debug/navigation lines."
- **The containment rings are zero-thickness white quads at median L 222** — ~3x the
  brightest lit brick in the room, saturation 0.147 — **and they intersect the bound
  creature**, the neck passing through the ring plane.
- **No contact shadow, and worse than absent**: in C-02 the floor measures 44.70 /
  47.80 beside the base against 36.94 away from it. The floor is BRIGHTER next to a
  15 m object.
- **Emissives emit nothing**: the T-03 floor conduit runs L 103-187, yet the floor
  12 px from it is medL 14.2 while the floor 90 px away is medL 23.0.
- **The T-03 white sliver** round 5 already reported is still there.
- **Every stand clips the machine** (C-02/C-03 off the top edge, T-03 on three
  sides), and **no stand puts the 1.80 m trainer in frame**, so the rubric's scale
  criterion cannot be applied to the one object whose point is that it is 15 m tall.
  `tools/_capture_stronghold_climax.gd` parks the player at the camera eye.

## Validation

`smoke_stronghold` green on every push. On the shipping asset:

```
machine 'TetherMachine': 0.0m from the chamber centre, bounding 16.6 x 15.0 x 12.0 m, placeholder=false
bound legendary: 0.00 m off the machine's axis, feet 3.18 m up (dais 3.13, crown 8.89, void 5.76 m), body top 7.57 m
machine facing: authored -101.2 deg, built rotation.y -101.2 deg
doorway-to-legendary sightline: 13.6m, clear
stronghold smoke test passed
```

## What would actually close H6 — start here, do not repeat the analysis

**Do the cheap one first, and re-judge before touching the mesh.**

### 1. Chamber lighting and staging (Hall dressing lane) — cheapest, and measured

Put a LIT surface behind the machine in the C-02 and C-03 stands. This is not a
guess: T-03 already does it and scores **Michelson 0.652** against those frames'
0.234/0.303, with the same mesh and the same albedo. Either add wall torches on the
run the C-02/C-03 cameras face, or move the stands. Also reframe — all three stands
currently clip the machine (C-02/C-03 off the top edge, T-03 on three sides), so it
never completes its own silhouette once in the set, and add a stand with the 1.80 m
trainer in it so the rubric's scale criterion can be applied at all.
**Re-judge after this alone.** It may be enough, and it costs no art.

### 2. Only if that fails: the mesh

The owner's standing decision (2026-09-06) is to KEEP the installed Meshy asset, so
this needs a fresh owner call before anyone starts. If it is ever authorised:

- **Do not re-author the whole object procedurally.** That was tried this lane and
  rejected on sight as a "cubes stacked together version". Primitives assembled to
  the board's proportions lose the surface the owner values.
- **The tractable subset is the four board features that are pure ADDITIONS**, none
  of which requires touching the existing mesh: hanging **chains** from the crown to
  the ring, **brass banding** at the silhouette breaks, a **containment ring with
  real depth** to replace the current zero-thickness white quad, and an **emissive
  tether core**. Those are the four the judges name most often, and each can be a
  separate small GLB placed against the existing mesh rather than a replacement.
- **The teal core is the single biggest miss**: 0.00% teal on the structure against
  the board's 18.06%. On the board it is the brightest thing in the image.
- **Constraints anything new must respect**, all verified this lane:
  - `machine.facing_deg` -101.2 (OP-0905-16) is the owner's own playtest fix. The
    archway's outward normal in the model's glTF frame is `Ry(+101.2 deg)*(1,0,0)`
    = **(-0.194, 0, -0.981)**, i.e. -Z rotated 11.2 deg about +Y.
  - `machine.height` 15.0 and `_fit_to_height` divides by the mesh's own measured
    `bounds.size.y`, so author at 15.0 m to keep scale 1.0.
  - **Never put a Light3D inside the GLB.** `Light3D` extends `VisualInstance3D`, so
    `stronghold.gd::_visual_bounds` folds its range into the bounds `_fit_to_height`
    divides by, silently rescaling the machine.
  - `smoke_stronghold` raycasts doorway->captive and fails if the mesh blocks it, and
    `stronghold_climax.gd::_measure_cage` reads the dais and crown off the highest and
    lowest geometry within `axis_probe_radius` 1.0 m of the axis. New geometry near
    the axis MOVES where the bound creature stands.
  - D24: the board licenses the MACHINE, not its prisoner. D23 §20 forbids a new
    creature mesh at any credit balance. The ring stays empty.

### 3. Do not spend another round on albedo

Three grades bracket and exhaust it (see the table above). The lever is done.
