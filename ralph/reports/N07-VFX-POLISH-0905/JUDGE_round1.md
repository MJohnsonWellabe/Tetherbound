# Blind judge — round 1 (before = sheet **B**, after = sheet **A**; `_sheet_before.png`, `_sheet_after.png`)

Code-blind sub-agent (opus, Agent tool), given only the two sheets labelled A/B in a deliberately
non-chronological order, the twenty frames behind them, `docs/reference/` and the visual-judge
skill; told nothing about what changed or which sheet was newer. `JUDGE_PROMPT.md` is the prompt.
Verbatim verdict follows; the lane's response is at the end.

---

# Visual judge — Sheets A and B, wind-up and seal

I read the rubric, the key-art board, and the Palworld reference before looking at the frames. No source, no context. Everything below is from the pixels.

Two facts up front that affect every comparison, because both sheets are broken as a controlled test:

- **In sheet B, `05-telegraph-clean.png` and `06-telegraph-behind-clean.png` are the same image.** Pixel diff: 198 pixels above threshold, all in a 280×43 strip of canopy at the top of the frame. There is no "behind" camera in B. Whatever repositioning 06 is supposed to do did not happen.
- **`07-telegraph-control` is the only shot that matches across sheets** (A/07 vs B/07: mean per-pixel diff 10.3, grass sway only). A/05 uses a camera that differs from A/07 by mean 77.3; B/05 differs from B/07 by mean 110. So neither sheet lets you compare the wind-up against its own control at the same camera, and A/06 is in a completely different *location* (the village, with houses and barrels) from A/05 and A/07 (the fence line under the cliff). Three frames described as one fight are shot in two places.

---

## 1. Where is the wind-up mark, and what colour is it?

**Sheet A — `05-telegraph-clean.png`: there is no mark.** Not faint, not occluded — absent. I zoomed 6× on the wild creature at (355, 265) and there is bare grass under it. I also ran a hue/saturation mask for the gold family (hue 35–50°, sat > 0.55, val > 0.6) across the whole frame: A/05 returns 5814 pixels, A/07 (the control, nothing happening) returns 5519. The difference is grass-highlight noise. The wind-up in A/05 draws nothing.

**Sheet A — `06-telegraph-behind-clean.png`: found it.** A **flat filled disc on the ground, roughly (600–730, 555–625)**, about 135 px across, directly under the small white wild creature and hard-clipped on its left by the player creature's front paw. Colour, sampled: rgb(205,164,62) / rgb(208,168,64) — **hue 41–43°, sat 0.70, val 0.80. Gold / mustard-amber.** In plain words: the colour of dry mustard, or a brass coin.

**Sheet B — `05` and `06` (same frame): found it, but not on the ground.** A **ring — a stroked ellipse, not a filled disc — at roughly (448–640, 448–540)**, sitting squarely across the player creature's shell plates between the shoulder and the mid-back. Colour at its strongest: rgb(199,77,41), rgb(212,103,54) — **hue 14–20°, sat 0.75–0.79, val 0.78–0.83. Bright coral / vermilion / terracotta**, going salmon where it thins out. It is translucent: the shell plates read through it clearly.

**Preferred for Q1: B.** Not close. A's mark is invisible in one of the two wind-up frames and, where it does exist, is a colour that disappears into sunlit grass. B's mark is present in both wind-up frames and is instantly findable. That B put it in the wrong place is Q2's problem; on the question of *can you find it*, A fails outright.

---

## 2. Which creature does the mark read as belonging to?

**Sheet A: the wild creature, correctly.** In A/06 the disc is centred under the small white creature's body, its far edge visible past that creature's flank, its near edge occluded by the player creature's paw. Position and occlusion both say "this belongs to the small thing standing on it." That read is right. It is also the only thing A gets right here.

**Sheet B: the player's creature, and that is backwards.** Three independent reasons:

- **Position.** The ring's centre (~525, 495) is on the player creature's upper back. The wild creature is at (890–930, 265–300), 370 px away across the frame, with nothing under or near it.
- **Occlusion.** The ring is composited *over* the shell plates — you can see the plate edges and the moss-green tint through the coral stroke. A ground decal that is properly depth-tested would be entirely hidden behind a body this large. This one is not, so it reads as painted onto the creature's hide, like a brand or a targeting reticle stuck to its armour.
- **Colour.** The ring's darker crossings land at hue 28–32°, which is the exact hue of the player creature's own tan/orange fur. Where the ring passes over the brown flank at x≈600–635 it stops looking like an overlay and starts looking like a marking in the pelt.

The ellipse's 2:1 foreshortening is consistent with a ground circle at this camera pitch, so the *intent* is almost certainly a ground danger zone at the target's feet — the HUD in `B/05-telegraph-hud.png` says "**! incoming — move**," so the mark is meant to be "the ground you must vacate." That intent is defensible. The execution is not: the entire visible ring falls inside the player creature's silhouette and never touches a single blade of grass, so the player cannot see the shape of the ground they are being told to leave.

**Preferred for Q2: A.** A's mark is under the right creature and behaves like a decal. B's marks the correct *ground* but renders it as body paint on the wrong actor.

---

## 3. Is this the reserved Team Tether oxblood, and does it clash?

I sampled the board's palette strip in `tetherbound-meadows-keyart.png` (row y=968). The relevant swatches:

| swatch | rgb | hue | sat | val |
|---|---|---|---|---|
| gold | (216,179,65) | 45° | 0.70 | 0.85 |
| brown-red | (72,48,42) | 12° | 0.42 | 0.28 |
| **oxblood** | (66,34,44) | **341°** | 0.48 | **0.26** |

**Neither mark is the oxblood.** Oxblood is a *dark* maroon at hue 341°, value 0.26 — the colour on the Team Tether banners in the stronghold panel. Nothing in either sheet is within reach of it.

**Sheet A's disc is, to three degrees of hue, the board's friendly gold swatch.** hue 43° vs the swatch's 45°, sat 0.70 vs 0.70, val 0.80 vs 0.85. It is the *sunshine* colour of this art direction. That is a real clash: it is the same family as the sunlit grass highlights in the same frame, the barrels and thatch behind it, and — worst — the **gold band around the catch orb in `04-catch-success`**. The game uses that exact gold for "you got the thing." Using it for "you are about to be hit" means the player learns nothing from colour at all. It also sits on green grass at value 0.80, which is barely above the lit grass around it: the mustard disc in A/06 reads as a puddle, a dropped plate, or a patch of mud, not a signal.

**Sheet B's ring is a bright cousin of the danger family but not a member of it.** Hue 14° is two degrees off the board's brown-red swatch (12°) — the right *hue*, but at value 0.78 and saturation 0.79 against the swatch's 0.28 and 0.42. It is the brown-red swatch turned up until it fluoresces. Against green grass it is unambiguous and it is the only thing that hue in the frame. Against the creature it is standing on, it is not: the creature's fur runs 28–35°, and the ring's soft outer falloff lands in exactly that band, which is why the left half of the ring dissolves into the shell's warm bounce and only the right arc reads.

So: **the reserved family is not being violated by either mark**, but B is close enough to it to work as danger, and A has taken the reward colour and used it for a threat.

**Preferred for Q3: B**, with the caveat that hue 14° at value 0.78 is not a colour on the board and should be brought down toward the brown-red/oxblood end rather than left as a stock vermilion.

---

## 4. Warning, reward, buff, or nothing?

**Sheet A/05: nothing.** There is no mark.

**Sheet A/06: reward, or debris.** A flat gold disc with no stroke, no gradient, no inner ring, no pulse and a hard edge, sitting under a creature's feet, reads as a **pickup or a buff circle** — the vocabulary of an aura you want to stand in. Nothing about it says "a blow is coming." It has no directional information (no arc, no cone, no facing), no urgency (nothing about a solid fill implies "shrinking timer"), and the grass draws over parts of it and under others, so it does not even read as firmly on the ground. My honest first read of that crop was "the wild creature is standing on a dropped coin."

**Sheet B/05–06: warning, but a warning about the wrong thing.** Coral, ring-not-fill, thin stroke — that is danger-zone vocabulary and it does land as "something bad is about to happen." But because it is painted on the player creature's back rather than on the grass, the specific message that arrives is "*this creature* is marked / targeted / afflicted," not "*this patch of ground* is about to be hit, move off it." Given the HUD literally says "move," the mark is failing at the one job the HUD is asking it to support. There is also no second element — no impact cone, no direction from the attacker, no tick or scale animation legible in a still — so it is a static sticker rather than a countdown.

**Preferred for Q4: B.** A signals nothing or the opposite of what is happening. B signals danger and misattributes it. Misattributed danger is recoverable by moving the decal; a reward-coloured filled disc is a rewrite.

---

## 5. What is drawn around the orb at 04a and 04?

**Sheet A — `04a-catch-seal-clean.png`.** The orb is at roughly (545–725, 425–600) and is **almost entirely obscured**. Over it sit about ten large, very soft, **muddy tan-brown out-of-focus blobs** (bounding roughly x 460–800, y 325–640, ~12% of the frame) plus a translucent brown dome with a visible **X-shaped polygon seam** running through it. Only a crescent of the orb's white rim shows, at the bottom. There is no white, no gold, no bloom — the whole thing is khaki. It reads as **dust or mud kicked up**, or, at 30% zoom on the contact sheet, as a smeared JPEG artifact.

**Sheet A — `04-catch-success-clean.png`.** The effect has essentially **evaporated**. What is left is a faint yellow-olive ground wash and two blurry beige streaks — one at ~(830–1000, 290–330), one at ~(1000–1140, 520–560) — that read as lens smudges, not as light. The orb is clean and prominent: white dome, gold band, (550–730, 415–600), about 3% of the frame.

**Sheet B — `04a-catch-seal-clean.png`.** A **large pale-cream translucent disc**, roughly (455–835, 315–720) — about 380×405 px, on the order of **14% of the frame** — centred on the orb, with **hard-edged white triangular spikes** radiating outward, several of them running past the disc's rim to the bottom of the frame. Inside it, a **solid opaque white cap** sits over the top half of the orb; the orb's dome is blown to flat, detail-free white and only the gold band and the bottom rim survive. A warm gold halo sits off the disc's upper right at ~(700–900, 300–420).

**Sheet B — `04-catch-success-clean.png`.** The same disc, **expanded to roughly (280–1010, 95–720)** — I traced its rim as a hard luminance step at x≈950–1015 in the lower right. That is a circle on the order of 730 px across, roughly **40–50% of the frame**, with straight-edged polygonal wedges radiating through it. The orb underneath has resolved back to a legible white dome with a gold band.

**Preferred for Q5: A for 04, B for 04a.** They fail in opposite directions and neither is right.

---

## 6. Does the seal read as a reward on the orb, or does it wash the frame? Rendering-bug reads?

**A washes nothing and rewards nothing.** A/04a's brown puffs are the wrong colour for a reward at any size — cream and gold say "sealed," khaki says "dirt." By A/04 there is nothing left at all, and the only thing telling the player they succeeded is a small cyan "Caught Bramblebun!" string in `04-catch-success-hud.png`, floating at mid-left over the creature's body rather than anywhere near the orb. A catch in this build is currently a text event.

**B washes the frame.** At `04`, a pale disc covering something like half the image, sitting between the camera and the meadow, desaturating the grass and painting a translucent wedge across the top-right terrain, is too much for a close-up. Palworld's reference (`palworld-01-boss-fight-forest.jpg`) does the opposite: its impact VFX are small, *hot* yellow sparks concentrated at the contact point, occupying maybe 5% of the frame, with the world behind them left at full saturation. B's seal is large and *cool* — a low-alpha overlay, not an emissive burst — which is the least effective combination available: it costs the whole frame and buys very little brightness.

**Things that read as bugs rather than choices, in the seal frames:**

1. **A flat, hard-edged, axis-aligned translucent quad crossing the lower frame — present in A and B, in both 04a and 04.** In A/04 it runs from x≈340 to x≈820 with a **razor-straight horizontal top edge at y≈600–605**, cutting across grass blades, with blades drawing both over and under it. This is a rectangular plane, not a radial glow, and it is unmistakably broken. Fix this before anything else in the seal; it is in every catch frame on both sheets.
2. **B: hard triangular spikes with aliased straight edges and pointed tips.** These are a lens-flare/star sprite's polygons, and at this camera distance you can see the individual triangles. They do not read as light.
3. **B: a fine dotted stipple/mesh pattern across the whole disc**, visible in the 4× crop — alpha dithering, not a texture. It looks like a screen-door failure, not a shader.
4. **B: a visible hard circular seam** where the disc terminates at x≈950–1015, with at least one straight chord in the "curve" — the circle is a low-segment polygon.
5. **B: the opaque white cap over the orb in 04a.** Blowing the subject to featureless white in the frame that is supposed to celebrate it is a bug in intent even if the shader is behaving.
6. **A: the X-shaped seam across the translucent dome in 04a**, and the blobs' complete lack of any shape at all — they have no silhouette, no core, no falloff structure.

**Preferred for Q6: A**, narrowly and for a bad reason. A does not wash the frame only because A has almost no effect to wash it with. On the specific question "does it read as a reward," both answer no.

---

## 7. Is the orb still legible as the subject?

**A/04a: no.** The orb is buried under brown puffs; you can see a sliver of white rim and nothing else. If you did not already know an orb was there, you would not identify one.

**A/04: yes, and it is the best orb in either sheet.** Clean white dome, crisp gold band, good contrast against the olive grass, correctly grounded in the blades. Nothing competes with it. The problem is that nothing *supports* it either — it looks like an orb lying in a field, not an orb that just did something.

**B/04a: no.** The subject is the starburst; the orb is the white hole in the middle of it, its top surface blown out and its form gone.

**B/04: partially.** The orb has resolved and its band reads, but it is a 3%-of-frame object sitting inside a 45%-of-frame disc. The eye goes to the disc. The subject is losing to its own effect.

**Preferred for Q7: A** (on the strength of A/04 alone).

---

## The rest of the rubric

**1. Silhouette and readability at small size.** Viewed as the contact sheet, the **wild creature — the thing you are fighting and catching — has no silhouette at all.** In A/05 at (355,265) and B/05 at (905,280) it is a white popcorn blob at the same value as the scattered white wildflowers three metres either side of it. Ears, head and body do not separate. At 30% you cannot tell the antagonist from ground clutter. Against `palworld-01`, whose Mammorest reads as a distinct shape at thumbnail size purely from its green-over-tan mass, this is the single worst readability failure in either sheet. Both sheets, all frames.

The player creature reads well — the pale plate mass over warm tan gives it a strong two-value silhouette against the grass. Trees read as trees. Rocks mostly read as rocks except where noted below.

**2. Colour and value structure.** The frames do read as one place: consistent olive-to-green meadow, warm sun, the board's gold-tan-green triad. Value range is thin in the mid-ground — grass sits in a narrow 0.35–0.60 band across most of the meadow, with almost nothing genuinely dark except the tree trunks. `palworld-03` and the key art both put real darks into the ground (shadow pooling under foliage, wet-dark earth) that these frames do not have. Oxblood is *not* leaked onto friendly elements anywhere I looked — that reservation is holding.

**3. Intentionality.** The meadow reads procedural. Grass tufts and white flowers are at near-uniform scale and near-uniform spacing across the whole ground plane in every frame; the boulders in A/07 upper area (x 750–1050, y 105–160) are all within about 20% of the same size and evenly spread. The village in A/06 is the one part that reads authored — clustered buildings, varied prop scale, barrels and baskets against a wall. The key art's meadow panels cluster their wildflowers into drifts and leave open clearings; these scatter uniformly.

**4. Lighting.** Time of day reads (late-morning sun, warm, from the upper left). Terrain has some form from the baked ground shading, but props are flat-lit — the boulder in A/07 has almost no directional shading. The player creature is grounded by a decent contact shadow. Distant fences and trees float slightly.

**5. Horizon and depth.** Depth reads adequately via scale and haze. **But there is a large flat translucent teal slab crossing the meadow in `07` (both sheets) and `B/05`** — a hard-edged semi-transparent plane running diagonally from the left edge across the hill. It passes **through** the boulder at (850–960, 275–360), tinting its upper half cyan with a straight horizontal boundary while the lower half is untinted, and it renders the fence rails at (830–1280, 300–440) semi-transparent so grass shows through the wood. That is geometry intersecting geometry, and it is the loudest artefact in either sheet. In the `A07_ribbon` crop it reads as a ghost river painted over the grass.

**7. Artefacts** (beyond the seal list above): the alpha-dither stipple visible on distant fence rails; grass rendered as untapered flat sticks that read as dark green pins at distance; the flat quad in the catch frames.

**8. Scale agreement.** Using the trainer as the ruler in B/05 (feet at y≈540, height 115 px) against the player creature at near-equal depth: the creature's body is about **230 px wide across the shell where the trainer's shoulders are 28 px** — roughly eight times a human's shoulder width, so on the order of 3.5 m across. The directive that creatures stand taller than 1.80 m is being honoured emphatically. The problem is the *other* side: in `A/06` the wild creature is about the size of one of the player creature's front feet. Whether Bramblebun should be small is a design call I will not make, but a fight between a 3.5 m armoured quadruped and something the size of its paw does not look like an event, and the rubric's "is the one you fight alongside bigger than the one you practise on" is answered by roughly 10:1 in linear terms. Environment scale is otherwise fine: the boulder in A/07 is chest-height on the trainer, the fence is waist-height, the village doors in A/06 are plausible.

---

## The three things that most separate these frames from the references

1. **The antagonist has no silhouette.** `palworld-01`'s boss reads at thumbnail size from mass and two-value contrast alone. Bramblebun in `A/05` and `B/05` is a white blob indistinguishable from the wildflowers beside it. This is not fixable by scene work — it needs the creature's value structure and shape language addressed in the asset.
2. **Nothing in these frames says a fight is happening.** `palworld-01` has hot yellow contact sparks, a hit-flash on the target, and a bold nameplate — the frame is unmistakably combat. `A/05` has *no* mark at all, and `B/05`'s mark is a thin coral ring on a creature's back. Fixable in-scene: this is decal placement, depth testing, and effect design.
3. **A flat translucent plane cuts through the world.** The teal slab in `A/07`/`B/07` passing through the boulder and the fence, and the hard mustard quad in every catch frame, are things no shipping game shows. Fixable, and cheap.

## The two bar questions

**A. Do these frames read as belonging to the world in `tetherbound-meadows-keyart.png`?** **Yes.** The palette matches the board's own strip closely — gold at 43–45°, the olive-greens, the tans, the violet flower clusters. The village in `A/06` is recognisably the board's "Starting Settlement" panel. What carried it is colour discipline and the settlement architecture. What it lacks is the board's density and value depth — the key art's meadows have drifts, clearings and real shadow; these have uniform scatter and a thin mid-tone.

**B. Shown beside `palworld-0*.jpg`, would someone say these are trying to be the same kind of game?** **Yes for the world, no for the moment.** The meadow, the trainer, and the plated creature would sit beside `palworld-02` and `palworld-03` without anyone asking what genre they were. But `palworld-01` is a fight, and `A/05` and `B/05` are not — one has no combat VFX at all, and the other's telegraph would be missed by any player not told to look for it. The catch frames are worse: `A/04` shows a ball lying in grass with the success announced only in cyan text, and `B/04` shows a half-frame grey wash. Nobody looking at `A/04a` would say it belongs to the same category of finish as `palworld-01`.

The split: **the telegraph, the seal, the teal slab, the flat quads, the spike polygons and the scatter uniformity are all fixable by changing the scene and the effects.** The wild creature's absent silhouette is not — that needs the asset itself changed, and it is the item that will still be failing after every other fix lands.

---

## Verdicts

### The wind-up

**B's mark is the better read**, decisively. A's is invisible in one of its two wind-up frames and, where it exists, is drawn in the same gold the game uses for the catch orb's band — a reward colour, flat-filled, at a value barely above the sunlit grass, reading as a dropped coin. B's is present in both frames, is the only object that hue in the shot, and is unmistakably a warning. That is worth more than being in the right place, because a signal you can't find has no place.

**The one thing I would still change: depth-test it and put it on the grass.** Every visible pixel of B's ring falls inside the player creature's silhouette, so the player is told "move" and shown nothing about where to move to. Draw it as a ground decal that the creature's body occludes, sized so a readable arc of it extends past the creature onto open grass. If the ring must remain visible through the body, use a distinct through-wall treatment (dashed, dimmer, no fill) so the on-ground arc and the see-through arc are not the same mark.

### The seal

**Neither is right, but A's `04-catch-success` is the better frame and B's is the better *idea*.** A/04 has the only orb in either sheet that reads as a proud, legible subject — clean white dome, crisp gold band, well grounded. What A has no version of is a reward: the effect is either brown mud (04a) or gone (04). B has an actual expanding seal with a clear before/after between 04a and 04, which is the correct structure — but it is executed as a cool, low-alpha, half-frame overlay with hard-edged polygon spikes, a visible circular seam, an alpha-dither stipple, and an opaque cap that blows the orb's top to flat white. **On balance I would build from B's structure onto A's orb.**

**The one thing I would still change: shrink it and heat it.** B's disc at `04` covers something like 45% of the frame at low alpha — that is the wrong trade. Cut its radius to roughly the orb's diameter plus half again (so it never reaches the frame edges at this camera), raise its brightness and warm it toward the gold band so it *emits* rather than *veils*, kill the hard triangular spikes entirely, and never let anything opaque cover the orb's dome. And separately, in both sheets: **delete the flat mustard quad with the straight horizontal edge at y≈600.** It is in `A/04a`, `A/04`, `B/04a` and `B/04`, it cuts across grass blades with a perfectly straight line, and it is the clearest rendering bug in the catch sequence.

---

## Lane response (what round 2 changes, and what is routed)

**Read against the record.** The judge did not know A was the after round. It independently
asked for exactly the structural fix A carries — "depth-test it and put it on the grass … a
ground decal that the creature's body occludes" — and confirmed A's mark sits under the right
creature (Q2). Its "no mark in A/05" is real for the player even though the creature it zoomed on
at (355, 265) is an ambient bramblebun by the stream, not the foe: the foe in A/05 is the pale
creature at the ally's near shoulder (~390, 520), and the ring under it is mostly hidden by the
ally's body and the grass (+663 amber px over control by the lane's own band; the judge's tighter
band found +295). "A/06 is a different location" is the same fight: the camera turned to face
the village. Its oxblood swatch is the board's dark maroon; this project's reservation is the
hue band its own building retint measured (`building_prefabs.json`: ~5–17°, sat 0.7+), and the
brief asked for the ring to leave that band, which it has. That part stands.

**What it got right about this lane's own choices, and what round 2 does about it:**

1. **Amber is the reward gold.** The judge's strongest finding: `#ffbe47` is three degrees of hue
   from the board's gold swatch, the orb's own band and the catch sparkle, so a warning in it
   reads as a buff or "a dropped coin", and at value 0.8 it sits inside the sunlit-grass band.
   Round 2 moves the ring to a hue the meadow does not contain and the reward layer does not
   use: **`#ff40e6`, hue 308°, saturation 0.75** — magenta, the complement of the grass, 44° of
   hue from the nearest painted oxblood (`#7a2430`, 352°), 31° from the palette's near-black
   `tether_oxblood` (339°) and 46° from the psychic lilac.
   This game has no shields, so every wind-up is an attack you must *move* off, and violet /
   magenta is the established vocabulary of the unblockable telegraph in the genre. The HUD's
   amber "!  incoming" line stays the HUD's; the ground mark no longer borrows the reward colour.
2. **The seal is hidden at its peak and gone by the shot.** A/04a's "muddy tan-brown blobs" are
   W09's `catch_burst` motes at birth (26 motes with `halo 0.6` dark halos, all still at the
   origin three ticks in) — `vfx.json`, not this lane's, routed below — and behind them the
   round-1 seal ring at 0.45 s had already faded to 12 % by the 16-tick shot. Round 2 keeps the
   seal small and gold and lets it **outlive the mote cloud: `duration` 0.45 → 0.75 s**, so at
   the 16-tick shot the ring is at 38 % opacity and 0.55 m radius around a clean orb — the
   "support" the judge said A/04's orb lacked — while never reaching the frame edge.

**Routed (not this lane's files), with the judge's own words for the coordinator:**
- `vfx.json` `catch_burst`: the dark-halo motes at birth read as "dust or mud kicked up" and
  bury the orb three ticks into the seal (W09's own capture avoided the moment by shooting at
  16 ticks). Lower `halo` or offset the birth ring.
- `orb.gd`: "a flat, hard-edged, axis-aligned translucent quad … razor-straight horizontal top
  edge at y≈600" under the orb in every catch frame, both rounds — the orb's readable halo
  rendering with no falloff under software GL. "Fix this before anything else in the seal."
- `impact_flash.gd`: "kill the hard triangular spikes entirely" — shared by every attack.
- World/water: the "flat translucent teal slab" through the boulder and fence in `07` is the
  stream plane (W09's judge saw the same in its `03`).
- Creature art: the bramblebun has no silhouette at thumbnail scale ("a white popcorn blob at
  the same value as the wildflowers"); the ally-to-wild size ratio reads ~10:1. Asset and
  design, outside any VFX lane.
- `catching.json` `resolve_camera`: the close-up still parks inside the ally.
