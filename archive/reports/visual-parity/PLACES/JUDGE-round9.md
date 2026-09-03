# Visual Judge — PLACES round 9 (vs round 8)

Blind review of `round9/locations/*.png` against `round8/locations/*.png`, `_sheet_r8_vs_r9.png`, and
`docs/reference/` (keyart + Palworld bar) plus `site/img/page-board.jpg`. No code/report/diff was read.

Pixel-diff check (`round8` vs `round9`, per-frame mean/max abs RGB delta) confirms every frame changed at
the byte level, but the deltas are consistent with cloud/foliage-shader animation and NPC micro-pose
drift, not authored fixes — the two new gate-face frames are the only genuinely new content this round.

## 1. Warrens slab / brow — **FAIL, unchanged**

`04-warrens-standing-day`: round8 and round9 are visually identical (0.63 mean diff, the lowest of any
pair checked — essentially camera-noise only). The pale, flat, rectangular slab is still there on the
right side of frame, roughly 70–95% across / 35–60% down: a light tan, stucco-textured plane with hard
rectangular edges standing alone among ferns, unconnected to any rock mass, reading as an unskinned
placeholder panel rather than a boulder. The dark "brow" boulder mass above the den mouth is still flat
near-black/very-dark-brown in both rounds — no stone tone, no visible form beyond silhouette. `approach-day`
shows the same boulder pile with the same flat brown material in both rounds. No change landed.

## 2. Hall up close — **FAIL, unchanged**

`10-stronghold-gate-day` and `11-castle-landmark-hall-100m-day` are pixel-for-pixel the same composition
in round8 and round9 (differences are cloud position / grass sway only — confirmed via side-by-side crop
at 2x). The Hall still reads as a near-black cutout with scattered pale rectangular highlights (window
slots) and blotchy green moss decals, not as weathered stone with joints and lit mid-tones. Sampling the
lit gate-wall face in round9 gives a mean luminance of roughly **70/255** for the small green/pink-lit
patch immediately over the arch, but the surrounding tower faces — the bulk of the silhouette — sit close
to 20–40/255, i.e. still reading as near-black at a glance and in the full-size frame. This is the same
in round8. 400 m (`11-castle-landmark-hall-400m-day`) still reads as a small, legible dark landmark
silhouette against the sky, unchanged and fine on its own terms — but that's the one distance where "flat
dark shape" is the correct answer, and it's not evidence the closer stands were fixed.

## 3. Sentries — **FAIL, not present**

`10-stronghold-gate-face-day` and `-night` are new this round (present only in round9, confirmed by
directory diff), so this is the first real test of the claim. At full resolution, neither frame shows a
human figure at either gate post. `gate-face-day` frames a close stone wall on the left and the gate
tower's flank on the right, with open ground between them — no guard model, no silhouette, nothing
posted at the arch. The only humanoid visible in the whole frame is a small blue-white figure far off to
the right near a rock outcrop, well away from the gate and not identifiable as a sentry (face/body/pose
illegible at that distance, and it's not at "the gate posts"). `gate-face-night` is almost entirely pure
black on the left (sampled mean luminance ~6/255) with one lit window on the tower face and the same
distant blue figure — again, no guard at the post. Compared against `10-stronghold-gate-day/-night`
(which also show no gate guards, in either round), there is no frame in this set where two sentries are
identifiable. Item fails outright — the feature this stand exists to verify is not visible.

## 4. Courtyard night — **PASS**

`10-stronghold-courtyard-night` (unchanged between rounds) does show a lit pool around the trainer: warm
brazier/torch light from the red banners and side stalls reaches roughly 2–3 m around the player,
the trainer model is clearly readable (pose, backpack, hair all legible), and there's a second lit pocket
on the right (an NPC beside a lit brazier/anvil table) that reads as an intentional prop cluster rather
than noise. The far background and most of the courtyard floor stay dark, but that reads as "dim
courtyard at night," not "black void" — there's enough falloff and secondary light to place the space.
Acceptable as-is.

## 5. Camps — **PARTIAL, unchanged from round8, ranked best→worst**

All three camps are pixel-identical in arrangement between round8 and round9 (differences are pose/cloud
noise); nothing was touched here this round.

1. **08-ridge-camp (best).** `fire-day`/`fire-night`: a real fire pit (rock ring, flame, smoke), a
   plank-and-log bench with an NPC seated on it, a stick tripod/rack, a grain sack, and a tent visible in
   the wider `standing-day` shot. Props sit at irregular angles and distances from the fire — reads as a
   used camp, and holds up passably at night with the fire as the readable anchor.
2. **09-waystop (middle).** `standing-day`: tent, firepit, and a bench cluster together off-center, with
   open ground to the right — legible as an occupied waystop but sparser than the ridge camp, and the
   fire ring itself is small/unclear at this distance (no visible stones or logs framing it, just a glow).
3. **05-relay-camp (weakest).** `standing-day`/`fire-day`: a bench, a supply crate, and a flagpole, but
   they read as scattered rather than clustered — the flag and crate sit apart from the bench and fire, a
   lot of bare trodden ground separates them, and the fire itself is barely visible/obstructed in the
   `fire-day` frame (mostly hidden behind the crate and flag in frame). Least "gathered around a fire" of
   the three.

None of the three shows obvious mirror-symmetry, so the "irregular, not mirrored" bar is met by all three
— the gap is furnishing density and fire-ring definition, not repetition.

## Regression sweep (all NEW frames vs PREVIOUS)

None observed. Every matched frame pair (29 of 31) is compositionally identical between round8 and
round9 — same geometry, same prop placement, same lighting rig — with differences fully explained by
cloud/foliage animation and small NPC pose drift. The two new frames (`gate-face-day/night`) add a camera
stand rather than changing anything at existing stands. No frame got worse.

## Score vs reference art

**Weak — roughly 3.5/10** against the keyart and the Palworld bar for this location set specifically
(not a whole-game score). The camps clear a real bar (occupied, irregular, legible at day and night). The
Hall — the single landmark this game is named around reaching a Palworld-plateau-shot ("Fable") level of
readability — still fails at 100 m and at the gate: it is a near-black shape with decal moss rather than a
lit stone structure with joints and weathering, identical to round8. The warrens slab defect and the
missing sentries mean two of the five named checks show literally zero movement from the previous round.

**Bar question A** (belongs to the keyart's world): partial at range (400 m silhouette, camps, warrens
approach all sit in the right palette/mood), no up close (the Hall's flat-black facade and the stray
placeholder slab in the warrens break the illusion the moment the camera gets close).
**Bar question B** (same kind of game as Palworld): no — Palworld's plateau/base shots show weathered,
fully lit stone and populated camps at all distances; these frames only reach that at the wide/approach
distance and fall back to flat, underlit geometry the moment the camera closes in, which is exactly where
items 2 and 3 were meant to test.

## MERGE / NEXT ROUND

**NEXT ROUND** — none of the round's three headline defects (warrens slab, Hall weathering, gate
sentries) show any measurable change, and the new gate-face stand confirms the sentries still aren't
there. Ranked remaining defects: (1) missing gate sentries at `10-stronghold-gate-face-day/night` — the
feature the new stand was built to verify isn't in frame at all; (2) Hall exterior still reads flat/near-
black at `10-stronghold-gate-day` and `11-castle-landmark-hall-100m-day` — needs actual lit stone material
with joints/weathering, not just moss decals; (3) unfixed placeholder slab + flat brow boulder in
`04-warrens-standing-day`; (4) relay-camp furnishing is the weakest of the three camps — cluster the fire,
bench, crate and flag together instead of spreading them across open ground.
