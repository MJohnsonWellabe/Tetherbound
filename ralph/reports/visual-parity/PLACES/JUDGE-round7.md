# Visual Parity Judge — Round 7 (blind)

Method: compared round6 vs round7 frames at native exposure (no brightening), 960x540, plus
the relay before/after pair. Judged against `docs/reference/tetherbound-meadows-keyart.png`,
`docs/reference/palworld-0*.jpg` (palworld-02 = warren/cave-mouth reference), and
`site/img/page-board.jpg`. Code, diffs, and reports were not read.

Standing owner verdicts going in: Warrens INTERIOR (den) GOOD/untouchable; Hall/stronghold,
Warrens EXTERIOR, and the relay were BAD at baseline.

---

## Per-frame, r6 → r7

**04-warrens-approach-day** — Pixel-near-identical. The rock-mound silhouette, the small
timber-framed doorway at its base, and the sky are unchanged. Top remaining defect: a
distinctly pale grey-white boulder sits directly above the doorway (see below, item A) —
present unchanged in both rounds.

**04-warrens-den-day** — Pixel-identical to r6. This is the frame the owner called good and
untouchable; it still is: warm stone-brick walls, timber roof beams, the badger creature is
clean and readable, floor and lighting are coherent. No action needed, none taken. Correctly
left alone.

**04-warrens-standing-day** — Pixel-identical to r6. Top remaining defect: a large flat,
pale, checkerboard-ish rectangular panel fills the right third of the frame — reads as a bare
material/back-face with no real texture, not a rock or wall the scene intends. Unaddressed
this round.

**10-stronghold-approach-day** — Improved. r6 has an opaque dark-grey storm band sitting
directly behind/above the hall roofline, roughly a third of the visible sky; r7 removes it
almost entirely, leaving normal wispy cloud texture. Same geometry, better sky. Remaining
defect: the hall itself is still a flat near-black silhouette with little material read even
this close (see item B).

**10-stronghold-approach-night** — Effectively unchanged. Moon, hall silhouette, and cyan
tether-line are all still legible against the night sky; no material regression or gain here.

**10-stronghold-courtyard-day** — Effectively unchanged. Banners, gate frame, NPC and the
sliver of exterior castle crenellation visible through the gate opening are all the same as
r6.

**10-stronghold-courtyard-night** — Effectively unchanged, and still a legibility problem
independent of r6→r7: at native exposure this frame measures median brightness 0 and ~83% of
pixels below value 20 (near-black). Outside the two lit banner pools and torch highlights,
the player, the second NPC, and the ground are essentially invisible. r7 did not touch this.

**10-stronghold-gate-day** — Improved. r6 carries a heavy diagonal grey-black band over the
right-hand hillside and small tower; r7 clears most of it, restoring blue sky there. Gate
towers and portcullis geometry unchanged. Remaining defect: no clearly identifiable sentry on
any tower (see item C).

**10-stronghold-gate-night** — Effectively unchanged. Same silhouette, same moon, same
partial cloud cover.

**11-castle-landmark-hall-100m-day** — Most improved frame in the set. r6's storm band is
thick, opaque, near-black, and covers roughly 30% of the visible sky directly over the hall;
in r7 it is reduced to faint cloud texture, no more than a couple of percent. The hall
silhouette itself, its towers, arched red door, ivy, and banners are unchanged — this is a sky
fix, not a hall-model fix.

**11-castle-landmark-hall-200m-day** — Improved, smaller effect. r6's band (~15% of visible
sky, still clearly a distinct grey stripe) is thinned to a faint haze (~4-5%) in r7.

**11-castle-landmark-hall-400m-day** — Improved, smaller effect, same pattern: r6's band
(~12-15% of visible sky) thins to ~3% in r7. At this distance the hall is a small dark
silhouette either way; the sky change makes it read as "distant castle under a clear sky"
rather than "distant castle under a bruise of cloud," which is the more legible and less
muddled read.

---

## Targeted questions

**(A) Warrens exterior — earth mound with a dark mouth? pale patch/band over the doorway? one
rock family?**

Yes to an earth/rock mound with a dark mouth: the boulder mass reads as a mound, and there is
a small dark rectangular opening at its base (flanked by a timber lintel) that functions as
the den mouth. But it is not "one rock family with the den" — a sharply pale grey-white
boulder sits immediately above the doorway, breaking from the uniform dark-brown/olive rock
material used everywhere else on the mound. It reads as a different, unfinished or
placeholder material dropped into the middle of a finished rock formation, not as a natural
lichen/mineral variation. This is present unchanged in both r6 and r7 — round 7 did not touch
the warrens exterior at all (file is pixel-identical). Compared to the reference
(palworld-02, the warren/cave-mouth shot), that reference reads as one continuous weathered
rock material with two dark mouths and no discontinuous patch; Tetherbound's warrens mound
does not yet match that.

**(B) Hall silhouette at 100/200/400m, and the storm band's share of the sky**

Silhouette: at 100m the hall reads clearly — twin crenellated towers, a taller corner turret,
an arched red door, hanging ivy, and red banners are all individually legible. At 200m it is
smaller but the twin-tower-plus-turret profile and crenellation line are still readable
against the sky. At 400m it is a small dark blob; zoomed in, the crenellation notches and the
turret spike are still just barely distinguishable, but at true in-frame size (as it would
appear at 30% thumbnail scale, per the rubric) it risks reading as "a dark rock/tree clump"
rather than unmistakably as a castle — it has no color or material cue at that distance, only
outline. This is unchanged r6→r7 (identical geometry both rounds); the sky treatment is what
changed, not the model's distance-readability.

Storm band's share of the visible sky, estimated from the frames (region above the horizon,
below the top of the crop used):
- Approach: r6 ~30-35% of the sky is occluded by an opaque dark band directly over the hall → r7 ~2-3%, mostly gone.
- Gate: r6 a heavy diagonal band covers roughly a third of the sky on the right side → r7 a thin remainder, roughly 5-8%.
- Hall 100m: r6 ~30% → r7 ~2%.
- Hall 200m: r6 ~15% → r7 ~4-5%.
- Hall 400m: r6 ~12-15% → r7 ~3%.

All five are a clear, consistent reduction in the same direction, not noise. The trade-off
worth naming: the storm band gave the enemy stronghold some visual menace/weight against a
Palworld/keyart-style bright meadow sky; removing it makes the day sky read cleanly but also
makes the hall itself carry all the "occupied enemy fortress" read on its own silhouette and
material — which it does not yet fully deliver (see gap #2 below).

**(C) Courtyard at night — legible? sentries on the gate towers?**

Courtyard night is not legible at native exposure. Measured: median pixel brightness 0,
~70% of pixels below value 10, ~83% below value 20. Only the two lit banner faces, a torch
pool, and the standing NPC's rim-lit silhouette register; the player character, the ground,
and the side structures are indistinguishable from black. This is a harsher black than the
keyart's own night reference (bottom-right panel of the keyart board), which keeps visible
moonlit terrain, a lit village in the distance, and clear character/creature silhouettes even
at night. r7 does not change this frame from r6.

Gate towers: no sentry is clearly identifiable on any tower in the day gate shot. There is one
small pale blob near the top of the left rear tower that could be a standing figure or could
be a banner/finial — at this resolution and distance it is not identifiable as a person, and
no shape resembling a figure appears on the other three towers. Unchanged r6→r7.

**(D) Relay from the road — weathered occupied compound, or still white/pale?**

Mixed, and meaningfully improved but not finished. The gate frame and the two flanking
compound walls visible from the road were flat pale cream/bone-white in the before shot; in
the after shot they are now a dark weathered brown/bronze, which reads far more like an
occupied, aged Team Tether structure and is a real, visible fix — the single biggest win in
this pair.

Still pale/untextured, unchanged before→after:
- The ground/sand plane under the whole relay compound (road, approach, apparatus, standing) — still a flat pale cream-tan in every one of the four after-shots, same as before.
- The raised colonnade/platform in the "apparatus" and "standing" views (the stone-block roof, pillars, and ramp directly under the tether machine) — still pale cream-white masonry in the after shots, not weathered or Team-Tether-branded, and now stands out even more because the gate walls around it went dark and this did not.
- In "standing," the sliver of gate structure visible at the far left edge is dark (matches the road/approach fix), but the large foreground colonnade the camera is under is untouched pale stone.

So: walls and gate frame = fixed. Ground and the central platform/colonnade = still white/pale
and now visually inconsistent with the walls around them.

---

## Ranked: three biggest remaining gaps vs. the references

1. **The enemy stronghold hall does not read as a weathered, occupied, dangerous structure up
   close, even now that the sky is clean.** At 100m (`11-castle-landmark-hall-100m-day.png`,
   also `10-stronghold-gate-day.png`) the hall is close to a flat near-black silhouette with
   little surface material, form-shadow, or color variation — compare to the keyart's
   "TEAM TETHER STRONGHOLD" panel, which shows weathered tan stone, torn red banners with
   visible fabric, climbing vines with individual leaf clumps, and warm interior light glowing
   through windows. Tetherbound's hall reads as one flat dark value with red banner cutouts
   pasted on. This is a lighting/material gap, not fixable by more sky work — the storm-band
   fix already exhausted what the sky alone can do for this frame.

2. **The relay compound's ground and central colonnade are still the pale, unfinished surface
   the round was meant to fix, and now clash with the walls that were fixed.**
   (`relay-after/06-relay-apparatus-day.png`, `relay-after/06-relay-standing-day.png`,
   `relay-after/06-relay-road-day.png` ground plane.) This is scene/material work, directly
   fixable: apply the same weathered dark treatment already used on the gate walls to the
   platform, pillars, and ground.

3. **Night interiors and small discontinuous "wrong material" patches undercut otherwise
   competent scenes.** The courtyard at night (`10-stronghold-courtyard-night.png`) is too
   dark to read at all outside two lit props, and the warrens mound
   (`04-warrens-approach-day.png`) carries one conspicuously pale boulder dropped into an
   otherwise unified rock family, plus the warrens-standing frame's flat pale checkerboard
   panel (`04-warrens-standing-day.png`) that reads as an untextured back-face. All three are
   fixable by re-lighting/re-texturing the specific surfaces named — none require new art.

## Two bar questions

**A. Do these frames read as belonging to the world in the keyart?**
**No**, for the frames the owner flagged as bad (Hall, Warrens exterior, relay); **yes**, for
the frames already called good (Warrens den). The meadow ground plane, tree language, and
lighting direction the round didn't touch (approach shots' foreground grass/trees) do match
the keyart's palette reasonably well. What breaks the match is the hall's flat unlit material,
the warrens mound's discontinuous pale rock, and the relay's remaining pale
ground/colonnade — none of those exist in the keyart's version of a stronghold, warren, or
enemy compound, all of which show full material and weathering detail even in wide shots.

**B. Shown beside the Palworld screenshots, would someone say these are trying to be the same
kind of game?**
**Partially — closer than round 6, still no.** The sky fix genuinely helps: a clean blue day
sky over green rolling hills is much closer to `palworld-04-plateau-landmark.jpg`'s bright,
readable composition than r6's brooding grey-banded sky was. But the structures themselves —
hall, relay compound, warrens rock — remain flatter, less material-rich, and less weathered
than anything in the Palworld set, where every base/ruin (`palworld-05-base-building.jpg`,
the tower in `palworld-04`) carries visible stone joints, moss, rust, and warm occupied
lighting even at a glance. The gap here is concentrated in specific named surfaces (hall
walls, relay ground/colonnade, the one warrens boulder) rather than spread evenly — which
means it is addressable without new assets, by extending the same weathering/material pass
that already worked on the relay's gate walls to the surfaces it hasn't reached yet.

### Fixable vs. not

Fixable by scene work (lighting, material/texture reassignment, palette, scatter — no new
art needed):
- Hall wall material/shading at close range (gap #1)
- Relay ground plane and central colonnade material (gap #2)
- Warrens mound's one pale boulder, and the warrens-standing pale panel (gap #3)
- Courtyard night exposure/fill light (item C)
- A visible, identifiable sentry silhouette on at least one gate tower, if that's meant to
  read at a glance (item C)

Not fixable by scene work alone (would need new/expanded art or geometry):
- Nothing in this round's findings requires new meshes — every defect found here is a
  material, lighting, or texture-assignment problem on existing geometry, consistent with the
  project's "no new Meadows meshes" constraint.
