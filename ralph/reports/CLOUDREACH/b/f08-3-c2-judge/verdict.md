BAR_A: FAIL  BAR_B: FAIL  READ: FAIL

# F08#3 High Perches camera, round c2: code-blind visual verdict

Frames: shots/locations/cloudreach-high-perches-c2/*.png (12, day+night pairs).
References viewed: tetherbound-meadows-keyart.png, cloudreach-sky-aviary-stronghold-board.png,
cloudreach-cliffs-creature-roster-board.png, palworld-01/02/04.
Note: the docs/reference key art and boards are tracked in git but missing from the
/home/user/Tetherbound working tree. I judged against identical copies in the session scratchpad
(`scratchpad/base/docs/reference/`).

## 1. Bar A (identity): FAIL
- The Cloudreach board promises a pale-stone aviary with a glass and gold dome, blue banners,
  turrets, arched bridges, waterfalls and floating islands with lush trees. The perch in every frame
  is instead five plain grey cylinders with plank caps, one rough stone arch and a flat grass disc
  (see court-high-oblique-day, southeast-glide-approach-day). Nothing in the frames shows the
  aviary's architecture: no dome, no banners, no gold, no waterfalls.
- The clouds are stacked flat white low-poly slabs and pill shapes. They read as ice or styrofoam,
  not the soft volumetric cloud sea on the board (west-glide-high-day left and right,
  court-high-oblique-day left). Cliff faces carry blotchy camouflage-like shading
  (glide-approach-day right half).
- The key art is lush, painterly and dense with foliage. These frames are sparse, with a few
  lollipop trees on a flat mesa (glide-approach-day top-left).
- What matches: the hawk carrier (rig-fly-departure-day) and the trainer model are on-bar and would
  fit the roster board's detailed, readable-creature style. The environment around them does not
  match that bar.

## 2. Bar B (genre/finish): FAIL
- Palworld frames have dense grass and foliage, atmospheric depth, soft lighting and a HUD. Here the
  finish is prototype-grade: primitive cylinders, a hard-edged grass disc with no transition into
  the rock (court-high-oblique-day), faceted flat clouds, and large empty fog planes
  (southeast-glide-approach-day background).
- The carrier is the one asset near that finish, and it clashes with the blockout world around it.
  At ordinary gameplay distance this reads as a greybox level holding one finished creature, not a
  polished creature-adventure game.

## 3. Criterion read (F08#3 "correct high-perch camera"): FAIL
- **Height: partially fixed, still not convincing.** southeast-glide-approach-day/night now reads
  as high: the perch top sits above the surrounding cliff tops, with cloud slabs below. In
  glide-approach-day/night, west-glide-high-day/night, court-high-oblique and rig-fly-arrival,
  though, a large grassy mesa sits at about the same elevation as the perch top, right beside it
  (left in glide-approach and arrival, behind in west-glide and court-high-oblique). That
  flattens the "high above the land" read. No frame shows the column's base, the ground far below or
  a clear drop to the cloud floor. The column simply exits the bottom of the frame, so the depth is
  implied, not shown.
- **Rim crowding: still present in 4 of 6 pairs.** Pillars touch or are cut by the top edge in:
  - glide-approach-day/night (tallest column cut at y=0)
  - court-high-oblique-day/night (two columns cut at the top; the high oblique also sits so close
    that the aerie fills the centre third and the column fills the lower frame)
  - rig-fly-arrival-day/night (tallest column cut at the top)
  - rig-fly-departure-day/night (column cut at the top)

  west-glide-high sits within about 20px of the top edge. Only southeast-glide-approach has clean
  headroom.
- **Landing/departure legibility: mixed.**
  - rig-fly-departure-day/night reads well: the hawk faces camera with wings spread on the aerie,
    and the trainer is in the foreground with arms raised. However, the trainer hangs in mid-air in
    front of the rock face, detached from both carrier and ground, so it is unclear whether they are
    boarding, jumping or being lifted.
  - rig-fly-arrival-day/night shows the carrier from directly behind and above as a flattened
    brown-and-tan shape. The underside membranes read like a pelt or a manta rather than a bird.
    The trainer dangles beneath, readable but small, and the perch landing target is hidden behind
    the carrier.
- **Day/night: pass on this point.** Night frames are legible. Moon-blue ambient, warm lamp pools
  on the court disc (court-high-oblique-night) and the silhouettes hold, though the uniform blue
  wash flattens the rock and cloud separation further.

## Worst 3 defects
1. **rig-fly-arrival-day** (and night): the carrier is framed from behind and above and reads as a
   flat, misshapen hide. The underside and tail membranes look like a pelt, the head is barely
   visible, and the carrier blocks the landing target. The arrival moment is the weakest read in
   the set.
2. **court-high-oblique-day** (and night): pillars are cut by the top rim, and the adjacent mesa,
   at equal height behind, kills the sense of height. This is the same "rim crowding / no height"
   failure the previous round was failed for.
3. **glide-approach-day** (also west-glide-high-day): flat faceted cloud slabs, blotchy cliff
   shading and bare cylinder architecture. It reads as greybox, far from the aviary board. The
   tallest pillar is also clipped at the top edge.
