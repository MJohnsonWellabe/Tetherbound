# Code-blind review: home creature bed (F17)

Inputs judged: `home_bed_day.jpg` (Day 1 08:00) and `home_bed_night.jpg` (Day 1 23:00), 1920x1080. I opened no code, config or report files. I also made enlarged crops of the bed region, brightened for night.

## 1. Can the bed be found?

YES in both frames. It is the only new object beside the house: a low, dark, double-coiled ring with a flat brown woven/bark pad inside. It sits on the grass at the right end of the stone ground floor, between the wooden bench and the barrel/crate group.

- Day: approx. x 800–1110, y 520–615 (ring outline). The pad inside spans approx. x 815–1095, y 535–590.
- Night: approx. x 800–1105, y 525–610. The pad is lit, roughly x 840–1090, y 535–585.
- In both frames the trainer stands in front of the bed and hides about a third of its front-centre (x 905–1000).

## 2. Does it read as a creature bed or resting nest?

**NO (weak, ambiguous).** If I had not been told, I would read it as a **raised garden bed or vegetable plot edged with logs**, or possibly a **coiled hose or rope on the ground**. A fire-pit ring would be my next guess. Why:

- **It is flat.** The rim is two thin, dark, rope-like coils, roughly ankle height (about 15–20 cm against the 1.80 m trainer). The interior is a flat brown plane at ground level. A nest needs a dished, raised, cushioned rim that you could curl up inside. There is no visible volume or soft material (straw, hay, fleece, blanket or cushion).
- **The interior pad is rectangular, not round.** Its straight edges and corners do not follow the ring. On the left (around x 815–840, y 560–580) a corner pokes past the inner coil. Brown, square soil inside a border is the visual language of a garden plot. Combined with the farmhouse setting, that pushes the read firmly toward "garden bed".
- **The colour is dark charcoal and dirt brown.** These are the colours of soil, charred logs or tyres, not warmth or comfort. Nothing hints at an animal's use (pawprints, a tuft of fur, a food bowl, a nameplate or a hanging lantern).
- It does not read as a decal: the coils have real depth and cast contact shadows. It does read as a low ground border, though.

## 3. Does it belong beside the house?

**PARTIAL: scale is plausible, grounding is good, and clearance is too tight.**

- **Scale: YES.** The ring is about 1.3–1.4x the trainer's height across, which matches the stated ~2.4 m. A creature larger than a person could plausibly lie in it. However, it is so low that it reads smaller and less substantial than it is.
- **Grounded: YES.** The coils sit on the grass with contact shadows. Nothing floats.
- **Clipping and crowding: borderline.** The back of the ring runs right up to the grey stone plinth/path at the base of the wall (around x 830–1100, y 525–540). From this angle the back coil appears to touch or slightly overlap the plinth slab, with no grass gap. The left edge of the ring (around x 800–815, y 565–595) almost touches the right end of the bench and its stool (bench ends around x 795). The bed looks squeezed into the corner rather than placed. There is no visible wall interpenetration.

## 4. Is it readable at night?

**PARTIALLY.** The interior pad catches a pool of warm light and is one of the brighter ground patches, so the location is findable. The dark coil rim, however, almost disappears into the night grass and the plinth shadow. What remains is a lit square patch of ground with no recognisable silhouette, which reads even less like a nest than in daytime. Most of the brightness comes from the nearby campfire at the door and the lit windows, not from the bed itself.

## 5. Defects and suggested fixes

1. **Silhouette (main issue: it does not read as a nest).** Replace or augment the flat pad with a dished, raised form. Give it a thick rim about 35–50 cm high (woven wicker or bundled straw) and a sunken soft centre (hay or straw texture, or a fleece/blanket in a warm cream or wheat tone). Make the interior round to match the ring. Use installed nature/village props (straw, wicker basket, cloth) if a new mesh is out of scope.
2. **Rectangular pad poking past the ring.** Either make the inner fill circular or scale it down so that no corner crosses the inner coil (visible on the left edge in both frames).
3. **Clearance.** Move the bed about 0.6–1.0 m away from the wall, out onto the grass. Then the back coil clears the stone plinth and there is a visible grass gap to the bench end, which avoids the jammed-into-the-corner look and any slab overlap. Rotating or offsetting it slightly to the right, toward the open grass before the barrels, would also stop the default camera placing the trainer squarely in front of it.
4. **Colour.** Lighten the rim from charcoal to a warm straw or wicker tone so that it separates from the soil-coloured interior and stops reading as logs around a garden plot.
5. **Night readability.** Add a small warm source tied to the bed (a hanging lantern on a post, or a faint emissive on the rim or bedding) so the rim silhouette survives at night, not just the interior patch.
6. **Optional affordance cue.** A small sign or nameplate, a water/food bowl or a scatter of fur tufts would quickly tell the player "creature rests here" without needing UI.

**Verdict:** the bed is placed, grounded and correctly sized, but it **does not yet read as a creature bed**. It reads as a log-edged garden bed. Fix the silhouette and fill (1, 2, 4) and the wall/bench clearance (3) before accepting it visually.
