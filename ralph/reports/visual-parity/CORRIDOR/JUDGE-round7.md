# Corridor Round 7 — Visual Judge

Blind review of five re-rendered corridor stations against round 6 and against
`docs/reference/tetherbound-meadows-keyart.png`, `site/img/page-board.jpg`, and
the Palworld references in `docs/reference/`. I did not read code, config, or
any report describing what changed; findings below come only from the pixels
in `round6/`, `round7/`, `_sheet_r6_vs_r7.png`, and a pixel-difference pass
between the two rounds (used only to locate where content actually moved, not
to read intent).

## Per-station verdicts

### 07 — band2-mid-day: **FAIL (no visible fix)**
Claim to check: does NEW show a tree copse framing the path that PREVIOUS
lacked? It does not, because PREVIOUS already has it. `round6/07-band2-mid-day.png`
and `round7/07-band2-mid-day.png` show the identical composition: a six-tree
copse upper-left, the same boulder/tent-shaped rock and two sheep at far
right, the same sky-to-ground ratio (sky occupies roughly the top 55% of the
frame). A pixel diff between the two files confirms the tree copse region is
essentially unchanged (near-zero difference) while the only measurable
differences are cloud shape and grass-blade jitter consistent with
frame-to-frame animation noise, not a scene edit. As a travel-view
composition it is adequate but thin: foreground interest is a few scattered
wildflowers, the mid-ground path is empty, and the framing device is a
background-left tree cluster rather than true foreground framing — the same
read as round 6, because it is the same render.

### 08 — band2-far-day: **PARTIAL**
Claim to check: are both signposts fully in frame in NEW where PREVIOUS
clipped one? I could not confirm the premise: in `round6/08-band2-far-day.png`
neither signpost touches a frame edge — the left post sits at roughly x=330 of
1280 with clear grass to its left, and the right post at roughly x=830 is
also fully inboard. Round 7 does show a real change (largest pixel diff of
the five stations, mean AE ~101): the camera has been pulled back/panned,
moving the left signpost from x≈330 to x≈230 and revealing more foreground
dirt path. Both posts remain fully in frame in round 7 too, so the specific
regression claimed for round 6 isn't visible in this pair, but the reframing
itself is not a regression.
Text legibility: the left sign reads approximately **"[B]arren Undertrail"**
at full resolution — legible, though the post itself passes directly in
front of the first 1–2 letters in both rounds (pre-existing occlusion, not
introduced by round 7, not fixed by it either). The right sign
("...ne Gate Spoke[n]" or similar) is **not reliably legible** — at native
resolution the lettering is a handful of dark pixels smeared by the sign
texture's low resolution; I can make out shapes but not confirm words.

### 10 — relay-approach-day: **PASS on content, but unchanged from round 6**
A red Team Tether banner is clearly visible through a gap in the treeline,
roughly centre-frame (x≈650–730 of 1280, y≈390–425), with what reads as an
armored figure standing beside it and a crate at its base — a real glimpse of
the relay presence past the trees. However this is identically present in
`round6/10-relay-approach-day.png` — same banner, same position, same figure,
same campfire and tent on the left. Pixel diff shows no structural change,
only cloud/grass noise. So station 10 already met this bar in round 6; round
7 did not regress it, but it isn't evidence of a round-7 fix either.

### 13 — band4-entry-bend-day: **PARTIAL**
Right side of frame is better but not "filled." Round 6 already had a small
tree cluster and two boulder-like shapes around x=700–950; round 7 adds two
more trees in that same mid-right cluster (visible in the diff heatmap as the
only bright region of the frame, confirming a real edit here — the one
station-13 change I can attribute with confidence). But the outer right
quarter of the frame, roughly x=1050–1280, remains empty rolling grass and
flat horizon in both rounds — no trees, rocks, or other mass reach the actual
right edge. So: improved density in the right-of-centre cluster, yes; right
edge of frame filled, no.

### 14 — ridge-camp-approach-day: **FAIL — NOT VISIBLE**
No tent, fire, crates, or log seats are visible anywhere in
`round7/14-ridge-camp-approach-day.png`, and the frame is pixel-for-pixel
consistent with round 6 in this respect (diff is grass/cloud noise only).
What is actually in frame: the player character; an NPC (bearded man in dark
purple/leather armor, hand on hip, standing to the left of a signpost); a
wooden signpost reading "...atchtower Spur" ("Watchtower Spur"); a dark
low lump partially behind the NPC's legs that could be a rock or crate but
reads ambiguously, not as camp furniture; a dense treeline filling the right
third of the frame; and two or three pale rounded shapes on the far horizon
left (rocks or distant sheep, too small/indistinct to identify). No fire
glow, no tent silhouette, no seating is present. If a camp was added for
round 7, it is not visible in this camera stand.

## Regression sweep (round 6 → round 7, all five stations)

None observed that make a frame worse than round 6. Specifically checked and
clear: no new clipping, no floating props, no popping/LOD seams, no colour
shift, no new z-fighting. The only differences across all five diffs are (a)
the intentional-looking camera reframe at station 08, (b) the added trees at
station 13, and (c) per-pixel cloud/grass-blade animation noise present in
all five that does not change any object's identity or position. Stations
07, 10, and 14 are visually indistinguishable from round 6 at the object
level.

## Corridor read against the reference art

Against `tetherbound-meadows-keyart.png` / `page-board.jpg`: palette and
general "meadow with tree clusters and a path" language are consistent with
the target — warm sunlit grass, blue sky, oak-shaped canopies. But value
range is much flatter than the key art (which uses strong core-shadow
modelling on canopies and rich ambient occlusion in tree clusters); these
renders read closer to flat-lit toy-scale foliage. Sky occupies an
outsized share of most frames (07, 13 especially), which the key art never
does — its compositions keep the horizon high and fill the frame with
landscape incident, not cloud.

Against the Palworld references: ground/foliage density is well below bar.
Palworld's `palworld-02` and `palworld-04` shots pack grass, low scrub, and
scattered rock down to the camera's feet with no visible bare ground plane;
these corridor stations (07, 13, 14 most visibly) show sparse, evenly-spaced
grass blades over a largely bare/flat-shaded ground texture, especially past
the immediate foreground.

## Overall score

Of the five re-rendered stations, only one (13) shows an unambiguous,
attributable improvement, and it is partial (mid-right density up, frame
edge still empty). One (08) shows a real change whose stated justification I
could not verify against round 6. Three (07, 10, 14) are visually identical
to round 6 — including 14, whose specific claimed content (a camp) is simply
not present in either round. No regressions. This is a stalled round, not a
regressed one.

## Ranked remaining defects

1. **Station 14 has no camp.** The station's own name promises a ridge camp;
   neither round shows tent, fire, crates, or seating. This is the largest
   gap between what the station is meant to show and what it shows.
2. **Station 07's copse doesn't compose as foreground framing**, and round 7
   made no change to it — sky still dominates over half the frame with the
   trees pushed to background-left rather than flanking the path.
3. **Station 13's right frame edge is still empty** past the newly-added
   mid-right trees — the fix stopped short of the actual edge.
4. Signpost text (station 08 right sign, and the left sign's occluded first
   letters at both stations 08 and 14) is not reliably legible at native
   resolution — a texture-resolution/placement issue independent of this
   round's changes.

## Recommendation

**NEXT ROUND** — station 14 needs an actual camp placed in frame, station 07
needs a real foreground-framing edit (not a no-op re-render), and station 13
needs its added trees carried through to the frame's right edge; station 08's
reframe should be confirmed intentional and its signpost text made legible
before merge.
