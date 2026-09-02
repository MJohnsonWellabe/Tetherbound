#!/usr/bin/env python3
"""Generate candidate meshes from the reference crops, via Meshy's REST API.

    export MESHY_API_KEY=msy_...
    tools/art_pipeline/meshy.py check
    tools/art_pipeline/meshy.py balance
    tools/art_pipeline/meshy.py generate terrapup --candidates 3
    tools/art_pipeline/meshy.py status <task_id>
    tools/art_pipeline/meshy.py fetch <task_id> --out assets_raw/terrapup/a

REST rather than Meshy's MCP server; see docs/decisions/D11.

COST. TETHERBOUND_3D_ART_PIPELINE.md section 25 is explicit that credits go
fast and that the order is: cheap preview, then two or three serious
candidates, then spend only on the winner. So `generate` defaults to the
preview tier, prints the balance before and after, and refuses to run a batch
that would cost more than `--budget` credits without `--yes`.

SECRETS. The key is read from the environment and from nowhere else. It is
never written to a file, never echoed, and never appears in a saved manifest —
section 23. Downloads land in `assets_raw/`, which `.gitignore` already covers.
"""

import argparse
import json
import os
import pathlib
import sys
import time
import urllib.error
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parents[2]
REFERENCE_ROOT = ROOT / "assets" / "creatures" / "tetherbound"
RAW_ROOT = ROOT / "assets_raw"

BASE = "https://api.meshy.ai"
## `top` is here for the PROPS, and it earns its place: a plan view is a
## standard drawing on an object board and it is sometimes the only clean one.
## The Legendary Tether Machine is exactly that case — board 15 draws the bound
## creature in every elevation except the rear, so the rear and the TOP are the
## two views the licence lets us use at all (see prop_views.json). No creature
## board carries a top.png, so this costs the creature path nothing.
VIEWS = ["front", "side", "back", "three_quarter", "head", "top"]

## Seconds between polls, and how long to wait before giving up. Generation
## takes minutes, not seconds; polling harder does not make it faster.
POLL_SECONDS = 15
POLL_TIMEOUT = 45 * 60

## Refuse a batch costing more than this many credits without --yes. A guard
## against a typo in --candidates spending a month's free tier in one command.
DEFAULT_BUDGET = 60

## Observed credit cost per task, measured against the balance endpoint before
## and after real batches — NOT taken from the pricing page.
##
## These were 5 for every preview tier, which is what the docs imply and what
## the guard was written around. The real figure is 20, so a "roughly 15" batch
## actually cost 60 and the guard sat four times too high to ever fire: the
## three Warden text candidates alone spent a quarter of what was left. Any
## future correction belongs here, and belongs measured the same way.
##
## T1-NPC-CAST, 2026-08-30: `image_refine` corrected 40 -> 30, the same way --
## balance checked before/after 15 separate refine-tier `generate` calls
## (one candidate each, across two batches), every single one landing at
## exactly a 30-credit drop (1440->1230 over 7, 1230->990 over 8). Estimator
## text elsewhere still prints "roughly 40" against this old figure in a few
## comments/docstrings that were not re-swept; the number that matters, this
## dict, is fixed.
##
## T1-RIG-2, 2026-08-30: added `rig`, which had no entry here at all despite
## being measured. T1-NPC-CAST ran the humanoid auto-rigger 22 times plus one
## resubmit and recorded 5 credits per call, checked against the balance
## endpoint the same way as the two corrections above; its own report named the
## missing entry as worth adding and no lane had. A `rig` call costing nothing
## in this table is how a rig round gets costed at zero in a plan.
##
## `retexture` is left at 30 deliberately. The same report measured ONE
## retexture call at 10 and explicitly declined to correct the table on a single
## data point -- unlike the two corrections above, which each rest on 15+ calls
## with no variance. Re-measure on the next retexture this project makes rather
## than trusting either number.
COSTS = {
    "image_preview": 20,
    "image_refine": 30,
    "text_preview": 20,
    "retexture": 30,
    "rig": 5,
}

## What every Tetherbound creature must be, and must not be. Section 8's two
## lists, verbatim in intent: the positives keep the species' identity, the
## negatives name the specific ways image-to-3D drifts off this project's style.
STYLE = ("stylized PBR game character, clean readable forms, large clear colour "
         "regions, restrained surface detail, appealing stylised proportions, "
         "single creature, neutral standing pose, T-pose-adjacent, full body")
## Two negative lists, because the creature one bans "humanoid anatomy" and
## "clothing" — which, sent with a HUMAN character, tells the generator to
## fight the subject itself. The first trainer batch went out with exactly
## that mistake and was resubmitted.
## The round-2 additions below were each a real fix, but they were written
## while the roster in production was four compact ground quadrupeds. They are
## SHAPE bans, and three creatures on the wild sheets are those shapes on
## purpose — see DROP_FOR_SPECIES. Adding a term here now means asking whether
## any species is supposed to have it.
NEGATIVE_CREATURE = ("photorealistic fur, strand hair, humanoid anatomy, clothing, armor, "
            "weapons, accessories, generic real-world animal, hyperreal claws, "
            "excessive moss, noisy surface detail, wet plastic shading, "
            "text, watermark, multiple creatures, base, pedestal, "
            # Round-2 additions, each one a specific invention the blind critique
            # found in a round-1 candidate.
            "bushy tail, upturned tail, paddle tail, beaver tail, long legs, "
            "tall slender body, fox proportions")

## Negative terms that must be REMOVED for particular species, because the
## creature's own canon signature is the thing the term bans.
##
## This is the same mistake NEGATIVE_HUMAN exists to prevent, one roster later:
## a shared negative list telling the generator to fight the subject itself.
## That one cost a resubmitted trainer batch. These three would each have cost
## 60 credits of candidates drawn without their defining feature:
##
##   Meadowhart  is a DEER. Its prompt asks for "LIGHT SLENDER FRAME with long
##               legs"; the list bans "long legs, tall slender body". It also
##               wears "A SADDLE of woven leaves and worn leather" — its single
##               most important feature, and the reason it is the rideable creature —
##               against a list banning "clothing, armor, accessories".
##   Brooktail   is canonically "a BROAD FLAT SCALED TAIL like a paddle"
##               (Water Sheet). The list bans "paddle tail, beaver tail".
##   Trailpup    has a "bushy dark-tipped tail" on Ground Sheet A. The list bans
##               "bushy tail" — which is where that ban came from, when a bushy
##               tail was an invention on Terrapup rather than canon on the
##               coyote. It is already built; the entry is here so a rebuild
##               does not repeat the round-1 result.
##
## Removed by exact substring so the rest of the list — the style and quality
## bans, which every creature still wants — stays intact.
DROP_FOR_SPECIES = {
    "meadowhart": ("long legs, ", "tall slender body, ", "clothing, ", "armor, ", "accessories, "),
    "brooktail": ("paddle tail, ", "beaver tail, "),
    "trailpup": ("bushy tail, ", "fox proportions"),
    # Sparkit is canonically fox-and-coyote proportioned (owner board
    # 03_Sparkit.png calls it a "Stormlands Wanderer" with an explicit
    # fox-coyote build) -- the same fight NEGATIVE_CREATURE's ban already
    # cost Trailpup once, one creature later.
    "sparkit": ("fox proportions",),
}
NEGATIVE_HUMAN = ("photorealistic skin, realistic human proportions, armor, weapons, "
            "sword, staff, gun, cape, robe, extra fingers, fused fingers, "
            "noisy surface detail, wet plastic shading, "
            "text, watermark, multiple people, base, pedestal")
## `warden_head` is the Warden's head as its own subject (board 16). It is a
## HUMAN for negative-prompt purposes -- the creature list bans "humanoid
## anatomy" and would tell the generator to fight the thing being made.
## T1-NPC-CAST, owner directive 2026-08-30 ("NPCs are going to be the same.
## just generate the people on the original art"): the reuse-only plan this
## lane first proposed did not survive a render (see
## tools/_capture_rank_variety.gd and ralph/reports/NPC_CAST_PLAN_2026-08-30.md's
## CORRECTION section -- eleven named grunts/officers/captains rendered
## through the real placement path came back as the same body wearing
## the same clothes with only a colour shift and a badge). These 24 are the
## Meadows NPC Design Board's own cast, one generation per board panel,
## matching the board's own 3 grunt / 2 officer / 2 captain body variants
## (reused across many named individuals via the existing rank/palette
## system exactly as today, not one generation per named grunt) plus the 17
## distinct village/trail identities. The Warden (board panel 8) is
## DELIBERATELY EXCLUDED -- CLAUDE.md and docs/art/HUMANOID_ASSET_INVENTORY.md
## are explicit that he is already rebuilt from board 16 and must not be
## regenerated or reopened.
HUMANS = {"trainer", "grandpa", "warden", "villager_female", "villager_male", "grunt",
          "warden_head", "warden_body",
          "grunt_a", "grunt_b", "grunt_c", "officer_a", "officer_b",
          "captain_a", "captain_b",
          "innkeeper", "inn_helper", "trader", "craftsperson", "creature_caretaker",
          "farmer", "local_historian", "young_trainer", "traveling_merchant",
          "rival_trainer", "field_researcher", "wandering_trainer", "lost_traveler",
          "campfire_traveler", "alpha_tracker", "courier", "former_tether_member"}

## The three hero objects D24 reserves Meshy for are STRUCTURES, and both the
## creature and human lists ban "base, pedestal" — which, sent with the Tether
## Energy Pylon, bans the pylon's own grounded base, the exact mistake
## DROP_FOR_SPECIES exists to prevent one asset class later. Structures also
## need their own style line: "single creature, neutral standing pose" is
## nonsense for a tower. The dominant drift risk for "energy pylon" is the
## real-world steel lattice transmission tower, so that family is banned by
## name.
## BAND1-D1 owner directive, 2026-08-23: three camp furniture props, added to
## the three Team Tether hero objects CLAUDE.md otherwise reserves Meshy for.
## The reference board (docs/art/reference/owner-board-2026-08-23-camp-set.png)
## is owner-supplied and satisfies the actual gate ("never spend a Meshy
## generation without owner-supplied reference art") — the "hero objects only"
## line exists to stop an autonomous Ralph firing from spending speculatively,
## not to block the owner directing a specific generation themselves. Recorded
## here rather than silently treated as routine, per CLAUDE.md's "ask instead
## of inventing" — this is the owner having already answered, not this file
## deciding on its own.
## TM-ORB owner directive, 2026-08-28. Same shape as BAND1-D1 above: the owner
## supplied a reference board (docs/art/reference/tm_orb_board.png) and directed
## the generation, which satisfies the real gate. The owner's playtest reported
## TMs as "cardboard cards" on every surface they appear -- world pickup,
## backpack and reward moment -- so this replaces a placeholder rather than
## adding an object.
##
## ONE MESH, TEN MATERIALS. The board's own subtitle is "Generic Mesh +
## Recolorable Material", and it draws ten type variants as hue/emissive swaps
## over one body. So this asks Meshy for the BASE orb only; the variants are a
## material job in-engine, the same economy character_model.gd already uses for
## villager palettes. Generating ten orbs would be ten times the credits for
## the same silhouette.
PROPS = {"tether_pylon", "relay_apparatus", "tether_machine",
         "camp_tent", "camp_fire_pit", "camp_bed",
         "camp_firewood", "camp_flame",
         "tm_orb"}
STYLE_PROP = ("stylized PBR game environment prop, hand-painted fantasy style, "
              "clean readable forms, large clear colour regions, restrained "
              "surface detail, single object, upright, full structure visible")
NEGATIVE_PROP = ("realistic electrical transmission tower, steel lattice, metal "
                 "truss, cables, power lines, scaffolding, photorealistic, "
                 "creature, character, human figure, weapon, tree, building, "
                 "noisy surface detail, wet plastic shading, text, watermark, "
                 "multiple objects")

## The reference board's bed panel carries a paw-print emblem and a leaf icon
## on its blanket/pillow — another game's trademark, not this project's. Both
## were blurred out of the crops under assets/creatures/tetherbound/camp_bed/
## reference/ before they ever reached this file, but a negative prompt is
## cheap belt-and-braces against the generator inferring a similar mark from
## the surrounding stitching/border shapes that survived the blur.
NEGATIVE_CAMP_BED = (NEGATIVE_PROP + ", logo, emblem, brand mark, insignia, "
                     "paw print, animal silhouette icon, trademarked symbol, "
                     "text, lettering")

## Meshy's documented ceiling for /openapi/v2/text-to-3d prompts, counted on
## the final string including the STYLE suffix. image-to-3d does not enforce it.
TEXT_PROMPT_LIMIT = 800


## The legendary is made OF plants, so the creature list's "excessive moss"
## and the style line's "restrained surface detail" would fight its design.
NEGATIVE_PLANT = ("photorealistic bark, realistic deer, scary, skeletal, "
            "humanoid anatomy, clothing, armor, weapons, rider, saddle, "
            "wet plastic shading, text, watermark, multiple creatures, "
            "base, pedestal")


## Board 15 draws the machine WITH its victim in the cage, because that is what
## the machine is for. The licence is for the machine alone (D24, and the R8.2
## backlog item says so in capitals): the bound creature is an existing roster
## asset or VFX placed inside at runtime. A generator handed that board's
## silhouette will happily fuse a dragon into the mesh, so the ban is explicit
## rather than left to the "single object" line in STYLE_PROP.
NEGATIVE_MACHINE = (NEGATIVE_PROP + ", creature inside, dragon, beast, "
                    "bound animal, wings, horns, claws, skull, face, "
                    "figure in cage, glowing creature silhouette")


def negative_for(species: str) -> str:
    if species == "tether_machine":
        return NEGATIVE_MACHINE
    if species == "camp_bed":
        return NEGATIVE_CAMP_BED
    if species == "veridian":
        return NEGATIVE_PLANT
    if species in HUMANS:
        return NEGATIVE_HUMAN
    if species in PROPS:
        return NEGATIVE_PROP
    negative = NEGATIVE_CREATURE
    for term in DROP_FOR_SPECIES.get(species, ()):
        if term not in negative:
            # Loud rather than silent: a term that no longer matches means the
            # list was reworded and this species is quietly being sent a ban on
            # its own signature again.
            sys.exit(f"negative_for({species}): '{term.strip(', ')}' is no longer in "
                     f"NEGATIVE_CREATURE. Re-read DROP_FOR_SPECIES against the list.")
        negative = negative.replace(term, "", 1)
    return negative

## Per-species prompt, from archive/docs/art/CLAUDE_BUILD_PROMPTS.md. The markdown is
## authoritative over anything an image generator wrote onto a sheet, so the
## words that drive generation come from there rather than from reading a PNG.
SPECIES_PROMPTS = {
    # Round 2 wording. The round-1 prompt said "oversized digging forepaws" and
    # "short tail with a stone tip" once each, and the blind critique of the
    # three round-1 meshes found exactly those two features missing: the best
    # candidate's forepaws were "barely distinguishable from the hind paws" and
    # two of three tails were invented (one bushy up-curl, one beaver paddle).
    # What the generator under-weighted is now stated harder and earlier, and
    # the stance drift the critique named ("too leggy... fox cub") gets its own
    # clause. The features it got right unprompted (mantle, face) keep their
    # original weight.
    "terrapup": (
        "small sturdy quadruped ground creature, badger and canine influence. "
        "ENORMOUS oversized front paws, much wider and deeper than the hind "
        "paws, with long splayed digging claws nearly as tall as the forearm. "
        "Short thick legs, low-slung belly close to the ground, compact tank-"
        "like stance. Short LOW-HANGING tail capped with one large faceted "
        "stone, never bushy, never curled up. Warm brown fur with cream face "
        "stripe and cream chest, spiky fur crest on the skull, cheek ruff, "
        "grey stone plates in separate rows forming a mantle across shoulders "
        "and back with visible gaps between plates, subtle moss in the seams, "
        "dark paw pads, large expressive teal eyes, friendly and loyal, short "
        "blunt muzzle with a big round nose"),
    "ripplet": (
        "small playful semi-aquatic creature, otter and newt influence, smooth "
        "turquoise skin, cream belly, translucent fin-like ear frills with pink "
        "inner membrane, broad translucent fan tail fin, pale teardrop markings, "
        "webbed hind feet, large expressive dark blue eyes, agile and curious"),
    "galewisp": (
        "small fox-bird glider creature, cream down over layered blue and teal "
        "feathers with tan accents, enormous feathered ear tufts, wing-membrane "
        "forelimbs, long feathered tail, slender dark scaled legs with talons, "
        "large expressive blue eyes, alert lightweight energetic silhouette"),
    # Round 2 wording. The blind critique found four SYSTEMATIC defects across
    # all six round-1 candidates: featureless egg faces ("no eye sockets, no
    # brow ridge, no mouth... zero nose projection"), ~4.8-head chibi
    # proportions against the sheet's 6.25, no fingerless gloves anywhere, and
    # a four-digit maximum on hands. Its verdict: regenerate with those named.
    "trainer": (
        "stylised young human explorer with FULLY SCULPTED FACIAL FEATURES: "
        "defined eye sockets, eyebrows, projecting nose and mouth geometry. "
        "Slim teenage build, six and a quarter heads tall, long legs, NOT "
        "chibi. Five separated fingers on each hand, brown fingerless gloves "
        "with knuckle cuffs. Teal jacket open over cream shirt, rolled "
        "sleeves, dark cargo trousers, chunky brown leather boots, canvas "
        "backpack with visible shoulder straps, brass and glass orb holder "
        "device at the belt, brown tousled spiky hair, friendly confident "
        "expression"),
    # ---------------------------------------------------------------------
    # The Meadows wild roster: twelve species and one evolution.
    #
    # REWRITTEN from the owner's Meadows Wild Canon Pack (docs/art/wild/,
    # sheets in docs/art/reference/wild/). The previous prompts were written
    # against exploration boards 05-08, which contradicted each other and had
    # no turnarounds. These sheets are 01-04 quality and give every species a
    # front/side/back turnaround, a palette strip, build notes and a scale
    # figure, so the prompts follow the sheets rather than the old boards --
    # replacing guesswork with drawn reference is the whole reason the pack
    # exists.
    #
    # Two roster changes come with it (D13): `ridgewolf` is GONE, because the
    # canine no longer evolves in the Meadows, and `mudsnout` is new as the
    # biome's only pre-evolution. `tuskroot` stays but is now reached by
    # evolving Mudsnout rather than met as a base creature.
    #
    # Each prompt states its signature feature in capitals and first: six
    # rounds of blind critique have shown the generator drops whatever is
    # mentioned once in passing.
    #
    # Three carry an explicit NOT clause, straight from the pack's distinction
    # rules -- each must not read as a character the player already knows.
    # ---------------------------------------------------------------------
    "bramblebun": (
        "meadow rabbit creature, agile forager. LONG upright expressive ears "
        "with pale pink inner surface, BROAD powerful hind legs built for "
        "jumping. Living MOSS AND SMALL MEADOW PLANTS with tiny purple "
        "flowers growing naturally along its back and shoulders, warm brown "
        "fur, cream chest and belly, short fluffy tail, large teal eyes, "
        "alert curious face, compact grounded silhouette"),
    "mudsnout": (
        "young wild piglet creature, rooting runt. BROAD FLEXIBLE PINK SNOUT "
        "for rooting in soil, SMALL BLUNT TUSKS just emerging, short sturdy "
        "legs and a low centre of gravity, rounded youthful body. Bristly "
        "brown coat caked with dried soil and flecks of moss and leaf litter "
        "along the back, cream muzzle, dark eyes, playful earthy character. "
        "Young and rounded, NOT armoured and NOT large"),
    "trailpup": (
        "lean prairie canine creature, tracker and flanker. LONG SLENDER LEGS "
        "built for speed and endurance, ELONGATED NARROW MUZZLE, large "
        "upright pointed ears. Sandy tan fur with cream underside and chest, "
        "darker markings around the eyes, bushy tail with a dark tip, "
        "coyote-like alert posture. NO stone plates and NO armour of any "
        "kind, and not a stocky mascot cub"),
    "meadowhart": (
        "graceful rideable meadow deer, mount and pathfinder. BRANCHING "
        "ANTLERS of modest size, LIGHT SLENDER FRAME with long legs and soft "
        "hooves. A SADDLE of woven leaves and worn leather over a blanket of "
        "layered green leaves across its back. Warm tan hide with pale cream "
        "spots along the flanks, cream throat and underside, large gentle "
        "teal eyes, friendly practical bearing. An ordinary approachable "
        "meadow animal, NOT an ancient sacred forest guardian"),
    "burrowback": (
        "broad low badger creature, digger and defender. ENORMOUS SHOVEL "
        "CLAWS on powerful forelimbs, BLACK AND WHITE STRIPED FACE with a "
        "white blaze from nose to crown. LOOSE GREY ROCK NODULES scattered "
        "in clusters over its back and shoulders with moss in the gaps, "
        "never one continuous shell. Dark brown shaggy fur, very low heavy "
        "silhouette close to the ground, small dark eyes, blunt snout"),
    "tuskroot": (
        "large heavy armoured boar creature, charger. LONG CURVED IVORY "
        "TUSKS sweeping up from the jaw, THICK GREY STONE PLATES layered "
        "across the shoulders and down the back like natural armour with "
        "moss growing in the seams. Massive forequarters, broad head held "
        "low, bristly dark brown coat, small fierce eyes, short powerful "
        "legs, immensely solid and heavy"),
    "paddlenewt": (
        "small amphibious newt creature, quick swimmer. TRANSLUCENT ORANGE "
        "FIN FRILLS fanning from the sides of its head and running as a "
        "crest down its spine, HUGE ROUND GOLDEN-ORANGE EYES. Smooth teal "
        "blue skin with paler spots and a cream belly, WEBBED TOES, long "
        "tapering swimming tail, moist glossy skin, curious expressive face"),
    "mosshell": (
        "sturdy pond turtle creature, steady tank. BROAD DOMED SHELL of "
        "mossy grey stone plates with a pale cream rim, moss and algae "
        "growing between the plates. Teal green skin, cream underside, "
        "strong stumpy limbs for lakebed traction, very low centre of "
        "gravity, gentle rounded head with large dark eyes, calm patient "
        "expression"),
    "brooktail": (
        "river otter creature, resourceful diver. SLEEK STREAMLINED BODY "
        "with a BROAD FLAT SCALED TAIL like a paddle, WEBBED FEET. Dense "
        "chocolate brown fur with a cream muzzle, throat and chest, long "
        "pale whiskers, small round ears, bright blue eyes, friendly clever "
        "face, semi-aquatic mammal proportions"),
    "reedwing": (
        "waterfowl creature, swift glider and swimmer. BROAD FEATHERED WINGS "
        "layered for flight, ORANGE BILL and ORANGE WEBBED FEET. Teal and "
        "blue-grey layered wing feathers over a cream breast and neck with "
        "tan accents, buoyant duck-like body, long graceful neck, bright "
        "eyes. Must read as equally at home on water and in the air"),
    "pipwing": (
        "tiny round songbird creature, zippy flier. OVERSIZED ROUND TEAL "
        "EYES taking up much of the face, SMALL RAISED CREST of feathers on "
        "the crown. Slate blue-grey wing and back feathers over a cream face "
        "and round chest, tan accents, tiny orange beak, small orange feet, "
        "very small and very round, bright and quick"),
    "duskhush": (
        "owl creature, silent watcher. BROAD ROUNDED SILENT WINGS, "
        "PRONOUNCED EAR TUFTS rising from the head, LARGE FORWARD-FACING "
        "EYES ringed in gold set in a pale facial disc. Grey-blue and cream "
        "layered plumage with soft feather edges, tan accents, strong "
        "talons, calm watchful expression. Serene rather than spooky, with "
        "NO glowing eyes"),
    "galecrest": (
        "large powerful hawk creature, aerial striker. ENORMOUS BROAD WINGS "
        "held open with long layered flight feathers, HOOKED DARK BEAK, "
        "HEAVY GRIPPING TALONS. Slate blue and tan layered plumage over a "
        "cream chest and face, fierce focused eyes, upright commanding "
        "raptor posture. A serious predator, NOT a small cute fox-eared "
        "glider"
    ),
    # Board 06, owner-approved as the Warden's source over the earlier boards'
    # off-brief priestess (docs/art/REFERENCE_CANON.md).
    # Round 2. Round 1 went through multi-image-to-3d and every candidate came
    # back with the board's CROSSED ARMS welded into one mass across the belly
    # — image-to-3D reconstructs the pose it is shown, and no amount of "arms
    # at his sides" in the text outvoted three views of folded arms. So the
    # Warden goes through text-to-3D instead: the design is still board 06's,
    # the pose is the only thing the drawing loses.
    #
    # The round-1 critique also charged three defects that turned out to be
    # MY prompt disagreeing with the art, not the mesh: the board's cape hangs
    # full from both shoulders (not a half-cape), and his boots are ankle-high
    # with a folded cuff over a dark greave (not tall riding boots). Corrected
    # here rather than "fixed" in the models.
    #
    # The face is the one thing worth being clever about. Six humanoid
    # candidates across two characters have now come back with smooth blank
    # egg heads — the generator does not sculpt faces at preview tier. The
    # Warden is the one character where that stops mattering, because board 06
    # already masks him: a hard green visor over the eyes and a mask across
    # nose and mouth. Asking for the MASK as geometry instead of a face plays
    # to what the generator can actually do, and it is what the art shows.
    #
    # Meshy caps text-to-3D prompts at 800 characters, so this one is written
    # tight: the two capitalised clauses are the two things every round-1
    # candidate got wrong, and they go first.
    "warden": (
        # SUPERSEDED BY BOARD 16 (2026-08-16). Everything above this entry's
        # older comment block was tuned against board 06, where the Warden is a
        # masked soldier whose face is hidden behind a hard visor and a mask
        # plate over nose and mouth. The owner supplied a dedicated character
        # sheet -- docs/art/reference/16_Warden_Aldis_Character.png -- and it
        # is a DIFFERENT AND BETTER DESIGN: the face is bare and human, with a
        # short beard and a green MARKING painted across the eyes in the shape
        # of a domino mask, not a plate standing off the skin. The board is the
        # owner's later word and wins, the same way D23 makes the newer brief
        # win elsewhere.
        #
        # The one thing carried forward unchanged is the VALUE BREAK. Board
        # 06's gate review failed this character at distance -- "coat,
        # trousers, boots, hair and face markings all sit in one narrow green
        # hue at essentially one value ... at 300px he is a vertical green
        # rectangle" -- and board 16 has the same risk, being green on green.
        # Its answer is the pale cream fur mantle, so that is stated LARGE and
        # PALE here for exactly the reason it was before.
        "stylised human man, BROAD HEAVY officer, wide shoulders, thick chest. "
        "BOTH ARMS HANG AT HIS SIDES clear of the body, five fingers per hand. "
        "BARE HUMAN FACE, no helmet, no mask plate: deep eye sockets with lids "
        "and heavy brows, projecting nose, short dark BEARD, and a flat GREEN "
        "PAINTED MARKING across the eyes like a domino mask, level with the "
        "skin. Short swept-back GREEN hair. Dark forest-green coat with gold "
        "botanical trim, LARGE PALE CREAM FUR MANTLE heaped over both "
        "shoulders, wide belt, dark trousers, tall boots. Seven heads tall"),
    # Board 06's Veridian Stag, likewise owner-approved as the legendary.
    # BOARD 16's body turnaround. The BODY only -- graft_head.py throws this
    # figure's head away and puts the separately-generated one on, so nothing
    # here describes a face. What it must get right is the SILHOUETTE and the
    # value break: a heavy officer in a long open greatcoat with a large pale
    # cream fur mantle, which is the only bright note in an otherwise green
    # design and the reason he reads at 300px at all.
    #
    # NO STAFF. The board draws one in his hand and NEGATIVE_HUMAN bans it; the
    # ban is deliberate here (see prop_views.json's warden_body comment).
    "warden_body": (
        "stylised human man, BROAD HEAVY commanding officer, wide shoulders, "
        "thick chest, not slim, standing straight. BOTH ARMS HANG AT HIS SIDES "
        "clear of the body, EMPTY GLOVED HANDS holding nothing, five fingers "
        "each. Long DARK FOREST-GREEN officer's greatcoat worn open over a "
        "tunic, gold botanical trim and gold edging, LARGE PALE CREAM FUR "
        "MANTLE heaped across both shoulders, wide brown belt with pouches, "
        "dark trousers, tall heavy boots. Seven heads tall"),
    # BOARD 16, the Warden's head as its own subject.
    #
    # cmd_head exists because nine humanoid candidates came back with "no face
    # on any of the three ... a featureless ovoid with hair over it", and its
    # diagnosis is resolution allocation: at a 30k budget over a standing
    # figure, an eye socket is smaller than the triangles available. It fixes
    # that by generating the head alone -- but it could only ever send ONE crop,
    # and said so in its own docstring: "the generator invents the back of the
    # skull".
    #
    # Board 16 draws the back of the skull, and the front, and the 3/4, and the
    # profile, all at one scale. So this goes through the ordinary four-view
    # `generate` path rather than through cmd_head, which is strictly more
    # information for the same money. The face is described as BARE with a
    # PAINTED marking, because board 16 supersedes board 06's visored soldier.
    "warden_head": (
        "stylised man's HEAD AND NECK ONLY, bust, no body, no shoulders. BARE "
        "HUMAN FACE: deep EYE SOCKETS with lids, heavy brows, projecting nose, "
        "cut mouth, short dark BEARD and moustache along a strong jaw. A flat "
        "GREEN PAINTED MARKING across the eyes and the bridge of the nose, "
        "shaped like a domino mask and LEVEL WITH THE SKIN -- paint, never a "
        "plate and never a visor standing off the face. Short swept-back "
        "spiky GREEN hair, ears, mature man in his forties"),
    "veridian": (
        "majestic large forest stag guardian, four-legged deer anatomy, "
        "ENORMOUS branching antlers of twisted woody branches with green "
        "leaves growing along them, spanning wider than the body. Mantle of "
        "layered overlapping green leaves across neck and chest like a mane, "
        "body of weathered bark and wood with golden vein patterns winding "
        "along the flanks and legs, cream muzzle, leaf tuft at the tail, "
        "calm noble expression, ancient and serene, standing tall and still"),
    # From archive/docs/art/CLAUDE_BUILD_PROMPTS.md §17. His reference is the weakest
    # in the pack — four ~90px figures cut from board 05, not a production
    # sheet — so the words carry more of the load here than for the starters.
    # Round 2 wording. The blind critique of round 1 found humanoid failures
    # on every candidate — a severed floating forearm, eye regions with "no
    # lids, no sockets, no brow break", elf ears, mitten hands — so the round-2
    # prompt names each of those as a requirement, the same move that fixed
    # Terrapup's paws.
    "grandpa": (
        "stylised elderly human man, late 60s, retired explorer. DETAILED "
        "FACE with clearly sculpted eyes, eyelids and brow, kind warm "
        "expression, ROUND human ears, VOLUMETRIC full white beard and "
        "moustache, swept white hair. Both arms complete and symmetrical, "
        "relaxed A-pose slightly away from the body, five separated fingers "
        "on each hand. Muted green vest layered over cream shirt with rolled "
        "sleeves, brown trousers, sturdy leather boots, green neck scarf, "
        "small belt pouches, old field satchel, empty hands, no armor, no "
        "weapon, no staff, six heads tall, gentle grandfather posture"),
    # NP4. The three reusable NPC bases from docs/art/reference/12_NPC_Bases_Reusable.png
    # (NP1's board), generated so NP1's hair/outfit/accessory swap system has
    # bodies to build onto. All three read "same height as the player" on the
    # board itself, so that clause is stated rather than left implicit the way
    # trainer/grandpa's "N heads tall" figures were -- there is no separate
    # scale reference to fall back on here.
    "villager_female": (
        "stylised human female villager, TWIN SMALL PONYTAILS gathered high "
        "near the temples with a SMALL GOLD HAIRPIN on the side-swept fringe "
        "-- the ponytails must read clearly in a STRAIGHT-ON FRONT VIEW, not "
        "only from the side or back. FULLY SCULPTED FACIAL FEATURES: defined "
        "eye sockets, eyebrows, nose and mouth geometry. Slim youthful "
        "build, six and a quarter heads tall, same height as the player, "
        "NOT chibi. Five separated fingers on each hand. Olive-green "
        "short-sleeve hooded jacket over a cream shirt, wide brown belt "
        "with a hip pouch, olive-brown cargo shorts, brown fingerless "
        "gloves, tall brown lace-up boots, small satchel strap across the "
        "chest, warm curious expression"),
    # Round 3. Round 2's "SLATE BLUE-GRAY" call was a misread on my part: the
    # reference sheet itself draws the vest blue-gray in the FRONT panel only
    # and brown in the other four (3/4-front, side, 3/4-back, back) -- an
    # inconsistency in the source art, confirmed by eye against the sheet,
    # not a crop bug. The round-1 brown render was the more faithful read of
    # the whole turnaround, not a defect, so this reverts to brown rather
    # than chasing the outlier panel. What round 2 DID find and fix in part:
    # the throat pendant is still unadded (accessory-level, left for NP1's
    # separate-mesh-parts system per the board's own implementation notes),
    # and round 2 also flagged the trousers rendering too dark/cold --
    # "dark brown" reads as near-black charcoal at this tier; naming the
    # actual reference tone instead.
    "villager_male": (
        "stylised human male villager, SHORT TOUSLED BROWN HAIR, FULLY "
        "SCULPTED FACIAL FEATURES: defined eye sockets, eyebrows, nose and "
        "mouth geometry. Average build, six and a quarter heads tall, same "
        "height as the player, NOT chibi. Five separated fingers on each "
        "hand. Cream work shirt with rolled sleeves under a sleeveless "
        "brown canvas vest, wide brown belt with a hip pouch, WARM MEDIUM "
        "CHOCOLATE-BROWN trousers (not dark, not charcoal, not black), "
        "brown lace-up boots, practical steady expression"),
    # Round 2. The blind critique of round 1 found the amber-tinted goggle
    # band across the eyes -- clearly drawn in the reference, between the cap
    # brim and the mask -- completely absent, reading as bare skin instead.
    "grunt": (
        "stylised human Team Tether operative, AMBER-TINTED GOGGLES with a "
        "hard raised frame worn across the eyes, DARK CLOTH MASK covering "
        "nose and mouth below them, FLAT-BRIMMED CAP with a small round "
        "insignia badge. Average build, six and a quarter heads tall, same "
        "height as the player, NOT chibi. Five separated fingers on each "
        "gloved hand. Charcoal-purple uniform jacket, CROSSED BROWN LEATHER "
        "BANDOLIER STRAPS over the chest, wide utility belt with pouches, "
        "dark grey trousers, black boots, tactical gloves, stern guarded "
        "posture"),
    # SF33. One of D24's three Meshy-reserved hero objects, from the owner's
    # board 13. Signature first, in capitals, per this file's own rule: the
    # floating crystal and the four inward-leaning struts are what make it a
    # tether pylon rather than a lamp post. Built once, instanced along a
    # line, so the prompt asks for the whole assembled pylon, not the board's
    # five-part kit exploded.
    "tether_pylon": (
        "fantasy tether energy pylon, dark stone and bronze infrastructure "
        "tower. LARGE FLOATING FACETED TEAL CRYSTAL held point-up above the "
        "top by a clawed bronze frame on a slender central column. FOUR "
        "ANGLED DARK STONE SUPPORT STRUTS leaning inward from the base to "
        "the top frame. Cylindrical glass energy core module in the centre "
        "glowing bright teal, wide round stepped stone base, bronze-gold "
        "trim bands and rivets, thin glowing teal energy conduit lines "
        "inlaid in weathered dark grey slate stone, faint moss in the stone "
        "seams, ancient but maintained"),

    # SE23. D24's second reserved hero, from the owner's board 14. The board
    # numbers its own five subassemblies and the top view shows the manifolds
    # radiating evenly, so the signature — a lit glass core inside an arched
    # cage, with tubes curling out of it — leads in capitals per this file's
    # rule. Human-scale: the board's own scale guide stands a figure beside it
    # at roughly chest-to-head height, so this is ~4m, not a building.
    "relay_apparatus": (
        "fantasy tether relay apparatus, a single squat machine on a stepped "
        "octagonal dark stone base. TALL GLOWING TEAL GLASS CYLINDER CORE "
        "standing upright in the centre under a round brass cap. FOUR DARK "
        "METAL ARCHED RIBS curving up and over the core from the base "
        "corners to form an open domed cage around it. CURVED TRANSLUCENT "
        "TEAL CONDUIT TUBES arcing outward and down from brass valve wheels "
        "on each side. Angled brass-framed control console with a glowing "
        "green screen and a row of brass knobs across the front face. Dark "
        "green-black panels, brass-gold trim bands, rivets, weathered grey "
        "stonework"),

    # R8.2. D24's third and last reserved hero, from the owner's board 15.
    #
    # THE BOARD DEPICTS A BOUND CREATURE INSIDE THE CAGE AND THE LICENCE DOES
    # NOT COVER IT. Board 15 licenses the MACHINE. Its occupant is an existing
    # roster asset or VFX in-engine and must never be generated here, which is
    # why the centre is described as EMPTY in the prompt and the creature terms
    # are banned outright in NEGATIVE_MACHINE below. A candidate that arrives
    # with a creature fused into the mesh is a reject, not a bonus.
    #
    # ~15m against the board's own 0-20m bar — the chamber (data/config/
    # stronghold.json's `machine` block) is already built at that scale.
    "tether_machine": (
        "fantasy tether extraction machine, a huge EMPTY containment device, "
        "no creature inside. Round stepped dark stone dais with stairs. FOUR "
        "TALL GOTHIC STONE-AND-BRASS BUTTRESS ARCHES rising from the rim and "
        "leaning inward to enclose an OPEN EMPTY CENTRE. TWO STACKED "
        "HORIZONTAL RUNIC BRASS CONTAINMENT RINGS floating one above the "
        "other around that empty middle, glowing teal. Heavy chains draping "
        "from the arches and a pointed clamp head hanging on chains from the "
        "apex above the rings. Tall banner pennants on the outer pillars, "
        "glowing teal runic channels inlaid in dark stone, brass-gold trim"),

    # BAND1-D1, owner board 2026-08-23 ("camp set": tent/campfire/bed), owner
    # directive to generate against it. Not a hero object — camp furniture for
    # the trail_camp cluster and the player-built camp (scripts/build/camp.gd)
    # — but the reference board is real and owner-supplied, which is the
    # actual prerequisite CLAUDE.md states. Signature first, in capitals, per
    # this file's own rule: the two lashed CROSSED ridge-pole tips are what
    # read as "tent" in silhouette before any canvas detail resolves.
    # ROUND 2 (owner reviewed round 1's renders directly against the board,
    # not against a text description of it). Round 1 measured close on the
    # front silhouette's own width:height (generated 1.32, board 1.35 --
    # tools/refcrop measurement of tent_front.png) but the owner read it as
    # proportionally off anyway, and the one dimension that measurement did
    # NOT check is floor footprint: round 1's AABB was 1.60m wide x 1.90m
    # deep, near-square, where an A-frame ridge tent is a long, narrow prism
    # -- the ridge runs the LENGTH of the tent, not its width. A near-square
    # footprint reads as squat and stumpy regardless of how correct the
    # front cross-section is. Explicit numbers added because round 1's
    # words ("narrow ground footprint") were true and still lost to the
    # images, the same lesson board 15's occupant and board 16's head both
    # already taught this pipeline: image-to-3D follows pictures over prose,
    # so when prose alone is not landing, make the prose impossible to
    # satisfy with the wrong shape.
    # ROUND 3. A dispatched Fable review compared round 2's render straight
    # against the reference and called it "a poor reproduction... the
    # defining A-frame silhouette has collapsed into a low tarp shape" --
    # specific and correct: both round 1 and round 2 came back a shallow
    # lean-to, roughly half the reference's height-to-width ratio, with a
    # flared ground skirt lost entirely. Two rounds of stronger TEXT did not
    # move it (round 1 -> round 2's footprint numbers barely changed the
    # AABB), which is this file's own recurring lesson: image-to-3D follows
    # its pictures far harder than its words. So this round changes the
    # PICTURES instead. The three-view set had a `back` crop -- the tent's
    # rear canvas panel, shot flat-on so it fills its own frame edge-to-edge
    # with no pole, no ground, no depth cue -- which a multi-view
    # reconstruction may well have read as evidence for a flatter, more
    # tarp-like structure than the hero and front views alone suggest.
    # Dropped it; TWO views only (front, three_quarter), both of which show
    # the true steep A-frame profile and nothing that looks flat.
    # ROUND 4. Round 3 (image-to-3D, two views, silhouette-only text) still
    # came back a low lean-to -- SIX generations across three rounds have
    # now converged on the same shape regardless of prompt wording or which
    # reference views were fed. That consistency itself is the diagnosis:
    # this is very likely not a prompt problem at all, but the reference
    # crops' own camera angle -- a fairly shallow hero-render angle that
    # foreshortens a tall A-frame's true height, and multi-image
    # reconstruction is reproducing what the pictures actually show rather
    # than what the object actually is. `tools/art_pipeline/README.md`'s own
    # documented fallback for exactly this situation -- a species with no
    # usable multi-view sheet -- is text-to-3D for FORM, then `texture`
    # against the concept art for STYLE, already the established path for
    # all twelve wild Meadows species with no drawn turnaround. Switched to
    # it here for the same reason: text-to-3D has no image to foreshorten,
    # only the numbers below, so a "height equal to width" instruction with
    # no competing picture is now testable on its own.
    # ROUND 5. Text-to-3D got the height right (candidates' own AABB: height
    # became the tallest axis for the first time in eight attempts) and lost
    # the construction entirely -- both candidates came back a round CONE
    # with one central pole, a teepee, not an A-frame. "A-frame" and "two
    # crossed pole tips at BOTH ends" did not stop the generator reaching for
    # the far more common association "tent = teepee" once there was no
    # picture forcing the ridge shape. Rewritten to rule the cone out by
    # name and to describe the ridge as a straight line joining two separate
    # peaks rather than trusting "A-frame" alone to carry it.
    # TM-ORB. Read off docs/art/reference/tm_orb_board.png. The board is
    # explicit that this is one mesh recoloured ten ways, so the prompt
    # describes the BASE (pale stone + brass) and says nothing about type
    # colour -- a fire-red orb generated here would fight the material swap.
    #
    # The two things that must survive generation are the ones the board
    # leads with: a CLEAN SILHOUETTE (it is a sphere; the panels are inset,
    # not bolted on) and the RECESSED EMISSIVE CORE, which is what stops it
    # reading as a plain rock. The board's own scale note is 18-22cm, so it
    # is a two-handed object sitting in grass, not a boulder.
    "tm_orb": (
        "a single spherical orb the size of a melon, 20cm across. Pale "
        "cream stone shell divided into smooth inset panels by raised "
        "brass banding. NOT A BALL OF ROCK, NOT A GEODE, NOT CRACKED. "
        "One circular recessed socket on the front holds a glowing "
        "spiral core, ringed by concentric brass rings and small square "
        "gem insets. Faint carved spiral glyphs on the side panels. "
        "Smooth clean sphere silhouette, panels flush with the surface. "
        "Hand-painted stylized fantasy game prop, restrained wear, "
        "single object, resting upright"),

    "camp_tent": (
        "small survival tent, canvas over wood poles. NOT A CONE, NOT A "
        "TEEPEE. A straight horizontal ridge joining two separate "
        "triangular peaks, one at each end -- a canvas tunnel with a "
        "triangular wall at each end. TALL AND STEEP: ridge height equal "
        "to base width. Crossed pole tips above EACH peak, rope-lashed. "
        "Steep canvas sides reaching flat to the ground. Open front flap "
        "at one end, dark interior. Square patches stitched on canvas. "
        "Guy-ropes to stakes. Worn tan-brown fabric, dirt-stained. One "
        "person scale, 2m tall"),

    # ROUND 2. Round 1 tried five times (3 preview, 2 refine) to keep ring,
    # logs and flame together in one generation and never got all three:
    # every attempt dropped one or flattened the stones to 2D discs. The
    # eventual round-1 fix split it -- a retextured ring alone, flame left
    # to the game's existing procedural campfire_glow.gd -- which solved the
    # geometry problem by not asking the generator to hold three unrelated
    # forms (a ring, a stack, a fire) in one topology budget at once. Owner
    # directive: try again as ONE PIECE, not split. The prompt below tries a
    # different failure fix from round 1's -- not more capitals on "flame"
    # (round 1 already led with capitals and still lost it), but a smaller,
    # more specific ask: fewer, LARGER stones (round 1 asked for a full ring
    # continuous under a woodpile at 1m across; this asks for six-to-eight
    # instead of twelve-to-fourteen, larger relative to the log stack, and
    # states the height ordering explicitly -- flame taller than logs taller
    # than stones -- so the topology budget has less small-detail competition
    # for the same triangle count).
    "camp_fire_pit": (
        "small stylized campfire, a low ring of SIX TO EIGHT LARGE ROUGH "
        "FIRE-CRACKED BOULDERS, each roughly bowling-ball sized, set apart "
        "from each other with visible gaps between them, not touching. "
        "A stack of three to four crossed split logs leaning together at "
        "the ring's centre, taller than the boulders. ACTIVE BRIGHT "
        "ORANGE-YELLOW FLAME rising from the centre of the log stack, "
        "TALLER THAN THE LOGS THEMSELVES, the single tallest element in the "
        "whole object. Visible embers glowing at the base of the flame, "
        "soot-blackening on the boulders nearest the fire, scorched dark "
        "earth visible in the gaps between boulders, roughly 1.2 metres "
        "across the stone ring, HEIGHT ORDER FROM TALLEST TO SHORTEST: "
        "flame, then logs, then boulders"),

    # ROUND 3. Owner, looking at the assembled camp: "the wood and the fire
    # looks like a toy". Split from the combined `camp_fire_pit` prompt
    # above rather than tuned further -- seven attempts across two rounds
    # already established that ring+logs+flame together in one generation
    # never converges (a stone ring OR a log stack OR a flame survives, "
    # never more than two at once), so the working answer stays compositional:
    # a textured stone ring (already generated, kept), a log stack (this
    # entry), and a flame (the next entry), placed together in-scene rather
    # than fused. Generated ALONE, this asks the generator to spend its
    # whole topology/texture budget on wood, which the combined prompt's
    # earlier passes never got the chance to do -- round 2's fire-pit
    # attempts (refine4/refine5) show a genuinely well-formed crossed log
    # stack with real bark texture whenever a ring wasn't competing for the
    # same triangles, which is the evidence this split is likely to work.
    "camp_firewood": (
        "a stack of three to four crossed SPLIT FIREWOOD LOGS leaning "
        "together at a central point like a small teepee, ready to burn. "
        "Rough split wood with visible grain and bark on the outer curved "
        "faces, cut flat ends showing growth rings, natural size variation "
        "between logs, weathered and slightly charred at the lower ends "
        "where they would sit in ash, roughly 0.5 metres tall"),

    # A static flame shape, not an effect -- Meshy generates a rigid mesh,
    # so this asks for the kind of STYLISED SOLID flame shape stylised games
    # use for exactly this (faceted, layered tongues, not a photoreal
    # gas-flame silhouette), which is also what the reference board's own
    # campfire panel actually draws. Intended to replace or sit alongside
    # `campfire_glow.gd`'s procedural billboard flame, which the owner
    # separately called out as reading as a toy.
    "camp_flame": (
        "a single stylised campfire FLAME, solid faceted shape, multiple "
        "layered upward-curling tongues of fire like low-poly stylised "
        "game fire, NOT a realistic photoreal gas flame and not a "
        "particle effect -- a sculpted solid object. Bright orange-yellow "
        "at the outer tongues shading to pale yellow-white at the core "
        "and base, sharp angular facets rather than smooth curves, "
        "roughly 0.6 metres tall, narrow flared base widening slightly "
        "toward jagged tips"),

    # ROUND 2. Owner: "it's missing a bottom portion basically." Round 1's
    # AABB was 1.23 x 0.41 x 1.90m and the render showed corner posts as
    # short stubs the frame sat almost directly on -- correct height by the
    # numbers (a real camp bed's mattress-top-to-ground is close to 0.4m)
    # but wrong by the READ, because nearly all of that 0.41m was mattress
    # thickness with the actual LEG below the rail barely present. Fixed the
    # same way as the tent above: state the leg as its own explicit
    # fraction of the total height rather than trust "knee height off the
    # ground" to imply visible legs on its own -- it did not.
    "camp_bed": (
        "small fantasy camp bed, a RECTANGULAR FRAME OF LASHED ROUND WOOD "
        "POLES raised on FOUR TALL VISIBLE ROUND WOOD LEG POSTS at the "
        "corners. THE LEG POSTS ARE THE TALLEST VISIBLE PART OF THE "
        "STRUCTURE BELOW THE MATTRESS -- clearly separate cylindrical posts "
        "reaching from the ground up to the side rails, at least as tall as "
        "the mattress is thick, so the whole bed reads as raised well off "
        "the ground on visible legs, not as a low pad sitting on the "
        "ground. Thick rope-wrapped joints where each post meets the rail. "
        "Plain unbranded dark fabric mattress filling the frame on top of "
        "the rails, one plump stuffed pillow at the head end, blanket "
        "corner folded back, coarse woven rope lashing visible at every "
        "joint, weathered worn wood, roughly 2 metres long, PLAIN "
        "UNDECORATED FABRIC WITH NO PRINT OR SYMBOL"),

    # ---------------------------------------------------------------------
    # T1-CREATURE-MESH. The Meadows Creature Expansion (owner brief
    # 2026-08-30, docs/owner/TETHERBOUND_MEADOWS_CREATURE_EXPANSION.md),
    # the five NEW-MESH creatures out of the nine named there -- the other
    # four (Nightburrow, Stormtrail, Riftfrill, Ashtusk) are recolor/VFX
    # passes on existing meshes and never reach this dict. Written from each
    # creature's own per-creature reference sheet
    # (docs/art/reference/creature-expansion-2026-08-30/), which states its
    # own Pipeline Note, Meshy Realism note and Flavor Note -- folded in here
    # as the positive-prompt clauses this file's own convention uses
    # (Terrapup's "never bushy, never curled up" is the precedent for
    # stating a realism warning as a positive instruction rather than
    # leaving it to the shared negative list alone). Signature feature
    # first, in capitals, per this file's own established rule. Sizes are
    # the master sheet's own size-guide row against its 1.8m player figure,
    # not the brief's rounder numbers, per the brief's own instruction to
    # read the real figures off the sheet.
    "sparkit": (
        "small electric fox-coyote creature, stormlands wanderer, roughly "
        "0.6m body length. OVERSIZED READABLE EARS with dark tufted tips, "
        "LONG TAIL ENDING IN A JAGGED LIGHTNING-BOLT SHAPE, a spiky charged "
        "fur ridge running from crown to tail base. Cream and pale "
        "lightning-gold body with graphite-black markings across the face, "
        "back and legs, bright blue eyes, black nose, slender alert fox-like "
        "build. Keep the fur simple and broad -- NO tiny whisker detail, NO "
        "over-complicated fur clumps -- so the ears, tail and body mass all "
        "read clearly at a glance"),
    "cindercub": (
        "small fire-ground cub creature, compact and sturdy, roughly 1.4m "
        "body length. GLOWING EMBER TAIL TUFT like a small contained flame "
        "at the tip, dark soot-black paws and lower legs, a few subtle "
        "glowing ember cracks across the shoulders and back. Terracotta-rust "
        "fur body with a cream face blaze and chest, bright orange eyes, "
        "black nose, short rounded muzzle, compact stocky cub build with a "
        "strong readable head shape. Keep the fire language simple -- "
        "glowing tail tuft and a few ember cracks only, NOT flames covering "
        "the whole body -- contained and believable rather than an inferno"),
    "shadelet": (
        "medium dark lizard creature, nocturnal wanderer, roughly 1.6m body "
        "length, NOT a tiny gecko. LONG CURLING TAIL that coils into a tight "
        "spiral, a ridge of low broad spikes running from crown down the "
        "spine and tail, OVERSIZED AMBER-GOLD EYES with an alert forward "
        "gaze. Midnight-purple and shadow-blue scaled body with a subtle "
        "violet sheen, broad flat readable head, sturdy four-legged lizard "
        "stance, dark clawed feet. Keep scale patterns broad and simple -- "
        "large readable plates rather than fine texture -- body sized like "
        "a monitor lizard, never small or thin"),
    "bramblebun_redesign": (
        "meadow guardian rabbit creature, larger and more substantial than "
        "an ordinary warren rabbit, roughly 1.0m body length. OVERSIZED "
        "DRAMATIC EARS with woody branch-like antler tips and thorny vine "
        "wrapping partway up each ear, LIVING BRAMBLE AND LEAF GROWTH across "
        "the back and shoulders with small reddish thorn accents, a "
        "bramble-tufted tail. Earth-brown and cream fur body with muted "
        "leaf-green mossy patches over the back, dark expressive eyes, "
        "sturdy round body and strong hind legs, cream chest and face "
        "markings. Silhouette first: broad readable forms with detail "
        "concentrated only in the ears, tail, bramble growths and face "
        "markings -- NOT an unreadable pile of foliage, the rabbit body "
        "must still read clearly beneath the plant growth"),
    "frostclaw": (
        "medium-large ice predator feline, lynx and snow-leopard influence, "
        "roughly 2.0m body length, NOT an ordinary real-world cat. TUFTED "
        "BLACK-TIPPED EARS, OVERSIZED PAWS with pale blue ice-crystal claws, "
        "a few BROAD ICE-CRYSTAL ACCENTS at the shoulders and cheeks, "
        "frosted whisker shapes framing the muzzle. Pale gray-white fur with "
        "slate-gray spotted markings, bright icy-blue eyes, black nose, "
        "sturdy predator build with a long thick tail. Use only a few large "
        "readable icy forms -- NOT hundreds of small crystals -- and keep it "
        "reading as a Tetherbound creature rather than a photoreal wildcat"),

    # T1-NPC-CAST, owner directive 2026-08-30 -- see the HUMANS set comment
    # above for why these 24 exist. First-pass prompts, written against this
    # lane's own crops at assets/characters/<slug>/reference/board_panel.png
    # (one crop per board panel, not yet split into per-view front/side/back
    # files the way crop_views.py's band+centres convention wants -- see
    # ralph/reports/NPC_CAST_PLAN_2026-08-30.md's Job 3 section). Palette
    # names below are the board's own COLOR PALETTE GUIDE swatches,
    # pixel-sampled directly because the board's own printed hex captions
    # are illegible AI-generated text: Tether Purple #8650D6, Dark Charcoal
    # #3A3834, Meadows Green #6C7735, Warm Brown #8B6138, Sky Blue #74B5D4,
    # Cream/Linen #E4D6C2, Ember Orange #F38A37, Slate Gray #6B6B68.
    # Scale: the board's SCALE REFERENCE panel gives grunt 1.7m, officer
    # 1.8m, captain 1.9m against a 1.75m average player -- close to but not
    # identical to the installed grunt rig's own measured 1.80m
    # (data/config/art.json); fit final height in art.json as usual rather
    # than trusting the generator's own scale.
    #
    # Team Tether: THREE grunt bodies, TWO officer bodies, TWO captain
    # bodies -- matching the board's own panel count, not one body per
    # named individual (Dorn/Pell/Kest etc. keep reusing whichever of these
    # three grunt bodies is chosen, via the existing rank/palette system,
    # exactly as the single grunt body is reused across eight-plus named
    # grunts today).
    "grunt_a": (
        "stylised human Team Tether grunt, young male, short dark hair, "
        "black tactical cap with a small purple Tether insignia stud, "
        "black balaclava/face mask covering nose and mouth, alert narrow "
        "eyes. Fitted black tactical jacket with a crossed strap harness, "
        "Tether Purple accent piping, dark cargo trousers, black combat "
        "boots, leather utility belt with pouches, fingerless gloves. Six "
        "heads tall, athletic ready stance, no visible weapon"),
    "grunt_b": (
        "stylised human Team Tether grunt, young female, dark hair in a "
        "short ponytail with a purple-streaked fringe, black balaclava "
        "covering the lower face, sharp confident eyes. Same black "
        "tactical uniform FAMILY as the faction's other grunts -- fitted "
        "jacket, crossed strap harness, Tether Purple accent piping, cargo "
        "trousers, combat boots, utility belt -- differentiated from her "
        "fellow grunts by hairstyle and build, not by a different uniform. "
        "Six heads tall, alert stance"),
    "grunt_c": (
        "stylised human Team Tether grunt, young male, short spiked "
        "blue-grey hair, black balaclava, narrow determined eyes. Same "
        "black tactical uniform family as the faction's other grunts -- "
        "fitted jacket, crossed harness straps, Tether Purple accent "
        "piping, cargo trousers, combat boots, belt pouches. Six heads "
        "tall, alert stance, leaner build than grunt_a"),
    "officer_a": (
        "stylised human Team Tether officer, adult male, short dark hair, "
        "NO MASK -- face fully visible, stern angular jaw, confident "
        "stance. Fitted black long-coat uniform with Tether Purple accent "
        "piping and a stand-up collar, layered command pieces over the "
        "base grunt uniform (extra shoulder strap, chest harness), dark "
        "trousers, tall boots. Six and a quarter heads tall, visibly more "
        "armoured than a grunt but shorter coat than a captain's"),
    "officer_b": (
        "stylised human Team Tether officer, adult female, dark hair "
        "pulled into a high tied bun with loose front strands, NO MASK, "
        "composed authoritative expression. Same black long-coat command "
        "uniform family as officer_a -- Tether Purple accent piping, "
        "stand-up collar, layered chest harness -- with a flared coat "
        "skirt reaching mid-thigh. Six and a quarter heads tall, poised "
        "confident stance"),
    "captain_a": (
        "stylised human Team Tether captain, adult male, shoulder-length "
        "silver-white hair swept back, NO MASK, sharp features, one eye "
        "marked with a dark tactical patch/paint stripe. LONG FULL-LENGTH "
        "TRAILING CAPE reaching past the knees over a fitted black "
        "high-collar coat with layered purple-and-gold command trim, tall "
        "boots, fingerless gloves. THE CAPE AND COAT LENGTH ARE THE "
        "DEFINING SILHOUETTE -- distinctly longer and heavier than the "
        "officer's short coat, this is what must read as \"captain\" from "
        "a distance without seeing a badge. Six and a quarter heads tall, "
        "commanding posture"),
    "captain_b": (
        "stylised human Team Tether captain, adult male, short dark hair "
        "and a full trimmed beard, NO MASK, weathered rugged face. LONG "
        "FULL-LENGTH TRAILING HOODED CLOAK reaching past the knees, over a "
        "fitted black high-collar coat with purple-and-gold command trim "
        "and heavier shoulder armour plates than the officer rank. Tall "
        "boots, wide belt. THE CLOAK, HOOD AND SHOULDER PLATES ARE THE "
        "DEFINING SILHOUETTE -- distinctly bulkier than the officer's "
        "coat. Six and a quarter heads tall, broad commanding stance"),

    # Village & Settlement -- one distinct identity per board panel, each a
    # named individual (Innkeeper is Bram, Craftsperson reads as Tam's
    # role, etc. -- see the plan doc's classification table for the mapping
    # this generation replaces).
    "innkeeper": (
        "stylised human male innkeeper, heavyset warm build, thick brown "
        "beard and curly hair, warm hazel eyes, friendly open smile. Green "
        "scarf knotted at the throat over a rolled-sleeve brown shirt, "
        "blue trousers held by a wide belt with pouches, cream half-apron, "
        "sturdy brown boots. Warm Brown and Meadows Green palette. Six "
        "heads tall, welcoming relaxed stance, empty hands"),
    "inn_helper": (
        "stylised human young female inn helper, short bobbed brown hair "
        "with a simple ribbon, bright cheerful expression. Mustard-yellow "
        "dress with a cream apron over it, simple flat shoes. Warm "
        "Brown/Ember Orange family palette, echoing the innkeeper's own "
        "warm tones. Five and a half heads tall (younger and shorter than "
        "an adult villager), cheerful ready-to-help stance, empty hands"),
    "trader": (
        "stylised human male trader, weathered middle-aged face, short "
        "beard, a deep hood drawn up shadowing the upper face. Long "
        "Meadows Green hooded traveling coat over a Warm Brown tunic, "
        "crossed satchel straps carrying two bags at the hip, sturdy "
        "boots. Muted practical palette, not bright. Six heads tall, "
        "watchful stance, hands visible and empty"),
    "craftsperson": (
        "stylised human male craftsperson, stocky build, thick ginger "
        "beard and moustache, tan flat cap with brass goggles pushed up "
        "on the forehead. Leather apron over a rolled-sleeve shirt, wide "
        "tool belt with visible pouches and a hammer loop, sturdy boots, "
        "fingerless work gloves. Warm Brown/Slate Gray palette. Six heads "
        "tall, confident working stance, empty hands -- tools are a "
        "separate prop, not part of this body"),
    "creature_caretaker": (
        "stylised human young female creature caretaker, shoulder-length "
        "teal-green hair, gentle warm expression. Sage-green short-sleeve "
        "tunic with a small leaf pendant at the throat, olive shorts, a "
        "satchel bag slung across the body, simple boots. Meadows Green "
        "palette. Six heads tall, caring approachable stance, empty hands"),
    "farmer": (
        "stylised human young male farmer, short sandy-brown hair, wide "
        "straw sunhat, friendly sun-weathered face. Rolled-sleeve cream "
        "shirt under brown dungarees, sturdy work boots. Warm Brown "
        "palette with a straw-yellow hat accent. Six heads tall, relaxed "
        "working stance, empty hands -- the pitchfork in the reference is "
        "a separate accessory, not part of this body"),
    "local_historian": (
        "stylised human elderly male local historian, thin build, round "
        "wire-frame glasses, short white hair, neat white beard, "
        "thoughtful scholarly expression. Long muted Meadows Green hooded "
        "traveling coat over simple robes, a small satchel at the hip. "
        "Slate Gray/Meadows Green palette -- echoes Grandpa's colour "
        "family but a distinctly thinner, more scholarly silhouette and "
        "its own coat cut, NOT Grandpa's own face or build. Six heads "
        "tall, contemplative stance, leaning slightly forward -- the cane "
        "in the reference is a separate accessory"),
    "young_trainer": (
        "stylised human boy, youthful round face, short brown hair under "
        "a baseball-style cap worn backward, eager excited expression. "
        "Navy zip jacket over a cream shirt, olive-brown cargo shorts, a "
        "small creature-training backpack with visible straps, sturdy "
        "boots. Warm Brown/Sky Blue palette. Five and a half heads tall "
        "(a child, shorter than the trainer), energetic eager stance"),
    "traveling_merchant": (
        "stylised human adult female traveling merchant, short brown bob "
        "with a loose side-swept fringe, warm shrewd smile. Olive-green "
        "short jacket over a cream blouse, cream apron-skirt, a brown "
        "leather satchel bag and pouches at the hip, sturdy boots. Warm "
        "Brown/Meadows Green palette. Six heads tall, confident welcoming "
        "stance -- the two-wheeled hand-cart in the reference is a "
        "SEPARATE PROP, generate the person alone, no cart geometry"),

    # Trail & Wilderness.
    "rival_trainer": (
        "stylised human boy, spiky sandy-blond hair, confident smirking "
        "expression, freckled face. Rust-orange short-sleeve jacket over "
        "a cream shirt, olive cargo shorts, a creature-training backpack, "
        "sturdy boots. Ember Orange palette, distinct from the player "
        "trainer's own teal jacket. Five and a half heads tall (same age "
        "as the player), cocky confident stance"),
    "field_researcher": (
        "stylised human young female field researcher, straight dark hair "
        "in a low ponytail, round glasses, curious focused expression. "
        "Olive-green field jacket with many visible pockets, a canvas "
        "satchel across the body, simple trousers, sturdy boots. Meadows "
        "Green/Slate Gray palette. Six heads tall, alert observant stance, "
        "empty hands"),
    "wandering_trainer": (
        "stylised human adult male wandering trainer, short dark hair, "
        "wide-brimmed dark travel hat, weathered easygoing expression, "
        "light stubble. Long tan traveling coat over a dark shirt, wide "
        "belt, sturdy boots, a bedroll strapped across the back. Warm "
        "Brown/Slate Gray palette. Six heads tall, relaxed nomadic stance "
        "-- generate the human alone, his companion creature is an "
        "existing roster species and not part of this generation"),
    "lost_traveler": (
        "stylised human young male lost traveler, tousled dark hair, "
        "anxious tired expression, a travel-worn dark Meadows Green cloak "
        "over plain clothes. Simple belt, a large travel backpack with a "
        "bedroll strapped to it, worn boots. Meadows Green/Slate Gray "
        "palette, deliberately more ragged and muted than the settled "
        "village NPCs. Six heads tall, weary uncertain stance"),
    "campfire_traveler": (
        "stylised human young female campfire traveler, dark hair loosely "
        "tied back, warm storytelling expression. Ember Orange scarf over "
        "a dark green hooded travel cloak, layered practical travel "
        "clothes, simple boots. Ember Orange/Meadows Green palette. Six "
        "heads tall, relaxed stance, hands gesturing slightly as if "
        "mid-story"),
    "alpha_tracker": (
        "stylised human adult male alpha tracker, short dark hair under a "
        "wide-brimmed forest-green hat, focused weathered expression, "
        "light stubble. Olive-green ranger jacket with a bandolier of "
        "pouches across the chest, cargo trousers, sturdy boots. Meadows "
        "Green/Warm Brown palette. Six heads tall, alert scouting stance "
        "-- binoculars/bow are separate accessories, not part of this "
        "body"),
    "courier": (
        "stylised human young male courier, short reddish-brown hair "
        "under a flat courier's cap, energetic focused expression. Warm "
        "Brown short jacket over a cream shirt, a satchel/scroll-case bag "
        "slung diagonally across the chest, practical trousers, sturdy "
        "boots built for walking distance. Warm Brown/Cream palette. Six "
        "heads tall, purposeful walking stance"),
    "former_tether_member": (
        "stylised human young adult, deliberately ambiguous gender "
        "presentation, most of the face shadowed by a deep dark hood, "
        "only eyes and nose visible, guarded wary expression. Dark "
        "Charcoal hooded cloak over a fitted dark tunic -- similar cut "
        "and material language to the Team Tether uniform family but "
        "with ALL PURPLE TETHER INSIGNIA AND ACCENT PIPING DELIBERATELY "
        "ABSENT, replaced by plain undecorated dark cloth, signalling a "
        "defector who has stripped the faction's markings. Dark "
        "Charcoal/Slate Gray palette, no Tether Purple anywhere. Six "
        "heads tall, closed-off wary stance"),
}


def api_key() -> str:
    key = os.environ.get("MESHY_API_KEY", "").strip()
    if not key:
        sys.exit(
            "MESHY_API_KEY is not set.\n"
            "\n"
            "  1. Sign up at https://www.meshy.ai/ and open Settings -> API Keys.\n"
            "  2. export MESHY_API_KEY=msy_...\n"
            "  3. tools/art_pipeline/meshy.py check\n"
            "\n"
            "Do not put the key in a tracked file. Everything in the pipeline\n"
            "except generation runs without it."
        )
    return key


def request(method: str, path: str, body: dict | None = None) -> dict:
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(f"{BASE}{path}", data=data, method=method, headers={
        "Authorization": f"Bearer {api_key()}",
        "Content-Type": "application/json",
    })
    try:
        with urllib.request.urlopen(req, timeout=120) as response:
            return json.loads(response.read())
    except urllib.error.HTTPError as error:
        detail = error.read().decode(errors="replace")[:400]
        if error.code == 401:
            sys.exit(f"Meshy rejected the key (401). Check MESHY_API_KEY.\n{detail}")
        if error.code == 402:
            sys.exit(f"Out of credits (402). Nothing was generated.\n{detail}")
        if error.code == 429:
            sys.exit(f"Rate limited (429). Wait and retry.\n{detail}")
        sys.exit(f"Meshy {method} {path} failed with {error.code}:\n{detail}")
    except urllib.error.URLError as error:
        sys.exit(f"could not reach {BASE}: {error.reason}")


def data_uri(path: pathlib.Path) -> str:
    """Meshy takes images as data URIs or public URLs. These are local, so URIs."""
    import base64
    return "data:image/png;base64," + base64.b64encode(path.read_bytes()).decode()


def reference_views(species: str) -> dict[str, pathlib.Path]:
    """Whatever views this species actually has, in VIEWS order.

    Not all of them, for everyone. The Warden's board gives three turnarounds
    and a bust; the legendary's gives two clean hero views among two
    contaminated thumbnails; Grandpa's gives three plus a face portrait.
    Demanding a fixed set either fabricates a view or blocks a character whose
    reference is simply smaller, and multi-image-to-3D reconciles two good
    images better than four bad ones.
    """
    directory = REFERENCE_ROOT / species / "reference"
    found = {view: directory / f"{view}.png"
             for view in VIEWS if (directory / f"{view}.png").exists()}
    if len(found) < 2:
        sys.exit(f"{species} has {len(found)} reference view(s) in {directory}; "
                 f"need at least 2.\nRun tools/art_pipeline/crop_views.py first.")
    return found


def prompt_for(species: str) -> str:
    if species not in SPECIES_PROMPTS:
        sys.exit(f"no prompt for '{species}'. Known: {', '.join(SPECIES_PROMPTS)}.\n"
                 f"Add one from archive/docs/art/CLAUDE_BUILD_PROMPTS.md.")
    style = STYLE_PROP if species in PROPS else STYLE
    return f"{SPECIES_PROMPTS[species]}. {style}"


def cmd_check(_args) -> None:
    balance = request("GET", "/openapi/v1/balance")
    print(f"key accepted. balance: {balance.get('balance', '?')} credits")


def cmd_balance(_args) -> None:
    print(json.dumps(request("GET", "/openapi/v1/balance"), indent=2))


def cmd_generate(args) -> None:
    species = args.species
    views = reference_views(species)
    prompt = prompt_for(species)

    before = request("GET", "/openapi/v1/balance").get("balance", 0)
    estimate = args.candidates * COSTS[
        "image_preview" if args.tier == "preview" else "image_refine"]
    print(f"{species}: {args.candidates} candidate(s), {args.tier} tier")
    print(f"balance {before} credits, this will cost roughly {estimate}")
    if estimate > args.budget and not args.yes:
        sys.exit(f"estimate {estimate} exceeds --budget {args.budget}. "
                 f"Re-run with --yes if that is intended.")

    payload = {
        "mode": "preview" if args.tier == "preview" else "refine",
        "image_urls": [data_uri(p) for p in views.values()],
        "prompt": prompt,
        "negative_prompt": negative_for(species),
        "should_remesh": True,
        "should_texture": args.tier != "preview",
        # Quad remesh suits organic deformation; a hard-surface structure at a
        # 2-3K triangle budget keeps its edges better triangulated directly.
        "topology": "triangle" if species in PROPS else "quad",
        "target_polycount": args.polycount,
        "symmetry_mode": "auto",
    }

    manifest = {
        "species": species,
        "tier": args.tier,
        "prompt": prompt,
        "negative_prompt": negative_for(species),
        "views": {v: str(p.relative_to(ROOT)) for v, p in views.items()},
        "polycount": args.polycount,
        "tasks": [],
    }

    for index in range(args.candidates):
        # Candidates differ only by the generator's own seed; the prompt and the
        # reference images are identical on purpose, so the comparison in
        # compare_sheet.py measures the generator's variance rather than ours.
        result = request("POST", "/openapi/v1/multi-image-to-3d", payload)
        task_id = result.get("result") or result.get("id")
        letter = chr(ord("a") + index)
        manifest["tasks"].append({"candidate": letter, "task_id": task_id})
        print(f"  candidate {letter}: {task_id}")

    out = RAW_ROOT / species
    out.mkdir(parents=True, exist_ok=True)
    (out / "manifest.json").write_text(json.dumps(manifest, indent=2))
    print(f"\nmanifest: {out / 'manifest.json'}  (no key is recorded in it)")
    print(f"poll with: tools/art_pipeline/meshy.py status <task_id>")


## Task endpoints, by the stage that created the task. Every Meshy task type
## lives under its own path and none of them answer for another's ids.
ENDPOINTS = {
    "generate": "/openapi/v1/multi-image-to-3d",
    "text": "/openapi/v2/text-to-3d",
    "texture": "/openapi/v1/retexture",
    "rig": "/openapi/v1/rigging",
    "animate": "/openapi/v1/animations",
}


def poll(task_id: str, endpoint: str, quiet: bool = False) -> dict:
    deadline = time.time() + POLL_TIMEOUT
    while time.time() < deadline:
        task = request("GET", f"{endpoint}/{task_id}")
        status = task.get("status", "?")
        if status in ("SUCCEEDED", "FAILED", "CANCELED", "EXPIRED"):
            return task
        if not quiet:
            print(f"  {status} {task.get('progress', 0)}%", flush=True)
        time.sleep(POLL_SECONDS)
    sys.exit(f"{task_id} did not finish within {POLL_TIMEOUT // 60} minutes")


def cmd_status(args) -> None:
    task = request("GET", f"{ENDPOINTS[args.stage]}/{args.task_id}")
    print(f"{args.task_id}: {task.get('status')} {task.get('progress', 0)}%")
    if task.get("task_error"):
        print(f"  error: {task['task_error']}")
    for name, url in (task.get("model_urls") or {}).items():
        print(f"  {name}: {'ready' if url else '-'}")


def cmd_fetch(args) -> None:
    task = poll(args.task_id, ENDPOINTS[args.stage])
    if task.get("status") != "SUCCEEDED":
        sys.exit(f"{args.task_id} finished as {task.get('status')}: "
                 f"{task.get('task_error', 'no detail')}")

    out = pathlib.Path(args.out).resolve()
    out.mkdir(parents=True, exist_ok=True)

    # The generate/texture stages return a `model_urls` map; rigging and
    # animation instead nest theirs under `result` with per-format keys
    # (`rigged_character_glb_url`). Both are normalised to the same little
    # {format: url} dict here, because the first rig task of the project
    # reported SUCCEEDED and then "returned no GLB" — the file was there, in
    # a shape this function did not look at.
    urls = dict(task.get("model_urls") or {})
    result = task.get("result")
    if isinstance(result, dict):
        for key, url in result.items():
            if not isinstance(url, str) or not key.endswith("_url"):
                continue
            for fmt in ("glb", "fbx", "obj"):
                if f"_{fmt}_" in key or key.endswith(f"_{fmt}_url"):
                    urls.setdefault(fmt, url)
    if not urls.get("glb"):
        sys.exit(f"{args.task_id} succeeded but returned no GLB")

    for name in ("glb", "fbx", "obj"):
        if not urls.get(name):
            continue
        target = out / f"model.{name}"
        urllib.request.urlretrieve(urls[name], target)
        print(f"  {target.name}  {target.stat().st_size // 1024} KB")

    if task.get("thumbnail_url"):
        urllib.request.urlretrieve(task["thumbnail_url"], out / "thumbnail.png")

    # Provenance, written next to the asset so docs/specs/ASSET_LEDGER.md can be filled
    # in from fact rather than memory. No key, no signed URLs — those expire and
    # leak.
    (out / "provenance.json").write_text(json.dumps({
        "service": "Meshy",
        "endpoint": ENDPOINTS[args.stage].rsplit("/", 1)[-1],
        "task_id": args.task_id,
        "created_at": task.get("created_at"),
        "finished_at": task.get("finished_at"),
        "prompt": task.get("prompt"),
        "negative_prompt": task.get("negative_prompt"),
        "art_style": task.get("art_style"),
        "texture_richness": task.get("texture_richness"),
    }, indent=2))
    print(f"\n{out}")
    print("  next: inspect_glb.py, then turntable.py, then compare_sheet.py")


## Head-only prompts. Deliberately short and about nothing but the face —
## naming a jacket here would invite the generator to model one.
HEAD_PROMPTS = {
    "trainer": (
        "stylised human boy's HEAD AND NECK ONLY, bust, no body. Deep eye "
        "sockets with rounded eyeballs and eyelids, thick angled eyebrows, "
        "projecting nose with a defined tip and nostrils, closed smiling "
        "mouth with modelled lips, defined jaw and chin, ears. Big messy "
        "spiky swept hair falling over the forehead"),
    # Round 2. The first head grafted cleanly and its FACE was right, but the
    # gate review called the hair "an outright defect, not a style choice":
    # a thick bright-white bouffant where the concept has thin receding grey,
    # and in profile "a mass of blobby waxy lobes with random spikes poking
    # through, like a cauliflower". It also found the face rounder and younger
    # than the concept's gaunt, hollow-cheeked old man. Both are named here.
    # The Warden's head crop is cut from board 06's full figure, so it is a
    # ~165px region upscaled and visibly soft — REFERENCE_CANON.md's standing
    # warning about this character's reference is that it is too small to drive
    # image-to-3D. It is used anyway, because for a MASKED face the image only
    # has to carry the layout (visor band across the eyes, wrap over nose and
    # mouth, spiky hair above) and the prompt carries the form. If it returns
    # mush, the body ships without a graft and the mask stays painted.
    "warden": (
        "stylised man's HEAD AND NECK ONLY, bust, no body, masked soldier. "
        "A THICK HARD VISOR BAND across the eyes, standing proud of the face "
        "as a raised rigid panel with sharp edges, and a separate FITTED MASK "
        "PLATE covering nose and mouth, also raised and hard edged, so the "
        "face is hidden behind two solid layers. Strong jaw below the mask, "
        "short spiky swept hair, ears"),
    "grandpa": (
        "stylised elderly man's HEAD AND NECK ONLY, bust, no body. GAUNT "
        "hollow-cheeked face, sharp cheekbones, lined and wrinkled, HIGH "
        "RECEDING HAIRLINE with a bare forehead and only THIN SPARSE WISPY "
        "grey hair swept back close to the skull, never thick, never a full "
        "bouffant. Deep eye sockets with eyelids and heavy brows, projecting "
        "bony nose, kind closed mouth, full grey beard and moustache in "
        "combed directional strands covering the jaw, round ears"),
}


def cmd_head(args) -> None:
    """Generate a head on its own, because a whole-body pass will not make one.

    Nine humanoid candidates across three characters and three rounds have now
    come back with the same defect, in the blind critic's words: "there is no
    face on any of the three ... a featureless ovoid with hair over it". The
    prompt is not the problem — it has demanded sockets, lids, brows and a cut
    mouth since round 2, in capitals.

    The problem is resolution allocation. At a 30k budget spread over a whole
    standing figure, the head is a few percent of the surface area, and an eye
    socket is smaller than the triangles available to describe it. Generating
    the head ALONE spends the entire budget on the part that has been failing,
    which is the one change that has not been tried.

    A head crop is a single image, so this goes through multi-image-to-3d with
    one view rather than the four a turnaround gives. That is a real cost — the
    generator invents the back of the skull — but the back of the skull is hair,
    and hair is the one thing the whole-body passes have consistently got right.
    """
    if args.species not in HEAD_PROMPTS:
        sys.exit(f"no head prompt for '{args.species}'. Known: "
                 f"{', '.join(HEAD_PROMPTS)}.")
    crop = REFERENCE_ROOT / args.species / "reference" / "head.png"
    if not crop.exists():
        sys.exit(f"{args.species} has no head crop at {crop}. Add a 'head' entry "
                 f"to tools/art_pipeline/views.json and re-run crop_views.py.")

    prompt = f"{HEAD_PROMPTS[args.species]}. {STYLE}"
    before = request("GET", "/openapi/v1/balance").get("balance", 0)
    estimate = args.candidates * COSTS["image_preview"]
    print(f"{args.species}: {args.candidates} head candidate(s), preview tier")
    print(f"balance {before} credits, this will cost roughly {estimate}")
    if estimate > args.budget and not args.yes:
        sys.exit(f"estimate {estimate} exceeds --budget {args.budget}.")

    manifest = {"species": args.species, "mode": "head-only", "prompt": prompt,
                "negative_prompt": negative_for(args.species),
                "views": {"head": str(crop.relative_to(ROOT))}, "tasks": []}
    for index in range(args.candidates):
        result = request("POST", ENDPOINTS["generate"], {
            "mode": "preview",
            "image_urls": [data_uri(crop)],
            "prompt": prompt,
            "negative_prompt": negative_for(args.species),
            "should_remesh": True,
            "should_texture": False,
            "topology": "quad",
            "target_polycount": args.polycount,
            "symmetry_mode": "on",
        })
        task_id = result.get("result") or result.get("id")
        letter = f"head-{chr(ord('a') + index)}"
        manifest["tasks"].append({"candidate": letter, "task_id": task_id})
        print(f"  candidate {letter}: {task_id}")

    out = RAW_ROOT / args.species
    out.mkdir(parents=True, exist_ok=True)
    (out / "head_manifest.json").write_text(json.dumps(manifest, indent=2))
    print(f"\nmanifest: {out / 'head_manifest.json'}")


def cmd_text(args) -> None:
    """Generate from the written spec alone, for a species with no sheet.

    The three starters, the trainer, Grandpa, the Warden and the legendary all
    have drawn reference. The twelve wild Meadows species do not — they exist
    as prose in archive/docs/art/CLAUDE_BUILD_PROMPTS.md and as scattered silhouette
    donors on the exploration boards, which is not enough to reconcile a
    multi-view reconstruction.

    So: text-to-3D for the FORM, then `texture` against a starter's concept
    crop for the STYLE. That second half is the important half. Style cohesion
    is the complaint that survived two blind reviews of the old roster —
    "two assets from two different pipelines" — and pointing every wild
    creature's texture pass at the same drawn reference is what stops thirteen
    independently-generated animals from looking like thirteen packs.
    """
    prompt = prompt_for(args.species)
    # Meshy rejects text-to-3D prompts over 800 characters, and it rejects them
    # at submission — after the balance call, and with a message that names the
    # limit but not the length. The cap applies to the FINAL string, STYLE
    # suffix included, which is the part that is easy to forget when writing a
    # species prompt. Fail here, with the arithmetic, instead of at the API.
    if len(prompt) > TEXT_PROMPT_LIMIT:
        sys.exit(
            f"'{args.species}' prompt is {len(prompt)} characters; Meshy's "
            f"text-to-3D limit is {TEXT_PROMPT_LIMIT}. The STYLE suffix adds "
            f"{len(prompt) - len(SPECIES_PROMPTS[args.species])}, so "
            f"SPECIES_PROMPTS['{args.species}'] must be at most "
            f"{TEXT_PROMPT_LIMIT - (len(prompt) - len(SPECIES_PROMPTS[args.species]))} "
            f"(currently {len(SPECIES_PROMPTS[args.species])}).")

    before = request("GET", "/openapi/v1/balance").get("balance", 0)
    estimate = args.candidates * COSTS["text_preview"]
    print(f"{args.species}: {args.candidates} candidate(s), text-to-3D preview")
    print(f"balance {before} credits, this will cost roughly {estimate}")
    if estimate > args.budget and not args.yes:
        sys.exit(f"estimate {estimate} exceeds --budget {args.budget}.")

    manifest = {"species": args.species, "mode": "text-to-3d", "prompt": prompt,
                "negative_prompt": negative_for(args.species), "tasks": []}
    for index in range(args.candidates):
        result = request("POST", ENDPOINTS["text"], {
            "mode": "preview",
            "prompt": prompt,
            "negative_prompt": negative_for(args.species),
            "art_style": "realistic",
            "should_remesh": True,
            "topology": "quad",
            "target_polycount": args.polycount,
            "symmetry_mode": "auto",
        })
        task_id = result.get("result") or result.get("id")
        letter = chr(ord("a") + index)
        manifest["tasks"].append({"candidate": letter, "task_id": task_id})
        print(f"  candidate {letter}: {task_id}")

    out = RAW_ROOT / args.species
    out.mkdir(parents=True, exist_ok=True)
    (out / "manifest.json").write_text(json.dumps(manifest, indent=2))


def cmd_texture(args) -> None:
    """Texture a local GLB against the species' own concept art.

    Retexture rather than re-generating with textures on, for two reasons.
    First, §25: form was selected at the cheap tier, and only the winner gets
    textured. Second, retexture takes `image_style_url` — the 3/4 concept crop
    itself — which aims the texturing at the drawing instead of at a text
    description of the drawing. The words come along too, but the image is the
    stronger signal and it is the exact likeness being scored.
    """
    model = pathlib.Path(args.model).resolve()
    if not model.exists():
        sys.exit(f"no such model: {model}")
    # A wild species has no crops of its own; --style-from points its texture
    # pass at a species that does, which is how thirteen separately-generated
    # animals end up looking like one pack.
    views = reference_views(args.style_from or args.species)

    payload = {
        "model_url": ("data:model/gltf-binary;base64,"
                      + __import__("base64").b64encode(model.read_bytes()).decode()),
        "text_style_prompt": prompt_for(args.species)[:600],
        "image_style_url": data_uri(views.get("three_quarter") or views.get("front")
                                   or next(iter(views.values()))),
        "enable_pbr": True,
        "enable_original_uv": False,
        "texture_resolution": args.resolution,
        "ai_model": "latest",
    }
    result = request("POST", ENDPOINTS["texture"], payload)
    task_id = result.get("result") or result.get("id")
    print(f"texture task: {task_id}")
    print(f"fetch with: tools/art_pipeline/meshy.py fetch {task_id} "
          f"--stage texture --out <dir>")


def cmd_rig(args) -> None:
    """Submit a textured GLB for auto-rigging.

    Meshy documents this as HUMANOID-only, and Terrapup is a quadruped, so this
    is expected to fail or produce nonsense for creatures — it exists because
    trying costs a few credits and the answer becomes a fact in the production
    report instead of an assumption. The trainer, when its turn comes, is the
    real customer.
    """
    model = pathlib.Path(args.model).resolve()
    if not model.exists():
        sys.exit(f"no such model: {model}")
    payload = {
        "model_url": ("data:model/gltf-binary;base64,"
                      + __import__("base64").b64encode(model.read_bytes()).decode()),
        "height_meters": args.height,
    }
    result = request("POST", ENDPOINTS["rig"], payload)
    task_id = result.get("result") or result.get("id")
    print(f"rig task: {task_id}")
    print(f"fetch with: tools/art_pipeline/meshy.py fetch {task_id} --stage rig --out <dir>")


def cmd_animate(args) -> None:
    payload = {"rig_task_id": args.rig_task_id, "action_id": args.action_id}
    result = request("POST", ENDPOINTS["animate"], payload)
    task_id = result.get("result") or result.get("id")
    print(f"animation task: {task_id}")
    print(f"fetch with: tools/art_pipeline/meshy.py fetch {task_id} "
          f"--stage animate --out <dir>")


def main() -> None:
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="command", required=True)

    sub.add_parser("check", help="verify the key and print the balance").set_defaults(func=cmd_check)
    sub.add_parser("balance", help="raw balance response").set_defaults(func=cmd_balance)

    gen = sub.add_parser("generate", help="submit candidates for a species")
    gen.add_argument("species", help=", ".join(SPECIES_PROMPTS))
    gen.add_argument("--candidates", type=int, default=3)
    gen.add_argument("--tier", choices=["preview", "refine"], default="preview",
                     help="preview is cheap and untextured; refine costs more (§25)")
    gen.add_argument("--polycount", type=int, default=30000)
    gen.add_argument("--budget", type=int, default=DEFAULT_BUDGET)
    gen.add_argument("--yes", action="store_true", help="proceed past the budget guard")
    gen.set_defaults(func=cmd_generate)

    head = sub.add_parser("head", help="generate a head alone, for grafting")
    head.add_argument("species")
    head.add_argument("--candidates", type=int, default=2)
    head.add_argument("--polycount", type=int, default=30000)
    head.add_argument("--budget", type=int, default=DEFAULT_BUDGET)
    head.add_argument("--yes", action="store_true")
    head.set_defaults(func=cmd_head)

    text = sub.add_parser("text", help="generate from the written spec (no sheet)")
    text.add_argument("species")
    text.add_argument("--candidates", type=int, default=2)
    text.add_argument("--polycount", type=int, default=30000)
    text.add_argument("--budget", type=int, default=DEFAULT_BUDGET)
    text.add_argument("--yes", action="store_true")
    text.set_defaults(func=cmd_text)

    texture = sub.add_parser("texture", help="retexture a local GLB against the concept art")
    texture.add_argument("species")
    texture.add_argument("model", help="path to the winning candidate's GLB")
    texture.add_argument("--resolution", choices=["2k", "4k"], default="2k")
    texture.add_argument("--style-from", default=None,
                         help="take the style image from another species' crops")
    texture.set_defaults(func=cmd_texture)

    rig = sub.add_parser("rig", help="auto-rig a textured GLB (Meshy: humanoid-only)")
    rig.add_argument("model")
    rig.add_argument("--height", type=float, default=1.7)
    rig.set_defaults(func=cmd_rig)

    animate = sub.add_parser("animate", help="apply a library action to a rig task")
    animate.add_argument("rig_task_id")
    animate.add_argument("action_id", type=int)
    animate.set_defaults(func=cmd_animate)

    status = sub.add_parser("status", help="one task's progress")
    status.add_argument("task_id")
    status.add_argument("--stage", choices=list(ENDPOINTS), default="generate")
    status.set_defaults(func=cmd_status)

    fetch = sub.add_parser("fetch", help="wait for a task and download it")
    fetch.add_argument("task_id")
    fetch.add_argument("--stage", choices=list(ENDPOINTS), default="generate")
    fetch.add_argument("--out", required=True)
    fetch.set_defaults(func=cmd_fetch)

    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
