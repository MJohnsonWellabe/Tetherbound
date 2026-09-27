# F03#0 lure judge, round 10 (code-blind; juno, final data)

Judge input: the 5 frames in `r10-judge/` (juno_01 to juno_05) plus the criterion (ACCEPTANCE F03 lure part, "a player can see the lure") and the ruling (visible from the road, then readable on approach). I did not open any code or data. Positions are in 1280x720 pixels.

| activity | visible from road | readable on approach | overall |
|---|---|---|---|
| juno (Tether patrol holding a Meadowhart, signal smoke) | FAIL (marginal) | PASS (marginal) | FAIL |

## Evidence

**Visible from road: FAIL (marginal).**
- Frame 01 (160 m, no HUD, looking along the road): the smoke passes on its own. It is a dark, opaque column about 40 x 95 px at x 350-390, y 258-352, set against pale mountains and haze. It sits about 25% in from the left edge, off the road axis but clearly in view. It is the only dark vertical shape on the horizon, so a player would notice it. Nothing else from the camp shows: no oxblood banner, no camp and no Meadowhart. The tan animals near x 500-580 look like wild creatures, not part of the lure.
- Frame 02 (first on-screen frame on the real walk, about 160 m, gameplay camera): this is the frame that decides the verdict, and the lure fails here. The smoke is a soft grey-brown puff, only about 30 x 40 px, at x 843-873, y 130-170. It has low contrast against a grey-blue sky. Its lower half sits right behind the head of the companion (Tup), who walks at the player's right, and it is right next to the MAIN STORY panel. It looks like haze or a smudge, not a column. A player walking with no deliberate look-around could easily miss it. It is on screen, which is why this is marginal and not a clear fail. But frame 01's strong read does not survive into the actual walking view: the column is about 3x smaller, much softer and partly hidden.

**Readable on approach: PASS (marginal).**
- Frame 03 (first readable): the smoke column now fills the top centre (about x 570-630, from the top edge down to y 150). An oxblood banner on a white gantry is at x 270-340, y 105-190, and more small oxblood standards are near x 570 and x 730. A deer silhouette with antlers, clearly the Meadowhart, stands on the ridge at x 655-705, y 95-150. Together, smoke, red standards and a big deer read as "a Tether camp with a creature". Weaknesses: a wild Burrowback and the companion fill the foreground, the team panel covers the left banner, and night is falling.
- Frame 04 (about 30 m): the same read, less cluttered. There is a banner at left (x 90-200), the Meadowhart on the ridge (about 45 x 65 px, x 660-705), a smoke column above the camp and small dark figures near x 640, y 160.
- Frame 05 (prompt): two oxblood banners on gantries flank a campfire with a column rising from it. A dark-clad grunt stands in front of the player, crates sit by the fire and the Meadowhart is large at right. The prompt "Challenge Tether Patrol" confirms who is there.
- Marginal notes: nothing in the image shows that the Meadowhart is *stolen*, such as a tether, pen or restraint. At the prompt it stands beside the player like a companion. The grunts are black silhouettes at night, so their team colour does not read; the banners carry all of the Team Tether identity.

## Single most important fix

Make the signal smoke read in the **gameplay camera** at 160 m the way it does in frame 01. It should be a tall, dark, opaque column that rises well above the horizon into open sky, clear of the companion's head and shoulders, instead of a short, soft grey puff. Raising its height and opacity/darkness enough to clear the right-side companion silhouette is the one change that would turn frame 02 into a pass.
