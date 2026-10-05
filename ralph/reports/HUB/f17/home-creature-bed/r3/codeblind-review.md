# Code-blind review r3: home creature bed

I opened no code, config, docs or report files. This review is based only on `home_bed_day.jpg` and `home_bed_night.jpg` (1920x1080), plus 2x crops of region x 880-1560, y 420-720. I brightened the night crop by 1.8x.

## 1. Findable in each frame: YES

- **Day (08:00):** The bed sits right of the trainer, in front of the farmhouse's stone ground floor. It spans roughly x 1030-1450, y 555-665. It has three parts. A dark ring of bound logs lies flat on the grass, x 1030-1450. A square wooden plank deck sits inside the ring, about x 1095-1375, y 560-640. A pale cream oval pad rests on the deck at about x 1130-1300, y 565-610.
- **Night (23:00):** The bed is at the same spot. The hanging lantern on the post at x ~1430-1500, y 425-670 lights the deck and the right arc of the ring warmly. The cream pad has a lit dome with a visible highlight at x ~1135-1300, y 565-600.
- Nothing else in the yard has this shape, so the bed is easy to find in both frames.

## 2. Reads as a creature bed or nest without context: PARTIAL

- **What helps the read:** It is a round, enclosed shape with a soft-looking cushion at its centre. It is clearly larger than a person and sits in a domestic yard beside the house. Together these suggest "something big sleeps here". At night the pad gains volume and reads as a padded mattress or cushion. That read is better than in daytime.
- **What hurts the read:**
  - In daylight the cream pad renders almost unshaded and flat (crop: flat cream, no rim shadow). It reads as a sand patch, a hay spread or a rug, not as a soft mattress.
  - The log ring lies at ground level, one log high, with a gap at the back. It reads as a garden border, a dry fire ring or a corral footprint, not as raised nest walls.
  - The square plank deck inside the round ring is the strongest wrong cue. It makes the whole object read as a small stage, a threshing floor or a building foundation that has not been built yet.
  - Nothing ties the object to creatures: no loose straw or tufts at the edges, no blanket, no feed bowl, no paw-worn hollow.
- An uninformed viewer would most likely call it a "sandpit or hay floor with a log border" first and a "pet bed" second.

## 3. Belongs beside the house: PARTIAL

- **Scale: YES.** The ring is about 420 px wide at a depth slightly behind the trainer, who is about 230 px tall. That makes the bed roughly 4-5 m across, which suits creatures larger than 1.8 m.
- **Grounding: YES.** The logs and deck sit on the terrain without visible floating. Grass grows up around them naturally.
- **Clearance:** The bed is about 1.5-2 m in front of the wall and bench (bench at y ~510-530). Nothing clips the wall. The crates at x ~1600-1830 have clear space between them and the bed. The trainer at x ~900-1020 stands to the left and does not block the bed.
- **Crowding:** The lantern post's foot stands right on the ring's right edge (x ~1450-1475, y 600-670). It reads as touching or piercing the logs. In daylight the tall shaft looks like a stake driven into the ring.
- **Placement:** The bed floats in the open lawn. No path, ground patch or fence links it to the house, so it reads as "placed near the house" rather than "part of the homestead".

## 4. Readable at night: YES (with a caveat)

- **Silhouette: YES.** The pale pad and lit deck are the brightest ground surfaces in the lower-right quadrant. The ring's right arc catches lantern light.
- **Own light: PARTIAL.** The hanging lantern beside it lights the bed and reads as belonging to it. However, the left half of the ring (x 1030-1150) and the back arc fall almost to black against the dark grass. The ring's full circle is lost, leaving a lit deck with a partial dark arc.
- The night frame is the better of the two for identity, because the pad gets real form shading.

## 5. Defects in priority order, each with a fix

1. **The square plank deck inside the round ring reads as a stage or foundation.** Fix: remove the deck or make it round, and recess it slightly. Alternatively, replace it with a thick, uneven straw or hay bed that fills the ring.
2. **The daytime cushion is flat and unshaded, reading as a sand patch.** Fix: give the pad real height (a pillowy dome or a donut-shaped bolster). Use a material with diffuse shading and a contact shadow, plus a fabric or straw texture, so it holds form under sun as well as lantern light.
3. **The ring is ground-level and reads as a border, not nest walls.** Fix: raise it to two or three stacked or woven layers at knee-to-hip height relative to the trainer, and let the walls lean inward. Close the gap at the back, or turn it into a deliberate entrance facing the player.
4. **There are no creature cues.** Fix: add one or two small cues from the installed prop family, such as loose straw tufts spilling over the rim, a folded blanket, or a water or feed trough beside it. No new meshes are needed.
5. **The lantern post collides with the ring edge.** Fix: move the post about 0.5-1 m outside the ring, angled so the lantern still hangs over the bed.
6. **At night the left and back arcs of the ring go black.** Fix: raise the lantern's light range, or add a faint warm fill or emissive at the bed's centre, so the full circle stays readable.
7. **The bed is not tied to the homestead layout.** Fix: add a worn dirt or stone path patch linking it to the house, or a short fence stub, so it reads as a homestead station.

Verdict: PARTIAL. The bed is easy to find, sits at sensible creature scale beside the house and stays readable at night under its lantern, but the square deck, flat daytime pad and ground-level log ring make it read as a sandpit or stage before it reads as a creature nest.
