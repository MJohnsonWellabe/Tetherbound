# Blind visual verdict — signpost and bridge A/B sheets

Run by lane W24-LANDING at landing time, not by W22. The lane committed both contact
sheets and its `JUDGE_PROMPT.md` but never the verdict, leaving `__W22_VERDICT_BLOCK__` in
its report; the owner directive of 2026-09-05 02:24 UTC asks the landing lane to run one
blind round for visual work no lane already has a verdict on, so this is that round. No new
render was made — the sheets existed.

**Method.** A code-blind sub-agent (opus) was given only the visual-judge skill,
`docs/reference/`, board 18 (`docs/art/reference/18_Signpost_Bridge_Modular_Props.png`) and
the two sheets, and was asked the lane's own four questions from `JUDGE_PROMPT.md`. It was
told the columns are labelled A and B, that it was **not** told which column was the newer
work, and explicitly that it must not assume either column is the improvement. It was
instructed not to read any source, report or anything else under `ralph/`.

**It identified B as the finished pass unprompted**, which is the lane's after column. That
is worth stating: the improvement is visible to someone who was not told where to look.

## The call

> **Not shippable for a first playable — but the remaining work is scene and material work,
> not new art.**

Split three ways, in its words:

- **Bridge deck and rail (B): ship it** once the value fixes below land. "The silhouette,
  the plank orientation and the deck colour are already on board 18."
- **Signpost (B): do not ship.** "It is the right model and it fails its only job in every
  gameplay frame. Until a player can read a destination from the path, this prop is
  decoration."
- **Checkpoint dressing (B): do not ship.** "Texture the barricades, put them across the
  road, and put the faction's red on the guard. Right now the strongest signal of occupation
  in the frame is the piece of geometry that looks least finished."

## Answers to the lane's four questions

**1. Signpost, which is closer to board 18's "Directional (Multi)", and is the text legible?**
B, decisively, in the studio rows: brown post and arms with the chevron cut into the plank,
cream lettering with a dark edge, pointed finial, collar rings, iron mounts — B has all of
them, A none. A also carries a geometry defect: its arrowhead is a separate flat lozenge
(~90×90 px) that does not join its plank and reads as a card pinned in mid-air. Colour: A's
board face is a flat `#ffdd9c`, over half the sampled area in two shades, essentially
unshaded; board 18's wood is `#875e42` / `#dec19e` with cream reserved for lettering. B's
`#b67c55` is in the right family, lighter and pinker than the reference.

Legibility splits by distance. **Studio rows: yes in both** — glyph bands 38–60 px, A about
13:1, B 3.0:1 against the lit half of the board and 11.6:1 against its dark band. **In-world
rows: no in either** — at `south-bridge-trailhead` the glyph band is 7–10 px with a cap
height of 5–7 px, text-to-board contrast 2.8:1 in A and about 1.3:1 in B. A is a smudge you
can tell is writing; B is invisible. Both columns also clip the last character
("Relay Statio") because the label runs under the post.

**2. Bridge deck, which is closer to "Bridge Plank & Rail"?** B, on four counts: transverse
planking matching the panel's two painted illustrations (the judge notes honestly that the
panel's own orthographic implies lengthwise, so the board is not self-consistent, and says
why it weighted the illustrations); a rope catenary rather than A's two-bar timber farm
fence, where the module is literally named "Rope Rail"; deck colour `(127, 90, 61)` against
the reference swatch `#7f5b44 = (127, 91, 68)`, a near-exact match, where A is more orange;
and readability, where B's dark-post / pale-rope rhythm reads as a rope bridge at thumbnail
scale while A collapses into one uniform value.

**3. Does the crossing read as HELD from the approach?** **A: no**, in every approach row —
gate, blue banners, lanterns, nothing on the road, "an unattended civic gate in an empty
field". **B: yes** at `bridge-approach-played` and `bridge-checkpoint-shoulder` (red banners
at `#90392b` against board 18's `#993633`, a guard at the gate mouth, held cargo, X-frame
barricades; the dressing changes 22.1 % of the frame's pixels), **weakly** at
`bridge-deck-far-side` where the tower stonework occludes the red and the blue dominates,
and **not at all** at `place5-bridge-approach`, which differs by 2.5 % of pixels with the
gate cluster about 2 % of frame width.

**4. What is still wrong in B, worst first** (condensed; the full ranking is in the round's
own text): the signpost fails to read as a signpost from any in-world viewpoint; the
untextured barricades carry the entire "held" read and do not block the road; the bridge's
value structure is stretched past the reference at both ends (posts 8× darker than the deck
where the board's spread is 3.4×, footings 5× brighter where the board's stone sits at deck
value); the rope is wound like a bollard fender and is the brightest thing in frame; deck
planks have no tone variation and stipple-dotted joints; posts are bulky and closely spaced;
the guard wears none of the faction's red and stands side-on; an arm bevel band eats the
letterforms; cream text at 3.0:1 is below the 4.5:1 threshold; placeholder white cubes at
the signpost base; mirrored text on rear-facing arms; three unrelated stone families at one
abutment.

## A finding that is not this lane's

The judge flags `place5-bridge-approach` as shot "at about knee height with a heavy
depth-of-field blur, and over half the frame is out-of-focus dirt", and says to reshoot it
at eye height before treating it as evidence either way.

**W05-TREELINE's independent judge flagged the same stand for the same reason**, on a
different lane, from different frames: `place2-the-rise` and `place5-bridge-approach` shot
from a camera at roughly 1.05 m rather than the game's ~2.8 m third-person rig, with no
player figure in shot. Two blind judges, two lanes, one broken capture viewpoint. That is a
defect in the capture tooling's stand definitions, not in either lane's art, and it is worth
fixing once rather than working around twice. Recorded here for the coordinator; it belongs
to whoever owns `tools/_capture_band1_places.gd`'s viewpoint list.

The judge also notes both sheets' studio rows have no figure in frame, so board 18's 2–2.5 m
signpost spec and 1–1.2 m rail height could not be verified: "Put the 1.80 m trainer into the
turntable shots and both become checkable in one pass."
