# Blind visual verdict — N05 world dressing (narrow round)

Sheet: `ralph/reports/N05-WORLD-DRESSING-0905/_sheet_dressing.png`
Frames: `shots/n05_before2/` (column A) and `shots/n05_after/` (column B), 1280x720.

I was told nothing about which column is which build or what differs. All coordinates below are
in the **1280x720 full-size frames**, origin top-left. Measurements were made in Python/NumPy on
the named crop; where I could not measure I say so.

Ruling only on the three points asked. One "out of scope, noticed" line at the end.

---

## 1. Fence geometry — rows 1, 2 and the zoomed pair

**Column B is better, and not marginally: it is the difference between a fence and a pile of fence
segments.** Every defect below is present in A and absent in B. I found no fence defect in B that
is not also in A.

### 1a. The run is chopped into disconnected segments (A only)

Row 2, `F-04-fence-run-behind-halda.png`, the far run behind the tournament board. Scanning the
rail band `y 250-345` column by column for fence pixels:

| x range | A | B |
|---|---|---|
| 944-953 | **completely empty, 10 px** | continuous, rails at y 300-321 |
| 1042-1058 | **completely empty, 17 px** | continuous, rails at y 300-321 |
| 1155-1159, 1173-1179 | covered | 4 px / 6 px breaks, both bush leaves in front, not real holes |

At **x 944-953, y 300-325 (A)** the rails simply stop. There is no post at the break; the top and
middle rails end with a cut end face at x≈943 and the next segment resumes at x≈955 with grass
visible straight through the gap. That is a rail ending in mid-air, and it is the answer to the
question asked.

At **x 1042-1058, y 250-345 (A)** the same thing happens with a height step: the left segment ends
on a post at x 1038 (post spans y 259-313) and the next segment restarts at x 1059 with its rails
**10 px lower** (y 310-316 against y 299-302). The two segments are not on the same line and
nothing ties them together.

Tracing the top-rail y across x 790-1280 in row 2, A has abrupt 16-18 px steps at **x=894** and
**x=953** that B does not have. A's run stair-steps down the hillside in discrete flat pieces
instead of following the slope; B's line falls smoothly.

Row 1, `F-05-halda-w08-stand.png`, far right past the big tree: in the band `y 222-285`, **A has a
17 px void at x 1189-1206** (173 of 190 columns covered); **B covers 190/190**. Same defect, other
frame: the run stops and restarts for no reason.

### 1b. Corners do not meet — two end posts with a hole between them (A only)

This is the zoomed pair at the bottom of the sheet, and it is the clearest single defect in the
round. Row 1, the junction at **x 1020-1080, y 228-290**:

- **A** puts *three* separate posts there — x 1024-1030, x 1041-1046, x 1061-1067 — and the top
  rail band (y 228-262) is **empty from x 1046 to x 1061**. Sixteen pixels of open hillside show
  through where the corner should be. The two runs also arrive at different rail heights (left
  run's mid rail y≈258 at x=1044; right run's y≈244 at x=1062) and at visibly different angles,
  so even where they overlap they read as two fences passing each other, not one fence turning.
- **B** puts **one** corner post there, x 1041-1048, top y≈232, base y≈277 in the grass. Both runs'
  rails terminate on it; the band y 228-262 is continuous across the whole span. The corner reads
  as a corner.

### 1c. A rail driven through a post and protruding into air (A only)

Row 1, the corner behind Halda's left shoulder, **post at x 524-534, y 346-434 (A)**. The eastern
run's middle rail is drawn straight through that post and protrudes about 5 px past its left face,
ending in mid-air at approximately **(519-524, 371-377)** with grass behind it. The post itself
also stands about 13 px proud of both runs' top rails (post top y≈346 in A). In **B** the same
corner is a single shared post at **x 523-535, top y≈359**, both runs' rails die on its faces, and
the protruding stub is gone.

### 1d. Floating posts and posts on slopes — no defect found in either column

I looked for this specifically and could not substantiate it in either column. On the near run in
row 2 the posts measure identically in A and B (wood extents: x 305-330 → y 486-602 in A, 490-603
in B; x 425-450 → y 450-606 in both; x 510-530 → y 425-623 in A, 423-623 in B), and each post's
base reaches below the lowest rail into the grass. In row 1 at x 855-1000 the post bases sit on the
dirt path in both columns. **No post in either column floats with ground visible beneath it**, and
posts stay vertical with their bases following the terrain on the slope. A's problem is horizontal
continuity, not vertical seating.

### 1e. Rail density

At row 1 x=1200, A has no rails at all in the upper band (the 17 px hole of 1a); B shows four rail
bands at y 236-241, 246-248, 249-251, 264-266. Across the frames B's runs read as fuller 3-rail
fences; A's read as thinner and gappier. Rail counts on the *near* run in row 2 are identical in
both (same band structure at x=200, 380, 480), so this is a far-run change only.

---

## 2. The inn's back wall — row 3

**Column A is a greybox. Not "sparse" — a greybox.** The entire back wall is one untextured cream
plaster plane; the bar is one flat cream box with no edge, moulding, front rail or top surface
detail; the room contains exactly one object, the innkeeper. There are no shelves, no bottles, no
tankards, no barrels, no stools, no sign, no lamps. Nothing.

**Column B has dressing:** four wall shelves carrying about 22 bottles, a hanging sign, a wooden
dresser at the left, three white tankards and one terracotta crock on the bar, an open barrel at
the right behind the bar end, and two stool seats cropped at the bottom corners.

So on the question "is anything present", B wins outright. On the question "does it read as a
lived-in inn", **B is not there yet**, and the specifics are:

### 2a. The sign's text plane is 1.8x the sign

Measured at y 10-30, the brown board spans **x 438-810 (372 px wide)**. The lettering, measured in
the band y 35-80, spans **x 278-950 (672 px)**. About 160 px of "ROOMS" and 140 px of "STOCK" hang
on bare plaster outside the board. The text is horizontal, correctly oriented, correct reading
order, and the on-board letters are legible — sampled letter stroke (196,186,162) against board
(202,141,70) separates cleanly by hue. The **off-board** strokes sample (212,204,177) against
plaster (232,214,163): a luminance contrast of roughly **1.2:1**, effectively invisible at any
distance. So half the sign is unreadable and the readable half is sitting on a board that is too
small for it. This reads as a bug, not a choice. The board's top edge is also cut off by the top
of the frame.

### 2b. The bottles are an array, not stock

Right lower shelf, bottle centres at **x = 895, 972, 1014, 1089, 1130** — spacings of 77, 42, 75,
41 px. A strictly periodic pair repeated at fixed pitch, mirrored on the left shelf, repeated
again on all four shelves. Two bottle shapes only (tall amber, short green), every one upright,
every one the same height, none clustered, none knocked over, no gaps, no corks, no labels, no
empty stretch of shelf. This is the classic "generator output" read from the rubric: regular
intervals and uniform prop scale. A tavern's back shelf is uneven by nature.

### 2c. Interpenetration: shelf plank through the dresser

At **(125-140, 300-312)** the lower-left wall shelf's plank end is drawn *over* the dresser's right
stile (which occupies x 93-140), while 60 px higher the dresser's cornice *occludes* the green
bottle standing on the shelf above. The two objects cannot both be in front — they occupy the same
volume. Nothing else in the frame floats, and nothing else intersects.

### 2d. No light source at all

There is no lamp, candle, lantern, sconce or hearth anywhere in B's frame. An inn interior lit
only by flat ambient is the single largest reason it reads as a shop display rather than a tavern.
(I am not judging the quality of the lighting here, only the absence of the props.)

### 2e. Other

- The four shelves cantilever off plaster with **no brackets or corbels**.
- The wall band directly behind and below the innkeeper, roughly **x 400-830, y 320-460**, is
  completely bare — no back bar, no taps, no keg rack, no hooks, no slate.
- The barrel at **x 1135-1280, y 430-480** is open-topped and you can see into it; its rim's inner
  edge is a jagged, stepped silhouette.

### 2f. Scale, with the innkeeper as the ruler

Nothing here is grossly mis-scaled. Using his head (top y≈213, ≈97 px tall at wall depth):

- The counter's rear top edge crosses him at **y=464**, level with his belt buckle — a bar at about
  1.05-1.10 m. Correct.
- Shelf bottles measure **83 px tall (y 213-296)** = 0.86 head heights ≈ 20-26 cm. Correct.
- Tankards measure **56x64 px** (left pair) and 47x57 (right, further off) — 0.77 of a bottle's
  height while standing *nearer* the camera, so under 20 cm true. Correct.
- The terracotta crock, **82x91 px**, is 1.6x the nearby tankard: a large stoneware jar, plausible,
  though nearly as wide as it is tall.
- The barrel is ≈145 px across at less than wall depth, so under ~45 cm — a small barrel, but in
  range.
- Bottles sit on their planks: bottle bases at y=296, plank top at y≈297 at x=1000. No floating.

**Verdict on row 3:** B is a large, real improvement over a literal greybox, and its object scales
are right. It is still not an inn — it is a wall of evenly-spaced bottles, a mis-fitted sign, and
an unlit room with nobody's cup half-drunk.

---

## 3. The courtyard — rows 4 and 5

**No difference between the columns on the question asked. Both are correct, and both are equally
inert.**

- **Row 4, held:** a humanoid is standing on post in **both** columns, same character, same pose,
  same place. Differencing Y-01 against Y-02 within each column isolates the figure's silhouette
  at **x ≈ 612-670, y 309-442, 133 px tall** — byte-identical bounding box in A and B.
- **Row 5, freed:** the figure is gone in **both** columns. The bench he was standing in front of
  (x 585-680, y 350-380) is revealed in both.
- **Anything else that differs between rows 4 and 5 within a column:** essentially nothing. The
  row4→row5 difference mask for each column contains only (i) the trainer's silhouette and (ii)
  the banner cloth's wave and brazier flame flicker. The crate at x 410-480, the two braziers at
  x 555-590 and x 730-780, the straw bundle at x 930-980, the wall torches and every banner are
  pixel-stable.

That is the finding, and it is the same finding for both columns: **when the garrison stands down,
the fortress does not visibly react.** The Team Tether oxblood banners still hang, the emblem still
faces the yard, the braziers still burn, nothing is furled, struck, scorched or cleared. A player
who beat this courtyard would walk back in and see one missing man. Under rubric §2, the oxblood
is still correctly reserved for Team Tether — but it is reserved for a Team Tether that is no
longer there.

---

## The two bar questions — as they apply to these three points only

### A. Do these frames read as belonging to the world in `tetherbound-meadows-keyart.png`?

**Column A: no.** Three reasons, all on the listed points. (1) The key art's fences — the
foreground run in the top-left Meadows panel and the paddock in the STARTING SETTLEMENT panel —
are unbroken lines that follow the ground and turn at corners; A's boundary run has a 10 px hole
at row 2 (944-953), a 17 px hole at row 2 (1042-1058), a 17 px hole at row 1 (1189-1206) and a
16 px hole at the row 1 corner (1046-1061), with a rail protruding into air at (519, 374). A fence
you can see through in four places is not a built object. (2) The key art's settlement panel is
warm, occupied and full of small human traces; A's inn is a blank plaster plane and a cream box.
(3) The stronghold panel shows a fortress that visibly *reads* as occupied; A's courtyard reads the
same occupied way after it has been taken.

**Column B: no, but only just, and for two of the three.** The fence now belongs — continuous runs,
shared corner posts, rails that die on wood, a line that follows the slope; on that point alone I
would say yes. The inn does not: the key art's world has firelight and human mess, and B's inn has
neither a light source nor a single object out of alignment. The courtyard does not, for the same
reason as A.

### B. Shown these frames beside `palworld-0*.jpg`, would someone say these are trying to be the same kind of game?

**Column A: no.** Palworld's world is dense with placed, functional-looking objects and its
structures hold together at close range. A's inn is an empty box, and A's fence falls apart the
moment you look at a corner.

**Column B: no — carried by the fence, sunk by the inn and the courtyard.** B's fence would pass
this comparison unremarked. B's inn would not: Palworld's built interiors carry workbenches,
chests, beds, crates and lights, and B's back wall is a repeating bottle array under a sign whose
text is nearly twice as wide as the sign. B's courtyard would not: Palworld bases and dungeons
visibly change state, and B's does not change at all.

### Which gaps are fixable in the scene, and which need art that is not in the build

**Fixable by changing the scene — this is the work:**
- Row 3: shrink the sign's text to fit the board (or widen the board), and raise the contrast of
  the lettering; the off-board strokes are at 1.2:1 against plaster.
- Row 3: break the bottle periodicity — vary pitch, leave empty shelf, lay one on its side, vary
  heights. Currently 77/42/75/41 px repeating.
- Row 3: pull the dresser clear of the wall shelf so the plank end at (125-140, 300-312) stops
  short of it instead of passing through it.
- Row 3: place a lamp or candle if one exists in the prop family, and put *something* on the bare
  wall band at x 400-830, y 320-460.
- Rows 4/5: on `legendary_freed`, change something. Furl or drop one banner, kill one brazier,
  open the gate — anything that makes the state visible. This is placement, not new art.
- Rows 1/2: nothing. B's fence is done for the defects in scope.

**Needs art that is not in the build:**
- An inn that reads lived-in wants props this frame does not have: a hearth or fire, taps or a
  back bar, plates, food, a spill, a stack of used tankards, bottles with labels and varied
  silhouettes, and a barrel modelled to be seen into (the current one's rim interior is a jagged
  stepped silhouette at x 1135-1280).
- A "stood-down" dressing set for the courtyard — a torn or furled banner variant, a doused
  brazier, cleared weapon racks — does not exist in these frames and cannot be faked by moving
  what is there.

---

*Out of scope, noticed (not judged):* column B's right-hand courtyard banner carries a large black
quad across the top of its emblem at roughly (895-985, 98-135) that column A does not (2410 dark
pixels against A's 882 in the same window), and the courtyard crossbeam at x 810-1150, y 60-200 sits
differently between the columns; row 3's shelf and bottle shadows resolve as blocky stepped
rectangles, which I take to be the software-GL shadow map and not a scene defect; grass, trees,
terrain, the trainer's design and texture resolution are unchanged between columns and were not
assessed.
