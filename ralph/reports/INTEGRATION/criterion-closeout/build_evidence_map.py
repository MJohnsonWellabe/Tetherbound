"""Build the exact acceptance evidence map; never changes the public board.

Descriptions below distinguish authored candidates from witnessed behavior.
The board provides historical IDs/text, not independent criterion verdicts.
"""
from __future__ import annotations

import collections
import hashlib
import json
import re
from source_audit import BASE, BOARD, OUT, PRIMARY, data, dump, paths, raw, source, stamp, warm


IMPLEMENTATION = {
"F16": [
"Schema28 refusal and title/picker explanation paths are implemented; baseline accepted old-save refusal does not certify later save producers.",
"Fourteen typed schemas/catalogues and validation/foreign-ID consumers are implemented; subsequent F23/F28/F31 fields must retain their declared contracts.",
"Eight-slot biome_order accessor supplies new order; later guarded realm handoffs are separate F19 behavior.",
"World, personal and creature carriers/flag scopes and transaction owners exist; new producer fields have since been composed into the combined candidate.",
"Title/NewGame/Grandpa entry source and v28 save pipeline exist; recorded baseline complete unit membership is historical and current full batch is not green."],
"F17": [
"Straight road/eight frontages, farm/start and Hall/end geometry and topology regression are implemented; baseline accepted plan/physical-path evidence recorded.",
"Hall/canopy/frontage presentation source has accepted historical destination day/night images; current layout/lighting relevance must be checked.",
"Hall generator builds home+seven signed arches and eight signed pedestals; historical sixteen controller approaches are recorded.",
"Eight houses have named/lived-in source and reachable service actors; historical controller approach proof does not certify a complete current Mira transaction.",
"Opening driver composes practice/tools/materials and optional full camp/readiness/tournament. Earlier Mira/terrain failures remain retained; newer582b actual Mira and three equipped gathers pass, then wholeCORE fails at Oskar. CORE does not prove full M1 chain.",
"Real ENet Hall producers and immutable agreement finalizer exist; historical accepted eight producer captures retain their failed whole-run transport limits.",
"Village/Hall visual sources exist, including installed-family frontage; no reviewed current full BarsA/B village/Hall matrix is available to this lane."],
"F18": [
"Authored Home Key gift and protected inventory category exist, with ownership/loss policy consumers; complete opening gift/protection witness remains required.",
"HomeKey actor implements tap/raise/transition/refusal policy; new travel runtime remains session-gated OFF in this pinned source.",
"Real portal-key items, portal escrow/delivery/action policy and retirement guard exist; ordinary key debit/unlock and portals-only route scan are not certified by compile.",
"Waystone catalogue and touch actor encode personal activated/last-return state and fallback entry; actual touch/reload/return path is unproved here.",
"Portal policy separates host-world and personal unlocks; Home Key travel uses personal actor identity; actual two-peer and cross-host portability proof is open.",
"Foundation travel and candidate loop producers exist; no completed ordinary deep-biome→HomeKey→paid station→portal/waystone saved route returned."],
"F19": [
"New order accessor/config and map/journal/credits consumers are authored; portal/boss/ending session producer gates remain OFF.",
"RD10 curve overlay authoring and exact-band tests exist; test_f19_curve explicitly checks inactive candidates separately from retained live legacy providers.",
"Per-character boss handoff and reward delivery source is composed; gate remains OFF and full multi-participant actual receipts are not a unit count.",
"Traversal gate/config data and retired physical crossing guards exist; no completed current gate-scan/native route certificate for every future-creature dependency supplied.",
"Veridian/Guardian/Solmane/Stormwood offer policies and current repairs exist; returned shared-boss/Stormheart witnesses cover bounded cases, not full four-realm space/capacity accept/refuse matrix.",
"Earned fixture directory and disk-handoff validator exist; new-boundary real saved generation/route ownership evidence remains open."],
"F20": [
"Dock exchange and guarded regional ending source separate new Tidewake chapter close from new Stormwood ending; retained legacy diagnostic flow is not redesigned ordinary completion.",
"HomeKey-triggered current-party homecoming/ending owner and once-only personal credits source exist; actual new-order finale/homecoming continuous path is unproved.",
"Fifth-key/arch stir policy and presentation source exist; no current native glow/sound/one-line/no-open/no-quest witness judged.",
"Completed-world/credits flags and repeatable services exist; named credits reload smokes are bounded diagnostics and do not prove activated redesigned continued play.",
"Personal homecoming/credits carriers use shared durable services; actual two-peer disconnect/reload once-only new ending proof is open."],
"F21": [
"HitFeedback/combat config, weighted hitstop/knockback/reaction/number adapters are composed; F21 runtime gate is OFF.",
"Feedback styles/cues encode ordinary/critical/effective/resisted distinctions; deterministic style tests do not certify visible/audible actual hit presentation.",
"Poise break/stagger/bonus-window source is composed; actual new-pipeline stagger timing and visible reaction remains unjudged.",
"Heavy feedback uses camera/rumble toggles and motion preferences; actual controller rumble/toggle witness and current shake capture remain open.",
"Production camera/body fitting contains size/framing repairs; old scoped unit/capture results do not supply current small/normal/giant code-blind matrix.",
"Matched impact/Medium frame-time capture infrastructure exists; no current after-preferred full-bar matched motion verdict supplied."],
"F22": [
"Four role families, pattern data and enemy attack publication/geometry adapters exist; patterns.runtime_enabled=false.",
"Reader/masher band pilot and smoke_f22_pattern_bands exist; publication and unit passes do not provide the required12+ seed distributions.",
"Tag-switch/type matchup and pilot comparison source exist; no current switching-vs-nonswitching numerical witness supplied.",
"Role catalogue and normal camera source exist; five distinct role judgments require source-blind fight footage.",
"Named profiles and repair source exist; pre448/450 timing results are stale; current full C2/C3 and distinct patterns/aftermath remain open."],
"F23": [
"Production creature fields/defaults, tap dispatch and four-slot HUD/input source exist; move-loadout runtime gate is OFF and actual controller fight proof remains open.",
"70 authored learnsets cover69 live species plus reserved bear, level/breakthrough gates and primary-type TM staging; native catalogue/TM consumer recheck requested.",
"Ten utility definitions and every live species' two or more choices cover four authored roles; native actual equip-policy staging requested, no ordinary station claim.",
"Altar/forward-camp loadout staging, carrier mirror/revisions and rejoin source exist; actual owned UI change+save+two-peer rejoin witness is not supplied.",
"MoveMastery stores bounded rank/use/receipt maps and effect growth; actual accepted uses→rank1..5 growth+durability required.",
"Landed-hit ultimate meter/host dispatch/HUD source is composed; actual hit filling/full-only fire/controller/HUD proof is open."],
"F24": [
"TetherCommands meter and four support-action paths are authored; host validation/actual producer boundaries require active gameplay proof.",
"Damage attribution/host accepted-hit adapters preserve creature ownership; no exhaustive current actual damage-event native proof is credited from source.",
"Tag combo window/joint-follow-up dispatch is authored; actual two-body timed attack proof is open.",
"Snare staging and wild-only target/refusal source exist; actual slow/catch-chance and trainer-owned refusal witness open.",
"Workbench gear/pouch/command growth data and consumers are composed; actual crafted tier effects require production proof.",
"Personal owner/actor binding and host policy exist; actual two-peer own-only commands and hostile payload refusal proof remains open."],
"F25": [
"24 authored effect bodies/trails/impacts/audio mappings and local render implementations exist; production move_library.enabled=false; content/audio/body existence is not active effect proof.",
"All94 pinned move rows map to24 archetypes with all8 declared parameters; independent detached unknown-ID negative check passes.",
"Native r14/r17 identity images/motion are retained, with original RED termination; full visual bar has not passed and this reviewer has not issued a code-blind subjective verdict.",
"Frozen arrival/original accepted receipt and contact cue adapters are composed; actual visible contact→HP/number/audio temporal ordering requires matched native observation.",
"Global particle/light budgets and Compatibility fallback source exist; actual worst-case four-creature Medium frame-time proof is not replaced by budget arithmetic.",
"Five mastery parameter tiers and geometry growth exist; current native visible size/count/trail rank comparison and full-bar verdict are open."],
"F26": [
"Forward+ material path and Compatibility Low are implemented with accepted historical material census proof; retained scope is materials, not full beauty/performance.",
"Low/Medium/High settings/toggles and persistence consumers are implemented with accepted historical pad/fresh-process proof.",
"ART_DIRECTION4.1 written biome look bars/reference boards exist; target documentation is an accepted static scope, not rendered attainment.",
"High/Medium matrix capture paths exist; no current full new-bar biome judgment supplied.",
"Twelve preset/biome desktop1920x1080 route records historically accepted; coverage does not certify frame-rate targets or current changed geometry relevance.",
"Forward+ default remains gated by owner ROG Ally run; desktop GTX captures do not constitute owner/device/default authorization."],
"F27": [
"Eight canonical essence items stack999; Tether Candy stack99; accepted historical static item cut.",
"Wild victory, release, nodes, crops, research and daily-care source adapters are composed; wild victory/Altar source gates remain OFF and every actual producer must be witnessed.",
"Configured auto_xp_scale=.35 and positive floor helper exist; progression source explicitly retains live legacy XP until earned-route activation; no reduced actual combat award claimed.",
"Altar chosen UID/type/Candy cap-aware spend source and current production consumer repair exist; actual paid own-creature station interaction/open cap proof open.",
"Durable release/spend intents and typed identity/replay rules exist; actual two-peer host/owner write/ACK cuts remain required.",
"Configured costs and route-ledger source exist; ordinary level-entry and optional grind speed ledgers have not been produced."],
"F28": [
"Masters/cap data holds10..60 live and70..100 reserved; breakthrough state and UI readouts exist; actual cap stop/required message proof open.",
"Five off-path Master sites/signs and placement source exist; normal input reachability/placement/Fly scope remains unproved here.",
"MasterDuel host challenge/select/loss retry/chest recipe source exists; actual chosen-creature1v1 and once-personal chest producer witness remains open.",
"Biome/type-attuned feast catalogues and Kitchen/feed staging exist; paid craft then actual feed/cap mutation must be proven atomically.",
"Personal recipe transactions and duel participant identity source exist; two real participants' independent once-only receipt proof open.",
"Feast material/ingredient authoring data exists; actual or independently sufficient reachable ingredient ledger per tier not returned."],
"F29": [
"Four biome source/target mappings are authored, including Mudsnout branch; Stormursa line is disabled pending actual bear proof.",
"Evolve/stay feast projection and per-tier choices are authored; actual paid feed choice/stay permanence is unproved.",
"Detached evolution projection preserves canonical history/identity and species-derived stats; actual feed/write failure/save/rejoin behavior is not a source assertion.",
"Bear readiness/provenance gates exist; no genuine accepted in-engine Meshy bear artifact in this evidence lane; remains flag-off.",
"Exact wild tables retain Cannonback/Water alias and three Cloudreach Stormcapra references, exclude Tuskroot/Ashtusk/Stormursa; provider-binding inspection underway."],
"F30": [
"Trait tiers/roll hooks and candidate probabilities exist; traits.runtime_enabled=false; actual wild alpha/night/weather distribution proof open.",
"Catch/inspect readout source exists; actual correct caught UID trait UI and readable capture required.",
"Altar chosen trait release/seed staging exists; actual caught individual release, debit/seed, failure/replay behavior remains open.",
"Breakthrough slot gates and paid essence teaching source exist; actual owned seed spend/slot denial/acceptance proof open.",
"Combat/traversal trait adapters and per-trait tests exist; inactive-runtime native checks are scoped regressions and do not certify each active effect."],
"F31": [
"Six station/Farm/chest buildable definitions and homestead geometry source exist; station build/craft/farm/den gates remain OFF.",
"Four upgradeable station families declare4 live/8 slots and attachment recipe gates; actual build/material debit/tier rejection remains unproved.",
"Tier1 defaults and next-tier personal relic-hang projections exist; actual shrine hang→attachment recipe unlock→one carried relic proof open.",
"StationNextUpgrade controller menu emits one target; actual readable single target/controller context proof open.",
"Present-player tap channels/tick bounds and manual farm/cook/refine plans exist; actual no-away/no-offline/no-replay production test required.",
"World building and personal craft/tier transaction scopes are composed; guest host-tier use/keep output/save/rejoin proof remains open.",
"Installed station objects/meshes/materials exist; normal-camera source-blind object distinction/full visual bar is unjudged."],
"F32": [
"F32 tier-material catalogue/runtime mount and resource source adapters are authored; f32_runtime gate is OFF, actual gather/yield per biome remains open.",
"Forge refinement recipes/service and paid producer repairs exist; actual Rootiron/Tidesteel/Skyglass/Stormglass plate receipts open.",
"EssenceNode catalogue/mount has type placements/yields/host timers; actual off-route access/contention/respawn proof open.",
"Eight crop/Greenhouse buildable and manual harvest rules exist; actual plant/growth/manual harvest/off-biome restriction proof open.",
"Shed drop/grooming source and non-butchery item vocabulary exist; actual victory/Den payout, repeat guards and lexical test needed.",
"Water crafting registration/proposal data and resource contention policy exist; actual registered ten proposals and four-character solvent contention proof open."],
"F33": [
"Harness/Charm tier/enhancement data and equip staging exist; gear runtime/network/visual flags are OFF.",
"CreatureGearAccent local trim/glow source exists; actual equipped normal-camera accent/full visual bar proof open.",
"Canonical gear damage modifiers and configured caps exist; actual per-boss matching-tier/prior-tier C2 simulation distributions open.",
"Hazard mitigation policy hooks exist; each actual fall/static/cold/drowning/current/terrain boundary requires named tests.",
"Tool pouch tiers, personal gear carriers and command growth consumers exist; actual paid gear/save/two-peer ownership proof open."],
"F34": [
"Workbench kit and forward-camp ground placement/bed/cookpot/bench source exist; runtime_enabled=false.",
"Travel-tier-only policy/refusal reason is covered by returned bounded unit contracts; active station refusals/allowed recipes require actual producer witness.",
"Rest/save/loadout contexts are authored; actual recover/save and edit path open.",
"Existing camp/readiness/rest-bonus source retained; opening/core still has physical route failure and no whole current camp regression certificate.",
"Host placement identity/world persistence and rejoin source exist; actual host plus guest placement/reload/rejoin remains open."],
"F35": [
"19 shared type×role signature move IDs and69 live species mappings authored; actual production spawn mapping native recheck requested.",
"Twelve named unique signature IDs/local choreography rows authored including reserved bear; F35 presentation enabled=false and actual unique executions unproved.",
"Breakthrough growth dimensions/layers authored; no current native visible milestone matrix accepted.",
"Configured2.4s presentations/budgets/peer opacity exist; actual control restoration and four-player readability/frame-time required.",
"Distinct unique choreography/source exists; every unique needs source-blind motion identification/full-bar verdict."],
"F36": [
"Priority-source audit/reference candidate inventory exists; no complete25..30 actual referenced Meshy/confirmed before-after pass set supplied.",
"Pose candidate/controller sources exist; every species hurt/faint/swim/fly/ride matrix remains required.",
"Scale census/body-fitting sources exist; current whole-species trainer/fight-scale native code-blind proof open.",
"Night guard and ledger cap30 exist; this actual ledger has zero submissions and empty tasks. Mock IDs/cap logic do not prove a completed attended priority generation batch."],
"F37": [
"Ripplet surface mount/current tuning and water host adapters exist; actual owned opening mount/swim speed/current witness remains open.",
"L30 completed breakthrough Dive guard and optional sunken site/route sources exist; actual lawful Dive/content access proof open.",
"Required human-swimmable route configuration is retained; actual current no-Ripplet hop/stamina steering matrix must be reused with dependency relevance or rerun.",
"Live contracts retire the old Teleport promise; scan of910 actual game files and Ripplet active definition finds no UI or active promise.",
"Stable mount UID/dive budget sanitiser and tests exist; JSON unit round trip is not actual save/reload/two-peer mounted rejoin."],
"F38": [
"Meadows/village visual candidate sources exist; no current after-F26>=200-frame recapture/rescore supplied.",
"Top20 fixes are partly historical/source-only; every current top20 item needs main landing and before/after full-bar code-blind PASS.",
"Impact>12 catalogue repair sources are incomplete/unjudged; exact current biome catalog membership and all passing judgments required.",
"High/Medium capture infrastructure exists; full approach/gameplay/reverse/detail/day/night/weather/real-fight new-bar matrix open.",
"Road/Hall hero landmark sources and historical destination captures exist; distance plus close current full-bar landmark proof open.",
"Material/body/collision repair sources exist; no inspected complete current matrix demonstrating absence of magenta placeholders/floating/clipping."],
"F39": [
"Tidewake shore/island candidate visual sources exist; no current after-F26>=200-frame recapture/rescore supplied.",
"Top20 Tidewake item sources/captures partly historical; full before/after main-landed code-blind pass set open.",
"Impact>12 Tidewake catalogue fixes are not all independently passed; remaining current-direction readability defect is retained.",
"High/Medium route captures exist historically; full current biome frame matrix/new-bar judgment open.",
"Veilfall hero geometry/lighting sources exist; current distance/detail full-bar native matrix judgment open.",
"Water/material/body repair source exists; no complete current matrix proving all placeholder/floating/clipping defects absent."],
"F40": [
"Cloudreach candidate skyline/waycamp/geometry sources exist; no current after-F26>=200-frame recapture/rescore supplied.",
"Top20 Cloudreach fixes partly authored/unjudged; every item still needs passing before/after and main proof.",
"Impact>12 Cloudreach repairs not all passed; flag-off occupied terrace/towers remain unaccepted.",
"High/Medium preset captures exist historically; full current approach/gameplay/reverse/detail/day/night/weather/real-fight new-bar matrix open.",
"Sky Aviary hero and restored route sources exist; actual distance/detail new-bar visual judgment open.",
"Material/skyline/pose repair candidates exist; no complete current frame matrix certifies zero placeholder/floating/clipping residue."],
"F41": [
"Stormwood tree/scar/dressing candidates exist; no current after-F26>=200-frame recapture/rescore supplied.",
"Top20 Stormwood sources/captures partly repaired; required full before/after main code-blind pass set open.",
"Impact>12 Stormwood items remain open, including scars/tree/catalogue defects; optional scars unjudged/flag-off.",
"High/Medium historical captures and finish sources exist; full current day/night/weather/real-fight new-bar matrix open.",
"Stormheart hero tree source/native geometry repairs exist; mesh/contact diagnostic is not landmark beauty/readability proof.",
"Material/scar/body fixes exist; no whole current matrix certifies zero flat magenta/placeholder/floating/clipping residue."],
"F42": [
"Map/menu/HUD widget repair candidates exist; original UI catalog full code-blind bar remains open.",
"Altar/station/gear/research/bounty controller screens and input_owner hooks exist; active each-screen controller flow and no stacked owner proof open.",
"Meters/move slots/subject fade source and HUD floors exist; old7-inch Stormwood judges failed/contradicted, current full readable HUD open.",
"System-screen capture harness exists; actual every-screen1920x1080+1280x800 native readability verdicts not supplied."],
"F43": [
"Bounty deterministic three-slot morning rotation/unlocked-biome rules and board source exist; runtime gate is OFF.",
"Four authored bounty kind templates and progress adapters exist; each real catch-trait/alpha/material/rematch producer required.",
"Personal bounty instance receipts/reward staging and anti-reroll policies have bounded unit checks; actual paid reward/reconnect duplicate proof open.",
"Personal board/carrier serialisation source and local roundtrip tests exist; actual host/guest saved independent board proof open."],
"F44": [
"Trainer/captain/Master rematch rules and level/reward schedules exist; runtime gate is OFF and actual unlock/rechallenge path unproved.",
"Postcredits endgame schedule data exists; actual completed-world leader/boss return and level55..60 proof open.",
"Host-day alpha respawn services/fresh trait hooks exist; runtime gate OFF; actual native day/respawn/new-trait proof open.",
"Unique receipt and repeat cycle/cap rules pass bounded units; no actual full reward-cycle exploit witness supplied."],
"F45": [
"Species research task catalogue/progress/essence staging authored; runtime_enabled=false, actual task producer and payout proof open.",
"Biome percentage/title/cosmetic completion source exists; actual100percent personal result proof open.",
"Journal research screen and released/never-kept observation sources exist; actual live progress/readability/controller proof open.",
"Personal progress/reward receipt carriers have unit roundtrip source; actual persistence/replayed producer/rejoin no-double-payout proof open."],
"F46": [
"Lesson unlock/skip catalogues and NPC/service panel source exist; onboarding.enabled=false, actual ordered lesson introductions/skip open.",
"Ordinary UI/journal/goal prompts exist; agent-piloted gate comprehension/following witness not returned.",
"Lesson/input_owner single-owner queues are authored; actual no-stacked-modal run and every prompt registration proof open."],
"F47": [
"Time/economy route analysis infrastructure exists; no real15..25h normal-route estimate plus owner confirmation supplied.",
"Essence/material cost/yield and route budget authoring exists; ordinary main-path level entry/no-required-regrind and optional speed ledger missing.",
"Shared contention/solvency authoring and host harvest policies exist; four actual character resource ledgers missing.",
"New-order pilot/C2 and gear adapters exist; current band distributions/required starter seeds not supplied.",
"Buy/rest/release/bounty replay and bounded reward rules exist; actual exploit-loop refusal/bounded-yield witness remains open."],
"F48": [
"Authentic input-only ENet loop harness and producer adapters exist; profiles/paid Forge/Altar/Feed/guest Master prerequisite proof still open at pinned source.",
"Process identity guards/host-owner cut observation and replay field checks authored; real persisted boundary exits/restarts/ACKs have not been passed by this lane.",
"Four-peer boss harness and per-participant settlement source exist; actual four participants each receiving durable own key/relic proof missing.",
"Behind-guest portal access and honest personal state policy/harness exist; actual no-earned-key guest-follow session proof missing."],
"F49": [
"One-save input composition/disk handoffs/new-order helpers exist; required runtime producer gates are OFF and no completed four-biome run artifact returned.",
"Owner human play requirement exists; no actual owner findings for passing current integrated build supplied.",
"ROG Ally renderer/device contract exists; no owner/device gate result supplied.",
"Historical rolling build is8f5dd6ed2; current combined candidate is not a passing published development download."],
}

ANCHORS = {
"F16": ["scripts/save/save_game.gd", "scripts/save/character_save.gd", "scripts/data/redesign_data.gd", "scripts/data/redesign_state.gd", "data/config/biome_order.json", "data/progression/flag_scopes.json"],
"F17": ["data/config/village.json", "data/config/crossing_hall.json", "tests/smoke_gate_b_continuous.gd", "tests/helpers/gate_a_npc_gather_segment.gd"],
"F18": ["scripts/world/home_key.gd", "scripts/world/portal_arch.gd", "scripts/world/waystone.gd", "scripts/net/portal_action_policy.gd", "data/config/portals.json", "data/config/waystones.json"],
"F19": ["scripts/creatures/level_curve_policy.gd", "scripts/creatures/chapter_curve.gd", "tests/test_f19_curve.gd", "data/config/multiplayer.json", "data/config/biome_order.json"],
"F20": ["scripts/story/regional_homecoming.gd", "scripts/ui/regional_credits.gd", "scripts/world/stormwood_ending.gd", "data/config/regional_ending_objectives.json", "data/config/multiplayer.json"],
"F21": ["scripts/combat/hit_feedback.gd", "scripts/combat/combat_manager.gd", "data/config/combat.json", "tests/test_hit_feedback.gd"],
"F22": ["scripts/combat/combat_ai.gd", "scripts/combat/combat_manager.gd", "data/config/combat.json", "tests/smoke_f22_pattern_bands.gd", "tests/test_f22_action_publication.gd"],
"F23": ["data/moves/moves.json", "data/moves/learnsets.json", "data/moves/tms.json", "scripts/creatures/teaching.gd", "scripts/creatures/move_mastery.gd", "scripts/creatures/creature_instance.gd", "data/config/combat.json"],
"F24": ["scripts/combat/tether_commands.gd", "data/config/combat.json", "scripts/ui/tether_command_input.gd", "scripts/ui/tether_command_meter.gd"],
"F25": ["data/moves/moves.json", "data/config/vfx.json", "scripts/vfx/move_effect_library.gd", "scripts/vfx/move_effect.gd", "scripts/combat/move_projectile.gd", "tests/test_move_effects.gd"],
"F26": ["docs/design/ART_DIRECTION.md", "scripts/ui/tab_settings.gd", "autoload/settings_store.gd"],
"F27": ["data/items/items.json", "data/config/essence.json", "scripts/creatures/essence.gd", "scripts/creatures/progression.gd", "scripts/creatures/wild_victory_adapter.gd", "scripts/ui/altar_service.gd"],
"F28": ["data/config/masters.json", "scripts/masters/master_duel.gd", "scripts/masters/breakthrough_service.gd", "scripts/creatures/breakthrough.gd", "scripts/masters/master_site.gd"],
"F29": ["data/config/evolution_lines.json", "scripts/creatures/evolution.gd", "scripts/creatures/water_species_catalog.gd", "data/config/cloudreach_chapter.json", "data/config/water_encounters.json"],
"F30": ["data/config/traits.json", "data/traits/traits.json", "scripts/creatures/traits.gd", "scripts/combat/trait_effects.gd", "scripts/ui/altar_traits_service.gd", "tests/test_f30_traits.gd"],
"F31": ["data/config/stations.json", "scripts/build/station_rules.gd", "scripts/build/station_next_upgrade.gd", "scripts/build/station_forge.gd", "scripts/build/station_actions.gd"],
"F32": ["data/config/f32_runtime.json", "data/config/essence_nodes.json", "scripts/world/f32_source_service.gd", "scripts/world/f32_world_mount.gd", "scripts/world/essence_node_catalog.gd"],
"F33": ["data/config/gear.json", "scripts/creatures/creature_gear.gd", "scripts/creatures/creature_gear_accent.gd"],
"F34": ["data/config/forward_camps.json", "scripts/build/forward_camp.gd", "scripts/build/forward_camp_rules.gd", "scripts/build/forward_camp_host.gd", "tests/test_forward_camp.gd"],
"F35": ["data/moves/ultimates.json", "data/moves/moves.json", "data/moves/learnsets.json", "scripts/vfx/ultimates/ultimate_library.gd", "scripts/vfx/ultimates/ultimate_choreography.gd"],
"F36": ["ralph/reports/R2-F36/implementation-evidence.json", "ralph/reports/R2-F36/priority-source-audit.json", "ralph/reports/R2-F36/scale-census.json", "ralph/reports/R2-F36/meshy-night-ledger.json", "tests/test_f36_pose_candidates.gd"],
"F37": ["scripts/player/ripplet_traversal.gd", "scripts/world/ripplet_sunken_rules.gd", "scripts/save/water_traversal_save.gd", "tests/test_f37_ripplet_traversal.gd", "docs/design/SYSTEMS.md"],
"F38": ["data/config/village.json", "data/config/crossing_hall.json", "docs/design/ART_DIRECTION.md"],
"F39": ["scripts/world/water_world.gd", "scripts/world/water_offshore_material.gd", "docs/design/ART_DIRECTION.md"],
"F40": ["scripts/world/cloudreach_galefoot_waycamp.gd", "scripts/world/cloudreach_environment_materials.gd", "data/config/cloudreach_f40_visual.json", "tests/test_cloudreach_f40_presentation.gd"],
"F41": ["tests/test_r2_f41_core_finish.gd", "scripts/world/stormwood_world.gd", "docs/design/ART_DIRECTION.md"],
"F42": ["scripts/ui/altar_panel.gd", "scripts/ui/bounty_board_panel.gd", "scripts/ui/research_log_panel.gd", "tests/smoke_f42_system_screen.gd"],
"F43": ["data/config/bounties.json", "scripts/world/bounty_board.gd", "scripts/world/bounty_host_adapter.gd", "tests/test_bounty_board.gd"],
"F44": ["data/config/rematches.json", "data/config/alpha_respawns.json", "scripts/repeatables/rematch_rules.gd", "scripts/repeatables/alpha_respawn_service.gd", "tests/test_f44_repeatables.gd"],
"F45": ["data/config/research.json", "scripts/creatures/research_log.gd", "scripts/creatures/research_actions.gd", "tests/test_research_log.gd"],
"F46": ["data/config/onboarding.json", "scripts/onboarding/lesson_rules.gd", "scripts/onboarding/lesson_panel.gd", "scripts/onboarding/lesson_service.gd"],
"F47": ["docs/design/PROGRESSION.md", "data/config/essence.json", "tests/smoke_f22_pattern_bands.gd"],
"F48": ["tests/helpers/f48_net_proof.gd", "tests/smoke_net_f48_loop.gd", "tests/smoke_net_f48_transactions.gd", "tests/smoke_net_f48_boss_four.gd", "tests/smoke_net_f48_behind.gd", "data/config/multiplayer.json"],
"F49": ["tests/helpers/f49_campaign_journey.gd", "tests/helpers/f49_disk_handoff.gd", "data/config/multiplayer.json", "docs/ACCEPTANCE.md"],
}

ORIGINAL_OPEN = {"F04#1": "F22#4", "F04#2": "F22#4", "F04#6": "F22#4", "F04#7": "F22#4", "F10#6": "F42#2", "F14#1": "F22#4"}
STATIC = {"F25#1": "f25-mapping-recheck.json", "F37#3": "f37-teleport-removal-recheck.json"}
NATIVE_CANDIDATES = {"F23#1", "F23#2", "F35#0"}

def modalities(requirement: str, ident: str) -> list[str]:
    r = requirement.lower()
    out = []
    if ident in STATIC or ident == "F26#2": out.append("static/data")
    if "test" in r or "simulation" in r: out.append("named deterministic/native check")
    if any(s in r for s in ["code-blind", "frame", "visib", "read", "capture", "pose", "visual", "glow"]): out.append("native pixels/motion and independent full-bar judge where visual")
    if any(s in r for s in ["co-op", "peer", "participant", "rejoin", "reconnect", "character contention"]): out.append("actual separate-peer/process authority/persistence")
    if any(s in r for s in ["save", "reload", "persist", "pay once", "durable", "once per"]): out.append("actual durable write/reload/failure/replay boundary")
    if "ledger" in r or "route estimates" in r: out.append("actual event/route/resource ledger")
    if "owner" in r or "human play" in r or "rog ally" in r: out.append("explicit owner/device action")
    if not out or any(s in r for s in ["ordinary", "controller", "reaches", "using", "can be built", "works", "sources work", "is cooked", "1v1"]): out.append("actual relevant production/player path")
    return list(dict.fromkeys(out))


def proof_family(ident: str) -> list[str]:
    f = int(ident.split("#")[0][1:])
    if ident in NATIVE_CANDIDATES or ident == "F25#1": return ["DATA-NATIVE-01"]
    if ident == "F17#4": return ["OPENING-M1-01"]
    if f == 48: return ["F48-AUTHENTIC-01"]
    if ident in {"F22#1", "F22#2", "F22#4", "F33#2", "F47#3"}: return ["COMBAT-BAND-01"]
    if f in {36,38,39,40,41,42} or ident in {"F17#6", "F21#4", "F21#5", "F22#3", "F25#2", "F25#4", "F25#5", "F26#3", "F35#2", "F35#3", "F35#4"}: return ["CAPTURE-JUDGES-01"]
    if f == 49 or ident in {"F18#5", "F19#5", "F20#0", "F20#1", "F20#3", "F46#1", "F47#0", "F47#1"}: return ["F49-CONTINUOUS-01"]
    return []


def config_flags(value, pointer=""):
    found = []
    if isinstance(value, dict):
        for k, v in value.items():
            if isinstance(v, bool) and ("enabled" in k or k == "active"):
                found.append({"pointer": pointer + "/" + k, "value": v})
            elif isinstance(v, (dict, list)): found += config_flags(v, pointer + "/" + k)
    elif isinstance(value, list):
        for i, v in enumerate(value): found += config_flags(v, pointer + "/" + str(i))
    return found


def main() -> None:
    board_raw = BOARD.read_bytes()
    board = json.loads(board_raw.decode("utf-8-sig"))
    available = set(paths(""))
    all_names = [p for names in ANCHORS.values() for p in names if p in available]
    warm(all_names)
    anchors = {}
    flags = []
    for f, names in ANCHORS.items():
        anchors[f] = []
        for path in names:
            if path not in available:
                anchors[f].append({"path": path, "present": False, "gap": "This proposed anchor is absent from the pinned source; no proof inferred."})
                continue
            anchors[f].append({"path": path, "present": True, "source_commit": BASE, "sha256_git_blob_content": hashlib.sha256(raw(path)).hexdigest()})
            if path.startswith("data/config/") and path.endswith(".json"):
                for gate in config_flags(data(path)):
                    flags.append({"feature": f, "path": path, **gate})
    receipts = json.loads((OUT / "native-receipt-audit.json").read_text(encoding="utf-8"))["records"]
    criteria = []
    for row in board["rows"]:
        fid = row["id"]
        original = int(fid[1:]) <= 15
        if not original and len(IMPLEMENTATION[fid]) != len(row["criteria"]):
            raise ValueError(f"wrong authored implementation cardinality {fid}")
        for ordinal, c in enumerate(row["criteria"]):
            ident = f"{fid}#{ordinal}"
            historical = c.get("status") == "met"
            verdict = "RECORDED_MAIN_ACCEPTED_CURRENT_RELEVANCE_NOT_RECHECKED" if historical else "OPEN"
            if ident in STATIC: verdict = "SUFFICIENT_STATIC_PASS_PENDING_GREEN_MAIN_LANDING"
            if ident in NATIVE_CANDIDATES: verdict = "AUTHORED_DATA_PASS_NAMED_NATIVE_RECHECK_PENDING"
            if ident == "F29#4": verdict = "STATIC_TABLE_PASS_PROVIDER_BINDING_REVIEW_PENDING"
            existing = {"board_recorded_status": c.get("status"), "board_exact_claim": c.get("evidence", ""),
                        "board_exact_gap": c.get("gap", ""), "source_commit": None, "package_hash": None,
                        "platform": "Only as explicitly recorded in board claim; inspect named artifact for missing fields.",
                        "input": "Only as explicitly recorded in board claim; a source/unit claim is not controller flow.",
                        "shortcuts": "Exact board disclosures retained verbatim; absent disclosures remain unknown.",
                        "binding": "Historical board entry is not a fresh current-source re-check."}
            evidence = [{"artifact": STATIC[ident], "scope": "independent exact static criterion evidence", "source_commit": BASE,
                         "platform": "Windows Python/Git", "input": "read-only pinned objects", "shortcuts": "static inspection only; no engine/player/campaign"}] if ident in STATIC else []
            if ident in {"F23#1", "F23#2", "F35#0"}:
                evidence.append({"artifact": "f23-f35-catalogue-recheck.json", "scope": "authored data bindings only; runtime unproved", "source_commit": BASE})
            if ident == "F29#4": evidence.append({"artifact": "f29-wild-roster-recheck.json", "scope": "exact wild-table census and disclosed Water alias; provider review pending", "source_commit": BASE})
            impl = IMPLEMENTATION[fid][ordinal] if not original else (
                "Historical main implementation/acceptance is recorded in the exact board claim below; this evidence lane has not re-executed it on the combined redesign source."
                if historical else "Original defect remains open; replacement requirement is " + ORIGINAL_OPEN.get(ident, "not identified") + "; newer timings invalidate old combat distributions.")
            if original and ident in ORIGINAL_OPEN:
                gap = "Still OPEN until replacement " + ORIGINAL_OPEN[ident] + " actually passes and lands. Old numerical/capture proof cannot close new timings/HUD. " + c.get("gap", "")
            elif historical:
                gap = "Retain historical acceptance only within recorded scope; verify current relevant dependency/source changes and required green main landing before claiming combined-candidate reuse."
            elif ident in STATIC:
                gap = "Exact static requirement independently passes at pinned source; green main landing/counting remains. No other row/engine/visual/co-op inference."
            else:
                gap = impl + " Named complete proof and an independent verdict are still required; source counts/compile/partial fixture passes are insufficient."
            candidates = []
            anchor_tests = [a["path"].split("/")[-1] for a in anchors.get(fid, []) if a["present"] and a["path"].startswith("tests/")]
            for r in receipts:
                if r.get("selection") and any(t in r["selection"] for t in anchor_tests):
                    candidates.append({"artifact": r["artifact"], "source_commit": r.get("source_commit"), "selection": r.get("selection"),
                                       "exit": r.get("exit"), "raw_sha256": r.get("actual_sha256"), "declared_hash_matches": r.get("hash_matches"),
                                       "counts": r.get("terminal_counts"), "scope": "bounded named check only; dependencies/full criterion relevance not established here"})
            criteria.append({"id": ident, "feature_title": row.get("title"), "requirement": c["text"],
                             "acceptance_authority": "docs/ACCEPTANCE.md6.1/6.2 and current owner RD36/RD37; board ordinal is zero-based",
                             "actual_implementation": impl, "source_anchors": anchors.get(fid, []),
                             "needed_proof": {"exact_requirement_to_observe": c["text"], "modalities": modalities(c["text"], ident),
                                              "named_run_request_ids": proof_family(ident), "existing_entrypoints": anchor_tests,
                                              "rule": "Full row conjunction must pass. Relaxed fixture starts must be disclosed; F48 authentic input restriction and actual co-op/durable/visual requirements remain."},
                             "existing_proof": existing, "independent_evidence": evidence, "bounded_native_candidates": candidates,
                             "independent_verdict": verdict, "honest_gap": gap,
                             "replacement_criterion": ORIGINAL_OPEN.get(ident), "acceptance_credit_added": 0})
    summary = collections.Counter(c["independent_verdict"] for c in criteria)
    if len(criteria) != 280 or sum(not int(c["id"].split("#")[0][1:]) <= 15 for c in criteria) != 179:
        raise ValueError("board cardinality drift; do not silently redefine acceptance")
    result = {**stamp(), "artifact_kind": "independent evidence map, not a status/planning document", "board_snapshot": {
        "path": str(BOARD), "sha256": hashlib.sha256(board_raw).hexdigest(), "generated_at": board.get("generated_at"),
        "recorded_main_sha": board.get("main_sha"), "note": "R2/R3 implementation status is stale; no board mutations."},
        "counts": {"mapped": len(criteria), "original": 101, "redesign": 179, "verdicts": dict(summary),
                   "native_receipts_inventoried": len(receipts), "declared_raw_hashes_matched": sum(r.get("hash_matches") is True for r in receipts),
                   "without_paired_declared_raw_hash": sum(r.get("hash_matches") is None for r in receipts)},
        "criteria": criteria,
        "global_limits": ["No engine/import/GPU/net/test execution launched by this lane.", "Main/board accepted110/280 is historical; no new MET before green main landing.",
                          "Flags and class/config existence are implementation evidence only for requirements demanding actual play/pixels/durable/co-op proofs.",
                          "95 receipt inventory contains79 matched declared raw hashes;16 lack paired hashes and are not called hash-verified.",
                          "Owner play and Ally device confirmation cannot be manufactured by agent/data/desktop runs."]}
    dump("criteria-evidence-map.json", result)
    dump("activation-gate-census.json", {**stamp(), "flags": flags, "scope": "literal flags only; actual producer capability/activation must be independently proven"})
    dump("board-snapshot.json", board)
    print(json.dumps({"counts": result["counts"], "absent_proposed_anchors": [a["path"] for aa in anchors.values() for a in aa if not a["present"]]}, indent=2))


if __name__ == "__main__":
    main()
