# CORRIDOR Round 6 — Visual Parity Judgment

Blind review of `round6/*.png` (16 player-height day stations) against `round5/*.png`, judged per `.claude/skills/visual-judge/SKILL.md` and the project's own references (`docs/reference/tetherbound-meadows-keyart.png`, `docs/reference/palworld-0*.jpg`, `site/img/page-board.jpg`). No code, diffs, or prior reports were read.

Pixel-diff sanity checks (mean per-channel delta) were run against round5 purely to catch silent regressions the eye might miss; they do not substitute for visual judgment but confirm which stations actually changed.

## Per-station verdicts

| # | Station | Round5 → Round6 | Verdict | Pass/Fail | Top defect |
|---|---|---|---|---|---|
| 01 | village-edge | unchanged (Δ<1) | same | pass | none material |
| 02 | first-bend | unchanged (Δ<1) | same | pass | none material |
| 03 | loop-apex | unchanged (Δ<1) | same | pass | none material |
| 04 | eastward-swing | unchanged (Δ<1) | same | pass | none material |
| 05 | south-bridge | unchanged (Δ~1) | same | pass | none material |
| 06 | stone-root-entry | unchanged (Δ~1) | same | pass | none material |
| 07 | band2-mid | unchanged (Δ~6, cloud/scatter jitter only) | **same** | fail | No foreground copse was added. Trees still sit at the same mid-distance cluster on the left as round5; nothing reads close to camera. The near-ground is still just grass and the path — no layered depth. |
| 08 | band2-far | unchanged (Δ~13, but only signpost position + foliage jitter) | **same** | fail | Signpost text is still clipped on both posts. Left post reads "...ren Underv...l" — the post itself occludes the start of the word. Right post reads "...ne Gate Spoke" — cropped at the placard's left edge (missing "Sto..."). Confirmed by direct crop; identical failure mode in round5. |
| 09 | river-lock-entry | **materially changed** (Δ~5, but real content) | **better** | pass | Mid-ground is now genuinely filled — a real grove with canopy density spans the center of frame instead of round5's isolated corridor of thin, widely-spaced trunks with open sky between them. Water is still structurally absent (per instructions, not scored), but the composition itself no longer reads empty. Minor: same partial blue creature silhouette clipped at the far-left edge in both rounds — not addressed, but not the flagged defect. |
| 10 | relay-approach | **materially changed** (Δ~7) | better density / defect persists | fail | Left side of the mid-ground now carries a real stand of trees (round5 had two isolated saplings there); overall frame reads less empty. But there is still no relay silhouette, spire, or apparatus glimpsed anywhere in the background — nothing in this frame tells the player "you are approaching a relay." The station's defining identity is still missing. |
| 11 | relay | **completely different composition** (out of scope per brief — materials owned by another lane) | n/a | n/a (not scored) | Camera angle, structure, and staging are all different from round5 (now a raised gantry with mechanical apparatus and NPCs vs. round5's walled courtyard). Flagging one non-material issue for the record: the sun disc is blown out to a flat white blob eating a large chunk of sky — that's an exposure/tonemapping artefact, not a material choice, and would read as a bug even to someone who never saw round5. |
| 12 | old-mill-crossing | unchanged (Δ~3, cloud jitter) | same | pass | none material |
| 13 | band4-entry-bend | **minor change** (Δ~6) | marginally better, still weak | fail (borderline) | Two boulder/rock shapes were added to the right-mid ground where round5 had nothing. That breaks up the silhouette line slightly, but the right two-thirds of the frame is still overwhelmingly open grass to the horizon — two rocks do not read as "filled" next to the tree mass anchoring the left third. Still an unbalanced, half-composed frame. |
| 14 | ridge-camp-approach | **materially changed, largest delta on the sheet** (Δ~43) | **worse** | fail | This is a regression. Round5 had a real wall of forest — dense canopy spanning roughly the center-right two-thirds of the frame, close behind the NPC, with real depth layering. Round6 pushes that same tree mass further right and shrinks its footprint; the left two-thirds of the frame is now open sky and bare rolling hill with a single distant sapling. The tan dirt clearing in the foreground is proportionally larger and emptier as a result. And there is still no camp — no tent, fire, cache, or any prop that would justify the station's name "ridge camp approach." Whatever changed here made the frame emptier, not fuller. |
| 15 | stronghold-approach | unchanged (Δ~2) | same | pass | none material |
| 16 | hall-gate-approach | unchanged (Δ~3) | same | pass | none material |

## Direct answers to the round-5 follow-up questions

- **07 restored with a foreground copse?** No. Composition is pixel-for-pixel the same tree layout as round5 (jitter only). Nothing was added near the camera.
- **08 signpost legible?** No. Both posts remain clipped — one occluded by its own post, one cropped at the placard edge — identically to round5.
- **09 mid-ground now present?** Yes, clearly. This is the round's one unambiguous win: a real grove now occupies the center of frame instead of a thin scattered line of trunks. Judged on composition alone (water absence excluded per instructions), it passes.
- **10 relay glimpsed / mid-ground mass?** Mid-ground mass: yes, improved (left-side grove added). Relay glimpsed: no — no structure of any kind is visible in the background at this station.
- **13 right side filled?** No, not meaningfully. Two rocks were added but the right two-thirds is still mostly bare grass to the horizon.
- **14 camp actually in frame with the clearing covered?** No camp is present in either round, and in round6 the clearing is *less* covered than round5 — the tree mass that was doing the work of "covering" the frame has shrunk and moved away from camera-left.

## Any station worse than round 5?

**Yes — station 14.** It has by far the largest measured change on the sheet (mean pixel delta ~43 vs. ~1-7 for every other altered station) and the change reads as a loss of density: the tree wall that anchored the frame in round5 has shrunk and been pushed toward the right edge, leaving more open sky and bare hillside than before. No other station regressed; 01-06, 12, 15, 16 are pixel-identical in substance (deltas under 3, consistent with cloud/AA noise, not content).

## Three weakest stations, ranked

1. **14 — ridge-camp-approach.** Not just unfixed but actively regressed: emptier composition than round5, and the "camp" the name promises still doesn't exist anywhere in frame. The single worst frame on the sheet.
2. **10 — relay-approach.** The mid-ground density fix is real progress, but the station still has zero visual identity — nothing distinguishes "approaching a relay" from any other meadow path. A named landmark station with no landmark in it is a bigger structural gap than a busy-but-imperfect frame.
3. **13 — band4-entry-bend.** Still a half-composed frame: a competent tree mass on the left and functionally empty grass on the right. Two boulders is a token gesture, not a fix — this remains the frame that most looks like someone forgot to finish dressing one side of it.

(07 and 08 are close behind — both are unaddressed carry-overs from round5 with no attempt visible in the diff — but they're narrower defects: 07 is a missing depth layer in an otherwise coherent frame, and 08 is a legibility/UI-adjacent bug rather than a composition failure.)

## Bar A — Do these frames belong to the keyart's world?

**No**, though parts of the corridor (01-06, 09, 12, 15, 16) individually clear the bar. What sinks the average across all 16: the keyart's meadow is continuously, densely dressed — every frame in it has layered foreground, mid-ground, and background vegetation with real canopy volume and understory detail (the oak-grove panel and the lake-dock panel are the clearest examples). This corridor is inconsistent: several stations (07, 08, 10, 13, and now 14) still read as a bare rolling field with a tree line pinned to one edge, which the keyart never does — even its most "open" panel (the sunset standing-stone vista) has foreground rock, midground scrub, and a silhouetted peak doing compositional work at every depth. A world that alternates between "fully dressed" and "half-dressed" every other station does not read as one authored place; it reads as a corridor where some stations got attention and others didn't.

## Bar B — Same kind of game as Palworld?

**No, not yet, though closer than a round ago at the stations that changed for the better.** Palworld's frames (all five references) share one trait this corridor still lacks broadly: ground-level density. Even Palworld's most open field shot (`palworld-02`) has continuous grass texture, scattered rock and scrub at multiple distances, and creatures/props breaking the horizon. Station 09 in round6 now approaches that — a real grove with depth. But 07, 08, 10, 13, and 14 still show the flat, evenly-spaced, low-prop-density "walking simulator" field that the keyart and Palworld both avoid. The player character and its animation/proportions read fine and are not the problem; the problem is that too many stations along this specific corridor still have long stretches of nothing between the path and the horizon.

### What's fixable by scene work vs. what needs new art

**Fixable by changing the scene (density, placement, scatter, exposure) — no new art required:**
- 07: add a foreground tree/shrub cluster close to camera-left or -right, matching the density already present in 09.
- 08: reposition or resize the signposts so the post doesn't occlude its own placard, and pull the right sign further from the left frame edge, or angle it toward camera.
- 10: nothing further needed for density (09/10's fix pattern already works) — but relay identity needs at minimum a distant silhouette (spire, cable run, structure) visible above the treeline at this station specifically.
- 13: replace the two token boulders with an actual scatter pass on the right two-thirds — trees, rocks, and scrub at the same density as the left third.
- 14: revert or redo whatever scattering pass thinned the tree mass here — round5's denser canopy was strictly better and should be the floor, not the frame this round shipped.
- 11: the blown-out sun is a tonemapping/exposure clamp, fixable without any new asset.

**Not fixable by scene dressing alone — needs actual art or a placed prop that doesn't exist yet:**
- 14's "camp" identity: there is no tent, fire pit, supply cache, or any prop establishing this as a camp in either round. That's a missing asset placement, not a density problem — scattering more trees will not make it read as a camp.
- 10's relay identity: if no relay-family structure/silhouette asset is placed anywhere near this station's sightline, no amount of tree scattering will fix it — it needs the landmark itself to exist in the scene, even distantly.
