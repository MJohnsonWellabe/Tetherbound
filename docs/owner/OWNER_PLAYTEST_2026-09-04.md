# Owner playtest — 2026-09-04 (ROG Ally)

Recorded verbatim so it survives session turnover. Under `CLAUDE.md`'s precedence
this is **owner-play evidence and outranks every other document in this repo for
what it covers**, including any green test or completion claim that contradicts it.
A current owner reproduction reopens an item even if a report says it shipped.

## Verbatim

> Someone has to reorganize the opening village still make it houses along a road
> instead of in a circle. Have a field of berries, a grove of trees and a stone area.
>
> There are still too many people in the village. 5 at most. Put the rest throughout
> the rest of the game.
>
> There is no night time.
>
> When you ride your person didn't show up on the creature.
>
> There isn't enough to do anywhere. Creatures are only really around the village the
> sparse anywhere else. There's nothing to take you off the path.
>
> Burrow warrens looks terrible.
>
> The game plays great. Visuals and content are the big my issues mostly. And it's
> really content after leaving the village. Bonding needs to mean more. I need more of
> a reason to fight everyone. I need more things to go gather. Maybe things pop up on
> the map and tell you to go do them.
>
> You can't sprint or jump when riding.
>
> Camping isn't necessary. It needs to be necessary.
> Beating creatures and other trainers is way too easy.
>
> The legendary should be in the machine not in a ring outside the machine.
>
> Burrowback and the grownup mudsnout should be rideable. Terrapup too. That means the
> other starters have to get special abilities. One should get fly and one teleport.
> But you can't use them till you learn them in the game. Nothing that is rideable
> should come with a saddle on it. You have to build the saddle and put it on then it
> visually appears. It shouldn't visually be there.

Plus a photograph of the kickoff run failing on the Ally — see OP-0904-0.

## The headline the owner led with

**"The game plays great."** The complaint is visuals and content, and specifically
content *after leaving the village*. Read every item below against that: the core
verbs are not the problem, the chapter's substance is.

---

## OP-0904-0 — The kickoff run aborts before it runs anything

Not in the owner's words but in the photograph: `kickoff.ps1` dies at parse time with
a wall of `Variable reference is not valid. ':' was not followed by a valid variable
name character`, then `Kickoff finished with exit code 1`.

Inside a double-quoted PowerShell string, `$Seg:` is not "variable then colon" — the
parser reads `Seg:` as a drive or scope qualifier, the way `$env:PATH` does, and fails
on the space. Ten occurrences (`$Name:` ×4, `$Seg:` ×6). Fixed the same day with
`${Seg}:`, and `tests/test_kickoff_script_syntax.gd` now guards the class, because CI
has no Windows runner and the first parse was on the owner's machine.

**This is why there is no other hardware evidence in this playtest.** Everything the
kickoff was built to collect — GPU frame rate, the route strip, the shipped build
under `--verify-export`, S01–S10e with video — did not happen.

## OP-0904-1 — The village is the wrong shape, and too crowded

> houses along a road instead of in a circle. Have a field of berries, a grove of
> trees and a stone area. / There are still too many people in the village. 5 at
> most. Put the rest throughout the rest of the game.

Two changes in one: **the plan** (a road with houses along it, plus three named
resource areas — berries, trees, stone) and **the population** (five villagers
maximum, the rest redistributed into the chapter). Note the second half is content
placement, not deletion: the villagers move out into the world, which is also part of
the answer to OP-0904-4.

`data/config/village.json`, `village_npcs.json`, `props.json`, band 1 `harvest.json`.

## OP-0904-2 — There is no night time

Flat. The day cycle either is not advancing on the real build or is not reaching
night. Note the repo currently believes otherwise: `docs/CURRENT_STATE.md` §3 carries
"day counter stuck / night reads as dusk" as *needs owner confirmation*, and the
NIGHT-LEGIBILITY work tuned night lighting against rendered night frames. This
reproduction closes that question in the negative and outranks the probes.

`scripts/world/day_cycle.gd`, `world_look.gd`, and whatever the shipped build does
differently from the harness.

## OP-0904-3 — Riding is unfinished in three ways

> When you ride your person didn't show up on the creature.
> You can't sprint or jump when riding.
> Nothing that is rideable should come with a saddle on it. You have to build the
> saddle and put it on then it visually appears. It shouldn't visually be there.

The rider is invisible; sprint and jump are lost while mounted; and the saddle is
worn before it is earned. The third is a design rule, not a bug: **the saddle must be
absent from the model until built and fitted, then appear.** It is the visible proof
of the craft the riding unlock is built around.

`scripts/world/riding_controller.gd`, the mount attach point on `creature_body.gd`,
the saddle recipe path.

## OP-0904-4 — There is not enough to do, and nothing pulls you off the path

> Creatures are only really around the village the sparse anywhere else. There's
> nothing to take you off the path. / I need more things to go gather. Maybe things
> pop up on the map and tell you to go do them.

The single largest content item in this playtest, and it agrees with what the
instruments already measured from the other side: band 5 ships 23 spawns and 8 harvest
nodes over the chapter's largest extent, against band 1's 69 and 48. The owner is
describing that gradient as a player.

"Things pop up on the map and tell you to go do them" is a **new mechanic** the owner
is asking for, not a tuning change — a surfaced, discoverable task feed. It needs a
design contract before implementation.

## OP-0904-5 — Bonding does not mean enough, and fights are too easy

> Bonding needs to mean more. I need more of a reason to fight everyone.
> Beating creatures and other trainers is way too easy.

Difficulty is now owner-reproduced, which changes the standing of the G-2 work: the
per-encounter `combat` profiles landed this session give named opponents real
behaviour for the first time, and this says the *baseline* is also too soft. Both
levers now have evidence behind them.

Bonding is `bond_milestones.json` and the bond system; "a reason to fight everyone" is
reward economy and trainer-journey design.

## OP-0904-6 — Camping is not necessary and must be

> Camping isn't necessary. It needs to be necessary.

The rest rhythm exists mechanically and costs the player nothing to skip. This is
prompt 61's own subject and the closure plan already carries it; the owner has now
made it a requirement rather than a quality goal. **Careful:** `CLAUDE.md` forbids
harsher hunger/thirst and starvation death. Necessity has to come from attrition,
distance and recovery scarcity, not from a survival meter.

## OP-0904-7 — The Burrow Warrens looks terrible

Blunt and unqualified. The Warrens has had four rounds of blind lighting judgement on
the guardian alone; this says the room around it still does not read. Treat prior
"verified" verdicts on the Warrens interior as superseded.

`data/config/burrow_warrens.json`, `scripts/world/burrow_warrens.gd`.

## OP-0904-8 — The legendary should be inside the machine

> The legendary should be in the machine not in a ring outside the machine.

A staging change to the chapter's climax, and it strengthens the reveal prompt 69 asks
for: the creature *is* the power source, so it should be inside the thing that is
draining it, not beside it.

`scripts/world/stronghold_climax.gd`, `data/config/stronghold_climax.json`.

## OP-0904-9 — The rideable roster, and two new traversal abilities

> Burrowback and the grownup mudsnout should be rideable. Terrapup too. That means
> the other starters have to get special abilities. One should get fly and one
> teleport. But you can't use them till you learn them in the game.

The largest design item here. Three creatures become rideable — Burrowback, Tuskroot
(the grown Mudsnout) and Terrapup — and to keep the starters balanced against that,
**the remaining starters get fly and teleport**, each gated behind an in-game unlock.

This is a real expansion of the traversal philosophy and it needs a design contract
before code: which starter gets which, what teaches it, what it costs, and how fly and
teleport interact with a corridor world whose gates are deliberately physical
(`severed_spokes.gd`, the Sigil gate, the South Bridge). A creature that flies over a
locked gate breaks the chapter's own structure, so the unlock and its limits are the
design, not the ability.

---

## Routing

| Item | Kind | Owner |
|---|---|---|
| OP-0904-0 kickoff parse | defect | **fixed 2026-09-04**, guarded by a test |
| OP-0904-1 village plan and population | world rebuild | needs a design pass first |
| OP-0904-2 no night time | defect | reproduce on the shipped build, not the harness |
| OP-0904-3 riding: rider invisible, no sprint/jump, saddle worn before built | defect ×2 + rule | riding lane |
| OP-0904-4 content density and a task feed | content + **new mechanic** | design contract, then band lanes |
| OP-0904-5 bonding and difficulty | tuning + design | economy/encounter |
| OP-0904-6 camping must be necessary | design | rest rhythm, within CLAUDE.md's satiety limits |
| OP-0904-7 Warrens looks terrible | visual | supersedes prior Warrens verdicts |
| OP-0904-8 legendary inside the machine | staging | finale |
| OP-0904-9 rideable roster, fly, teleport | **major design decision** | contract before code |

Nothing in this file is implemented by recording it. OP-0904-0 is the only item closed.
