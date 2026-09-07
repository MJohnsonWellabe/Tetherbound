# CURRENT_STATE history — moved 2026-09-07

Moved verbatim from `docs/CURRENT_STATE.md` when that file was slimmed to the live
status. History only; nothing here routes current work. See `docs/CURRENT_STATE.md`.

## Burrow Warrens art round — 2026-09-06 (`claude/art-warrens-round-0906`)

`archive/docs/handoffs/HANDOFF_2026-09-06.md` §4.3 W1, W3 and W5 plus the §5.2 leftovers, closed against
two blind visual-judge rounds. Full report and both verdicts:
`ralph/reports/WARRENS-ART-0906/` (`REPORT.md`, `JUDGE-round1.md`, `JUDGE-round2.md`).

**Closed.** W1 mushrooms — `Mushroom_Oyster`/`Mushroom_RedCap` installed from the already
vendored nature megakit (no download, no Meshy; their texture was already installed) with
per-species pale cave tints; round 2 calls the cluster "the only object in any interior
frame with a designed silhouette". W5 burrow arch — the swept bark tube is now a displaced
earth collar in the bank's own shader and the ten root cylinders are real `DeadTree_*`
meshes; round 2 opens with "`03-mouth` is the best frame in the survey and it is genuinely
good". The §5.2 tube-foot sliver — a z-gap between the apron ramp and the threshold fan,
219 bright pixels → 0.

**Partly closed.** W3 — the material half is done (`site.earth_clad_walls`, one wall
material across all five chambers and the passages; round 1's "two unrelated rock
materials … no material identity" does not recur in round 2). The geometry half is open:
both rounds call the rooms extruded prisms and both put an organic tunnel kit in their
*cannot be fixed by scene work* list.

**Owner-directed, landed.** Interior heights raised (den 4.8 → 7.0, hall 4.2 → 5.6,
hall→den passage 3.4 → 4.4) after "the interior looks a little cramped for that creature";
root tips and light heights re-authored with them. A Cloudreach-style geology layer on
`earth_bank.gdshader` after "the placed rocks … look like plastic prop assets", with the
prop rock scatter cut back.

**Open, with detail in the report.** `07-den-dressing` lost value (median 46.6 → 32.0) when
the den walls went from pale stone to earth — a regression this lane introduced; the den
light pools were tuned against an albedo that no longer exists. The geology layer and its
correction are rendered but **not blind-judged**. `smoke_warrens` was last run in full at
`2905e2ae`; the four commits after it are covered by `smoke_warrens_fixture` and renders
only. No CI run was dispatched from this lane.

## Meadows Hall interior art — HALL-ART-0906 (2026-09-06)

`claude/art-hall-round-0906`, off `claude/second-biome-art-plan-470zru`. Closes
the Hall half of `archive/docs/handoffs/HANDOFF_2026-09-06.md` §4.2 — H1, H2, H3, H4, H5, H7, H8
— plus X1 and both §5.2 Hall leftovers. **H6 was not touched**: the tether
machine and `stronghold.json`'s `machine` block are outside this diff.

Two blind verdicts on the same three stands, in
`ralph/reports/HALL-ART-0906/` with the full round write-up. The after-verdict
**stops naming** four things the before-verdict measured: the empty brick boxes
(H2), the flat untextured doorway in both T-01 and T-02 (H5), the missing torch
fixture (H1 — which it had listed under *needs art that is not in the build*),
and T-02's white wedge. Measured on the judged frames: floor-band medians
20.6/18.6/11.9 → 24.2/21.1/23.3, the floor band's crushed-black share
18.6/31.6/34.6 % → 8.1/15.4/9.8 %, and shadow-tier R/B **13.8/10.2/4.9 →
9.6/4.3/2.2** — under the ~10 bar on every frame. The brightest object in T-01
and T-02 is now a torch, not a machine panel.

Green on the shipped tree, first attempt: `smoke_stronghold` (87 dressing props,
0 dropped inside the arena ring; per-room omnis 6/10/10 against the cap of 16;
exterior budget unchanged at 21 of 22) and `test_stronghold_warden_arena`
(3 tests, 35 assertions, 0 failed).

**Not verified, and it should not be treated as settled:** the final tuning round
— glow-card energy, the siphon cap, the elite's rim height, the arena ambients'
height and the east torch pair's offset — answers the after-verdict's own
findings but **was never rendered**; its capture was killed mid-boot when the
lane was told to land. Every one of those five values moves a measured quantity
in the direction the verdict asked for and none adds a light or changes geometry,
but the next session should re-render T-01..T-03 before relying on any of them.
`ralph/reports/HALL-ART-0906/REPORT.md` names all five in a table.

Still open and belonging elsewhere, all located with the new
`tools/_probe_hall_frame_geometry.gd` rather than guessed at: T-02's "flat unlit
maroon plane" is `StrongholdClimax/TetherReadout/Panel` at 2.9 m from the arena's
entrance stand, T-03's "floating white chevron" is that lane's
`ContainmentVFX/RestraintRing0` at emission ×1.15 seen edge-on, and the T-03 hero
mass is H6. Both judges also noted, correctly, that no creature and no Warden is
in frame — these three stands are shot pre-fight by design, so that is a
capture-set question rather than an art one.

## Legendary Tether Machine restyle — H6, 2026-09-06 (TETHER-MACHINE-0906)

**Half met, and the unmet half is not this asset's texture.** The installed
`tether_machine.glb` was regraded to the Hall's palette by
`tools/art_pipeline/regrade_tether_machine.py` (value-keyed albedo ramp: warm dark
stone → `site.stone` #6a6157 → board 15's own BRASS/GOLD on lit trim, baked
micro-detail flattened; `roughnessFactor` 0.80 → 0.93). Geometry, UVs and vertex
count untouched; no Meshy call and no credits spent.

Round 5's "**grey-green** mass in an orange room ... as if it were lit by a
different scene" is **closed**: two independent blind judges now open with "not a
palette mismatch. The opposite" (machine median hue 35.5° against wall 27.7°), and
surface churn is down ~30% (gradient energy 13.32 → 9.37 against the wall's 3.98).
The "**dark blob you cannot name**" is **not** closed, and round 3 proved why inside
one frame set — same mesh, same albedo, three cameras: T-03 scores Michelson
**0.652** against C-02/C-03's 0.234/0.303 purely because it is silhouetted against a
**torch-lit** wall. That is chamber lighting and staging, not albedo; three grades
at rendered medL 64.9 / 32.7 / 32.5 against the same wall all failed it.

Two corrections to `HANDOFF_2026-09-06.md` §4.2 H6, both verifiable: the reference
board is **not** missing (`docs/art/reference/15_Legendary_Tether_Machine.png`), and
there is **no emissive to cap** — the mesh carries one material, `metallicFactor` 0,
no `emissiveFactor` and no emissive texture. A roughness change was measured and did
**not** move the surface read (top-5% saturation 0.426 → 0.425); under
`gl_compatibility` the specular lobe is negligible and those highlights are baked in
the albedo. The procedural re-author was prototyped and rejected by the owner
("I prefer the original 3d asset version"), so it was deleted and the mesh kept.

`smoke_stronghold` green throughout: `bounding 16.6 x 15.0 x 12.0 m`, `machine
facing: authored -101.2 deg, built rotation.y -101.2 deg`, `doorway-to-legendary
sightline: 13.6m, clear`. Verdicts, measurements and the exact next steps:
`ralph/reports/TETHER-MACHINE-0906/` (`REPORT.md`, `JUDGE-machine-round{1,2,3}.md`).

## Cloudreach Cliffs atmosphere and verticality (CLOUDREACH-ATMOS-0906)

On `claude/art-cloudreach-atmosphere-0906`, off `claude/second-biome-art-plan-470zru`.
Evidence, both blind verdicts in full and the two interim rounds:
`ralph/reports/CLOUDREACH-ATMOS-0906/`.

**C5 (floating islands) is closed on the charge the judge made.** Before: "it has no
underside, no roots, no mist, no anchor — it reads as a mesh that lost its parent and is a
bug to any player who sees it", with "detached rock blobs hanging in the air beneath it".
After, asked the question directly and blind: "authored, not a rendering failure ...
failures do not produce that shape or that supporting detail." Three literal causes were
found and fixed: `_mesa` never capped its bottom ring (an airborne `LandmarkLedge` was an
open tube — it now gets a tapering root); `_build_embedded_rock_shelves` measured outcrop
depth from the crown without bounding it by the mass's own height, putting four of thirteen
outcrops 25–61 m *below* the bottom ring (the falling pebbles); and the mooring lines were
not missing but 0.16 m of rope read at 800 m.

**C4 (thin horizon) moved but is not closed.** Before: "no distant ranges, no lower cloud
deck, no further spires, nothing". After: cloud below eye level "yes in three, no in one",
terrain lower than the player "yes in three, no in one" — but "rendered as flat cutouts, so
the horizon carries *layers* without carrying *depth*". A tier-following cloud sea, distant
lower relief and hazed skyline tiers now exist; making them read needs a soft-edged cloud
material, not more of them.

**C3 (a region named for cliffs never shows one) is not closed at the judged stands.**
Region crowns now terrace down to their rims and route shoulders drop 14–54 m at their
outer edge, both through the shared height model — but stands 01/02/04/11 all sit mid-crest,
and the judge's answer is still "No, and no." Closing it needs a drop within about 60 m of
where the player actually stands, or different stands.

**A real bug found on the way:** `cloudreach_look.gd` re-applied this realm's fog by
multiplying the environment's *current* value every frame, which is only correct while
`world_look.gd` keeps resetting the base — and that function returns on its first line when
its clock is frozen, which every capture tool does before rendering. Fog compounded at 0.55
per frame for a dozen frames before the first shutter, so **Cloudreach had effectively no
distance fog in any judged frame to date.**

Gate held: ground truth **0 holes, 33 mismatches, 888 buried** (from 0/33/914), crown
triangles unchanged at 727,157; `probe_cloudreach_wild_performance` 12 phases, 0 failures,
frame interval mean 16.665–16.668 ms, p99 up to 18.313 ms; `smoke_cloudreach_foundation`,
`_look`, `_ground_truth` and `_arrival_walk` all green. Frame exposure moved into the
reference band (p90 194–223 against palworld's 210–226; p99 228–231 against 225–242) with
saturation coming *down* from 50–61 % to 36–52 %, which answers the before-judge's own
largest finding.

## Cloudreach dressing lane — 2026-09-06 (C6, C7, C8, X3)

Branch `claude/art-cloudreach-dressing-0906` off `claude/second-biome-art-plan-470zru`.
Full write-up and evidence: `ralph/reports/CLOUDREACH-DRESS-0906/`.

**Not closed.** The bar was "the blind judge no longer names the gap". Asked
directly, `JUDGE-after.md` still answers no on all three: the arena "reads as a
village square that has been swept", the aviary "reads as an unfinished frame",
and the cottages are "generic ... could be anywhere". `REPORT.md` §5 is the
concrete remaining list; the short version is that the arena needs geometry
(a kerb, a step, a rim) rather than more tinting, the aviary's interior is
hidden behind its own 9 m drum wall from the one stand it is judged at, and the
cottage dressing is placed but too small to read at that distance.

**Verified closed:** the stand-11 "near-black matte blobs" (Rec.709 region
median 0.059 → 0.271 with the frame median unmoved), and stand 08's "flat
yellow-green rectangle for a banner". Both had a cause worth recording:

- `apply_stone_palette` set the albedo colour but left the source
  `albedo_texture` in place, so the result was the product of the two, and the
  nature kit's `Rocks_Diffuse.png` has a Rec.709 median of 0.324. C9's routing
  fix was real — every rock did reach the function — but the function could not
  produce the "cool mid-grey" its own comment promised while it multiplied.
  Separately, `_build_authored_route_details` is a second rock placer that never
  got C9's line at all and probed at albedo luminance 1.000.
- Godot renames colliding siblings to `@ClassName@N`, discarding the label. A
  `find_children("WindBanner*")` search therefore hid one of the two slabs per
  settlement and reported a healthy count while the other stayed up.

34 already-vendored props and medieval modules were installed (no downloads, no
Meshy) with their `ASSET_LEDGER.md` rows; 0 of 34 carry the absent-
`metallicFactor` black-silhouette defect. `smoke_cloudreach_foundation`,
`smoke_cloudreach_look` and `smoke_cloudreach_ground_truth` pass, and
`probe_cloudreach_wild_performance` holds the 16.67 ms mean / ~18 ms p99
baseline with 0 failures — both taken before the last two commits, which are
data and prop placement only and which nobody has judged.
