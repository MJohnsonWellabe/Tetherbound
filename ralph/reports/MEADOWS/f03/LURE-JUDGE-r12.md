<!-- Code-blind judge (sonnet subagent) on 52 frames: walks_122a8efb bram/doss/juno/herd, vault 122a8efb (A) + vault_cleared_36d88a84 (B), hall_south_14e917a3. -->
# F03 lure visibility — verdict

Judged only the frames in `judge_f03/`. Criterion: from the ordinary road a player can notice a world-space lure (not a HUD marker) that draws them off it, and on approach that lure becomes readable as a specific place/thing, ending in the interaction prompt.

## bram (Old Bram)
- **Visible-from-road: PASS.** `bram_05_road-glance-before-exit.jpg` / `bram_06_lure-first-seen.jpg`: a huge armored badger creature sits close to the path, filling roughly the left third to half of the frame — impossible to miss.
- **Readable-on-approach: PASS.** The badger itself drops out of frame once the player turns down-path (`bram_07`–`bram_08`, plain grass), but a dark funnel-cloud-over-firelight beacon appears center-screen and grows steadily larger/closer across `bram_09_lure-first-readable.jpg` → `bram_10_approach-30m.jpg` → `bram_11_prompt-offered.jpg`, ending directly in the "Challenge Old Bram" prompt. Reads as a specific campsite to walk toward.
- **Overall: PASS.**

## doss (bank-perch repair)
- **Visible-from-road: PARTLY.** `doss_01_start.jpg`/`doss_03` show only forest, no lure. From `doss_04` on, the frames are dominated by unrelated interactables (an "Engage Duskhush" owl, then a "Chop" tree prompt) that occupy most of the screen. The actual doss beacon (dark funnel + firelight) is visible in `doss_06_lure-first-seen.jpg`–`doss_08_approach-30m.jpg`, but only as a small sliver in the upper-left, largely blocked by a foreground tree trunk in every shot.
- **Readable-on-approach: PARTLY.** The beacon barely changes size/position across 06→07→08 (minimap stays ~556–570 m the whole time despite being three "different" moments), then the frames jump straight to `doss_09_prompt-offered.jpg`, a close-up of an NPC ("Doss") and a fenced bank/perch with fire — with no intermediate mid-range shot showing that NPC or structure becoming readable. It's a hard cut from a tiny occluded smudge to the finished prompt.
- **Overall: PARTLY** (weak, obstructed silhouette; readability jumps rather than resolves).

## juno (Tether Patrol camp)
- **Visible-from-road: PASS.** `juno_09_lure-first-seen.jpg`: a dark funnel/firelight beacon is clearly silhouetted against open sky, unobstructed, in a wide meadow — small but unmistakable at distance.
- **Readable-on-approach: PASS.** `juno_13_lure-first-readable.jpg` and `juno_14_approach-30m.jpg` add visible oxblood/red banner-poles and a standing creature/figure at the camp; `juno_15_prompt-offered.jpg` shows the full scene up close — banners, a patrol NPC in dark armor, a stag-like creature, campfire — ending in "Challenge Tether Patrol." Clean progressive reveal.
- **Overall: PASS.**

## herd (Meadowhart herd)
- **Visible-from-road: PARTLY.** `herd_04_lure-first-seen.jpg` (00:10, night) shows small white deer-like silhouettes plus a firelight glow far off, but they're tiny, low-contrast against dark night sky, and the frame is dominated by an unrelated large badger creature and a hooded NPC ("Tobin") in the foreground that compete for attention and aren't part of this activity.
- **Readable-on-approach: PASS.** By `herd_09_approach-30m.jpg` and `herd_10_prompt-offered.jpg`, two distinct deer (Meadowharts) are clearly visible close to the player alongside the prompt "Watch the Meadowhart herd" — legible as the target once close.
- **Overall: PARTLY** (the herd itself is small/dim/cluttered at first sighting, even though it resolves well on approach).

## hall (Alpha Galecrest) — special attention per instructions
- **Visible-from-road: PARTLY, and the alpha's BODY does not show early.** `hall_10_lure-first-seen.jpg` (17:15) shows only a distant tower/pylon structure with energy lines — no creature at all. `hall_11` (17:25) shows a griffin-type creature close to the player, but the team panel identifies it as the player's own companion "Gale" (a Galecrest, same species as the target), not the alpha. `hall_12_lure-first-readable.jpg` (17:38) is the first frame carrying the name "Alpha Galecre..." floating over the towers — but still no creature body, just the tower and grass. `hall_13`/`hall_14` continue showing the floating name "Alpha Galecrest"/"ha Galecre..." over the towers with no alpha body present (a griffin is again visible in `hall_13`, again plausibly the player's own "Gale").
- **Readable-on-approach: PARTLY.** Only at `hall_15_approach-30m.jpg` (18:23, already essentially at the tower) does a griffin body appear near the name "Alph[a] Galecrest," and by `hall_16_prompt-offered.jpg` two griffins are on screen with the name partly obscured behind them ("You backed off."), so the specific alpha is hard to distinguish visually from an ordinary/companion Galecrest even at the prompt stage.
- **Overall: PARTLY, leaning weak.** The location (spire/tower encampment) and the floating nameplate are readable from a fair distance, which technically satisfies the letter of "nameplates floating in the world count." But the alpha creature's own body is not a visible-from-road cue at all — the only body on screen early is the player's own same-species companion, which actively invites misreading. This is the one activity where the lure is functionally name-text-only until near-melee range.

## vault (vaultA + vaultB, one activity)
- **Visible-from-road: PASS.** `vaultA_03_road-exit-glance-toward-lure.jpg` / `vaultB_03_road-exit-glance-toward-lure.jpg`: a distinctive earthen mound with a carved den archway and a wooden sign reading "THE BURROW WARRENS" is clearly visible at moderate distance (partly framed behind a foreground companion creature, but the den itself is unobstructed and legible).
- **Readable-on-approach: PASS.** Both walks continue into a lit den entrance with braziers (`vaultA_06`/`vaultB_06`), then deeper passages (`vaultA_08`/`vaultB_07`–`08`), ending in `vaultB_09_prompt-offered.jpg` with the guardian creature "Elder Trailpup" clearly visible at close range and the "Engage Elder Trailpup" prompt. vaultA (pre-guardian) and vaultB (post-guardian) show the same entrance and progression, consistent with covering the one vault activity end to end.
- **Overall: PASS.**

## Summary

| Activity | Visible-from-road | Readable-on-approach | Overall |
|---|---|---|---|
| bram | PASS | PASS | PASS |
| doss | PARTLY | PARTLY | PARTLY |
| juno | PASS | PASS | PASS |
| herd | PARTLY | PASS | PARTLY |
| hall | PARTLY (no body, name only) | PARTLY | PARTLY |
| vault (A+B) | PASS | PASS | PASS |

**LURES PASSING: 3 of 6 activities (activities: bram, juno, vault)**

Doss, herd, and hall each have a real weakness worth fixing: doss's beacon is too small/occluded and its readability jump-cuts to the finished prompt; herd's animals are too dim/small at first sighting and compete with unrelated foreground clutter; hall is the most serious — the alpha creature's own body is not visible from the road at all, only a tower structure and a floating name, and the only creature shown early is the player's own identically-styled companion, which undermines "readable as a specific thing" rather than supporting it.
