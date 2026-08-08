# Reference canon — which art wins, and what each image is for

> ## ⚠ The wild roster has moved. `docs/art/wild/` wins.
>
> The owner has supplied a **Meadows Wild Canon Pack** — five production
> sheets and four documents — and it is explicit: *"For the Meadows biome
> wild-creature roster, treat the art and documents in this folder as the
> current authoritative source of truth ... When a previous note or
> placeholder conflicts with this pack, follow this pack."*
>
> So for the **twelve wild species and the one evolution**, read
> `docs/art/wild/21_MEADOWS_WILD_ROSTER_CANON.md`, not the donor table below.
> The sheets are in `docs/art/reference/wild/`, and unlike boards `05`–`08`
> they are real turnarounds with palettes, scale charts and build notes — the
> same quality as sheets `01`–`04`.
>
> The pack explicitly does **not** cover the three starters, the legendary,
> Grandpa, the Warden or the player character. Everything this file says about
> those still stands, and all six are already produced.
>
> What the pack changed, and what it retired, is in
> `docs/decisions/D13-the-wild-roster-is-recanonised.md`.

It agrees with `docs/art/README.md`, written by the owner, which already says the
markdown wins: *"The image generator occasionally invented labels while rendering
the boards; those labels are not game-design authority."*

## The precedence rule

| Question | Answer comes from |
|---|---|
| Anything at all about a **wild** species or Tuskroot | `docs/art/wild/`, then its sheets in `docs/art/reference/wild/` |
| Names, types, roles, scale, animation lists for everyone else | `ROSTER_MANIFEST.md`, `CLAUDE_BUILD_PROMPTS.md` |
| Style, materials, proportion, rendering language | Sheets `01`–`04` |
| Silhouette and palette for the three characters with no sheet | Boards `05`–`11`, **names and type icons discarded** |
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

### The wild sheets — `docs/art/reference/wild/`

Five sheets, owner-supplied with the pack, at `01`–`04` quality: four-view
turnarounds, palette swatches, silhouette rows and build notes. They cover all
thirteen wild creatures, which is why the donor rows below are gone.

| File | Creatures on it |
|---|---|
| `01_Meadows_Wild_Roster_Master_Guide.png` | The whole roster at a glance. Overview, not a turnaround source. |
| `02_Meadows_Wild_Ground_Sheet.png` | Ground Sheet A — Bramblebun, Mudsnout, Trailpup |
| `03_Meadows_Wild_Water_Sheet.png` | Paddlenewt, Mosshell, Brooktail, Reedwing |
| `04_Meadows_Wild_Air_Sheet.png` | Pipwing, Duskhush, Galecrest |
| `05_Meadows_Wild_Scale_Palette_Implementation_Guide.png` | **Misnamed — see below.** Ground Sheet B — Meadowhart, Burrowback, Tuskroot |

`05_Meadows_Wild_Scale_Palette_Implementation_Guide.png` IS MISNAMED. It is
Ground Sheet B — Meadowhart, Burrowback and Tuskroot — not a scale guide. The
file name is the owner's and is left alone; this note is the correction. The
same correction is carried in `tools/art_pipeline/views.json`, which is where a
crop job would otherwise trust the name and cut the wrong band.

## Donor mapping

Every roster entry and where its visual source comes from. This table used to
be sixteen donor mappings, because sixteen entries had no sheet. It is now three:
the starters and the trainer have their own sheets, the thirteen wild creatures
have theirs, and the only characters still reading a figure off a concept board
are Grandpa, the Warden and the legendary.

| # | Roster entry | Type | Sheet | Donor | Override required |
|---|---|---|---|---|---|
| 1 | Terrapup | Ground | `01` | — | none |
| 2 | Ripplet | Water | `02` | — | none |
| 3 | Galewisp | Air | `03` | — | none |
| 4–16 | The twelve wild species and Tuskroot | Ground / Water / Air | `docs/art/reference/wild/02`–`05` | — | **None. Do not use a donor board for these.** Each has a real four-view turnaround; identity, palette, anatomy and the distinction rules come from `docs/art/wild/21_MEADOWS_WILD_ROSTER_CANON.md` and `22_MEADOWS_WILD_ROSTER_ART_MAPPING.md`. |
| 17 | Grandpa Elias | — | `05` turnaround (best available), `06` head close-ups | `07`, `09` | Retired explorer/trainer, late 60s–70s. Brown, cream, muted green layers. Walking stick, **not a combat staff.** Silhouette must relate to `04` so the player plausibly learned from him. |
| 18 | Warden of the Meadows | — | **`06`, used directly** | — | See the override note below. |
| 19 | Veridian Stag (Ground legendary) | Ground | **`06`, used directly** | `05`, `07`, `11` for antler mass | See the override note below. |

### What the wild rows used to say, and why it is worth recording

Rows 4–16 held thirteen donor mappings written when no wild sheet existed, and
several of them were load-bearing guesses that a builder would otherwise still
be following:

- **"No boar donor exists"** for Tuskroot, so its anatomy was to be invented
  from a text brief with stone language borrowed from `01`. Ground Sheet B draws
  it, and D13 makes it the evolved form of Mudsnout rather than a base species.
- **Meadowhart was to be built from the Veridian stag**, tawny instead of green.
  That is precisely the confusion the pack forbids: Meadowhart is drawn on its
  own sheet, "lighter, friendlier, more practical — less sacred", and must not
  share the legendary's visual language.
- **Bramblebun at ~0.35 m**, and every other centimetre figure in those rows.
  Those were donor-board estimates, not measurements. Creature biology comes off
  the sheets; **game** height comes from D12's peer scale, 1.20–2.60 m, which
  D13 re-confirmed. The two are different questions and neither is a fix for
  the other.
- **Mudsnout had no row at all**, because it did not exist yet, and Ridgewolf
  had one, because it did.

### The Warden and the legendary: overrides lifted

Rows 18 and 19 used to carry the heaviest corrections in this table — the
Warden was to be redirected away from board `07`'s "fantasy forest priestess"
and the legendary away from being a Grass deer.

**The owner has lifted both:** *"the final boss warden for this biome can come
from the reference art and so can the legendary."*

Board `06` is the source, and it is a better one than the boards those
overrides were written against:

- **The Warden of the Meadows** on `06` is not `07`'s Rooklyn. He is a male
  figure in a long dark-green Team Tether coat with a fur-lined collar, mask
  or visor, and a confident commanding stance — already the uniformed officer
  the override was asking for. Board `06`'s own note: *"The Warden commands
  Team Tether's Meadows outpost. Charismatic and ruthless in equal measure."*
- **The Veridian Stag** on `06` is the legendary, named. Antlers of wood and
  leaf, green foliage mane, nature-guardian bearing. Board `06`: *"Guardian of
  the Meadows. Its presence brings life to the land. It is said the forest
  itself moves when it walks."*

### Measured: how far each of these three references actually gets

Production has now tested this file's warning that `09`–`11` "are too small to
drive image-to-3D", and the answer is more specific than the warning was.

| | body | head |
|---|---|---|
| Grandpa Elias | board `05` crops carried it | board `06`'s head close-up carried it |
| Warden of the Meadows | board `06` carried it, via text-to-3D | **failed** |

The technique that gives these characters faces is to generate the head on its
own, so the whole polygon budget lands on it — a whole-figure pass spreads 30k
polygons over a standing figure and an eye socket comes out smaller than the
triangles available to describe it. That technique needs a clear head image as
well as the budget. Grandpa has one. The Warden does not: his only reference is
a figure on `06`, so a head crop is a ~165px region upscaled, and both
head candidates came back as unreadable lumps.

**The Warden is therefore the one character in the pack that still needs a
proper `01`–`04`-quality sheet made before he can be finished.** His body is
produced and in the game; his face is painted on and reads as a defect at
close range. The legendary did not need one — board `06`'s stag is large and
clear enough to have driven a usable model.

`ROSTER_MANIFEST.md`'s old production name **Terracrown** and board `06`'s
**Veridian Stag** are the same character. Veridian Stag is what the project
uses — the owner picked the art, and the art carries the name. The manifest and
`CLAUDE_BUILD_PROMPTS.md` have both been moved onto it; Terracrown survives only
where a document is explaining the rename.

The one thing still inherited from the old override: the legendary is the
**Ground** legendary per `GAME_DESIGN.md` §26 and `ROSTER_MANIFEST.md`. Board
`06` labels it Grass/Earth, and by this file's own precedence rule the markdown
wins on type while the image wins on looks.

## Deferred, deliberately: Sparkit

Board `06` carries **Sparkit**, an Electric fox kit — *"The Static Kit Pal.
Crackling with energy. It stores electricity in its fur and releases it in
quick bursts."* The owner likes the design.

**Do not generate Sparkit.** It is not part of the Meadows vertical slice:
`GAME_DESIGN.md` §26 gives the Meadows three types — Ground, Water, Air — and
an Electric creature would be the first crack in a locked type system that
`CLAUDE.md` forbids changing without a flag.

It is recorded here as a **future roster candidate**, so the design is not lost
and nobody has to rediscover it. When a biome exists that has a use for
Electric, Sparkit is already drawn.

The same applies to the rest of board `06`'s creatures — Leaflet, Floafluff,
Hopperoo, Dewcale, Petalynx. They were silhouette and palette donors for the
wild roster until the wild sheets arrived and made them unnecessary. None of
them is a species, and none of them should be reached for now that every wild
creature is drawn.

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
