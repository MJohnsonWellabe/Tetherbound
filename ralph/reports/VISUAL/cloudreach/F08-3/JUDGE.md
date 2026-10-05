# F08#3 code-blind verdict: High Perches production camera (Low/Compatibility, 12 frames)

Inputs I used: the 12 frames plus the sheet, criteria.md, and the four references. I read no source code, reports or earlier verdicts.

## Per-frame camera notes

1. **arrival-far-day**: Nothing blocks the lens and the framing is good: the perch crown sits mid-frame, the cloud sea and lower mesas are on the right, and the drop below the cliff is visible. This frame reads as high. The carrier bird's spread wings cover the trainer's head and shoulders, so from behind the trainer is only legs and a backpack.
2. **arrival-lip-day**: Readable court, with the two stone gate piers framing the landing ring. A dark curved rail/pipe prop pushes into the bottom-left corner, and the cliff rim fills the bottom edge. The wings again hide the trainer's upper body. Height reads only from the cloud sea on the right edge.
3. **arrival-landed-day**: The trainer is clear and centred and nothing clips the lens. The frame looks away from the perches, though: it is a flat lawn with a bench, the ram and the glider, and no pillars, rim or drop are in view. It reads as a meadow with clouds at the horizon, not as high ground.
4. **crown-rim-out-day**: **Fails the brief.** The camera is supposed to tilt down over the drop, but it shows a grass slope with the cloud sea almost level with the trainer. No cliff face or depth falls away. A black/dark-green object is cut off by the near plane in the bottom-left corner, which is lens intrusion. The left third is a flat grey haze wall with no sky. A floating nameplate/text label hangs above the orange pad.
5. **crown-court-day**: The trainer is readable and nothing clips the lens, but a huge pillar base fills the left third and oversized grass cards fill the foreground. The camera sits at court level, and no rim, drop or cloud sea is visible, so the frame does not read as high at all. A cut-off text label ("...d your footing") is jammed against the pillar beside the glider.
6. **departure-lookback-day**: The trainer faces the camera under the carrier and is readable. The landmark and court skyline make a good silhouette. The cliff wall behind the trainer is in deep, muddy shadow, so the trainer sits on a dark field with little contrast. The left horizon is a grey haze void. A small floating text label sits on the right edge. Height reads moderately, via the lower shelves at bottom-left.
7. **arrival-far-night**: Same composition as day, with nothing clipping. Height reads well thanks to the moonlit cloud sea. The trainer is tiny and mostly hidden by the dark-blue wings, and the cliff masses merge into one dark slab.
8. **arrival-lip-night**: Same composition as day, and the rail prop still pushes into the bottom-left corner. The court lamps give a small warm read on the ground, which is good, but the wings still hide the trainer's upper body.
9. **arrival-landed-night**: **The lens is crowded.** The ram fills the left quarter and is cut off by the frame edge. The glider's head and fins fill the right third and run off the right and bottom edges. The camera seems to have ended up much closer to the companions than in the day frame. The trainer stays readable in the centre, but the scene reads as flat ground with no sense of height.
10. **crown-rim-out-night**: Same defects as day: the near-plane object clips the bottom-left corner, no drop is shown, and a floating label hangs above the pad. The upper-left half is a flat dark-blue plane that reads as ocean or void rather than sky, so the frame loses all sense of altitude.
11. **crown-court-night**: Same framing as day, with the pillar filling the left third and no height cue. The trainer is readable. One lamp lights a pillar base warmly, which is nice. The horizon is a flat dark plane.
12. **departure-lookback-night**: The trainer is readable against the cliff, and this frame is actually lit better than the day one. The skyline silhouette is good. A flat dark-blue plane sits behind the shelf where sky and cloud sea should separate, so height reads only from the lower-left terrain.

## Remaining bar defects

- **Sky / horizon void**: rim-out-day, departure-lookback-day (left) and arrival-landed-day (behind the mesas) show a featureless grey haze band instead of high blue sky. At night, rim-out-night, crown-court-night and both departure frames show a flat dark-blue plane that reads as sea rather than sky above a cloud layer. This breaks "clear high blue" and "height-aware cloud banks".
- **Cloud layer not below the shelves**: in rim-out (day and night) the cloud sea sits nearly flush with the crown grass and looks like a snowfield next to the lawn. In arrival-far the cloud sea is correctly below, but it has no stacked haze between shelves. The small white ellipse "cloud puffs" scattered on the mesas (arrival-far and arrival-lip, day and night) look like placeholder discs.
- **Placeholder shapes**: the perch crown and the neighbouring shelves are plain extruded cylinders with flat tops (all frames, clearest in rim-out and arrival-far). The neighbouring shelf carries a flat orange disc "pad" that reads as a placeholder slab (arrival-far, rim-out, departure). The distant rim fortress is a plain cylindrical wall with a gate prop (arrival-far, arrival-landed). The pillars are untextured-looking tubes with board caps. The ground has no rope/timber bridge rails or skyroad. Nothing resembles the reference board's stacked cliffs, strata, waterfalls or domed Aviary.
- **Materials**: one noisy granite texture is stretched over cliffs, pillars and crown, with no strata, bedding or moss following the shelves (arrival-far, departure-lookback). It reads brown-grey rather than pale weathered stone. Distant mesas are flat grey extrusions. The grass ground is a uniform tiled texture, and the grass cards are oversized next to the trainer (crown-court).
- **Light**: in departure-lookback-day the whole cliff face is in deep shadow while the sky is bright, so the warm-stone/cool-sky separation is missing. Shadows are hard and uniform, and there is no atmospheric depth or haze separating the shelves (expected on Low, but it still misses Bar B).
- **Night lighting**: the moon is good and the cloud sea is moonlit, but there are no contained warm Aviary windows, the lamps are tiny and sparse (arrival-lip-night, crown-court-night), there are no stars of note, and the cliffs crush to a single dark-blue mass (arrival-far-night). The night creatures in arrival-landed-night are lit flat, with no rim light.
- **UI/debug**: floating text nameplates are visible in rim-out (both), crown-court (both) and departure-lookback (both, right edge).
- **Creatures**: the ram and glider broadly match the roster board's Stormcapra and Ribbonray identities, which is good. The carrier bird's wings consistently hide the trainer from behind (arrival-far and arrival-lip, day and night).

## Answers

- **Camera correct: NO.** Arrival-far and departure are acceptable. Rim-out has a near-plane clip in the corner and never shows the drop. Crown-court and arrival-landed do not read as high. Arrival-landed-night has companions filling the lens, and arrival-lip has a rail prop pushing into frame.
- **Bar A: NO.** Placeholder cylinder cliffs, flat orange pad discs and a cylinder fortress, with no Aviary, strata, bridges or settlement read compared with the Sky Aviary board.
- **Bar B: NO.** Grey or flat-plane horizon voids, no haze between shelves, muddy day shadow on the departure cliff, and a night without contained warm window light. This is Low preset only; High and Medium were not supplied.

## Overall F08#3: **FAIL**

Top blocking defects:
1. **crown-rim-out (day and night):** a dark prop is clipped by the near plane in the bottom-left corner, and the "tilted down over the drop" shot shows no drop: the cloud sea is level with the lawn and the frame does not read as high.
2. **arrival-landed-night:** the ram and glider fill and run off the left and right of the frame, so the post-landing camera does not keep companions out of the lens. Arrival-landed (both) also faces away from the perches and reads as a flat meadow.
3. **crown-court (both):** the camera sits at court level behind a pillar that fills a third of the frame, with no rim or cloud-sea cue, so the frame does not read as a high perch.
4. **arrival-lip (both):** the curved rail prop pushes into the bottom-left corner. In arrival-far and arrival-lip the carrier's wings hide the trainer's upper body.
5. **Bar failures that block the full bar regardless of camera:** placeholder cylinder cliffs and orange disc slabs, grey or flat-plane horizon voids, floating text labels, and a night without warm contained light. No High or Medium matrix was provided.
