# Nerissa fight + Veilfall interior — visual verdict (r2)

## A. Captain Nerissa boss fight (Heart Chamber)

**Framing: 30/31 (97%) checked frames pass.** Reviewed all 12 tell-start, 10 of 12
tell-ended, and 9 "t-" frames across all four opponents (Cannonback, Mirejaw,
Riverdrake, Riptusk). One clear failure:
- `tell-ended-249.67.png` — camera whips to an extreme close-up wedged behind a
  foreground pillar with a wall of foliage geometry filling the upper-right
  quadrant. Riptusk (the opponent named in the header) is completely off-screen;
  only Ripplet's face/back and a sliver of the trainer are visible. This is the
  kind of frame the acceptance bar exists to catch.
- Near-miss, not a fail: `tell-start-182.22.png` (Riverdrake) has the two
  creatures almost fully overlapping — Riverdrake is posed climbing onto
  Ripplet's back — which hides most of the warning ring. Both silhouettes are
  still identifiable, so it passes, but it's tight enough to flag.

**Tells: 12/12 tell-start frames readable.** Every tell-start frame shows a
ground telegraph (an oval ring, or for Riptusk a rectangular lane) plus a
banner ("! incoming — move") sized and placed clearly over the spot the attack
will land. No misses.

**Heavy tell distinct: YES.** Riptusk's three tell-start frames
(`tell-start-249.05`, `-251.40`, `-253.75`) all show `!! HEAVY — get clear` in
orange, paired with a wide rectangular marked lane (chevron-striped) plus a
ring around Riptusk itself — visibly larger and differently shaped than the
plain oval "! incoming — move" rings used by the other three opponents. This
reads as a distinct, escalated cue.

**Presentation breaks:**
- `tell-ended-249.67.png` — camera/geometry break described above.
- `tell-start-251.40.png` — an oversized vine/plant prop clips diagonally
  across the right third of the frame, and the background shows a bright,
  separate interior room (chairs, a fence, an open sky-lit gap) visible
  through what should be a solid wall behind Riptusk — a geometry/culling leak.
- `t-264.00.png` — a small duplicate portrait of the trainer renders stacked
  directly on top of the "TEAM 5/5" HUD label at top-left, a HUD layering bug.

No exploration-HUD bleed, no void frames, no sunk/floating fighters were found
in the frames reviewed.

**C3: FAIL.** Framing and tells both clear their numeric bars, but a hard
occlusion frame (`tell-ended-249.67`) plus two separate rendering breaks
(`tell-start-251.40`, `t-264.00`) are the kind of "presentation break" the
bar explicitly asks to be called out, and one of them is a genuine framing
miss inside the sampled set.

## B. Veilfall interior (vi3, normal camera)

- `intake_gallery.png` — plain vaulted stone corridor; lanterns and hanging ivy
  repeat at identical spacing on both walls with no variation; nothing reads
  as an "intake" (no grates, pipes, or water machinery). **Weak/no.**
- `pump_hall.png` — same corridor shell as intake_gallery, distinguished only
  by a glowing crystal at the far end and one hanging flag. No pump, pipe,
  wheel, or valve geometry anywhere — the name and the room disagree. **No.**
- `sluice_crossing.png` — a plain iron-fenced footbridge over two flat, still
  pools; the pools show a clean mirrored sky reflection despite being deep
  inside a mountain behind a waterfall, which reads as a reflection-probe/skybox
  leak. No sluice gate or valve mechanism visible. **No.**
- `heart_chamber_entry.png` — same bare corridor; one idle NPC stands off to the
  side with nothing to do or interact with. **Weak.**
- `heart_chamber_crystal.png` — the crystal centerpiece is a simple faceted
  translucent shape in front of a flat, looping waterfall-texture plane; no
  bridges, catwalks, or multiple levels as the board depicts — reads small and
  flat next to the reference's towering chamber. **Weak/no.**
- `heart_chamber_banner.png` — the banner itself is a **flat, solid-blue
  rectangle with no crest, no insignia, no fabric folds** — an unmistakable
  placeholder texture sitting in the exact spot the reference board calls out
  as a detailed heraldic banner with a diamond sigil. **No — clearest blockout
  tell in the whole set.**

**Specific read: NO.** All six stands are the same undressed corridor shell
reused with a label change; none of the three "function" rooms (intake, pump,
sluice) show the machinery their names promise, and the Heart Chamber itself
is missing the verticality, bridges, and heraldry the board treats as
load-bearing. This reads as a placeholder pass, not a finished, inhabited
stronghold hall.

## C. Three biggest defects, ranked

1. **`heart_chamber_banner.png` — the banner prop is an untextured flat-blue
   placeholder**, in the single frame the reference board most explicitly
   details (a heraldic banner with a diamond crest). This is the loudest
   "not finished" signal across both parts.
2. **`tell-ended-249.67.png` — the fight camera produces a hard occlusion**,
   swinging behind a pillar/foliage clump so the named opponent is fully
   off-screen. A boss-fight camera must not be able to do this.
3. **The Veilfall interior is one corridor shell reused six times** (`intake_
   gallery`, `pump_hall`, `sluice_crossing`, plus the three heart-chamber
   stands) with identical lantern/ivy spacing and none of the named rooms'
   defining machinery or architecture — the opposite of the board's promise of
   a towering, multi-level stronghold.

## D. Bar A / Bar B

**Bar A (matches the Meadows key art identity): NO.** Carried by: the four
opponent creatures and Ripplet read as vibrant, readable, cohesively painted
character art consistent with the key art's creature style. Sunk by: the
interior is flat gray-brown stone with none of the key art's saturated
color range or warm/cool lighting contrast, and the one frame meant to carry
identity detail (the banner) is a blank placeholder.

**Bar B (same kind of game as the Palworld reference): NO.** The Palworld
references show dense hit sparks, particle bursts, and dynamic camera/motion
around a boss; Nerissa's fight frames are comparatively static — creatures
mostly hold idle poses facing off, with only a light steam-poof on stagger and
no impact flashes or motion blur. The interior shots are also far emptier and
less textured/dressed than any Palworld reference frame.

**Fix split:**
- (a) Scene/camera/placement, fixable without new art: the `tell-ended-249.67`
  camera clip; the geometry/reflection leaks in `tell-start-251.40` and
  `sluice_crossing.png`; the `t-264.00` HUD portrait glitch; varying the
  lantern/ivy prop spacing and adding clutter (crates, tools, bedding, water
  stains) to the interior corridor using existing asset kits; retuning interior
  lighting for more warmth/contrast.
- (b) Needs new art: a real banner texture bearing the Team Tether/diamond
  crest (currently a flat placeholder); pump/sluice-specific machinery meshes
  if none exist in the library, since no amount of rearranging turns an empty
  corridor into a "pump hall"; additional bridge/catwalk modular pieces if the
  Heart Chamber is meant to gain the reference's verticality; combat impact
  VFX (sparks, dust bursts, motion trails) if the engine's hit-reaction system
  doesn't already have assets to place.
