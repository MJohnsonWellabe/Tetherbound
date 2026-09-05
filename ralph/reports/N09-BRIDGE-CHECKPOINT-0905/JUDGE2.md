# Verdict — bridge checkpoint, A vs B

Sheet: `_sheet_checkpoint_r2_ab.png`, 1280x836.
Row 1 = `bridge-approach-played / A | B`. Row 2 = `bridge-checkpoint-shoulder / A | B`.
Backgrounds are pixel-identical between columns apart from cloud noise, so every
difference below is the dressing, not the camera or the terrain.

**Measuring conventions.** All pixel coordinates are per-tile (640x400). Ground-plane
metres are derived from the horizon (r1 y≈170, r2 y≈145) and the 1.80 m trainer in row 1
(99 px tall, feet at y=315 → camera height ≈ 2.6 m). Cross-checked against the row-2
guard: the two cameras agree on road width to within 6%.

---

## 1. Does the crossing read as HELD by a faction from the approach?

**A: yes, marginally — and only because of the guard's coat.**
**B: no.**
**Neither has a light.**

What each element actually delivers:

| Element | A | B |
|---|---|---|
| Banners | Two oxblood banners, white circle-cross device, flanking the gate. Read clearly at 30% zoom. Identical in both columns: RGB (141,56,43), hue 8°, sat 0.70. | Identical to A. |
| Guard | Figure in oxblood head-to-toe beside the gate. At 30% she reads as a red mark that rhymes with the banners — the eye ties them together. | Figure in dark neutral grey-brown. At 30% she disappears into the shadowed pier behind her. Reads as a traveller, not a garrison. |
| Barricade | Two textured timber trestles, one clipping each road edge, narrowing the carriageway. | Two untextured blockout trestles standing in the grass off both verges. The road is untouched. |
| Light | None. | None. |

On the light specifically, because the question asks: there **is** a lantern in both
columns — a small hanging lamp on a black iron post immediately right of the gate. It is
not a light. Its glass is a flat, opaque **cyan** swatch (a cold hue, ~185°, against a
faction identity built on 8° oxblood) with no emission, no bloom, no falloff and no spill
onto the pier a few centimetres behind it. At gameplay distance it reads as a small blue
signboard. There is no brazier, no torch, no fire, no lit window, nothing that says
someone keeps this post after dark.

So: in **A**, the crossing reads as *dressed by* a faction. It still does not read as
*held* — see §4 — but a player would correctly guess whose ground this is. In **B**, the
crossing reads as a gate with two banners on it and some carpentry lying in the grass
beside the road; the faction owns the signage and nothing else.

---

## 2. The barricades

### (a) Textured, or blockout?

**A: textured, in both rows.** Longitudinal wood grain, darker knot streaks, saw-cut ends
showing end grain, colour variation along each beam, and dark iron bands wrapped near the
leg ends. This matches the material language of the owner's prop board
(`18_Signpost_Bridge_Modular_Props.png`), where every wooden asset carries visible plank
grain plus darkened metal fittings.

**B: untextured blockout, in both rows.** Flat matte putty-brown prisms with a single
diffuse albedo and nothing but hard-facet Lambert shading. No grain, no end grain, no
wear, no fittings, no colour break at all.

Measured — high-frequency detail (per-pixel luminance minus a 1.5px Gaussian) on a patch
that lies entirely inside one beam face:

| Patch | mean lum | hf std | distinct colours |
|---|---|---|---|
| A left rail (220–300, 322–331) | 118.2 | **16.57** | 687 / 720 px |
| B left beam (150–196, 328–338) | 118.3 | **1.89** | 98 / 460 px |

Same mean luminance, **8.8x** the surface detail in A. For scale, the gate timber in the
same frame measures hf 23.4 and the shared crate 15.3 — A's barricade sits inside the
frame's normal material range; B's is an order of magnitude below everything else in the
picture and is the flattest object in all four tiles apart from the placeholder ramp slab.

### (b) Beside the road, or controlling passage?

**Road width, measured from the unobstructed column and confirmed in both rows: ~2.3 m.**
(r1: 138 px at y=330, 197 px at y=390, 158 px at y=344 → 2.27 / 2.34 / 2.30 m. r2: 106 px
at y=245 → 2.42 m. A single-cart track.)

**A — they control passage, partially.**
- Row 1: the left trestle's rail tip reaches x=338, which is 53 px past the road's left
  edge (x=285) — it eats ~46% of the carriageway. The right trestle's inner foot lands at
  x=424–442, inside the road's right edge (x=458–467 at that depth) — another ~28%.
  Clear projected channel: columns 348–423 = **76 px = 1.25 m**, about 54% of the road.
- Row 2 (the harsher, more axial view): the two inner feet sit at x=380 and x=428 on the
  ground line — **48 px = ~1.0 m**, about 28% of the road at that depth.
- **What fits: a person, comfortably. A handcart, scraping. A wagon or a cart team, no.**
  That is a real checkpoint gap, and it is the single strongest thing column A does.

**B — they stand beside the road and control nothing.**
- Row 1: the left trestle's rail tip terminates at x=276 (verified by pixel scan: the flat
  barricade albedo, B channel 60–77, stops at x=275–276 and the ground takes over at 277).
  The road's left edge at that scanline is x=282. It stops **6 px short of the verge** —
  entirely off the carriageway. The right trestle's leftmost tip is at x≈469; the road's
  right edge at that depth is x≈467. Also off. Clear channel: **~180 px**, versus a road
  of 139 px. The gap is *wider than the road*.
- Row 2: left trestle ends at x≈338, right begins at x≈455 → **117 px** against a 106 px
  road. Again wider than the road.
- **What fits: everything. A person, a cart, a wagon, a team at full trot.** In B the
  entire carriageway is open and the two barricades are decoration sitting in the weeds.

**Applies to both columns:** the verges are wide open. Neither barricade is tied into the
gate piers, into a fence line, or into the terrain — they are two free-standing trestles
with a hole between them. In row 2 the meadow to the right of the right trestle is flat,
unobstructed and runs off the frame. A player who does not want to use A's 1 m slot simply
walks around it on the grass. A narrows the road; it does not close the crossing.

Height, for the record: A's trestles are **~0.97 m** tall (right trestle, 74 px screen
height, foot at y=370), B's **~1.22 m** (85 px, foot at y=353). Both are hip-to-waist on a
1.80 m person. Both are single-rail X-frames — a sawhorse silhouette, not an obstacle.

---

## 3. The guard — does she wear the faction's colour?

**A: yes, unambiguously. B: no, not remotely.**

Same figure, same pose, same mesh, same position in both columns; only the clothing
material differs. All samples are medians over on-body patches, compared against the
banner cloth *in the same tile*.

| Sample | RGB | hue | sat | R/B ratio |
|---|---|---|---|---|
| **Banner cloth** (r1A left) | 139, 54, 41 | 8.0° | 0.705 | **3.39** |
| **Banner cloth** (r1B left) | 141, 55, 42 | 7.9° | 0.702 | **3.36** |
| **Banner cloth** (r2A left) | 142, 57, 43 | 8.5° | 0.697 | **3.30** |
| A guard, chest upper (r1) | 118, 63, 49 | 12.5° | 0.589 | 2.43 |
| A guard, chest lower (r1) | 72, 34, 25 | 12.1° | 0.657 | 2.92 |
| A guard, hips (r1) | 135, 70, 48 | 15.4° | 0.648 | 2.84 |
| A guard, torso (r2) | 83, 41, 31 | 11.5° | 0.627 | 2.68 |
| A guard, thigh (r2) | 79, 40, 29 | 13.3° | 0.631 | 2.71 |
| A guard, shin (r2) | 99, 51, 33 | 16.4° | 0.667 | **3.00** |
| B guard, chest upper (r1) | 110, 102, 91 | 35.7° | 0.169 | 1.20 |
| B guard, chest lower (r1) | 67, 61, 54 | 32.3° | 0.194 | 1.24 |
| B guard, hips (r1) | 74, 70, 63 | 38.2° | 0.149 | 1.17 |
| B guard, torso (r2) | 79, 69, 62 | 26.5° | 0.217 | 1.28 |
| B guard, thigh (r2) | 73, 67, 59 | 34.3° | 0.192 | 1.24 |
| B guard, shin (r2) | 94, 85, 68 | 39.2° | 0.277 | 1.38 |

**Column A.** Hue 11.5–16.4° against the banner's 8.0–8.5° — a 4–8° drift, i.e. the same
red family, a shade warmer. Saturation 0.59–0.67 against 0.70 — within 0.05–0.11.
Red-to-blue 2.4–3.0 against 3.3–3.4. She is darker than the cloth (value 0.28–0.46 vs
0.55) which is exactly what leather/wool reads as against a dyed banner. **A player reads
that figure as wearing the livery.** At 30% zoom she is a red mark next to two red
banners, and the association is instant.

**Column B.** Hue 22–39°, drifting all the way to yellow-brown. Saturation **0.15–0.28** —
roughly a quarter of the banner's, and below the point where a hue reads as a colour at
all. Red-to-blue **1.17–1.38** against the banner's 3.3, i.e. about **a third** of the
banner's red bias; the R, G and B channels are within 15 units of each other, which is the
signature of a neutral, not a red. **A player does not read that figure as wearing
anything. She is a dark-clothed NPC standing near a red banner** — and at 30% zoom she
does not survive at all, because her value (0.29–0.31) matches the shadowed stone pier she
stands in front of.

Neither column's guard is armed, neither faces the road, neither is doing anything, and in
both the face is featureless at gameplay distance — no eyes, brows or mouth resolve at
this size.

---

## 4. What is still wrong in the better column (A), worst first

**A is the better column, on all three counts, without qualification.** Everything below
is what remains wrong with it.

1. **Nothing in the frame casts a shadow.** Not the two 3 m banners, not the gate, not the
   trestles, not the crate, not the trainer, not the guard. Zoomed to 8x, the trainer's
   boots meet pale ground with zero darkening and zero contact occlusion; the same is true
   at every barricade foot. The only shading present is surface-normal shading. This is the
   loudest defect in the picture and it is why the whole checkpoint reads as decals stuck
   on a hillside rather than objects standing on ground. The owner's key art
   (`tetherbound-meadows-keyart.png`) is built on long directional shadows across grass;
   the Palworld bar (`palworld-02-open-field-path.jpg`) puts a hard contact shadow under
   every character, creature and tree.
2. **The crossing is narrowed but not closed, and is trivially walked around.** The 1.0–1.25 m
   slot is good, but both trestles are free-standing islands: neither butts into a gate
   pier, neither is tied to a fence run, and the grass to the left and right of them is
   open, flat and unobstructed to the frame edge (row 2 especially — the meadow right of
   the right trestle is bare for 120+ px and keeps going). A checkpoint that can be
   bypassed on foot in three seconds is not a checkpoint. The reference board's Team Tether
   stronghold panel shows what this needs: a continuous line — palisade or fence — running
   from the gate out into the terrain until it dies on something impassable.
3. **The barricades are sawhorses, not obstacles.** A single hip-height rail (~0.97 m) on
   an X frame. No stakes, no points, no lashings, no rope, no crossed spears, no
   sandbagging. The silhouette a player sees is "carpentry left out", not "you stop here".
   The iron bands are good; the form is wrong.
4. **The slab in front of the gate is untextured blockout, in all four tiles.** A flat
   blue-grey plate (median ~(120,128,133), essentially uniform, only a soft top-to-front
   gradient) sitting where the road meets the gate. It has a visible hard edge against the
   dirt and does not read as stone, plank, threshold or ramp. It is the one piece of
   undisguised placeholder left in column A and it sits at the exact centre of the
   composition.
5. **The guard is doing nothing and is badly placed.** She stands on the grass verge —
   *not* on the road, *not* at the gap, *not* between the player and the gate — in a
   neutral idle with both arms down, carrying nothing, facing across the road rather than
   down it. In row 1 a black iron lamp post passes vertically straight through her
   silhouette and cuts her in half. Her face carries no features at this size. One
   unarmed, unposed, unlooking figure cannot hold a bridge.
6. **Three cloth/light colours compete at one post.** Deep **blue** drapes hang on both
   gate piers, immediately behind and beside the oxblood banners, and the lantern glass is
   **cyan**. The board does license a blue sign panel for wayfinding, but stacking blue
   drape + cyan lamp + oxblood banner inside one 640px frame means the faction colour is no
   longer the thing that identifies the place. Oxblood should be the only saturated
   non-natural colour at this crossing.
7. **The banners are rigid flat quads.** No sag, no fold, no wind, no thickness read, and
   the cloth carries almost no material detail at all (hf std **5.9**, against 16.6 for the
   barricade rail, 23.4 for the gate timber, 15.3 for the crate — the banner is the least
   textured surface in the frame after the ramp slab). The emblem is a crisp,
   perfectly-circular vector decal with no weave, no fade and no weathering; it reads as a
   logo printed on card.
8. **The road is a dirt splat, not a made road.** The grass-to-dirt boundary is a hard
   alpha cut with no gravel, scuff or verge transition. The dirt itself is one blobby noise
   tile with visible repetition. There are no ruts, no gravel bed, no edging stone, and —
   most tellingly for a guarded crossing — no worn track showing where traffic actually
   funnels through the gap the barricades leave.
9. **No sign, no notice, no second figure, no traffic.** A checkpoint that stops people
   would have something posted on it and someone waiting at it. There is no signpost or
   notice board anywhere in frame, despite the owner's board devoting a whole asset panel
   (ASSET 03, with an explicit Notice Board variant) to exactly this.
10. **Composition: the barrier line is foreground clutter.** In row 1 both trestles are
    shoved into the extreme foreground and the left one is cut by the bottom edge, so
    instead of reading as a line drawn across the road they read as loose props scattered
    between the camera and the subject. The row-2 framing, where the two sit close together
    at the gate mouth, is far stronger and is what row 1 should be showing.

---

## 5. SHIP / DO NOT SHIP — checkpoint dressing, column A, first playable

# DO NOT SHIP.

Column A is close, and it is clearly the direction: the barricades are real props in the
project's material language, they genuinely narrow the road to a person-width slot, and the
guard is in livery so the place has an owner. That is most of the way there. But the
checkpoint currently fails on two things a first playable cannot carry: **nothing casts a
shadow**, so the whole set floats; and **an untextured grey blockout plate sits at the dead
centre of the composition**. Either alone would be a visible bug to a player. Together they
undo the dressing work that is already good.

Ship gate: items 1, 2 and 4 must close. Items 3, 5 and 6 should close. The rest is polish.

**What each gap costs:**

| # | Gap | Art that must be made, or scene/material work with what is in frame? |
|---|---|---|
| 1 | No shadows | **Scene/material.** Turn on shadow casting for the directional light and give the props a contact/AO term. No new asset. Highest value per hour on this list by a wide margin. |
| 2 | Bypassable crossing | **Scene, mostly.** Push both existing trestles until they butt into the gate piers, and repeat the trestle mesh outward along both verges until the line dies on the hill (left) and on impassable terrain (right). Genuinely closing it with a *fence* rather than repeated trestles would need a fence/palisade asset, which I cannot see anywhere in these four frames — treat that as art if the repeated-trestle line does not read. |
| 3 | Sawhorse silhouette | **Art.** A taller, spiked-and-lashed barrier variant. Scaling the existing trestle up will fix the height but not the read; a hip-height single rail is the wrong object no matter how tall you make it. |
| 4 | Untextured grey ramp slab | **Material.** Both the stone material on the gate piers and the plank material on the gate itself are already in the frame and either would fix it. No new art. |
| 5 | Guard idle, unarmed, misplaced | **Split.** Moving her onto the road, into the gap, facing the approach, and off the lamp post is scene work, free. A weapon prop and a standing-guard pose are art/animation that must be made. |
| 6 | Blue drape + cyan lamp vs oxblood | **Material.** Retint or remove the pier drapes; retint the lantern glass to a warm amber and give it an emissive so it reads as a lamp. No new art. |
| 7 | Rigid flat banners | **Art** for real fold geometry or cloth sim. A weave texture and a subtle normal to break the flatness is material work and would buy most of it. |
| 8 | Dirt splat road | **Scene/material.** Terrain-blend the dirt-to-grass edge and break the tiling. A rut/gravel decal would be art if none exists. |
| 9 | No sign, no notice, no second figure | **Split.** A second guard is a duplicate of a character already in the frame — scene work. A signpost/notice board is art; nothing of the kind appears in any of these four frames. |
| 10 | Foreground clutter framing | **Scene/camera.** Free. |

Column B is not a candidate for shipping in any form: its barricades are raw blockout
geometry and they stand off the road entirely, so the checkpoint has no barrier and no
garrison read at all.
