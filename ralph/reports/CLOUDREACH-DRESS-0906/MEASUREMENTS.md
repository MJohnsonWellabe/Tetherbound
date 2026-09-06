# CLOUDREACH-DRESS-0906 — measurements taken before any change

Handoff trap 2: "The blind judge reads exposure off the PNG. Measure Rec.709
medians yourself first; a wasted round costs 15 minutes." These are mine,
taken off `shots/dress_before/` (gitignored; the numbers are the evidence).

## 1. The stand-11 "near-black matte blobs" (judge defect 6)

Rec.709 medians over rectangles measured off
`11-aerie-ground-connection.png` (1280x800):

| Region | median lum | mean RGB |
|---|---|---|
| left dark mass (x 140-255, y 355-450) | **0.059** | (16, 28, 26) |
| right dark mass (x 890-1000, y 285-355) | **0.138** | (34, 48, 43) |
| big central cliff mass | 0.156 | (33, 42, 37) |
| lit grass | 0.398 | (77, 112, 37) |
| trainer torso | 0.187 | (72, 66, 45) |
| tree canopy | 0.146 | (48, 73, 40) |
| whole frame | 0.387 | (67, 92, 56) |

The left mass sits at 0.059 against a 0.387 frame median: about 6.5x darker
than the scene it is standing in. "Near-black matte blobs with no highlight"
is an accurate description, not an exaggeration.

## 2. Why they were dark

`tools/_probe_cloudreach_dark_props.gd` reconstructs the exact stand-11
production camera the capture tool poses (ground raycast, +0.2 m player, +1.55 m
pivot, -5 deg pitch, 5.8 m spring arm, 70 deg fov, 1280x800), projects every
drawn surface into it and reports image-space rectangles. The right mass
resolves to
`AuthoredRoutes/WindscarFloorLoopCliffShoulders/RouteRock003_1/Rock_Medium_2`
— a rock that HAD been routed through `apply_stone_palette` (C9's fix is real).

The palette was the defect. It set `albedo_color` and left the source
`albedo_texture` in place, so the rendered result was the product of the two.
Measured over the whole of the nature kit's shared 512x512
`Rocks_Diffuse.png`:

| statistic | value |
|---|---|
| mean Rec.709 | 0.330 |
| median Rec.709 | 0.324 |
| p10 / p90 | 0.229 / 0.441 |
| most common colours | (45,61,0), (53,65,31), (45,60,0), (52,66,23) |

A 0.557 grey multiplied onto a 0.324 median lands near 0.18 — which is what
the frames show. The function's own comment promised "a cool mid-grey"; it
could not produce one while it was multiplying.

## 3. The second, opposite rock defect

The same probe found `AuthoredRouteDetails/AerieApproachRockShelter/Rock00/
Rock_Medium_1` at albedo luminance **1.000** — no palette at all.
`_build_authored_route_details` is a SECOND rock placer and never got C9's
line; it retints `bush` and `flowers` and nothing else. That is the other half
of the judge's defect 6, the "pale translucent green cubes that read as jade
or ice", and it was still open.

## 4. Camera arithmetic that changed a placement

The stand-09 capture camera stands at arena-local z = -23 and the production
SpringArm pulls it 5.8 m further back, so the lens is near z = -28.7. Two prop
groups first authored at z = -29.5 would have been at or behind it. Measured,
then moved to z = -16 at |x| = 31 — a radius that clears the west and east lee
pockets at (+-20, -12) by 11.7 m against a 9.7 m requirement, sits inside the
36 m deck and inside the 39.3 m perimeter wall.

## 5. Frame time (acceptance criterion 4)

`tools/probe_cloudreach_wild_performance.gd`, headless, on this branch with all
of this round's dressing in the scene. The handoff's standing baseline is
"16.67 ms mean / ~18 ms p99, 0 failures"; dressing adds draw calls and had to
hold it.

```
CLOUDREACH WILD PERFORMANCE COMPLETE: 12 phases, 0 failures
```

Per-phase `frame_interval_ms`, worst three phases of the twelve:

| site / phase | mean | p50 | p95 | p99 | max |
|---|---|---|---|---|---|
| ravine_wind / roaming_instrumented | 16.669 | 16.663 | 17.083 | 18.180 | 21.289 |
| ravine_wind / roaming_uninstrumented | 16.669 | 16.662 | 17.052 | 17.999 | 20.644 |
| causeway_watch / roaming_uninstrumented | 16.667 | 16.657 | 16.996 | 17.492 | 20.840 |

Mean across every phase sits between 16.665 and 16.669 ms and p99 between
16.872 and 18.180 ms, with **0 failures** — the baseline holds.

Note: this probe writes to
`ralph/reports/CLOUDREACH-PRODUCTION-INTEGRATION-0905/wild-performance-headless.json`,
which is another lane's evidence file. That write was reverted rather than
committed; the numbers above are this lane's record of the run.

## 6. The rock palette, before / overcorrected / final

Same two rock rectangles in `02-lower-cliffs-galefoot.png` across the three
states, Rec.709 medians:

| rectangle | before (tint x dark texture) | texture dropped, `#8e918c` | final, `#676d66` |
|---|---|---|---|
| shadowed face (35-75, 395-420) | 0.136 | 0.468 | **0.357** |
| sunlit face (985-1050, 422-450) | 0.202 | 0.809 | **0.649** |

Reference values in the final frame: lit grass 0.406, cottage plaster 0.696,
whole-frame median 0.424.

Before, both faces sat far below the frame median — the judge's "near-black
matte blobs". With the texture merely dropped, the sunlit face went to 0.809,
*brighter than the plaster beside it*, which is the same defect with the sign
flipped. The final value brackets the frame median the way stone should: the
shadowed face just under it, the lit face just under the plaster. The
prediction that set `#676d66` (scale the linear albedo by ~0.52 to land a lit
face near 0.60 and a shadowed one near 0.34) came out at 0.649 and 0.357.

## 7. The stand-11 blobs, before and after

Same rectangle, same camera, `11-aerie-ground-connection.png`:

| | before | final |
|---|---|---|
| left mass (140-255, 355-450) | **0.059** — mean RGB (16, 28, 26) | **0.271** — mean RGB (60, 80, 85) |
| whole frame median | 0.387 | 0.388 |

A 4.6x lift on the object with the frame's own median unmoved (0.387 -> 0.388),
which is the shape a targeted material fix should have: the thing that was
wrong changed and the exposure did not. The second mass in the same frame reads
0.271 as well. Both are shadowed faces at this stand — the sunlit reading is
the 0.649 in §6 — and neither is "near-black with no highlight" any more.

## 8. Two claims in `JUDGE-after.md` that region medians do not support

The after-verdict's answer D is measured off SINGLE PIXELS. Handoff trap 2 says
to measure Rec.709 medians before spawning a judge; the same discipline applies
to reading one back. Both of these are on `02-lower-cliffs-galefoot.png`, the
frame the verdict cites.

**"The bushes in 02 measure (0,11,0) — pure black, no highlight, no rim."**

| region | median | mean RGB | darkest single pixel |
|---|---|---|---|
| bush, far left (95-130, 398-422) | 0.129 | (38, 56, 20) | (0, 0, 0) |
| bush, left (218-252, 400-424) | **0.434** | (66, 93, 29) | (0, 0, 0) |
| bush, right (888-925, 398-424) | **0.488** | (118, 145, 89) | (30, 55, 12) |
| lit grass | 0.407 | (81, 116, 39) | (48, 77, 24) |
| whole frame | 0.424 | (83, 109, 69) | (0, 0, 0) |

The two lit bushes sit AT or ABOVE the frame median. The third is inside a cast
shadow. A (0,0,0) pixel exists in almost every region of this frame — including
the grass crop and the frame as a whole — because the scene has hard shadows and
because `Bush_Common` is an alpha-cutout mesh whose texture is transparent-black
between the leaf cards. `Leaves_TwistedTree_C.png` and the derived Cloudreach
leaf texture both read median 0.000 over ALL pixels and 0.353 over OPAQUE ones.
There is no bush defect here, and this round deliberately did not "fix" one.

(The rock diagnosis in §2 is not the same case and does survive the check:
`Rocks_Diffuse.png` is RGB with no alpha channel at all, so its 0.324 median is
genuine surface colour and not a cutout background.)

**"The cliff face measures (20,30,31) while the boulders in front measure
(169,181,171) — a 6x luminance gap between two stones in the same frame."**

| region | median | mean RGB |
|---|---|---|
| cliff face (600-700, 150-260) | **0.331** | (67, 87, 85) |
| boulder in front of it (35-75, 395-420) | **0.356** | (87, 107, 95) |

0.331 against 0.356 — the two stone families are within 0.025 of each other and
both sit just under the 0.424 frame median. The 6x gap is two sampled pixels,
one in shadow and one on a specular face, not two objects.

This does not make the verdict wrong about the frames overall; it means answer D
is not evidence that the rock work failed. The rock work is evidenced in §6 and
§7 by region medians before and after.

## 9. The two post-verdict changes, measured (nobody has judged these)

`JUDGE-after.md` answer B: "sampling through it at two points returns sky colour
(134,155,156), so you are looking straight through to the sky, not at glazing."
The membrane band was widened (rim to 0.78 of the rib instead of 0.62), one gap
in six is left open instead of one in four, and the material alpha went 0.62 →
0.82. Re-rendered `06-summit-final-approach.png`:

| region | median | mean RGB |
|---|---|---|
| dome, mid-left (470-560, 320-370) | 0.625 | (146, 149, 139) |
| dome, upper (600-700, 300-340) | 0.584 | (121, 130, 127) |
| open sky, clear of the dome | 0.456 | (86, 128, 153) |

The dome now reads warm-neutral and about 0.15 brighter than the sky behind it,
rather than returning the sky's own blue. It is a surface. Whether it reads as
a *finished aviary* is a judgement nobody has made on these frames.

The arena's two `Stall_Empty` props were also removed in the same round — a
blind verdict read them as market stalls and their awnings as Team Tether
oxblood leaking onto ordinary furniture, in the one yard in the region where
oxblood is supposed to mean the enemy. They are replaced by weapon stands.
Also unjudged.
