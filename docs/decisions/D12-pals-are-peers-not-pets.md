# D12 — Pals stand as peers to the trainer, not as pets at his ankles

> Starter scale amended by D19 (owner decision, 2026-08-09).

**Status:** accepted, by the owner
**Decided:** after seeing the first three starters standing in the meadow

## The decision

Creatures are scaled to **stand as peers to the 1.8 m trainer**. Starters are
1.55–1.70 m; wild pals run 1.35–2.00 m.

The owner's words: *"can we make the pals canonically about the same size as
the character... just want them to have more emphasis and focus in the game so
the large size will be good."*

## What changed

| | before | after |
|---|---|---|
| Terrapup | 1.20 m | **1.70 m** |
| Ripplet | 1.05 m | **1.60 m** |
| Galewisp | 1.00 m | **1.55 m** |
| Bramblebun | 0.95 m | **1.35 m** |
| Tuskroot | 1.45 m | **2.00 m** |

Collider radius scales by the same ratio as height for each species, so the
hit cone's reach and the catch formula's accuracy bonus keep the relative
tuning they were given — a creature does not become easier to hit *relative to
its own size* because everything grew.

## The tension this resolves, and how

The reference sheets carry real-world sizes: Terrapup is drawn at 0.45 m at
the shoulder against a 1.75 m human, Ripplet at 0.45 m, Galewisp at
0.45–0.50 m. Those numbers stay in the sheets and stay true — they are the
creature's **biology**.

Game scale is a different question, and the answer is now different. A 0.45 m
creature beside a 1.8 m trainer is a pet: it lives in the bottom quarter of
the frame, its face is never legible without a dedicated camera, and a fight
between two of them reads as something happening on the floor. At 1.6 m the
same creature is a character standing next to you — which is what a game whose
entire premise is *five pals who become emotionally important* needs its pals
to be.

`species.json` records the split explicitly so nobody later "fixes" the
heights back to the sheets.

## What this does NOT change

- **GAME_DESIGN.md §26's "pal size should vary substantially"** still holds.
  The range simply recentres: 1.35 m for the small practice creature to 2.00 m
  for the one that ambushes you, and the legendary above all of them.
- **The sheets' proportions.** Only the overall metre figure moves; every
  head-to-body ratio, paw size and mantle placement is untouched.
- **The arena.** It stays at 11 m radius. Two 1.7 m creatures in an 11 m circle
  still have room to circle each other, and a fight that feels cramped is a
  playtest finding, not a prediction.

## Watch for, at the next playtest

- Two peer-sized fighters may crowd the combat camera; `camera` in
  `combat.json` is the first dial if they do.
- Attack reach was tuned when creatures were ~1.2 m. It is derived from
  `body_radius()`, so it scaled automatically, but whether it *feels* right at
  the new size is a question only playing answers.
- Wild pals now loom over the trainer in the world. That is the intent.
