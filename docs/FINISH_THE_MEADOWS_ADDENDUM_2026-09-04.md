# Finish the Meadows — progression/exploration addendum

**Status:** active execution addendum to `docs/FINISH_THE_MEADOWS.md`, created 2026-09-04 from the newest owner directives in `docs/owner/OWNER_DIRECTIVES_2026-09-04-C.md`.

Read this immediately after `docs/FINISH_THE_MEADOWS.md`. Where this addendum expands a shorter row in that document, use this fuller requirement.

---

# Why this addendum exists

The current plan correctly identifies visuals, content after the village, and evidence as the remaining major tracks. Three connected player-experience gaps need to be made explicit inside that work:

1. Bonding and leveling are too invisible while they happen.
2. Exploration needs more finite, useful rewards spread through the world.
3. Creatures need enough contextual behavior to feel like companions rather than summoned combat units.

These are chapter-completion requirements, not Biome 2 work.

---

# A. Progression visibility — promote this above ordinary Phase 2b polish

The existing `FINISH_THE_MEADOWS.md` row **"Bonding and levelling made visible"** is load-bearing and is now expanded by the owner directive.

Treat it as a dedicated progression workstream, not a single VFX ticket.

## A1. Bond progress

Design the feedback contract first, then implement it in bounded lanes.

Required outcome:

- current bond is visible;
- progress toward the next milestone is visible and understandable;
- meaningful bond-gaining actions create readable feedback;
- milestone approach is legible without becoming noisy;
- milestone completion is a major audiovisual moment;
- the reward/effect of higher bond is clearly communicated;
- save/load preserves progress correctly.

Use existing gameplay actions where possible rather than inventing chores.

**Done when:** during a continuous Meadows segment, a player can identify at least two real actions that increased bond, can inspect progress toward the next milestone, and can recognize an actual milestone without checking debug data.

**Fails if:** only the final bond-up event becomes visible while the process of bonding remains opaque.

## A2. Level/XP progress

Required outcome:

- XP gain is visible after meaningful awards;
- current level and progress to next level are easy to inspect;
- approaching a level feels legible;
- level-up produces a strong audiovisual event;
- important resulting changes are surfaced to the player;
- candy level gains use the same core feedback language rather than a separate silent path.

**Done when:** normal combat and candy use both produce clear, consistent level progression feedback and the player can tell how close a creature is to the next level.

**Fails if:** a level changes correctly in data but the player must open a debug-like screen or infer it later.

---

# B. Candy exploration system

Add the owner-directed finite world consumables:

- **Good Candy**: +1 creature level;
- **Great Candy**: +2 creature levels;
- **Rare Candy**: +3 creature levels.

Target about 100 placed pickups across the full Meadows after tuning:

- ~60 Good;
- ~30 Great;
- ~10 Rare.

Use one persistent pickup identity per authored location so save/load cannot duplicate a collected candy.

## Placement contract

Do not author all 100 as one mechanical scatter pass.

Place them in regional batches tied to the world-density work:

- critical path: sparse, mostly Good;
- ordinary side exploration: Good with occasional Great;
- meaningful detours/points of interest: Great;
- difficult encounters, major secrets, memorable landmarks, deep branches: Rare.

The distribution should become more rewarding as the player moves into harder regions without making the opening trivial.

## Progression safety

Before mass placement, establish and test:

- creature level cap behavior;
- what happens when +2/+3 would cross the cap;
- whether one-creature funneling can trivialize required encounters;
- interaction with any level-gated trainer logic;
- save compatibility and one-time pickup persistence.

Prefer clamping/clear player feedback over silent waste if a candy cannot grant its full amount.

**Fails if:** candy placement makes required combat progression irrelevant or creates a save-reset farming exploit.

---

# C. World findable density — expand the existing density pass

The existing Phase 2 density task is not only about more wild spawns and harvest nodes.

Include authored pickup rewards in the same regional pass:

- candy;
- revives;
- potions/healing items;
- other useful existing consumables that fit the chapter economy.

Target roughly **100–150 meaningful placed item pickups across the Meadows, including candy**, then tune from actual route evidence.

Do not satisfy the count with random sprinkling. Every region should have an authored reward pattern.

For each band, measure at least:

- useful pickup count;
- critical-path pickup count;
- optional/side-route pickup count;
- average distance/time between meaningful discoveries on the walked route;
- whether recovery items arrive before/after the attrition they are meant to support;
- whether side exploration clearly pays better than simply staying on the road.

**Dependency remains unchanged:** density lands before level gating/no-refight rules that increase the need to regrind.

**Fails if:** findables become so common that potions/revives erase recovery/camping pressure.

---

# D. Pickup visual family

Inventory installed assets first.

Implement a readable three-tier candy family and recognizable world representations for recovery items.

The implementation can temporarily use existing suitable assets while systems are built, but visual completion requires normal-distance recognition and the standard capture + code-blind judge loop.

Do not spend generation budget before the project's reference-art rule allows it.

---

# E. Companion-presence pass — one additional improvement

Bond is supposed to make the player's five emotionally meaningful. UI feedback alone will not do that.

Add a small reusable contextual-reaction layer for the active/deployed creature, using existing animation capability wherever possible.

Target a limited set of high-value states rather than a large pet simulation:

- acknowledgment/attention toward the player;
- post-victory reaction;
- visibly hurt/tired reaction at low health;
- camp/rest reaction;
- care/feed/heal response;
- stronger or warmer reaction at higher bond where feasible.

This work should be designed alongside A1 so bond progression and companion behavior reinforce each other.

Avoid constant barks/animations. Reactions need cooldowns/context so they stay special and do not interfere with combat, traversal, interaction prompts, or camera control.

**Done when:** a continuous play segment with one creature produces multiple contextual companion moments naturally, and at least one of them is influenced by health, care, victory, rest, or bond state rather than playing as a generic random idle.

**Fails if:** the feature is only a looping idle animation that does not respond to the journey.

---

# Recommended execution order relative to FINISH_THE_MEADOWS

Start the original Phase 0 blockers and cheap Phase 1 visual work exactly as `FINISH_THE_MEADOWS.md` says.

In parallel:

1. write the A1/A2 progression feedback contract;
2. audit the existing bond/XP UI and event hooks;
3. audit current potion/revive pickup art and persistence infrastructure;
4. define candy item data/persistence/progression-safety tests;
5. design the minimal companion-reaction contract around existing animations.

Then implement:

- progression visibility first enough that candy rewards are satisfying when they land;
- candy item/persistence mechanics;
- candy + recovery-item regional placement as part of the Phase 2 density pass;
- companion reactions in parallel where file ownership allows;
- visual pickup pass and blind judging;
- route/evidence validation after each regional density wave.

Do not wait for all 100 candy locations before landing anything. Author, test, and merge by regional batch so the world improves incrementally and remains recoverable.

---

# Evidence to add to the final Meadows verdict

Before the chapter can be called finished, add evidence answering:

- Can a player tell how bond is progressing while they play?
- Can a player tell how XP/levels are progressing while they play?
- Do bond/level milestones feel consequential?
- Are Good/Great/Rare Candy understandable, persistent, and safe for progression?
- Does optional exploration reliably pay better than merely holding the critical path?
- Are potions/revives/findables frequent enough to reward exploration without removing attrition?
- Do active creatures visibly feel like companions during ordinary travel/care/combat downtime?

These answers should come from runtime evidence, not from code/config inspection alone.
