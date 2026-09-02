# VP4 Travel Corridor — Round 5 Judgment

Blind review of `ralph/reports/visual-parity/CORRIDOR/round5/*.png` (16 stations,
village → South Bridge → Band 2 → river/relay → old mill crossing → Band 4
ironwood → ridge camp approach → stronghold approach → Hall gate), against
`docs/reference/tetherbound-meadows-keyart.png` and `docs/reference/palworld-0*.jpg`.
Stations 01–08 compared to round4 (their previous judged set); stations 09–16
compared to `00-before-b3b5` (their befores).

Method note: pixel-diffed round4 vs round5 for 01–08 first. All eight differ by
only 3–8% of pixels (cloud drift / soft shadow noise), confirming no
compositional change happened in that half of the route this round — so
"better/worse/same" below for 01–08 is "same" throughout except the specific
sheep removal noted at 07. Stations 09–16 were compared frame-for-frame against
their befores; several are byte-for-byte identical.

## Per-station verdicts

**01 — village-edge-day.** Same. Pass, Bar A yes. Foreground split-rail fence,
midground oak cluster + rock outcrop landmark, two pale grazing shapes on the
skyline reading as distant life, background ridge. Top defect: the tree in the
top-right corner is clipped by the frame edge — cosmetic only.

**02 — first-bend-day.** Same. Pass. A loose stand of trees frames the path
left-of-centre with a second, denser copse on the horizon giving real depth.
Top defect: the band between the near copse and the horizon line is bare grass
with no midground incident — a thin waist in an otherwise good composition.

**03 — loop-apex-day.** Same. Pass. Full canopy passage — this is the one
station that plays the "walking through the trees" card, and the oversized
right-foreground trunk with light bleeding through leaves overhead is the most
atmospheric single frame in the set. Top defect: sky is reduced to a sliver;
fine here because it reads as a deliberate canopy tunnel, but the set can't
sustain many of these before it starts to feel enclosed rather than open
meadow.

**04 — eastward-swing-day.** Same. Pass. Clean foreground/mid/background with
a pale mountain sliver on the horizon holding the eye. Top defect: none
significant — the weakest of the "clean pass" stations only in that it is the
most generic, without a landmark prop.

**05 — south-bridge-day.** Same. Pass. Dense forest wall on the right against
open sky on the left gives a strong asymmetric read, distinct from 03's full
canopy. Top defect: the lone left-foreground tree is doing a lot of work by
itself; one more mid-distance tree on that side would balance it.

**06 — stone-root-entry-day.** Same. Pass. Forest corridor with a second
character on the path ahead — the first frame in the set with a human NPC,
which helps scale and life. Top defect: the signpost at bottom-left renders
its label as garbled/boxed glyphs, not legible text — a font or string-encoding
bug, not a composition problem, but it reads as a bug in a still.

**07 — band2-mid-day.** Same composition as round4; the only pixel change is
that two pale sheep silhouettes present in round4 (one on-path, one by the
tent) are gone in round5. **Not fixed.** The foreground copse called out in
the previous verdict is still absent: one isolated tree at far left, a thin
ridge-line tree cluster on the horizon, and otherwise nothing but flat
flower-scatter meadow between the camera and the horizon. It is the emptiest
frame in the walkable half of the route and reads as open field, not corridor.
Top defect: no near/foreground tree mass — nothing stands between the player
and the horizon to compose the shot.

**08 — band2-far-day.** Same composition as round4 (near-identical, cloud
noise only). **Signpost still clipped, not fixed.** Cropped both signs at 2x:
left post reads "...rten .nderal" and the right post reads "...one Gate
Spoke" — both overflow past their board's left edge, so the string is being
truncated or the board mesh is undersized for its text at this camera
distance; this is the same defect as before, unchanged pixel-for-pixel. Rest
of the frame is good — a rock outcrop landmark on the left, a proper forest
wall on the right, real foreground/mid/background structure.

**09 — river-lock-entry-day.** Better than before, but still fails on its own
terms. The previous stray cropped creature (a winged silhouette clipped at
the left frame edge in the "before" shot) is gone. The frame itself is now a
clean, well-composed avenue — two flanking foreground trees, a midground tree
line, background hills — genuinely better structure than most of the set.
But it is called "river-lock-entry" and **there is still no water anywhere in
frame**, in either the before or the round5 version. Top defect: no river —
the one landmark the station's name promises is absent.

**10 — relay-approach-day.** Byte-for-byte near-identical to before, unchanged.
Still weak. It reads as a generic wilderness campsite (tent, fire, crate,
signpost, a distant NPC) rather than as an approach to a relay — nothing in
frame telegraphs "relay" as a destination, and the signpost text is again
illegible smudge-text. Decent foreground/mid/background bones, but the content
doesn't earn the station name.

**11 — relay-day.** Unchanged from before. Still fails hard: bare
white/untextured concrete walls, a flat sand-coloured ground plane with no
grass or dirt texture, and floating crates/workbenches with no ground
contact shadows reading naturally. This is the single least-finished frame in
the whole set — it looks like an unskinned blockout, not a place. Owned by
another lane per the brief, but it remains the worst thing in the route as
experienced end to end.

**12 — old-mill-crossing-day.** Unchanged, still a pass. Half-timbered mill
tower as a clear landmark, river visible lower-right, reed/cattail foreground
detail giving real ground texture — one of the best-composed stations in the
set.

**13 — band4-entry-bend-day.** **Improved, no longer the textbook failure it
was.** Before: almost pure grass-to-sky with only a token tree smudge on the
horizon. Round5 adds a distinct foreground cluster of tall, thin-canopied
trees (a different silhouette language from the oak clumps earlier in the
route — reads as this band's own "ironwood" identity) breaking the skyline at
left-of-centre. That is a real, addressable fix and it changes the frame's
read at a glance. But the fix is partial: sky still occupies roughly half the
frame, the right two-thirds of the ground plane is still open flower-scatter
with no incident, and there is nothing in the midground to carry the eye from
the new foreground trees to the horizon. Call it fixed-from-broken but still
short of the bar the rest of the set clears — a borderline pass, not a clean
one.

**14 — ridge-camp-approach-day.** Unchanged. Still weak. The bones are
actually good — an NPC waiting at a forest wall with a signpost ("...atchtower
Spur") and a proper tree mass on the right — but a large, flat, featureless
dirt clearing dominates the right-foreground third of the frame with no
scatter, no shadow break, no prop. It reads as a bare lot cut into the scene
rather than a camp. That clearing is the thing dragging this station down,
not the composition around it.

**15 — stronghold-approach-day.** Unchanged. Still borderline. The stronghold
silhouette with a black smoke plume rising behind it is a genuinely strong
landmark beat, and the crystal-topped relay spire on the right gives a second
point of interest — this is doing real work as a "danger ahead" story beat.
It stays borderline because the midground gate/fence structure between camera
and stronghold reads flat and small relative to the drama behind it, and
there is a small blue winged creature rendered directly behind/above the
player's head that reads as an ill-placed floating prop rather than a
companion — it's cropped by the player model and unclear what it is.

**16 — hall-gate-approach-day.** Unchanged, still a clean pass. The Team
Tether gate reads as genuinely ominous — dark stonework, banked smoke, tether
cables running to the crystal spire — and a fox/wolf companion trotting
beside the player on the path adds life and a sense of "not alone anymore."
The strongest closing beat in the set.

## Direct answers

**Is 13 fixed?** Partially. The specific defect named — "textbook empty
grass→sky" — is gone: a real foreground tree cluster now breaks the skyline
and gives the shot a landmark. It is not a clean pass yet: sky still covers
about half the frame and the rest of the ground plane (particularly the right
side) is still undifferentiated flower-scatter with no midground. Call it
upgraded from fail to borderline, not upgraded to pass.

**Is 07 fixed?** No. Pixel-identical composition to round4 apart from two
removed sheep silhouettes. The missing foreground copse the previous verdict
named is still missing — the frame is still an open field with nothing
between the camera and the horizon.

**Is 08's signpost fixed?** No. Both sign boards still overflow their text
past the board's left edge, unchanged pixel-for-pixel from round4.

**Do 09/10/14 still fail?**
- 09: composition itself improved (the stray cropped creature is gone and the
  avenue framing is genuinely good), but it still fails its own premise —
  there is no water in a station named "river-lock-entry."
- 10: yes, still fails/weak, unchanged — reads as an unrelated campsite, not
  a relay approach.
- 14: yes, still weak, unchanged — a bare flat dirt clearing undercuts an
  otherwise solid NPC/forest composition.

## Three weakest stations, ranked

1. **11 — relay-day.** Untextured white walls, flat sand-toned ground, no
   natural material anywhere in frame. The one station that doesn't look like
   the same game as the rest of the route, let alone the same game as
   Palworld. (Reported as owned by another lane, but it is still the worst
   frame a player walks through on this corridor.)
2. **07 — band2-mid-day.** The emptiest frame in the walkable route: one
   lonely tree, a thin ridge-line cluster, and otherwise unbroken flat
   meadow between camera and horizon. No foreground structure at all.
3. **09 — river-lock-entry-day** (narrowly ahead of 10). Well-composed as a
   generic meadow avenue, but delivers none of the landmark its name
   promises — no river, no water, nothing that marks this as a "lock entry"
   rather than any other stretch of path. 10 is a close fourth for the same
   reason (no relay identity at a station named for the relay).

## Bar questions

**A. Do these frames read as belonging to the world in the keyart?**
**No — not as a full, continuous 16-station route**, though a clear majority
of individual stations do. Twelve of sixteen stations (01–06, 08 mostly,
12, 13 now-borderline, 14, 15, 16) carry the keyart's oak-grove-and-rolling-
hills language convincingly, with real foreground/mid/background structure,
a believable path, and — at 15/16 — a genuine mood shift into "hints of
mystery" as the stronghold's smoke and dark silhouette come into view, which
is exactly the beat the keyart's sunset stronghold panel sets up. What breaks
the "yes" is that this is a *route*, judged end to end, and four consecutive-
ish stations (07, 09, 10, 11) go slack or hollow right in the middle of the
walk — an empty field, a river station with no river, a campsite standing in
for a relay approach, and an unfinished white box for the relay itself. A
player walking the corridor hits a good five-minute stretch of "this doesn't
look finished" right where the route should be building toward the
river/relay landmark. That is a route-level failure even though most
individual frames pass.

**B. Would someone shown these beside the Palworld references say this is
trying to be the same kind of game?** **No.** Palette and path-through-meadow
staging are close enough — greens, ochre dirt trails, blue sky, similar
camera height. What's missing is density and life. Every Palworld reference
(even the plain field-path shot) carries rock outcrops, varied undergrowth,
built structures, or creatures in frame; open-field Tetherbound stations
(01, 02, 04, 07, 09, 13) are comparatively bare — grass, a path, a tree
clump, sky, and nothing else. More decisively: creatures are almost entirely
absent from this walk. Of sixteen stations, only 15 and 16 show anything
resembling wildlife (an oddly-placed floating creature, and a companion
fox/wolf), versus Palworld's every-frame creature presence. A route this
long with essentially no creature encounters reads as a hiking-sim traversal
test, not as gameplay footage of the creature-bonding game the keyart and
Palworld references both promise.

## What's fixable by scene changes vs. what needs new art/content

**Fixable by scene work (density, placement, scripted content) — no new art
required:**
- 07: add a foreground tree/rock cluster near the camera, same asset kit
  already used at 02/05/09.
- 09/10: either move or add a visible water feature near 09, and add a
  visible relay-silhouette landmark (even distant) at 10 so the station
  delivers on its name before the player reaches 11.
- 13: extend the fix already applied — add a second midground element (rock,
  scrub cluster, second tree stand) so the right two-thirds of the frame
  isn't bare.
- 14: break up the flat dirt clearing with ground scatter, a prop, or a
  shadow-casting object — same treatment used successfully at 10's campsite.
- 08/06/10: fix the signpost text overflow (string/board sizing) — this is
  data or UI-mesh work, not new art.
- 09/15: remove or reposition the stray/oddly-placed creature so it reads as
  a deliberate companion rather than a floating artifact.
- Corridor-wide: script at least occasional wild-creature presence into 3–4
  more of the open-field stations (01, 02, 04, 13 are good candidates) — this
  is placement/spawn-scripting, not new creature assets, since creatures
  clearly exist and render fine elsewhere in the project (15, 16).

**Needs actual art/content, not just scene arrangement:**
- 11: the relay compound needs real ground and wall materials — an
  untextured white blockout can't be fixed by moving props around.
- Overall density gap vs. Palworld: Palworld's frames carry more built
  clutter (crates, tools, banners, decorative structures) even in "just
  walking" shots. Matching that fully means more placed environment-art
  content along the route, not only creature/scatter scripting.
