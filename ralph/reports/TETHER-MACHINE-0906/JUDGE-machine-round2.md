# Blind visual judgement — Legendary Tether Machine, albedo regrade round 2

Frames: `shots/tm_r2/*.png`, same rig, same three stands, same brief as round 1.
Fresh sub-agent, told nothing about round 1 or about what changed.

## Verdict: NO on both bar questions — but the failure INVERTED, and that is the finding

Round 1 aimed the albedo at the walls and rendered the machine *brighter than its
own room*. Round 2 aimed the value at board 15 and rendered it *identical to the
wall*. The judge's words: **"not a style mismatch. The opposite, and it is worse.
The machine is not from another game; it is rendered as the same material as the
wall behind it, at the same value, and it disappears into its own room."**

| frame | machine medL | wall medL | Cohen's d | Bhattacharyya | histogram intersection |
|---|---|---|---|---|---|
| C-02 | 28.3 | 33.2 | **0.025** | 0.967 | 0.807 |
| C-03 | **33.8** | **33.8** | 0.101 | 0.988 | 0.922 |
| T-03 | 13.6 | 16.4 | 0.037 | 0.968 | 0.800 |

> "A *d* of 0.03 means the hero object of the chapter and the background masonry
> are statistically the same tone."

The judge then tried three independent ways to isolate the machine from the room
and all three failed: a hue mask (`R/B < 2.05`) selects **46.7% of C-02**; a
texture-energy mask selects **61.3%**; an Otsu luma threshold inside the machine's
own bounding box returns ONE dark component spanning machine *and* wall. On the
board's own front view the same Otsu procedure recovers **99% of the silhouette in
one component at P^2/4piA = 3.64**. That gap is the silhouette verdict.

Boundary contrast, worst samples: **C-02 dL 2.1 (Weber 0.062)**; **T-03 dL 0.9
(Weber 0.037)** — "the object boundary is literally not present."

## What the two rounds together establish

They bracket the albedo lever, and the bracket is the deliverable:

| | albedo median Y | machine rendered medL (C-02) | wall medL | judge |
|---|---|---|---|---|
| shipped | 64.8 | 43.9 | ~33 | grey-green, different scene (round 5) |
| round 1 | 80.7 | 64.9 | ~33 | brighter than its own room |
| round 2 | 45.6 | 32.7 | ~33 | statistically the same tone as the wall |

There is no single flat albedo value that both sits in board 15's dark-stone band
AND separates from a wall occupying that same band. What is left is not the ramp's
MEAN but its RANGE: round 2's ramp runs p10/p90 31.3/84.6, which is why the judge
measured the object as "flat, undirectional". Widening it puts the mass at the
board's dark end and the lit faces above the wall.

## The ceiling on this lane, in the judge's own numbers

The room has no value range for anything to separate against:

| | median L | % above L=96 | p95 | % below L=8 |
|---|---|---|---|---|
| C-02 | 28.3 | 4.2% | 87 | — |
| C-03 | 29.7 | **2.5%** | 72 | — |
| T-03 | 14.1 | 5.5% | 104 | **32.0%** |
| palworld-01..05 | 105-133 | **54.8-73.8%** | 217-235 | 0.0-2.2% |
| meadows keyart | 66.3 | 38.6% | 195 | — |

That is the Hall lighting lane's frame, not the machine's albedo. So is the
judge's finding that **the unlit wall's own albedo is brown** (`C-02` upper-left,
far from any flame: G/R 0.851, R/B 1.564) where the keyart's stronghold is neutral
grey granite at G/R 1.044, R/B 1.048 — round 5 said the same thing ("the material
identity of the building has drifted") and it is a wall material, not a machine one.

## Board features still missing — unchanged from round 1, and unreachable by grading

No chains, no runes, no brass trim (the gold mask's two largest components in C-02
are **the wall torches**), no glowing core, no clamps, no siphon, no banners. Board
containment detail is **22.7% teal**; C-03 is 0.99% teal and 96% of that is the
floor conduit. The containment ring is "two flat, unshaded, near-white polygons"
at **median L 222.6-222.8, saturation 0.147** — about **3x brighter than the
brightest lit brick in the room**, taking no scene colour, reading as debug
wireframe, and clipping through the captive's antlers.

## Artefacts named — again, NONE of these are this lane's

- **C-02:** a cyan bar suspended across the machine, back-wall column mean jumping
  **14.1 -> 119.1 -> 31.6 -> 14.1 across rows y=179-183**. 3 px tall, floating.
- **C-03:** a second cyan bar floating over the wall, x195-496 y76-151, 1,342 px,
  unattached to anything.
- **T-03:** a stray near-white triangle, 866 px at mean RGB (223.4, 231.5, 230.8),
  bbox x0-60 y30-130. (Round 5 reported this same sliver; it is still there.)
- The white containment rings clip the captive's antlers (C-03) and body (C-02).
- **Emissives emit nothing.** The T-03 floor conduit runs L 103-187; the floor
  **12 px from it** is medL 14.2 while the floor **90 px away** is medL 23.0 — the
  strip's surroundings are DARKER than the far floor. A flat unlit quad with no
  light attached.
- **No contact shadow.** C-03 floor beside the base medL 36.9 vs 40.0 at 150 px —
  8%. C-02 18.3 vs 22.8/24.5 — 20%. "The machine is pasted onto the floor."

## One process defect this lane owns and can fix

> "Scale agreement — cannot be checked. The rubric's ruler, the 1.80 m trainer, is
> not in any of the three frames. That is itself a defect in the survey: the one
> object whose whole point is that it is 15 m tall was photographed with nothing in
> frame to prove it."

The same gap was reported against this chamber in `HALL-STAGING-0906`'s own
`JUDGE-chamber-and-bramblebun.md`. `tools/_capture_stronghold_climax.gd` parks the
player at the camera eye rather than in shot, so no stand in the set can ever carry
the ruler. Worth a stand that does.
