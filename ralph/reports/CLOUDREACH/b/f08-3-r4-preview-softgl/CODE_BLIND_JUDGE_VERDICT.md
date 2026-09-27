# F08#3 High Perches r4 (softGL preview): code-blind verdict

Per frame: (a) reads as high / (b) uncrowded / (c) trainer locatable / (d) coherent landmark

| Frame | a | b | c | d |
|---|---|---|---|---|
| glide-approach day | NO. The gate mesa on the left is level with the crown. Canyon on the right helps, but no ground or cloud floor sits far below. | YES | NO. About 15 px, lost under the arch. | NO |
| glide-approach night | NO | YES | YES. A small lit figure. | NO |
| southeast-glide day | NO. Shot from below, so it reads as a hill or mound. | YES | NO. The crown top is hidden. | NO |
| southeast-glide night | NO | YES | NO | YES. Best silhouette of the set. |
| west-glide-high day | NO. The clouds are at crown level and a green mesa continues behind. It reads as a promontory, not a lone pillar. | YES | NO. It is barely visible. | NO |
| west-glide-high night | NO | YES | YES. Just barely. | NO |
| court-high-oblique day | NO. Only haze below, with no terrain far below. | NO. Two columns cut through the top edge and occlude the court. | YES | NO |
| court-high-oblique night | NO | NO | YES | NO |

## Overall: FAIL

Rim crowding is mostly fixed. The r3 defect (1) remains: no frame shows depth below the crown.

Concrete fixes:
1. **Show the drop.** At least two stands need to look down and past the rim to a far-lower layer: the canyon floor, lower plateaus, or a cloud sea well below the crown. Adjacent landforms must sit clearly lower. The gate mesa (glide-approach and west) is level with the crown or above it, so lower it, move it, or frame it out.
2. **Southeast stand:** raise the camera above crown height. The current worm's-eye view makes the pillar look like a knoll and hides the trainer.
3. **Needles:** they read as smooth identical cylinders with plank caps, like chimneys or smokestacks. Give them taper, strata and irregular tops (ART_DIRECTION wants "strata" and stacked silhouettes). In the court frame, move or reframe the two front columns so they don't cut the top edge or occlude the court.
4. **Pale cliffs:** the white/blue cliff masses (west, court and southeast) are flat-shaded and read as ice or untextured placeholder. At night they are the brightest thing in frame, so the values are inverted. Give them the pale weathered stone material and a night value below the lit crown.
5. **Clouds:** the flat stacked-disc clouds read as placeholder. Put them below the crown to act as the depth cue.
6. **Artefacts:** fix the rim props that hang into the air (curved black hooks with dangling poles) and the floating grass slab on the left of glide-approach.
7. **Trainer:** give the trainer a readable contrast or rim light, and a stand where they are at least about 25 px tall.

Bar A (Cloudreach board identity): NO. The sky is right, but the stone, strata, bridges and aviary language aren't there. Bar B (Palworld): NO. The clouds, ice cliffs and cylinders read as greybox. Fixes 1, 2, 3 and 6 are scene changes. Fixes 4 and 5 need material or asset work.

## Camera question

These are fixed evidence stands, and the manifest says so ("not the gameplay spring arm"). C2 asks for "high-perch **production-camera** footage", and ART_DIRECTION says high-perch captures "must use a corrected camera". The Meadows precedent (ART_DIRECTION §village) defines production-camera witnesses as approach, centre and departure motion at the play camera.

As judge: the stands are acceptable as supplementary establishing shots for the landmark's silhouette. They cannot satisfy F08#3 alone, because the criterion is about the camera the player actually gets. Gameplay spring-arm frames or footage are also needed: arriving by Fly, standing on the crown (trainer framed, with the rim and the drop visible behind), and departing. They must show that the corrected camera doesn't clip into the needles and that the height reads from the player's own view. These frames were rendered with software GL, so a GPU re-capture is also needed before final acceptance.
