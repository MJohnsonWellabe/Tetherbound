# Tetherbound World and Chapter Contract

**Status:** Product contract. Built status is stated per feature; a design target is not completion evidence.

**Product:** A finite, authored creature expedition action RPG for one to four players, with co-op required for release. The four current chapters/biomes form the release campaign; around eight good hours is an acceptable clear and there is no minimum duration per chapter. Optional exploration, catching, team experiments, gathering and building can extend a run. The game is not an endless survival sandbox.

## 1. Player journey

The player leaves Grandpa's farmhouse with one named companion, builds a five-creature team, crosses four compact worlds and breaks a regional Team Tether supply network. Each chapter asks the player to prepare, travel, read terrain and creature behavior and defeat named gatekeepers. Meadows, Stormwood and Tidewake also free one captive legendary and ask whether the volunteer belongs among the five. Cloudreach restores its wind roads and earns Wings without inventing a captive or legendary offer.

The campaign order is fixed:

1. **The Meadows** — learn the expedition loop and break the Hall's regional occupation.
2. **Cloudreach Cliffs** — reconnect wind roads and learn Fly.
3. **The Stormwood** — relight Stormglass roads and end the Long Storm.
4. **Tidewake** — restore the archipelago's currents and close the regional supply network.

The four-chapter ending is complete in itself and is the current release pass. Eight legendary forces, eight Tether Rifts and an eventual eight-biome campaign remain later canon/scope; they do not add release work, require a fifth-chapter tease or weaken this ending.

## 2. Rules shared by every chapter

### 2.1 Authored geography

Roads, water, caves, settlements, gates, strongholds, landmarks, sightlines and regional entrances are placed deliberately. Procedural or rule-driven dressing supports those compositions. It does not decide the critical path.

Every chapter provides:

- A readable principal route with physical landmarks and an always-available next lead.
- Loops, far-side shortcuts, overlooks and optional pockets that make a finite map worth learning.
- A safe preparation point before a major commitment.
- Visible changes after local Team Tether machinery is disabled.
- **6–10 meaningful optional activities per chapter**, **24–40 total**, with at least one in every principal region. These remain release content, not prerequisites for the initial owner check or reasons to pad runtime.

An optional activity counts only when it has a discoverable lure, a distinct action or decision, a useful reward, acknowledgement, saved completion and a route that works through ordinary play. Pickups and spawn rows do not count individually.

The terrain envelopes are fixed. Density work may repair routes, leads and rewards; it may not shrink the Meadows or any later chapter to manufacture a shorter runtime. Use shortcuts and route edits to remove dead travel; do not add travel or encounters to manufacture runtime.

### 2.2 Gates, relics and chapter handoffs

Each chapter climax grants its relic. Chapters 1–3 also grant the world-owned key for the next realm; Tidewake closes the regional campaign and grants no fictional fifth key.

- The world-owned key is spent atomically once to open the next realm gate. The opened gate is reusable by the party.
- The personal relic is earned, physically placed at its shrine and remains reusable.
- Exactly one relic power is active at a time; selection persists.
- The next chapter is shown first as a distant, non-enterable view.

Relics are Heart of the Meadows (**2× max stamina**), Wings of Cloudreach/Skyborne (**0 Fly stamina cost**), Spark of the Stormwood/Livewire (**0.75 move-cooldown multiplier**) and Tideglass Compass/Tidal Guard (**0.90 incoming-damage multiplier**).

### 2.3 Legendary offer

When a chapter frees a legendary, that creature volunteers. The player never weakens it for capture and never throws an Orb at it. With fewer than five companions it may join directly. With five, the existing ceremony presents the volunteer beside the five companions' names and history and requires one permanent release or a refusal. Refusal completes the chapter. This contract applies to Meadows, Stormwood and Tidewake; Cloudreach has no offer.

In co-op there is one host-owned world offer and one stable-character recipient. Other participants share the world resolution and relic outcome; they do not receive copied legendary companions. The UI must say this before a player accepts the one claim.

### 2.4 Progression envelope

| Chapter | Intended entry | Intended exit / ace | Current authored basis |
|---|---:|---:|---|
| Meadows | 3 | 21 target; Warden ace 20 | Source curve 3→9→12→15→17→21; Warden 18/18/19/19/20 |
| Cloudreach | 18–21 overlap | 33 target; Veyra ace 34 | Trainer ladder 19–34; wild bands 18–33 |
| Stormwood | 33 | 44 | Region team curve 33→35→37→39→40→42→44 |
| Tidewake | 43 | 55 | Trainer ladder 43–55; Aquaryn49, Tidecoil54, Guardian55 |

The overlaps let a normal party enter without grind and still find optional challenge. The global creature level cap is **100**. No route uses a generic level wall where a person, creature, machine, current or physical gate can explain the boundary.

## 3. Chapter 1 — The Meadows

### 3.1 Geography and cadence

The authored envelope is x **−1024…1024**, z **−512…7680**, about **16.78 km²**. Its spine is **11,594 m** by the archived segment formula:

`96 Home + 2,384 Band 1 + 2,653 Band 2 + 2,372 Band 3 + 3,436 Band 4 + 651 approach`.

That equals 38.6 minutes at 5 m/s walking. The corrected sprint cycle is 8.33 seconds sprint plus 6.67 seconds recovery, about 7.0 m/s sustained and 27.6 minutes for the spine. These are route-length checks, not playtime claims.

The route includes ten named local loops, the quarry haul-road shortcut and the river ferry/reconnection. A meaningful sight, encounter or decision should occur every **150–250 m**; no 250 m route window should lack a beat within 40 m. Four authored camp-place decisions sit roughly three kilometres apart. Perimeter treatment must read as distant country, water, ridge or forest rather than an invisible wall.

The live Bible's 11,518 m value conflicts with the archived segment sum by 76 m. Re-measure the current spine before either value becomes acceptance truth.

### 3.2 Story route

**Home and village.** The opening cannot be skipped. Grandpa gives the starter choice, the player names the creature, learns a real fight and physical catch, and understands that the team is being built for a journey. The tournament is an eight-slot bracket with three player-played fights and four simulated entrants around the player. **Current source** requires a five-creature party, level 5 and care readiness, and `progression.json.home.required_pieces` asks for tent, campfire, bedroll and one creature bed. **Owner target:** three usable creature beds must be present before bracket entry; this deliberately exceeds the current one-bed source and needs implementation/economy reconciliation. The target order places the South Bridge grunt before Oskar's final, teaches the saddle recipe early enough to use it in the chapter, and lets Oskar's Meadowhart final demonstrate the mount payoff. Current source/probe order still completes the tournament before `south_bridge_grunt`, so that reordering is not built. A tournament loss heals the entered team and permits a clean retry without duplicating bracket rewards.

**Lower Meadows.** Broad readable grassland, local habitats, trainers and the first voluntary detours lead to the South Bridge. The bridge opens through story/trainer progression, never a floating level message.

**Stone & Root.** The Old Quarry and Burrow Warrens introduce Rootstone, stronger Ground creatures and the required compact dungeon. The L14 guardian controls the visible vault door; victory opens the Heartstone, Greater Orbs, Rootstone and useful equipment branch. Disabling later machinery can restore the quarry's live vegetation and fittings, but its baked colour/control-map scar cannot repaint at runtime. An aftermath NPC must explain that visible remainder instead of letting it read as a failed world change.

**River Lock.** A substantial river is a physical divider. Team Tether holds the Old Mill crossing and a captive. The route escalates pickets → Officer Dell → Captain Vance. Victory frees the captive, disables the relay and restores the crossing.

**Upper Meadows.** High pasture, old growth, ridges and Ironwood lead through three regional captains. Meadowhart and the saddle pay off riding. Oreth, Halder and Vess grant the three Sigils that physically open the Hall approach.

**Hall approach and stronghold.** The Hall grows in the view while hardware, drained land and patrols intensify. Band 5 is deliberately short and cannot be padded to extend the clock. Three basic road supplies support preparation, while the final waystop communicates the consecutive garrison and shows one last optional elder without providing healing. There is no ordinary recovery from the Sigil gate through the Outer Works except authored rare rewards; the bed after Hald remains the final legal recovery before Aldis. The interior sequence is Outer Works → Courtyard → Chamber Approach → Warden Arena → Legendary Chamber.

Warden Aldis believes separation prevents disaster; he warns and does not recant. Defeating his full five opens the tether. The player frees the Veridian Stag, resolves its voluntary offer, and watches the region heal. Team Tether recedes, rescued people return, and the Heart and existing Cloudreach key entitlement are awarded. The rift first holds, then dissipates across the storm-road carve while a physical bridge grows through it. This is the Meadows-to-Cloudreach return gate; it is not a Meadows portal or menu teleport.

If the Veridian offer is refused, the desired story disposition is an unengageable Stag among the healed Highfield herd. This remains an owner decision until implemented and accepted.

### 3.3 Band 1 visual contract

Village-to-bridge trail is approximately **2,421 m** and has five authored place beats: Gate Meadow, Rise, Pond, Long Field and Bridge. Each needs a reason to stop, a creature or gather subject and a distinct silhouette. The Pond remains the localized lush reference; its density does not spread across all open ground.

Composition uses a near rail at 3–10 m to one side, a subject at 15–80 m, a far mass at 150–600 m and horizon crossings in roughly 20–35% of the frame. The Rise is a controlled sightline window and the bridge reads as a grove gate. A representative route should not contain a roughly 60-second dead interval and should show creatures in at least three of five planned frames.

### 3.4 Built status

The five bands, stronghold, finale ceremony and aftermath are landed with broad automated coverage. Current data contains 31 trainer rows, 365 wild placement rows, 198 harvest nodes and 129 pickups. A fresh earned campaign and the player's voluntary-discovery/attachment experience remain unaccepted. Exact source: `data/config/bands/`, `data/config/stronghold.json`, `data/config/stronghold_climax.json`, `data/config/stronghold_occupation.json`, `scripts/world/stronghold_climax.gd` and the chapter reports.

## 4. Chapter 2 — Cloudreach Cliffs

### 4.1 Identity and topology

Cloudreach is bright, exposed and vertical: stacked cliffs, rope bridges, ruined waystations, shrines, bird perches, wind-cut plateaus, dangerous drops and broad horizons. It must not read as a flat Meadows corridor with cliff walls.

Its six regions are not six checkpoints:

1. Cloudreach Gate / Lower Cliffs — arrival, first settlement and vertical grammar.
2. Broken Causeways — shattered roads, route choice and visible inaccessible terrain.
3. Windscar Ravine — narrow traversal, wind hazards and Fly preparation.
4. High Roost / Sky Shrine — Fly-only pivot and relic destination.
5. Upper Cloudreach — broad elevated routes, late ecology, trainers and shortcuts.
6. Summit / Stronghold — a lattice aviary dome, central oculus, deliberate route throat, elite approach and Veyra's extraction engine.

Loops, alternate paths, overlooks, optional ledges, shortcuts and reconnecting roads are required. The sheer Fly-only destination must change how the map is understood.

### 4.2 Fly

Fly is a carrier glide. The trainer hangs visibly from a healthy active carrier. Maela's temporary loaner prevents a full non-flying team from deadlocking the chapter and never becomes owned. Second Jump launches; authored currents permit climb; elsewhere flight gradually descends. Collision, swept gate volumes, landing anchors, no-fly regions, save/load and host-validated remote landing still apply when Skyborne removes stamina cost.

Baseline tuning: launch cost 8, minimum launch stamina 18, glide 1/s, climb 1.6/s, maximum flight 180 seconds. There is no flat-ground infinite ascent or noclip travel.

### 4.3 Story route

Warden Aila receives the traveler while extraction has stalled the ancestral wind roads. Lieutenant Senn holds the broken causeway. Keeper Maela's Windscar trial teaches flight. Naturalist Sora and the settlements show ecological and civilian cost. Officer Voss controls the summit approach. Captain Veyra forces the wind through a summit engine.

The final encounter combines Veyra's three-creature team with a separate movement exam: pilot a creature through collapsing wind lanes and strike three exposed relays. Restored wind reconnects settlements and routes. Aila grants Wings, the Stormwood key and a Stormward overlook showing the non-enterable forest and distant water.

### 4.4 Content and status

Current data contains three acts, 17 act objectives, four side chains, 11 named NPCs, seven trainer encounters, 82 wild-site rows, 178 pickups, six resource types and 14 resource-node rows. The pickup mix is 100 candy, 75 recovery and three TMs.

Cloudreach has the strongest later-chapter continuous witness: 19,040.43 m, 3,795.33 simulated seconds, actual named combats, three bed recoveries, a production save and five retained companions. That witness also recorded very long no-action intervals, up to 885.87 seconds. Route cadence and visual acceptance remain open even where state progression passed.

Source: `data/config/cloudreach_chapter.json`, `data/config/cloudreach_world.json`, `data/config/cloudreach_encounters.json`, `data/config/cloudreach_finale.json`, corresponding `scripts/world/cloudreach_*` runtimes, `scripts/player/fly_controller.gd`, and the recovered Cloudreach integration evidence indexed as B04–B09 in `ralph/reports/PLAN-REWRITE/FINDINGS.md`.

## 5. Chapter 3 — The Stormwood

### 5.1 Identity and topology

The Stormwood is a deep old forest under the Long Storm. Giant trunks, glass-fused lightning scars, copper vines, black pools and moss-lit understory replace Cloudreach's open sky. Light comes from below. Team Tether's rod line drives lightning toward the Dynamo.

Envelope: about **4.5 × 6.0 km**, critical route about **6.5 km**, authored route target **≥12 km**, vertical range about **120 m**. Six regions:

1. Cinder Verge / Ashfoot.
2. Glowmoss Hollows / Lantern Pools.
3. Conductor Run / Rodline Post / Capacitor Grove.
4. Hollow Crown, reachable only by arch.
5. Deepwood / Lantern Hollow / Fallen Giant / Old Rodfolk Hall.
6. Dynamo outer works, core and legendary chamber.

The chapter requires at least four loops, three far-side shortcuts, five dead-end pockets and two alternate routes between consecutive regions after region 2. Every principal landmark must read from a neighboring region. These remain release constraints, not prerequisites for the initial owner check.

### 5.2 Surge and lightning

The Surge cycle is Calm 240 s → Building 90 s → Break 120 s → Fading 60 s. During Break, telegraphed strikes land every 4–8 seconds on exposed ground. Regions 1–2 use the gentler Calm multiplier 1.35. Camps with rods, settlements, Still Grove and Hollow Crown are safe. A disabled local rod multiplies Calm by 1.5 and Break by 0.6. After the finale, phase durations become 2400/45/45/60 seconds for Calm/Building/Break/Fading: the sky opens and Breaks become rare.

Lightning uses a 1.2-second ground telegraph and 3 m radius, damages humans and creatures without one-shotting a prepared target, and applies Static: half stamina regeneration for 8 seconds. Rod safe radius is 12 m. Sound/light must make each phase nameable without HUD text.

### 5.3 Stormglass Arches

Nine ancient arches comprise four fixed pairs and the Crown arch:

- A: Ashfoot ↔ Lantern Pools.
- B: Lantern Pools ↔ Rodline Post.
- C: Rodline Post ↔ Lantern Hollow after Rootgate.
- D: Old Rodfolk Hall ↔ Fallen Giant, optional.
- E: Crown arch ↔ mandatory player-built Still Grove twin.

Five sockets include one mandatory and four optional. The player may build at most three pairs. Relighting a fixed endpoint costs three ordinary Stormglass. The mandatory Still Grove footing costs **six Crown-grade Stormglass**, two Thunderwood Frames and four Conductor Vines; “Crown-grade” is an item identity, not a material grade numbered 6. A player-built pair receives one stable twin UID and commits payment/linkage atomically. Free-build waives material cost only; it does not waive legal footing, pair cap, gate, twin identity or persistence. Travel is walk-through, companion-aware, disabled in combat, realm-local and persistent.

### 5.4 Story route

The Rodfolk teach the Surge at Ashfoot. Hesk, Tamsin and the early rod line establish the cost of the Long Storm. Four stations and their outer works are disabled. The player builds the Still Grove twin, reaches the Hollow Crown, meets Archivist Wen, learns the truth and returns with the Heartstone to open Rootgate. Lantern Hollow, Kestrel and the upper Dynamo follow.

Captain Marrow's five-creature fight runs across four capacitor banks and three grounded plates. The lower platforms, hollow trunk, visible captive and route to the core must remain readable throughout the approach. At two creatures remaining the banks enter Overload. After the fifth falls, the player directly pilots a companion to strike four distinct conduits. The current implementation counts a full28-second four-bank cycle, not a single7-second bank serial. BOSSES replaces the phase-aligned deadline with an explicit30-second target window spanning bank cycles and a measured solo route budget. Timeout retries Break only; full party loss returns contributors to Ember Bivouac.

The containment opens and the Stormheart voluntarily offers companionship. Release awards Spark; its Lantern Hollow shrine explains the single-active choice. Returning to the high platform grants the Water key and Waterward view. The Long Storm ends, arches brighten and the forest enters a mostly calm storm season.

**New starter-utility target, not recovered implementation:** Ripplet's promised return/Teleport ability unlocks only after Stormwood is complete **and** the character has entered Tidewake. It may then recall its trainer to one personally attuned, previously used safe arch in the current realm after a visible 5-second channel, with a 120-second cooldown, out of combat and interrupted by movement or damage. This explicitly preserves the recovered decision that creature teleport is not introduced during Stormwood. It cannot reveal or bypass an unopened endpoint, and no source currently proves the destination/cooldown persistence.

### 5.5 Content and status

Contract floor: 16 landmarks and 330 wild clusters. The recovered floor allowed Hollow Crown only 12 clusters; the **selected target supersedes that exception** with at least 40 wild clusters in each of all six regions. Require 12 Calm/Surge tables with at least three roles in every table, six named wilds, 26 trainers, 18 NPCs plus the Crown resident, three inhabited settlements with 4/4/8 residents, six safe camps, ten rod clearings, 210 harvests, 24 charged nodes, 200–230 pickups with at least 80% off the principal path, 24–30 objectives, six side chains of at least three steps, four buildables, six resources and at least 12 recipes. Ordinary Hollow Crown opposition caps at L40; its named guardian may exceed that cap, and Captain Marrow's ace remains L44. These remain release constraints, not prerequisites for the initial owner check.

The four authored Stormwood TMs retain their source power bands: 1.15 quick, 1.30 charged and the two stronger authored values 1.60 and 2.00. They are chapter rewards, not permission to replace the global 1.25/0.80 type graph.

Current config contains six regions, 19 landmarks, nine top-level route records, 401 wild clusters, 12 tables, six named fights, 26 trainers, 19 characters, 229 pickups, 210 harvest sites and six side chains.

`scripts/world/stormwood_world.gd` mounts both `StormwoodDynamo` and `StormwoodEnding`. Focused Dynamo and ending tests pass, including host authority and Livewire consumption. Continuous ordinary play is proved only through the early chapter prefix into pair B; later acts and the entire chapter are not fresh-campaign accepted.

## 6. Chapter 4 — Tidewake

### 6.1 World shape

Tidewake is one authored realm of open water and twelve islands. Bounds are x **−1200…1900**, z **−500…4900**, y **−80…650**, sea level 0.

| Island | Centre / radius | Role |
|---|---|---|
| First Shore | (0,0), 180 m | Arrival, lesson, trader, camp |
| Reedhaven | (0,440), 180 m | Marsh settlement and pier repair |
| Brine Steps | (420,660), 190 m | Terraces and trainer demonstration |
| Shellwatch | (320,1120), 190 m | Occupied dock, rescue, first pump |
| Tidal Cradle | (700,1530), 260 m | Aquaryn and Swim Stone |
| Salt Crown | (150,2310), 260 m | Late settlement and shrine |
| Sluice Isle | (850,2960), 290 m | Pumps and final channel controls |
| Veilfall | (200,4140), 400 m | Mountain, stronghold and Guardian |
| Lantern Cove | (−350,170), 110 m | Optional early swim cache |
| Gull Rest | (−70,870), 100 m | Optional researcher branch |
| Drowned Garden | (1200,2240), 160 m | Optional mounted ruins |
| Deep Watch | (1350,3500), 150 m | Optional Tidecoil/current shortcut |

The first four exposed gaps were historically measured at **80.00 m, 104.13 m, 90.74 m and 109.02 m** across the early route samples. Those source measurements must be remeasured against the baked production shore before becoming current acceptance truth. Late gaps are 400–660 m. The chapter requires four land loops, three return shortcuts, eight reward pockets, at least 8 km land routes and 2 km water routes. Each of the eight main islands provides a camp at least 7 m inland from its legal landing. Shallows are slopes, beaches are landings and currents/cliffs explain every gate. Adjacent gentle beaches may not bypass a dock or story boundary. These remain release constraints, not prerequisites for the initial owner check.

### 6.2 Explicit exclusions

There are no boats, oxygen meter, diving, underwater building, thirst, fishing minigame, grappling or universal wetness punishment. These are scope boundaries, not backlog.

### 6.3 Swimming, mounts and currents

Human swimming uses land, human-swim, mounted-swim and combat-paused states. Baseline speed is 3.8 m/s, stamina drain 2.8/s and exhausted damage 4 HP/s. The Swimming skill reduces drain by 1.5% per level, capped at 35%. The archived floor was 15% reserve for a level-0 unfed swimmer. **The selected target supersedes it:** the first and every mandatory human-swim hop must leave at least **20%** reserve after a route sample that includes **15% steering deviation**. Combat pauses swim drain, regeneration and drowning until the host validates the outcome.

Mount stamina belongs to the creature and is separate from combat energy. Baselines:

| Compatible species | Swim speed | Capacity | Drain/s |
|---|---:|---:|---:|
| Aquaryn | 10.0 | 200 | 2.0 |
| Mosshell | 6.8 | 240 | 1.7 |
| Sirenseal | 8.5 | 180 | 2.0 |
| Riverdrake | 9.2 | 160 | 2.0 |
| Cannonback | 6.3 | 210 | 1.8 |

Mount exhaustion costs 3 HP/s. Tidecoil and the Guardian are never mounts. **Owner-retained-team override:** an owned swimmer is never mandatory on the critical path. The player can finish with the five they already love. Human-swim routes and safe shore anchors must satisfy the baseline reserve/steering bar above; swim mounts improve speed, convenience and marked optional routes. This supersedes the earlier mandatory-mount wording, not the five-creature cap, no-boats rule or current source state. Audit quest conditions and route anchors before claiming the unchanged-team path works. Current speeds are early 0.35–0.70 m/s, late 1.0–1.8 and hazardous 2.2. A mounted save/load must restore the same creature identity and remaining traversal stamina. If that lawful rider/mount state cannot be reconstructed, use the last validated shore/anchor and preserve the lower available resource state; the fallback may not refill either human or creature stamina.

### 6.4 Skills

The only global skills are Running, Catching, Riding, Swimming and Flying. Cap is 30; next level costs `100 + 30 × current level`. XP comes from real movement or a legal host-confirmed catch, never idle/menu time or fabricated history. Catching progress is portable character state; an old save with no receipt starts at 0 Catching XP. The host clamps the legal award; catch probability replicates only the resulting Catching level, not client-asserted XP, fractional progress or odds. Portable saves retain actual local progress. Skill Candy grants 1/2/3 levels, keeps fractional progress and refuses the whole consumption if any level would exceed cap. Twelve placements use a 7/4/1 tier split.

### 6.5 Story route and ending

**Broken Channels.** Dockkeeper Mara receives the group. Pell teaches the calm-water lesson. Reedhaven repairs its pier, Brine Steps asks for a trainer demonstration, and Shellwatch opens after its residents are freed and its pump disabled. Iona identifies the captive Guardian and the route forward.

**A Back Across the Sea.** L49 Aquaryn alternates Shore Crest, Tidal Run and Broken Wake. Catch or defeat resolves one shared encounter and awards eligible participants a personal Swim Stone. A catch journals the stable catcher identity and exact creature before confirming the shared result; it cannot insert a sixth creature or use a transient peer ID as ownership. Iona teaches the saddle recipe. Catching Aquaryn is never required to continue.

**Behind the Veil.** The party disables two Sluice controls, provisions at Lastlight and crosses to Veilfall. Officer Venn guards the climb. Inside, two ordered controls open the channel to Captain Nerissa. Her defeat permits release of the L55 Abyssal Guardian and the voluntary five-slot ceremony. Tideglass is earned for placement at the Meadows home circle; the currents return and NPC dialogue changes across the archipelago. L54 Tidecoil remains an optional deep-water apex.

**Regional conclusion.** Restored currents break Team Tether's regional supply monopoly. Docks reopen as civilian exchange points: Reedhaven, Shellwatch, Salt Crown and surviving Rodfolk/Cloudreach contacts can move people, medicine and ordinary goods without Tether permission. The result is shown through changed dock use, named NPC aftermath lines and a final shared departure, not an economy simulation.

The party returns through the reopened route to Grandpa's home. Grandpa acknowledges the specific five companions present, including a legendary only if that character actually accepted one. The final scene recognizes released companions without reversing the choice, confirms that this regional road is free, and rolls credits. The wider eight-force cosmology remains in existing lore; the homecoming has no post-credits sequel sting, invented count of unresolved forces or fifth-chapter prompt.

### 6.6 Content and status

Current data has 12 islands, six regions, 18 landmarks, four land loops, 12 land-route records, 22 water-route/current records, three shortcuts, eight pockets, 303 wild-site rows, 16 tables, five data-named encounters, 24 trainers, 18 NPCs, 182 harvest rows and 200 pickups. It has 12 main objective rows and no local objective chains. Six to ten chapter-level optional activities therefore require authored packaging of existing islands/fights/rewards rather than more scatter. This packaging remains release content, not a prerequisite for the initial owner check.

The recovered content target was 240 wild clusters, 16 tables, **six** data-named encounters, 24 trainers split 12 critical/12 optional, 18 NPCs, three settlements, eight camps, 160 harvests, 200 pickups with at least 80% off the principal route, 28–32 objectives, six side chains, at least 150 dialogue lines, five resources, ten recipes and ten current routes. These are provenance, not new release quotas. Current data has five existing data-named encounters; retain and differentiate them rather than add a sixth row for its own sake. Aquaryn already supplies a major optional-capture test and the non-combat Guardian offer remains distinct. The six local chains in §11 are candidates after the owner check, not prerequisites for the four-biome pass.

WaterChapter, Veilfall, Aquaryn, Nerissa, Guardian ceremony, relic award and restored-current state are landed and focused-tested. Continuous opening through Iona passed from a disclosed synthetic L44 party. The late one-creature diagnostic failed during Nerissa and proves neither normal difficulty nor a full ending. The regional epilogue, dock exchange consequences, return home, companion acknowledgement and credits are **designed here and not built**.

## 7. Multiplayer world behavior

One shared world can contain players in different realms. World changes, gates, docks, pumps, bosses, one-time pickups and legendary offers are host transactions. Character skills, party, portable inventory, personal unlocks, pose and per-creature traversal stamina travel with the character.

Mixed-realm simulation must not remove terrain, bosses or Veilfall state needed by another player. A gate spend and unlock is atomic. A disconnect during a boss, flight or crossing restores a saved safe state without granting progress. Late join reconstructs all chapter aftermath before enabling interaction.

The campaign requires 1–4 player smoke coverage, including two players on separate islands, host in another realm, simultaneous combat/traversal, competing gate/dock actions, legendary one-recipient settlement and reconnect during a crossing.

## 8. Visual and performance bar

The commercial art bar remains aspirational. Each chapter needs its own ground, vegetation, sky, structure and landmark hierarchy; creatures must read at gameplay camera distance and retain ground contact on slopes. Use the assets already in the project and the existing Meshy licence; this release plan authorizes no extra investment or commissioned art. Existing stand-in meshes and shared geometry limit silhouette quality. Configuration or a placement count is not visual acceptance.

Performance acceptance uses real hardware and representative chapter views with combat, creatures, weather and co-op present. Historical Cloudreach and terrain timings identify risk; they are not current budgets.

## 9. Out of scope

- New release biome, playable chapter or fifth-biome tease; the eventual eight-biome campaign is later scope.
- Terrain shrink or replacement with generated endless worlds.
- Human weapons or human-versus-creature combat.
- Creature storage, breeding, factory labor or automated production.
- Hunger escalation, thirst, cold, fatigue stacks or forced starvation.
- Boats, diving, fishing minigame, grappling or underwater construction.
- Copying one world legendary reward to every co-op participant.
- Claiming that data counts prove route quality, emotional attachment or commercial visuals.

## 10. Acceptance boundary

A chapter is **built** when source/configs mount its systems, **integrated** when its ordered state and rewards work together, **continuously earned** when ordinary actions traverse it without state injection, and **accepted** only after representative players understand the route, choose optional content, use recovery, read major fights and reach the intended aftermath.

Before expanding content or adding candidate mechanics, run one 15–30 minute owner expedition through existing systems. That check asks whether movement, route reading, catching, direct creature combat, switching, recovery and co-op already produce a compelling loop. It does not require L4 skills, Strain, revised bond, normalized poise or completion of the optional-activity ledger. Keep testing these mechanics to the minimum needed for that decision; do not create a repeated cohort or harness programme.

Release verification still requires the relevant target regression, network and save/reconnect tests, including a fresh earned four-chapter save and solo/co-op witnesses for the final route. Automated walkers may prove reachability and persistence. Owner observation is required for geography comprehension, five-companion attachment and the ending, but retaining the same beloved five for the full campaign is success and later catches remain optional.

Primary recovered provenance is indexed file by file in `ralph/reports/PLAN-REWRITE/FINDINGS.md` B01–B33 and its archive coverage table. Current implementation evidence lives under `data/config/`, `scripts/world/`, `scripts/combat/`, `scripts/player/` and `tests/`. Archive paths were sparse-excluded from this worktree, so the checked-in recovery index is the resolvable citation rather than a nonexistent local archive path.

## 11. Minimum optional-activity implementation ledger

This is the **selected release content**, not a claim that current rows already qualify as complete activities. It is not a prerequisite for the initial owner check. Prefer rewards that strengthen the retained five. Existing object/quest/defeat IDs retain their flags and reward receipts. New wrapper flags below are **target IDs, not built**; declare world completion and per-character reward scope before implementation. A wrapper cannot pay an item already awarded by its source pickup/quest. Claim existing pickups through their original receipt. These activities replace the inflated per-subregion quota and do not add a second quest engine.

Shared state: hidden → discovered (physical lure/NPC knowledge) → in progress → action complete → acknowledged/rewarded. No timers, repeatable payout or abandon penalty. Existing valid actions count even if done before the conversation. On failure retain discoveries and item claims, reset only the encounter/attempt. Every target has a3–10minute detour budget beyond its approach; a longer multi-region chain accrues while traveling the main route, not in a mandatory return trip. A reward blocked by full inventory stays pending at its original authority rather than disappearing. No optional objective gates the main story.

### Meadows — eight selected activities

Source foundations are the seven local rows in `data/progression/objectives.json`, band trainer/spawn/pickup records and `scripts/world/burrow_warrens.gd`. These are **partial activity foundations**: qualifying discoverability, useful reward and acknowledgement require ordinary-play evidence.

| Region / source identity | Lure and exact completion action | Target payoff / count boundary |
|---|---|---|
| Lower Meadows: Old Bram / `band1_old_champion` | Meet the champion in the eastern fields; win his two-creature fight. | Existing one-time trainer reward plus his Pond-alpha direction/map knowledge. Count fight once; alpha is separate only if player subsequently resolves it. |
| Lower Meadows: herd / `band1_meadowhart_herd` | Rae looks west toward the existing herd; approach the actual herd within12m with a companion, not merely finish Rae's greeting. | Personal landmark/bond visit and a plain saddle/traversal lead. Target moves completion off the current same-line greeting; no duplicate herd spawn. |
| Lower Meadows: cart / `band1_broken_cart` | Coll and damaged cart visible off bridge road; deliver the source item-gate cost once. | Existing repair reward and visibly repaired cart/usable approach. No new currency payout beyond source. |
| Stone & Root: Night Watch / `band2_night_watch` | Farro describes stirred Duskhush; meet him at night and win once. | Existing trainer reward, revealed Duskhush habitat and daylight acknowledgement. Waiting for night is optional; no main gate. |
| Stone & Root: Warrens branch | See the branch-vault light beyond the required guardian; take the optional Elder Trailpup branch and resolve its existing encounter. | Existing branch rewards/evolution catalyst access, never a second main-guardian credit. Keep each pickup's original claim. |
| River Lock: nest / `band3_river_nest` | Doss's blocked bank is visible from the river loop; pay current wood/fiber repair resolution once. | Restored bank access and existing reward. Target present it as clearing/rebuilding a bank perch, not a nonexistent hunting fight or playable fishing system. |
| Upper Meadows: lost companion / `band4_lost_creature` | Follow missing-Meadowhart lead; defeat the named Tether patrol. | Actual reunited NPC/creature presentation and existing reward; never award the rescued creature to the player. Ironwood's Juno→Halder story remains additional optional interpretation, not counted twice as main-Sigil victory. |
| Hall approach: off-road elder | Visible rare habitat/alpha pin at one existing band5off-road site; catch or defeat that existing alpha. | Current once-only alpha reward/possible team choice, map marker clears; no new road fight/cache/bed. This is the required band5detour and respects its short attrition corridor. |

The Pond alpha and Ironwood story can raise Meadows to10activities if their full qualification passes; neither is required to pad the floor. The current herd greeting alone and simple discovery counter do not qualify until the action/payoff above is integrated.

### Cloudreach — six selected activities

The four existing chain IDs/steps below come from `data/config/cloudreach_chapter.json::side_chains`; preserve their completed step flags. Two new activities use installed route landmarks and existing props, with no new mesh requirement.

| Region / identity | Action and resolution | Target useful payoff |
|---|---|---|
| Broken Causeways/High Roost: `three_bells_against_silence` | Find lower bell, ring Windscar bell, Fly to final High Perches bell; existing three-step order. | Audible route signals and moving travelers; reveal the three known safe landing points. No coin-for-each-bell loop. |
| Lower Cliffs/Windscar: `packs_on_the_wrong_side` | Recover west-ropeway pack, deliver medicine to ravine shelter, acknowledge Neri on next normal passage. | Two stranded couriers relocate to Galefoot; one eligible personal small-potion×2 reward, once, only if no equivalent source award already paid. |
| High Roost/Upper/Summit: `aeries_of_cloudreach` | Survey High Perches, Observatory updraft and hidden Waterward roost through actual Fly landings. | Three reusable landing/rest anchors and map knowledge. Rest anchor restores traversal stamina on safe landing only; not creature injury/HP. |
| Upper Cliffs: `the_cliff_circuit` | Existing lower pair, Windscar pair, then Tavi victory. | Team mark on board and one existing compatible TM choice from the chapter's three placed TM rewards, collected through its original source receipt. Archived rematch-tier promise is deliberately deferred; no repeatable trainer economy in minimum release. |
| Lower Cliffs: Waycamp shelter (new `side_waycamp_shelter_complete`) | Neri's canvas bundle points to an installed legal camp area; deliver4fiber and assign a companion to its existing bed once. | Repair that shelter's rain cover/presentation and one reusable camp/rest location. The4fiber cost is optional, not a required Fly gate; no extra terrain footprint. |
| Summit: Observatory return latch (new `side_observatory_latch_complete`) | An upper-route sightline shows the reverse side of an existing return route; reach it by earned Fly and tap the latch out of combat. | Open a far-side descent shortcut to the Observatory, saved world state; cannot reach Summit from below before the main route unlock. |

High Roost gets its useful optional payoff through bells/aeries; Summit gets both aerie and latch. A three-region chain counts once, but may satisfy regional coverage only where it has a real local action/payoff.

### Stormwood — six existing chains made concrete

Source: `data/config/stormwood_chapter.json::side_chains`; **partial**, with exact existing step flags and required count3for the Circuit. Preserve source rewards; additional target supplies below substitute for generic duplicate reward rows rather than stacking payouts.

| Chain / regional coverage | Exact actions | Target payoff and acknowledgement |
|---|---|---|
| `stormwood_dark_arches` / Ashfoot→Deepwood/Dynamo | Inspect remaining ancient arches; relight the optional Deepwood/Dynamo pairs with source costs; tell Hesk. | Those physical routes become reusable and visible on known map. Hesk describes reopened Rodfolk movement; no duplicate material reward. |
| `stormwood_pims_parcels` / Lantern Pools | Collect sealed parcels; deliver to three existing households on restored arch roads; return to Pim during normal passage. | Residents visibly receive supplies; two small potions per eligible character once. Delivery is three flags, not three new inventory items. |
| `stormwood_crown_remembers` / Hollow Crown | Read the three surviving records around grove, then speak to Wen. | Wen supplies the complete account and an already-authored Crown cache location; count the original cache reward once. No main Heartstone flag shortcut. |
| `stormwood_glass_for_bryn` / Conductor Run | Speak to Bryn; deliver3ordinary Stormglass+2Conductor Vine once; inspect repaired supplies at Rodline Post. | Existing rod shelter becomes a usable safe care point, with one creature bed. Does not duplicate the mandatory rod disable or its Calm multiplier. |
| `stormwood_raise_a_road` / optional footings including Deepwood | Select two legal optional footings, build/bind within the three-pair cap, use both directions, acknowledge Ondra. | Durable player-selected shortcut pair; no refunded construction cost or fourth pair. Travel itself is payoff; do not require this optional pair to finish story. |
| `stormwood_deepwood_circuit` / Deepwood | Accept Rook's circuit; defeat any3of its5named trainers; return to Rook. | Team acknowledgement and one authored Electric TM reward through existing entitlement/receipt; source-catalogue compatibility still applies. No infinite rematch tier. |

Dynamo optional coverage is the far-side Dark Arches endpoint reached before the final commitment. Its safe return route is the reward; do not put a new errand inside the active bank fight. Each principal region has a local payoff even where a chain crosses more than one.

### Tidewake — six new local chains using built places

**Not built as local chains:** `water_objectives.json::local` is empty. Foundations are `water_world.json` islands/pockets/return shortcuts, `water_characters.json` installed NPCs and existing pickup/camp/encounter consumers. These target wrappers supply the missing authored actions and consequences rather than another200scatter pickups. Each has three recorded steps; the Swim Stone/saddle reward route remains independent and cannot gate the human-swim critical path.

| Target chain / region | Three actions, lure and constraints | Payoff |
|---|---|---|
| `side_water_lantern_return` / First Shores | Pell points to Lantern Cove's visible rock arch; swim the optional legal route; claim `lantern_hidden_cache` and return to the First Shore landing. | Existing Skill CandyI pocket via original receipt; personal return-route knowledge and Pell acknowledgement. No extra candy. |
| `side_water_gull_research` / Marsh Channels | Adair names Gull Rest; reach researcher/satchel via safe optional crossing; return the recorded observations on next Brine Steps passage. | Existing `gull_research_satchel` Skill CandyII plus charted safe route. Satchel is quest flag; cannot be sold/lost as a second inventory object. |
| `side_water_cradle_care` / Tidal Cradle | Otto points to `cradle_shell_nest`; reach the dry nest and gather4Reef Stone; return to Otto with a legal owned swimmer or after declining Aquaryn. |4Reef Stone remain with player plus3berries, once, and explicit alternate-swimmer habitat/map lead. No requirement to catch Aquaryn or sixth-slot staging. |
| `side_water_garden_records` / Outer Reaches | Edda points to visible above-water Drowned Garden vault; reach via lawful mount route; bring the recorded wall account back to Salt Crown. | Existing `garden_exposed_vault` Skill CandyII and Edda explains pre-Tether dock history. No diving/oxygen and no generic chest-only conclusion. |
| `side_water_deep_watch_chart` / Tether Current | Orsen names Deep Watch; resolve optional Tidecoil by catch/defeat; operate the separate chart/return-current control. | Existing Skill CandyIII pocket plus source return-current shortcut; victory alone does not silently flip the chart flag. |
| `side_water_lastlight_shelter` / Veilfall exterior | Halen reveals a sheltered route beside Lastlight; deliver4Driftwood+4Reed Fibre to the existing legal camp; rest one assigned companion there before or after Venn. | One permanent shared sheltered creature-bed site and Halen acknowledgement. No access to interior before controls/Nerissa; resources placed on exterior side; optional cost must leave the resources needed for a saddle available to a player who chooses mounted travel. |

Additional pocket/alpha content is welcome up to10qualified activities per chapter, but does not take priority over these six, the ending or combat. Recipe and item identifiers must resolve through existing item databases at implementation; new wrapper state is explicitly named above, all geographic subjects already exist, and any unverified placement must be walked from its real approach before it is accepted.
