# D3 creatures and D4 characters — blind pass, round 1

Two independent Fable critics, each given only a contact sheet, the frames and
`docs/reference/`, told nothing about what changed or what anyone hoped to hear
(`ralph/OWNER_DIRECTIVES_2026-08-22.md` §5: blind review is Fable-only and never
judges evidence it produced).

| domain | A (keyart world) | B (Palworld kind) |
|---|---|---|
| D3 creatures | **yes, narrowly** | **no** |
| D4 characters | **no** | **no** |

The divergence is useful: the creature roster passes the keyart-belonging test
that the corridor and the human cast both fail.

## D4's finding, and why it is the highest-value result of the sweep

The critic, from pixels alone:

> *"The four antagonist 'rank' frames are not four characters. They are the
> Warden's exact mesh, costume, and pose four times, with an untextured coloured
> ball floating in front of his throat."*

It sampled the badges itself: grunt `(162,188,204)`, officer `(255,179,92)`,
captain `(255,178,66)` — **officer and captain differ by 26 points in one
channel and nothing else**. It called the badge *"a debug gizmo left in the
shot, not insignia"*; it hovers detached from the chest.

**This corroborates, blind, a finding reached separately by grep**: nothing in
`data/config/` or `scripts/` references `assets/characters/grunt/grunt_lod0.glb`,
though `docs/art/HUMANOID_ASSET_INVENTORY.md` — authoritative per CLAUDE.md —
lists it as a reusable Team Tether archetype and tells authors to use the grunt
family "rather than repainting a civilian and calling it a grunt".
`npc_ranks.gd` still hardcodes the Warden's rig for every rank. Two lines of
evidence, blind to each other, converging on one fix: rebuild the ladder on the
grunt body and leave the Warden his own.

The critic also named a consequence the code evidence did not reach: **the
ladder built on the boss's body costs the Warden his reveal.** After fighting
captains wearing his face, coat, hair and mask, *"the boss reveal reads as
'another one of those guys'."*

Also D4: Team Tether has **no faction colour** — the Warden wears the same
olive-green family as Grandpa and the villager female, the grunt wears a
purple-navy that appears nowhere else including on his own commander, and
nothing carries the oxblood the keyart reserves for them. *"The boss reads as a
forest ranger standing with the villagers."* Three rendering languages in one
cast. The Warden's eyes are unreadable inside his mask — *"at gameplay distance
he reads as eyeless"*. The villagers read as **1.78 m children** — child faces
and head ratios at adult height. A real texture bug: orange emissive glitch on
`04-villager-male-front`'s right sock.

**What works, stated because it decides the strategy:** *"The trainer alone
would pass… it proves the target style is achievable in this build, because one
asset already hits it."*

## D3's finding

> *"This roster is two different art packs wearing one logo."*

About twelve species are a cohesive mascot family and the critic insisted that
be said plainly — *"that core holds up beside Palworld, and I want that said
clearly, because it is the best news in the survey."* Five — bramblebun,
trailpup, duskhush, galecrest, brooktail — are realistic wildlife with a green
tint, and read as **sourced**: *"Bramblebun is 'a rabbit, but the ears are
green'."* Paddlenewt reads as *"a baby Toothless — a player will name the
reference before they name the species."*

**It fails as a collection.** Ripplet and brooktail are the same animal at
thumbnail size; terrapup's and burrowback's shinies are both blue badgers with
white face stripes; mudsnout and tuskroot are near-twins; a third of the sheet
reads "blue creature" against a green-gold board. **Seven of seventeen shinies
land on pink/coral** — *"'rare = turn it pink' is a filter language, not a
design language."*

It confirmed independently what a grep had already shown: **alpha is a scale
slider.** *"The normal Galecrest scaled up ~40% with identical coloring — 'alpha'
is conveyed by nothing except size."*

## Two defects in THIS SURVEY's own rig, and what they invalidate

Both found by the critic, both now fixed in `_capture_creature_roster.gd`.

1. **No contact shadows on anything, the trainer included** — *"everything
   floats on the pale ground like a sticker."* The critic could not tell
   whether this was the rig or the shipped renderer and flagged it as possibly
   a real in-game problem. **It is the rig.** Godot defaults
   `DirectionalLight3D.shadow_enabled` to false and the bare stage never set
   it; `world_look.gd:348` sets the world's sun from `art.json` defaulting to
   true. The shipped world has cast shadows all along.
2. **The ruler was lying.** Species models disagree about where their origin
   sits, so a single `global_position.y` left some floating and some sunk.
   *"Terrapup reads TALLER than the trainer, which contradicts 'starter pup'.
   Pin every creature's pivot to the trainer's ground line or the ruler lies."*

**Consequence, stated rather than buried: every SCALE finding in D3 round 1 is
provisional** — the 1.4 m songbird chick, the 1.6× span across seventeen
species, the legendary-equals-common-deer reading. The findings that do not
depend on ground contact — the two-art-packs split, the twin collisions, the
pink shinies, alpha-as-scale — stand on their own.

---

# D3 creatures — round 2, on the fixed rig

Fresh critic, fresh frames, shadows on and every creature seated on the ground
line. **A — no (as a set). B — no.** A moved DOWN from round 1's narrow yes, and
the reason is not that the roster got worse: this critic read
`docs/reference/owner-board-2026-08-15-creature-colors.png` and compared, which
round 1 never did.

## The finding that outranks the verdict: the renders contradict the owner's board

| species | the board paints | the build renders |
|---|---|---|
| terrapup | a small leafy **puppy** | a 2.2 m badger |
| burrowback | rock-plate **shell armour** | a moss strip, no shell |
| brooktail | a signature **water-swirl tail** | a plain flat beaver tail |
| ripplet | a quadruped **axolotl-dragon** with fin frills | a glossy bipedal chipmunk with a droplet decal |
| reedwing | an elegant blue **crane** | a domestic duck, 1.8 m, eye to eye with the trainer |
| duskhush | dark **plum** | pale lavender |
| trailpup / bramblebun | leaf and bramble growth | almost none of it survives |

Several of these are the species' *identifying* feature: burrowback's shell is
the one thing separating it from terrapup, and **they share one badger mesh**.
The consequence the critic drew: *"a player cannot tell their shiny starter from
a shiny Burrowback across a meadow"*, and *"recoloring cannot make the starter a
different species from the tank; only geometry can."*

Lightening duskhush off the board's plum also cost the roster its **only
dark-value creature** — everything else is mid-value pastel, which is a
measurable part of why the sheet reads flat.

**Galecrest's rarity is inverted:** the "shiny" is natural brown hawk plumage
while the normal is the exotic white-and-blue one. The rare looks more common
than the common.

## What the rig fix bought

Round 1's two harness defects are confirmed closed, in the critic's own words:
*"Grounding shadows are present everywhere; nothing floats. Good."* and the
harness is now cited as an asset — *"identical camera and ruler in every frame is
exactly what made the scale and mesh-sharing findings checkable."*

The re-measured roster: **1.35 m (pipwing) to 2.60 m (veridian), a 1.93x span
over 17 species.** Round 1's "barely 1.6x" was measured against the lying ruler
and was wrong in detail — but its conclusion survives the correction. There is
still no small tier: the smallest creature in the game is a metre-tall rabbit,
the "chick" is 1.3 m, and the duck is eye to eye with the trainer. Two scale
readings did change: veridian is now the largest species rather than
common-deer-sized, and terrapup at 2.2 m genuinely does out-mass burrowback,
the tank it shares a mesh with.

**On the box today:** veridian, with galewisp as runner-up. *"The toon family's
material quality is honestly competitive."*
