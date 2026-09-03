# The full-corridor blind pass — round 1

**Verdict: A — no. B — yes, narrowly.**

Sheet: `shots/corridor_pre/_sheet.png`, 16 frames — twelve daylight and four
night, walking one continuous 7.5 km route through all five bands in the order
a player travels it. Critic: an independent Fable sub-agent per
`ralph/OWNER_DIRECTIVES_2026-08-22.md` §5 (blind review is Fable-only and never
judges evidence it produced), given the sheet, the frames and `docs/reference/`,
told nothing about what changed or what anyone hoped to hear.

**What this pass judged: `main` at 1adfeacb, BEFORE the five visual lanes
landed.** VISUAL-LIGHT, VISUAL-GROUNDCOVER, STRONGHOLD-R2, CREATURE-IDENTITY-2
and BAND2-FLOOR all pushed while it was rendering. They target this critique's
gaps 1 and 3 directly, so round 2 is the merged build and is not graded against
this verdict.

## B moved. That is the news.

`ralph/ASSESSMENT_2026-08-23.md` recorded **both** bar questions as NO. B is now
yes: *"the grammar matches — over-shoulder trainer on a trail, wild creatures
beside the path, glowing enemy towers as landmarks."* The narrowness is the
finding, not a hedge: **two frames of sixteen carry it** (`03-band2-stone-root`
and `11-band5-mid-route`), and *"shown 05 or 07 alone, a viewer would say 'empty
prototype'; shown 08-day they would say 'broken prototype'."*

## The finding that outranks the verdict: the player is standing on an NPC's head

> *"Both feet planted on the crown of a cloaked NPC, the pair reading as a
> ~3.5 m totem pole… the player character broken in a fifth of the survey, and
> it persists across a day and a night capture in the same band, so it is a
> state that survives along the route, not a one-frame fluke."*

`08-band4-ironwood-day`, `08-band4-ironwood-night`, `09-band4-ridge-day`. Reached
blind, with no knowledge that anything was being tested. Under investigation as
a separate item — the honest question is whether a walking player can do this or
whether the capture's teleport-to-authored-coordinate drops the body onto an NPC
that a walking player would never land on. Either answer is worth having; only
one of them is a game bug.

## Defects, as the critic gave them

**Artefacts.** Untextured grey blockout slabs ARE the destination — horizon in
`10-day`, walling the mid-ground in `11`, half of `12-day`, pale ghosts at
night. `12-day`'s terrain around the gate pylon is stark white with no edge
treatment, *"an unshaded patch"*, glowing again at night. A text label floats
in mid-air in `09-day` with no signboard behind it. `04`'s rock outcrop carries
a photo-real gravel texture on visibly faceted low-poly triangles beside toon
trees. Distant tree LOD renders near-black in daylight (`02`, `04`, `05`) while
the same trees close up are bright kelly green.

**Night is a void, not a mood.** No moon disc in any of the four night frames.
Characters are lit by a different rig than the world: the trainer renders at
near-daylight brightness against pitch black, *"pasted onto black paper"*.
Measured alongside: all four night frames return sky 0.0% and horizon 0.00 —
the sky is indistinguishable from the ground, so there is no horizon at all —
and near-field luminance falls to 0.012 against 0.116–0.301 in daylight.

**Scale, against the 1.80 m ruler.** The path is 10–20 m wide, *"ten
trainer-heights… not a footpath"*, against Palworld's 3–4 m. Signposts are 4.5 m
telephone poles with the plank at the very top. Foliage is jungle-scale in a
temperate meadow — leaves the length of the trainer's torso, a 2 m fern.
*"Scale is right where props are conventional — it breaks on the authored
elements."*

**Composition.** `03-day` is *"the one composed frame in the set… it proves the
team can do it."* `05` is the opposite: props at even spacing on open grass,
*"a campfire with no camp around it, a banner and a grunt with nothing to
guard."*

## Measured, so round 2 can be compared rather than argued

Twelve day frames, `tools/frame_stats.py`: **eleven of twelve carry exactly
three hue families, and the same three every time** — blue, chartreuse, yellow.
That is the numeric form of the standing "palette incoherence" finding and the
baseline any groundcover or lighting change has to move. Full table in
`shots/corridor_pre/`.

## The split the rubric asks for

**Scene-fixable:** ground-cover density (gap 1, *"the single biggest visual gap
and it is scene-fixable, no new art required"*), flower/tuft clustering, path
width and edge, signpost scale, night ambient floor and moon disc, the character
light rig at night, the trainer-on-NPC stack, `09`'s floating label, the black
daylight LOD trees, creature placement against contrasting ground, `05`'s relay
camp, distant landmark silhouettes on `07`'s horizon.

**Needs art not in the build:** the stronghold the grey slabs stand in for, and
wild creatures with enough bespoke silhouette and colour identity to anchor a
frame the way `palworld-01`'s boss does — *"nothing photographed on this route
can currently do that job."*

## What is working, recorded because knowing this matters too

The trainer holds up and is never lost at 30% — *"this character belongs in the
world it walks through"*. The tether pylon survives shrinking with a real
silhouette. The oxblood discipline passes: the only red of that family in the
whole survey is the Team Tether banner at the relay, exactly where it belongs.
And the cyan tether-cable glow tracing the horizon at night is *"exactly 'hints
of mystery'. It is the only thing out there."*
