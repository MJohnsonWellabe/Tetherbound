# Visual Parity Judgment — PLACES Round 6

Blind judge pass. Read only: `.claude/skills/visual-judge/SKILL.md`, `docs/reference/*` (keyart + palworld-0*.jpg, palworld-02 taken as the warren/cave-mouth reference), `site/img/page-board.jpg`, and the round5/round6 frames. No code, diffs, or reports were read. All judgments at native exposure (crops enlarged for inspection only — no brightening).

Standing owner verdicts respected as given: Warrens INTERIOR (den) is GOOD and must stay unchanged; Hall/stronghold and Warrens EXTERIOR were BAD at baseline.

---

## Per-frame: round5 → round6

**04-warrens-approach-day** — Changed, mixed. The rock mound reads slightly more monolithic/uniform brown in r6 (fewer visible pale rock caps, a bit less faceted variety than r5). More importantly, r6 introduces a new defect: a stark, hard-edged white/light-grey angular "bowtie" patch sitting directly above the door, roughly 2m wide, that reads as a mismatched texture or a stray piece of geometry rather than exposed stone — it has none of the moss/weathering of the boulders around it and its silhouette is too regular to be natural rock damage. **Top remaining defect: that white patch — it is the single most eye-catching thing in the frame and it reads as a bug, not a design choice.**

**04-warrens-den-day** — Unchanged (pixel-identical to r5 as far as this judge can tell). Correct per the standing verdict — this shot must not have moved, and it hasn't. Still the best-looking location in the set: warm mottled granite walls, real beam shadows, readable creature silhouette. **No defect worth logging.**

**04-warrens-standing-day** — Unchanged. The grey mottled-granite threshold wall matches the den's wall material and tone almost exactly (same stone family, same speckle scale). This is the one place in the Warrens where "exterior meets interior" already reads as one build. **No defect worth logging**, though the shot is dark enough that the cave interior beyond is largely silhouette.

**10-stronghold-approach-day** — Essentially unchanged. Same castle silhouette, same tree line, same pylon. The storm band over the Hall is fractionally lighter in value than r5 but occupies the same slice of sky. **Top remaining defect: nothing new here; carries over the Hall's storm-band problem (see below).**

**10-stronghold-approach-night** — Unchanged. Moon, tree silhouettes and castle massing read the same as r5.

**10-stronghold-courtyard-day** — Changed, roughly a wash. The banners are visibly less saturated / more orange-terracotta in r6 than in r5 (sampled: r5 cloth ≈ #7a1b24/#51040c, a fairly saturated blood-red; r6 cloth ≈ #954c3e/#6a241d, warmer and more washed-out). Composition, floor, NPC placement all unchanged. **Not clearly a fix — the daylight banner reads less like "oxblood" than it did in r5, more like weathered brick/terracotta.**

**10-stronghold-courtyard-night** — Improved. The floor now shows visible plank/stone texture under and around the trainer instead of going to near-black; the brazier on the right throws real warm light across the ground; the grunt NPC on the right is now a readable silhouette with a visible weapon instead of a near-invisible blob. Banners are the brightest, clearest element in both versions. **Remaining defect: the trainer himself is still close to a flat dark silhouette — jacket, hair and pack read as shape, not surface, at native exposure.**

**10-stronghold-gate-day** — Improved, with one clear fix. The dark floating object (a bell/lantern-shaped prop hovering disconnected above and left of the left tower in r5) is **gone** in r6 — that specific bug is fixed. Otherwise the gate reads the same: mossy dark-stone towers, salmon-pink twin doors, small orange sconce lights on the wall faces. **Top remaining defect: no identifiable sentries** — the only figures near the gate in r6 are a small tan quadruped creature and one indistinct dark upright shape half-swallowed by shadow just inside the arch that could be a guard or could be a wall detail; nothing reads as "a person is posted here."

**10-stronghold-gate-night** — Unchanged in composition; the same lack of identifiable sentries carries over, now worse because night lighting hides the arch interior almost completely. One lit window/sconce glow is visible on the right-hand tower face and small torch dots line the wall — those do read.

**11-castle-landmark-hall-100m-day** — Changed slightly, marginal. Storm band is a touch lighter (min row luminance ~124 vs ~111 in r5) but unchanged in vertical extent. At 100m the Hall itself reads clearly: twin square towers, a round turret with a conical cap, dark walls with a red banner accent — recognisably a ruined/occupied castle. The cluster of pale crystal-topped pylons and white flag/statue props at its base is busy and unclear at this distance (unclear whether these are meant to be readable Team Tether tech or just visual noise).

**11-castle-landmark-hall-200m-day** — Essentially unchanged. Silhouette is still legible as "castle with towers" — the two square towers and the turret are distinguishable — but wall detail, doors and banners are gone; it reads as a generic dark castle blob at this range rather than specifically the Hall.

**11-castle-landmark-hall-400m-day** — Slightly improved: the storm band is visibly lighter/hazier than r5's harder charcoal band, a real if small gain. The castle itself, however, is now barely more than a dark smudge with a faint turret bump — silhouette readability at 400m is poor in both versions, unchanged by the storm-band edit.

---

## (A) Warrens exterior — earth mound + threshold read

**Does it read as an earth mound with a dark mouth cut in, half-buried accent boulders and spoil, with threshold rock matching the den?**

Partially, and one part actively regressed. The overall silhouette — a rounded mass sitting on the hillside with a dark gap cut low in its face — does read as "mound with a cave mouth" at a glance, which is the right shape language. But:

- **The threshold match is good**: `04-warrens-standing-day` shows grey mottled granite that is convincingly the same rock family as `04-warrens-den-day`'s interior walls. This part of the ask is met.
- **The mound itself does not read as earth.** It reads as a pile of dark-brown low-poly boulders — a rock pile, not an earth-and-turf mound with rock breaking through it. There is no grass-over-dirt transition climbing the mound's flanks, no distinct "spoil" (displaced dug earth) at the base distinguishable from ordinary meadow grass, and only one or two isolated boulder chunks scattered on the approach — not enough to read as "half-buried accent boulders."
- **New defect, not present as such in r5**: the hard-edged white/grey patch directly over the doorway (detailed above) breaks the boulder read entirely — it looks like an unfinished or mismatched texture, not weathered stone, and it sits exactly where the eye lands first (centered over the door).

Net: threshold-to-den continuity is solved; the "earth mound with spoil" read is not yet there, and the round has added a new, very visible artifact at the doorway that needs to be fixed before this passes.

## (B) Hall silhouette and storm band

**Silhouette at 100/200/400m:**
- 100m: reads clearly as a specific structure — twin towers, round turret with conical roof, dark stone, a red banner accent. Matches the general shape language of the keyart's "Team Tether Stronghold" panel (dark ruined castle, arched entrance, banner drops).
- 200m: still reads as "a castle" — tower massing is distinguishable — but stops reading as *this* castle; it's a dark blob with two bumps.
- 400m: barely reads as a structure at all; a small dark smudge with the faintest turret hint. This is below the "landmark visible from distance" bar the game's own art direction notes set ("silhouettes and landmarks visible from distance").

**Storm band fraction of the day sky:** measured by row-luminance profile on the 100m frame, the dark band spans roughly y≈140–230 of a 540px-tall frame, against a sky zone running roughly y≈0–280 before the horizon haze/castle line. That's **roughly one-third of the visible sky's height** (≈32% of the sky zone, ≈17% of the total frame height). This is essentially unchanged in *extent* from r5 in all three distances — what changed is that the band's minimum brightness rose (r5 ≈111–117, r6 ≈123–134 on the same 0–255 luminance scale), i.e. it's a visibly lighter, hazier grey than before, most noticeably at 400m. The band still sits directly over the Hall in every shot and still dominates the middle third of the sky; this is a real but partial improvement, not a fix.

## (C) Courtyard night — floor, banners, people; banner colour sample

At native exposure, the floor around the trainer is **now legible** — a dark plank/stone texture with visible seams is visible directly under and a few metres around the player, where r5 went essentially to black in the same area. Banners read clearly in both rounds — they are the brightest, most legible object in the frame. People: the trainer is a readable silhouette (backpack, hair, jacket shape all distinguishable) but reads as shape rather than lit surface — no clear material read on cloth vs skin vs metal at this exposure. The Team Tether grunt on the right is more legible in r6 than r5: weapon, stance and rank silhouette are now visible where in r5 he nearly vanished into the dark background.

**Banner cloth colour sample** (courtyard-night, r6, sampled from flat cloth regions away from the white emblem and its glow):
- Upper cloth strip: RGB (38, 6, 13) ≈ `#26060d`
- Lower cloth strip (closer to the brazier's light): RGB (94, 17, 23) ≈ `#5e1117`

Both samples are dark, heavily red-dominant with low, roughly-equal green and blue — this is **oxblood/dark red**, not poster red. (For comparison, a "poster red" like crimson runs closer to RGB 220,20,60 — far higher red channel and higher overall value than anything sampled here.) The daylight courtyard sample of the same banners is warmer and less saturated (`#954c3e`/`#6a241d`) due to ambient bounce light, but even there the red channel never approaches poster-red territory — it reads as a sun-warmed terracotta/oxblood rather than a bright flag red. **Verdict: oxblood, confirmed by sampling, in both lighting conditions.**

## (D) Gate — floating prop, sentries, lit window/sconce

- **Floating prop: gone.** r5 had a distinct dark bell/lantern-shaped object floating disconnected in the air above and left of the left tower. It does not appear anywhere in the r6 day or night gate frames. This is a clean, confirmed fix.
- **Sentries: not identifiable.** No humanoid figure at the gate reads clearly as a posted guard in either day or night frames. The only moving/living thing visible near the arch in the day shot is a small tan quadruped creature; one dark upright shape just inside the arch might be a person but is too shadow-swallowed to identify as a sentry rather than a wall post or door frame element.
- **Lit window/sconce: present.** Small orange sconce points line the gate walls in both day and night shots, and the night shot additionally shows a warm lit-window glow on the right-hand tower face. This reads correctly in both lighting states.

---

## Ranked: the three things that most separate these frames from the references

1. **The Hall does not function as a landmark past 100m** (`11-castle-landmark-hall-200m-day`, `400m-day`). The keyart's own "Team Tether Stronghold" panel and the project's stated art direction ("silhouettes and landmarks visible from distance") both promise a structure you can navigate toward from far away; at 400m here it is a smudge, and the storm band sitting over it — even lightened — actively works against silhouette contrast rather than helping it. **Fixable by scene changes**: brighten/thin the band further or break its silhouette so the tower tops pierce it, and consider a stronger value/colour contrast on the tower silhouette itself (the keyart's castle is near-black against a warm sky — high contrast is what sells it at range; the compatibility renderer's version is close in *value* to its surrounding haze at 400m, which is what kills the read).

2. **The Warrens exterior reads as a boulder pile, not an inhabited earth mound**, and now carries a visible texture/geometry artifact at the doorway (`04-warrens-approach-day`). Palworld-02's cave-mouth reference and the keyart both show natural ground cover breaking against exposed rock, with the rock itself reading as one continuous weathered surface. Here the transition from grass to rock is a hard edge with no spoil or half-buried debris, and the pale patch over the door is the loudest single defect in this round's whole set. **Fixable by scene work** (turf decals overlapping the mound base, a few more scattered/half-sunk boulder props, redo or remove the mismatched patch) — this does not require new art, it requires dressing what's already there.

3. **Character and NPC presentation still doesn't hold up as "the point" the way Palworld's does.** Across the courtyard and gate shots, the trainer and the grunt NPCs remain flat, low-detail silhouettes even where lighting has improved (courtyard-night) — clothing reads as blocky shape, not tailored gear, and no NPC in these twelve frames is doing anything that reads as "a person with a job" the way Palworld's sentries, workers and trainers do in `palworld-05-base-building.jpg`. This is the gap that is **not fixable by scene changes alone** — it is a character-art/shading budget gap, not a placement or lighting one, and the rubric is explicit that stand-in art doesn't get a pass here.

## Bar questions

**A. Do these frames read as belonging to the world in `tetherbound-meadows-keyart.png`?**
**No, but closer at short range than at long range.** The palette (warm greens, oxblood banners, grey stone) is consistent with the board, and the den interior and courtyard-night are close in mood to the board's warm-lit, cozy-but-serious tone. But the keyart sells its landmarks — the stronghold, the standing stone, the tower — through hard silhouette contrast against open sky, and none of these frames achieve that past close range; the Hall dissolves into its own storm band by 200–400m, which is the opposite of what the board is doing everywhere it shows a landmark.

**B. Shown beside `palworld-0*.jpg`, would someone say these are trying to be the same kind of game?**
**No.** The environmental language (grass density, rock forms, gate architecture) is in the right neighbourhood, but the two things Palworld's own screenshots foreground — creatures and characters with real presence, and a world that reads as busy/lived-in with NPCs doing things — are both weak here. The trainer and grunts in these frames are flatter and less detailed than any human figure in the five Palworld references, and there is no frame in this set with the kind of creature-and-character density `palworld-01` or `palworld-05` shows. Environment dressing alone won't close this gap.

### What's fixable by scene work vs. what needs new art

**Fixable by scene/lighting/dressing changes** (no new art required): the Hall's silhouette-vs-storm-band contrast at range; the Warrens' earth/spoil dressing and the doorway texture defect; gate sentry placement (put a readable humanoid figure, even an existing rig, at the arch in worklight); daylight banner saturation drifting warm/orange.

**Needs art that isn't in the build**: the trainer's and NPCs' surface/material read under available lighting — this is a shading or asset-detail ceiling, not a placement problem, and no amount of re-dressing the Warrens or re-tuning the storm band will close it.
