# Owner playtest — 2026-08-30

Recorded by the coordinator as given, so it survives session turnover. Under
`CLAUDE.md`'s precedence rules this is **owner-play evidence and outranks every
other document in this repo for what it covers** — including any green test or
prior completion claim that contradicts it.

A current owner reproduction reopens an item even if `DONE.md` says it shipped.
Where a regression test still passes while the owner path fails, **the
false-positive coverage gap is part of the defect** and must be fixed with it.

---

## OP-0830-1 — The village gate does not gate

> "the village gate is pointless. it doesn't keep you in. it should keep you in
> until you find the key."

The gate is decoration. The player can leave without the key, so the key, the
search for it, and the gate itself all lose their meaning — and the authored
first-act structure silently collapses.

**Intended behaviour:** the gate physically holds the player inside until the
key is found. This is the spec's own "the world itself creates the gate" rule
(`MEADOWS_PROGRESSION_SPEC` §1/§15) — a physical barrier, not a UI lock and not
a level requirement.

Start from `scripts/world/item_gate.gd`, `gated_crossing.gd`, `village.gd`, and
whatever collider the village boundary actually builds. Confirm by **playing
it**: walk at the gate without the key and fail to pass; pick the key up and
pass. A test asserting a flag is not evidence.

## OP-0830-2 — The key does not glow

> "the key should glow."

The player is told to find a key and then given no visual affordance for it.

## OP-0830-3 — Nothing in the grass glows

> "all items in the grass like tms, potions, orbs whatever should glow so
> they're visible."

Every world pickup — TMs, potions, orbs, consumables, caches, key items — needs
a visible affordance that reads at normal player distance and against real
grass. This is the same class of defect as OP-0830-2 and should be solved once,
as a shared pickup-highlight treatment, not per item.

Note the interaction with the ground lane's work: grass density is being
increased, which makes this *worse*, not better. Whatever the treatment is, it
must be verified against real grass at the density that is shipping — and the
capture harness has a known defect where frames render with no grass at all, so
a frame that looks fine may be lying.

## OP-0830-4 — Trapped in Grandpa's house after the first conversation

> "after the first conversation with grandpa you're trapped in his house with
> nothing telling you to talk to him again before you can go."

The player finishes the opening conversation, cannot leave, and is given **no
indication** that talking to Grandpa a second time is what releases them. This
is a dead stop in the first two minutes of the game — the single worst place in
the chapter to lose a player.

**This is also a coverage failure.** `tests/smoke_opening.gd` and
`tests/smoke_wake_softlock.gd` both exist and pass. They did not catch this,
which means they assert the door gate's flag rather than the player's
experience of it. Fix the pedagogy AND close the gap that let it pass.

Start from `scripts/world/grandpa_house.gd` (`_build_door_gate`),
`scripts/story/opening_beats.gd`, `data/config/opening.json`, and the objective
system's own reveal path (`quest_log.gd` / `tab_quest_log.gd`).

The fix is direction, not a wall of text: the tracked objective should name the
next action, and Grandpa himself should read as interactable.

## OP-0830-5 — Catching is far too hard

> "catching is way too hard."

Catching is a core verb and one of the primary sources of team-building joy.
The vision's own words: seeing a desirable wild creature should be *exciting
rather than administrative*. If it is a chore, the five-creature promise never
lands.

Tune it against `data/config/catching.json` / `combat.json` and the real orb
throw path. **Diagnose before tuning**: is the failure rate the catch formula,
the aim/throw feel, the HP/status precondition, the window, or the orb's flight
and collision? Fix what is actually wrong rather than multiplying the success
rate and hoping.

Verify by playing a real catch loop repeatedly and reporting an actual measured
success rate at a representative early-game encounter — before and after.

## OP-0830-6 — ROG Ally performance is still bad

> "the game performance on a rog is pretty bad still."

Unchanged from the 2026-08-21 owner playtest, which also led with ROG lag. Every
visual lane has since added geometry, lights and scatter against a budget that,
as of today, **has never been measured or written down** — two separate lanes
went looking for a documented ROG light budget and found none exists.

This is `MEADOWS_EXIT_CRITERION.md` J4 and K: performance is pass/fail, and
beauty that kills the frame rate is not a pass.

Owned by the `T1-PERF` lane opened 2026-08-30. Note honestly what headless
measurement can and cannot settle — some of this needs a real device run, and
saying so is better than inventing a number.

---

## Coordinator routing, 2026-08-30

| Item | Lane |
|---|---|
| OP-0830-1 gate, OP-0830-2 key glow, OP-0830-4 Grandpa trap | `ralph/T5-OPENING` |
| OP-0830-3 pickup glow, OP-0830-5 catching difficulty | `ralph/T5-FEEL` |
| OP-0830-6 ROG performance | `ralph/T1-PERF` (already open) |

All six are first-hour-of-the-game defects except the last, which is
everywhere. Together they are the difference between a player continuing and a
player stopping, which makes them higher priority than any remaining polish
item on the board.
