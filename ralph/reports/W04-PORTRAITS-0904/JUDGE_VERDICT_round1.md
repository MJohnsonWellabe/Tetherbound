# Portrait / Dialogue Visual Judge — W04-PORTRAITS-0904

Judged blind, pixels only: the two in-game frames, the portrait contact sheet,
and trainer.png / grandpa.png as the style bar.

## Say this first: the contact sheet does not show what it claims to

`_sheet_portraits.png` is 1536×256 px — one row of six 256 px cells, not the
34-plate, six-per-row sheet the brief describes. Of those six cells, only
four hold an image; the other two (cols 5–6) are flat empty grey. Worse,
columns 1–3 are the *same* render of the same girl character — a pixel diff
between col 1 and col 2 averages under 1/255 with a max of 45 in one small
region, i.e. visually identical. So the "contact sheet of 34 portraits" in
front of me actually shows **two distinct characters**. Whatever the other
~30 roster portraits look like cannot be judged from this file, and that gap
is itself the headline finding, not a footnote.

## A. Does the dialogue portrait match the NPC standing in the scene?

**Frame 1 (Halda):** Yes, this one holds up well. The standing character
(green hooded top with a gold collar emblem, brown bob with a straight
side-swept fringe, light skin) matches the portrait's hair, hood colour and
emblem. Both also carry the same pale jagged mark on the right cheek (see
below) — consistent, if not flattering, between the two renders. This is a
genuine same-character match, not a reused generic face.

**Frame 2 (Oskar):** Also a good match. Portrait and standing NPC share the
same side-parted brown bowl cut, neutral/flat brow, and the same brown vest
over a cream buttoned shirt. Nothing here reads as the wrong person.

Neither frame shows the player's own portrait or a mismatched stranger. On
the specific question asked, both frames pass.

## B. Do these match trainer.png / grandpa.png well enough to share a UI?

They do **not**, and it's a style-family problem more than a polish problem.

1. **Rendering style split (High).** Trainer/grandpa are soft-shaded,
   semi-realistic, painterly — think Pixar-adjacent: gentle gradient
   shading, textured individual hair strands, naturalistic iris/eyebrow
   proportions. Halda (contact-sheet cols 1–3, and her in-game portrait) is
   flat cel-shaded with a single oversized anime-style eye, thick black
   eyebrow, and hair rendered as glossy hard-edged chunks with banded
   specular highlights. Put next to trainer.png it reads as a different game.
   Oskar (col 4) is closer to the trainer/grandpa painterly treatment — so
   the roster isn't even internally consistent with itself, let alone with
   the two references.
2. **Head angle/pose (Medium-High).** Trainer and grandpa are both near-frontal,
   both eyes visible, looking at the viewer. Halda and Oskar are both
   cropped at a near-full side profile — only one eye rendered, nose to the
   frame edge. Portraits that never make eye contact with the player will
   read as a different asset pass the moment they sit next to trainer.png.
3. **Background matte (Medium).** trainer.png/grandpa.png sample as opaque
   near-white (RGB ~242,242,242) at their corners. The contact-sheet cells —
   populated and empty alike — sample as opaque slate grey (~107,112,119).
   In the actual dialogue box the portraits show a near-black corner instead
   (matching the box, so likely alpha or a dark composite), but if the
   underlying plate file truly bakes in that grey rather than transparency,
   it will show as a mismatched matte behind the head the moment art
   direction changes the dialogue skin.
4. **Crop scale (Low / non-issue).** Measured subject bounding boxes are
   actually comparable across all four references (roughly full frame height,
   165–210 px of the 256 px width) — head size in frame is not the problem
   here, angle and shading style are.
5. **Edge/AA quality (Low / non-issue).** Hair-silhouette antialiasing on the
   sheet portraits is comparably soft to trainer.png's; this isn't a visible
   tell on its own.

## C. Contact sheet — indistinguishable cells and visible defects

Row 1 is the only row that exists.

- **Cols 1, 2, 3:** effectively indistinguishable from one another — same
  character, same pose, same expression, no meaningful variant between them.
  If these were meant to be different emotion states or different
  characters, none of that reads.
- **Col 4:** distinguishable from 1–3 (different character, different
  render treatment), no obvious artefact.
- **Cols 5, 6:** blank grey — no portrait rendered at all.
- **Defect, cols 1–3:** a hard-edged, jagged pale zigzag mark sits on the
  character's right cheek, and a matching set of thin dark scribble lines
  sits on her neck. Both have sharp aliased edges that don't belong to the
  otherwise smooth cel-shading — this reads as a shading/normal-map or UV
  seam bug, not an intended scar or tattoo, and it is not cosmetic once
  spotted. It also appears identically in her in-game dialogue portrait
  (frame 1), so it's a persistent asset defect, not a one-off render glitch.

## D. Other things a player would notice in the two frames, ranked

1. **Speaking character loses the frame to the player model.** In both
   shots the tall foreground trainer dominates the composition while the
   actual speaker (Halda, Oskar) is smaller, set back, and in frame 1
   partly cut by a fence rail and a barrel in the foreground. The person
   the player is supposedly listening to is the hardest thing to look at.
2. **Trainer isn't looking at who he's talking to.** In both frames the
   player character's head/gaze points forward-right, away from the NPC
   standing behind/beside him. It reads as the player character being
   distracted mid-conversation rather than engaged.
3. **Tree canopy crowds the HUD in frame 2.** The large tree at top-left
   has leaf geometry running right up to and behind the minimap and the
   "MAIN STORY" quest box at top-right, making the HUD look like it's
   growing out of foliage rather than sitting in clean sky.
4. **Minor: ground grass reads as evenly scattered tufts** rather than
   naturalistic clumping — noticeable but secondary to the portrait/NPC
   issues above.

## Bottom line

Where the two frames can be judged (A), the character-to-portrait identity
holds up. Where the brief asked for roster-wide judgment (B/C), the evidence
that exists says the new portraits are a different, inconsistent style
family from trainer.png/grandpa.png, one of the two delivered characters
carries a visible rendering defect that reaches the shipped dialogue box,
and the contact sheet itself is not the 34-plate survey it claims to be —
that last point should be fixed before this line of work is judged again.
