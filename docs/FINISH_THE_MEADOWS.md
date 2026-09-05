# Finish the Meadows — the whole remaining plan

**Written 2026-09-04, after seventeen Gate 3 lanes landed and the owner answered six open
decisions.** `main` verified healthy at `2b5a2a55`.

This is the direction document. It says what is left to finish the game's first chapter,
in what order, and what "done" means for each piece. It is written to be picked up cold.

**Precedence:** `CLAUDE.md` first, then the newest owner directive, then this. Where this
document and an older one disagree, this one is newer — but say so in the edit rather than
leaving both standing. That habit is why several things below were found at all.

---

## The shape of what is left

The chapter is **built**. Almost none of it is **proven**, and the owner's verdict on what
is built is *"the game plays great — visuals and content are the big issues, and it's
really content after leaving the village."*

So the work divides three ways, and they are not equally blocked:

| Track | State | Blocked by |
|---|---|---|
| **Visuals** | the owner's top priority; several fixes are cheap and one is nearly free | one instrument (below) |
| **Content after the village** | the largest body of work; its four design contracts are written (2a, `docs/specs/C*.md`) | density first, then the contracts' slices |
| **Evidence** | one band of five has real played evidence | two harness defects |

**One thing blocks two of the three tracks**, and it is first for that reason.

---

# Phase 0 — Unblock the instruments

Nothing here is glamorous and all of it is load-bearing. Until these land, visual work
cannot be judged and three of five bands cannot be evidenced.

### 0.1 — The route strip photographs the world with nobody in it (CL-H9 / task 2.15) — **S–M**

**The most blocking item in the project, it has no owner, and the repair is much smaller
than it has been described.**

**First, what is not wrong.** The capture-and-judge loop exists, it is extensive, and it
works: **64 capture scripts, 18 survey scripts, a route-strip tool and a code-blind judge
skill.** It produced Bramblebun's day and night colour, the night lighting floor, creature
contact shadows, the mid-layer between grass and canopy, and tree silhouettes at seven
copses. **And 17 of those scripts do put creatures on screen** —
`_capture_creature_roster`, `_capture_life`, `_capture_locations`,
`_capture_night_legibility`, `_capture_combat_moments`, the T1 variant lineups. Creature
capture is not missing. Do not rebuild any of this.

**The actual gap is narrower.** The scripts that stage a creature are *creature-subject*
captures — a roster lineup, a bed rest, an animation sheet. The scripts that judge *the
world* — the survey stands, the location set, and critically `tools/_capture_route_strip.gd`,
which D73 §2 made the basis for **both bars** — photograph the world with nobody in it.
Grepped for `creature`, `companion`, `deploy`, `party`: **zero hits.** It walks the spine
and shoots empty landscape.

So the loop is not broken. **It is pointed at two subjects that never appear in the same
frame** — and Bar B asks a question only a combined frame can answer: *does this look like
the same kind of game?* That cannot be answered from a creature lineup on a neutral
background, and it cannot be answered from a beautiful empty meadow. Four passes returned
no / no while individual defects genuinely got fixed, because the frames showed the
scenery and the cast separately and never the game.

**Two things compound it, both already decided and neither needing new work:**

- **The judging has been on posed stands.** D73 §2 already moved it to the route strip,
  for the obvious reason — a camera parked at a nice spot flatters a build.
- **Container frames are software-rendered.** `VISUAL_BIBLE.md` says outright: trust
  composition, silhouette, colour relationships, scale and geometry; **do not trust fine
  lighting.** So every lighting iteration run in-container has been half-blind, which is
  exactly why D73 moved the bars onto GPU frames from the kickoff run.

**Done when** `_capture_route_strip.gd` deploys the companion before it walks and takes at
least one frame inside a real fight — borrowing from `_capture_life.gd` and
`_capture_combat_moments.gd`, which already know how — and rejects a frame that fails a
"creature present and readable" check rather than saving it.

**Fails if** anyone treats this as a reason to rebuild the capture system. The system is
fine. Two scripts need to learn what a third already does.

### 0.2 — The harness's `input_context` misresolves (CL-H13) — **M**

Flips to `build_catalogue` and never returns; every step after it in that run executes
behind a menu nothing closes. Confirmed at **three independent sites** — Oreth, Captain
Vance, and S08 after Captain Riverwatch.

**Do not fix this by rebinding a key.** One lane attributed it to `combat_charged` and
`build_shortcut` sharing `JoyAxis:4` and reported it as a player-facing controller bug. It
is not: two of the three sites involve no charged attack at all, and two shipped guards
(`input_contexts.json` makes `world` and `combat` mutually exclusive; `_world_input_allowed()`
refuses during combat) mean a real player cannot reach it. It is the harness's own input
path resolving against a context the action does not belong to.

**Fails if** it is closed by rebinding, or by routing one more step through the mouse
device. Those are per-site workarounds — correct as such, and the existing one is kept —
and the next segment finds the next site.

### 0.3 — S08 freezes solid (CL-H14) — **M–L**

`S08-22` pins at `(-164.12, -9.13, 4334.56)` for its entire 45,000-frame budget,
reproduced twice from the identical seed to the centimetre. **This is why Band 4 has no
evidence.**

Two causes already ruled out, with probes committed so nobody redoes the work: not the
walker (the same navigator call in isolation arrives cleanly in 10,792 of 12,000 frames),
and not a CarveFailsafe volume (none within 60 m).

**Fails if** it is closed by moving the waypoint. The leg is walkable in isolation, so a
re-site hides the defect instead of finding it.

---

# Phase 1 — Visuals

The owner's priority. Ordered by impact per unit of effort. **1.1, 1.2 and 1.3 need
nothing from Phase 0** — start them immediately, in parallel. Everything from 1.4 down
wants 0.1 first, not because the judge is broken but because until the route strip carries
a creature and a fight, the judge keeps answering the same two bars on frames that cannot
address them.

### 1.1 — Every NPC speaks with the player's face — **S. The cheapest large win available.**

`assets/ui/portraits/` contains exactly two images, `trainer.png` and `grandpa.png`.
Counted across `data/dialogue/`: **127 of 140 portrait references point at `trainer.png`.**

Mira, Oskar, Tam, Bram, Halda, Captain Vance, every Team Tether rank, the Warden — every
character in the game except Grandpa — is drawn with the player's portrait.
`dialogue_panel.gd` draws exactly what the line names, so it is behaving correctly.

**No new meshes needed.** Render one portrait per installed humanoid rig from the meshes
already in the project, re-point each conversation's `portrait` field at its real speaker.

**Done when:** a test asserts no non-player speaker resolves to `trainer.png`, and it has
been seen to fail for the right reason.

### 1.2 — The tree-lines that read as "one lollipop, repeated" — **S–M**

Two blind judges independently ranked this the top residual visual gap. The lane that
could have fixed it declined, because three documents claimed widening the tree layer's
`scale_min`/`scale_max` would re-roll the whole 12 km corridor's RNG stream.

**That was checked against the code on 2026-09-04 and it is false.**
`scatter_rules.gd::_place_one()` draws scale, model and yaw unconditionally in a fixed
order, with every rejection test resolved before them. A wider range consumes the same
draws in the same order: identical placements, identical models, identical yaws — only the
sizes change. `vegetation.json`'s own note said exactly this and was overruled by prose.

So it is ordinary tuning, landable in any bake window, and it affects most of what the
player looks at while walking.

**What genuinely does re-roll the corridor**, and so does need sequencing: raising an
anchor's `count`, and adding a per-layer `band_scale`.

### 1.3 — The endgame dialogue is paragraphs — **S–M**

Measured on `data/dialogue/stronghold.json`: the file is **5,343 characters**;
`stronghold_warden_challenge` alone is 8 lines / **1,547 characters**, averaging 193 a line
and peaking at 379 — at the moment the player most wants to fight.

**What must survive the cut:** the Warden believes separation prevents chaos, he confirms
the readout rather than denying it, and he does not recant when he loses. That is canon and
it is why the fight lands. Say the same thing in a fraction of the words; let the freeing
sequence carry its weight visually, which is what the design asks for anyway.

### 1.4 — The Burrow Warrens — **M**

Owner: *"Burrow warrens looks terrible."* The Warrens has had four rounds of blind lighting
judgement and **all four judged the guardian, not the room.** Those "verified" verdicts on
the interior are superseded.

### 1.5 — The dialogue camera — **M, already decided**

Villagers read too small in conversation. The approach is settled: a conversation push-in to
a two-shot at ~3.5 m over the fade — **not** a change to villager scale, which the owner has
already had cut and re-cut. This is a scoped task, not an open question.

### 1.6 — Combat and reward VFX (CL-A2) — **M, newly funded**

A level-up flourish and a hit spark. Shader and particle work inside the installed kit —
no new meshes, no Meshy, no hard-rule conflict.

Two reasons it earns its place: **Bar B cannot reach yes without it** (a fight that looks
like two models standing near each other correctly reads as not-a-creature-game), and it
answers the softer half of *"beating creatures is way too easy"* — part of why a win reads
as trivial is that winning produces no picture.

### 1.7 — The judge's standing art list (CL-A1) — **L**

Every blind pass ends with the same six asks. The route for each is now fixed: find up to
three free-pack candidates matching the installed families' style and scale, install each
in place, render it on the stand where the judge named the gap, and put the three to a
blind judge.

**A pass ships. Three fails produce a brief — not a generation.** Per the owner,
2026-09-04: *"you shouldn't use Meshy keys without art first."* The owner supplies
reference art, and only then is a generation spent.

The six: a built South Bridge with Team Tether presence · one Meadows landmark to navigate
by · trees with branch structure below the canopy · creature silhouettes readable at 16 px
(this is 0.1) · combat and reward VFX (this is 1.6) · distinct NPC bodies (1.1 covers the
portrait half).

### 1.8 — Creature palette: the one open question — **S, needs a call**

Bramblebun's day and night colour is fixed and measured. Mudsnout was failing and was
raised. Terrapup already cleared. **Burrowback is a design question, not a bug:** it is
darker than the field *by design* (grey-olive rock-nodule armour), reaches only 1.18:1
against the 1.5:1 bar across a full sweep, and pushing it brighter trades away the
identity. Someone has to decide whether the bar or the identity gives.
**Decided 2026-09-04: `docs/decisions/D74-burrowback-keeps-its-rock-armour.md`** — the
identity stays; legibility is met in the dark direction (field over creature ≥ 1.30:1) by
value, rim and contact shadow, never hue.

---

# Phase 2 — Content after the village

The owner's largest complaint, and it agrees with what the instruments measured
independently: **band 5 ships 23 spawns and 8 harvest nodes over the chapter's largest
extent, against band 1's 69 and 48.** The owner is describing that gradient as a player.

## 2a. Write these three contracts first — **XL each, and they are the long pole**

> **Written 2026-09-04 (W19-CONTRACTS).** The contracts exist and are the implementation
> briefs; the paragraphs below are the summary that commissioned them. Hand a lane the
> contract, not this section:
>
> | Contract | File | What it settles |
> |---|---|---|
> | **C1** | [`docs/specs/C1_RIDEABLE_ROSTER_FLY_TELEPORT.md`](specs/C1_RIDEABLE_ROSTER_FLY_TELEPORT.md) | Terrapup, Burrowback and Tuskroot rideable behind the one saddle; Galewisp flies and Ripplet teleports only beyond the Meadows, as a presentation-only promise; the pick made legible on three surfaces; each starter's in-chapter payoff; the nine-site gate sweep that proves nothing rides over a locked gate |
> | **C2** | [`docs/specs/C2_TASK_FEED.md`](specs/C2_TASK_FEED.md) | a task is an objective plus a pin, a counter and a reward, still a pure function of the flag store; the four-station relay shutdown chain and the generated every-trainer tally, plus alphas, Sigil pins, the Rootstone/Ironwood surveys and the camping chain; no save-format change, the MAIN STORY card untouched |
> | **C3** | [`docs/specs/C3_VILLAGE_REPLAN.md`](specs/C3_VILLAGE_REPLAN.md) | houses along the chapter's own road, a berry field, a grove and a stone yard as named places; five villagers stay by function and fourteen are resited with a role each; the opening's smoke constraints, the one terrain bake, and a four-stage plan |
> | **C4** | [`docs/specs/C4_CAMPING_NECESSARY.md`](specs/C4_CAMPING_NECESSARY.md) | the 2b row "Camping made necessary", promoted to a contract: strain (damage only rest clears), recovery scarcity, a per-leg strain floor for the density pass, and night rules — with every satiety number frozen by test |
>
> Two decisions this section was waiting on are recorded: **D74** (Burrowback keeps its
> rock-armour; item 1.8 below is closed) and **D75** (where a level gate sits and at what
> number; the 2b row "The level gate that prompts" now has its placement rule).

Do not hand any of these to an implementation lane as a paragraph of owner quote. Each
changes what the game is, and each has a trap that a contract exists to catch.

### C1 — The rideable roster, fly and teleport

Burrowback, Tuskroot and Terrapup become rideable. The other two starters get fly and
teleport, **learned well after the Meadows** — nothing of Biome 2 gets built; the abilities
simply are not granted and this chapter never teaches them.

**The trap:** the Meadows' gates are deliberately physical — the severed spokes, the Sigil
gate, the South Bridge. **A creature that flies over a locked gate breaks the chapter's own
structure**, so the unlock and its limits *are* the design, not the ability.

**The consequence to design for rather than discover:** two of three starter choices have
no traversal payoff inside this chapter. That is the trade — deferred versus immediate —
but the Meadows must stay fully completable and satisfying with any of the three, and
**the choice must be legible at the moment it is made.** A player who picks fly and spends
the chapter wondering what they gave up has been punished, not rewarded.

### C2 — The task feed

*"Things pop up on the map and tell you to go do them."* A new mechanic, not tuning. The
owner's directives gave it two authored instances to design around rather than an abstract
feed: **the relay shutdown chain** (beat the grunts at each relay, each win lets you turn
that relay off, built into the story) and **a tracked quest to beat every trainer in the
Meadows.** And explicitly: *"add more like that."*

### C3 — The village replan

Houses along a road, not a circle. A berry field, a tree grove, a stone area as named
places. **Five villagers maximum** — and the second half is placement, not deletion: the
rest move out into the chapter, which is also part of the answer to "there isn't enough to
do."

## 2b. Build these — no contract needed

| Item | Notes | Size |
|---|---|---|
| **Density across bands 2–5** | The half of "not enough to do" that needs no design work. **Do this before the level gate and the no-refight rule** — see the dependency below. | L |
| **There is no night time** | Flat, on the owner's build. The probes pass and the night-lighting work was tuned against rendered night frames — those frames are real, which means **the shipped build reaches the clock by a different path than the harness does, and that gap is the defect.** Root-cause it there. | M |
| **Riding is unfinished three ways** | Rider invisible on the mount; sprint and jump lost while mounted; and the saddle is on the model before it is built. The third is a rule: **a rideable creature ships with no saddle, and it appears only once built and fitted.** It is the visible proof of the craft the riding unlock is built around. **Fails if** any rideable species carries a saddle at spawn. | M |
| **Alpha map pins at 300 m** | Clears when caught **or beaten**. 16 alpha/elder entries already exist, unadvertised. **Cheaper than it looks:** `map_state.gd` already has `add_dynamic_marker`/`remove_dynamic_marker` and the minimap already draws dynamic markers with collision handling. **Fails if** the pinned set is not persisted. | M |
| **The Challenge button never disappears** | Confirmed defect: `trainer_npc.gd::_prompt_for()` is unconditional, so a beaten trainer still advertises "Challenge" though the conversation has correctly switched. **The trap:** that function's comment records the prompt must never contain "talk" or "choose", because `smoke_opening.gd` finds Grandpa and the three starters by those exact substrings. "Talk to %s" breaks the opening smoke. | S |
| **No leaving a trainer fight** | Trainers only. Wild fights keep their exit, which removes the softlock risk. The tournament's post-loss retry stays a deliberate exception. | M |
| **The level gate that prompts** | No UI lock: **the fight does not start and the trainer says why, in character.** A fifth reason `can_challenge()` can be false. **A too-low player must hear the taunt, not the already-defeated line.** Placement and number: `docs/decisions/D75-the-level-gate-placement-rule.md`. | M |
| **Bonding and levelling made visible** | *"Once we make bonding and levelling more important and visual it will feel better to grind it. That's what we need."* **Load-bearing** — until advancing a bond or a level is legible, every other tracked objective asks the player to grind toward a number they cannot see. | L |
| **The legendary inside the machine** | The creature *is* the power source, so it belongs inside the thing draining it. | S–M |
| **Fights are too easy** | Now owner-reproduced, which changes the standing of the per-encounter combat work that landed: named opponents have real behaviour for the first time, and this says the **baseline** is soft too. | M |
| **Camping made necessary** | `CLAUDE.md` forbids harsher hunger and starvation death. Necessity comes from attrition, distance and recovery scarcity. **Fails if** the fix is a faster satiety drain. Contract: `docs/specs/C4_CAMPING_NECESSARY.md`. | M |

## The dependency to state plainly

**Density ships before the level gate and the no-refight rule.** No-refight plus a level
gate means wild encounters carry the entire regrind — and wilds are already sparse outside
the village. Ship density first, or the bridge gate becomes exactly the wall the owner's
own amendment says it must not be.

---

# Phase 3 — Close Gate 2

Three of four clauses are met or measurable. The bar was rewritten on 2026-09-04 so that
the gate's own tasks can actually move it.

| Clause | State |
|---|---|
| Blind judge, three parts (a)/(b)/(c) | **not met** — and (c) cannot even be asked until 0.1 lands |
| Evidence template; dead travel under ~60 s unless intentional | dead travel **met** (63 s and 71 s, both intentional); template fails on presentation and the roster clause |
| Perf proxy; the Ally frame rate | proxy **met** (6,891 draws / 10.79 M primitives vs 7,500 / 12.0 M); the Ally half now comes from the kickoff run |
| Tags: `gate2-candidate`, then `gate2-done` | not placed |

**Landed but unproven** — code shipped, no played path has scored it: the post-tournament
recovery beat, the revived-creature redeploy, the roster decision on the Band 1 route, and
most of the props/bridge/signpost work.

---

# Phase 4 — Close Gate 3

**One band of five has real evidence.**

| Segment | State |
|---|---|
| S07 The River Lock | **104 / 119**, inventory complete, five relay fights resolving, party alive |
| S06 Stone & Root | no chain evidence |
| S08 Upper Meadows | **blocked by 0.3** |
| S09 Stronghold Approach | no chain evidence |
| S10a–e the finale | no chain evidence; the smokes cover the mechanism, not the walk |

Everything else in Gate 3 is authored and unproven: the per-encounter combat profiles, the
relay ladder, the captains, the Warden's rebalance. They pass their own tests. **No played
path has scored them.**

Plus a blind judge per band, gated on 0.1.

---

# Phase 5 — Gate 4 is smaller than it looks

Gate 4's evidence is the **kickoff run**, not a human playthrough.

`tools/owner/KICKOFF.cmd` is the whole human contribution: the owner double-clicks it on a
Windows machine with a GPU, it runs the acceptance script end to end and pushes what it
produced to `owner-run/<stamp>`. **No owner playtest, confirmation or screenshot is a
precondition for closing anything any more.** Every ledger row reading "needs owner
confirmation on hardware" waits on that run, not on a person.

The ROG Ally is the reference box, so its frame-rate numbers are the real ones, and four
hardware-only items close from the run's own evidence: interact reliability, frame rate
with grass on, player sleep, and day/night advancing.

**Concretely:** run `KICKOFF.cmd` on the Ally — the parse bug that killed the last attempt
is fixed and guarded by a test, since CI has no Windows runner and the first parse was on
the owner's machine. It produces telemetry, video sheets, `fps.json` and the GPU route
strip, and the route strip is what the blind judge uses.

**Caveat: run it after 0.1.** Before that the route strip shows frames with no creature in
them, and the visual half of Gate 4 measures the camera rig again. Running it earlier still
gets frame rate, the export check and the four hardware items, which is most of Gate 4.

---

# The order

| When | What | Why |
|---|---|---|
| **Now, in parallel** | 0.1, 0.2, 0.3 · 1.1, 1.2, 1.3 · start writing C1, C2, C3 | 0.1 is now a two-script change, so it is cheap and first. 0.2 and 0.3 block three bands of evidence. 1.1–1.3 need none of them. The contracts are the long pole and only need a writer. |
| **Once 0.1 lands** | 1.4–1.8 · the first GPU route strip · Gate 4's kickoff run | Visual work becomes judgeable; Gate 4 becomes collectable. |
| **Once 0.2 and 0.3 land** | S06, S08, S09, S10 evidence · per-band judges | Gate 3's remaining four bands. |
| **Once the contracts are written** | 2a implementation · then 2b's gated items | Density first, then the gates that depend on it. |
| **Last** | Gate 2's tags · Gate 3's verdict · Gate 4's close | Each needs everything above it. |

---

# How to trust this document

Seven claims were checked against the code on 2026-09-04 and found wrong. All had been
written down confidently; two had already propagated into other documents; one was
blocking a top-ranked visual fix. **The seventh is this document's own first draft** — the
owner read it and asked why the existing capture-and-judge loop was not simply being run
again, which was the right question and exposed an overstatement.

| Claim as written | What was true |
|---|---|
| A crash was "a Godot 4.7 GDScript-VM edge case" | An ordinary bug: `get("k", {}) is Dictionary` tests the **default**, then the next line indexes a missing key |
| `verify-gate-b-core` is the "Quarry Foreman / Prompt under Door" defect | A nondeterministic leg with four outcomes on one commit — and two concurrent CI runs of the **same commit** disagreed with each other. **The check carries no information about the branch under test.** |
| Widening a scatter scale range re-rolls the corridor's RNG stream | It does not. This wrongly blocked item 1.2 for weeks |
| A shared trigger binding lets a charged attack open Build mid-fight | Two shipped guards make it unreachable; the real defect is in the harness, at three sites |
| The fence-corner walker fix "does not exist on `origin`" | It sat in an open pull request the whole time |
| Grandpa's loft bed is closed by harness evidence | The owner has never been able to sleep in it. The smoke passes because the harness reaches the bed by a path the player cannot |
| *(this document, first draft)* “the capture pipeline cannot put a creature in frame” | Overstated, and the owner caught it. 17 capture scripts stage creatures; the loop works and has shipped real fixes. Only the **route strip** walks empty — two scripts need to learn what a third already does. A plan that describes a small gap as a broken system gets a rebuild it does not need |

**The habit that caught all six: verifying a comment against another comment is not
verification.** A lane had certified an encounter as meeting its contract by reading the
config's own prose about it.

Two corollaries worth keeping:

- **A green check is not evidence until something has seen it go red for the right reason.**
- **Check open pull requests, not just `main`.** One of the six above cost a verified fix
  sitting unmerged through four landings while a plan told readers it did not exist.

---

Detail, with a *fails if* on every open item, is in **`docs/GATE2_GATE3_CLOSURE_PLAN.md`**.
The owner's own words are in **`docs/owner/OWNER_PLAYTEST_2026-09-04.md`** and
**`docs/owner/OWNER_DIRECTIVES_2026-09-04-B.md`** — those are the record; this is the plan.
