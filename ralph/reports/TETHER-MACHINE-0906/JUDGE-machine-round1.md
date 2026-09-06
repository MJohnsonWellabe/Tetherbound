# Blind visual judgement — Legendary Tether Machine, albedo regrade round 1

Frames: `shots/tm_after/{C-02-chamber-door-bound,C-03-chamber-corner-bound,T-03-legendary-side-wall}.png`,
1280x720, software GL (gl_compatibility, D01), captured by
`tools/_capture_stronghold_climax.gd --only=T-03,C-02,C-03`.

Judged per `.claude/skills/visual-judge/SKILL.md` by a sub-agent told nothing about
what changed, against `docs/reference/tetherbound-meadows-keyart.png`,
`docs/reference/palworld-0*.jpg` and the machine's own production board
`docs/art/reference/15_Legendary_Tether_Machine.png`.

## Verdict: NO on both bar questions. Still a style mismatch, still an unreadable silhouette.

The acceptance bar for this lane was "the judge no longer calling it a style
mismatch or an unreadable silhouette". It is not met.

### 1. Style mismatch — still yes, but the axis moved

The judge's measurements on C-02, same frame and same light:

| region | mean RGB | G/R | R/B | mean luma |
|---|---|---|---|---|
| machine (colour mask, 19.3% of frame) | 92.8 / 82.3 / 64.0 | 0.886 | 1.45 | 83.2 |
| left wall, torch-lit | 50.0 / 30.8 / 17.2 | 0.617 | 2.90 | 33.9 |
| right wall, torch-lit | 69.8 / 44.2 / 25.4 | 0.634 | 2.74 | 48.3 |
| floor | 25.6 / 17.5 / 5.2 | 0.687 | 4.90 | 18.4 |

**The regrade moved the hue and broke the value.** The board's own object is
`G/R 1.129, R/B 1.050` and **66.9% of it sits below luma 70** — dark stone and
dark metal, with the teal reading against that darkness. The graded machine
renders at G/R 0.886 and median luma 76-82, i.e. **brighter than the room it
stands in**. Round 5's "grey-green mass in an orange room" is answered; a new
defect — a hero object lighter than its own chamber, and warm where the board is
neutral — is in its place. The target was wrong: the grade aimed at the Hall's
walls alone when the acceptance names the walls **and** the board.

The judge's other two reasons are not colour at all and are worth recording as
the standing limit of any texture pass on this mesh:

- **Two texture-authoring languages side by side.** The wall is hand-painted
  stylised stone with a painted rim on each cobble. The machine is "blurred,
  low-frequency mottled tan with random ochre blotches that land mid-face, on
  edges, and across silhouettes indiscriminately - a rock/cliff noise map, not a
  designed material. Nothing on it has a painted edge, a bevel highlight, a panel
  line, a rivet, a rune or a tile boundary."
- **No light in the frame explains it.** Vertical profile over the machine's full
  height runs 50 -> 87 -> 38: flat and undirectional, against two wall sconces
  that peak at 131.8 and fall to 49.2 over ~80 px. It reads as an asset carrying
  its own ambient dropped into a lit room.

### 2. Silhouette — still no, and it reads from exactly one camera

Perimeter^2/(4*pi*A) on the value mask, against the board's own views:

| | board beauty | board side | C-02 | C-03 | T-03 |
|---|---|---|---|---|---|
| raggedness | **29.3** | **21.4** | **403** | **362** | **210** |
| disconnected fragments >20 px | — | — | 242 | 284 | 86 |

- **C-02 (axial):** "reads as a symmetrical arch or gateway with a dark void at
  its centre... a legible landmark. It is not identifiable as an apparatus."
- **C-03 (45 degrees round):** "an amorphous vertical lump... a melted candle, an
  iceberg, a termite mound." Unreadable.
- **T-03 (side wall):** left 11.2% of frame, "fringed pale confetti", unnameable.

> "The object has exactly one readable pose - dead-on axial, where symmetry does
> the work the shapes cannot. Rotate 45 degrees and it dissolves. A hero prop that
> only reads from one camera is not a landmark, and this is a room the player
> walks around."

Weber contrast at the silhouette boundary is only **+0.52 (C-02)** and **+0.58
(C-03)**. This is the measurable half of the defect and it is geometry: the
board's front, side, top and rear views are each independently readable at 21-29
raggedness, and image-to-3D filled the board's negative space with rock.

### 3. Against its own board — four of six key materials absent

Board's KEY MATERIALS strip: DARK STONE, DARK METAL, BRASS/GOLD, TETHER ENERGY,
RUNIC GLOW, CHAIN/MECHANICAL. Callouts: TETHER CLAMP, TETHER CONDUIT,
CONTAINMENT RING, ENERGY SIPHON.

Present: the overall massing and archetype, a stepped approach, two flanking
verticals, and brass **by the metric only** (saturated warm pixels 1.23-1.35% vs
the board's 1.70%) — "the metric passes and the picture fails: that warmth is
random ochre lichen splotch scattered over a rock texture, not metal trim. There
is not one brass *edge* in any of the three frames."

Missing:

1. **DARK STONE / DARK METAL** — the object's base value and temperature.
2. **TETHER ENERGY** — 13.57% of the board, **0.20-0.55%** of the build. A
   25x-70x deficit on the material the object is named for. 73-89% of all bright
   teal in frame is the floor conduits, not the machine.
3. **CHAIN / MECHANICAL** — zero links found in any frame.
4. **RUNIC GLOW** — zero.
5. **CONTAINMENT RING** — a flat single-sided untextured hexagonal line loop.
6. **TETHER CLAMP** — absent; nothing on the machine touches what it binds.
7. **ENERGY SIPHON** — the hanging crown "reads as a stalactite or a wasp nest".
8. **Banner pylons** — bare faceted rock obelisks; the Warden sigil appears nowhere.
9. **The octagonal plinth** — an irregular rocky mound with one ramp.
10. **The subject** — machine/creature height ratio 4.4 in C-03 against the board's
    3.4, so the containment volume is ~30% too big for its occupant. Per the
    owner's 2026-09-01 directive that is fixed by growing the creature, never by
    shrinking the machine.

> "What has been built is the board's **silhouette gesture executed in cliff rock**."

## Artefacts named — NONE of these are this lane's and none are albedo

Recorded here so they reach the lane that owns them:

- **C-03: both containment rings pass straight through the bound creature's neck
  and forelegs** with a hard planar cut. `stronghold_climax.json::bound.rings`.
- **T-03: the ring clipped by the frame edge reads as a floating white debug gizmo.**
- **C-03: the teal conduit is drawn over the machine's arm and terminates in
  mid-air against the back wall** with no bracket, socket or emitter, casting no
  light on the wall it is pressed against.
- **No contact shadow under a 15 m object.** C-03 floor directly under the base
  measures **41.8** against 32.4/40.0 beside it — the ground under the machine is
  *brighter* than the ground next to it. "Everything is sitting on the floor
  rather than standing on it."
- T-03 crushes **37.7% of the frame below luma 12** (the keyart night panel
  crushes 8.5%) and gives ~87% of its area to bare wall and floor with two
  sconces. That is the Hall dressing lane's frame, not the machine's.

## What this lane can and cannot still do

**Can (albedo only, reversible):** correct the value. Hold the walls' warm-neutral
hue (G/R ~0.90) so round 5's "grey-green" stays answered, but pull the output down
so the machine is no longer the brightest thing in its own chamber and the board's
dark-stone base value is restored. This also *raises* silhouette contrast rather
than lowering it, since a dark mass against torch-lit wall is a stronger boundary
than a pale mass 1.5x its backdrop.

**Cannot, at any grade:** the raggedness (403 vs 29.3), the single readable pose,
chains, clamps, runes, brass edges, a modelled containment ring, a real emissive
core. The UV atlas is 8,186 verts across thousands of disconnected islands with no
contiguous trim or ring region to paint, so there is nothing to paint them onto.
Those need the board's mesh and material set authored, which is a separate
decision, and one the owner has taken: keep the installed asset (2026-09-06).
