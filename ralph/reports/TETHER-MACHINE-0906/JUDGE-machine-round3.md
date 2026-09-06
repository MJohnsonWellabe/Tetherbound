# Blind visual judgement — Legendary Tether Machine, albedo regrade round 3

Frames: `shots/tm_r3/*.png`. Third fresh sub-agent, same brief, told nothing about
rounds 1-2 or about what changed.

## Verdict: NO on both bar questions — and the three rounds have converged

## What is now SETTLED: the style mismatch is answered

Two independent blind judges, rounds 2 and 3, open with the same sentence:

> "Plainly: **not a palette mismatch. The opposite.**"

Round 5's original complaint — "a grey-green mass in an orange room, receiving no
warm light and reading as if it were lit by a different scene" — does not survive
in either. Round 3 measures machine median hue **35.5 deg (C-02) / 32.3 deg
(C-03)** against wall **27.7 / 26.7** — the same orange-brown band — and machine
G/R 0.857/0.805 against wall 0.661/0.679.

## What is now SETTLED: the silhouette is a LIGHTING failure before it is a mesh one

This is round 3's most useful finding, and it is proved inside its own frame set.
Same mesh, same albedo, three frames:

| frame | machine medL | wall medL | mean Michelson | note |
|---|---|---|---|---|
| C-02 | 31.6 | 34.0 | 0.234 | sign FLIPS: brighter in 6 of 10 samples, darker in 4 |
| C-03 | 32.6 | **32.6** | 0.303 | medians identical to one decimal |
| T-03 | 15.6 | 17.0 | **0.652** | consistent dark-on-light in 4 of 5 samples |

> "T-03 puts it against a lit wall and immediately gets a 2.5x-better Michelson
> figure — **proving the object *can* silhouette, and that the failure in the
> other two is a lighting/staging failure, not only a mesh failure.**"

C-02 and C-03 point the camera at UNLIT wall; T-03 puts the machine against a
torch-lit one. That is a staging and lighting property of the chamber, owned by the
Hall dressing lane, and no albedo value can substitute for it: rounds 1, 2 and 3
put the machine at rendered medL 64.9 / 32.7 / 32.5 against the same ~28-34 wall
and none of them produced a stable figure-ground in C-02 or C-03.

## What round 3 found that IS this lane's, and is now fixed

> "Saturation of each population's top-5% brightest pixels: **machine 0.400 /
> 0.410 / 0.288; wall 0.700 / 0.632 / 0.642.** ... Mean luma gradient: machine
> 10.19 / 9.46 vs wall 5.44 / 4.53 ... That signature — desaturated blown
> speculars, double the gradient energy — is **wet plastic or oiled obsidian
> sitting against matte masonry**."

The mesh shipped `roughnessFactor` **0.80** with `metallicFactor` 0, against the
Hall's own masonry at **0.92-0.93** (`stronghold.gd::_material`). Raised to 0.93.

## What remains, and is NOT reachable from this lane at any grade

Board features absent from the mesh, measured:

| board feature | board | built |
|---|---|---|
| TETHER ENERGY (teal pixels on the object) | **18.06%** | **0.00 / 0.02 / 0.00%** |
| BRASS / GOLD banding | 8.98%, bright yellow at every silhouette break | none; the warm-bright hits are torchlight on brown, desaturated at 0.288-0.410 |
| CHAIN / MECHANICAL | on all five orthographic views + the detail inset | **zero** |
| RUNIC GLOW | on every pier, ring and the plinth | **zero** |
| DARK STONE vs DARK METAL break | two distinct materials | one surface on the whole object |
| CONTAINMENT RING | reinforced runic torus, depth, brass bolts | two flat zero-thickness white hexagonal outlines |
| TETHER CLAMP | grips the subject | absent |
| stepped octagonal plinth, radial ribs | crisp radial architecture | "an irregular heap of intersecting flat plates" |
| pointed arch of two fluted piers | architecture | "lumpy, asymmetric and organic; there is no arch line" |

> "The built object shares roughly three features with its board — flanking spire
> columns, a hanging mass, a front stair — and none of its six named key materials."

> "It does not look like it came from a different game. It looks like it came from
> the **nature prop family** and was dropped into an architecture set."

## Defects named that belong to OTHER lanes

Recorded so they reach their owners. None is albedo and none is this lane's:

- **Team Tether oxblood has leaked into the architecture.** Oxblood-band pixels
  cover **11.11 / 13.36 / 14.41%** of the three frames; the keyart's own stronghold
  panel confines the same band to **0.63%**, on the hanging banners only. "The
  accent that is supposed to flag Team Tether is now the ambient colour of the
  room." `palette.json`'s `_reserved` note is explicit that this colour is what
  lets a player read threat at distance.
- **The walls' ALBEDO is brown, not grey.** Wall R/B **2.33-2.60** against the
  keyart stronghold's **1.060**, at roughly twice the chroma and a third of the
  value. Round 5 called this "the material identity of the building has drifted";
  it is a wall material, not a machine one.
- **Value collapse.** Frame medians 28.0 / 29.4 / **14.0**; pixels below L=32
  **58.2 / 56.4 / 76.9%**; above L=200 **0.4 / 0.3 / 0.3%**. Palworld: medians
  104.7-133.3, below-32 0.6-11.8%, above-200 14.3-21.8%.
- **Flat unlit cyan conduit ribbons terminating in mid-air** with square cuts and
  no fitting — C-02 at y~178 spanning x 540-720; C-03 from (195,80) to (580,165)
  floating across the upper wall. "These read as debug/navigation lines."
- **The containment rings intersect the bound creature** — the lower ring's near
  edge crosses in front of the chest while the neck passes through the ring plane.
- **No contact shadow, and worse than absent.** In C-02 the floor measures **44.70
  (left) / 47.80 (right)** beside the base against **36.94** away from it: the
  floor is BRIGHTER next to a ten-metre object than away from it.
- **The white wireframe triangle at T-03 top-left** — round 5 reported this same
  artefact; it is still there.
- **Every frame clips the machine.** C-02 and C-03 run it off the top edge, T-03
  clips it on three sides. "Reframe so the hero object completes its silhouette at
  least once."
- **Two props in the room.** Two torch sconces per frame and nothing else.
- **No 1.80 m ruler in any stand**, so the rubric's scale criterion cannot be
  applied to the one object whose whole point is that it is 15 m tall.

## Conclusion for this lane

Three grades bracket and exhaust the albedo lever:

| | albedo medY | rendered medL (C-02) | judge |
|---|---|---|---|
| shipped | 64.8 | 43.9 | grey-green, lit by a different scene |
| round 1 | 80.7 | 64.9 | brighter than its own room |
| round 2 | 45.6 | 32.7 | statistically the same tone as the wall |
| **round 3** | **44.3** | **32.5** | palette matched; silhouette is a lighting failure |

Round 3 ships: it is the only one that holds the board's dark-stone mass (78.9%
below luma 70 against the board's 64.3%) AND restores a highlight end (machine
p90/p95 93.3/134.9 against round 2's 75.4/101.2), with hue held in the wall family
at G/R 0.894. Plus roughness 0.80 -> 0.93.

The bar as written — "the judge no longer calling it a style mismatch or an
unreadable silhouette" — is **half met**. Style mismatch: answered, twice, in the
judges' own words. Unreadable silhouette: NOT answered, and the evidence says it is
not answerable here. It needs either the chamber's own lighting to put a lit
surface behind the machine (the Hall dressing lane, and T-03 shows it works), or
the board's mesh and material set authored (an owner decision, taken 2026-09-06:
keep the installed asset).
