# Product, positioning and release scope

## 1. The product bet

Sell a **creature expedition action RPG** with four authored chapters in this pass, solo or required 1–4-player co-op, Windows/ROG Ally first. Eight good hours are acceptable; measured quality and completion replace the old 12–16-hour floor. Future growth to the full eight biomes remains intended outside this pass. The pitch is **Five companions. A world worth reconnecting.** The product is the journey with the team, not owning everything that exists. Keeping the same beloved five through the ending is success; later exploration primarily pays with moves, role development, traversal and world consequences.

**Status:** substantial playable code, not a launch-ready product. `project.godot`, four world scenes, species/band/biome data and network/save code prove foundations. Commercial targets, final store claims and schedule below are **plans**, not achieved sales, certification or completion. Main's status update a49783a3d preserves the earlier owner direction, "personal / friends — I just want it good." The later request for CEO positioning supports the proposal below but does not authorize a commercial release or spending. Build the approved game and invite co-op now; sales targets do not gate useful private play. Eventual publication remains an owner decision.

## 2. Who chooses it

Primary player: someone who names a small RPG party, likes approachable action combat, explores for consequential rewards, and wants a campaign to finish with a partner or friends. Secondary: a Valheim player who enjoys preparations and expeditions but wants less survival maintenance; a creature fan who values a few companions over a complete collection.

A Palworld player will notice fewer economic and collection possibilities immediately. A Valheim player will notice shallow construction and weak survival stakes. Do not hide these differences with survival-crafting positioning. Our proposed advantage is direct creature control, remembered individuals, authored route/fight payoffs and a completed story at manageable length. This is unproven; generic fights and repetitive creature models would invalidate it.

The official [Palworld store description](https://store.steampowered.com/app/1623730/Palworld/) emphasizes collecting and using creatures across combat, farming and work. The [Valheim store description](https://store.steampowered.com/app/892970/Valheim/) emphasizes procedural exploration, survival, crafting and construction. These are competitive expectations, not a demand to copy their scope. Do not promise their replay hours or building breadth.

**Not the target:** completionist collectors requiring storage/breeding; factory optimizers; hardcore survival players; competitive PvP players; players expecting an enormous seamless multiplayer service. Losing those audiences is a positioning consequence, not a marketing problem to solve with misleading tags.

## 3. Store page copy

This is intended **launch** copy. Publish claims only after ACCEPTANCE verifies them. Development material labels in-progress scenes and omits unsupported promises.

**Short description**

Choose five companions and lead them across a divided world. Take direct control in real-time creature battles, build camps for the road, and reconnect four handcrafted regions in a complete adventure for one to four players.

**About this game**

Your grandfather can no longer make the journey. You can.

Leave home with a creature you name and a place for four more. Team Tether has locked the roads between regions and bound their legendary guardians. To reopen the world, you will need a team you know, supplies for the next stretch and the courage to take the longer path.

**Become your companion in battle.** Pilot your active creature directly. Read an attack, step out of danger, set up a charged strike and switch to the companion whose style fits the fight. Your trainer gathers and cares; your creatures do the fighting.

**Choose your five.** Meet creatures across grassland, high cliffs, storm forests and open water. Teach moves, earn bonds and carry your companions to the end. Keep a team you love or make room when a newcomer belongs with you. There is no reserve box waiting at home.

**Make camp. Move on.** Gather what you need, build a place to recover and prepare for the next expedition. Food offers help without starvation. Ride, fly and cross the currents as your journey opens new ways through the world.

**Reconnect a world with friends.** Explore four authored chapters alone or with up to three friends. Break Team Tether's regional hold, see routes and people change, and bring your companions home at the end of a complete campaign.

**Campaign:** four authored chapters and a complete regional ending, with optional exploration and team experimentation. Publish a duration only after ordinary first-clear measurement; eight good hours are acceptable. **Launch co-op lets up to three Steam friends join by invite without entering an IP address or configuring a router. LAN/direct IP remains a fallback. No PvP, public matchmaking, factory automation or creature storage.** Publish this connectivity claim only after the target integration and outside-network acceptance pass.

Suggested tags, checked against platform taxonomy at publication: Action RPG, Creature Collector, Adventure, Co-op, Exploration, Third Person, Controller. The collector tag needs the five-owned disclosure. Do not lead with Open World Survival Craft.

## 4. Platform, price and distribution

**Decision:** one Windows x86_64 Steam release, English text, full controller support, offline solo and required 1–4-player host/client co-op with Steam friend invite joining that needs no typed address or router configuration. The built ENet LAN/direct-IP path remains a fallback. ROG Ally is a required tested Windows device, not an assumption from controller support. Linux remains a development/headless target; no advertised Linux/Steam Deck/native console support until separately budgeted and verified. No cross-play, cross-save service, Tetherbound account service, split screen, public matchmaking, PvP, dedicated-server product or host migration at minimum launch.

**Proposed price: US$19.99**, with platform regional pricing reviewed at submission. This is a positioning decision, not a current comparable-price claim. No paid progression, cosmetics shop or preorder financing. The eight-biome ambition is future scope, with no paid expansion schedule promised. Target a complete 1.0 release; a public Meadows demo can test demand after the chapter passes. Do not use Early Access to sell a missing replacement loop.

Store/video production uses existing tools after the brief expedition check and representative visual pass. Trailer target 60–90 seconds: creature piloting first 10s; five-team decision; camp-to-route payoff; later-biome glimpses; regional stakes/co-op. No cinematic implies unavailable art quality or an absent ordinary-play mechanic. Screenshots use actual camera/materials.

**Connectivity target, not current implementation:** retain the built ENet LAN/direct-IP model (MULTIPLAYER/D95), then add a controller-first Steam friend/lobby invite path using Steam networking/relay so an ordinary friend can host and join across networks without seeing an IP address or changing router settings. Steam's official documentation supports lobby invites and peer networking that relays through Valve when appropriate; GodotSteam documents a Steam-ID-based `MultiplayerPeer` compatible with Godot's high-level multiplayer model. This selects the platform-native direction for implementation, not a claim that it is integrated or accepted. Sources: [Valve Steam Networking](https://partner.steamgames.com/doc/features/multiplayer/networking), [Valve lobby invites](https://partner.steamgames.com/doc/api/ISteamMatchmaking), [GodotSteam MultiplayerPeer](https://godotsteam.com/tutorials/multiplayer_peer/).

The launch flow is `Host for Friends` → friends-only lobby → Steam invite/Join Game → portable-character selection → version/capacity handshake → host snapshot → play. It must work by controller on Windows/ROG Ally, with the game already running or launched from the invite. Full lobby, version/content mismatch, Steam unavailable, host gone, connection failure and snapshot timeout each get a specific recovery message without creating or overwriting a save. Rejoin preserves the same portable character and reconciles the host world. Host exit saves the host-owned world, preserves committed portable characters, closes the lobby and returns peers to title; there is no migration. Public lobby browsing/quick play and a new account service remain outside the product.

This direction assumes existing Steam platform facilities and an open-source integration, with no new paid relay/account/matchmaking service or purchase authorized. The repository currently contains no Steam integration. The Tetherbound Steam AppID, Steamworks partner access/credentials, separate-account test entitlements, compatible GodotSteam version and matching Godot 4.7 Windows export artifacts are unresolved launch dependencies; credentials stay outside source control. If the prerequisites cannot be provided, the product has a release blocker requiring an owner decision—ENet port forwarding does not meet the confirmed launch experience. Official-source status checked 2026-09-19; implementation must recheck pinned versions and packaging before claiming support.

## 5. Success in numbers

These are **management thresholds and planning assumptions**, not a sales forecast:

| Stage | Continue signal | Failure response |
|---|---|---|
| First expedition | One brief 15–30-minute agent-piloted check of the existing loop: readable fight, meaningful team choice and useful detour/preparation. Actual desire to continue is unmeasured without people. | Fix the observed blocker or select one justified mechanic; no new cohort or harness programme. |
| Complete Meadows | Earned route without a duration floor or blocker/coerced grind; two independently judged visual subject/domain improvements visible in motion. A 4/5 human desire-to-continue result is optional research, not an automatic-build claim. | Fix pacing/combat/payoffs or stop rather than add biomes. |
| Public demo | After 200 qualified completions: 60% of survey respondents want next chapter; report response rate/self-selection. 2,000 wishlists as an organic reach target; no paid promotion budget assumed. | Investigate friction/positioning; neither number alone validates demand. |
| Launch quality | Five fresh agent-piloted solo campaign clears and two four-peer clears without blocker on the candidate package; reported measured duration, with eight good hours acceptable. A 4/5 human recommendation result is optional research and stays unmeasured until run. | Delay; a finite campaign must finish reliably. |
| First year | 10,000 paid units modest commercial success target; 25,000 strong; below 2,000 triggers review of expansion timing without silently cancelling the owner's eight-biome direction. Target 80% positive once 100 public reviews exist. | Maintain paid-product reliability; reconsider further scope. |

**Owner resource constraint:** no new investment assumed. Production uses coding, existing assets/tools, the Steam platform facilities already required by the Windows release and the already-held Meshy license. Selecting Steam friends/lobbies/networking does not authorize a platform fee, third-party service or other purchase; unresolved Steam access/AppID prerequisites are dependencies to surface, not costs to incur. The earlier $15k–35k commissioning envelope, $40/hour owner valuation and illustrative break-even scenario are withdrawn; they were agent assumptions, not owner commitments. Do not commission art/audio or infer paid promotion. The owner authorizes agents to draft reference art and use the held Meshy license for scoped current-roster/hero-asset improvements without another permission turn; ART_DIRECTION owns the remaining identity, provenance, validation and no-new-purchase limits. Actual platform/distribution prerequisites remain to be checked without authorizing a purchase.

## 6. Minimum release and cut order

Minimum saleable version: all four chapters, resolved regional story/homecoming, five-owned model, meaningful piloted combat, viable care/camps, essential traversal, six meaningful optional activities per chapter, chapter-specific audio, and 1–4-player co-op with durable saves and accepted invite joining without IP/router setup. Save/input/device reliability and truthful art are not optional polish. The proposed L4 skill, strain and revised bond/poise are candidate solutions; they are not a mandatory pre-test feature bundle. Record retention or rejection in the owning spec after the brief check.

Cut in this order when the critical path slips:

1. Fishing, resource-survey/camp checklists, extra decorative lore pickups and optional tool variants. Already outside minimum; do not build them to satisfy an old archive list.
2. Activities above six per chapter, duplicate elite variants and redundant errands, preserving one useful detour per principal region and all reward classes in PROGRESSION.
3. Mechanical trait perks if they threaten balance/QA; retain individuality/flavor. Reduce bespoke vocal variants while retaining species-family signatures, readable feedback and four chapter palettes.
4. Decoration/build catalogue beyond current 12 essentials, cosmetics, post-credits challenges and additional localization. Never cut a mandatory camp/traversal component.
5. Promotion breadth or launch date. If combat, four chapters, co-op, ending, saves or readability cannot pass, delay or stop. A one-chapter sale is a different product needing an explicit decision.

Current 57 species/12 adapters are existing content, not a requirement to commission 57 new meshes. ART_DIRECTION prioritizes hero subjects and coherent differentiation; more species are out of scope. No cut invalidates owned creatures, promised starter capabilities or required routes.

## 7. Failure case

Most likely failure: competent technology with interchangeable fights and rewards. Next: art that cannot sell its creatures, then production time spent on distant scenery before the first hour works. Co-op persistence can consume the schedule if left late. A finite campaign has little tolerance for a missing ending or filler hours.

ROADMAP buys evidence in that order. Accept narrower appeal openly. If someone says the fifth catch removed their reason to explore, show the move, route, encounter and companion decision replacing collection. If those are not enough in play, the central bet has failed.
