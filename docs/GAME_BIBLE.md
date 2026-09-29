# Tetherbound — Game Bible

## 1. The game we are making

**Tetherbound is a four-chapter creature expedition action RPG for Windows and ROG Ally, playable alone or with up to three friends. You leave Grandpa's farm with a named companion, keep at most five creatures, directly pilot their real-time fighting styles and build them into the best team you can. The spine is creature power; Grandpa's homestead is its required engine: essence spent by choice, breakthroughs earned from Masters and cooked into feasts, gear, moves and traits. The chapters run Meadows → Tidewake → Cloudreach → Stormwood, reached through the Crossing Hall's portals, and the story ends when the Stormwood finale sends you home by Grandpa's Home Key. A normal clear targets 15–25 hours with a loop that is fun to grind but optional to repeat: each biome needs real preparation, the main path needs no padding, and players who grind get clearly stronger. Keeping the same beloved five through the ending is success. Eight biomes remain the plan; this pass builds four and reserves slots for the other four (owner, 2026-09-29, RD-01, RD-02, RD-09).**

This is the central product decision. PRODUCT owns audience, price and cuts; the twelve contracts in `design/` specify it (TRAINING and HOMESTEAD are new, owner 2026-09-29); ACCEPTANCE defines proof (§6.2 holds the redesign rows F16–F49). `CODEX_START_HERE.md` §1 numbers the owner decisions RD-01..RD-35 that this revision integrates. This Bible owns identity and canon, not a second copy of every tuning number. `ralph/reports/PLAN-REWRITE/FINDINGS.md` preserves the archive recovery. **Everything below that goes beyond the stated baseline is a target, not built.**

The honest genre is an **authored creature expedition action RPG**. Open world describes freedom within large, connected authored chapters; it does not promise an endless procedural survival sandbox, and the homestead is a preparation engine, not a colony. There are 57 base species records and 12 Water adapters at the audited baseline; one new species, the Stormwood storm bear, is authorized (RD-28). **Five is the ownership cap.** A player may meet many creatures while keeping very few.

## 2. Pillars and the experience they demand

1. **Five companions with a shared history.** Name the starter, learn its attack shapes, see it travel beside you, care for it and remember a difficult victory. A catch offers an optional different way to play at the cost of a real place in the team; replacing companions is never required. Traits and Trait Seeds come *to* your five, so there is no pressure to swap them out (RD-30). Releasing somebody is optional and deliberate.
2. **Build the best five.** Building the strongest five-creature team is the goal (RD-02). Each creature grows by essence the player chooses to spend, a breakthrough every ten levels, a move loadout and mastery, traits, and a Harness and Charm per biome tier. Every biome's boss is meant for that tier of preparation. Grinding is optional and rewarding: the main path reaches each band without mandatory repeat grinding, and optional grinding measurably speeds it (F27#5, F47#1).
3. **The creature is the action character.** In a fight the player pilots a creature with quick, charged and utility moves plus a signature ultimate (RD-11), reads telegraphs, bursts and switches. Five means five usable roles. The trainer supports with **Tether Commands** (item throw, Rally, tag-switch combo, Tether Snare) on a meter filled by creature hits and **never deals damage** (RD-12). Hits must land with Palworld- and Monster-Hunter-class weight (RD-13).
4. **Prepare at home, then push the route.** The homestead turns what you gather into creature power: the Forge refines, the Kitchen cooks feasts, the Altar levels and teaches. A portal key opens the next arch; waystones and forward camps shorten the way back out. Gathering and building exist because those outcomes are useful; chores without a payoff are not depth.
5. **A finite world with visible consequences.** Distinct regions culminate in memorable fights. Machines stop, currents return, people come back and the actual team comes home. The ending pays off this campaign; the fifth arch *stirs* as a quiet promise, not a cliffhanger (RD-22).

**The loop (15–30 minutes, repeated):** pick a goal (a Master, a material, a bounty, the next boss); portal to your last waystone; fight, catch and release, gather nodes and shed drops, tick research; when the bag is full or the team is tired, tap the Home Key; refine, cook, spend essence, swap loadouts, teach a seed, plant type crops; portal back out. There must be scenic breathing room; neither uninterrupted battle traffic nor forward-stick travel through decorative terrain satisfies the loop.

## 3. Hard rules

**Retained:** Godot/Windows/ROG Ally/controller first; five owned total with no box, reserve, sixth or loaner loophole; the human never deals damage; creature combat is real-time and directly piloted; no shield/block/held-button gameplay (Fly may use held input); catching only during wild combat, never trainer-owned creatures; starters exclusive; freed legendaries volunteer, one offer per fight participant; no hunting, butchering, base jobs, automation or factory economy; light satiety without starvation death; stack/slot inventory without carry weight; multiple persistent death satchels; creatures taller than the 1.80 m trainer, fixed by growing the smaller side; reference-backed art with agent-drafted references and the held Meshy license; reuse of the installed humanoid cast; oxblood/red reserved for Team Tether; all new gameplay multiplayer-native. AGENTS/CLAUDE hold the operational form. ART_DIRECTION preserves earlier accepted assets and exception history; installed assets and references are not proof of redistribution clearance.

**Changed by the owner (2026-09-29):**

| Former rule | Now |
|---|---|
| Eight good hours, no grind or padding | 15–25 h normal clear; a grind loop that is optional but rewarding (RD-01). |
| Human never fights | Retained; the trainer supports with Tether Commands and deals no damage (RD-12). |
| No automation | Retained and sharpened: nothing produces while the player is away; crops, smelting and cooking need the player's interaction (RD-16). |
| Migrate legacy saves without loss | One-time reset: v27-and-older saves are refused with a clear message and never overwritten; migration discipline resumes after (RD-35). |
| No roster expansion | One exception: the storm bear Staticub evolves into (working name *Stormursa*, RD-28). |
| No unattended Meshy batches | One bounded, agent-attended overnight batch of about 25–30 named priority assets, capped at 30 generations per night, each judged and provenance-logged (RD-26). |
| No enemy scaling tier after the ending | Rematches at the next biome's level; leaders return at L55–60 after credits (RD-31). |
| No fifth-chapter tease | The fifth key makes the fifth arch stir but not open (RD-22). |
| Compatibility renderer | Still the default; a Forward+ path with Low (Compatibility)/Medium/High presets becomes default only after the owner's ROG Ally test (RD-25). |
| Starters do not evolve | Retained (RD-28). |

## 4. World canon

Eight legendary forces are conduits that maintain artificial **Tether Rifts**. Team Tether controls those conduits and thereby movement, trade, knowledge and migration. Its doctrine is that separation prevents catastrophe, and some of that warning may be true. The faction is a system of occupation and dependence, not only rude trainers on roads.

**Grandpa and the village.** The player starts at Grandpa's farm, the homestead plot at the head of one straight village road inside the Meadows. Eight to ten lived-in houses line both sides, and the stone **Crossing Hall** caps the far end, visible from the farm door (RD-29). Grandpa, a former trainer who cannot make this journey, gives the player a named starter, a patch of land and the **Home Key**. The village tournament remains the first proof of caring for a team.

**The Crossing Hall and portals.** The Hall's nave holds the home arch and seven portal arches: Tidewake, Cloudreach and Stormwood live, four sealed for biomes 5–8 (RD-17). The physical crossings between biomes are retired; portals are the only realm path. Each boss drops the next **portal key as a real item**, used once on its arch; a portal sends the player to their last activated **waystone** in that biome (3–5 per biome, activated by touch; RD-19, RD-20). Portal signs show a recommended level; the key is the only hard gate (RD-10).

**Grandpa's Home Key** is personal, free and has no cooldown. One tap raises it (~2 s of light, not a hold) and the player arrives at the home arch. It is refused in combat, dialogue, cutscenes, while swimming and mid-flight, and cannot be dropped, sold, traded or lost in a satchel (RD-18).

**The relic shrine.** The Hall's Shrine Room has eight pedestals. Hanging a biome's relic is required; it unlocks the next tier's homestead attachment recipes (Meadows attachments are available from the start, so each boss is fought with its own biome's gear), and the player then carries one chosen relic power (the existing one-active rule; RD-20).

**Masters.** Five named Masters from the installed humanoid cast each hold one level tier (L10, L20, L30, L40, L50). The player wins a 1v1 with a creature of their choice; the Master's chest teaches that tier's **Ascension Feast** once per character; losses are retryable. The feast needs the tier's biome materials plus one type-attuned ingredient matching the creature, and breaks its cap (RD-06, RD-07, RD-08).

**Starters.** Terrapup, Ripplet and Galewisp are exclusive to the player's choice and **do not evolve** (RD-28). Terrapup rides from the Meadows. **Ripplet swims** as a surface mount from Tidewake's opening and gains **Dive** at its L30 breakthrough; its former Teleport promise is dropped because the Home Key does fast travel, and every required water route stays human-swimmable (RD-32). Galewisp flies in Cloudreach. **Evolution** is optional and happens at breakthrough feasts on four lines, one per biome: Mudsnout → Tuskroot or Ashtusk (L20), Mosshell → Cannonback (L30), Craghorn → Stormcapra (L40), Staticub → the storm bear (L50) (RD-28).

Warden Aldis believes he is preventing a worse disaster and warns rather than recants. The chapter leaders differ in method and territory but serve one regional supply network. Reconnection is difficult and worth choosing.

**Legendaries** are freed and **volunteer**; they are never weakened for capture. All four chapters free one: Veridian (Meadows), the Abyssal Guardian (Tidewake), Solmane after Veyra (Cloudreach, owner 2026-09-27) and Stormwood's legendary. Every participant in the freeing fight gets their own once-only offer; a chapter completes whether they accept or refuse. Relics are reusable with one personal power active. Neither a relic nor a refusal is a hidden loss condition.

**The fifth arch.** The Stormwood finale drops a **fifth portal key**. Using it makes the fifth arch *stir* (glow, low hum, one line: not ready yet) but not open: no quest, marker, cliffhanger or sequel prompt. This explicitly supersedes the former "no fifth-chapter tease" line (RD-22).

Out of scope for this pass: content for biomes 5–8 (only reserved slots), simulated continental rearrangement, systemic migrating populations, branching moral alignment, trainer damage, romance and any cliffhanger the four-chapter story needs to resolve.

## 5. The four chapters

| Chapter | Player experience | Culmination and consequence | Grounding (STATE owns current status) |
|---|---|---|---|
| 1 · The Meadows (team 3→22) | Leave the village road, prove readiness, cross grassland, quarry and river, ride into high pasture; meet the L10 and L20 Masters. | Break relays, free captives, defeat Aldis (~21–22), free Veridian; Heart of the Meadows relic and the Tidewake portal key. | **Partial:** continuous world, band configs, trainers, wilds, stronghold/ceremony code. Hub road, Hall and key hand-off are targets (F17–F19). |
| 2 · Tidewake (20→33) | Read currents across 12 islands; swim, ride Ripplet, open shortcuts; the L30 Master waits on an outer island. | Venn, Tidecoil, Nerissa (~32–33)/Veilfall and the Abyssal Guardian; restored currents, the dock exchange as the chapter close; Tideglass relic and Cloudreach key. | **Partial:** built as chapter four at L43–55 with credits after the dock exchange (card T3). Re-levelling, no-Fly gate scan and moving credits are targets (F19, F20). |
| 3 · Cloudreach Cliffs (31→44) | Follow wind roads through six vertical regions; learn Fly; the L40 Master sits on a high perch. | Veyra (~43–44) and the aviary; free Solmane; Wings relic and Stormwood key. | **Partial:** configs, scene, trainers and finale consumers; card C1 and Solmane's per-participant offer proven; re-levelling targeted (F19). |
| 4 · The Stormwood (42→55) | Travel beneath the Long Storm, read grounded clearings and rods; the L50 Master waits deep in the storm. | Dynamo, Stormheart and the finale (~54–55); Spark relic and the fifth key; the Home Key homecoming. | **Partial:** world scripts, trainers, wilds and Dynamo exist; earned play unproven; ending relocation targeted (F20). |

Wild ranges and named teams follow PROGRESSION (RD-10; F19#1). Detailed maps, activities and fights are in WORLD and BOSSES. The 15–25 h target is measured on an agent-piloted normal route and confirmed by the owner's play pass (F47#0); geography is not shrunk or padded to meet it. Keep 6–10 meaningful optional activities per chapter and at least one per principal region.

### The ending we will build

Tidewake's dock exchange stays as Tidewake's chapter resolution and no longer rolls credits. After the Stormwood finale the player **uses the Home Key** and walks into Grandpa's homecoming at the farm. Grandpa acknowledges the current five by their actual names, the starter if still owned, one bond or victory memory and chapter choices; nothing is fabricated, and a released starter is acknowledged without guilt. Credits roll once per character. Control returns to a safe completed world with the repeatables: three bounties each morning, trainer/captain/Master rematches, alpha respawns with fresh traits and research completion (RD-22, RD-31; F20, F43–F45).

**Baseline:** the homecoming and credits are built after Tidewake (card T3 passed). Moving them after Stormwood and the fifth-arch stir are targets (F20). WORLD re-frames which link of the supply network each finale closes.

## 6. Systems earn their place

| System | Role | Status and owner |
|---|---|---|
| Combat/catching | Pilot embodied roles; take a risk to recruit. | **Partial:** quick/charged, Wind, burst, poise, throw/switch. Impact, patterns, anti-mash, fight camera are targets (F21, F22). COMBAT. |
| Moves and effects | Three slots plus ultimate, learnsets, TMs, mastery 1–5; ~24 effect archetypes with real objects; unique ultimates for starters, legendaries and evolved forms. | **Not built (target):** F23, F25, F35 (RD-11, RD-23, RD-27). COMBAT/CREATURES. |
| Tether Commands | Trainer support on a meter; no damage. | **Not built (target):** F24 (RD-12). COMBAT/UX. |
| Essence and breakthroughs | Eight type essences plus Tether Candy spent at the Altar; reduced auto-XP; caps every ten levels (ceiling 60, data to 100); Masters and feasts. | **Not built (target):** F27, F28 (RD-03..RD-08). Current source has XP levelling to 100. TRAINING/PROGRESSION. |
| Evolution and traits | Optional breakthrough evolution; 0–3 rolled traits, Trait Seeds, slots at L10/L30/L50. | **Partial:** evolution and bond-trait code exist (Mudsnout L15+bond); lines, traits and seeds are targets (F29, F30). TRAINING/CREATURES. |
| Homestead and gear | Six stations; Forge, Kitchen, Altar and Den take one attachment per biome; Harness and Charm tiers; trainer gear against real hazards; forward camps. | **Partial:** home/camp build pieces exist; stations, attachments, gear and camps are targets (F31, F33, F34). HOMESTEAD/SYSTEMS. |
| Gathering and materials | Tier materials, attuned essence nodes, type crops, shed drops (never butchering). | **Partial:** harvest/craft/catalogue/save paths built; tiers, nodes and crops targeted (F32). HOMESTEAD/SYSTEMS. |
| Care/bond | Recover for journeys; earn individual milestones. | **Partial:** beds, nourishment, happiness, unordered bond. CREATURES/SYSTEMS. |
| Hub and travel | Crossing Hall, Home Key, portal keys, waystones, shrine. | **Not built (target):** F17, F18. Physical realm gates are built and retire. WORLD/UX. |
| Traversal/weather | Change how each chapter is read. | **Partial:** riding, Fly, swimming, Stormwood systems; Ripplet swim/Dive targeted (F37). WORLD/SYSTEMS. |
| Repeatables | Bounties, rematches, alpha respawns, research log. | **Not built (target):** F43–F45 (RD-31). WORLD/BOSSES/PROGRESSION. |
| Co-op | Friends share a world with durable personal teams. | **Partial:** transport/authority/save infrastructure; the new loop is F48. MULTIPLAYER. |
| Presentation | Palworld/Animo-class creatures and world with Valheim-class light (RD-24). | **Partial:** art, shadows and synthesized cues exist; renderer presets and the full bar are targets (F26, F36, F38–F42). ART_DIRECTION/AUDIO/UX. |

**Shared-play canon (MULTIPLAYER owns detail).** The host is authoritative. Portal keys, relics, legendary offers and Master recipes go to every participant, once per character. A portal opens for the session when the host world or your own character has unlocked it. Station buildings are world-owned; station tiers, recipes, essence, gear, Home Key, bounties and research are personal and travel with the character, so a guest crafts at the host's tier and keeps the result. Release payouts, spends, feasts, key uses and relic hangs are transactions that neither duplicate nor vanish through reconnect or reload (RD-21; F48).

The homestead is the engine of creature power, not a colony: no workers, automation, factory or offline production. Five-owned pressure still differs structurally from Palworld's mass collection and labor loop. We win only if piloting, the growth of a remembered five and authored journeys beat the chores they replace.

## 7. Explicit disagreements and scope control

**Superseded (owner, 2026-09-29, RD-01, RD-02):** the first grilling's "eight good hours, no padding to twelve" and the lean, no-grind direction are replaced by the 15–25 h clear with an optional-but-rewarding grind loop and creature power as the spine. The former framing that building "is not a rival to Valheim's construction game" and that the product need only differ from Palworld is replaced by a Palworld/Animo- and Valheim-class target for look and loop appeal (RD-24); **no factory, automation, workers or butchering** remains a hard rule. Still in force from that interview: keep mechanics checks brief, regard an unchanged beloved team as success, use coding, existing tools and the held Meshy license without new investment, keep required co-op with invitation joining (no router setup), and grow toward eight biomes.

The redesign supersedes the Phase 1 and Phase 2 briefs (RD-34); still-valid F01–F15 rows fold into F16–F49 per `CODEX_START_HERE.md` §7.5. Superseded canon: the old order Meadows → Cloudreach → Stormwood → Tidewake, the Tidewake ending, physical interchapter crossings, Ripplet Teleport, one-quick-one-charged move sets, and Mudsnout's L15+bond evolution (now the L20 feast).

FINDINGS records every reviewed archive source and destination. Lower-level rewrite choices stand unless replaced above: bounded injury replaces stacked night/faint/revive pressure; unordered bond stays attainable for late catches; current 1.25/0.80 type multipliers stay; a L4 geometry skill is selected over the TM-only alternative, and new L4 skill, strain, bond and poise changes remain candidate solutions, not a prerequisite bundle; activities are budgeted per chapter; Galewisp Scout reveal and Ripplet catch-affinity stay out of minimum scope.

These are decisions for the plan, not evidence that code changed. No new spending or other hard-rule exception is implied. If a later instruction conflicts with a hard rule, state the exact requested change in STATE before implementation. Routine numbers may be tuned with evidence; pillars and chapter scope are not quietly rewritten by an implementation agent.
