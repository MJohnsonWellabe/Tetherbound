# Tetherbound — Game Bible

## 1. The game we are making

**Tetherbound is a four-chapter creature expedition action RPG for Windows and ROG Ally, playable alone or with up to three friends. You leave home with a named companion, choose at most five creatures to keep, directly pilot their distinct real-time fighting styles, and prepare small camps for journeys through authored regions. The pleasure is getting better with a team you remember, taking detours that change what that team can do, and physically reopening a world divided by Team Tether. Keeping the same beloved five through the ending is success. This pass ends in Tidewake with a regional victory and homecoming; eight good hours are acceptable without padding to twelve. The longer-term plan remains eight biomes, with the other four outside this pass.**

This is the central product decision. PRODUCT owns audience, price and cuts; the ten documents in `design/` specify it; ACCEPTANCE defines proof. This Bible owns identity and canon, not a second copy of every tuning number. `ralph/reports/PLAN-REWRITE/FINDINGS.md` preserves the full archive recovery and dispositions.

The honest genre is an **authored creature expedition action RPG**. Open world describes freedom within large, connected authored chapters; it does not promise an endless procedural survival sandbox. There are 57 base species records and 12 Water adapters at the audited baseline, not five species. **Five is the ownership cap.** A player may meet many creatures while keeping very few.

## 2. Pillars and the experience they demand

1. **Five companions with a shared history.** Name the starter, learn its attack shapes, see it travel beside you, care for it and remember a difficult victory. Later rewards deepen the team's moves, roles, traversal and history. A catch offers an optional different way to play at the cost of a real place in that team; replacing companions is never required to keep exploration rewarding. Names, bond tasks and a cap support attachment; they do not prove it. Releasing somebody is optional and deliberate.
2. **The creature is the action character.** The human explores and cares; in a fight the player pilots a creature, places attacks, reads tells, uses burst movement and switches. Five means five usable roles, not one attacker and four numerical benches. COMBAT's reader-versus-masher proof precedes encounter expansion.
3. **Prepare for a journey, then change the route.** A camp recovers creatures; a saddle changes travel; a TM changes reach; freeing a crossing changes the map. Gathering and building exist because those outcomes are useful. Repeated feeding clicks and an empty long road are not depth.
4. **A finite world with visible consequences.** Distinct regions invite detours and culminate in memorable fights. Machines stop, crossings reopen, people return and the actual team comes home. The ending pays off this campaign rather than selling an unfinished larger one.

The repeating 15–30-minute expedition is: notice a destination or creature; choose route and team; fight/catch or solve a traversal problem; get a durable payoff; judge health and supplies; recover or push farther. There must be scenic breathing room. Neither uninterrupted battle traffic nor forward-stick travel through decorative terrain satisfies the loop.

## 3. Hard rules retained

Godot/Windows/ROG Ally/controller first; five owned total with no box/reserve/sixth; human never fights; creature combat is real-time and directly piloted; no shield/block/held-button gameplay; catching only during wild combat, never trainer-owned creatures; no hunting/butchering/base jobs/automation; light satiety without starvation death; stack/slot inventory without carry weight; multiple persistent death satchels; creatures taller than the 1.80m trainer, resolving relative scale by growing the smaller side; reference-backed creature/humanoid work, with agent-drafted references and Meshy submission now owner-authorized for scoped improvements; oxblood/red reserved for Team Tether; all new gameplay multiplayer-native. AGENTS contains the operational form.

The owner explicitly changed the reference-source rule: agents may draft new art and run it through the existing Meshy license for scoped current-roster/hero improvements. Reference-backed work and quality/provenance checks remain; the owner no longer has to supply every image. ART_DIRECTION preserves earlier accepted assets and named exception history without turning them into unlimited batches. Installed assets and references are not proof of redistribution clearance.

## 4. World canon

Eight legendary forces are conduits that maintain artificial **Tether Rifts**. Team Tether controls those conduits and thereby controls movement, trade, knowledge and migration. Its doctrine is that separation prevents catastrophe. Some of that warning may be true: reconnection has consequences. The faction is a system of occupation and dependence, not only rude trainers on roads.

The player starts in Grandpa's farmhouse. Grandpa is a former trainer who cannot make this journey himself. He sends the player to become capable enough to challenge the occupation, with a named starter and practical help. The village tournament is the first proof that this means caring for a team and preparing for danger, not merely throwing Orbs.

The starters are Terrapup, Ripplet and Galewisp. They are exclusive to the player's choice: wilds, trainers, vendors, trades and variants cannot supply the other two. No starter evolution. Terrapup's early riding, Galewisp's later Fly and Ripplet's post-Stormwood return/Teleport capability are real promises; the latter two need integration work and must not be advertised as finished.

Warden Aldis believes he is preventing a worse disaster. He warns rather than recants after defeat. The four chapter leaders differ in method and territory, but all connect to this regional supply network. Rescued people and reopened routes carry the answer to their doctrine: reconnection is difficult and worth choosing.

Legendaries are freed and **volunteer**; they are not weakened for capture. A chapter completes whether the player accepts or refuses. There is one durable offer/recipient in a co-op world. Meadows, Stormwood and Tidewake have legendary offers; Cloudreach does not. Relics are reusable, with one personal power active; keys open the three physical interchapter gates once. Tidewake grants no fifth-chapter key. Neither a relic nor refusal is a hidden loss condition.

Out of scope for this pass: biomes five through eight, simulated continental rearrangement, systemic migrating populations, branching moral alignment, human combat, romance and a cliffhanger required to resolve the four-chapter regional story. Eight biomes remain the owner's longer-term direction, not a cancelled ambition or a dated delivery promise.

## 5. The four chapters

| Chapter | Player experience | Culmination and consequence | Grounding at b8eda885 |
|---|---|---|---|
| The Meadows | Leave a lived-in village, prove readiness, cross grassland, quarry and river, ride into high pasture and old growth, choose a team for the Hall. | Break relays, free captives, defeat Aldis, free Veridian, see healing and open Cloudreach. | **Partial:** continuous world, five band configs, 31 trainer rows, 365 wild rows, seven local objectives, stronghold/ceremony code. Accepted continuous first clear and distinct combat remain open. |
| Cloudreach Cliffs | Follow wind roads through six vertical regions; learn safe landings, Fly and how height makes a route. | Veyra's summit/aviary sequence and Wings; next realm becomes reachable. Cloudreach has no captive legendary offer. | **Partial:** cloudreach configs, scene, 82 wild rows/seven trainer encounters, act/finale consumers. Flight/remount and full path/device proof remain open. |
| The Stormwood | Travel beneath the Long Storm; read grounded clearings, rods and dangerous routes; restore the Stormglass circuit. | Dynamo and Stormheart, storm aftermath, Spark and Water passage. | **Partial:** stormwood data/world scripts, 26 trainer rows plus leader handling, 401 wild rows. Dynamo is instantiated; unbuilt was false. Earned accepted play is unproven. |
| Tidewake | Read currents across 12 islands in six groups; ride swimmers, open shortcuts, choose sea and land approaches. | Venn, Tidecoil, Nerissa/Veilfall and Abyssal Guardian; restored currents/docks and regional network closure. | **Partial:** Water runtime integration, 24 trainers, 303 wild rows and five named spawns. **Not built:** final regional-resolution/homecoming sequence below. |

Detailed maps, activities, counts and named fights are in WORLD and BOSSES. There is no mandatory 3–4-hour chapter or 12–16-hour campaign floor. Measure the earned route and preserve density, useful rewards and the ending; an eight-hour four-chapter clear can pass. Keep 6–10 meaningful optional activities per chapter and at least one per principal region. The old multiplication to 6–10 per subregion is explicitly reversed: it had no production budget and encourages shallow errands. Geography is not shrunk to meet duration.

### The ending we will build

Tidewake is the regional supply network's final relay, not the final legendary force in the universe. After the guardian resolution, the player disables the regional control link; a saved world-state transition changes currents, dock access and faction occupation. A short civilian dock exchange names both reopened trade and the work of living with reconnection. The player takes the restored route home.

Grandpa acknowledges the current five by their actual names, the starter if still owned, one bond/victory memory and chapter choices. Do not fabricate participation. A released starter is acknowledged without guilt or reversing the release. The scene ends with the team present and credits. Control returns to the completed world with outstanding optional activities available; no new compulsory quest, enemy scaling tier or fifth-chapter tease appears. WORLD specifies transactional flags/co-op playback; UX/AUDIO own presentation.

This is a new design decision, not a recovered implemented feature. The archive contained no complete four-chapter resolution; ending at the Water exit was not a finished product.

## 6. Systems earn their place

| System | Role | Current status and specification |
|---|---|---|
| Combat/catching | Master embodied roles; take a risk to recruit. | **Partial:** quick/charged, Wind, burst, poise, throw/switch code; Y skill/reactive AI/normalized poise are targets. COMBAT/CREATURES. |
| Care/bond | Recover for journeys; earn individual milestones. | **Partial:** beds, nourishment, happiness, unordered bond built. Revised credit and bounded injury unbuilt. CREATURES/SYSTEMS. |
| Gathering/crafting/building | Supply camps, tools, movement and moves. | **Built foundations, partial journey integration:** harvest/build/craft/catalogue/save paths. No factory. SYSTEMS. |
| Progression | Keep five viable as actions and routes change. | **Partial:** XP/cap100/type/TM/evolution/item paths; four-chapter budget unproven. PROGRESSION. |
| Traversal/weather | Change how each chapter is read. | **Partial:** riding/Fly/Water/Stormwood systems; starter utility and gates need integration. WORLD/SYSTEMS. |
| Co-op | Friends make choices with durable personal teams. | **Partial:** transport/authority/save infrastructure; four-peer campaign/device proof open. MULTIPLAYER. |
| Presentation | Appealing, readable, memorable creatures and places. | **Partial:** art, ordinary directional shadows, audio managers/synthesized cues exist. Commercial parity, custom silhouettes, final music and handheld certification unproven. ART_DIRECTION/AUDIO/UX. |

Building supports expeditions; it is not a rival to Valheim's construction game. Five-owned pressure differs structurally from Palworld's mass collection and labor loop. We win only if piloting, attachment and authored journeys are better than the chores they replace. If the first expedition cannot demonstrate that, expansion stops; prettier later biomes cannot fix it.

## 7. Explicit disagreements and scope control

The owner's first grilling answers supersede the rewrite's production assumptions: keep mechanics testing minimal, regard an unchanged beloved team as success, use coding/existing tools and the already-held Meshy license without new investment, retain required co-op, and accept eight good hours. Future growth to eight biomes remains intended outside this pass. New L4 skill, strain, bond and poise changes are candidate solutions, not a prerequisite bundle for the short existing-systems check in ROADMAP. The next owner answer explicitly authorizes agent-drafted references followed by Meshy and requires invitation-based co-op without router setup. ART_DIRECTION and MULTIPLAYER specify those workflows; neither is falsely reported as implemented by these document edits.

FINDINGS records every reviewed archive source and destination. This rewrite deliberately changes lower-level proposals: bounded injury replaces stacked C4 night/faint/revive pressure; unordered bond becomes attainable for late catches; current 1.25/0.80 types stay; a L4 geometry skill is selected over the unresolved TM-only alternative; activities are budgeted per chapter; a regional ending replaces the absent ending; Galewisp Scout reveal and Ripplet catch-affinity are dropped from minimum scope while later traversal promises remain.

These are explicit decisions for this proposed plan, not evidence that code changed or that every earlier preference was separately re-approved. Generation authority follows from the explicit owner instruction recorded in AGENTS/ART_DIRECTION, not merely merging prose. No new spending or other hard-rule exception is implied. If a later instruction conflicts with a hard rule, state the exact requested change in STATE before implementation. Routine numbers may be tuned with evidence; pillars and chapter scope are not quietly rewritten by an implementation agent.
