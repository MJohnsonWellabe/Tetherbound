# F03#0 lure judge, earned save, set A (code-blind; hall, juno)

Judge input: the 8 frames in `lure-judge-a/` (hall and juno x lure-first-seen, lure-first-readable, approach-30m, prompt-offered; 1280x720 gameplay camera) plus the F03 lure criterion and the ruling ("visible from road, then readable on approach"). No code, data, config or other files were opened.

| activity | visible from road | readable on approach | overall |
|---|---|---|---|
| hall (Alpha Galecrest) | **FAIL** | PASS (marginal) | **FAIL** |
| juno (Tether patrol + Meadowhart) | PASS (marginal) | PASS (marginal) | PASS (marginal) |

## hall

- **Visible from road: FAIL.** `hall_lure-first-seen`: the only trace of the lure is a blue fleck about 12x10 px at roughly (570,130). It sits beside a tan creature and a grey boulder in a busy, tree-framed middle distance, and much of the frame is dark canopy and shadow. No gold nameplate or alpha pin is visible. A player walking past would not notice anything worth a detour. The avatar is also standing on grass, not an obvious road surface, so the "taken on the road" condition cannot be confirmed from the image.
- **Readable on approach: PASS (marginal).** `hall_lure-first-readable` does not read: trunks hide most of the gold nameplate (only "…a G…" shows, about 40 px tall at about (500,165)), and the bird cannot be seen at all. The frame is labelled readable, but it is not. At `hall_approach-30m` the Galecrest is clear: a large blue-and-white raptor about 110x90 px at about (590-690,100-190) with the gold "…Galecrest" nameplate. The stone pylon in front covers the word "Alpha", and no alpha pin can be seen. Two smaller Galecrests nearby are told apart from the alpha only by size. `hall_prompt-offered` (combat) shows "Alpha Galecrest, Level 19" clearly. So what is there only becomes clear at about 30 m, and the alpha status is still hidden at that range.
- **Fix (single most important):** give the site a road-facing sightline. Clear or thin the tree band between the road and the site, or place the alpha on open, raised ground. Also add a distance-legible alpha marker, such as the gold pin or a beacon above the creature, that shows over the treeline from the road. That marker must not be blocked by the pylon.

## juno

- **Visible from road: PASS (marginal).** `juno_lure-first-seen`: a dark smoke column about 45x210 px (x about 240-300, y about 25-240) rises against the night sky. Nothing else in the frame is vertical and man-made, so it is noticeable without looking around. It is marginal for three reasons: it is dark on a dark night sky (low contrast), its lower part sits behind the TEAM panel, and nothing oxblood, no camp and no Meadowhart can be read at this range (a possible white deer speck about 8 px at about (405,265)). The avatar is on grass, but the minimap shows the road running through the player's position.
- **Readable on approach: PASS (marginal).** At `juno_lure-first-readable` and `juno_approach-30m` you can see the smoke column, a campfire glow, two or three dark-maroon standards (about 15x40 px each), a human silhouette and a pale antlered deer (about 15x45 px at about (710,180)). Together these read as "someone's camp with a deer". But at night the maroon barely separates from the wooden posts, the grunt is a black silhouette with no Tether colour, and nothing shows that the deer is held or stolen. At `juno_prompt-offered` it is unambiguous: large oxblood banners, fire, crates, a grunt next to the player, a big Meadowhart on the right, and the prompt "Challenge Tether Patrol". Who is there only becomes fully clear inside prompt range.
- **Improvement (not blocking):** make Team Tether's oxblood read at night and at 30 m. Light the standards or give them emissive trim, and add a visible restraint or tether on the Meadowhart so "stolen creature" reads before the prompt text says it.
