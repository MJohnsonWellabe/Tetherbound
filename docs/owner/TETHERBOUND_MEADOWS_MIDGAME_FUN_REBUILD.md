# Tetherbound — Meadows Midgame Fun Rebuild
## Claude Code implementation prompt

**Status:** Owner-directed gameplay redesign  
**Run in parallel with:** `TETHERBOUND_VISUAL_STUNNING_PASS.md`  
**Primary objective:** Turn the Meadows after the first-hour opening into a compelling 3–4 hour creature-training campaign focused on building the best team of five to defeat Team Tether.

---

## 0. Read before changing anything

Start from current `main`.

Read at minimum:

1. `CLAUDE.md`
2. `docs/GAME_VISION.md`
3. `docs/specs/MEADOWS_PROGRESSION_SPEC.md`
4. `docs/ROADMAP.md`
5. newest owner directives/playtests
6. the current First-Hour Fun Rebuild / opening dialogue implementation if it has landed
7. current band spawn/trainer/resource/objective data
8. tournament, South Bridge, Warrens, Relay, Upper Meadows, Captain, Stronghold and Warden implementation
9. current reward/XP/TM/equipment/crafting systems
10. current save/load/progression state

Do not replace working systems with parallel systems.

This is an **experience-structure pass**. Reuse existing infrastructure wherever possible.

---

## 1. Product thesis

After the village tournament, Tetherbound must stop feeling like:

> follow road → fight something → run a long distance → reach next marker.

The Meadows should become:

> **Build the strongest, most versatile, most personally meaningful team of five you can, because Team Tether keeps giving you harder problems to solve.**

The entire chapter after the tournament should repeatedly create reasons to:

- catch a new creature;
- replace or reconsider a team member;
- train;
- learn switching/type coverage;
- seek a TM;
- obtain equipment;
- gather a meaningful material;
- establish or use a camp;
- heal/rest a creature;
- explore a side route;
- fight an optional trainer;
- challenge a stronger wild creature;
- prepare for a known Team Tether threat.

The player should nearly always understand:

1. **What major threat am I preparing for?**
2. **What could make my five better before I face it?**

---

## 2. Meadows campaign structure

Implement/tune the chapter around this progression:

**Opening / Grandpa**
→ starter
→ first catch
→ Mira
→ Creek Hollow
→ first campsite
→ Village Tournament
→ **South Bridge / first Team Tether grunts**
→ Lower Meadows team-building
→ **Burrow Warrens / Guardian**
→ River region preparation
→ **Tether Relay assault / Captain Vance**
→ world-state payoff / crossing restored
→ Upper Meadows opens
→ **Three Captain Hunts**
→ three Sigils
→ Stronghold Approach
→ final preparation opportunity
→ **Meadows Hall gauntlet**
→ **Warden**
→ legendary
→ final-five decision
→ Meadows recovery.

Do not turn this into a linear corridor. The critical path is clear, but the world around it should create optional preparation decisions.

---

## 3. Major challenge ladder

The player should repeatedly know the next serious challenge.

Use the existing canonical ladder:

1. first wild encounter;
2. village tournament;
3. South Bridge / first Team Tether confrontation;
4. Warrens Guardian;
5. Tether Relay / Captain Vance;
6. Upper Meadows Captain 1;
7. Upper Meadows Captain 2;
8. Upper Meadows Captain 3;
9. Meadows Hall trainers / elite;
10. Meadows Warden.

Each rung must feel meaningfully harder or mechanically different.

Do not make progression only “same fight, larger HP.”

---

## 4. South Bridge — first Team Tether proof

Immediately after the tournament, give the player a concrete next objective:

### REACH SOUTH BRIDGE

The player should understand Team Tether is controlling deeper routes.

At or near the bridge:

- introduce the first real Team Tether grunt encounter;
- clearly distinguish Team Tether presentation from village trainers;
- make the fight a noticeable step up without becoming a wall;
- reward victory with physical route progression, useful preparation, or both;
- make the player feel: **“I can beat their lowest-level people.”**

Use believable world gating, not a UI level lock.

If existing bridge logic uses a key/mechanism, preserve the physical-world logic while making the Team Tether conflict part of the experience.

---

## 5. Lower Meadows after the tournament

The route to the next major challenge cannot be bare.

Populate/tune the Lower Meadows so normal traversal provides repeated reasons to stop.

Include a deliberate mix of:

- ordinary wild creatures;
- at least 2–3 legitimate roster temptations;
- local trainers;
- Team Tether patrol or evidence;
- resources with known uses;
- a TM pickup/discovery;
- small creature cluster/nest;
- a stronger wild individual;
- a short side path or landmark;
- at least one optional discovery that visibly pulls the player away from the main route.

Do not merely increase random prop density.

Every addition should pay into team strength, team choice, preparation, discovery, route knowledge, or story/world pressure.

---

## 6. Burrow Warrens — roster improvement test

The Warrens must make the player question whether their current team is good enough.

### Objective

**EXPLORE / CLEAR THE BURROW WARRENS**

The player should find:

- stronger Ground-oriented non-starter creatures;
- desirable catches;
- Rootstone;
- a meaningful TM/reward;
- evidence of Team Tether;
- the Guardian;
- at least one optional harder branch or special encounter.

### Critical starter rule

No starter species or starter variants in the Warrens.

Remove `Elder Terrapup` and prevent equivalent starter reuse.

### Design purpose

If the player struggles with the Guardian, intended responses should include:

- catch a better-suited creature;
- improve type coverage;
- train;
- use switching better;
- equip/use a TM;
- rest/recover;
- improve preparation.

Do not make repetitive grinding the only practical solution.

---

## 7. Tether Relay — first real enemy operation

The Relay should feel like a mission, not merely the next fight marker.

### Objective

**SHUT DOWN THE TETHER RELAY**

The approach should contain:

- Team Tether visual presence;
- patrols/grunts;
- desirable wild creatures;
- meaningful resources;
- optional trainer/encounter;
- visible environmental damage;
- captive/story clues;
- a practical camp/recovery opportunity before commitment.

The assault should escalate through an authored chain such as:

**Grunt(s) → Officer → Captain Vance**

Do not require them to be back-to-back with no pacing.

### Victory payoff

After Captain Vance:

- machinery shuts down;
- captive is freed;
- crossing becomes available;
- local environment visibly changes where systems permit;
- story acknowledges the victory.

The player must see that defeating Team Tether changes the world.

---

## 8. Upper Meadows — Captain Hunt structure

The Three Captains are the core of the late-middle game.

Treat them as three mini-boss hunts / preparation exams.

Each Captain grants a Sigil required to open the Meadows Hall approach.

The captains must test **different aspects of team-building**, not simply higher stats.

### Captain 1 — Power / fundamentals

Purpose: **Are your creatures actually strong enough?**

Emphasize readable hard combat, levels/moves, movement/attack skill, and baseline team strength.

Reward: Sigil + strong TM or equivalent + substantial XP/progression payoff.

### Captain 2 — Team composition

Purpose: **Did you build a balanced five?**

Design the roster/encounter so a one-dimensional team has a noticeably harder time.

The player should plausibly respond by hunting a different type, changing a team member, teaching a move, or switching more intelligently.

Reward: Sigil + meaningful creature equipment / preparation reward where supported.

### Captain 3 — Endurance / expedition management

Purpose: **Can you keep your team functional through a difficult expedition?**

Use a route with meaningful fights before the Captain, injury/recovery pressure, camp/rest value, switching, and preparation choices.

Do not turn it into survival punishment.

Reward: final Sigil + final-preparation unlock/reward.

---

## 9. Every Captain creates a preparation loop

For every Captain:

**Learn about threat**
→ understand what makes it difficult
→ explore for creatures/TMs/resources
→ catch or improve team
→ train
→ equip/prepare
→ camp/rest
→ challenge Captain
→ receive Sigil + meaningful reward.

Do not tell the player exactly which creature to use.

Give enough information that preparation feels intelligent rather than random.

---

## 10. Team Readiness presentation

Create or improve a lightweight readiness communication layer for major challenges.

This does NOT need to be a new numerical stat.

For a major challenge, communicate useful non-binding guidance such as:

- approximate expected level range;
- whether varied types are recommended;
- whether the challenge is an endurance sequence;
- whether rested creatures are recommended;
- any special mechanic already known to the player.

Do not hard-lock by level.

Also surface clear honest ways to improve:

- battle trainers;
- hunt stronger creatures;
- find TMs;
- improve equipment;
- gather useful materials;
- rest/recover.

---

## 11. Region-by-region roster temptation

Catching must remain relevant for the full chapter.

Every major region must contain at least **2–3 credible reasons to reconsider the five**, using a combination of:

- new species;
- better type coverage;
- uncommon species;
- higher-level individual;
- visual size variation;
- rare trait/appraisal;
- shiny;
- evolution potential;
- traversal role;
- attachment / visual appeal.

The test is:

> **Could a reasonable player see something here and think, “I might want that instead of one of mine”?**

By the legendary, the five-creature rule should already feel emotionally real.

---

## 12. World activity cadence — eliminate dead Meadows

The world does not need constant combat. It does need constant **potential**.

### Authoritative cadence target

During required traversal, the player should **rarely go more than roughly 60–90 seconds without seeing or encountering a meaningful reason to** fight, catch, gather, investigate, prepare, change direction, or anticipate something clearly visible ahead.

This is an experience target, not a hard-coded timer.

A visible herd on a ridge, trainer by a camp, strange cave entrance, TM sphere, Team Tether pylon, resource formation, ruined camp, rare creature silhouette, or distant landmark can satisfy the cadence even if the player chooses not to engage.

### Activity vocabulary

Use combinations of:

- creature nest / feeding patch;
- rare habitat;
- stronger Alpha/Elder **non-starter** creature;
- trainer;
- Team Tether patrol;
- Team Tether camp;
- TM sphere;
- resource formation;
- ruined campsite;
- cache/chest;
- NPC;
- small cave/overhang;
- overlook;
- creature in distress;
- special grove/tree;
- water/fishing opportunity if implemented;
- environmental storytelling;
- shortcut;
- time/weather encounter;
- landmark with visible reward.

Do not scatter all categories uniformly. Author them to fit regions.

---

## 13. Small content is valid content

Do not assume every point of interest needs a bespoke quest.

Examples:

- Pipwing nest on a rock shelf with a TM sphere;
- Team Tether grunt guarding an Orb cache;
- rare creature visible across a creek;
- tiny cave containing Rootstone and a strong Burrowback;
- abandoned camp with a recipe;
- trainer beside a scenic overlook;
- mushroom/berry pocket near a creature habitat;
- damaged Tether machine with environmental storytelling.

Use existing systems to create layered reasons to explore.

---

## 14. Reward ladder

Major victories need meaningful rewards beyond XP.

Use current systems and tune toward this shape:

- **Tournament:** validates first team; advances preparation.
- **South Bridge:** physical route progression + useful reward.
- **Warrens Guardian:** Rootstone progression + useful TM/equipment/recipe.
- **Captain Vance:** world-state change + restored crossing + meaningful reward.
- **Captain 1:** Sigil + strong TM.
- **Captain 2:** Sigil + equipment/preparation improvement.
- **Captain 3:** Sigil + final preparation unlock/reward.
- **Three Sigils:** physically open Meadows Hall approach.
- **Warden:** legendary release + chapter resolution + final-five decision.

Do not invent empty currencies merely to create reward slots.

---

## 15. Stronghold Approach — final preparation

The approach must build anticipation.

The player should see:

- Meadows Hall becoming visually dominant;
- increased Team Tether hardware/patrol presence;
- more damaged/drained land;
- stronger wild creatures;
- at least one final tempting roster opportunity;
- one clear final camp/preparation location;
- optional challenge/reward.

Give the player a moment to think:

> **Are these the five I want to take in?**

---

## 16. Meadows Hall — the exam

The Stronghold is the culmination of systems already learned.

Use escalating Team Tether trainers, meaningful combat spaces, readable camera, recovery pacing, an elite/final pre-Warden test where canonical, and the Warden.

The Warden should test the team the player spent the whole chapter building.

After victory:

- tether mechanism disabled;
- legendary freed;
- voluntary join offer;
- if party is full, permanent release choice with ceremony;
- world recovery/state changes;
- story acknowledgment.

The final emotional answer is:

> **These are my five.**

---

## 17. Measure fun structure

For every major route/region measure:

- real traversal time;
- longest dead-travel interval;
- visible wild opportunities;
- legitimate roster temptations;
- trainers;
- Team Tether encounters;
- meaningful resources;
- optional detours;
- major landmarks;
- time to next meaningful decision;
- time spent confused;
- XP gain;
- team changes;
- rests/camp uses;
- rewards;
- whether the player understood what they were preparing for.

A green config file is not proof the region is fun.

---

## 18. Fresh-playthrough target

A fresh Meadows playthrough should produce:

- first team formed near home;
- tournament proves basics;
- first Team Tether grunt beaten;
- Warrens encourages roster improvement;
- Relay makes Team Tether a real enemy;
- Upper Meadows repeatedly tempts team changes;
- three Captains require different forms of preparation;
- Stronghold tests the accumulated team;
- legendary forces the final-five decision.

A focused clear remains approximately 3–4 hours, with longer runs for exploration and catching.

Do not pad with forced grinding.

---

## 19. Testing

Add/expand coverage for:

- starter uniqueness;
- challenge progression;
- objective transitions;
- Captain Sigils / Hall gate;
- reward delivery;
- save/load at every major chapter boundary;
- spawn validity;
- Team Tether encounter state;
- world-state changes after Relay/Warden;
- party-five rules.

Then run continuous player-path evidence.

Unit/smoke tests are necessary but not sufficient.

---

## 20. Parallel-work ownership

This prompt is intended to run in parallel with a visual production pass.

### Gameplay lane owns

- objectives;
- encounter placement/content intent;
- spawn/trainer/resource data;
- progression;
- rewards;
- readiness communication;
- Team Tether campaign structure;
- Captain structure;
- pacing/activity cadence;
- gameplay state.

### Avoid owning unless required

- broad lighting rewrite;
- terrain shader/material art pass;
- vegetation visual overhaul;
- global post-processing;
- asset beautification;
- decorative prop pass.

Coordinate shared files before editing.

---

## 21. Acceptance standard

The Meadows midgame passes only when continuous play demonstrates:

1. The next serious Team Tether challenge is usually clear.
2. The player repeatedly has understandable ways to improve.
3. Catching remains relevant throughout the chapter.
4. Every major region creates genuine roster temptation.
5. Survival/building/care support the creature journey rather than distract from it.
6. Major fights test different aspects of the five.
7. Major victories change capability, access, or world state.
8. Long required stretches of purposeless travel are rare.
9. The Stronghold feels like the exam for the team the player built.
10. The legendary choice pays off the five-creature rule.
11. The player would voluntarily keep exploring because the world keeps presenting things worth doing.

**Primary judgment:**  
> Does the player spend the Meadows thinking about how to build a better five for the next Team Tether challenge?
