# T1-ARCH — buildings pass, 2026-08-29

Owner verdict this lane answers (`ralph/OWNER_FEEDBACK_2026-08-29_BUILDINGS.md`):
castle bad, stronghold bad, Warrens interior good, Warrens exterior bad.

Evidence: `tools/capture_t1arch_all.gd` (one scene load, all four sites,
90-frame settle — the base scripts' 240-frame settle plus three separate
scene loads was blowing the session's time budget under this environment's
software rasterizer). Frames are gitignored (`shots/`); the before/after
pairs were sent directly to the owner in-session.

## 1. Warrens exterior mound — diagnosed, fixed, verified

**Before:** `W-ext-01/02-knoll-from-outside.png` — the outcrop reads as a
wall of dark, undifferentiated moss-green hedge, not granite. A flat grey
box face was visible showing through a gap in the boulder pile.

**Cause:** `_build_mound()` clads the whole exterior box in
`Rock_Medium_1/2/3.gltf`, scaled 2.2–4.4x, coloured by `_tint_rock()` — a
*multiply* over the model's own `Rocks_Diffuse.png`. Pixel-sampled that
texture directly: a dark, consistently green-dominant moss/lichen photo
(~(80,90,65) average). A multiply can only darken/desaturate toward the
tint; it cannot rotate a green-dominant photo to a neutral stone hue.
CONTENT-0828B already hit and fixed this *exact* bug for the cave's
*interior* decorative rock (`_wear_the_cave_stone`, swapping to the cave's
own triplanar Rock030 wall material instead of tinting the nature pack) but
explicitly left the exterior mound on the multiply, reasoning that strong
outdoor sun would read differently. It doesn't.

**Fix:** `burrow_warrens.gd::_place_rock()` now calls
`_wear_the_cave_stone()` instead of `_tint_rock()` — reuses the
already-installed, already-tuned Rock030 stone (triplanar, so it needs no
UVs authored for the nature-pack mesh) so the outcrop and the chamber walls
are the same rock in both directions, not just in the file's own comment
about them.

**Verified:** re-rendered. The mound now shows real granite facet/fracture
detail and grey-tan mineral variation, matching the interior's own bar.

## 2. Stronghold exterior approach — diagnosed, partially fixed

**Before:** `S-ext-01-approach-ramp-foot.png`, `S-ext-02-flank-wide.png` —
the `outer_works` curtain renders as a near-total black silhouette from
every stand, no stone detail readable.

**Cause:** the same backlighting bug `stronghold_occupation.gd` already
diagnosed and fixed for `landmark.gd`'s castle — `art.json`'s sun is in the
north sky, every approach here is south-facing (`_build_approach_ramp`
exits toward decreasing local z), so the hero face is backlit at every hour
the chapter is played. That file's own header says outright the stronghold
route "is a different building entirely... untouched by it." It still is,
mostly.

**Fix, attempt 1 (reverted by evidence):** two fire-coloured OmniLights
flanking the gate, energy 1.8/range 18 — guessed rather than calibrated.
Re-rendered: no visible change. Checked the castle's own numbers: fourteen
braziers (~1.69 energy/~10.2 range) *plus* four wide shadowless sky-fill
omnis (1.4–2.4 energy/30–50 range) across a 10m curtain. Two small-range
points were never going to be that system at any energy.

**Fix, attempt 2 (shipped):** four fire points spread across the curtain's
own 20m width (local x −8/−3/3/8, all just outside the mouth) plus one wide,
weak sky-fill light standing off the approach — a smaller version of the
same two-part recipe, sized to this wall.

**Verified, partially:** `S-ext-01` (the straight-on approach — the shot a
player actually walks toward) now shows real warm-lit masonry, a large
improvement over pure black. `S-ext-02` (a wide flank stand 40m off to the
side, looking at the *perpendicular* west wall) is still mostly dark — the
four fire points are all on the south face and don't reach that face at all.

**Not done:** a full `TetherOccupation`-scale dressing pass (lighting every
face, not just the approach) for this building. That is a separate task at
roughly the scale the castle's own pass was.

## 3. Castle — inspected, root cause is NOT what it looks like, not fixed

**Before/after (unchanged — no fix attempted):** `C-02-silhouette-far.png`,
`C-03-corner-close.png`. Up close the castle reads pale, flat and
plastic/toylike.

**What it is not:** the retint is not broken. Pixel-sampled a wall face in
`C-03`: rendered RGB ~(186,175,152), which is the authored `LightRock` hex
`#a3907a` (163,144,122) brightened by direct sun — correct, not a fallback
white material. `capture_castle.gd`'s own `SITE` constant was found stale
(pre-GATE-E2 coordinates, 7.5km from the current site) and was fixed in a
separate tool (`capture_castle_63.gd`), but that was a *capture* bug, not a
build bug — the live castle itself renders at the right site.

**What it likely is:** the Quaternius kit's own solid-colour, no-texture
low-poly style, un-weathered, un-AO'd, viewed under harsh unshadowed
midday sun in software rendering — the same "no middle scale of visual
interest" diagnosis `interior_structure.gd`'s own header gives for
constructed interiors, now showing up on an *exterior* kit asset that never
got an equivalent pass (no AO/grime/edge-wear, nothing between "wall" and
"crenellation"). Not attempted: this needs its own pass (weathering
overlay, or moving more of the wall area under the same fire/sky-fill
treatment `stronghold_occupation.gd` already proves works with this exact
kit) and was out of reach of this lane's remaining time.

**Also unresolved, flagged for a future lane:** `stronghold.json`'s own
`_comment_ow5d_relocation` already says `yaw_deg: 90` is "very likely WRONG"
for the post-corridor site — the approach now arrives from the north but
the route still progresses as if approached from the west, so the
`outer_works` entrance faces world −x while the player travels roughly
north–south past it. Re-deriving the room-by-room layout for the correct
approach bearing is a full re-siting job (probe grid, every
chamber/light/mark recomputed), explicitly left to a future reviewer by
that comment. Not attempted here — too large and too risky to do blind
inside this lane's time box, but it is plausibly a real contributor to "the
stronghold reads bad from the approach," independent of the lighting fix
above.

## Why the interior method worked and the exterior needed something else

The direction doc asked this as the real question. Short answer from what
the frames actually show: `interior_structure.gd`'s bays/course/ribs/
reveals/corners give an enclosed, artificially-lit room the middle scale of
visual interest it has nothing else to supply (no sun, no weathering, no
sky). Outdoors that problem doesn't exist — the sun and the terrain already
give scale and value variation for free — so the exterior defects were
never about missing structure. They were two unrelated failures that happen
to share a class label ("a building"): a wrong SOURCE TEXTURE (Warrens
mound) and a wrong LIGHT DIRECTION relative to a fixed sun (stronghold
curtain, and probably the castle's own remaining flatness once its texture
issue is ruled out). Exteriors don't need their own version of the interior
grammar; they need their two, unrelated, already-precedented fixes applied
consistently everywhere a building meets the outdoors.
