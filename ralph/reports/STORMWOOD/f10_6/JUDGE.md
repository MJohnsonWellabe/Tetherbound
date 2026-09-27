# Stormwood F10.6 — Visual Judge Report

Frames judged: `_sheet_7inch.jpg` (7-inch panel readability calls) plus the full-size
`explore/*.jpg` and `fight/*.jpg` (detail checks only). References: Bar A =
`tetherbound-meadows-keyart.png` + `stormwood-stormheart-tree-stronghold-board-a/b.png`;
Bar B = `palworld-01..05`.

## Device-profile read

**1. HUD text legible at 7-inch: MIXED — mostly yes, one clear no.**
- Objective card ("MAIN STORY / Find Ashfoot Waycamp.") — **yes**, in all six `explore/*` cells. High-contrast white-on-navy card with a gold rule; holds up small.
- Health/food bars ("100/100", "FOOD 100%") — **yes**, bottom-left in the explore cells; simple bar + percentage reads at a glance.
- Enemy name and level ("LEVEL 38 Voltarach", "LEVEL 41 Staticub") — **yes**, easily the strongest HUD element in the sheet; large centered white type, holds up even shrunk.
- Tell text ("! incoming — move", "it's open — hit it") — **yes**, in `hollows_alpha-tell2-b-mid.jpg` and `crown_guardian-tell1-b-mid.jpg` / `crown_guardian-tell2-f-recovery.jpg`; short, high-contrast, centered under the nameplate.
- Team list (Sparkit/Mudsnout/Bramblebun/Terrapup/Brooktail, "bond 0/5 Lv 42") — **no**. In every fight cell on the sheet (`hollows_alpha-00-before.jpg`, `hollows_alpha-tell2-b-mid.jpg`, `crown_guardian-i05.jpg`, etc.) this is five stacked rows of small type at low contrast (pale green on dark teal). At 7-inch size the "bond 0/5 Lv 42" portion of each row fuses into a grey smear; only the pet names stay legible. This is the one HUD element that fails the readability bar outright.
- Move buttons (Spark Bite / Arc Lash / No orbs / Switch) — **yes, marginal**. Legible in the sheet cells but tight: four labels plus icons in a small box bottom-right, the smallest comfortably-passing text on screen.

**2. Tells and danger legible: yes for the ring, marginal for the attack shape.**
- The lightning ground warning (magenta ring) — **yes**, unambiguous in `hollows_alpha-tell2-b-mid.jpg`, `hollows_alpha-tell2-e-impact.jpg`, `crown_guardian-tell1-b-mid.jpg`, `crown_guardian-tell2-f-recovery.jpg`. Saturated magenta against green grass is the single clearest signal in the whole set, at any size.
- The attack warning shape on the creature itself — **marginal**. In `crown_guardian-tell1-b-mid.jpg` the charge glow is so bright it blooms the bear itself into a near-white silhouette; you can tell "something is charging" but the bear's pose and the shape of the warning read as a generic flare, not a directional cue. In `hollows_alpha-tell2-b-mid.jpg` the same glow is more contained and easier to parse, so this is inconsistent between the two boss tells, not uniformly bad.

**3. Subjects legible: yes for fights, no for exploration.**
- In the fight frames, trainer + piloted creature (Sparkit) + opponent are each findable in under a second — daylight, green grass, strong silhouette separation (`hollows_alpha-00-before.jpg`, `crown_guardian-i05.jpg`).
- In every `explore/*` frame, **no**. The trainer is a near-black silhouette standing in near-black flowers/path under a near-black tree canopy (`forest_break.jpg`, `forest_calm.jpg`, `glass_break.jpg`, `glass_calm.jpg`, `rod_line_break.jpg`, `rod_line_calm.jpg`). At 7-inch size on the sheet the trainer is genuinely hard to pick out from the ground — the silhouette-vs-ground value gap is only a shade or two. This is a straight fail on this question for the exploration half of the sheet.
- Bonus scale note (not part of the four questions but relevant to subject-finding): `crown_guardian-i05.jpg` puts three visually-identical bears in frame — the engaged Staticub plus two more in the background — with no visual distinction beyond the HUD nameplate anchoring to one of them. First-look confusion about which bear is "the fight" is plausible.

**4. HUD keeps a safe area, doesn't cover key action: mostly yes.**
- Team list, objective card, and move buttons sit in the four corners and don't sit over the boss body in any frame.
- One partial exception: in `hollows_alpha-tell2-b-mid.jpg` and `hollows_alpha-tell2-e-impact.jpg` the enemy nameplate/HP-bar panel's bottom edge is close enough to Voltarach's raised front legs that the leg tips run up behind it. It's the legs, not the tell or the body mass, so it doesn't obscure the fight's key action, but it's tight enough to flag.

## Full verdict — defects by frame

- **`forest_break.jpg` / `forest_calm.jpg`**: Near-identical compositions and near-identical lighting despite one being tagged "Break · Sheltered" and the other "Calm" — nothing in the frame (rain density, sky brightness, particle effects) signals the difference the label claims. Trees are flat black silhouettes with no rim light or occlusion modelling, evenly spaced, reading as placed-on-a-grid rather than authored. Value range is crushed: almost the entire frame sits in one dark band except the pale flowers.
- **`glass_break.jpg` / `glass_calm.jpg`**: Same break/calm indistinguishability. Introduces teal glass/crystal spikes and a dark metal pylon/tower linked by a thin red cable across the sky — a hard-surface, faintly sci-fi silhouette language that does not match Bar A's warm timber-and-banner Stormheart language (board A/B: wood platforms, rope, warm lantern light, blue lightning *inside* the tree, not loose crystal spikes and cabling in an open field). The Stormheart Tree itself, the board's stated "landmark visible across the forest," is absent from the frame.
- **`rod_line_break.jpg` / `rod_line_calm.jpg`**: Same pair again — break and calm read as the same lighting state with a slightly different camera angle. The glowing gold crack in the ground (the "rod line") is the best-looking single element on the sheet: it is the only thing in the exploration half with real value contrast and a clear, legible shape, and it reads as authored rather than scattered. Everything else in these two frames repeats the flat-black-tree, crushed-shadow problem above.
- **`hollows_alpha-00-before.jpg`**: The strongest frame on the sheet. Bright, saturated grass green, clear silhouette separation between trainer, Sparkit, Voltarach and the distant frog-like creature at right, and a genuine value range (dark ground, mid green grass, bright sky). Team list text is the one weak spot (see device Q1).
- **`hollows_alpha-tell2-b-mid.jpg` / `-e-impact.jpg`**: Voltarach reads as a large, distinct, chunky hard-surface silhouette against the grass — the best-realized creature silhouette in the set. Its lightning-crack surface detail reads as a texture rather than a lit effect (flat, doesn't change with the tell), which is a minor artefact but not a readability blocker. Nameplate panel's bottom edge grazes the raised front legs (Q4).
- **`crown_guardian-i05.jpg`**: Three near-identical bear silhouettes in one frame with no differentiation apart from the HUD nameplate; the electric-crack pattern on Staticub's fur reads as a flat decal rather than a volumetric or emissive effect, especially visible here where the bear is otherwise naturalistically shaded.
- **`crown_guardian-tell1-b-mid.jpg`**: The charge-tell bloom is strong enough to wash the bear itself toward white, trading "you can see the bear's danger pose" for "you can see a bright blob." Contrast with `hollows_alpha`'s tell, which keeps the creature's silhouette intact through its own warning — the two bosses are not tuned to the same tell-legibility standard.
- **`crown_guardian-tell2-f-recovery.jpg`**: Clean recovery beat — bear, Sparkit, and trainer all separately readable, tell text legible, no complaints.

## Three biggest gaps versus the references, ranked

1. **Exploration lighting crushes the world's own subjects.** Bar A (both the Meadows keyart and the Stormheart boards) is built on a real value range — bright sky, sunlit canopy, dark ground shadow all present at once, with the tree readable from far away specifically *because* of that contrast. Every `explore/*` frame instead sits in one dark, low-saturation purple band where the trainer, the trees, and the ground are barely distinguishable from one another (clearest in `forest_break.jpg`/`forest_calm.jpg`). This fails device-profile Q3 outright and is the single largest gap from Bar A.
2. **The chapter's own signature landmark and its "Break" spectacle moment don't appear.** Board A/B sell the Stormheart Tree as a landmark "visible across the forest" and describe Break as this chapter's "lightning peak." None of the six exploration frames show the tree, and the three frames explicitly tagged `_break` are visually indistinguishable from their `_calm` twins — no extra lightning, brightness spike, or particle intensity marks the state the design calls the chapter's high point.
3. **Team-list HUD and the boss "charge" tell are under-tuned for a 7-inch screen relative to Bar B.** Palworld's equivalent (target/party UI, `palworld-01..03`) keeps party status compact and high-contrast even with several bars on screen at once. Here the five-row bond/level list fuses into noise at 7-inch size, and one of the two captured boss tells (`crown_guardian-tell1-b-mid.jpg`) blooms out the creature it's supposed to be telegraphing.

## Bar A — yes/no

**No.** What carries it: the "rod line" gold ground-crack (`rod_line_*.jpg`) and the fight-arena grass in `hollows_alpha-00-before.jpg` and `crown_guardian-i05.jpg` genuinely land the vibrant, readable natural palette the board calls for. What sinks it: the exploration half of the sheet is a near-monochrome dark-purple gloom with flat black trees, the opposite of the board's sunlit, high-value-range forest, and the board's headline landmark (the Stormheart Tree) is not in frame anywhere in this set. The teal crystal/metal-pylon dressing in `glass_break.jpg`/`glass_calm.jpg` also reads as a different material language than the board's warm wood-and-banner stronghold.

## Bar B — yes/no

**Partial — call it no.** What carries it: the two fight frames with full daylight and green grass (`hollows_alpha-00-before.jpg`, `crown_guardian-i05.jpg`) have Palworld's basic recipe — readable party HUD anchor, clear creature silhouette against grass, an event-scale boss. What sinks it: Palworld's own screenshots keep full value range and legible parties at all times, including in dim reference shots; nothing in this set is as dark and flat as `forest_break.jpg`/`forest_calm.jpg`/`glass_calm.jpg`, and Palworld's compact party UI stays legible at a glance in a way this build's five-row bond list does not. Someone shown the exploration frames beside the Palworld shots would clock the lighting and HUD density gap immediately.

## Split: scene-fixable vs needs-new-art

**Scene-fixable** (lighting/scene/UI tuning, no new assets required):
- Raise the ambient/fill light and reduce fog density in the forest exploration frames so the trainer, ground, and trees separate in value, not just the flowers.
- Differentiate Break from Calm visually (rain intensity, lightning flash frequency, sky brightness) so the two states the design names are actually distinguishable on screen.
- Shrink/simplify or raise the contrast of the five-row team list (drop "bond 0/5" to icons, or enlarge the level text) so it survives 7-inch scale.
- Cap or dim the charge-tell bloom on `crown_guardian`-style tells so the creature's silhouette survives its own warning, matching the better-behaved `hollows_alpha` tell.

**Needs new art / content, not a scene tweak:**
- The Stormheart Tree landmark itself isn't placed/visible from these vantage points — that's a level-layout or landmark-placement task, not a lighting pass.
- The teal crystal spikes and metal pylon/cable dressing in `glass_break.jpg`/`glass_calm.jpg` read as a different prop family from the Stormheart boards' warm timber language; reconciling that is an asset/art-direction decision, not a scene fix.
- Staticub's lightning-crack fur pattern reading as a flat decal rather than an emissive/volumetric effect is a shader/material change, likely beyond a scene-only tweak.

## TOP FIXES

1. **Light the exploration path.** The `explore/*` frames are the biggest single gap: raise ambient/fill and cut fog so the trainer and trees hold a real value range instead of one dark band — this is device-profile Q3's flat "no."
2. **Make Break look like the chapter's lightning peak.** Give the `_break` frames a visibly different sky/lightning/rain treatment from their `_calm` twins so the state the design calls out actually reads on screen.
3. **Compress the team-list HUD for 7-inch legibility.** The five-row bond/level list is the one HUD element that fails the readability bar outright; simplify or enlarge it before anything else in the HUD.

