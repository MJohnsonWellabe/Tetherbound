# Code-blind visual judgement — creature gear accent (f33-accent-r4)

I judged this only from the six PNGs in this folder (row_day, row_night, close_day, close_night, side_day, side_night). I read no source code, tests, docs or other files.

## 1. Per image

Creatures are numbered left to right as they appear on screen. The species is a brown/white badger-like quadruped with grey stone plates on its shoulders and back.

**row_day (08:00, normal camera, front)**
- C1: no band or glow. The fur and stone plates look the same as the base creature. **Ungeared.**
- C2: two thin, flat **gold/ochre** bands, one around the upper chest under the chin and one lower around the chest and forelegs. No glow. **Geared.**
- C3: two **green** bands in the same positions, slightly more saturated than C2's. **Geared.**
- C4: two **blue** bands. **Geared.**
- C5: two **violet/purple** bands. Where the bands wrap behind the body, they show past C4's flank. **Geared.**
- Rank guess: the colours run gold → green → blue → purple, which reads like a rarity ladder (common → uncommon → rare → epic), so C2 < C3 < C4 < C5. The order is not obvious on its own, though: many players will read gold as the *top* tier. Apart from colour, nothing (width, glow, extra parts) separates the tiers.
- No charm is visible on any creature.

**row_night (23:00, front)**
- C1: still bare. **Ungeared.**
- C2 to C5: the same bands, now lighter and more pastel (pale yellow, mint, light blue, lilac). They stand out against the darkened fur, so there seems to be some self-illumination. There is no bloom or halo. All four are still clearly visible and their colours can be told apart. Rank guess is the same as in the day shot.

**close_day (front, closer, C1 out of frame on the left)**
- The four visible creatures wear gold, green, blue and purple double bands. The bands sit across the chest and forelegs and run over the shoulder stone plates and the arms. Up close they read as a simple strap/hoop harness, not as a texture seam. They are plain uniform tubes with no buckles, so they look more like a generic ring than a crafted item. Eyes, muzzle, facial stripe and ears are all left clear.

**close_night**
- Same as close_day. The bands keep their colour and are the brightest saturated element on the bodies. The pink-lilac (top?) and light blue read well. The yellow is the weakest against the white chest fur, but it still shows.

**side_day (side view)**
- Only **one** creature is visible. It is seen from the side and partly behind the trainer and a cyan vertical beam (probably a waypoint marker). It shows **no band, trim or glow**: brown fur, grey stone plates and a small green tint on the back. **Ungeared**, or the gear is not visible from this angle. No geared creature can be seen from the side.

**side_night**
- The same single creature, dark, with no visible accent. **Ungeared / not visible.**

No accent anywhere is red or oxblood. The only nearby warm tones are the gold band and the brown fur.

## 2. Pass/fail against the criterion

| Sub-check | Result |
|---|---|
| Geared vs ungeared distinguishable, normal camera, day, front | PASS: C1 is plainly bare and C2–C5 are plainly banded |
| Same, at night, front | PASS: the bands get lighter and stay readable |
| Same, from the side, day and night | **FAIL / unproven**: the side shots show only one creature, which looks ungeared. No geared creature is shown from the side. |
| Different tiers distinguishable | PARTIAL: the four colours are clearly distinct, but tier is shown by hue alone, and gold sitting at the *lowest* tier goes against common rarity conventions |
| Reads as gear trim, not a texture glitch | PASS (weak): looks like a strap/harness; the bands are plain uniform tubes |
| Does not cover face/identity | PASS |
| No red/oxblood | PASS |
| Charm visible | Not observed in any frame |

## 3. Problem and single most effective fix

The main gap is the **side view**: neither side frame shows a geared creature, so "from the side" cannot pass. **Fix:** re-capture the side_day/side_night frames with a *geared* creature (ideally the top tier) placed side-on to the camera and not hidden behind the trainer or the waypoint beam. If the bands then turn out to be invisible from the side, add a band segment that wraps over the back/flank so the trim reads in profile.

Secondary issues: tier depends on hue alone and gold is at the bottom. Making higher tiers wider or adding a subtle emissive rim, and confirming that the charm actually renders, would make rank readable without needing to learn a colour key.

## 4. Verdict

**PARTIAL**

## Re-judgement of the side frames

I judged this only from the two recaptured PNGs (side_day.png and side_night.png). I read no code, tests or docs.

**side_day (08:00):** A single creature, seen fully side-on and facing left, with the camera at the other end of the row. It wears two **violet/purple** bands. One runs around the upper chest and shoulders and over the top of the stone back plates. The other runs lower around the belly and wraps the full length of the body to the hindquarters. The bands follow the body's outline, rising over the plates and dipping at the waist, so in profile they read as harness straps, not as a texture seam or a floating ring. The trainer stands in front of the lower forelegs only, so the bands, flank and head are unobstructed. The eye, muzzle, white face and ear are fully clear. This matches the top-tier (purple) creature from the front shots.

**side_night (23:00):** The same creature and the same framing. The bands turn pale lilac/pink and are the brightest saturated element on the darkened body, so they stand out more at night than by day. The face is clear and nothing blocks the bands.

| Sub-check (side) | Result |
|---|---|
| Geared creature's accent reads as gear trim from the side, day | PASS |
| Same, night | PASS |
| Unobstructed | PASS (the trainer covers only the lower forelegs) |
| Face/identity clear | PASS |
| No red/oxblood | PASS (violet by day, lilac by night) |

The recapture closes the side-view gap from my first pass.

### Updated overall verdict (front results from the first pass plus these side frames)

At the normal camera, a geared creature can be told from an ungeared one by day and at night, from the front and from the side. The four tiers have clearly different colours. The accent reads as harness trim, leaves the face clear and uses no red.

Remaining non-blocking notes:
- Tier is shown by colour only, and gold sits at the lowest tier, which players may read as the top.
- No separate charm is visible in any frame.
- The side view shows only one tier, so the side check proves gear-vs-ungeared visibility but not side-on tier comparison.

**Verdict: PASS**
