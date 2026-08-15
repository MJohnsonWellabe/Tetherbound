# TETHERBOUND — MEADOWS QUALITY REBUILD PLAN

> **Status:** Owner-directed additive plan for the existing Ralph backlog.
>
> This document does **not** replace `ralph/BACKLOG.md`, `CLAUDE.md`, or settled decisions.
> It strengthens and supersedes the quality bar for the overlapping work named below.
>
> Where this document overlaps an existing backlog item, **do not create a parallel duplicate task**.
> Instead, treat this document as the owner-authored execution brief for that existing item and split the work into Ralph-sized subitems as needed.

---

# 0. EXECUTION RULES

## 0.1 This is a quality rebuild, not another tuning pass

Several Meadows systems have already received multiple rounds of patching, tuning, and blind critique.

Where the current implementation has repeatedly failed to reach the intended quality bar, **do not continue incremental tuning indefinitely**.

If the current approach has clearly hit a ceiling:

1. stop preserving the implementation merely because it already exists;
2. preserve only the settled player-facing requirements, reusable assets, data, and proven infrastructure;
3. restart the creative/structural solution from a clean design pass;
4. use the strongest available model for that first pass;
5. rebuild toward the target experience;
6. only then hand implementation details, wiring, tests, and bookkeeping to cheaper subagents where appropriate.

A previous investment of time is not a reason to preserve an approach that is visibly below the quality target.

## 0.2 Fable must start all ceiling-setting rebuilds

Any item in this document marked:

`START WITH FABLE`

must begin with a fresh Fable-authored pass.

A Sonnet/Opus/Haiku agent must **not** inherit the old implementation and decide how to improve it before Fable has reset the direction.

Fable owns:

- aesthetic target
- player-feel target
- composition
- motion quality
- world-layout authorship
- encounter identity
- pacing
- qualitative acceptance criteria
- what should be preserved vs discarded from the previous implementation

After that, implementation may be delegated according to the repo's existing Fable-dispatch rules.

## 0.3 Never duplicate existing backlog work

This plan overlaps existing items, particularly:

- movement/animation quality work
- `R7.3` world-layout work
- `SB9`–`SB11` progression plumbing
- `SC12`–`SF34` Meadows content
- catching work
- captain/dungeon work
- future leveling/XP work

Do not create second systems or competing backlog items for the same feature.

Instead:

- amend/supersede the quality brief of the existing item;
- create child/remainder items only where a task is too large for one firing;
- reference the original backlog ID in every child item;
- close/replace stale wording explicitly when this brief supersedes it.

## 0.4 Current `main` wins over stale documentation

Before executing any item:

1. inspect current `main`;
2. inspect the current relevant `BACKLOG.md` entry;
3. inspect relevant `DONE.md` history only for the specific feature;
4. confirm whether the problem still exists in the current playable build.

Do not rebuild functionality that has already shipped successfully because an older note still describes it as missing.

## 0.5 Player experience is the gate

A task is not complete because:

- code compiles;
- tests pass;
- a shader changed;
- animation curves changed;
- a scene exists;
- a feature technically works.

For all quality items, completion requires direct player-facing or rendered verification appropriate to the feature.

## 0.6 Preserve shipped quality unless intentionally superseded

When rebuilding larger systems such as the world layout, do not silently regress already-shipped work.

Preserve the latest validated versions of:

- opening sequence
- village
- hillside
- vegetation
- terrain material work
- stronghold
- NPCs
- catching presentation
- UI
- current asset-family rules

unless the new design genuinely requires change.

Never reconstruct these from older docs or memory.

---

# 1. BUILD ORDER

Use this order unless a concrete dependency proves another order is necessary:

1. `MQ1A` — locomotion motion rebuild
2. `MQ1B` — locomotion terrain adaptation / foot placement
3. owner/blind checkpoint on movement and current catching
4. `MQ2A` — Meadows macro-layout redesign
5. `MQ2B` — prove one finished-quality regional loop
6. build remaining regional geography incrementally
7. progression plumbing (`SB9`–`SB11`) as required
8. region content in unlock order (`SC12`–`SF34`)
9. `PW2` alpha/elder encounters integrated during region authoring
10. `PW4` signature encounter rules integrated into dungeon/captain authoring
11. `PW1` traversal shortcuts only if owner approves
12. revisit catch probability only if fresh play evidence says it is still needed

Do **not** build a huge empty world first and promise to make it interesting later.

---

# 2. MQ1A — FULL LOCOMOTION MOTION REBUILD

**START WITH FABLE**

`area: player, animation`

This supersedes any assumption that the current gait only needs more tuning.

## Why

The current movement has already been tuned repeatedly and has still produced visibly unnatural motion.

The rebuild should assume the current procedural locomotion clips may themselves be the ceiling.

Do not begin by preserving:

- the current procedural sine motion;
- the current arm swing;
- the current leg phase;
- the current transition strategy;
- the current playback-rate solution;

unless fresh Fable review concludes those pieces are genuinely worth keeping.

## Goal

The trainer and reused humanoid rigs should move like believable stylized people.

The target is:

- grounded;
- weighty;
- readable;
- natural enough that the player stops noticing the animation;
- consistent with the game's existing Palworld-adjacent visual register without copying it.

Not:

- floaty;
- ice-skating;
- robotic;
- exaggerated cartoon sprinting;
- arms moving in anatomically wrong directions;
- stiff procedural pendulum motion.

## Required design pass

Before implementation, Fable must review current walk/run renders from:

- rear;
- side;
- front three-quarter;
- rear three-quarter;
- start;
- stop;
- turn;
- walk;
- sprint.

Fable then decides:

- what is fundamentally wrong;
- which existing motion components should be discarded;
- whether to rebuild clips procedurally, author/import better clips, or use another allowed approach;
- the desired walk/run transition behavior;
- the intended arm/leg opposition;
- the intended hip/shoulder motion;
- the intended stride length and cadence.

## Required motion qualities

The rebuilt locomotion must include:

- anatomically correct arm/leg opposition;
- elbows bending naturally;
- knees bending in the correct direction;
- no visible hyperextension;
- believable hip rotation;
- counter-rotation through shoulders;
- natural stride;
- clear distinction between walk and sprint;
- acceleration that does not read as a gear shift;
- deceleration with visible weight;
- natural directional changes;
- no obvious upper-body freeze while legs move;
- no persistent foot skating on flat ground.

## Shared-rig scope

Fix the reusable humanoid locomotion system once where practical.

The trainer, Grandpa, Warden, villagers, and other reused humanoid rigs should not remain on visibly inferior motion if they share the same locomotion foundation.

## Verification

Use existing capture tooling where useful, but visual quality is the primary gate.

Required:

- one full walk-cycle contact sheet;
- one full sprint-cycle contact sheet;
- rear and side motion capture;
- start/stop capture;
- turn capture.

At minimum inspect:

- heel/contact;
- mid-stance;
- toe-off;
- mid-swing;

for both legs.

Measurements such as foot-sweep/body-speed comparison are supporting diagnostics, not the final acceptance criterion.

## Done when

A fresh blind visual critic:

- does not flag backward/unnatural arm movement;
- does not flag broken knee/elbow anatomy;
- does not flag floatiness or robotic cadence;
- does not flag obvious flat-ground foot skating;
- reads walking and sprinting as intentional, grounded locomotion.

If the critic still describes the motion as fundamentally wrong after multiple implementation rounds, **do not continue micro-tuning the same approach**. Return to Fable and restart the motion solution.

---

# 3. MQ1B — TERRAIN ADAPTATION AND FOOT PLACEMENT

**START WITH FABLE**

`area: player, animation`

Depends on `MQ1A`.

Do not build sophisticated terrain IK on top of a bad base walk cycle.

## Goal

The good flat-ground locomotion from `MQ1A` must continue to look believable on the real Meadows terrain.

## Required capabilities

Evaluate and implement the minimum robust solution needed for:

- uphill walking;
- downhill walking;
- cross-slope walking;
- uneven ground;
- small terrain height variation;
- idle stance on slopes.

This may include:

- foot planting;
- foot IK;
- foot orientation to ground normal;
- pelvis compensation;
- stance-phase locking;
- controlled release at toe-off.

Do not add complexity for its own sake.

## Done when

Blind rendered/play inspection on flat and sloped test terrain shows:

- no gross foot penetration;
- no obvious hovering;
- no sustained slope skating;
- no knee inversion;
- no broken pelvis motion;
- no visible snapping caused by IK;
- walk/run still reads as natural.

---

# 4. MOVEMENT + CATCHING OWNER CHECKPOINT

Before large-scale Meadows world construction begins, run a fresh player-facing checkpoint.

Purpose:

- verify `MQ1A/B` actually solved movement feel;
- verify the **current shipped catching implementation** in real play;
- determine whether catching still needs probability changes.

Do not assume old catching complaints still apply.

The current implementation already includes trajectory-preview and aim-assist work.

At this checkpoint explicitly judge:

- can the player predict the throw before release?
- does aiming feel controllable?
- does early catching feel frustrating because of aim, odds, feedback, or encounter tuning?
- is the tutorial/common catch experience satisfying?

Only create a new catch-probability task if current play still demonstrates a real problem.

---

# 5. MQ2A — MEADOWS MACRO-WORLD REDESIGN

**START WITH FABLE**

`area: terrain, world-layout`

This is the quality brief for the existing `R7.3` world-layout work.

Do not create a parallel second world-layout system.

## Core structure

The Meadows chapter should have a clear progression spine:

**Village / Lower Meadows
→ Quarry / Burrow region
→ River / Relay region
→ Upper Meadows / Ironwood region
→ Stronghold**

But the world must **not** feel like one long corridor.

Each progression band should open into an explorable regional loop.

Use:

- branching paths;
- reconnecting paths;
- overlooks;
- shortcuts;
- side valleys;
- small vertical loops;
- optional clearings;
- hidden pockets;
- alternate return routes;

while preserving the understandable macro progression.

The mental model should be:

> a connected adventure through several real places

not:

> a road with content placed beside it.

## Scale philosophy

Do not target map size for its own sake.

Do not force a 10–20 minute uninterrupted straight-line walk merely to create scale.

The world should be only as large as the team can make meaningfully dense.

Prioritize:

- memorable geography;
- navigation;
- authored composition;
- meaningful decisions;
- exploration;
- strong vistas;
- region identity;

over raw kilometers.

## Interesting-decision density

During normal exploration, traversal should regularly present something worth noticing or deciding.

Examples:

- fork in the trail;
- resource opportunity;
- creature behavior;
- vista;
- environmental story;
- ruined object;
- alpha/elder silhouette;
- optional path;
- hidden cache;
- landmark;
- climbable rise;
- NPC;
- traversal shortcut;
- safe camp location;
- combat risk;
- useful gatherable cluster.

Long stretches of simply holding forward through procedural scenery are a failure even if the terrain is visually attractive.

## Regional identity

Each band must have a distinct playable and visual identity.

Not a different biome.

Still Meadows.

But distinguish regions through combinations of:

- landform;
- vegetation structure;
- openness;
- path geometry;
- water;
- rock exposure;
- elevation;
- ruins;
- human occupation;
- creature behavior;
- weather/lighting opportunities.

## Navigation

The player should be able to develop a mental map.

Use:

- visible landmarks;
- terrain silhouettes;
- path hierarchy;
- region entrances;
- elevation cues;
- reconnecting routes;
- strong local focal points.

Design the world so the minimap supports navigation rather than being the only reason navigation is possible.

## Camps

Do not convert the route into a chain of free hotels.

Authored camp-related locations should primarily be:

- safe clearings suitable for the player's own camp;
- abandoned camps;
- ruined camps;
- story camps;
- resource/rest landmarks;

unless the existing progression explicitly calls for a functional fixed rest point.

Player-built campfire/bedroll gameplay must remain meaningful.

## Day span

A normal exploratory chapter crossing should naturally expose the player to multiple day/night cycles.

Do not engineer the map around hitting an arbitrary day-counter number.

## Preserve shipped scenes

Reuse/reposition the latest validated:

- village;
- hillside;
- stronghold;
- vegetation rules;
- opening area;

rather than rebuilding them from stale versions.

## First deliverable

Before constructing the full final terrain, produce a top-down authored map plan showing:

- all five macro bands;
- main progression spine;
- regional loops;
- reconnects;
- major elevation;
- river;
- quarry;
- stronghold;
- major landmarks;
- intended side-content pockets.

Fable must approve this shape before large terrain production begins.

## Done when

A blind traversal of the macro layout can answer:

- where did I come from?
- where can I go?
- what region am I in?
- what landmark am I orienting around?
- what looks optional?
- what looks like progress?

without the route feeling like disconnected pockets or a hallway.

---

# 6. MQ2B — PROVE ONE REGION AT FINISHED QUALITY BEFORE SCALING

**START WITH FABLE**

`area: terrain, world-layout, content`

Do not build all five bands at mediocre density.

Take the first appropriate Meadows region and finish it to the actual desired production standard.

This is the production-recipe proof.

## The region must include

- final-quality terrain composition;
- final-quality vegetation structure;
- readable paths;
- major landmark;
- exploration loop;
- at least one reconnect/shortcut;
- meaningful gatherable placement;
- creature habitat;
- at least one optional discovery;
- at least one memorable encounter or event;
- day and night readability;
- useful navigation;
- no obvious empty filler stretches.

## Playtest gate

A blind playtest should spend meaningful time exploring the region voluntarily rather than simply following the critical path through it.

The tester should be able to describe:

- what made the region visually distinct;
- what made it mechanically interesting;
- where they chose to leave the path;
- what landmark they used to navigate;
- what they discovered;
- whether traversal felt empty.

## Expansion rule

Only after this region passes should its composition/content principles be used to author the remaining bands.

Do not copy exact layouts.

Copy the quality bar and production discipline.

---

# 7. MQ3 — MEADOWS CONTENT UMBRELLA

**START WITH FABLE FOR EACH MAJOR CONTENT BEAT**

`area: content, quests`

This is **not one giant Ralph task**.

This is the creative/quality umbrella for the existing `SB9`–`SB11` and `SC12`–`SF34` work.

Break the implementation into the existing progression-sized units.

## Progression plumbing

Build the necessary progression infrastructure first where still unbuilt:

- state tracking;
- keys/gates;
- quest log;
- required objective transitions.

Do not over-generalize future-biome architecture.

## Author in unlock order

Populate regions in progression order so each section can be played and judged before later content depends on it.

## Regional exit gate

A region is not complete merely because all quest triggers fire.

Each regional package should include:

- clear entry;
- clear purpose;
- recognizable geography;
- one meaningful critical-path objective;
- at least one optional discovery;
- one memorable encounter;
- navigation that works;
- day/night usability;
- meaningful reason to explore;
- clear transition toward the next region.

## Side content philosophy

Optional content should make leaving the main route feel worthwhile.

Do not hardcode the design around XP/hour before the leveling economy exists.

Possible rewards include:

- XP;
- crafting materials;
- rare consumables;
- recipes;
- buildables;
- unique encounters;
- shortcuts;
- lore;
- useful world information;
- visual/memento rewards.

When `R4.1` eventually provides XP/levels, tune XP rewards as part of the broader progression economy rather than inventing a fixed multiplier now.

## Do not block fun content on XP

Side quests and optional discoveries may be authored before the XP system exists.

Reward wiring can land later.

---

# 8. PW2 — ALPHA / ELDER WILD VARIANTS

**START WITH FABLE**

Fold this into regional content creation.

No new Meadows creature meshes.

## Purpose

Create rare landmark encounters that make exploration memorable and give optional paths a reason to exist.

## Required differentiation

An alpha/elder must not simply be:

> normal creature + larger scale + more HP.

Each should have at least one meaningful behavioral or encounter difference, such as:

- different aggression pattern;
- altered attack cadence;
- unusual group behavior;
- unique habitat;
- environmental advantage;
- move variant;
- special arena;
- unusual time-of-day presence;
- distinct VFX/animation treatment.

## Reward design

Defeating an alpha should be worthwhile even when the player does not want to catch it.

The five-pal limit means catch value alone is not enough.

Rewards may include:

- rare materials;
- unique drops;
- recipe progress;
- world unlock;
- narrative discovery;
- cosmetic/memento reward.

Do not create a storage loophole.

---

# 9. PW4 — SIGNATURE DUNGEON AND CAPTAIN ENCOUNTERS

**START WITH FABLE**

Fold this into the existing dungeon/captain items.

## Rule

No major dungeon or captain fight should reduce to:

> same standard fight in a different room with more HP.

Each major encounter needs one strong identity.

## Scope discipline

Prefer recombining mechanics the player already understands.

Good examples:

- terrain forcing repositioning;
- attack windows tied to cover;
- environmental hazards;
- vertical arena structure;
- changing safe zones;
- adds/priority targets;
- destructible arena elements;
- movement timing;
- type interaction expressed spatially.

Avoid building an entire bespoke system used once.

## Done when

A blind player can describe what made each captain/dungeon mechanically memorable without answering only:

- "it was harder";
- "it had more health";
- "it looked different."

---

# 10. PW1 — PARTNERED TRAVERSAL ABILITIES

**OWNER DECISION REQUIRED BEFORE BUILDING**

Do not sequence until approved.

## Recommended direction if approved

For Meadows, use pal traversal abilities primarily for:

- shortcuts;
- secrets;
- alternate routes;
- optional resource areas;
- optional alpha encounters;
- alternate dungeon entrances;
- traversal convenience.

Do **not** make the critical Meadows storyline permanently depend on owning a specific pal unless the design also guarantees the player cannot softlock themselves through the five-pal permanent-roster rule.

Examples:

- glide from a ridge;
- cross a small optional water route;
- dig/open a shortcut;
- reach a ledge;
- bypass a long return path.

The system should make team composition affect exploration without turning roster choice into an accidental progression trap.

---

# 11. PW3 — SIXTH-PAL RELEASE / TRIBUTE

**DO NOT IMPLEMENT A STAT-TRIBUTE SYSTEM**

The sixth-pal decision is one of Tetherbound's distinctive emotional mechanics.

Do not convert released pals into permanent combat statistics or upgrade fuel.

That would incentivize catching creatures specifically to sacrifice them and undermine the intended emotional release choice.

If the release experience needs more lasting meaning, prefer non-power persistence such as:

- journal/memory entry;
- camp keepsake;
- record of name and release location;
- later sighting;
- relationship history;
- cosmetic remembrance.

Any larger mechanical reinterpretation of release requires a new owner decision.

---

# 12. CATCHING — CURRENT DIRECTION

Do not automatically create a new trajectory-visibility rebuild.

The current repo already contains significant catching presentation work.

## Required next action

At the movement/catching checkpoint, play the current implementation fresh.

Only reopen catching visibility if real play still shows the player cannot predict the throw.

## Catch probability

Do not implement a low-level catch floor solely because an older complaint requested one.

First determine the actual current source of frustration:

- aim;
- trajectory readability;
- catch odds;
- poor odds communication;
- insufficient early orbs;
- practice-creature tuning;
- HP tuning;
- feedback.

The tutorial/common creature already has its own catch tuning and should be adjusted first if the problem is specifically early onboarding.

A global catch floor becomes an owner decision only if fresh evidence shows the existing design still creates a bad early-game experience after the current presentation improvements.

---

# 13. QUALITY GATES FOR EVERY REGION

Every Meadows region should pass these before being considered production-ready.

## Geography

- recognizable silhouette;
- clear entrance/exit;
- no arbitrary terrain walls;
- no giant empty filler space;
- traversal feels authored.

## Navigation

- major landmark;
- useful paths;
- optional routes readable;
- reconnects/shortcuts where appropriate;
- player can return to a known location.

## Content density

- meaningful interaction/discovery opportunities occur regularly;
- gathering placement feels intentional;
- creatures inhabit believable spaces;
- optional content exists off the critical route.

## Visual quality

- terrain materials coherent;
- vegetation clustered/composed rather than random noise;
- path surfaces read correctly;
- landmarks have clear visual hierarchy;
- repeated asset use is disguised through composition rather than random tinting.

## Gameplay

- at least one memorable encounter;
- at least one reason to explore;
- progression objective works;
- no obvious softlocks;
- day/night both playable.

## Blind test

The blind tester should be able to answer:

- Where am I?
- What is important here?
- Where is likely progress?
- What tempted me off the path?
- What did I remember about this region afterward?

---

# 14. RESTART RULE FOR CEILINGED WORK

This rule is intentional and applies across this plan.

If an aesthetic/player-feel item has undergone repeated tuning rounds and the blind result remains fundamentally below target:

**STOP TUNING.**

Create a fresh rebuild child item marked:

`START WITH FABLE`

The rebuild should:

1. state the player-facing target;
2. identify what previous approach hit the ceiling;
3. explicitly name what may be discarded;
4. preserve only settled design constraints and useful assets/data;
5. start the creative solution again;
6. produce new representative captures;
7. use a fresh blind critic;
8. iterate only while the new approach is converging.

Examples include:

- locomotion;
- terrain composition;
- vegetation composition;
- major landmark massing;
- encounter presentation;
- UI composition;
- any other visual/feel system where endless micro-tuning has stopped producing meaningful gains.

Do not allow sunk cost to become a design constraint.

---

# 15. BLIND-VERIFICATION RULE

For creative/visual work, the agent who built the feature should not be the only judge of whether it succeeded.

Where practical, use a fresh blind critic that is not told:

- what was changed;
- what bug was being chased;
- what answer the implementing agent hopes to hear.

Ask the critic what is wrong with the result first.

If the original targeted defect no longer appears among the meaningful complaints, that is stronger evidence than asking:

> "Did we fix X?"

---

# 16. REQUIRED SCREENSHOT / CAPTURE EVIDENCE

For visual or feel milestones, retain representative evidence in the repo's existing workflow.

At minimum include:

- before;
- after;
- the exact player-facing vantage relevant to the task;
- night variant when lighting matters;
- movement sequence when animation matters;
- top-down/map view when geography matters.

Do not close a visual-quality task based only on code inspection.

---

# 17. FINAL MEADOWS QUALITY TARGET

The Meadows chapter should ultimately feel like:

- a real connected place;
- a journey through several memorable regions;
- dense enough that exploration remains interesting;
- readable enough that navigation does not depend on developer knowledge;
- grounded and comfortable to traverse;
- populated by creatures that feel placed in habitats rather than spawned into a field;
- paced so story, exploration, gathering, catching, combat, and building reinforce each other;
- visually cohesive;
- controller-first;
- polished enough that the player stops thinking about implementation defects and starts thinking about what they want to do next.

The goal is not to complete the maximum number of backlog entries.

The goal is to make the Meadows a chapter the owner and a fresh player voluntarily want to keep playing.

---

# 18. OWNER DECISIONS STILL REQUIRED

Do not invent answers to these.

1. Approve/reject `PW1` partnered traversal abilities.
2. If approved, define whether Meadows traversal abilities are optional/shortcut-only or can gate critical progress.
3. Any future catch-floor mechanic after fresh play evidence.
4. Any mechanical reinterpretation of the sixth-pal release beyond the non-power remembrance direction above.

Everything else in this plan is intended to be executable under the existing project rules.
