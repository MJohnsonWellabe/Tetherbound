# Owner playtest and direction — 2026-09-07

Recorded verbatim so it survives session turnover. Under `CLAUDE.md`'s precedence
this is **owner-play evidence and outranks every other document in this repo for
what it covers**, including any green test or completion claim that contradicts it.
A current owner reproduction reopens an item even if a report says it shipped.

Build played: the shipped Windows build on the ROG Ally, on or before 2026-09-07
(the `release.yml` asset current at that time; `main` was at or near `ba8a66fb`,
PR #77). Check the release asset timestamp before assuming a later fix was in it.

## Verbatim — playtest

> Played the game. It froze a lot at the beginning then after about ten minutes it
> just froze for good while placing a second creature bed without going back to the
> menu.
>
> In the meadows there are still long bare patches on the road that don't have any
> creatures. I'd expect to always be able to see multiple creatures in a 180 view in
> front of me.

## Verbatim — direction for the next orchestration run

> There's a ton of outstanding work to do. The visual agent has noted several things
> that don't work together. The kickoff ms also noted performance issues. Claude lanes
> have left handoff files detailing work that needs to be done. Codex lanes have
> started building the next two biomes but haven't completed. There's instructions for
> full visual audit over everything. There's a Claude file that detailed changing
> combat to make it better.
>
> There are new creatures and characters that need to be plugged into the right places
> (choose a character menu showing all four, and biomes for the creatures).
>
> Don't focus too much on performance yet. Focus more on making things look good and
> the rest of the content. We will come back to performance but you can do the easy
> wins first.
>
> [The next run] should use a lot of subagents to do things in parallel. It should
> work on its own branch then merge to main when it's ready.

## What this reopens or sets

- **P0 — hard freeze placing a second creature bed** (no return to menu; process
  hung). New. The older "Gate B's tail stalls placing creature beds (3 of 5)" item in
  `docs/CURRENT_STATE.md` §3 is the same area and is reopened by this reproduction.
- **P0 — repeated freezes in the first ten minutes** of a fresh game on the Ally.
  Reopens the "froze for a while" note from `OWNER_PLAYTEST_2026-09-05.md`.
- **P1 — Meadows road creature presence.** Bar, in the owner's words: multiple
  creatures visible in a 180° view ahead of the player, always, on the road. The
  2026-09-05 note "very few creatures after I leave the village and run towards
  bridge" is reopened; whatever `GATE3_CREATURE_PRESENCE` closed is not enough.
- **Priority order for the next run:** looks and content first, then the remaining
  performance work; take only the cheap performance wins now.
- **Character select** must show all four playable characters; the new creature
  roster must be placed in its biomes' spawn and encounter tables.
