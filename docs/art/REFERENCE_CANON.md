# Reference canon — which art wins, and what each image is for

The Meadows art pack contains **four different rosters**. They contradict each
other on names, on types, and on which creatures exist at all. This file settles
which is authoritative, so the question is answered once instead of by every
agent that opens the folder.

It agrees with `docs/art/README.md`, written by the owner, which already says the
markdown wins: *"The image generator occasionally invented labels while rendering
the boards; those labels are not game-design authority."*

## The precedence rule

| Question | Answer comes from |
|---|---|
| Names, types, roles, scale, animation lists | `ROSTER_MANIFEST.md`, `CLAUDE_BUILD_PROMPTS.md` |
| Style, materials, proportion, rendering language | Sheets `01`–`04` |
| Silhouette and palette for species with no sheet | Boards `05`–`11`, **names and type icons discarded** |
| Anything still unresolved | `docs/GAME_DESIGN.md` §26 |

**The Meadows has three types: Ground, Water, Air.** Boards `05`–`08` show Grass,
Fire, Electric, Fairy, Normal and Rock. Those types do not exist in this game.
Never infer a mechanic, a type, or a species name from an image.

## What each file is

### Production sheets — the style target

1491×1055, four-view turnarounds with colour/material swatch strips, expression
rows, silhouette rows, scale charts against the 1.75 m trainer, and build prompts
printed on the sheet. These define what "a Tetherbound creature" looks like.

| File | Character | Key facts |
|---|---|---|
| `01_Ground_Starter_Terrapup.png` | **Terrapup**, Ground starter | Badger/canine. Warm brown fur, cream face and chest, stone-grey mantle plates over shoulders and back, restrained moss, oversized digging paws, dark pads, teal eyes. ~0.45 m shoulder, ~0.75 m body, 18–22 kg. |
| `02_Water_Starter_Ripplet.png` | **Ripplet**, Water starter | Otter/newt. Turquoise skin, cream belly, translucent ear frills with pink inner membrane, translucent tail fin, teardrop markings, dark-blue eyes. ~0.45 m shoulder. |
| `03_Air_Starter_Galewisp.png` | **Galewisp**, Air starter | Fox-bird glider. Cream down, layered blue/teal feathers, tan accents, enormous feathered ear tufts, wing-membrane forelimbs, feathered tail. ~0.45–0.5 m. |
| `04_Main_Character_Style_Reference.png` | **The trainer** | 1.75 m, 6.25 heads. Teal jacket, cream shirt, dark pants, brown leather, orb holder at the belt, canvas backpack. 20–35k tris, 2048², standard humanoid IK rig. |

Sheet `04` is the reason the creatures and the human read as one game. Any
character work checks against it for material language and proportion, not only
against its own sheet.

### Donor boards — silhouette and palette only

`05`, `06`, `07` are three separate earlier explorations. They disagree with each
other as much as they disagree with the manifest: three different starter trios
(Leafin/Sparkit/Aquaffin, Leaflet/Floafluff/Sparkit, Florabit/Pyrill/Aquabit),
three different Grandpas, three different Wardens, two different legendaries.
`08` is a fourth roster again (Hopplet, Leafin, Petallum, Bobble, Puddlefin,
Sproutox, Woolet, Breezee, Scirch, Craglet).

`09`, `10`, `11` are 358 px crops lifted out of board `07`. They are the only
dedicated art for Grandpa, the Warden and the legendary, and they are too small
to drive image-to-3D. Board `07` is itself only 1536×1024, so re-cropping at
native resolution recovers nothing. **These three characters need proper
`01`–`04`-quality sheets made before their production starts.**

## Donor mapping

Every roster entry, and where its visual source comes from. Fifteen of the
nineteen have no sheet of their own, so this table is what stops them being
invented twice.

| # | Roster entry | Type | Sheet | Donor | Override required |
|---|---|---|---|---|---|
| 1 | Terrapup | Ground | `01` | — | none |
| 2 | Ripplet | Water | `02` | — | none |
| 3 | Galewisp | Air | `03` | — | none |
| 4 | Bramblebun | Ground | — | Hopplet `08`, Hopperoo `06`, Hoppip `05` | Ground, not Normal. Burr and seedpod accents, **no leafy Grass styling**. ~0.35 m. |
| 5 | Tuskroot | Ground | — | Craglet `08` for the stone vocabulary | No boar donor exists. Build the anatomy from the brief; take stone-plate language from `01`. Appealing, not realistic-boar ugly. ~0.75 m. |
| 6 | Trailpup | Ground | — | Floxie `05`, Sparkit `06` | **Strip Electric and Fire entirely.** Sandy coat, dark back stripe, cream muzzle, oversized ears and paws. ~0.55 m. |
| 7 | Ridgewolf | Ground | — | Trailpup, matured | Same individual after evolution — preserve face, colour logic, eyes. Taller, longer-legged, neck ruff, emerging stone ridges. **Not an armoured monster.** ~0.95 m. |
| 8 | Meadowhart | Ground | — | Veridian stag `05`/`06`/`07` | Tawny, not green. Compact antlers. Scale to ~1.35 m so Terracrown still reads as larger. Generic saddle interface. |
| 9 | Burrowback | Ground | — | `01` read as an adult | Broader, lower, more mature than Terrapup. Charcoal/brown, cream facial stripe, huge shovel claws, **loose stone nodules, not a full mantle** — it must not look like grown-up Terrapup. ~0.55 m. |
| 10 | Paddlenewt | Water | — | Aquabit `07`, Pondlet `05`, Dewcale `06` | Aqua skin, cream underside, translucent gill frills, webbed feet. ~0.3 m. |
| 11 | Mosshell | Water | — | Sproutox `08`, Leafin `08` | **Water primary, moss strictly secondary.** Both donors are Grass turtles; blue-green skin and pond-stone shell are the correction. ~0.45 m shell. |
| 12 | Brooktail | Water | — | Bobble/Puddlefin `08` palette only | No otter donor. Take material language from `02`. Otter torso, beaver tail, chestnut and cream, aqua accents. ~0.5 m. |
| 13 | Reedwing | Water/Air | — | Breezee `08` | Must read as **genuinely dual-type**, not a bird painted blue. Teal primaries, cream chest, tan accents, webbed feet. ~0.65 m standing. |
| 14 | Pipwing | Air | — | Skytuft `05`, Breezee `08` | Tiny, round, cream body, sky-blue wings, dark tips, small crest. Silhouette must hold at ~0.25 m. |
| 15 | Duskhush | Air | — | `03`'s feather treatment | No owl donor. Grey-blue and cream plumage, ear tufts, broad wings, large eyes **without literal glow**. Calm, not spooky. ~0.55 m. |
| 16 | Galecrest | Air | — | `03`'s feather treatment | No raptor donor. Slate-blue and cream layers, gold accents, broad wings, strong talons. Powerful but inside the same friendly design language. ~0.8 m. |
| 17 | Grandpa Elias | — | `09` | `05`, `06`, `07` — consistent across all three | Retired explorer/trainer, late 60s–70s. Brown, cream, muted green layers. Walking stick, **not a combat staff.** Silhouette must relate to `04` so the player plausibly learned from him. |
| 18 | Warden Lyren | — | `10` | `05`, `07` silhouette and green/brass palette | **Team Tether field uniform, not a fantasy forest priestess.** Long coat in forest green, charcoal, cream, restrained brass. Insignia and hardware. Any staff is a ceremonial tether interface, **never a weapon.** |
| 19 | Terracrown | Ground | `11` | `05`, `06`, `07` stag boards for silhouette and antler mass | **Ancient Ground guardian, not a Grass deer.** Antlers of weathered root and stone. Cream/tawny/earth body. Moss only as age. Subtle teal Tetherbound energy at chest, antlers, hooves. 1.8–2.0 m shoulder. |

Rows 17–19 carry the heaviest overrides because their donor art is the furthest
off-brief. `CLAUDE_BUILD_PROMPTS.md` names two of them itself: the Warden must be
"unmistakably Team Tether rather than a fantasy forest priestess", and Terracrown
must "feel like a living piece of the Meadows, not a Grass deer."

## Where these files live, and why

Under `docs/`, which carries a `.gdignore` and is excluded by both Windows export
presets (`exclude_filter="docs/*, *.md"`). At the repository root — where they
were first committed — Godot imported them and they shipped inside
`Tetherbound.exe`, about 24 MB of concept art in every build.

`ChatGPT Image Aug 7, 2026, 10_30_03 PM.png` was a byte-identical duplicate of
`04` and was deleted.

The re-uploaded `Tetherbound_Meadows_Art_Pack.zip` was verified byte-for-byte
identical to these files. There is no higher-resolution copy of `09`–`11`.

## Relationship to `docs/reference/`

`docs/reference/` holds the **world** target: the Meadows key art board, whose
palette is sampled into `data/config/palette.json`, and the five Palworld
screenshots the owner set as the quality bar.

`docs/art/reference/` holds the **character** target.

The visual critic (`.claude/skills/visual-judge`) judges the world against the
first and creatures against the second. Neither replaces the other.
