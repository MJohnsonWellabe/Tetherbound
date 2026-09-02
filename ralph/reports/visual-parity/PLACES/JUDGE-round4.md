# Visual-parity judge — PLACES round 4 (round3 vs round4)

Blind visual review. No code, diffs, or reports were read — only the rubric (`.claude/skills/visual-judge/SKILL.md`), the reference art (`docs/reference/tetherbound-meadows-keyart.png`, `docs/reference/palworld-0*.jpg`, `site/img/page-board.jpg`), and the twelve BEFORE/AFTER frame pairs plus the side-by-side sheet.

Owner verdicts respected as given: Warrens **interior (den)** is GOOD and must stay unchanged; Hall/stronghold and Warrens **exterior** were BAD at baseline.

---

## Per-frame findings

### Warrens

**04-warrens-approach-day** — Changed, better. The boulder mound was recolored from flat pale-grey stone to an earthy brown/olive rock with green moss capping the tops of the boulders. This is a real step toward reading as ground/earth rather than quarried stone.
*Remaining top defect:* the geometry itself did not change — it is still a cluster of smooth, similarly-sized, evenly-domed boulders with no dug soil collar, exposed roots, or scale variety at the entrance. It reads as a re-skinned rock pile, not an excavated burrow. The mouth of the den is still just a dark gap between boulders, not a shaped entrance.

**04-warrens-standing-day** — Changed, mixed. The same brown/moss retexture is visible on the exterior slab and rockface glimpsed through the gap on the right of frame, consistent with the approach shot. But the interior tunnel walls (left, and the cave ceiling) are still the old cool-grey stone texture, unchanged.
*Remaining top defect:* within a single frame the "earthwork" exterior rock (warm brown/green) now visibly disagrees in material and color temperature with the "cave" interior rock (cool grey) a few meters away — a new mismatch introduced by only re-texturing the outside.

**04-warrens-den-day** — Pixel-identical between rounds. Confirmed unchanged, and it still reads as intended (a warm, lived-in animal den with visible roof beams, floor litter, and a good creature-in-context read). Correctly left alone.

### Stronghold

**10-stronghold-approach-day** — No perceptible change.
*Remaining top defect:* at this distance the Hall is a flat dark green-black mass that merges into the dark horizontal smoke/fog band sitting directly behind it; crenellations are barely distinguishable, and the band erases any sky-to-hill transition behind the building.

**10-stronghold-approach-night** — No perceptible change.
*Remaining top defect:* the castle is a near-pure-black silhouette with two tiny window lights; nothing else (banners, wall detail, scale) reads at all — it does not register as "occupied," only as "dark shape."

**10-stronghold-courtyard-day** — No perceptible change.
*Remaining top defect:* banners are bright poster-red rather than the deeper oxblood in the keyart's stronghold panel; the NPC guard on the right has no readable Team Tether identity (insignia, coloring) beyond standing near the banners.

**10-stronghold-courtyard-night** — Changed, meaningfully better, but only inspectable with exposure lifted. At native brightness this frame is still overwhelmingly black in both rounds and the delta is nearly invisible. Boosting exposure ~4x for inspection shows round 4 added small point lights (a brazier/torch cluster lower-left, a warm light lower-right near the NPC) and the banners now carry a dim red glow instead of being flat black — the first frame in the set where "still Team Tether, still red" survives into night.
*Remaining top defect:* even boosted, the player's and the NPC's faces are unreadable silhouettes, the new lights are small hot spots that don't spread across the yard, and at the actual in-game exposure level (not boosted) the improvement is essentially imperceptible — this still fails "does the courtyard read at night" for a player who isn't examining a brightness-lifted crop.

**10-stronghold-gate-day** — Changed, better. A red pennant/flag was added atop the right-center tower, and a small hanging dark object (reads as a banner or lantern rig) was added off a beam on the left tower. These are the first "someone is here" details on the gate itself.
*Remaining top defect:* still no sentry figure, no lit window, no smoke — the wall mass itself is a flat, uniformly dark green-black repeating-brick surface that reads as an abandoned ruin rather than a garrisoned stronghold; two small props don't yet counter that.

**10-stronghold-gate-night** — No perceptible change. Too dark to tell whether the day's new pennant/hanging prop are even present; if they are, they don't register at this exposure.

**11-castle-landmark-hall-100m-day** — Changed, marginally better. The same red flag and hanging prop seen at the gate are visible here on the Hall's towers — a small saturated color accent that breaks up an otherwise monochrome dark silhouette.
*Remaining top defect:* the dark smoke/fog band still sits directly at and above the roofline, at essentially the same density as round 3, and still eats most of the value contrast that would otherwise separate the Hall's silhouette from the sky. One flag is not enough to read as "occupied, weathered stronghold" against that.

**11-castle-landmark-hall-200m-day** — No perceptible change. The Hall is already reduced to a small dark rectangle against the fog band; the new flag/prop are not resolvable at this size.

**11-castle-landmark-hall-400m-day** — No perceptible change. The Hall is a few dark pixels; it was not a legible landmark at this distance in round 3 and still is not in round 4. This gap is untouched by the patch.

---

## (A) Does the Warrens exterior now read as a burrowed earthwork/creature warren rather than a grey boulder pile?

**Not yet.** The recolor (brown rock, green moss caps) is a real and correct move away from "quarried grey stone," and it is applied consistently between the approach and standing shots. But nothing about the *shape* changed: it is still a cluster of uniform, smoothly-domed boulders at even intervals — the rubric's own description of a procedural, ungrounded prop cluster. A burrow needs an excavated read: a soil collar or dug lip around the entrance, an asymmetric mound instead of stacked domes, maybe root/dirt spill at the mouth. Until the shape changes, the palette fix reads as "a boulder pile that got mossier," not as an earthwork.

## (B) Does the Hall read as an occupied, weathered Team Tether stronghold with a legible silhouette at 100/200/400 m, and does the horizon band behind it still dominate?

**No, on both counts, though 100 m improved slightly.** A single red flag and a small hanging prop are the only new "occupied" signals added across three distances and both times of day — there is no smoke, no lit window, no visible figure on the walls in daylight, and gate-night shows no change at all. That is not enough incident detail to read as garrisoned rather than abandoned. Silhouette legibility: at 100 m the tower shapes are readable if you already know what you're looking at; at 200 m it is a small dark blob; at 400 m it is not a landmark at all — this is unchanged from round 3. And yes, the horizon smoke/fog band still sits at the same density directly behind and above the roofline at every distance, still flattening the value contrast that would otherwise let the dark stone silhouette separate from the sky. This was the single most-repeated defect across the Hall frames and the patch did not touch it.

## (C) Does the courtyard at night read at all (banners, people, faces)?

**Barely, and only under inspection, not at native exposure.** Round 4 added small warm point lights and gave the banners a dim red glow that is genuinely visible once brightness is lifted — banners now survive into night as "still red, still Team Tether," which round 3 did not achieve at all (round 3 boosted the same way shows only thin edge-highlights, no fill). But at the frame's actual exposure level the courtyard is still almost entirely black; a player looking at this frame without post-processing it would not perceive the change. Faces — player's or the NPC's — are not legible in either round, boosted or not.

---

## Three biggest remaining gaps vs. the references, ranked

1. **The Hall reads as a flat dark mass smothered by its own horizon fog, where the keyart's stronghold panel reads as a richly lit, weathered ruin with mechanical detail.** The board's Team Tether Hall panel shows visible vine growth on individual stones, multiple oxblood banners, torch-lit steps, and metal scaffolding/apparatus climbing the tower — texture and incident light doing the "occupied and dangerous" storytelling. The in-game Hall at 100/200/400 m (all three frames) is a near-silhouette with one flag; the smoke band that was flagged as a problem at baseline is present at identical strength in round 4. This is the frame the task specifically asks about and it is the least-changed of the set.

2. **The Warrens is still a procedural rock cluster, not a placed, excavated landform**, against Palworld's own landmark language (`palworld-04-plateau-landmark.jpg`) where rock strata vary in scale, vegetation grows unevenly out of real crevices, and the formation has an obvious "this place was carved by something" read. `04-warrens-approach-day` (round 4) still shows uniform, evenly-scaled boulder domes at regular intervals — the recolor changed the palette question but not the intentionality question the rubric singles out.

3. **Night at the stronghold does not register as a place**, where the keyart's own NIGHT inset shows a settlement with warm lit windows glowing distinguishably against dark hills and moonlit sky — atmosphere carrying the scene even in near-darkness. `10-stronghold-approach-night` and `10-stronghold-gate-night` are both still almost total black with only the moon and a zipline cable readable; the one lighting fix that landed (courtyard braziers) is invisible without post-boosting the image and doesn't extend to the other two night frames in the set.

---

## Bar questions

**A. Do these frames read as belonging to the world in `tetherbound-meadows-keyart.png`?**
**No**, specifically for the two landmark set-pieces this round targeted. The open meadow terrain in the approach/gate-day frames (rolling green hills, scattered oak-like trees, dirt path, wildflowers) is a fair match for the board's palette and mood. But the Warrens is still read as a boulder pile rather than the board's implied natural-burrow language, and the Hall — the board's single most detailed named panel — is a flat dark mass fighting its own fog band rather than the weathered, torch-lit, vine-grown stronghold the board draws. The pieces being graded are the weakest link, not the strongest.

**B. Shown these frames beside the Palworld references, would someone say it's trying to be the same kind of game?**
**No, for the frames that matter most here.** The open daylight meadow shots are in the right family for ground cover, palette, and scale, and would pass a casual side-by-side. But the courtyard-night and approach/gate-night frames read closer to an underlit, empty test level than to Palworld's bases and fields, which stay legible and populated-feeling even at night; and the Warrens' still-procedural rock cluster is the exact "looks generated, not placed" failure this project's own reference README calls out as the kind of gap worth chasing. Someone shown the night frames or the Warrens frame next to a Palworld screenshot would not say these are the same kind of game; someone shown only the daylight meadow-approach frame might.

### What's fixable in-scene vs. what needs new art

**Fixable by scene work (density, palette, lighting, composition, scatter):**
- Warrens entrance shaping — an asymmetric dug mound/soil collar around the den mouth instead of uniform boulder domes; scale variety between the boulders.
- Hall/gate incident detail — lit windows, a visible smoke wisp, more banners/flags reusing the prop that was just added, so "occupied" reads from more than one accent.
- Horizon fog band density/placement behind the Hall at all three distances — this is a scene/environment fog setting, not new geometry.
- Courtyard and approach night exposure — the round-4 brazier lighting proves the fix direction works; it needs to be strong enough to read at native exposure, and extended to the approach and gate night frames, not just the courtyard.

**Likely needs new art or a different asset, not just scene tuning:**
- A genuinely different Warrens rock-formation *shape* (not just material) if the boulder-pile massing itself is the wrong kit of parts for a burrow.
- Face/character readability at night may need a rim-light or minimum-visibility rule on the player/NPC rig rather than only more world lights, if point lights alone can't be pushed further without blowing out the banners.
