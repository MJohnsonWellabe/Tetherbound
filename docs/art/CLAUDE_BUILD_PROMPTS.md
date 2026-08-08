# Tetherbound — Meadows Claude Build Prompts

## Global art + implementation prompt

Use the supplied PNGs as the visual style target. Build creatures as stylized game-ready 3D assets for Godot, not as photoreal sculptures.

Shared requirements:
- appealing modern stylized PBR
- rounded organic anatomy plus a few strong angular silhouette breaks
- readable at third-person gameplay distance on ROG Ally
- large expressive eyes where appropriate, but not chibi
- simplified fur/feathers/scales built as modeled clumps or clean texture breakup rather than expensive strand systems
- 2K hero textures maximum for small/medium Pals; disciplined material count
- conventional clean quad topology where generated/retopologized
- skeletons designed for animation retargeting where practical
- separate attachment/helper bones only when gameplay needs them
- strong neutral idle silhouette
- no weapons or human-like clothing on normal wild Pals
- every Pal must look like it belongs to the same world as Terrapup, Ripplet, Galewisp, and the player-character reference
- export as GLB with correct Godot scale and transforms
- create LOD0 / LOD1 / LOD2 where practical
- store final source, exported GLB, textures, and provenance in an organized asset folder
- validate in Godot before considering the asset complete

Do not treat text rendered inside AI-generated PNGs as authoritative. Use this file for names/types/roles.

---

## 1. TERRAPUP — Ground starter

Use `01_Ground_Starter_Terrapup.png` as primary authority.

A small, sturdy Ground starter with badger/canine influence, warm brown-and-cream fur, oversized digging paws, stone mantle plates across the shoulders/back, and subtle moss accents. Friendly and loyal rather than aggressive. Approximate shoulder height 0.45 m. The silhouette must communicate defense and digging immediately.

Rig/animation minimum:
idle, walk, run, turn, hop, sleep, happy interaction, hurt, faint, directional quick attack, heavier charged attack, dig/scratch action.

---

## 2. RIPPLET — Water starter

Use `02_Water_Starter_Ripplet.png` as primary authority.

A playful small Water starter combining otter/newt qualities. Smooth turquoise skin/fur treatment, cream belly, translucent fin-like ears and tail fin, subtle pink inner-fin warmth, highly expressive dark-blue eyes. Approximate shoulder height 0.45 m. Balanced temperament and movement.

Rig/animation minimum:
idle, walk, run, swim loop, turn, sleep, happy interaction, hurt, faint, ranged quick-water attack, stronger charged-water attack, splash/emote.

---

## 3. GALEWISP — Air starter

Use `03_Air_Starter_Galewisp.png` as primary authority.

A small fox-bird glider with cream down, layered blue/teal feathers, enormous feathered ear tufts, wing-like forelimbs, feathered tail, and expressive blue eyes. Approximate shoulder height 0.45–0.5 m. Lightweight, alert, energetic silhouette.

Rig/animation minimum:
idle, hop/walk, run, glide/fly, land, perch, sleep, happy interaction, hurt, faint, directional quick attack, charged gust attack, playful spin.

---

# THE WILD ROSTER — READ THIS FIRST

The thirteen prompts below were written before the owner supplied the **Meadows
Wild Canon Pack**, and they were written from donor concept boards because no
wild reference sheet existed. Five do now, in `docs/art/reference/wild/`.

**For any wild creature, `docs/art/wild/` wins over this file** — names, types,
anatomy, palette, silhouette and the three distinction rules. See
`docs/decisions/D13`. These sections are kept for their animation lists and
gameplay roles, which the pack does not cover, and because a prompt is easier to
argue with than a blank page. Everything visual in them should be re-derived
from the sheet before it drives a generation.

Two structural corrections the pack makes, already applied here: **Ridgewolf is
retired** — "the canine evolves in Meadows" is named as a superseded assumption
— and **Tuskroot is not a base wild species**. It is the evolved form of
Mudsnout, the biome's only evolution, so it is listed after the wild roster
rather than inside it.

The shoulder-height figures in these sections are donor-board estimates of the
creature's biology. In-game height is one number per species in
`data/pals/species.json`, set by D12's peer scale and re-confirmed by D13.

---

# WILD GROUND ROSTER

## 4. BRAMBLEBUN — Ground rabbit

Design a compact meadow rabbit Pal, clearly distinct from Terrapup. Warm tan fur, pale belly, long expressive ears, broad hind feet, small burr/seedpod or earth-pattern accents rather than leafy Grass-type styling. Fast prey-animal silhouette but with enough personality to plausibly become a bonded companion.

Scale: ~0.35 m shoulder.
Combat read: evasive light Ground attacker.
Animation: idle sniff, hop locomotion, sprint, dig, kick/quick attack, charged dirt burst, hurt, faint, sleep, friendly nuzzle.

## 5. MUDSNOUT — Ground pig / rooting runt

Use `docs/art/reference/wild/02_Meadows_Wild_Ground_Sheet.png` as primary authority.

A young rooting piglet: broad pink snout disc, small emerging tusks, bristly coat caked with soil, a bristle ridge along the spine. Round, youthful and low-intensity — **not armoured**. It must read as the creature Tuskroot grew out of, so face, colour logic and ear shape carry forward into the evolved form.

Combat read: scrappy low-tier Ground attacker.
Animation: idle root/sniff, walk, trot, run, quick snout jab, charged shove, hurt, faint, sleep.

## 6. TRAILPUP — Ground canine

A lean prairie/coyote-inspired canine Pal. Sandy coat, darker back stripe, cream muzzle/chest, large upright ears, bushy dark-tipped tail, bright intelligent eyes. It should look adventurous and trainable, not like a real-world dog breed. **No stone plates anywhere on it** — the mantle is Terrapup's, and a wild canine that borrows it reads as the Ground starter.

Scale: ~0.55 m shoulder.
Role: mobile generalist. It does **not** evolve — that was Ridgewolf's premise, and D13 retired it.
Animation: canine locomotion set, sniff, sit, bark/howl, pounce quick attack, ground-burst charged attack, sleep, interact.

## 7. MEADOWHART — Ground rideable deer

A graceful but sturdy stylized deer/elk Pal designed as the first normal riding Pal. Warm tawny coat, cream underside, dark hooves, expressive face, compact branch-like antlers or horn structures incorporating subtle stone/earth growth. Saddle interface must work with the game's generic Riding Saddle.

Scale: ~1.35 m shoulder.
Role: first major traversal upgrade.
Animation: idle graze, walk, trot, run, sprint, jump, mount idle, mounted turns, skid/stop, quick antler attack, charged stomp, sleep.

## 8. BURROWBACK — Ground badger-like

A squat powerful digging Pal, visually distinct from Terrapup by being broader, lower, and more mature. Charcoal/brown coat with cream facial stripe, huge shovel claws, a few natural stone nodules on the back rather than a full stone mantle.

Scale: ~0.55 m shoulder.
Role: defensive Ground wild species.
Animation: waddle/walk, run, dig, defensive brace, claw quick attack, charged upheaval, sleep, faint.

---

# WILD WATER ROSTER

## 9. PADDLENEWT — Water frog/newt

A small amphibious Pal with a rounded salamander/newt body, bright aqua skin, cream underside, soft translucent crest/gill frills, webbed feet, and friendly eyes. Must work both on land and in shallow water.

Scale: ~0.3 m shoulder.
Role: early Water wild species.
Animation: idle breathe, four-legged scurry or frog-like hop, swim, paddle, tongue/head quick attack, water-burst charged attack, sleep.

## 10. MOSSHELL — Water turtle

A stylized pond turtle Pal with blue-green skin and a broad smooth shell carrying subtle pond-stone and moss textures. Keep Grass styling secondary; primary read is Water. Kind, patient personality.

Scale: ~0.45 m shell height.
Role: tanky Water species.
Animation: walk, swim, retract/brace, bite or water quick attack, shell-spin/water charged attack, sleep, faint.

## 11. BROOKTAIL — Water otter

A cheerful semi-aquatic mammal Pal: streamlined otter-like torso, broad useful beaver-inspired tail, chestnut-and-cream fur, small aqua accents around tail/paws. Avoid making it simply a realistic otter.

Scale: ~0.5 m shoulder.
Role: fast balanced Water Pal; natural candidate for later swim utility.
Animation: quadruped land locomotion, swim, float, tail slap quick attack, charged wave, play, sleep.

## 12. REEDWING — Water/Air waterfowl

A stylized duck/goose/heron-inspired water bird with teal-blue primary feathers, cream chest, warm tan accents, webbed feet and broad readable wings. It must read as genuinely dual Water/Air rather than a generic bird painted blue.

Scale: ~0.65 m standing height.
Role: first clear dual-type ecology example.
Animation: walk/waddle, run, takeoff, fly, land, swim/float, wing quick attack, charged water-gust attack, sleep.

---

# WILD AIR ROSTER

## 13. PIPWING — Air small bird

Tiny round meadow songbird Pal with cream body, sky-blue wings, dark wing tips, oversized expressive eyes and a small crest. Strong silhouette even at small screen size.

Scale: ~0.25 m height.
Role: common early Air species / energy-focused.
Animation: hop, short flight, sustained flight, perch, peck/gust quick attack, charged gust, sleep.

## 14. DUSKHUSH — Air owl

A medium owl Pal used as the Meadows nocturnal species. Soft gray-blue and warm cream plumage, large luminous-looking eyes without literal glow, ear/feather tufts, broad silent wings. Calm and mysterious rather than spooky.

Scale: ~0.55 m height.
Role: nocturnal Air specialist.
Animation: perch idle, head turns, hop, takeoff, flight, land, talon/gust attack, charged air attack, sleep/fold-wing rest.

## 15. GALECREST — Air hawk/eagle

A larger raptor Pal with confident silhouette, layered slate-blue/cream feathers, gold/tan accents, broad wings and strong talons. Powerful but still within the same friendly stylized design language. It must read as a serious predator and **not** as Galewisp, the cute fox-eared glider.

Scale: ~0.8 m standing height; large wingspan.
Role: rarer offensive Air wild species.
Animation: ground idle, hop, takeoff, flight bank, dive, land, talon quick attack, charged wind dive, hurt, faint, rest.

---

# THE ONE EVOLUTION

## 16. TUSKROOT — Ground armoured boar, evolved from Mudsnout

Use `docs/art/reference/wild/05_Meadows_Wild_Scale_Palette_Implementation_Guide.png` as primary authority. That file is misnamed: it is Ground Sheet B, not a scale guide.

The evolved form of Mudsnout and the only evolution in the Meadows. A heavy stocky boar with a low center of gravity, long curved ivory tusks, coarse warm-brown fur, darker ear/leg points, thick stone plates over shoulders and back with moss in the seams. It must read as **Mudsnout grown up** — preserve the face, the colour logic and the eyes — and it must not be realistic-wild-boar ugly.

Scale: ~0.75 m shoulder.
Combat read: bruiser / charge attacker.
Animation: walk, trot, run/charge, root/sniff, quick headbutt, charged ground slam, hurt, faint, sleep. Must support evolution continuity with Mudsnout.

The player never meets a wild Tuskroot. It exists only as something a Mudsnout becomes, which is what the ceremony around it has to earn.

---

# HUMAN CHARACTERS

## 17. GRANDPA ELIAS

Use `09_Grandpa_Reference.png` as visual direction, but keep Tetherbound lore authoritative.

Grandpa is a former trainer who is now too old to travel as he once did. He lives with the player and entrusts them with one of the three unique starters. He should look like a retired explorer/trainer, not a wizard or warrior.

Design:
- late 60s to 70s
- warm expressive face
- white/gray hair and beard
- weathered but healthy
- practical layered outdoors clothing in brown, cream and muted green
- sturdy boots
- walking stick acceptable, but not a combat staff
- old field satchel / keepsake gear
- no armor or weapon
- silhouette should visually relate to the player's explorer clothing so it feels plausible the player learned from him

3D:
standard humanoid rig compatible with the player-character skeleton where practical.
Animations: idle, walk, sit, talk gestures, laugh, concerned, point/explain, hand starter to player, interact with Pal, rest.

## 18. WARDEN OF THE MEADOWS

Use `10_Warden_Reference.png` for silhouette/color inspiration, but make the character unmistakably Team Tether rather than a fantasy forest priestess.

The first regional Warden is a skilled trainer commanding the industrialized sacred/natural Meadows stronghold. The character should embody the design tension: reverence for natural power combined with belief that Team Tether must control it.

Design:
- adult, composed, formidable
- elegant long coat / field uniform in deep forest green, charcoal, cream and restrained brass
- Team Tether insignia / hardware
- botanical/sacred-site motifs integrated into an otherwise practical organization uniform
- no personal combat weapon; any staff-like object is a ceremonial control/tether interface, not a melee weapon
- confident, controlled posture
- sympathetic enough to support nuanced writing, not cartoon-villain styling
- visually distinct from Grandpa and player

3D:
standard humanoid rig.
Animations: idle command stance, walk, dialogue gestures, deploy Pal, recall Pal, frustrated defeat, stronghold control interaction, story-scene poses.

---

# 19. VERIDIAN STAG — Ground Legendary

Use board `06` as the strongest silhouette direction; `11_Ground_Legendary_Reference.png` is a 358 px crop out of board `07` and is too small to drive generation.

**Terracrown** was this file's earlier production name for the same character. Board `06` names it the Veridian Stag, the owner picked that art, and the art carries the name — see `docs/art/REFERENCE_CANON.md`.

The Veridian Stag is the unique captive legendary freed after defeating the Meadows Warden. It voluntarily offers to join the player. It must be Ground type and provide a clearly superior version of riding traversal.

Concept:
A majestic ancient stag/elk-like earth guardian, far larger and more awe-inspiring than Meadowhart. Long branching antlers that resemble ancient roots and weathered stone, layered cream/tawny/earth-brown body, moss/lichen used only as environmental age accents, subtle turquoise/teal Tetherbound energy marks around chest/antlers/hooves. It should feel like a living piece of the Meadows, not a Grass deer.

Scale:
~1.8–2.0 m shoulder, dramatic antler height.

Silhouette:
immediately recognizable at long distance; elegant rather than bulky.

Legendary riding:
- substantially faster than Meadowhart
- huge jump / exceptional stamina
- generic Riding Saddle compatibility or special presentation that does not create species-specific saddle clutter
- camera and rider pose must remain comfortable on handheld

Animation:
majestic idle, graze/rest, walk, trot, gallop, legendary sprint, huge jump, land, rear, antler quick attack, ground-wave charged attack, roar/call, tethered exhaustion pose, freeing/recovery sequence, voluntary-join story pose, sleep/rest.

VFX:
restrained earth particles, dust, small floating pebbles or subtle teal energy only during charged moves/story moments. Do not bury the creature in particles.

---

# Production order for Claude

1. Lock visual scale chart with player, three starters, Bramblebun, Meadowhart, and the Veridian Stag.
2. Build/obtain representative production-quality meshes for the three starters.
3. Build one representative wild Ground Pal and one Water/Air Pal.
4. Validate combat readability in Godot.
5. Build remaining wild roster in silhouette families.
6. Build Meadowhart and riding.
7. Build Tuskroot, once Mudsnout exists to evolve out of.
8. Build Grandpa.
9. Build Warden.
10. Build the Veridian Stag only once the stronghold/release presentation can show it properly.
11. Record every sourced/generated asset and license/provenance in `docs/ASSET_LEDGER.md`.

Do not call a creature finished merely because it imports. Validate:
- third-person readability
- combat aiming readability
- animation quality
- material cohesion
- scale
- camera interaction
- performance on target hardware
