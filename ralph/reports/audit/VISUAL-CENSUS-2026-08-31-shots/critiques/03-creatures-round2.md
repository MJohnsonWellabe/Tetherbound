# Area 3 — creature roster — blind critique, round 2 (in-world roster rig, trainer as ruler)

Frames: `shots/census/03-roster-world/` — 70 PNGs from
`tools/_capture_creature_roster.gd`. Every creature, plus its `-rear` and
`-shiny` variants and the `galecrest-alpha`, photographed with the 1.80 m
trainer standing beside it as the `visual-judge` criterion-8 ruler, on one
shared camera. Round 2 is a **fresh** critic on a **different rig** from round
1's presentation frames — not a re-read of the same pictures.

This round named a large number of defects round 1 did not (the shiny hue-rotation
system, the whole measured scale table, `galecrest-alpha` floating off the ground,
the `pipwing` lineup/frame size mismatch, and the clipped-white / crushed-black
percentages against the references). By the convention's own stopping rule that
is **improvement, not convergence** — this area was still moving when the session
ran out of budget, and warrants at least one further round.

Verbatim below.

---

I have what I need. Here is the critique.

---

# Blind visual review — `shots/census/03-roster-world/`

## Method note on the measurements

All 70 per-creature frames are 1280×800 and share one camera: the trainer is **pixel-identical in every one of them** (I confirmed this by taking the per-pixel median across all 70 frames — the trainer comes out perfectly sharp, so he does not move). His bounding box is x 400–535, y 332–608, i.e. **276 px = 1.80 m**. The ground/sky boundary is row 443. Heights below are corrected for each subject's own ground-contact row and are good to about ±5%.

`00-lineup.png` uses a different camera (the trainer is 131 px there, feet at row 510), but the same horizon row, and when solved independently it agrees with the per-creature frames to within 2–4% on four of five subjects. So the numbers are cross-checked, not from one reading.

---

## Said first, plainly: the creature art

**This roster is not one game's creature line-up. It is at least four unrelated art treatments sitting on the same stage.**

Put these four frames next to each other:

- `06-trailpup.png` — a naturalistic grey wolf with a flat untextured coat (I measure mean saturation 0.34 and value SD 0.16 across its pixels — the flattest-shaded asset in the set), and a hard-edged green blotch decal stuck on its neck that follows no fur direction. This is a stock quadruped with a "make it Tetherbound" sticker.
- `12-brooktail.png` — a photo-accurate otter. No fantasy design language at all. It would pass unremarked in a nature documentary.
- `01-terrapup.png` — a chibi badger cub with 4:1 eye-to-face proportions and glassy teal irises.
- `03-galewisp.png` — a painterly white winged fox with translucent pale-green wing tips.

Palworld's roster in `palworld-01`, `-03` and `-04` is four different creature bodies rendered in one identifiable house style: soft form shading, flat bold colour fields, markings placed on anatomy. Nothing in this set shares a treatment with anything else in this set.

**The texture treatment that *is* shared is the wrong one.** Six unrelated species carry the identical hard-edged two-tone blotch mask over a base colour, with no fur grain, no gradient, no micro-detail: `07-burrowback.png` (green on black), `17-veridian.png` (gold on black), `13-galecrest.png` (cyan on white), `02-ripplet.png` (blue on white), `16-reedwing.png` (white on cobalt), `05-mudsnout.png` (dark on ochre). On `13-galecrest-alpha.png` you can see the mask's edges stair-stepping on the cyan legs — the mask texture is lower resolution than the model it wraps. This is the signature of an automated texture pass, and it is exactly what criterion 3 calls generator output.

**`04-bramblebun.png` has no face.** Zoomed in, the head is a smooth beige blob with no eyes, no nose, no mouth — two twig ears above it, and the body buried under overlapping bramble alpha cards with visible card intersections and scattered magenta specks that read as material error. This is a broken asset, not a stylistic choice, and it is the fourth creature in the roster.

**The trainer holds up better than most of the creatures.** The face, jacket layering and belt kit in the median plate are competent stylised character work, roughly in the neighbourhood of the archer in `palworld-02`. The hands are the weak point — bare pink mitts with fused stub fingers, and a hard cut where the sleeve meets the wrist.

---

## 1. Silhouette and readability at small size

I rebuilt the set as 96 px thumbnails from a matched crop. At that size:

- **`06-trailpup.png` disappears.** Its coat sits at mean value 0.34 against a ground of ~0.45 with an internal value SD of 0.16 — a grey shape on a grey plane with no interior structure. It is the least readable asset in the set.
- **`04-bramblebun.png` reads as a dead shrub**, not a creature.
- **`15-pipwing.png` is a white speck**, and `15-pipwing-rear.png` has literally no identifying feature — a fluff ball with a scaly cap whose texture boundary is a hard tiling seam.
- **`07-burrowback-rear.png` reads as a boulder.** No tail, no rear anatomy, black plate geometry on top. You could not tell it is an animal.
- **Four eggs.** `02-ripplet.png`, `14-duskhush.png`, `15-pipwing.png` and `16-reedwing.png` all resolve to the same upright ovoid silhouette. The key art's silhouette row exists as a variety check (rabbit / boar / deer / raptor / turtle / canine); these four collapse onto one shape.
- **What works:** `16-reedwing.png` is the single most readable small silhouette in the set — strong hue *and* value separation plus distinct legs. `08-meadowhart.png` and `09-tuskroot.png` also survive the shrink. `13-galecrest.png` reads as a raptor.

## 2. Colour and value structure

**There is no shared palette discipline.** Measured over creature pixels only, mean saturation runs from **0.12** (`03-galewisp.png`) and **0.13** (`15-pipwing.png`) to **0.85** (`10-paddlenewt.png`), **0.75** (`05-mudsnout.png`) and **0.73** (`16-reedwing.png`). For comparison, the key art's settlement panels sit at 0.38–0.43 and all five Palworld frames sit at 0.41–0.47. Palworld's *creatures* run 0.43–0.70 — so saturation itself is not the problem; the seven-fold spread across one roster is.

**Specific off-board colours.** The board's palette strip is 11 swatches; its most saturated is the gold (217,180,66) at S=0.70, and it contains no cyan at all. `10-paddlenewt.png` is rgb(18,171,193), S=0.91 — **70% of its pixels are more than 110 (L1) from any swatch on the board.** `11-mosshell.png`'s head is rgb(35,195,194), S=0.82. These same unexplained saturated cyans reappear on `13-galecrest.png`'s feet, connecting three unrelated species by a colour that means nothing.

**Clipping and crushing — this is the hard finding.** I sampled the reference creatures (Mammorest in `palworld-01`, Grintale in `palworld-03`, Lamball in `palworld-05`, the yellow pal in `palworld-04`) and **every one has 0.00% pure-white and ≤0.01% pure-black pixels**, including a white sheep. In these frames:

| frame | pure white (255,255,255) | pure black (0,0,0) |
|---|---|---|
| `14-duskhush-shiny.png` | **31.9%** | 2.2% |
| `03-galewisp.png` | **26.4%** | 0.7% |
| `02-ripplet.png` | **22.6%** | 2.6% |
| `07-burrowback-shiny.png` | 0.1% | **41.9%** |
| `07-burrowback-rear.png` | 0.0% | **39.2%** |
| `17-veridian.png` | 2.8% | **37.9%** |

A third of `14-duskhush-shiny.png`'s owl is a flat white cut-out carrying zero form information. Over a third of `17-veridian.png`'s stag is a hole. That is a material/lighting bug, not a look.

**Value against the backdrop.** In `17-veridian.png` the stag's neck and head (x 830–900, y 360–430) average value 0.200 against a backdrop of 0.220 — a 2% separation; only the pale antler tips keep the head on screen. `01-terrapup.png`'s left flank above the horizon measures 0.202 against the same 0.220. The backdrop is the rig's, but the near-black albedo is the asset's.

**The reserved danger colour has leaked.** `16-reedwing-shiny.png` renders a friendly duck in rgb ranging (55,8,17) → (106,37,46) → (182,42,64). The board reserves (67,35,45) for Team Tether banners; (106,37,46) is that hue at higher chroma. `11-mosshell-shiny.png`'s shell is a brick red at rgb ~(110,35,12) — adjacent to the same family. Whatever generates the shiny variants does not know the oxblood is spoken for.

## 3. Intentionality — authored or generated?

Reads generated, and the shiny system is the clearest evidence.

**`09-tuskroot-shiny.png` is strictly worse than `09-tuskroot.png`.** The base boar has three separated reads: brown body, green moss crest along the spine, ivory tusks. The shiny applies one flat hue rotation to every material slot at once, so the crest and the tusks both become the same mint green as the body and the internal silhouette collapses. The same failure is on `01-terrapup-shiny.png` (the green shoulder patch turns mauve — the "moss" motif becomes a random blob) and `17-veridian-shiny-rear.png`, where antlers, mantle and body all flatten into one ochre mass and the stag becomes markedly harder to read than the base.

**`13-galecrest-alpha.png` is `13-galecrest.png` scaled 1.39×.** Nothing else. No crest, no scars, no colour shift, no aura, no ground effect. Compare `palworld-03`, where the field boss Grintale is a distinct silhouette, a distinct colour and is throwing dust and sparks — a fight that looks like an event. This alpha is a big bird.

**The blotch mask** described above is the third piece of the same evidence.

## 4. Lighting

The rig is a single key from upper-left with a soft blob shadow cast to the right; direction is consistent across all 70 frames and every subject has one, so objects sit in one lighting world. That much works.

Two real defects:

- **No fill.** There is essentially no ambient/sky bounce, which is what produces the 38–42% pure-black readings on `07-burrowback.png` and `17-veridian.png`. Palworld's dark creature (`palworld-04`, right-hand pal, mean value 0.30) still carries form in shadow; these do not.
- **No contact occlusion.** In the `01-terrapup.png` foot crop the ground immediately under the paw is the same value as ground 20 cm away — the paws read as decals lying on the plane rather than objects resting on it.

## 5. Depth (partial — fog/horizon not answerable from this rig)

**`13-galecrest-alpha.png` floats.** Zoomed to the talons, there is clean lit ground visible *underneath and between every claw*, the rearmost right toe ends in mid-air, and the cast shadow sits well right and behind. The bird hovers a few centimetres off the plane. This is the only outright grounding failure I found, and it is on the roster's boss.

## 7. Artefacts

Each of these names a frame and a location:

- `04-bramblebun.png` — no facial features on the head; overlapping alpha-card intersections visible throughout the body; stray magenta specks around x 840–860, y 500–520.
- `05-mudsnout.png` — a leaf card on the crown (top of head, x ~800–840) shows a hard untextured white/grey backface fringe.
- `12-brooktail-rear.png` — the teal paddle tail is a different material and hue from the brown fur with a hard unblended seam at the rump (x ≈ 815, y ≈ 575); a stray red/orange dot at the tail base (x ≈ 832, y ≈ 600); and because the tail is invisible from the front in `12-brooktail.png`, the creature's named feature reads from exactly one angle.
- `17-veridian-shiny-rear.png` — a black see-through gap between the shoulder mantle and the neck (x ≈ 800–830, y ≈ 415–440); the tail is a leaf card on a bare thin stalk projecting horizontally from the rump.
- `08-meadowhart-rear.png` — the shoulder card-fan floats above the withers with a visible gap and hard edge (x ≈ 770–880, y ≈ 390–460) and reads as a **saddle** on a wild creature; the flank spots are a five-dot decal cluster with a visible boundary; no tail.
- `07-burrowback.png` — the grey plate on the spine reads as a rock prop clipped on rather than anatomy; the black fur carries a strong specular sheen that reads wet/plastic and matches nothing else in the roster.
- `09-tuskroot.png` — the moss crest is a flat green slab with a hard seam where it meets the back, not integrated growth.
- `13-galecrest-alpha.png` — the eye ring is a hard-edged painted green circle that reads as a texture mistake; the blotch mask on the legs is aliased.
- `15-pipwing.png` — the body texture is visibly low-resolution/blurred on the belly; the crest is a flat card with a cut-paper alpha edge.

## 8. Scale agreement — the most important criterion here

**Measured heights, tallest visible geometry, ruler = trainer at 1.80 m:**

| creature | height | width | vs trainer |
|---|---|---|---|
| `15-pipwing` | 0.77 m | 0.44 m | 0.43× |
| `05-mudsnout` | 0.97 m | 0.86 m | 0.54× |
| `04-bramblebun` | 0.99 m | 0.94 m | 0.55× |
| `12-brooktail` | 1.06 m | 0.64 m | 0.59× |
| `10-paddlenewt` | 1.17 m | 0.95 m | 0.65× |
| `06-trailpup` | 1.25 m | 0.61 m | 0.69× |
| `14-duskhush` | 1.28 m | 0.83 m | 0.71× |
| `11-mosshell` | 1.39 m | 1.52 m | 0.77× |
| `16-reedwing` | 1.51 m | 0.94 m | 0.84× |
| `07-burrowback` | 1.66 m | 1.49 m | 0.92× |
| `03-galewisp` | 1.90 m | 1.85 m | **1.06×** |
| `01-terrapup` | 1.92 m | 1.57 m | **1.07×** |
| `02-ripplet` | 1.93 m | 1.13 m | **1.07×** |
| `13-galecrest` | 2.05 m | 1.57 m | **1.14×** |
| `08-meadowhart` | 2.08 m | 0.81 m | **1.16×** |
| `09-tuskroot` | 2.08 m | 1.67 m | **1.16×** |
| `17-veridian` | 2.50 m | 1.92 m | **1.39×** |
| `13-galecrest-alpha` | 2.85 m | 2.02 m | **1.58×** |

**Defect A — there is no small tier.** Sixteen of seventeen species are ≥0.97 m; twelve sit inside a single 0.97–2.08 m band, a 2.1× spread that carries most of the roster. The median creature is ~1.4 m — chest height on the trainer. Only `15-pipwing.png` at 0.77 m is meaningfully small, and even it is thigh-high. Nothing in this set could sit on a shoulder, ride in a pack or scurry underfoot. `palworld-05` shows Lamball at roughly knee height beside the player; `palworld-02` and `-04` both have small pals and large ones in the same frame. The dynamic range here is compressed at the bottom.

**Defect B — the two starters are taller than the player.** `01-terrapup.png` (1.92 m) and `02-ripplet.png` (1.93 m) both exceed the 1.80 m trainer. `02-ripplet` in particular is designed as a pocket mascot — chibi 1:2 head-to-body, stubby mitts for hands, no fingers — and is rendered at human-plus height. The design and the transform disagree.

**Defect C — the cub outranks the adult.** `01-terrapup.png` and `07-burrowback.png` are both badgers. The chibi cub measures **1.92 m**; the naturalistic adult measures **1.66 m**. If these are a line, the young form is 16% *taller* than the mature form. If they are unrelated, then two badgers occupy adjacent roster slots at nearly the same size in opposing art styles. Either reading is a defect.

**Defect D — the alpha barely reads as one.** `13-galecrest-alpha.png` at 2.85 m is only 1.39× `13-galecrest.png` at 2.05 m, and 1.14× the ordinary `09-tuskroot.png` boar. A boss that is 14% bigger than a common field creature is not a boss you can see coming.

**Defect E — the same creature is two different sizes across frames.** `15-pipwing.png` measures **0.77 m**; the identical asset in `00-lineup.png` (confirmed by side-by-side crop — same crest, same cap, same feet) measures **1.05 m**. That is a 36% discrepancy, and it is an outlier: the other four lineup subjects reconcile with their own frames to within 2–4% (`01-terrapup` 1.92 / 1.92; `09-tuskroot` 2.08 / 2.12; `17-veridian` 2.50 / 2.54; `04-bramblebun` 0.99 / 1.04). Something applies a different display scale to this creature in the lineup.

**What is right:** `05-mudsnout.png` (0.97 m piglet) → `09-tuskroot.png` (2.08 m boar) is a clean 2.1× progression that reads correctly at a glance. `11-mosshell.png` at 1.39 m tall and 1.52 m wide is a properly imposing tortoise. `17-veridian.png` at 2.50 m genuinely towers over `08-meadowhart.png` at 2.08 m.

**A caveat on the ruler itself:** the trainer reads at roughly 5.5 head-heights including his hair volume, i.e. as an adolescent, not a 1.80 m adult. That is consistent with the key art's DAY/NIGHT panels and is not a defect in itself, but it means "1.80 m" is a declared number the model does not visually advertise, and everything measured against him inherits that ambiguity.

---

# Verdict

## The three things that most separate these frames from the references

**1. The roster has no house style, and the only thing it does share is an automated texture pass.**
`palworld-01`, `-03` and `-04` show a boar-thing, a whale-thing, a fox-thing and two bird-things that are unmistakably from one game: one shading model, one marking language, markings placed on anatomy. Here, `06-trailpup.png` (documentary wolf), `12-brooktail.png` (documentary otter), `01-terrapup.png` (chibi cub) and `03-galewisp.png` (painterly fantasy) share nothing — while `07-burrowback.png`, `17-veridian.png`, `13-galecrest.png`, `02-ripplet.png`, `16-reedwing.png` and `05-mudsnout.png` all share one hard-edged two-tone blotch mask with no grain beneath it. The set is simultaneously incoherent in design and uniform in the wrong way.

**2. A third of some creatures carries no shading information at all.**
Every reference creature I sampled — including a white sheep — has 0.00% clipped-white and ≤0.01% crushed-black pixels. `14-duskhush-shiny.png` is 31.9% pure white; `07-burrowback-shiny.png` is 41.9% pure black; `17-veridian.png` is 37.9% pure black. Palworld's creatures hold form in both their highlights and their shadows; several of these are flat cut-outs at one end or holes at the other.

**3. The size spread is compressed at both ends of the range that matters.**
Sixteen of seventeen species are ≥0.97 m, twelve fall inside one 2.1× band, both starters (`01-terrapup.png` 1.92 m, `02-ripplet.png` 1.93 m) are taller than the 1.80 m trainer, a cub (`01-terrapup`) outranks its adult (`07-burrowback`, 1.66 m), and the boss (`13-galecrest-alpha.png`, 2.85 m) is only 1.14× a common field boar. `palworld-05` puts a knee-high Lamball beside the player and `palworld-03` puts a Grintale that dwarfs him in the same game; that range is the readability that carries a creature-collecting game, and it is missing here.

## A. Do these frames read as belonging to the world of `docs/reference/tetherbound-meadows-keyart.png`?

**No.**

The board's own note is "vibrant, readable colours with a **natural** palette", and its eleven swatches top out at S=0.70 with no cyan anywhere. `10-paddlenewt.png` sits at S=0.91 with 70% of its pixels more than 110 units from any swatch on that board; `11-mosshell.png`'s head at rgb(35,195,194) and `16-reedwing.png`'s cobalt-and-yellow are the same story. At the other end `03-galewisp.png` (S=0.12) and `15-pipwing.png` (S=0.13) are nearly monochrome. The board's fifth reserved item — oxblood for Team Tether only — is broken by `16-reedwing-shiny.png`, which paints a friendly creature in that exact hue family.

The board's silhouette row (rabbit, boar, deer, raptor, turtle, canine) also acts as a variety check, and this roster fails it in one direction and passes in another: boar, deer, turtle, canine and raptor are all covered and covered well (`09-tuskroot.png`, `08-meadowhart.png`, `11-mosshell.png`, `06-trailpup.png`, `13-galecrest.png`), but the rabbit slot is `04-bramblebun.png`, which is faceless, and four separate species collapse onto one egg.

What carries: `08-meadowhart.png` is genuinely on-board — the leaf ears and small green antlers integrate the nature motif into anatomy instead of pasting it on, and its ochre/green sits inside the swatch strip. `09-tuskroot.png` and `11-mosshell.png` are close behind.

## B. Shown beside `docs/reference/palworld-0*.jpg`, would someone say these are trying to be the same kind of game?

**Yes — but only about half of these frames, and the half that isn't is loud.**

`01-terrapup.png`, `02-ripplet.png`, `03-galewisp.png`, `08-meadowhart.png`, `10-paddlenewt.png` and `13-galecrest.png` all read as monster-collector creatures standing next to a stylised anime-proportioned trainer; anyone would place them in the same genre as `palworld-04`. The trainer himself holds his own beside the characters in `palworld-01` and `-02`.

What sinks the "yes" from being unqualified: `06-trailpup.png` and `12-brooktail.png` are documentary wildlife with no design language, `07-burrowback-rear.png` reads as a boulder, and `04-bramblebun.png` is faceless. Palworld's weakest creature is still obviously *designed*; three of these are not.

## The split: what is fixable in the scene vs what needs art that is not in the build

**Fixable by changing scene/material/config — this is the work list:**

- **Every scale defect.** A/B/C/D/E in criterion 8 are transform values. Rebalance the roster so the small tier actually exists, drop the starters below 1.80 m, make `07-burrowback` larger than `01-terrapup`, push `13-galecrest-alpha` well past 1.39× (Palworld's field bosses read as 2×+), and fix the `15-pipwing` mismatch between `00-lineup.png` and `15-pipwing.png`.
- **The clipping and crushing.** 31.9% pure white on `14-duskhush-shiny.png` and 41.9% pure black on `07-burrowback-shiny.png` are albedo/exposure/fill problems. Add sky fill so dark albedos hold form; pull the shiny albedos back under 1.0.
- **The shiny system.** Stop applying one hue rotation across all material slots. `09-tuskroot-shiny.png` losing its tusks and moss crest into one green, and `17-veridian-shiny-rear.png` flattening antlers/mantle/body into one ochre, are both "recolour the fur slot only" fixes. Exclude the oxblood family from the shiny hue range so `16-reedwing-shiny.png` stops wearing Team Tether's colour.
- **Palette conformance.** Pull `10-paddlenewt`, `11-mosshell`'s head and `16-reedwing` back toward the board's swatch strip, and give `06-trailpup` and `12-brooktail` some value structure so they don't vanish at 96 px.
- **Grounding.** `13-galecrest-alpha.png`'s hovering talons and the missing contact occlusion under `01-terrapup.png`'s paws.
- **The clipped-on props.** `07-burrowback`'s spine plate, `09-tuskroot`'s moss slab and `08-meadowhart`'s saddle-reading card fan can be reseated and blended without new meshes.

**Needs art that is not in the build:**

- **`04-bramblebun` needs a face.** No scene change makes an eyeless creature read. This is a modelling and texturing job.
- **`06-trailpup` and `12-brooktail` need to be designed.** They are unmodified wildlife. Recolouring will not give them a place in a creature roster; they need the same treatment `08-meadowhart` got.
- **`07-burrowback` needs a rear.** `07-burrowback-rear.png` has no tail, no rear anatomy and no readable species. Half the model is missing.
- **The blotch mask has to be replaced with authored markings.** Six species sharing one procedural two-tone mask is a texturing pipeline decision, not a parameter — and it is the single biggest reason these read as generated rather than placed.
- **`13-galecrest-alpha` needs boss-specific art**, not a scale multiplier: a crest, a scar pass, a palette shift, an effect. `palworld-03` shows what that costs and what it buys.
- **Four egg silhouettes need to become three different shapes.** `02-ripplet`, `14-duskhush`, `15-pipwing` and `16-reedwing` cannot be told apart at distance, and silhouette is geometry.
