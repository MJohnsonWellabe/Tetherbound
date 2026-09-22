# Owner directives — 2026-09-04 (B): what there is to do

Recorded verbatim. Under `CLAUDE.md`'s precedence this outranks every other
document for what it covers, and it reverses at least one settled spec statement
(§B below). Follows `OWNER_PLAYTEST_2026-09-04.md`, and answers its own
OP-0904-4 ("there isn't enough to do... nothing to take you off the path").

## Verbatim

> For all alphas they should pop up on your map once you're within 300 meters of
> them and then it shouldn't disappear from the map until you catch it. This gives
> you more to keep doing.
>
> You should have to beat tether grunts along the way at the relay stations and
> they each then allow you to turn off that relay and we should build that into the
> story so you have that to do as you keep going as well. Then a quest to beat all
> trainers in the meadows and that's tracked too for another thing to do. Add more
> like that so we can keep it entertaining rather than being a running simulator.
>
> the other two starters should not be able to fly or teleport until well after the
> meadows. but they will eventually have that ability to make it a fair choice
> between the three. take terrapup now and you can ride him midway through the
> meadows. take the others and get the better ability but you can't do it until the
> different biomes where we learn those things.
>
> we can also gate certain things by level. like you can't cross the bridge til
> you're level whatever plus you get the key. then it would prompt you to go back
> and fight more to get a level up.
>
> you shouldn't be able to fight anyone more than once. and you shouldn't be able to
> leave a fight once it started.
>
> once we make bonding and leveling animals more of an important and visual thing in
> the game it will feel better to grind it. that's what we need

## The thesis, in the owner's own last line

Every item here serves one goal: **make the grind worth doing rather than
removing it.** "Running simulator" is the failure state. More tracked things to
do, and a bond/level system visible enough that advancing it feels like progress
rather than bookkeeping. Read the individual items as instruments of that, and
if an implementation satisfies the letter while leaving the route feeling empty,
it has failed.

---

## D-0904B-1 — Alphas pin to the map at 300 m and stay pinned

Within 300 m an alpha appears on the map, and **does not disappear until caught**.
15 alpha/elder entries exist across the band spawn files today, so the content is
there and unadvertised.

**One thing needing a decision before implementation.** The player may hold only
five creatures. A player with a full roster cannot catch the alpha, so a pin that
clears only on catch will sit there permanently, and a permanent pin the player
cannot action is nagging rather than motivating — the opposite of the intent.
Recommended: clear the pin on **caught, or deliberately dismissed**, and keep a
dismissed alpha discoverable in the world. Flagged, not decided.

## D-0904B-2 — Relay stations as a running, story-carried objective

Beat the Team Tether grunts at each relay station; each defeat lets you **turn
that relay off**; the sequence is built into the story so it is something to keep
doing as you travel. Plus **a tracked quest to beat every trainer in the Meadows**.
And explicitly: *"add more like that."*

This is the concrete form of OP-0904-4's "things pop up on the map and tell you to
go do them" — the task feed now has two authored instances to be built around
rather than an abstract mechanic. `tether_relay.gd`, `relay_site.json`, the quest
log, the map.

## D-0904B-3 — Fly and teleport come well after the Meadows, and that is the trade

Terrapup pays off **inside** the Meadows: rideable from midway. The other two
starters get the better abilities — one fly, one teleport — **learned in later
biomes**, not here.

Compatible with `CLAUDE.md`'s "no Biome 2 implementation until the Meadows passes
its exit gate": nothing of Biome 2 gets built. The abilities simply are not
granted, and the Meadows never teaches them.

**The consequence the owner is knowingly accepting**, stated so it is designed for
rather than discovered: two of three starter choices have **no traversal payoff
inside this chapter**. That is the point — deferred gratification versus immediate
— but it means the Meadows must remain fully completable and satisfying with any
of the three, and the choice must be legible at the moment it is made. A player
who picks fly and spends the whole chapter wondering what they gave up has been
punished, not rewarded.

## D-0904B-4 — Level gating, used to generate an objective

> you can't cross the bridge til you're level whatever plus you get the key. then
> it would prompt you to go back and fight more to get a level up.

Key **and** level. The important half is the second sentence: the gate exists to
**hand the player a next thing to do**, not to stop them. A gate that refuses
without saying what would change is a wall; this one names the remedy.

**⚠ This reverses a settled spec statement.** `docs/specs/MEADOWS_PROGRESSION_SPEC.md`
§ the South Bridge currently reads: *"It has a physical key/mechanism, **not a UI
level lock**"* and *"roughly 5–8 (tunable, **not a hard level requirement**)"*.
Gate 2's own 2.8 evidence run then praised the build for exactly that — *"the
player is never told a level requirement, which is what `GAME_VISION.md` §Lower
Meadows asks for."*

Under precedence the owner wins and the spec must be **edited, not left
contradicting** — that is how this repo accumulated stale prose before. The
spirit of the old rule is worth keeping inside the new one: let the refusal be
**diegetic** (the guard sizes up your team and turns you away, naming what would
change) rather than a menu error. That satisfies "the world itself creates the
gate" and the owner's prompt-to-go-level in the same beat.

## D-0904B-5 — One fight per opponent, and no leaving a fight

**Already shipped, half of it.** All **31** authored trainers across the five band
files carry `"rechallenge": false`, so "cannot fight anyone more than once" is
current behaviour, not new work. Verify it holds for the wild/guardian path and
for the tournament's own retry loop (the tournament is explicitly re-enterable
after a loss, which is a deliberate exception and should stay one).

**No leaving a fight** is new. `combat_manager.gd` has `_flee_pressed()` and a
documented disengage button on both devices; removing it needs the total-party-
faint path defined as the only exit, since the death-satchel system already exists
for that outcome. A player locked in a fight they cannot win and cannot leave, with
no faint resolution, is a softlock — this must be specified before it is coded.

**And a dependency worth stating plainly:** no-refight plus a level gate means
**wild encounters carry the entire regrind**. The owner has separately reported
wilds are sparse outside the village (OP-0904-4). Ship the density first, or the
bridge gate becomes the wall it is explicitly not meant to be.

## D-0904B-6 — Bonding and levelling must be important and visible

The load-bearing item. `bond_milestones.json` and the level system exist and are
close to invisible in play. Until advancing them is legible and feels like
something, every other item here is asking the player to grind toward a number
they cannot see.

---

## Routing

Nothing here is implemented by recording it, and **no lane is being started for
any of it** — the owner's standing instruction is that in-flight work finishes
first. These are scoped, unstarted rows for `docs/GATE2_GATE3_CLOSURE_PLAN.md`.

| # | Item | Kind | Needs deciding first |
|---|---|---|---|
| D-0904B-1 | alpha map pins, 300 m, persistent | feature | what clears a pin for a full roster |
| D-0904B-2 | relay shutdown chain + all-trainers quest + more | feature, story-carried | the task-feed contract |
| D-0904B-3 | fly/teleport post-Meadows; Terrapup rides mid-chapter | progression design | what the other two starters give *inside* the Meadows |
| D-0904B-4 | level+key gating that prompts | design, **reverses spec** | edit `MEADOWS_PROGRESSION_SPEC.md`; keep the refusal diegetic |
| D-0904B-5 | one fight per opponent; no fleeing | half shipped; half new | the total-party-faint exit |
| D-0904B-6 | bonding and levelling visible | design + UI | — |


---

# Amendment — same day, owner clarifications

These correct and narrow the items above. Where they disagree with §D-0904B-1,
-4 or -5, **the amendment wins**.

## Verbatim

> you shouldn't be able to leave a fight with another character once it's started.
> still should be able to with a wild creature. also you can still hit challenge
> someone else after you beat them. maybe it doesn't let you fight again but you
> should t even see the challenge button anymore. just talk to or whatever. alpha
> pin clears when you catch it or beat it. gate just make the fight not start
> unless you're a certain level. the guy can just say "you're too low level I'll
> crush you and send you crying to Grandpa"
>
> the dialogue at the end needs to be cut way down. it was paragraphs with the
> warden. then paragraphs on the legendary thing.

## A-1 — No fleeing applies to TRAINERS only; wild fights keep the exit

This resolves the softlock concern raised against D-0904B-5. A wild fight stays
leavable, so the player is never locked in an unwinnable encounter with no exit;
only a trainer fight is a commitment once accepted. `combat_manager.gd`'s
`_flee_pressed()` stays, gated on the opponent being wild.

## A-2 — The Challenge button must disappear once a trainer is beaten

**Confirmed in the code, and it is a real defect.** `trainer_npc.gd::_prompt_for()`
is unconditional:

```gdscript
return prompts().get("challenge", "Challenge %s") % str(spec.get("name", "Trainer"))
```

The *conversation* already switches after a win — `can_challenge()` is false and
the defeated line plays — but the **prompt label never does**, so every beaten
trainer still advertises "Challenge". That is the repo's own stated rule being
broken: `interactable.gd` says *"off means no offer at all... a visible prompt
the button refuses is worse than no prompt."*

**A trap for whoever implements this.** `_prompt_for()`'s own comment records that
the prompt must never contain **"talk"** or **"choose"**, because
`tests/smoke_opening.gd` locates Grandpa and the three starters by exactly those
substrings. So the obvious fix — "Talk to %s" — will break the opening smoke.
Pick different wording, or change how that smoke finds its targets; do not
discover this in CI.

## A-3 — The alpha pin clears on caught **or beaten**

Answers the open question in D-0904B-1. No dismissal mechanic needed: a full
roster can still clear the pin by winning the fight.

## A-4 — The level gate is the trainer refusing, not a lock

> gate just make the fight not start unless you're a certain level. the guy can
> just say "you're too low level I'll crush you and send you crying to Grandpa"

This settles the tension flagged in D-0904B-4 in the best available way. There is
no UI level lock: the **fight does not start**, and the trainer says why, in
character. `MEADOWS_PROGRESSION_SPEC`'s "a physical key/mechanism, not a UI level
lock" survives intact — a trainer who sizes you up and refuses *is* the world
creating the gate. The spec still needs a line added for the level condition, but
it is no longer a reversal.

Mechanically this is a **fifth reason `can_challenge()` can be false**, and the
dark-features T1 note in `trainer_npc.gd` already warns what happens when those
reasons get collapsed: a too-low player must hear the taunt, not the
already-defeated line.

## A-5 — Cut the endgame dialogue down, hard

Measured on the current build, `data/dialogue/stronghold.json`:

| Conversation | Lines | Characters |
|---|---|---|
| `stronghold_warden_challenge` | 8 | **1,547** |
| `stronghold_free_legendary` | 4 | 784 |
| `stronghold_warden_defeated` | 5 | 741 |
| `stronghold_reveal` | 5 | 637 |
| `stronghold_machinery_fails` | 4 | 636 |
| `stronghold_chamber` | 4 | 424 |
| **whole file** | | **5,343** |

The Warden's pre-fight speech averages 193 characters a line and peaks at 379 —
paragraphs, exactly as reported, at the moment the player most wants to fight.

**What must survive the cut.** Spec §33 gives the Warden a worldview rather than a
motive: he believes separation prevents chaos, he confirms the readout rather than
denying it, and he does not recant when he loses. That characterisation is canon
and is the reason the fight lands. Cutting to length is not licence to flatten him
into a generic boss — the job is to say the same thing in a fraction of the words,
and the freeing sequence should carry its weight visually rather than in text,
which is what prompt 69 asks for anyway ("physically and emotionally legible").
