# Stormwood §13 census and placeholder ledger — 2026-09-07

## Scope and evidence boundary

This is a fresh configuration/runtime audit for the resumed Stormwood tail. It does not
update the stale `ralph/reports/STORMWOOD-CONTRACT-CENSUS-2026-09-06.md` baseline.

The merged-main baseline is `4562268dee581d2f2ce167a4670bbf752f139310` (PR #76).
All claims marked **configured** come from the JSON named below, parsed at the current
checkout. They are not evidence of a player walk, rendering acceptance, gap measurement,
visual review, multiplayer proof, or whole-chapter completion.

The checked-out branch is `ralph/stormwood-dynamo-0907`, at `69ac80285`, and is ahead of
that merged baseline. Its Dynamo/TM/Crown work is **unmerged** and therefore has zero
merged-main credit in this report. The checkout also contains unrelated and Stormwood
uncommitted work; it is not used to upgrade a configured row to proven.

## §13 census

| Contract row | Minimum / rule | Current actual from source | Status and source |
|---|---:|---:|---|
| Named map regions | 6 | 6 | Configured: `stormwood_world.json:regions`. |
| Landmarks | 16, at least 2 each | 19 | Configured: `stormwood_world.json:landmarks`. The config has 3/3/3/3/4/3 by region. Silhouette visibility is unmeasured. |
| Authored route | at least 12 km; 4 loops, 3 shortcuts, 5 pockets, 2 alternates late | 24.001 km across 9 route entries; 5 `loop`, 3 `critical`, 1 `island` | Configured: route-polyline sum in `stormwood_world.json:routes`. `kind` does not itself establish the required shortcuts, pockets, alternates, or a walkable route. |
| Wild clusters | 330; 40 each (Crown 12) | 330 | Configured: `stormwood_encounters.json:wild_clusters`, 55 in each of the six regions. Critical-path worst/average gaps are unmeasured. |
| Encounter tables | 12; Calm/Surge per region | 12 | Configured: `stormwood_encounters.json:tables`; all marked replaceable. Role differentiation and night-weight behaviour require runtime verification. |
| Named wild encounters | 6 | 6 | Configured: `named_encounters`; catchability, once-only state, G-1/G-3 behaviour and fight play are unproven. |
| Trainers | 26; 14 critical / 12 optional | 26 | Configured: `stormwood_trainers.json:trainers`. The critical/optional split, dialogue and rank-body presentation were not independently recalculated here. |
| Team Tether pickets | 4 stations plus outer works | 4 rod stations; Dynamo config present | Configured: `stormwood_rod_stations.json` and unmerged `stormwood_dynamo.json`. Guard-fight-to-switch chain and healing ground are unproven. |
| Named NPCs | 18 | 19 | Configured: `stormwood_npcs.json:characters`. State dialogue, bodies/portraits and distribution are unproven. |
| Settlements/camps residents | 3, with 4/4/8 residents | 15 structure records | `stormwood_settlements.json:structures` is not a resident census. The specified resident distribution is not established by this audit. |
| Safe camps | 6 | 6 | Configured: `stormwood_camps.json:camps`; their full save/rest/cook/recovery interaction path is unproven. |
| Rod-able clearings | 10 | Not independently countable from a dedicated clearing ledger | `stormwood_surge.json` needs a spatial/runtime audit; do not infer this from safe zones or stations. |
| Ancient arches / footings | 9 / 5 | 9 / 5 | Configured: `stormwood_arches.json`. Main has ancient-arch work; constructed pairs/Crown progression are unmerged. Visibility/readability unproven. |
| Player arch-pair cap | 3 | 3 configured | `stormwood_arches.json:player_pair_limit`; constructed build/save/travel work is unmerged. |
| Harvest sites | 210; 25 each | 210; 35 each region | Configured: `stormwood_harvests.json:sites`. Runtime collection/persistence and scattered-tree/stone coverage are not certified here. |
| Charged sites | 24; 3 in regions 2–6 | 28; 4/4/5/5/5/5 across regions 1–6 | Configured: `stormwood_harvests.json`. Break/Fading availability is data, not a played Surge path. |
| Item pickups | 200–230; 28 each; 80% off path | 229; 38/39/40/29/43/40 by regions 1–6 | Configured: `stormwood_pickups.json:pickups`. Off-route percentage, stable-id runtime persistence and visual reward cadence are unmeasured. |
| Candy | 60 / 30 / 10 | 60 / 30 / 10 | Configured item-id tally. Critical-path cap not measured. |
| Potions | 30 / 18 | 30 / 18 | Configured item-id tally. |
| Revives | 24 | 24 | Configured item-id tally; mini-boss/Dynamo reachability not measured. |
| Mushrooms | 24 | 24 (8 speed, 8 stamina, 8 wild) | Configured item-id tally. |
| Tonics / elixirs | 12 | 12 (4 attack, 4 swift, 4 stoneguard) | Configured item-id tally. |
| Orbs | 12 | 12 (6 basic, 4 greater, 2 prime) | Configured item-id tally; late-region restriction unverified. |
| Electric TMs | 4 | 4 configured, **unmerged** | Four pickup entries exist in merged config; item/move/teaching support is in commits after `4562268`. |
| Found insulated gear | 2 | 2 (boots, leggings) | Configured pickup tally. |
| Story items | 3 | 3 (Rootgate key, Dynamo core key, Spark) | Configured pickup tally. Their story delivery is unproven. |
| Main objectives | 24–30 | 28 (9 + 7 + 12) | Configured: `stormwood_chapter.json:acts`. Runtime completion path is not accepted. |
| Side chains | 6 | 6, each with 3 steps | Configured: `stormwood_chapter.json:side_chains`; completion paths unproven. |
| Dialogue nodes | at least 160 | 57 conversations containing 171 lines | Configured: `stormwood.json:conversations`; line count is not proof of 160 distinct stateful dialogue nodes or adequate cadence. |
| New buildables / resources / recipes | 4 / 6 / at least 12 | 4 / 6 / 8 live recipes; 12-recipe integration payload | The six resources are Stormglass, Thunderwood, Conductor Vine, Glowmoss, Voltcap and encounter-reward Sparkfur. `recipes_stormwood.json` supplies 8 live recipes; `stormwood_items_recipes.json` carries 12 proposed recipe records, so the live count is short. Built-arch integration is unmerged. |
| Audio cues / visual review points | 10 / 8 | Audio uncounted; 8 rendered survey frames | Eight Compatibility production-scene frames exist, but the blind visual judge failed both bars. No visual acceptance claim. |
| Surge phases | 4 | 4 configured | `stormwood_surge.json:phases`; phase recognition and player-changing behaviour remain unproven. |

## Placeholder replacement ledger

The only deliberate creature placeholders found by a case-insensitive scan of current
Stormwood JSON are listed below. Each has an explicit `replacement_point`; no missing row
is silently treated as final. The exact source fields are the exhaustive ledger: **461
distinct replacement points** = 373 encounter points + 87 trainer points + 1 Dynamo
legendary point.

| Scope | Exact replacement-point set | Count | Current placeholder | Replacement action |
|---|---|---:|---|---|
| Wild table roles | `tables.{verge_calm,verge_surge,hollows_calm,hollows_surge,run_calm,run_surge,crown_calm,crown_surge,deepwood_calm,deepwood_surge,dynamo_calm,dynamo_surge}.roles.{each of 3 configured roles}` | 36 | Meadows species in `placeholder_species` | Replace each role's `placeholder_species` at its listed point when the final roster is installed; preserve role, table, weights and behaviour profile. |
| Wild-cluster instances | `wild_clusters.{cinder_verge,glowmoss_hollows,conductor_run,hollow_crown,deepwood,dynamo}_cluster_{01..55}` | 330 | Cluster-selected Meadows species | Replace the species at every cluster's exact `replacement_point`; retain stable cluster ids and placements. |
| Named encounters | `named_encounters.{hollows_alpha,capacitor_alpha,crown_guardian,old_rodfolk_hall_guardian,blackwater_elder,glass_field_alpha}_placeholder` | 6 | Named Meadows species | Replace at the named encounter point while retaining the authored profile, level, catchability and once-only state. |
| Encounter legendary | `legendary_placeholder.stormheart_placeholder` | 1 | Sparkit | Replace the legendary body/name at the listed point, retaining the five-slot ceremony. |
| Trainer roots | `trainers.{26 configured trainer ids}` | 26 | Trainer roster metadata | Replace each trainer's roster profile at its root point; retain trainer identity, progression and dialogue. |
| Trainer party slots | `trainers.{26 configured trainer ids}.party.{configured member index}` | 61 | Meadows party members | Replace each party member's `placeholder_species` at its own point; retain its move/loadout/rank context. |
| Dynamo captive | `stormwood_dynamo.captive.placeholder_species` | 1 | Sparkit at scale 1.8, “the Stormheart” | Replace body/name from `stormwood_dynamo.json`; retain level 44 and the release/offer structure. |

For a mechanically reproducible exhaustive list, parse the three source files and collect
every `replacement_point` value. The audit observed 373 unique values in
`data/config/stormwood_encounters.json`, 87 in
`data/config/stormwood_trainers.json`, and 1 in
`data/config/stormwood_dynamo.json`; duplicate count is zero in each file. This is the
authoritative replacement ledger, rather than a hand-maintained copy that could lose rows.

Two additional visible stand-ins are not creature roster replacement points and need their
own art decisions:

| Location | Stand-in | Replacement point |
|---|---|---|
| `scripts/world/stormwood_arch_runtime.gd` | `BoxMesh` dark footing slab beneath the installed castle entrance frame | Replace the footing visual with a Stormglass-specific authored/installed prop while retaining collision and arch state. Constructed arches are unmerged. |
| `scripts/world/stormwood_dynamo_arena.gd` | `CylinderMesh` grounded rod plates; banks use installed tether pylons | Replace plate visual with an authored/installed grounded-plate asset. This entire Dynamo arena layer is unmerged. |

`scripts/world/stormheart_tree.gd` also builds custom mesh floors/ramps and `BoxMesh` rail
instances. They are current geometry, not labelled placeholder/replacement-point data, but
they require a real visual review before acceptance; this audit does not call them final.

## Branch separation

| Tier | What exists | Merge status |
|---|---|---|
| Baseline | PR #76 foundation at `4562268`: six-region config/runtime foundation, ordinary content tables, entry/return, partial Surge/ancient-arch interactions according to the preceding scorecard. | Merged main. |
| Dynamo/TMs | `a08c5ea45`, `147425418`, `5c1145162`, `904dbe074`, `f46c6d2ac`: Dynamo rules/arena/host adapters, four electric TMs and related tests. | Unmerged commits after baseline on current branch. |
| Crown/constructed arches | `69ac80285`: constructed Stormglass roads/Crown progression; plus current checkout modifications touching arch/surge/world paths. | Unmerged; some work is also uncommitted. |

No row above claims an authored count as a successful player path. The next acceptance work
must use the §13 probes and an actual continuous play/visual route to establish gaps,
off-route rewards, silhouette readability, interaction ordering, and the post-Crown path.
