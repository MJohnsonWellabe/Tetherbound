# Blind visual judge — round 1 (2026-09-05)

Code-blind sub-agent (opus). Given: the contact sheet `_sheet_round1.png`, the
full-resolution frames under `shots/w06_before/` and `shots/w06_after/`,
`docs/reference/`, and `.claude/skills/visual-judge/SKILL.md`. Told nothing about what
changed, which column was which, or what the lane hoped it would say; the sheet's rows
are labelled by camera stand only. It identified the frames by matching pixels.

Verdict committed verbatim below.

---

I read the skill, the contact sheet, and the full-resolution frames. Frame identification, confirmed by matching pixels rather than filenames:

- Row 1 A = `shots/w06_before/C-01-chamber-face-bound.png`, Row 1 B = `shots/w06_after/C-01-chamber-face-bound.png`
- Row 2 A = `shots/w06_before/C-03-chamber-corner-bound.png`, Row 2 B = `shots/w06_after/C-03-chamber-corner-bound.png`
- Row 3 A = `shots/w06_before/C-05-chamber-corner-freed.png`, Row 3 B = `shots/w06_after/C-05-chamber-corner-freed.png`
- Row 4 A = `shots/w06_after/G-01b-causeway-night-held.png`, Row 4 B = `shots/w06_after/G-03b-causeway-night-freed.png`
- Row 5 A = `shots/w06_after/G-02-yard-night-held.png`, Row 5 B = `shots/w06_after/G-04-yard-night-freed.png`

---

# 1. Rows 1–3: where the creature actually reads

**Row 1 — head-on, machine filling frame.**
The frame is a symmetrical stone hall; a tall teal-green structure sits dead centre on a stepped plinth, two arms curving overhead to a glowing green boss at the apex, a broad stair running to camera. Four flat cyan bars cut across the walls at 45°.

- **A: no creature.** In the machine's central alcove, at plinth level, there is a cluster of roughly twenty small flat-white unlit vertical quads of uneven length, half-buried in the machine's own geometry. Unaccompanied, they read as a bar chart or a white picket fence dropped into the shot — not as a cage, not as a field, not as anything.
- **B: creature present, inside the machine.** A dark quadruped with gold panelling and a pale antler crown stands head-on in the alcove, raised to the machine's mid-tier, with two flat white hexagonal ring outlines around its chest and hips. Positionally it is the only frame in the set that reads as **"the machine is running on this creature."** But it reads that way by *placement only*: the rings do not touch it, there is no cable, clamp, beam, glow, socket or spill of light between creature and machine, and the creature's hindquarters simply dissolve into an unlit black void behind it. Nothing is doing anything to it. It reads more like "a creature has walked into an alcove" than "a creature is the power source."

**Row 2 — raised three-quarter from the doorway corner.**

- **A: creature present, standing beside the machine on the floor.** It is on the ground plane at the far left, clearly outside the machine's base footprint, with ~20 of the same flat-white vertical bars scattered around it at random heights — several clipping straight through its body, several sunk into the floor, several floating clear of it. This is unambiguously **"a creature standing next to a machine,"** with debug primitives strewn around it.
- **B: creature present, inside the machine.** It is now in the machine's upper alcove, small in frame, with two flat white hoops at chest and hip. Positionally it reads as inside. Legibly it barely reads at all: its black-and-teal body sits against the machine's black-and-teal clutter, and at contact-sheet size it is an indistinct pale smear. Its scale relative to Row 3 is actually consistent once distance is accounted for — the problem is camouflage, not size.

**Row 3 — same three-quarter, later.**

- **A and B: creature present, standing on the chamber floor beside the machine.** Both read as **"a creature standing next to a machine."** No restraint geometry, no rings, no bars, nothing connecting it to the structure. B differs only in pose and framing: the creature is turned further toward camera, head lowered, the green chest fronds brighter and the crown reading more clearly. In neither is there a visible contact shadow under it, so it sits on the floor without landing on it.

**Plain answer:** Row 1 B and Row 2 B read as inside the machine. Rows 2 A, 3 A and 3 B read as beside it. Row 1 A has no creature. And I would qualify the first group hard: *inside* is carried entirely by where the creature is standing. Nothing in any frame visually asserts that the machine is *drawing on* the creature — no light travels between them, the machine's green glow is identical in Row 1 A (empty) and Row 1 B (occupied), and the containment rings are unlit white polygons with visible faceting that read as unshaded placeholder geometry. The staging is right; the connective language is missing.

---

# 2. Rows 4–5: held vs. stood down

These are genuinely dark night frames under software GL. I lifted both pairs with a 0.42 gamma to read them; mean luminance is 6/12/26 and 5/11/26 (Row 4 A/B) and 10/6/11 and 5/4/9 (Row 5 A/B) out of 255. The difference is **real and callable**, but it is carried by a very small number of pixels.

**Row 4 (gate face from the causeway).** A reads as **manned**; B reads as **stood down**. Evidence, all of it small:
- Two guards in pale tan uniforms standing at the gate arch in A, absent in B. Each is about 55 px tall in a 1280-wide frame.
- A barrel and a small cart on the causeway in A, absent in B.
- Two small warm bracket lamps lit above the flanking brazier plinths in A, dark in B. The braziers themselves are unlit black bowls in both.
- The banner colour shifts from warm magenta-lit in A to cold violet in B, and the causeway floor loses most of its warm bounce.
- The gate is **closed with the same purple curtain-banner in both** — B does not read as opened, breached, or vacated, only as unattended.

**Row 5 (courtyard from the gate sill).** A reads as **occupied**; B as **stood down**, but weakly, and one element actively inverts the reading:
- The brazier at right is lit in A (flame plus rising sparks) and unlit in B. This is the single strongest cue in the pair.
- A stacked log pile, a bench in the left foreground, and a barrel are present in A and gone in B.
- Two hanging vine/garland strands appear on the columns in B and not A.
- **The same NPC stands in exactly the same spot, in the same pose, in both frames.** An "abandoned" courtyard with a garrison figure still posted in it undoes the story the rest of the props are telling.
- **The foreground floor is nearly pure black in the occupied frame A and warmly lit cobblestone across the whole lower half in the abandoned frame B.** The stood-down state is the brighter, warmer, more inviting of the two. That is backwards.
- The four Team Tether banners, the emblem, the weapon rail, the cistern prop, the crates and the inner doorway are identical in both; only the doorway's light shifts warm-red to cold.

So: callable, yes. Convincing, no. Strip the two guards and one brazier flame and the pairs are indistinguishable.

---

# 3. What is wrong, worst first

1. **The machine does not read as a machine.** In every chamber frame it is a single monolithic teal-green mass with blurred, low-frequency texture and no mechanism anywhere on it — no wheel, piston, coil, conduit, panel, gauge, vent or seam that separates from the mass. At contact-sheet size Rows 2 and 3 read as *a green rock formation*. This is the game's climax object and it has no legible function.

2. **"Captured and retrofitted" is completely absent.** The machine shares zero material or colour vocabulary with the faction that captured it. The fortress speaks in violet/magenta banners, red causeway timber and a white circle-cross emblem; the machine speaks in undifferentiated ancient teal. Nothing bolted on, no oxblood plating, no cabling, no scaffolding, no emblem. Compare the key art's stronghold panel, which sells occupation with timber scaffold, palisade and hanging red banners over old grey ruin. The retrofit story does not exist in these pixels.

3. **The containment VFX are unlit white primitives.** The vertical bars (Row 1 A, Row 2 A) and the hexagonal hoops (Row 1 B, Row 2 B) are flat, self-lit, shading-free white polygons with visible facets, of varying random lengths, clipping through the creature and the floor. They cast no light, receive none, and glow nothing. Row 2 A in particular — twenty white sticks around a creature standing several metres away from the machine — reads as a debug draw someone forgot to disable.

4. **The diagonal cyan bars slicing the chamber.** Four to five flat cyan rectangles cross the walls, floor and machine at 45°. They pass through solid geometry, cast no light, have no source and no terminus. They are the loudest artefact in the chamber set and they read as a rendering bug.

5. **Row 4 and Row 5 give 40–60% of the frame to unreadable black.** In Row 4 the entire lower 40% — the causeway the player is standing on — is void. In Row 5 A the near half of the courtyard floor is void. Nothing is composed there; it is not moody, it is missing. The key art's own night panel shows the intended answer: deep blue night with a warm fire as the focal punctuation and the ground still legible.

6. **Team Tether's occupation reads as decoration, not as force.** In Row 5 the four banners are identical, identically sized and evenly spaced along the wall like wallpaper — a procedural-looking placement, not an authored one. In Row 4 the only piece of Team Tether hardware visible is a flat untextured blue box with a cyan tube running off to the right over the moat, unlit, unanchored, floating. That is the faction's signature tech object and it is a rectangle and a straw.

7. **Colour is single-key in both locations.** The chamber is teal-on-teal-on-olive with one green accent; there is no warm note anywhere to give the green somewhere to be green *against*. The courtyard is magenta-on-violet, with the magenta lighting leaking onto the stone walls so the whole right wall is pink, not just the banner. Neither location has the value range or the hue contrast of any Palworld reference, where a single warm key against cool shadow does the whole job.

8. **Empty ground everywhere.** The chamber floor is a featureless olive-brown plane with no rubble, no cabling, no scorch, no floor markings, no props — the bottom third of Row 1 and the left half of Rows 2 and 3 are empty. The Palworld references have flowers, grass tufts and ground debris out to the near-field in every frame.

9. **No contact shadows.** The creature in Rows 3 A and B has no readable shadow under it; it sits on the floor rather than standing on it. Same for the barrel and cart in Row 4 A.

10. **Composition is static and symmetric.** Row 1 is a dead-centre bilateral shot with mirrored wall lamps, the machine's top cropped off and the frame bottom-heavy with stairs. Rows 2 and 3 are the same camera twice with the subject in the same third. Nothing is composed to make the climax feel like an event; compare Palworld's boss shot, which frames the creature large, off-axis, mid-action, with the player in the near corner for scale.

11. **No ruler in the chamber.** The trainer appears in none of the five chamber frames, so relative scale in the game's most important room is unverifiable from these stills. What I can check — creature against machine base, creature at Row 2 B distance against creature at Row 3 distance — is internally consistent, so I am not calling a scale defect; I am calling a missing scale cue.

12. **Texture resolution on the machine.** Heavy bilinear mush at the sizes it is presented at, with tiling stone behind it whose repeat is visible as a stamped pattern across the back wall in Row 1.

---

# Verdict

**The three things that most separate these frames from the references.** (1) The key art's stronghold panel makes occupation legible in one glance — scaffold, palisade, hung banners, lit gate — while Row 4 B differs from Row 4 A by two 55-pixel guards and a barrel; the state change is technically present and dramatically invisible. (2) Every Palworld reference has a warm key against a cool field and readable ground detail to the near edge; Rows 1–3 are one teal mid-tone with an empty floor, and Rows 4–5 hand half the frame to black. (3) The Palworld boss frame makes the creature the event — large, off-axis, in contact with the world through impact sparks and light; in Row 1 B, the single frame where the creature is supposedly powering the machine, nothing passes between them and the machine's glow is byte-for-byte the same as in the empty Row 1 A.

**Bar question A — do these belong to the world of `tetherbound-meadows-keyart.png`?** **No.** The board specifies deep red banners with the white compass-cross on warm grey stone, vegetation reclaiming the ruin, and night rendered as blue with warm firelight punctuation. The courtyard delivers violet-magenta banners washing pink light onto the walls, and a night with essentially no warm punctuation. The chamber has no counterpart on the board at all and shares no palette with it.

**Bar question B — beside `palworld-0*.jpg`, same kind of game?** **No.** Density, value range, ground detail and staging are all a tier below, and the climax object reads as terrain rather than as machinery.

**Fixable by changing the scene:** the black-crush and missing warm key in Rows 4–5; the pink light leak onto the courtyard stone; banner spacing and variety; ground scatter and debris in the chamber; contact shadows; composition and camera on all five; removing or re-authoring the cyan slicing bars; replacing the white bar/hoop primitives with an emissive, light-casting restraint effect; making the machine's glow respond to whether a creature is in it; deleting the courtyard NPC from the stood-down state; and inverting the Row 5 lighting so occupied is the warmer state. **Not fixable by scene changes:** the machine needs actual retrofit geometry and a legible mechanism — bolted Team Tether plating, cabling, a socket the creature occupies — and the relay hardware on the causeway needs to stop being an untextured blue box. Those are art that is not in the build.

This is a climax that currently reads as a green rock in a dark room with a deer standing politely nearby, and a fortress whose fall is announced by removing two guards and blowing out one candle. The staging decisions underneath are sound — the creature is in the right place in Rows 1 B and 2 B, the held/freed prop pass is doing the right kind of work in Rows 4 and 5 — but nothing in the rendering carries them. Not shippable as the game's final location.
