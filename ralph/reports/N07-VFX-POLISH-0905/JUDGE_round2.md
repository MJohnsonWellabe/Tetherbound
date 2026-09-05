# Blind judge — round 2 (before = sheet **B**, round 2 = sheet **A**; `_sheet_before.png`, `_sheet_after2.png`)

Code-blind sub-agent (opus, Agent tool), given only the two sheets labelled A/B in a deliberately
non-chronological order, the twenty frames behind them, `docs/reference/` and the visual-judge
skill; told nothing about what changed or which sheet was newer. Same prompt as round 1
(`JUDGE_PROMPT.md`) plus one sentence naming which small creature is the foe. Verbatim verdict
follows; the lane's response is at the end.

---

# Verdict — sheets A and B

Frame coordinates are in 1280×720 screen pixels, origin top-left. Colours are sampled, not eyeballed.

**Structural note before anything else, because it confounds half the comparison:** in sheet B, `06-telegraph-behind-clean.png` is the *same camera and same pose* as `05-telegraph-clean.png` — whole-frame maximum pixel difference is 49 (grass sway only). In sheet A the two are genuinely different cameras (max difference 231; A/06 looks toward the village, A/05 does not). **Sheet B lost a shot.** Its "behind" angle never moved, so B gives you one look at the wind-up where A gives you two. That is a survey defect, not an art defect, but it means B's mark is only ever seen from directly behind the player's creature — the one angle where it cannot be read.

---

## 1. Can you find the wind-up mark in 05 and 06?

**Sheet A — 05:** Yes, barely. A magenta wedge at **(349–375, 507–543)**. That is **379 pixels, 0.041% of the frame** — a sliver poking out from behind the player creature's left shoulder. Peak colour **#b03887 → hue 320°, sat 0.68, val 0.69: magenta**, verging on hot pink. Position: lower-left of centre, on the player creature's near flank.

**Sheet A — 06:** Yes, clearly. A flat annulus on the ground at **(603–699, 562–625)** — **995 px, 0.108% of frame** — wrapped around the feet of the pale Bramblebun that is nose-to-nose with the player's creature, just past the player creature's front-left paw. Same **hue 320°, magenta**.

**Sheet B — 05 and 06 (identical frames):** Yes. A soft-edged translucent ring roughly **(478–605, 443–537)**, centred at about (530, 490). Peak colour **#b9653d → hue 19°, sat 0.67, val 0.73**; the lighter arcs sample **#e2a775, hue 28°**. In plain words: **coral / burnt-orange terracotta**. Hue family: **orange**, edging to amber on the bright side. Position: dead centre of the frame — **on top of the player creature's shell plates**, between its shoulder blades and its hips.

**Preference: A.** Not because A's mark is good, but because A/06 puts it somewhere a mark can mean something. A/05 is a failure of a different kind — 0.04% of the frame is not a telegraph, it is a leak.

---

## 2. Which creature does the mark read as belonging to?

**A/06 — the wild creature. Correct, and correctly built.** Three independent cues agree: (i) **position** — the ring is concentric with the Bramblebun's feet, not the Terrapup's; (ii) **occlusion** — the ring's far arc disappears behind the Bramblebun's body and its near arc disappears behind the player creature's front paw, so it is genuinely on the ground *between* and *under* them, at the right depth; (iii) **grass** — individual grass blades draw in front of it, so it sits on the terrain rather than over it. This is the only frame in either sheet where the attribution is unambiguous and right.

**A/05 — ambiguous, and if anything wrong.** All you can see is a pink wedge touching the player creature's flank. A player reading this frame would guess it belongs to the big creature, because that is the only thing it touches.

**B/05 and B/06 — the player's creature, unambiguously, and this is the worst possible outcome.** I masked hue 10–30°/sat >0.4 across the whole frame: **there is not one pixel of the ring on the grass anywhere.** The entire annulus is contained inside the player creature's silhouette. It draws over the white shell plates, over the green carapace, and over the brown right hind leg, and it stops exactly at the body's outline. It also does **not wrap the body's curvature** — it is a flat ground-plane ellipse punched through solid geometry with depth test off.

The read is: *a coral target reticle has been painted on your own creature's back.* For an effect whose entire job is "the enemy is about to hit you," attributing it to the player's creature is a total inversion of the signal. Compounding it: in B/05 the fighting Bramblebun is not visible in the frame at all, so the mark has no candidate owner other than the Terrapup.

**Preference: A, decisively.**

---

## 3. Is this the reserved Team Tether oxblood, and does it clash?

The board's own palette strip (`tetherbound-meadows-keyart.png`, bottom row) ends with two warm darks: **#48302a — hue 12°, sat 0.42, val 0.28** (russet) and **#42222c — hue 341°, sat 0.48, val 0.26** (oxblood). Both are **dark and low-key**. That is the reserved family.

**A's magenta (hue 320°, sat 0.68, val 0.69):** **No, this is not the reserved family.** It is hue-adjacent to the oxblood but carries **1.4× the saturation and 2.7× the value**. It exists nowhere on the board's palette strip. Its nearest board neighbour is the muted plum **#704e70 (hue 300°, sat 0.30, val 0.44)**, which this game spends on wildflowers. Clash test: nothing else in A/06 is magenta, so it does not literally collide — but that is the problem. It is an **orphan hue with no established meaning**, and at small size it reads as plant/flower/decoration, i.e. the one meaning it already has in this world.

**B's coral (hue 19–28°, sat 0.67, val 0.73):** **Family-wise, yes — this is the warm-red/russet family.** But it fails the reservation test worse than A does, because it collides with three things at once:
- **The player creature's own fur** — sampled at **#e7c580, hue 40°**, and the leg shadows at hue 42°. The ring is 12–20° from the coat it is drawn on, at similar value. That is why it reads as a marking rather than an overlay.
- **The exposed dirt patches** in the same frames (warm ochre).
- **The reward colour.** The catch orb's band samples **#998443, hue 45°, sat 0.56**, and the whole catch flash is a gold wash at **hue 45–46°**. So B's "danger" sits about **20° from the game's "reward"** on the wheel, at comparable saturation. A player who learns "warm orange glow = you just caught something" will not read "warm orange ring = duck."

**Neither sheet uses actual oxblood.** Neither passes. A fails by using a colour the world does not own; B fails by using a colour the world has already spent on the reward.

**Preference: split, and I will say so rather than fake a winner.** B is right about the *family*; A is right about *separation*. The correct answer is neither of these two: take the board's own **#42222c, hue 341°**, and raise its value/chroma for readability while holding the hue. 341° is clear of the gold reward (45°), clear of the tan fur (40°), and clear of the violet flowers (~260–280°) — it is the only warm hue in this world that is not already committed.

---

## 4. Warning, reward, buff, or nothing?

**A/05: nothing.** 379 pixels. It communicates zero.

**A/06: a prop, not a warning.** It reads as a **magenta plastic hoop or a collar** the small creature is standing in. Reasons, all fixable: it is a **flat unlit band with a uniform width and hard aliased edges** — no thickness gradient, no inward-sweeping fill, no brightening toward the strike, no soft ground-contact glow, no second element (an arc, a cone, a rising tick) to say *direction*. Nothing about it is time-varying-looking, and a telegraph's whole grammar is "this is filling up." Plus magenta's learned meaning in this genre is **rarity/loot/friendship**, not threat.

**B/05 and B/06: a buff or a status aura on the player's creature.** Soft-edged, translucent, low contrast against a shell it shares a hue family with. If I had to guess from the frame alone I would say "the Terrapup is charging something," which is precisely backwards.

**Neither reads as "a blow is coming."** The only element in either sheet that actually says so is the HUD's small amber `! incoming — move` line at screen top-centre — and note that in A the HUD warning (amber, ~hue 40°) and the ground mark (magenta, 320°) **do not agree with each other about what colour danger is**. B's mark at least matches its own HUD. That is B's one real win on this question.

**Preference: A/06 for attribution, B for internal consistency with the HUD. Both fail the actual question.**

---

## 5. What is drawn around the orb?

**A / 04a-catch-seal** — five separate elements that never fuse into one object:
1. A **flat, screen-facing gold disc**, ~130 px across, **#ccae4f (hue 46°, val 0.80)**, with a white core and faint radial spokes. Pasted onto —
2. A **dark olive-grey dome shell**, ~190 × 170 px, with a hard dark rim, over —
3. A **white sphere** whose bottom third protrudes below the dome.
4. A soft cream halo, ~300 px.
5. A **hard-edged translucent gold ground quad**, roughly **800 × 400 px ≈ 35% of the frame**.

**A / 04-catch-success:** the gold disc is gone. Orb is a **translucent white sphere with a gold equatorial band, ~200 px**, veiled by the cream halo, plus the same gold quad, plus three blurred cream bokeh blobs at (830–920, 300–340), (1000–1150, 490–570) and (60–200, 660–720).

**B / 04a-catch-seal:**
1. A **near-opaque flat cream disc, ~370 px diameter ≈ 11% of the frame**, centred on the orb.
2. **Eight hard-edged white triangular spikes** radiating from it, dead-straight sides, **no falloff at the tips**, the longest running off the bottom edge of the frame.
3. The orb reduced to a **featureless white puck, ~150 px**, with no band and no sphere shading.
4. The same gold ground quad.

**B / 04-catch-success:** the disc has expanded to **~800 px, covering roughly the right half of the frame (~30% of pixels)**, now clearly a **low-poly decagon** — straight chord edges, visible corners, flat-shaded internal spike triangles. The orb underneath is a **clean opaque white sphere, ~190 px, with a warm tan band #998443**. Same gold quad.

---

## 6. Does the seal read as a reward on the orb, or wash the frame? Bugs?

**A: reads as a rendering bug, not a reward.** At 04a the orb is three objects that do not compose — a flat coin stuck on a dark bowl over a white ball. The dome's **dark rim reads as a hole punched in the orb**, and it is the darkest thing in the frame by a wide margin. At 04 the orb is a **ghost**: a dozen grass blades pass straight through its centre and it reads as a glass lampshade.

**B: washes the frame.** 04a is a **milk-white pancake** with the subject buried in it; 04 is a **faceted polygon** across half the frame.

**Hard edges / spikes / seams / flat discs — everything the question asks about is present, in both:**
- **Untrimmed gold quad, all four catch frames.** Dead-straight boundary with a visible corner at ~**(1000, 610)** where the gold stops and green resumes with zero falloff. I cropped (820,540)–(1120,700) in both A/04a and B/04a: **the artefact is pixel-identical between the two sheets.** Nothing was done to it.
- **A dashed vertical seam** of dark pixels running from ~(940, 610) to the bottom edge, in the same crop, in both sheets. Reads as a stencil/decal stitch.
- **Hard flat spikes**, B/04a: eight untextured triangles, straight-sided, no alpha ramp at the tip.
- **Visible polygon facets**, B/04: crop (760,120)–(1180,420) shows the disc's rim as a series of straight chords with corners, and the interior spikes as flat-shaded triangles with hard boundaries. You can count the sides.
- **Alpha dithering / stipple crosshatch** across both the A/04a gold disc and the B/04a white disc — a visible dot pattern from the Compatibility renderer's transparency, reading as a dirty texture.
- **Grass draws in front of the orb** in all four catch frames — ~15 blades cross the sphere's face in B/04 — with **no contact shading**, so the orb reads as sunk into a grass decal rather than resting on grass.
- **No contact shadow under the orb in any of the four catch frames.** The single most important cue that a caught orb has *landed* is absent.

**Preference: neither passes, but B/04 is the least broken single frame of the four and A/04a is the most broken.** The distinction matters: A's problem is that **the orb itself is wrong**; B's problem is that **the effect on top of it is wrong**. The second is much cheaper to fix.

---

## 7. Is the orb still legible as the subject?

- **A/04a: no.** The flat gold coin reads as the subject. The orb reads as a manhole cover.
- **A/04: barely.** Translucent, grass through the centre, halo eating the top edge. Reads as glassware.
- **B/04a: no.** Completely buried. At 30% it is a white blob with spikes.
- **B/04: yes — the clearest orb read anywhere in either sheet.** Opaque white sphere, warm tan band, correct silhouette, legible at 30%. Undermined only by the disc behind it, the grass across its face and the missing contact shadow.

**Preference: B, clearly.**

---

## Rubric pass over everything else

### Creature and character art (rubric says say this first and plainly)
The **Terrapup holds up.** Chunky bear/tortoise silhouette, white stone plates over tan fur, hand-painted texture with real brush direction. It is stylistically consistent with the world and with the trainer, and it reads at 30%. This is not a placeholder problem.

The **Bramblebun does not hold up.** In A/06 at full size (crop 540–780, 520–660) it is a **shapeless cotton ball with dark specks** — no readable ear, no readable limb, no eye, no line of action. It has less silhouette information than the flowers next to it. Against `palworld-01`'s Mammorest — which is legible as a species from its outline alone — this is the weakest asset in either sheet, and it is the creature the whole catch and telegraph sequence is built around.

The **trainer** is too small to judge as art, but at B/05 (1050–1120, 425–545) the face resolves to a flat low-resolution smear with no feature separation.

**Exposure defect on the hero creature:** in A/04a and B/04a the Terrapup's white plates at (0–320, 0–300) are blown to **val > 0.95 flat white with no gradient** — all form lost across the largest single mass in the frame.

### Artefacts (identical in both sheets — nothing was fixed between them)
- **The stream is a flat quad that tints instead of occludes.** A/07 and B/07, crop (820,240)–(1280,420): a pale-teal plane cuts a **razor-straight diagonal across the boulder at (855–950, 275–350)**, tinting its upper half teal, then carries on over the fence rails to (1280, 420). No shoreline, no depth fade, no normal, no refraction. This is the loudest bug in the wide frames and it is in every one of them.
- **Fence renders as a dashed stipple** along the right side of A/05, A/07 and B/07 — alpha dithering on thin geometry, reads as a broken texture rather than a fence.
- **A/05 lower-left (0–110, 350–400):** the purple flower cluster is a flat dark violet smear with no leaf geometry — a billboard LOD sitting in the near field.
- **Bystander creatures clipped by the top edge** of A/04a and B/04a (y 0–50) render as blown-out white smudges.

### Lighting
Sun low and to the left; the meadow reads mid-morning, which is fine. But the grass canopy is **effectively flat-lit** — the grass cards take almost no directional shading, so the whole hillside in A/07 and B/07 is one green tone from foreground to tree line. **The Bramblebun in A/06 has no ground shadow at all** — it floats. The trainer in A/05, A/07 and B/07 has no visible cast shadow either. The only object placed on the ground by shadow is the Terrapup.

### Value and colour structure
Everything is compressed into a mid-to-light green band. In A/07 the darkest non-shadow ground and the brightest lit grass sit within about one stop. `palworld-02` and the keyart meadow panels both hold **dark tree-line, mid grass, bright sky** simultaneously; these frames hold one. The frames do read as one place — that part works.

### Horizon and depth
Horizon is cropped out of every wide frame; A/06's village at 60–80 px is the only distance cue in either sheet. **No aerial perspective** — the distant trees in A/07 carry the same saturation as the near ones, which collapses the hill into a flat sheet. No LOD or chunk seams found in the terrain itself.

### Intentionality
Reads procedural. In A/07 and B/07 the small white flowers are **near-uniformly spaced across the entire hillside at one prop scale with no clumping**, and the bare-dirt patches are equal-sized ovals. The only authored-looking element in either sheet is the purple bush cluster at (730–880, 360–470) in A/05 and A/07 — and it works, which proves the point.

### Scale agreement — measured against the 1.80 m trainer
Using ground-contact screen-y against the horizon as a depth proxy in A/06: the villager measures ~64 px at contact y=182; the Bramblebun ~45 px at y=240; the Terrapup ~320 px at y=660. That gives the **Bramblebun ≈ 0.9 m** and the **Terrapup ≈ 1.9–2.0 m** — the Terrapup is roughly **2× the trainer and 2× the wild creature** in height, and about 3× in body length. A second estimate from A/05's camera puts the Terrapup nearer 3.5 m. Either way the ordering is right: **the creature you fight alongside is clearly larger than the one you practise on, and both agree with the trainer.** **No scale defect found.** The catch orb reads about the width of the Terrapup's front paw, ~25–30 cm — plausible.

### Interface (`-hud` frames; layout identical in A and B)
- **`Day 1 · 07:00` is drawn underneath the `LEVEL 2 / Bramblebun` panel** at top centre and is unreadable. Straight overlap bug, present in every HUD frame.
- **The enemy nameplate is locked to screen top-centre with no anchor to the creature it names.** In B/05-hud the named Bramblebun is not in the frame at all; in A/06-hud it is ~500 px below and left of its own nameplate. No leader line, no world-space tag.
- **`bond 0/5 · discovered` toast** at (320–480, 215–232) in B/05-hud: grey-green text on grass with no backing plate, illegible, and it collides with the right edge of the TEAM panel.
- **`100 / 100` and `COOLDOWN 100%`** in the bottom-left Terrapup panel are dark grey on dark navy — effectively invisible.
- **The Orbs panel is two misaligned rectangles:** outer plate ~x 875–1235, inner ability grid ~x 945–1245 — the grid overhangs the plate on the right by ~10 px.
- **`Caught Bramblebun!`** is small cyan text placed left of centre over the gold wash. The loudest moment in the game gets the quietest type in the HUD.
- **Safe area is fine** — ~40 px / 3% margins on all sides.

---

## The three things that most separate these frames from the references

1. **A fight does not look like an event.** In A/06 the entire visual evidence of combat is a flat pink hoop on the ground; in B/05 it is a soft orange ring on the wrong creature's back. `palworld-01-boss-fight-forest.jpg` sells the same beat with impact sparks, a muzzle flash, a screen-filling boss and a red boss bar — **impact is drawn, not annotated.** Nothing in either sheet reads as a blow landing or about to land.
2. **No value range and no aerial perspective.** A/07 and B/07 are one mid-green from the near grass to the tree line. Both the keyart's oak-grove panel and `palworld-02-open-field-path.jpg` hold dark canopy shadow, mid grass and a bright sky in the same frame, and desaturate with distance. Without that, the hill is a flat sheet.
3. **Uniform, unauthored ground.** A/07 and B/07 scatter equally-spaced white flowers at one scale and equal-sized dirt ovals across the whole hillside. `palworld-02` gives every region of ground a job — a path, a rock cluster, a tree group, real empty space between them. The one clustered element here (the purple bush in A/05/A/07) is also the only part of the ground that looks designed.

---

## The two bar questions

**A. Do these frames belong to the world in `tetherbound-meadows-keyart.png`? — NO.**

What carries it: the palette family is right (olive/gold/tan greens, violet wildflowers, warm timber village), the A/06 village is straight off the board's "starting settlement" panel, and the creature design is on-brief. What sinks it: the keyart is built on **layered value** — dark canopy, lit clearing, bright sky — and every wide frame here is a single mid-green with the horizon cropped away.

*Fixable by changing the scene:* value separation between canopy/grass/sky, aerial perspective on distant foliage, clustered rather than uniform scatter, shot framing that includes a horizon, a real contact shadow under every creature and under the orb.
*Not fixable by scene work:* the effects vocabulary. The gold quad, the polygon disc, the spike triangles and the flat ring are not tuning problems — they are **missing authored VFX assets** (a proper soft-edged decal with a radial alpha ramp, a textured shockwave, a telegraph material with a fill sweep). No amount of density or lighting work reaches the board without them.

**B. Beside `palworld-0*.jpg`, would someone say these are trying to be the same kind of game? — YES.**

Carried by the subject and by the Terrapup: creature-plus-trainer-plus-orb-plus-team-HUD reads unmistakably as the same genre, and the Terrapup's design and texture work would not embarrass itself next to a Pal. Caveated hard on two things: the **Bramblebun's silhouette** is well below that bar and it is the creature every one of these shots is built around; and the **combat/catch effects** would be identified as unfinished at a glance.

---

## Final calls

### The wind-up
**Sheet A's mark is the better read** — specifically A/06. It is the only frame in either sheet where the mark is on the ground, occluded correctly at both ends, and centred on the creature that is actually winding up. B's mark is drawn through solid geometry onto the player's creature and inverts the signal.

**The one thing I would still change:** **the colour.** Magenta hue 320° at sat 0.68 / val 0.69 exists nowhere on the project's palette board and reads as loot or decoration, not danger — and it contradicts A's own amber `! incoming` HUD line. Move it to the board's oxblood hue (**#42222c, hue 341°**), raised in value for readability. That hue is 55° clear of the reward gold (45°), 60° clear of the Terrapup's fur (40°), and 80° clear of the violet flowers — the only warm hue in this world that is not already spoken for.

*(Second-order, if you get one more change: A/05 proves the mark can be 0.04% of the frame and still be "present." Whatever guarantees legibility — a vertical component, a screen-edge indicator, a size floor — is missing.)*

### The seal
**Sheet B's seal is the better read**, on the strength of B/04 alone: it is the only frame of the four where the orb is unambiguously the subject — an opaque white sphere with a legible tan band and a correct silhouette at 30%. A/04a's orb is three unfused objects with a dark rim that reads as a hole, which is a worse starting point than a good orb behind a bad effect.

**The one thing I would still change:** **kill the flat disc and the spikes.** In B/04a it is a 370 px near-opaque pancake that buries the subject; in B/04 it is an 800 px decagon with countable facets covering half the frame. Replace it with a thin, soft-edged, ground-conforming expanding ring whose alpha ramps to zero at both radii — one that never covers the orb at all. The orb is already good; stop hiding it.

**And the thing neither sheet touched, which I would fix before either of the above:** the **untrimmed gold ground quad** in all four catch frames — a hard-edged translucent rectangle covering ~35% of the frame with a visible corner at (1000, 610) and a dashed vertical seam beneath it. I cropped the identical region in A/04a and B/04a and it is **pixel-for-pixel the same in both sheets.** It is the most obviously-a-bug element in the entire survey and it survived whatever changed between A and B untouched.

---

## Lane response — the ceiling, and what ships

**Read against the record.** Two judges, both blind to which sheet was newer, now agree on
the structural finding: the old ring was painted through the ally's back onto the wrong
creature, and the depth-tested ring is "the only frame in either sheet where the attribution
is unambiguous and right". This judge also measured, independently, that neither the old
red nor the magenta is the board's oxblood — and then asked for the board's oxblood hue
(341°) raised in value, which is the family the brief, `palette.json` and `test_telegraph_glow.gd`
all exclude. That is the ceiling for the colour, and it is recorded rather than crossed:
once the reserved reds, the reward golds (the round-1 judge's objection), the tan coats, the
element tints, the violet flowers and the reserved teal are taken, roughly 285–313° is what
the wheel leaves for a warning nobody else is using. The ring ships magenta.

Its HUD-consistency point is fair and routed: the amber "!  incoming" line is `combat_hud.gd`
(`scripts/ui/`); if the ring stays magenta the line could take the same hue so mark and text
agree. Its "0.04 % of the frame" on A/05 is the fight geometry — the foe was at the ally's far
shoulder — and is the same limitation recorded in round 1; A/06 is the read.

**The seal, and what ships.** The 0.75 s ring this round tried so the seal would outlive the
sparkle's birth motes did keep the orb framed at sixteen ticks — and this judge read exactly
that as the orb becoming "a ghost … glassware", ranking B/04's clean orb above it, while the
round-1 judge had called the 0.45 s cut's sixteen-tick orb "the best orb in either sheet".
Both put the orb's legibility first. `impact_flash.gd` draws its ring camera-facing without
a depth test in front of whatever it plays on, so every extra tenth of a second is a tenth
of a second the orb is veiled. **`duration` goes back to 0.45 s** (round 1's value, whose
seal frames are `_sheet_after1.png`); radius 0.5, strength 1.0 and the gold stay. The
"three unfused objects" at A/04a are the ring at small radius over the orb face (the same
primitive, three ticks in), the sparkle's dark-haloed motes packed on the orb (`vfx.json`),
and the orb — the ceiling for a config-only retune of this primitive, which both judges
want replaced (soft-edged, ground-conforming, never over the orb, no spikes). Routed with
the rest.

**Routed, with this judge's words, for the coordinator** (none of these files are this lane's):
- `orb.gd`: the untrimmed gold ground quad with a corner at (1000, 610) and a dashed seam,
  pixel-identical in every catch frame of every round — "the most obviously-a-bug element in
  the entire survey".
- `impact_flash.gd`: "kill the flat disc and the spikes"; a soft-edged ring that never covers
  the orb.
- `vfx.json` `catch_burst`: the dark-haloed motes at birth over the orb.
- `combat_hud.gd`: the "!  incoming" line's hue vs the ring; `Day 1 · 07:00` drawn under the
  enemy panel; the enemy nameplate unanchored to its creature; the `bond 0/5` toast without a
  plate; `100 / 100` / `COOLDOWN` grey on navy; the Orbs panel's overhanging grid; "Caught
  Bramblebun!" as the quietest type in the HUD.
- World/water: the stream plane tinting the boulder and fence with a straight edge (both
  judges, and W09's before them).
- Creature art: the bramblebun has no silhouette; no ground shadow under the bramblebun, the
  trainer or the orb.
