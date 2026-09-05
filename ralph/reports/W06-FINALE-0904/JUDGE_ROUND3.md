# Blind visual judge — round 3 (2026-09-05), and the ceiling

A third code-blind sub-agent (opus), fresh context, told nothing about rounds 1 and 2,
what changed, which column was which, or what the lane hoped it would say. Given only
`_sheet_round3.png` (round-2 chamber frames as A, round-3 as B), the full-resolution
frames, `docs/reference/` and the visual-judge skill.

**The change it was judging has been reverted** (`f28fc030`) on the strength of this
verdict. The shipped state of this branch is the round-2 state — the frames this verdict
calls "A". Verdict committed verbatim below.

---

## 1. What is in each frame

**Row 1 (head-on).** A tall, symmetrical structure of carved stone filling a stone-walled chamber. It has a broad tiered base, a wide central staircase leading up to it, flanking spires and buttresses, and an arch at its top holding a mass of pale green crystal facets. Standing in the arch, centred, is a dark quadruped with wide branching antlers, black body, gold banding on its legs and flanks. Two white hexagonal outline rings float around it — one at antler height, one at chest height. Long thin pale-cyan bars cross the frame at the upper left, upper right and lower left. Everything except the creature's gold is the same desaturated teal-green.

**Row 2 (three-quarter from a corner).** The same structure seen from outside and above, its whole silhouette visible against the chamber's back and side walls. The creature is a small dark shape deep inside the arch. The two white rings are now near edge-on and read as two straight white horizontal bars laid across the creature. Four more cyan bars cross the room, two of them running over the floor in front of and behind the base.

**What differs.** In both rows, A and B are pixel-identical everywhere except one localised region above and around the creature's head (measured: a 347×244 patch in Row 1, a 165×257 patch in Row 2). B adds a solid, opaque, flat-white cone hanging from the underside of the crystal down toward the creature — wide at the top, tapering downward, with a hard silhouette and a flat cut-off bottom edge. In Row 1's B it ends over the creature's face; in Row 2's B it terminates in mid-air above the antlers without touching anything. It fully occludes the crystal behind it. Nothing else changes: same camera, same lighting, same creature pose, same rings, same bars.

## 2. The premise question

**A: no.** A reads as a creature standing in a niche. The composition is a shrine — a symmetrical façade, a central stair leading up to a raised alcove, an ornamented arch, a figure framed in it. That is the visual grammar of an altar, and every element reinforces it rather than fighting it. Nothing connects the creature to the structure: no cable, no clamp, no conduit, no contact of any kind. The two white rings float clear of the body — they do not touch it, tighten on it, or deform it, and there is nothing at their ends. The creature's pose is a neutral four-square idle: head level, legs straight, no strain, no sag, no drooping. The green crystal above it is the only element that could be read as an energy store, and there is no path between it and the creature. Nothing in A says drain, direction, or captivity.

**B: no, and the addition does not carry the premise.** The cone is the only new information and it argues against the intended reading three ways. First, it is opaque and flat, so it reads as a solid object hanging in the arch, not as energy. Second, its taper points *down at* the creature — the shape language of a spotlight or a funnel pouring into something, which says the machine is feeding or illuminating the creature, the opposite of extraction. Third, in Row 2 it stops short in empty air with a flat cut and never reaches the creature, so it is not even connected to the thing it is supposed to be draining. The creature is identical to A: same pose, same alertness, same absence of contact. B is still a creature standing in a niche, now with a white cone hanging over it.

The deeper problem is that neither frame reads as machinery. The structure is uniformly carved stone with gothic ornament, finials, buttresses and tracery. There is no mechanical vocabulary anywhere in it — no pipes, cabling, coils, tanks, bolts, gauges, housings, seams between old and new, or anything that looks bolted on to something that was there first. "Captured and retrofitted" requires two visibly different material languages in one object; there is exactly one here. Without that, "the machine" is not present in the frame for the premise to be about.

## 3. Artefacts, debug draws, and mistakes

- **The white cone (B, both rows).** An untextured, unlit, fully opaque white cone with a hard rim and a flat truncated bottom. No falloff, no gradient, no additive blend, no soft edge, no volume. This is what an unassigned material looks like. Both B frames.
- **The two hexagonal rings (A and B, both rows).** Pure-white, uniform-width, hard-cornered line loops with no glow, no core-to-edge falloff, and no interaction with anything they overlap. Seen edge-on in Row 2 they collapse into two straight white bars crossing the creature. These read as collision-shape or gizmo outlines, not as authored VFX.
- **The cyan bars (all four frames).** Flat, constant-width, hard-edged strips with no falloff along their length, no dust, no bloom, and no visible source or termination. In Row 2 two of them lie across the floor and clip past the machine's base without any interaction; in Row 1 one crosses the lower-left staircase. They read as debug lines.
- **The chamber walls (Row 2, most visible; the left wall of Row 1).** Built from many overlapping thin slabs at differing tile scales and offsets, with hard vertical seams where one slab crosses another and a black-red vertical gap on the left wall showing through the construction. The cobble texture is also mis-scaled — individual stones read hand-sized on a wall many metres tall.
- **The staircase (Row 1).** The treads are painted into a smooth sloped surface rather than being geometry, and the baked stripe aliases badly along the whole run.
- **No contact shadow anywhere.** The machine's base meets the floor with no darkening, no occlusion, no shadow; the creature has none either. Nothing in either frame is grounded.

## 4. What is still wrong, worst first

1. **The machine is not machinery.** It is an ornate stone shrine, and everything about the composition — symmetry, central stair, arch, framed figure — pushes "altar" rather than "apparatus". No VFX pass fixes this; it needs a second material and detail language physically imposed on the structure. Both rows, A and B.
2. **The creature is not visibly a victim.** Neutral standing idle, no strain, no restraint touching it, no wound, no depletion, no direction of flow. Both rows, A and B.
3. **The creature is barely readable.** A dark body with dim gold banding, set inside the darkest recess of the frame, surrounded on all sides by the machine's high-frequency teal ornament. At contact-sheet scale in Row 2 you cannot tell there is a creature there at all. The single most important object in the game's final location loses its silhouette to its own set.
4. **Three separate white/cyan elements all read as debug draws** — the rings, the bars, and in B the cone. Together they make the frame look mid-development rather than authored. Both rows.
5. **The B cone actively works against the reading.** Opaque, downward-tapering, disconnected. It states "light is being projected onto this creature."
6. **Chamber construction is exposed.** Overlapping wall slabs, seams, a black gap, mis-scaled cobble, texture-painted stairs. Row 2 worst.
7. **No value range and no Team Tether colour.** Both rows sit in one narrow teal-green mid-tone from wall to machine to floor; the only break is the creature's gold. The project's own board reserves oxblood red for Team Tether and there is none anywhere in Team Tether's final chamber, so the location does not identify whose it is.
8. **Scale is uncheckable.** No human is in frame, and the one apparent ruler — the staircase — is a texture, not steps. Relative scale between creature and structure therefore cannot be verified from these frames, and the frames should include the 1.80 m trainer if that check matters here.

## Verdict

Neither frame delivers the premise. Both read as a creature standing in a lit alcove of a stone shrine, because that is literally what has been built: a symmetrical carved-stone façade with a central stair and an arched niche, containing an unrestrained, unstrained animal that nothing in the scene touches. The intended statement — captured machinery running on a living power source — requires a machine that looks retrofitted onto something older, a physical connection between apparatus and creature, and a creature whose body shows the cost. None of the three is present in A, and B adds only an opaque untextured cone that points the wrong way and, in the corner view, never reaches the creature at all. The change between the two rows is confined to a small patch above the creature's head; everything else is identical, so B is A with one placeholder-looking primitive added. On top of the premise failure, the frames carry several things that read as unfinished build rather than art: white gizmo-like rings, flat cyan debug bars clipping through floor and geometry, exposed overlapping wall slabs with a black gap, texture-painted stairs, and no contact shadows anywhere. This is the last location in the game and it is not yet reading as an authored scene, let alone as the scene it is meant to be.

---

## The ceiling, recorded

Three rounds. What measured, and what did not:

| Round | Change | Measured effect | Judge |
|---|---|---|---|
| 1 | the creature staged inside the machine's measured cage void; the floor ring replaced by restraint rings on the body | 20.7% of the old floor-ring crop changed; 9.8% of the arch-void crop | **"Row 1 B and Row 2 B read as inside the machine"**, staging "sound" |
| 2 | ring emission 2.2 → 1.15; withdrawal widened to the siphons and pipe runs | ring hue separation (G+B)/2−R **+6 → +35**; withdrawal 11 → **14** lights out, 2 → **13** surfaces unlit | rings "stop being an off-palette pure-white foreign object"; gain "small and cosmetic" |
| 3 | a draw column from the creature to the crown | column hue separation **+36** (on palette) | **worse than nothing** — reverted |

**The ceiling is the asset, and it is outside this lane.** Every remaining finding that
would move the reveal is geometry the build does not have: the machine needs a socket,
clamp or cable that the creature physically sits in, and a second material language that
says "bolted on by Team Tether". The installed hero mesh has neither — D49 generated it
*without its prisoner* on purpose (the licence forbade the creature in the reference
crops), so its cage volume is a bare arch with nothing in it to attach to. Primitives
placed in that arch by this lane read as gizmos, and the third round proved that adding
more of them makes the frame worse rather than better. `stronghold.gd` and
`assets/environment/team_tether/tether_machine.glb` own the rest, and both are outside
this lane's ownership list.
