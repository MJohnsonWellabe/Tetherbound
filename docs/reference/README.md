# Reference set — the world

What each image is for, and how it may be used to judge the build.

**This folder is the world target.** Characters have their own, in
`docs/art/reference/` — nineteen creature and human references, with
`docs/art/REFERENCE_CANON.md` deciding which of the four contradictory rosters in
that pack is authoritative. The visual critic judges terrain, foliage, palette
and composition against the images here, and creatures and the trainer against
the sheets there. Neither set substitutes for the other, and item 4 below is the
seam between them.

## `tetherbound-meadows-keyart.png` — the primary reference

The owner's Meadows art direction board. This is the target, and it is specific
to this game rather than borrowed from another one.

It carries five usable things:

1. **The palette**, sampled into `data/config/palette.json`. Materials, UI and
   lighting all read from that file so they cannot drift apart.
2. **Its own art notes**, quoted rather than paraphrased: stylized realism
   between Valheim and Palworld; vibrant, readable colours with a natural
   palette; silhouettes and landmarks visible from distance; cozy and inviting
   but with hints of mystery; day and night create different moods.
3. **Named framings** — STARTING SETTLEMENT, TEAM TETHER STRONGHOLD (MEADOWS
   HALL), DAY, NIGHT. These become the fixed camera positions for any
   screenshot survey, so the build is judged against the panel it is trying to
   be rather than against a general impression.
4. **A creature silhouette row** — rabbit, boar, deer, raptor, turtle, canine.
   This was the acceptance test for a bought creature pack: cover those six
   cohesively, or bend `docs/GAME_DESIGN.md` §26 to fit what the pack holds.
   **That trade is off the table now.** The owner's reference pack names all
   nineteen characters and gives production sheets for four of them, so the
   roster is built to the design rather than the design to the roster. The row
   survives as a silhouette-variety check: if the finished creatures do not
   spread across it, they are too similar to each other.
5. **The reserved danger colour.** The oxblood red appears only on Team Tether
   banners in the stronghold panel. Keep it that way.

## `palworld-0*.jpg` — secondary, for a different question

Five Palworld screenshots, carried over from the abandoned prototype. They are
useful for one thing the painted board cannot show: what a **real-time engine**
actually achieves. Ground cover density, creature readability at combat
distance, HUD hierarchy, and how much atmospheric haze a stylised game gets away
with.

## How NOT to use these

**Do not score the build for per-pixel fidelity against the key art.** It is
painted concept work with per-leaf canopy detail, refractive water with
caustics, and painterly global illumination. No real-time stylised game reaches
that, and treating it as a literal bar produces a permanent "we never get
there" verdict that tells nobody anything.

This is not hypothetical. The previous prototype was reviewed against the
Palworld screenshots exactly that way, and the useful findings — no cast
shadows, ground reading as dirt with props stabbed into it, a world that looked
generated rather than placed — were structural, not fidelity gaps. Those are the
kind of finding worth chasing.

Judge against these images for **palette, composition, landmark language,
silhouette and mood**. Judge fidelity against what the engine can hold at frame
rate on the Ally.
