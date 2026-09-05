# Code-blind visual verdict — round 4, run 8 frames (final)

Judge: a fourth sub-agent via the Agent tool (opus was rate-limited mid-run;
this retry ran on the session's then-current model), given only the run-8
`_sheet_route_strip.png`, the four run-8 PNGs, `docs/reference/` and
`.claude/skills/visual-judge/SKILL.md`, plus the note that these are llvmpipe
road frames in the Meadows with one fight and a 1.80 m trainer as the ruler.
It was told nothing about the earlier rounds, this lane's existence, or what
any answer would mean, and was asked to spend most of its effort on the fight
frame's separation and readability specifically. Reproduced verbatim.

---

# Tetherbound Visual Judge — Route Strip (4 frames)

## 1. Ranked defects (brief)

1. **Ground reads as a featureless brown smear.** In all three route frames (00000m, 00040m, 00080m) the dirt path is a blurry, mostly uniform brown-green mass with no visible texture break, worn-track detail, or grass/dirt blending edge. It dominates the lower half of every walking frame.
2. **Vegetation is thin and regularly spaced.** Grass is sparse blade-sprites scattered over that bare dirt/mud rather than a dense mat; trees are uniform "lollipop" canopies at even intervals along the path edge in all three frames — reads as placed by a scatter tool, not a grove.
3. **Frame 1 (00000m) has a silhouette-clarity problem at the house corner.** The grey armored NPC, Terrapup's hindquarters, and the grey stone wall corner sit stacked in the same small area with similar dark/mid-grey values — the NPC nearly disappears into the building behind it.

## 2. Three biggest gaps vs. the references

1. **Ground/foliage density vs. both references** — the keyart's dirt paths have visible pebbles, worn ruts, and grass creeping into the track edges; Palworld's paths are thinner but the surrounding grass is thick and textured right up to the trainer's feet. These frames have neither — just blurred dirt with isolated grass blades (00040m, 00080m worst).
2. **Tree/canopy language vs. the keyart** — the keyart's oak groves are layered, irregular, and read as a "grove"; these frames show identical single-silhouette canopy trees at even spacing (00000m, 00040m), which reads generic rather than authored.
3. **World "fullness" vs. Palworld** — Palworld's screens are visually busy (buildings, crates, other creatures, foliage clutter) even in open-field shots; these route frames are comparatively empty aside from one fence run and one creature.

## 3. The two bar questions

**A. Do these belong to the keyart's world? No.** The building style, palette hue, and creature warmth are in the right family, but the keyart's core promise — lush, richly-detailed ground and groves — is not there; the bare blurred dirt and sparse grass undercut the "cozy, inviting" note specifically. **Fixable**: grass density/scatter, ground texture blend, tree placement variety. **Needs art**: the tree model itself (canopy shape/read) is a single asset repeated; better silhouette variety needs a different or additional tree mesh, not just more of the same one.

**B. Beside the Palworld shots, same kind of game? Yes, with a caveat.** The third-person over-the-shoulder framing, the creature-name/level/HP plate and move-button HUD layout in the fight frame, and the trainer-with-backpack silhouette all read as the same genre and are close copies of Palworld's own HUD conventions. What doesn't clear the bar is world density — Palworld's fields are never this empty or this blurred underfoot. **Fixable**: density/scatter pass. **Needs art**: none of this gap is a modeling problem — it's a dressing/texture problem, so it should be fully fixable in-engine.

---

## 4. Creature and trainer readability (main focus)

**Frame 00000m** — Terrapup present, clearly readable beside the trainer: cream/tan fur, white stone-plate armor down its back, bulky quadruped stance. It reads roughly 1.3–1.5× the trainer's shoulder height and several times his body length — plausibly a "big companion creature," not undersized. Readable, no complaint on this creature alone. The complication is the second (armored, grey) humanoid standing almost against Terrapup's rear leg and the stone house-corner behind it — three grey/tan-ish shapes stacked in one small zone. It's not unreadable, but it's the one cluttered corner of the four frames.

**Frame 00040m** — Terrapup only, isolated against fence/grass/sky, unambiguous silhouette, good scale relationship with the trainer standing beside it (same proportions as frame 1). No issues.

**Frame 00080m** — Same creature, same clean read, now with two small wolf-like animals visible in the far background on the right — legible as background wildlife at that distance, not confused with the main pair.

**Fight frame (band1_fight_galecrest) — the one that matters most:**

**(a) Two separate animals, or one merged shape?**
At full size (1280×720) they read as **two distinct creatures**, not a merged blob. The colour split does the work here: Terrapup is warm cream/tan/white, Galecrest is cool teal/dark-blue/grey — the hue break alone separates them even where the shapes get close. There is a visible sliver of background grass between Galecrest's raised wing and Terrapup's back, and daylight is visible under Galecrest's raised far wing. Where they are tightest is at ground level — Galecrest's talons and Terrapup's front paws are close to touching, with little to no clear gap right at that point of contact, which reads as a deliberate "face-off" pose rather than an accident, but it is the one spot where the two silhouettes come closest to fusing.
At contact-sheet (thumbnail) size, the separation is **weaker but still holds**: the two forms blur together somewhat at the point of contact, but the same warm/cool colour break still lets you tell "there are two things here" rather than one. I would not call this a merge failure, but it is close enough that a slightly different camera angle or a half-step of separation between the two models would remove the ambiguity entirely rather than relying on colour alone to save it.

**(b) Is the opponent readable — species and relative size?**
Yes. Galecrest reads unambiguously as an avian/gryphon-type creature: hooked beak, spread feathered wings, clawed feet, long tail plumage. Its body bulk is comparable to Terrapup's — not obviously smaller or a "trash mob" — and its spread wingspan makes it the visually larger of the two creatures in the frame, appropriate for a same-or-higher-level wild opponent (HUD marks it Level 3 vs. the player's Level 1 Terrapup). No scale violation here — it does not read as smaller than it should relative to the trainer or to Terrapup.

**(c) Is the trainer present, uncropped, and watching?**
Yes. He is fully visible bottom-left, head to feet, not cropped by the frame edge, not clipped by the HUD (the Terrapup status panel sits below and beside him with only marginal proximity to his feet, no visible overlap of his character model). His pose — angled toward the confrontation — reads as watching the fight rather than participating directly, consistent with "the human never fights." No ambiguity on this point.

**Bottom line on the fight frame:** nothing is too small, cropped, or hidden. The one soft spot is that the two creatures' readability as *separate* animals leans on colour contrast rather than on a clean silhouette gap — it survives at full size, and survives at thumbnail size only because the palettes happen to be different temperatures. If a future matchup pairs two creatures of similar hue, this same staging distance would likely produce an actual merge, which the rubric would then have to fail.
