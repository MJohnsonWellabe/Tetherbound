# Tetherbound World and Chapter Contract

**Status:** Product contract. Built status is stated per feature; a design target is not completion evidence.

**Product:** A finite, authored creature expedition action RPG for one to four players, with co-op required for release. The four current chapters/biomes form the release campaign. The target normal clear is **15–25 hours** (owner, 2026-09-29, RD-01). The loop is fun to grind but optional to repeat. Each biome asks for real preparation (gather, train, craft, build), and the main path finishes without padding. **Superseded (RD-01):** the former "around eight good hours" clear and the no-grind rule. There is still no minimum duration per chapter. Optional exploration, catching, team experiments, gathering, building and the repeatables (§2.11) can extend a run. The game is not an endless survival sandbox.

**Redesign routing (owner, 2026-09-29).** This contract now covers:

- the new chapter order: Meadows → Tidewake → Cloudreach → Stormwood (RD-10);
- the village road and the Crossing Hall hub (§3.2, §2.6; RD-17, RD-29);
- the Home Key, portal keys and waystones, which replace the physical crossings (§2.7; RD-18–RD-21);
- the Stormwood ending (§2.8; RD-22);
- Master placement (§2.10);
- repeatables (§2.11; RD-31);
- material and attuned essence nodes (§2.12);
- the eight-biome slots (§2.13; RD-09).

All of it is **target, not built** unless a line says otherwise. Section numbers are kept stable for cross-references. The chapter sections therefore stay in the old order: §3 Meadows is chapter 1, §6 Tidewake is chapter 2, §4 Cloudreach is chapter 3 and §5 Stormwood is chapter 4. Acceptance lives in ACCEPTANCE §6.2 (F17–F20, F28, F32, F37, F43, F44); this file does not restate it. BOSSES owns fight levels, Masters' fights and rematch tiers. TRAINING owns breakthroughs and Ripplet. HOMESTEAD owns stations, materials and forward camps.

## 1. Player journey

The player leaves Grandpa's farm with one named companion, a Home Key and a patch of land. They build a five-creature team and grow its power at the homestead. From the Crossing Hall they portal into four compact worlds and break a regional Team Tether supply network. Each chapter asks the player to prepare, travel, read terrain and creature behavior and defeat named gatekeepers. Every chapter frees one captive legendary and asks whether the volunteer belongs among the five: Veridian, the Abyssal Guardian, Solmane and Stormheart (§2.3). The older line saying Cloudreach offers no legendary is withdrawn. Solmane has been freed after Veyra since the owner decision of 2026-09-27.

The campaign order is fixed. **Superseded (owner, 2026-09-29, RD-10):** the former order Meadows → Cloudreach → Stormwood → Tidewake.

1. **The Meadows** (§3), L3→22: learn the expedition loop and break the Warden's regional occupation.
2. **Tidewake** (§6), L20→33: restore the archipelago's currents. Its dock exchange closes the chapter.
3. **Cloudreach Cliffs** (§4), L31→44: reconnect the wind roads and learn Fly.
4. **The Stormwood** (§5), L42→55: relight the Stormglass roads, end the Long Storm and go home.

`data/config/biome_order.json` (new, F16) is the single source of this order for the map, journal, portal signs and credits (F19#0).

The four-chapter ending is complete in itself and is the current release pass (§2.8). Eight legendary forces, eight Tether Rifts and an eventual eight-biome campaign remain later canon and scope. This pass reserves their data and hub slots (§2.13) but builds no content for them. **Superseded (owner, 2026-09-29, RD-22):** the former "no fifth-chapter tease" line. The fifth portal key makes the fifth arch *stir* and nothing more. That is not a cliffhanger, quest or sequel prompt.

## 2. Rules shared by every chapter

### 2.1 Authored geography

Roads, water, caves, settlements, gates, strongholds, landmarks, sightlines and regional entrances are placed deliberately. Procedural or rule-driven dressing supports those compositions. It does not decide the critical path.

Every chapter provides:

- A readable principal route with physical landmarks and an always-available next lead.
- Loops, far-side shortcuts, overlooks and optional pockets that make a finite map worth learning.
- A safe preparation point before a major commitment.
- Visible changes after local Team Tether machinery is disabled.
- **6–10 meaningful optional activities per chapter**, **24–40 total**, with at least one in every principal region. These remain release content, not prerequisites for the initial brief loop check or reasons to pad runtime.

An optional activity counts only when it has a discoverable lure, a distinct action or decision, a useful reward, acknowledgement, saved completion and a route that works through ordinary play. Pickups and spawn rows do not count individually.

The terrain envelopes are fixed. Density work may repair routes, leads and rewards; it may not shrink the Meadows or any later chapter to manufacture a shorter runtime. Use shortcuts and route edits to remove dead travel; do not add travel or encounters to manufacture runtime.

### 2.2 Gates, relics and chapter handoffs

**Current source:** each chapter climax grants its relic, and chapters 1–3 grant a world-owned key that is spent once to open a physical realm gate, in the old order. The relic is placed at an in-biome shrine or the Meadows home circle. F15 and the T3 card closed the old ending in Tidewake, and they stay met as history (CODEX_START_HERE §7.5).

**Target (owner, 2026-09-29, RD-17, RD-20, RD-21, RD-22). Superseded:** the world-owned key, the physical crossings between biomes and the Tidewake ending.

| Climax | Relic (each participant) | Portal key item (each participant) |
|---|---|---|
| Warden Aldis, Meadows | Heart of the Meadows | Tidewake portal key |
| Captain Nerissa, Tidewake | Tideglass Compass | Cloudreach portal key |
| Captain Veyra, Cloudreach | Wings of Cloudreach | Stormwood portal key |
| Captain Marrow, Stormwood finale | Spark of the Stormwood | Fifth portal key (the arch stirs only; §2.8) |

- Every admitted participant in the climax receives their own relic and their own key. BOSSES §9.1 owns the drop transaction. A non-participant receives neither.
- The **portal key** is a real inventory item, used once at its arch in the Crossing Hall (§2.7). It is not spent by the party as a whole.
- The **relic** must be hung on its biome's pedestal in the Shrine Room (§2.6). Hanging it unlocks that biome's homestead attachment recipes (HOMESTEAD) and adds its power to the player's selectable set. Exactly one relic power is active at a time, and the selection persists.
- **Physical crossings retired (RD-17; F18#2).** The Meadows rift bridge, the Cloudreach and Stormwood realm gates, the Stormwood water gate, the First Shore passage and the return gates no longer lead between biomes. Each becomes scenery or a one-way return to the Crossing Hall; F18 chooses per gate. They sit behind one `legacy_physical_crossings` flag that defaults off (F16). Portals are the only realm path. Existing overlooks (Stormward, Waterward) remain as views, not routes.
- The next chapter first appears as its signed arch in the Crossing Hall, showing the biome name and recommended level.

Relic powers are unchanged: Heart of the Meadows (**2× max stamina**), Wings of Cloudreach/Skyborne (**0 Fly stamina cost**), Spark of the Stormwood/Livewire (**0.75 move-cooldown multiplier**) and Tideglass Compass/Tidal Guard (**0.90 incoming-damage multiplier**). The new order makes Tideglass the second relic and Wings the third. Nothing in Tidewake may assume Wings or Spark (§2.9).

### 2.3 Legendary offer

When a chapter frees a legendary, that creature volunteers. The player never weakens it for capture and never throws an Orb at it. With fewer than five companions it may join directly. With five, the existing ceremony presents the volunteer beside the five companions' names and history and requires one permanent release or a refusal. Refusal completes the chapter. This contract applies to Meadows, Cloudreach (Solmane, freed after Veyra (owner, 2026-09-27)), Stormwood and Tidewake.

In co-op the host owns the shared freeing result, then records a separate, once-only offer for **each participant in that fight** against that participant's stable character. Each may accept or refuse independently; a non-participant receives no offer. Every accepter keeps their own legendary within the five-creature cap. The UI states this and the permanent-release consequence before each personal commitment. The world restoration stays shared. **Target (RD-21):** the relic and the next portal key are per participant (§2.2), replacing the former shared relic and gate. This supersedes the historical single-recipient interpretation everywhere in this file. The offers work in the new order, accepting and refusing, at capacity and with space (F19#4).

### 2.4 Progression envelope

**Target (owner, 2026-09-29, RD-10). Superseded:** the old-order envelope, shown in the last column as current source.

| Order | Chapter | Team in→out | Wild | Boss team | Masters (§2.10) | Current authored basis (old order) |
|---:|---|---|---|---|---|---|
| 1 | Meadows | 3→22 | 2–20 | Warden ~21–22 | L10, L20 | Curve 3→9→12→15→17→21; Warden 18/18/19/19/20 |
| 2 | Tidewake | 20→33 | 18–32 | Nerissa ~32–33 | L30 | Ladder 43–55; Aquaryn49, Tidecoil54, Guardian55 |
| 3 | Cloudreach | 31→44 | 29–43 | Veyra ~43–44 | L40 | Ladder 19–34; wild 18–33 |
| 4 | Stormwood | 42→55 | 40–54 | Finale ~54–55 | L50 | Team curve 33→35→37→39→40→42→44 |
| — | After credits | endgame | — | Leaders and bosses L55–60 | Rematches | none |

- **Rows and data.** BOSSES §0 lists the per-row fight targets. F19 re-derives the wild tables and named teams and pins them with a curve test (F19#1).
- **Caps.** Creature level caps sit at L10/20/30/40/50, with a **ceiling of 60** this pass. Data supports tiers to **100** for biomes 5–8 (RD-08). **Superseded:** the former global cap of 100. TRAINING owns caps and breakthroughs.
- **Portal signs, not level walls.** Each Crossing Hall portal sign shows the recommended level. The portal key is the only hard gate (F19#5). No route uses a generic level wall where a person, creature, machine, current or physical gate can explain the boundary. A breakthrough cap is a creature-power limit, not a route wall.
- **Overlaps.** The band overlaps let a prepared party enter the next chapter at the bottom of its band. Grinding makes the party clearly stronger (RD-01).

### 2.5 Ordinary wild return policy

An ordinary wild site may repopulate only after **two complete 600-second world days** have elapsed since its defeat or catch **and** every player has left that principal region at least once. The host persists the site's stable ID and next-eligible world time; reload, rest, reconnect and realm transition cannot move the deadline backward or instantly respawn it. A new wild is a new encounter with the site's authored table, not a resurrection of an owned/caught instance. Trainers, quest fights, rewards, pickups and permanent harvests remain once-only under their existing receipts. **Superseded for alphas and trainers (owner, 2026-09-29, RD-31):** named alphas respawn on their own timer with freshly rolled traits (§2.11). Trainers can be rematched in tiers (BOSSES §9.2). Their first-win rewards stay once-only. Wild defeats now also pay type essence (TRAINING §1), so this return policy feeds the optional grind. F47 may tune the interval with evidence. The journal need not show a countdown. This policy makes optional later catching possible without making respawn farming a route requirement. Acceptance uses a deterministic world clock, solo and two-peer exit/re-entry, save/reload before and after eligibility, and exact reward/XP receipts; the required route and four-player supply ledger must still clear when **no wild respawns at all**. This constraint keeps respawn grinding optional (RD-01). F47 confirms it against the new essence ledger.

### 2.6 The Crossing Hall and the Shrine Room (RD-17, RD-20; F17)

**Not built (target).** No Crossing Hall, arch or pedestal exists in source.

- **Place.** The Hall caps the far end of the village road (§3.2). It is the tallest village landmark and reads as the destination from Grandpa's farm door, by day and by night (F17#1). It is kitbashed from installed families (MegaKit stone, timber, props) under ART_DIRECTION, and it needs no new mesh. Config: `data/config/crossing_hall.json` (new, F17).
- **Nave.** It holds the **home arch**, where the Home Key arrives, plus **seven portal arches**:
  - **Tidewake, Cloudreach and Stormwood** are live-capable.
  - **Biomes 5–8** are sealed, dark but visible, and signed "Sealed".
  - The Meadows has no portal arch, because the village sits inside it.
  - Each arch is signed with its biome name and recommended level, read from `biome_order.json` and the §2.4 band.
  - Arch states are *sealed* (biomes 5–8; biome 5 can also show *stirred*, §2.8), *locked* or *open*.
- **Shrine Room.** A side room holds **eight pedestals** in biome order, Meadows first. Pedestals 1–4 are live and 5–8 are dark placeholders. A player hangs a relic by using the pedestal with that relic in their inventory:
  - The relic leaves the inventory and appears on the pedestal.
  - The player's character records it as hung.
  - That relic's power joins the character's selectable set. The one active power is chosen at the Shrine Room, and the choice persists. UX owns the screen.
  - Hanging unlocks the homestead attachment recipes that HOMESTEAD §4 assigns to that relic. HOMESTEAD settles this as the *next* biome's attachments.
  - Hanging is required for those recipes and for the power. It does **not** gate the next portal, because the portal key alone opens that.
- **Existing in-biome shrines** (the Sky Shrine at High Roost, the Lantern Hollow shrine and the Meadows home circle) are no longer where a relic is placed. Their geography stays. F18/F19 decide whether each keeps an acknowledgement line or becomes scenery.
- **Co-op and scope.** The Hall layout and each arch's and pedestal's *display* are world scope, owned by the host. Host and guest see the same display (F17#5). Portal unlocks and hung relics are **character** scope, and each also writes a world-scope display record in the host world where it happened, as portal keys do (§2.7). The host validates each hang once, keyed `relic_hung:<biome>:<character_id>`. A reconnect replays or rolls back the hang, never both. Nothing here needs migration, because saves reset for this redesign (RD-35).

### 2.7 Home Key, portal keys, waystones and portal access (RD-18–RD-21; F18)

**Not built (target).** Source currently moves players between realms through physical gates and `Game.enter_realm`, and has no fast travel.

**Home Key.** Grandpa gives it during the opening. F18 picks the earlier natural beat: `grandpa_first_catch` or the tournament send-off (F18#0).

| Rule | Target |
|---|---|
| Item | Key category, in the backpack. It cannot be dropped, sold, traded or lost, and it is excluded from death satchels. |
| Use | One tap. The trainer raises the key for about **2 s** (`data/config/portals.json`, starting value 2.0 s), with glow and sound under an `input_owner` lock, then fades and arrives at the home arch. Free, with **no cooldown**. |
| Refused | In combat (as an admitted participant), in dialogue, in a cutscene, while swimming or diving, and mid-flight. Each refusal states its reason. Taking damage or entering combat during the raise cancels it at no cost. |
| Companions | The player's own five travel with them. Other players stay where they are. |
| Scope | Character. The grant is a one-time receipt; the item cannot be duplicated and needs no re-grant because it cannot be lost. Using it writes only the player's position, which saves normally. |

**Portal keys.** The keys are `tidewake_portal_key`, `cloudreach_portal_key`, `stormwood_portal_key` and `fifth_portal_key`. Each is a real item dropped per participant by a chapter climax (§2.2). Like the Home Key, they cannot be dropped, sold or lost, and they are excluded from death satchels. A player uses one with a tap at its arch. The key is consumed once, and two records are written in the same host transaction (`portal_unlock:<biome>:<character_id>`):

- a **character-scope** unlock that travels with the player;
- a **world-scope** unlock for the host world.

A locked arch refuses with a readable reason ("Needs the Cloudreach Portal Key") (F18#2).

**Portal access rule (RD-21).** An arch is open for a player when the **host world or that player's character** has unlocked it. That holds for the whole session. Passing through moves only that player and their five. A behind friend can therefore follow a host through an open portal. Their own key still comes only from fighting the climax, so their progress stays honest (F48#3).

**Waystones (RD-19).** Each live biome has **3–5 waystones**, placed at existing camps and landmarks through `data/config/waystones.json` (new). Each one is a small shrine from installed families. A player activates one by walking up to it and tapping interact out of combat. The **last** waystone a character activated in a biome is that biome's portal destination. With none activated, the destination is the biome entry point: First Shore for Tidewake, Cloudreach Gate for Cloudreach and Cinder Verge for Stormwood. Waystones are not a network; the portal is the only way to travel to one. Activation is character scope, and it persists through reload and travels to other hosts (F18#3).

- **Starting placements (F18 finalizes).**
  - Tidewake: First Shore, Shellwatch, Tidal Cradle, Salt Crown and Sluice Isle camps.
  - Cloudreach: Lower Cliffs settlement, Windscar shelter, High Roost and Summit Bivouac.
  - Stormwood: Ashfoot, Lantern Pools Camp, Still Grove Shelter, Lantern Hollow Waycamp and Ember Bivouac.
- **Meadows gap (open question).** F18#3 requires Meadows waystones, but the Meadows has no portal arch. **Proposed:** the home arch doubles as the Meadows portal, sending the player to their last Meadows waystone. The candidates are the Trail camp, the Quarry camp, the Old Mill crossing, the Upper Meadows camp and the Sigil-gate waystop. This needs owner or F18 confirmation before it is built.

**Consequence of RD-18 for attrition sequences.** The Home Key works anywhere the refusal list allows. That includes the Meadows stronghold corridor ("no ordinary recovery from the Sigil gate through the Outer Works", §3.2), Veilfall and the Dynamo approach. Leaving to heal at home and returning through a waystone is therefore legal. The cost is the walk back through already-cleared ground, since cleared fights stay cleared. The no-recovery rule still governs placed beds and supplies inside those sequences. The owner is asked to confirm that this is intended, rather than a Home Key no-use zone, which RD-18 does not list.

| State | Scope | Authority | Transaction / duplication | Save and reconnect |
|---|---|---|---|---|
| Home Key grant | character | host validates the opening beat | Once per character (`home_key_granted`) | Portable; cannot be lost |
| Home Key use | character (position only) | host validates the refusal list and the destination | No resource spent | A disconnect during the raise leaves the player where they stood |
| Portal key item | character | host grants it from the climax (BOSSES §9.1) | One per participant per climax | Portable inventory |
| Portal unlock | character + host-world display | host, at the arch | Key consumed and unlocks written atomically, once | A reconnect replays or rolls back, never both |
| Waystone activation | character | host validates proximity | Idempotent | Portable; the last-activated id per biome |
| Portal destination | derived | host | — | Recomputed on use |

### 2.8 Campaign ending (RD-22; F20)

**Superseded (owner, 2026-09-29, RD-22):** the ending in Tidewake, the physical return route home and the "no fifth-chapter tease" line.

- **Tidewake closes its own chapter** with the dock exchange (§6.5). It does not roll the credits (F20#0). Nerissa's participants receive Tideglass and the Cloudreach key (§2.2).
- **Stormwood is the finale.** The sequence runs:
  1. Marrow and the Break (BOSSES §4.7).
  2. Stormheart's offer.
  3. The Spark of the Stormwood relic and the **fifth portal key** for each participant.
  4. The Long Storm ends.
  5. The objective feed prompts the player to **use the Home Key**.
  6. The player arrives in the Crossing Hall and walks up the road to the farm.
  7. Grandpa's homecoming names the current five, the starter's status, one bond memory and the player's chapter choices. It names a legendary only if that character accepted one.
  8. The credits roll **once per character**, and the player returns to the same live world (F20#1).
- **The fifth arch.** Using the fifth key at the biome-5 arch consumes the key and makes the arch *stir*: a glow, a low hum and dust. Grandpa or a Hall NPC says one line meaning *not ready yet*. The arch does not open. There is no quest, marker, cliffhanger or sequel prompt. A player may use the key before or after the homecoming (F20#2). Scope: a character receipt (`fifth_arch_stirred`) plus a host-world display, keyed once per character.
- **After credits.** Reload resumes a safe completed world. Bounties, endgame rematches, alpha respawns and research completion are available (§2.11; F20#3).
- **Co-op.** Each peer gets their own homecoming acknowledgement and credits exactly once, through disconnects and reloads (F20#4). The built character-scope flags `homecoming_seen` and `regional_credits_seen` carry over.
- **Built today, to move.** The homecoming conversation and the credits slice are built, but they are keyed to Tidewake's `water_currents_restored` (§6.5). F20 re-keys them to the Stormwood finale. It must not rebuild them.

### 2.9 Traversal assumptions by chapter order (F19#3)

A chapter may assume only what every player has been granted by then. No route may require a relic power, because only one is active at a time.

| Chapter | Available | Must not be required |
|---|---|---|
| 1 Meadows | Walking, sprint, Terrapup Ride, the Meadowhart saddle | Swimming beyond authored shallows, Fly |
| 2 Tidewake | Human swimming (§6.3), the Swim Stone and saddle as optional extras, Ripplet surface mount if owned, Dive after its L30 breakthrough | **Fly** (not learned until Cloudreach), Wings, Spark, any swim mount, Dive, catching Aquaryn |
| 3 Cloudreach | Fly (taught by Maela; Galewisp's Fly; the loaner under §4.2) | Stormheart, Spark, Dive, any Tidewake-only ability |
| 4 Stormwood | Fly, the Stormglass arches | Dive, Tidewake-only abilities, any legendary |

Tidewake rules that mention Fly, such as the sealed tide-race discs (§6.6), still apply because players can return by portal after Cloudreach. A gate-scan test proves the table (F19#3).

### 2.10 Master placement (RD-06, RD-07; F28)

**Not built (target).** BOSSES §4.13 owns each Master's fight. TRAINING §3 owns the breakthrough.

| Tier | Where (RD-10 table) | Starting site | Access | Must be reachable before |
|---|---|---|---|---|
| L10 | Mid-Meadows (River Lock/Quarry) | Old Quarry approach, off the haul road | On foot | Burrow Warrens guardian (L14) and Captain Vance |
| L20 | Upper Meadows, before the Hall approach | An Ironwood ridge off the Upper Meadows road | On foot or riding | The Sigil gate and Keeper Hald |
| L30 | An outer Tidewake island | Gull Rest (human-swimmable optional crossing) | Human swim; no mount, Fly or Dive needed | Veilfall |
| L40 | A Cloudreach high perch | High Perches, off High Roost | Fly | Officer Voss's summit approach |
| L50 | Deep Stormwood | A rod-protected storm clearing in Capacitor Grove | On foot, through storm hazard | The Deepwood fights |

- **Siting.** Each Master is off the main path and signposted from it by a physical sign and a named NPC lead. The arena is a clear, flat, collision-tested space of about **18 m radius** (starting value, `masters.json`) with room for co-op observers.
- **Order.** The "reachable before" column is the cap constraint in BOSSES §0.
- **"The Hall" means the Warden's Hall.** In this row and throughout §3, "the Hall" is the Meadows stronghold. The village hub is always "the Crossing Hall". TRAINING §3's wording "before the Crossing Hall" appears to be a slip; see the open questions.
- **Scope.** The arena is world scope (host). The win and recipe are character scope (BOSSES §4.13).

### 2.11 Repeatables (RD-31; F43, F44, F45)

**Not built (target).** **Superseded (owner, 2026-09-29, RD-31):** the former "no enemy scaling tier after the ending" and "no repeatable trainer economy" lines. These loops are optional. The main path never requires them (RD-01).

| Loop | Contract | Scope, authority and transaction |
|---|---|---|
| **Bounty board** at Halda's tournament board | **Three bounties** refresh each in-game morning, drawn only from biomes the player has unlocked (F43#0). There are four kinds: catch a creature with a named trait, defeat an alpha, deliver materials, win a rematch (F43#1). Rewards are type essence, Tether Candy, materials and an occasional Trait Seed (F43#2). Data: `data/config/bounties.json`. | Personal: each character gets their own three, rolled by the host from a per-character seed and the world day. Each bounty instance pays once under `bounty:<instance>:<character_id>`, and a reconnect cannot pay twice. Bounties survive save and reload (F43#3). |
| **Alpha respawns** | Named alphas reappear every configured number of in-game days (starting value 3, in the alpha respawn config that F44 adds) at their authored sites, with freshly rolled traits at better odds (F44#2; TRAINING §6). The first-defeat and first-catch rewards stay once-only. A caught alpha is never copied; the respawn is a new individual. | The host owns the timer and the roll (world scope). Rewards are receipts per character. The §2.5 "every player has left" rule applies. |
| **Rematches** | Tiered trainer, captain, Master and boss rematches (BOSSES §9.2). They open after the chapter's climax, at the next chapter's level, and at the endgame tier (L55–60) after the credits. | BOSSES §9.2 |
| **Research log** | At least three tasks per species that pay type essence, with a completion title per biome (TRAINING §8; F45). | TRAINING §10 |

None of these may revert a world aftermath, reopen a story gate or pay a unique reward twice.

### 2.12 Material and attuned essence nodes (RD-05, RD-33; F32)

HOMESTEAD §5 owns material identities, refining, crops and respawn timers. This section owns placement. The tier material nodes and the essence nodes are renewable. Starting respawn values are 2 in-game days for tier nodes and 3 for essence nodes (HOMESTEAD §5.1). Story pickups and caches stay once per world.

| Chapter | Tier material nodes (existing ids) | Placement rule |
|---|---|---|
| Meadows (tier 1) | rootstone, ironwood, sunleaf, plus wood, stone and fiber | Quarry and Warrens for rootstone; Upper Meadows for ironwood; along the main route and its loops |
| Tidewake (tier 2) | driftwood, reed_fiber, reef_stone, sluice_metal, tide_bloom, tide_pearl (new) | On land and in shallows on the main islands. `tide_pearl` has human-reachable reef beds on the main islands, with richer optional beds at Dive-only sunken sites (§6.7). F32#5 registers the ten `water_crafting.json` proposals at runtime. |
| Cloudreach (tier 3) | windworn_heartwood, cliffglass_ore, gale_fiber, skyplume, cloudberry | Ledges and causeways. At least one required-tier source per material must be reachable without Fly-only terrain before Windscar. |
| Stormwood (tier 4) | thunderwood, stormglass, conductor_vine, glowmoss, sparkfur, voltcap | The existing 210 harvest sites plus the 24 charged nodes |

- **Attuned essence nodes (F32#2).** Each biome holds one or two nodes per type, mostly off-route, placed with the existing harvest schema. Harvesting yields that type's essence and an `attuned_<type>` ingredient.
- **Shed drops.** Items such as skyplume and sparkfur come from wins and Den grooming (HOMESTEAD §5.4). Nothing implies hunting or butchering (F32#4).
- **Co-op.** Node depletion and respawn timers are world scope and host-owned. The harvest receipt and the items are character scope. Contention among four characters follows MULTIPLAYER's existing node rules (F32#5).
- **Ledger.** F28#5 and F47 prove that every feast and gear ingredient is reachable in or before its biome.

### 2.13 Eight-biome planning slots (RD-09)

This pass builds four biomes. The data and the hub reserve biomes 5–8:

- `biome_order.json` reserves `biome5`–`biome8`, each with the display name "Sealed".
- The Crossing Hall has 4 dormant arches and 4 dark pedestals.
- The material, gear and attachment schemas hold 8 tiers.
- The level caps `[70, 80, 90, 100]` are reserved.

Nothing in this pass names, dates or promises a fifth biome. The only acknowledgement is the fifth arch's stir (§2.8). Reserved slots never block the four-chapter release.

## 3. Chapter 1 — The Meadows

### 3.1 Geography and cadence

The authored envelope is x **−1024…1024**, z **−512…7680**, about **16.78 km²**. Its spine is **11,594 m** by the archived segment formula:

`96 Home + 2,384 Band 1 + 2,653 Band 2 + 2,372 Band 3 + 3,436 Band 4 + 651 approach`.

That equals 38.6 minutes at 5 m/s walking. The corrected sprint cycle is 8.33 seconds sprint plus 6.67 seconds recovery, about 7.0 m/s sustained and 27.6 minutes for the spine. These are route-length checks, not playtime claims.

The route includes ten named local loops, the quarry haul-road shortcut and the river ferry/reconnection. A meaningful sight, encounter or decision should occur every **150–250 m**; no 250 m route window should lack a beat within 40 m. Four authored camp-place decisions sit roughly three kilometres apart. Perimeter treatment must read as distant country, water, ridge or forest rather than an invisible wall.

The live Bible's 11,518 m value conflicts with the archived segment sum by 76 m. Re-measure the current spine before either value becomes acceptance truth.

### 3.2 Story route

**Home and village.** The opening cannot be skipped. Grandpa gives the starter choice, the player names the creature, learns a real fight and physical catch, and understands that the team is being built for a journey. The tournament is an eight-slot bracket with three player-played fights and four simulated entrants around the player. **Current source** requires a five-creature party, level 5 and care readiness, and `progression.json.home.required_pieces` asks for tent, campfire, bedroll and one creature bed. **Owner target:** three usable creature beds must be present before bracket entry; this deliberately exceeds the current one-bed source and needs implementation/economy reconciliation. The target order places the South Bridge grunt before Oskar's final, teaches the saddle recipe early enough to use it in the chapter, and lets Oskar's Meadowhart final demonstrate the mount payoff. Current source/probe order still completes the tournament before `south_bridge_grunt`, so that reordering is not built. A tournament loss heals the entered team and permits a clean retry without duplicating bracket rewards.

**Village form is fixed for this pass.** Rebuild the existing footprint as a road settlement, not the old compact radial/circular arrangement. A traversable through-road must connect the home/opening side to the South Bridge exit, with at least one visible side lane that leads to the berry field, grove or stone-working area. Face house fronts/doors and civic activity onto those roads; vary roof lines and building setbacks so the approach, centre and departure read as different silhouettes. Keep at most five street villagers, all required interactions, protected starter/tournament/camp flow and every authored boundary gate. Roads at the boundary have working gates; other edges are dressed and cannot be bypassed. The new geometry may move buildings, paths and props but must preserve stable IDs, saves, quest triggers and accessibility. **Acceptance:** compare a labelled overhead plan of old/new traversable road topology, then walk home→centre→bridge and one side lane with the normal camera and controller at day and night; verify that the three named subareas and exit are visible without map overlays, all key interactions and NPCs are reachable, no path or gate can be skirted, and save/reload/co-op peers see the same layout. A paint or prop pass on the former circular road plan fails this criterion.

**Current village shape (owner-picked option B, 2026-09-29).** One straight main street runs north-south at x = 10.5 from the z = -16 crossroads (Grandpa's cross lane, the Rise lane and Stoneyard Lane) to z = 2, where the Pond lane and South Street to TrailGate leave it. Houses line both sides. The well stands on the street axis at (10.5, -6) in the middle of a small walkable green (radius about 4 m, no collision, existing grass and the 0.9 m square flat). The inn (-2.5, -6, turned 90 degrees) and the stone cottage (19.5, -6, turned to face west) look onto the green and street; Mira's shop, Oskar's pen, Tam's workshop, Halda, the bracket board and Grandpa's house did not move. Data: `terrain_playground.json` `paths` and `building_aprons`, `village.json`; pinned by `tests/test_village_main_street.gd`.

**Target village road (owner, 2026-09-29, RD-17, RD-29; F17). Not built.** The village stays inside the Meadows and becomes **one straight road**:

- **Homestead at the start.** Grandpa's farm, now the homestead plot (HOMESTEAD §2), sits at the start of the road beside the Meadows exit and the South Bridge road.
- **Houses on both sides.** Eight to ten MegaKit houses face the road on both sides. They hold Mira's shop, Tam's workshop, the inn, Halda's tournament board with the bounty board (§2.11) and the arena lawn, the research keeper, and named residents from the installed cast.
- **Crossing Hall at the end.** The Hall caps the far end of the road (§2.6) and is visible from the farm.

Every house has a named resident or lived-in dressing (F17#3). **Superseded (RD-29):** the former ceiling of five street villagers. The resident count follows the installed cast, and residents can be at doors or inside.

**What changes from the built street.** The built street already runs straight. It puts Grandpa's house at the northern crossroads and the exit at the southern end, which is the opposite of RD-29, where the homestead sits by the exit and the Hall at the far end. F17 therefore either moves the farmhouse to the exit end or re-routes the exit. It keeps Grandpa's farmhouse as the homestead anchor and pins any new position in tests.

**What F17 must preserve.** Stable IDs, the South Bridge route, every authored boundary gate and the whole M1 opening chain (starter, practice catch, camp, three-bed readiness, three tournament rounds) must survive (F17#4). F17 re-bakes terrain and scatter for the village pad only. The acceptance walk in the paragraph above still applies to the new plan, together with F17#0–#6.

**Naming.** In this chapter "the Hall" and "Hall approach" mean the Warden's stronghold. The village hub is always "the Crossing Hall".

**Lower Meadows.** Broad readable grassland, local habitats, trainers and the first voluntary detours lead to the South Bridge. The bridge opens through story/trainer progression, never a floating level message.

**Stone & Root.** The Old Quarry and Burrow Warrens introduce Rootstone, stronger Ground creatures and the required compact dungeon. The L14 guardian controls the visible vault door; victory opens the Heartstone, Greater Orbs, Rootstone and useful equipment branch. Disabling later machinery can restore the quarry's live vegetation and fittings, but its baked colour/control-map scar cannot repaint at runtime. An aftermath NPC must explain that visible remainder instead of letting it read as a failed world change.

**River Lock.** A substantial river is a physical divider. Team Tether holds the Old Mill crossing and a captive. The route escalates pickets → Officer Dell → Captain Vance. Victory frees the captive, disables the relay and restores the crossing.

**Upper Meadows.** High pasture, old growth, ridges and Ironwood lead through three regional captains. Meadowhart and the saddle pay off riding. Oreth, Halder and Vess grant the three Sigils that physically open the Hall approach.

**Hall approach and stronghold.** The Hall grows in the view while hardware, drained land and patrols intensify. Band 5 is deliberately short and cannot be padded to extend the clock. Three basic road supplies support preparation, while the final waystop communicates the consecutive garrison and shows one last optional elder without providing healing. There is no ordinary recovery from the Sigil gate through the Outer Works except authored rare rewards; the bed after Hald remains the final legal recovery before Aldis. The interior sequence is Outer Works → Courtyard → Chamber Approach → Warden Arena → Legendary Chamber.

Warden Aldis believes separation prevents disaster; he warns and does not recant. Defeating his full five opens the tether. The player frees the Veridian Stag, resolves its voluntary offer, and watches the region heal. Team Tether recedes, rescued people return, and the Heart and existing Cloudreach key entitlement are awarded. The rift first holds, then dissipates across the storm-road carve while a physical bridge grows through it. This is the Meadows-to-Cloudreach return gate; it is not a Meadows portal or menu teleport.

If every eligible participant refuses the Veridian offer, an unengageable Stag appears among the healed Highfield herd after the climax. If any participant accepts, that world display is absent; each refuser still receives the personal refusal journal result and the shared healing. The display never reopens the offer, becomes catchable or pays another reward. Verify solo refusal, mixed co-op choices, save/reload and reconnect against the exact world and character receipts.

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

The final encounter combines Veyra's three-creature team with a separate movement exam: pilot a creature through collapsing wind lanes and strike three exposed relays. After Veyra falls, the players free the captive Solmane, which volunteers to each finale participant under §2.3 (owner, 2026-09-27); it is never wild or catchable, and the summit wild tables use tempestwing. Restored wind reconnects settlements and routes. Aila grants Wings, the Stormwood key and a Stormward overlook showing the non-enterable forest and distant water.

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

The chapter requires at least four loops, three far-side shortcuts, five dead-end pockets and two alternate routes between consecutive regions after region 2. Every principal landmark must read from a neighboring region. These remain release constraints, not prerequisites for the initial brief loop check.

Interpretation settled under the spec-freeze delegation (STATE):
- **Far-side shortcuts.** The three are the optional ancient arch pairs C and D and the player-built Raise a Road pair. Mandatory story arches A and B do not count.
- **Alternate routes.** Where a connection is arch-only or single-pass by design (Crown 3→4; Rootgate 3→5), the arch is the second route. The two-route rule otherwise applies to walkable regional connections, and 5→6 needs a second walkable road.
- **Dead-end pockets.** A pocket is a physically bounded optional space with one entry and a reward. A walled clearing built from installed static walls or deadwood, with an existing reward pickup moved inside, qualifies. A pickup grid point alone does not.

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

Contract floor: 16 landmarks and 330 wild clusters. The recovered floor allowed Hollow Crown only 12 clusters; the **selected target supersedes that exception** with at least 40 wild clusters in each of all six regions. Require 12 Calm/Surge tables with at least three roles in every table, six named wilds, 26 trainers, 18 NPCs plus the Crown resident, three inhabited settlements with 4/4/8 residents, six safe camps, ten rod clearings, 210 harvests, 24 charged nodes, 200–230 pickups with at least 80% off the principal path, 24–30 objectives, six side chains of at least three steps, four buildables, six resources and at least 12 recipes. Ordinary Hollow Crown opposition caps at L40; its named guardian may exceed that cap, and Captain Marrow's ace remains L44. These remain release constraints, not prerequisites for the initial brief loop check.

The four authored Stormwood TMs retain their source power bands: 1.15 quick, 1.30 charged and the two stronger authored values 1.60 and 2.00. They are chapter rewards, not permission to replace the global 1.25/0.80 type graph.

Current config contains six regions, 19 landmarks, 15 top-level route records, 401 wild clusters, 12 tables, six named fights, 26 trainers, 19 characters, 229 pickups, 210 harvest sites and six side chains.

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

The first four exposed gaps were historically measured at **80.00 m, 104.13 m, 90.74 m and 109.02 m** across the early route samples. Those source measurements must be remeasured against the baked production shore before becoming current acceptance truth. Late gaps are 400–660 m. The chapter requires four land loops, three return shortcuts, eight reward pockets, at least 8 km land routes and 2 km water routes. Each of the eight main islands provides a camp at least 7 m inland from its legal landing. Shallows are slopes, beaches are landings and currents/cliffs explain every gate. Adjacent gentle beaches may not bypass a dock or story boundary. These remain release constraints, not prerequisites for the initial brief loop check.

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

Mount exhaustion costs 3 HP/s. Tidecoil and the Guardian are never mounts. **Owner-retained-team override:** an owned swimmer is never mandatory on the critical path. The player can finish with the five they already love. Human-swim routes and safe shore anchors must satisfy the baseline reserve/steering bar above; swim mounts improve speed, convenience and marked optional routes. This supersedes the earlier mandatory-mount wording, not the five-creature cap or no-boats rule. The previous blanket early0.35–0.70/late1.0–1.8m/s current range is superseded for mandatory sheltered routes: retain their actual source strengths0.08 early,0.2 Cradle/Crown and0.3 Sluice/Veilfall. Direct and optional currents retain their individual source tuning. A mounted save/load must restore the same creature identity and remaining traversal stamina. If that lawful rider/mount state cannot be reconstructed, use the last validated shore/anchor and preserve the lower available resource state; the fallback may not refill either human or creature stamina.

**Human route implementation: partial; baked floor and two bounded body crossings pass, full-route and physical-gate acceptance remain open.** Keep the twelve named islands and existing shared story gates. Seventeen small terrain shoals divide the sheltered crossings: one each on Reedhaven→Brine Steps, Brine Steps→Shellwatch and Shellwatch→Cradle; four Cradle→Salt Crown, four Crown→Sluice and six Sluice→Veilfall. First Shore→Reedhaven remains a continuous swim. Each shoal has20m shoreline radius,1.5m dry centre,19m gentle beach and a6m safe-anchor radius. `water_world.json::rest_shoals` is separate from inhabited islands and binds each shoal to an existing parent island. `water_heightfield.gd` and the committed Terrain3D bake supply real floor; an anchor or decorative rock alone cannot qualify.

The player sees the next stone-and-torch marker, swims to dry ground, and recovers through ordinary land stamina regeneration. There is no arrival refill, healing, camp service, reward, new catch or new progression flag. Keep the clear landing centre unobstructed. Sheltered route/current polylines and ordered `rest_anchor_ids` must agree. The three late direct routes remain optional mounted alternatives. The Cradle departure opens on existing shared `water_aquaryn_resolved`, earned by catch **or defeat**; personal Swim Stone/saddle checks must not gate the human departure. Other dock flags retain their order. Validate each water leg with full adverse current,15% steering and acceleration/shallow transition allowance against≥20% reserve; actual body/floor recovery and a closed-gate flank check remain required. Closed gates seal the land behind them with a visible tide race (§6.6); an optional mount or Fly cannot open an uncleared gate. Out of scope: boats, teleport crossings, floating invisible platforms, extra camps/island quests, stronger baseline swimming, inferred gate acceptance or chapter completion from route arithmetic.

### 6.4 Skills

The only global skills are Running, Catching, Riding, Swimming and Flying. Cap is 30; next level costs `100 + 30 × current level`. XP comes from real movement or a legal host-confirmed catch, never idle/menu time or fabricated history. Catching progress is portable character state; an old save with no receipt starts at 0 Catching XP. The host clamps the legal award; catch probability replicates only the resulting Catching level, not client-asserted XP, fractional progress or odds. Portable saves retain actual local progress. Skill Candy grants 1/2/3 levels, keeps fractional progress and refuses the whole consumption if any level would exceed cap. Twelve placements use a 7/4/1 tier split.

### 6.5 Story route and ending

**Broken Channels.** Dockkeeper Mara receives the group. Pell teaches the calm-water lesson. Reedhaven repairs its pier, Brine Steps asks for a trainer demonstration, and Shellwatch opens after its residents are freed and its pump disabled. Iona identifies the captive Guardian and the route forward.

**A Back Across the Sea.** L49 Aquaryn alternates Shore Crest, Tidal Run and Broken Wake. Catch or defeat resolves one shared encounter and awards eligible participants a personal Swim Stone. A catch journals the stable catcher identity and exact creature before confirming the shared result; it cannot insert a sixth creature or use a transient peer ID as ownership. Iona teaches the optional saddle recipe. The main journal follows shared `water_aquaryn_resolved`; personal Stone/recipe entitlement appears separately as an optional hint. Catching Aquaryn or owning a swimmer is never required to continue.

**Behind the Veil.** The party disables two Sluice controls, provisions at the Sluice Isle camp and crosses to Veilfall. Lastlight supplies recovery on Veilfall before the climb. Officer Venn guards the climb. Inside, two ordered controls open the channel to Captain Nerissa. Her defeat permits release of the L55 Abyssal Guardian and the voluntary five-slot ceremony. Tideglass is earned for placement at the Meadows home circle; the currents return and NPC dialogue changes across the archipelago. L54 Tidecoil remains an optional deep-water apex.

**Regional conclusion.** Restored currents break Team Tether's regional supply monopoly. Docks reopen as civilian exchange points: Reedhaven, Shellwatch, Salt Crown and surviving Rodfolk/Cloudreach contacts can move people, medicine and ordinary goods without Tether permission. The result is shown through changed dock use, named NPC aftermath lines and a final shared departure, not an economy simulation.

The party returns through the reopened route to Grandpa's home. Grandpa acknowledges the specific five companions present, including a legendary only if that character actually accepted one. The final scene recognizes released companions without reversing the choice, confirms that this regional road is free, and rolls credits. The wider eight-force cosmology remains in existing lore; the homecoming has no post-credits sequel sting, invented count of unresolved forces or fifth-chapter prompt.

**Return guidance, partial:** once this world's currents are restored, the
current main-story feed becomes two personal acknowledgements: bring the
current companions home (`homecoming_seen`), then finish credits
(`regional_credits_seen`). HUD, journal, map marker and world beacon use one
realm-aware reader in `quest_log.gd`; `regional_ending_objectives.json` owns
the destinations/prose. Earlier personal tasks are not awarded by this feed
change, and Local Requests remain available. Completed credits clear the
active ending marker; another unfinished world resumes its ordinary chapter
feed. Mara's First Shore afterword describes civilian supplies/couriers and
names the route home; hearing it is optional and writes no progression.

The current physical route is First Shore's Stormwood passage, Stormwood's
Cloudreach return gate, Cloudreach's Meadows return gate, then Grandpa's home.
No new gate, ferry, party teleport, mandatory catch or companion replacement
is added. The configured gate endpoints imply roughly19km across the three
return realms before counting Water crossings or actual route bends. The
existing physical return is the selected four-chapter ending route. Do not
add a teleport, ferry or new gate solely to shorten it. Apply already-authored
far-side shortcuts where legally unlocked. The homeward return is exempt from
A7 and needs no activity spacing (owner, 2026-09-27); T3/F15 still require the
physical return, Grandpa, credits and reload clauses. Cut repeated compulsory fights and dead travel
by improving that route within its existing gate network; do not claim the
ending accepted from a waypoint jump. Physical civilian exchange/shared departure,
the earned continuous return and the complete ending remain separate gates.

### 6.6 Content and status

Current data has 12 islands, six regions, 18 landmarks, four land loops, 12 land-route records, 22 water-route/current records, three shortcuts, eight pockets, 303 wild-site rows, 16 tables, five data-named encounters, 24 trainers, 18 NPCs, 182 harvest rows and 200 pickups. It now has 11 main objective rows and one optional saddle-recipe hint; no local objective chains are complete. Six to ten chapter-level optional activities therefore require authored packaging of existing islands/fights/rewards rather than more scatter. This packaging remains release content, not a prerequisite for the initial brief loop check.

The recovered content target was 240 wild clusters, 16 tables, **six** data-named encounters, 24 trainers split 12 critical/12 optional, 18 NPCs, three settlements, eight camps, 160 harvests, 200 pickups with at least 80% off the principal route, 28–32 objectives, six side chains, at least 150 dialogue lines, five resources, ten recipes and ten current routes. These are provenance, not new release quotas. Current data has five existing data-named encounters; retain and differentiate them rather than add a sixth row for its own sake. Aquaryn already supplies a major optional-capture test and the non-combat Guardian offer remains distinct. The six local chains in §11 are candidates after the initial brief loop check, not prerequisites for the four-biome pass.

WaterChapter, Veilfall, Aquaryn, Nerissa, Guardian ceremony, relic award and restored-current state are landed and focused-tested. Continuous opening through Iona passed from a disclosed synthetic L44 party. The late one-creature diagnostic failed during Nerissa and proves neither normal difficulty nor a full ending. The return gates exist. **Card T3 passed** (batch 67, `ralph/reports/TIDEWAKE/full/card_t3/`): in one two-peer run the dock exchange charges once, each peer keeps its own legendary choice, Grandpa names each current team, credits roll once and reload shows no fifth key or sequel prompt; shortcuts are disclosed there. Implementation detail (landed from the former `ralph/regional-homecoming` branch): the existing Grandpa prompt gains a partial homecoming conversation after current-world `water_currents_restored`: it names the current local party, including nicknames, without recreating former companions. Natural conversation completion saves only that character's `homecoming_seen`; interruption or failed save permits retry. A brief repeat greeting follows successful acknowledgement. The subsequent credits slice (former `ralph/regional-credits`) opens a local, skippable roll after saved normal completion, or after the repeat greeting for an older acknowledged save. Continue/Skip saves player-scoped `regional_credits_seen`; save refusal permits retry. It returns to the same live world without party changes or global pause. UX§2.6 owns timings/input and `data/config/regional_credits.json` the credit content. This does not teleport the party or award a relic. Source: `scripts/story/regional_homecoming.gd`, `sequence_director.gd`, `data/dialogue/homecoming.json`, player scope in `data/progression/flag_scopes.json`.

**Gate integration and known defect.** `water_characters.json` requires the Salt Crown chart before Bex/Calder; `water_dock_actions.json` requires that chart plus the corresponding trainer victory for each Sluice control. `water_veilfall.json::controls[intake_pump].requires` demands the combined Sluice completion before the existing ordered interior chain. These are host-checked story prerequisites, not physical gate acceptance. Existing completed flags are not revoked. While a mandatory dock is uncleared, every island and rest shoal behind it is ringed by a visible outward tide race (12 m/s, shoreline to 16 m offshore; `water_swimming.json::docks.seal_race`), faster than any swimmer or swim mount; Fly treats the same discs as sealed routes. A seal opens with its landform's own dock fact or any later fact on a chain through it. The reproduced Cradle flank is closed analytically and by a single-player runtime smoke (`smoke_water_closed_gate_seal.gd`); swimmer-height readability failed code-blind judges and stays open under F13, and runtime Fly, network-guest and mounted flanks are unexercised. A separate open-gate movement-only run reached the first shoal centre and recovered normally; this does not accept every crossing. Preserve visible current/cliff/dock causality; an invisible ocean wall is out of scope. Exact setup, positions, evidence and limits: `ralph/reports/WATER-HUMAN-ROUTE/REPORT.md`.

## 7. Multiplayer world behavior

One shared world can contain players in different realms. World changes, gates, docks, pumps, bosses, one-time pickups and legendary offers are host transactions. Character skills, party, portable inventory, personal unlocks, pose and per-creature traversal stamina travel with the character.

Mixed-realm simulation must not remove terrain, bosses or Veilfall state needed by another player. A gate spend and unlock is atomic. A disconnect during a boss, flight or crossing restores a saved safe state without granting progress. Late join reconstructs all chapter aftermath before enabling interaction.

The campaign requires 1–4 player smoke coverage, including two players on separate islands, host in another realm, simultaneous combat/traversal, competing gate/dock actions, per-participant legendary settlement and reconnect during a crossing.

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
- Copying one creature instance or one character's offer receipt to peers; each actual fight participant receives their own independently journaled offer under §2.3.
- Claiming that data counts prove route quality, emotional attachment or commercial visuals.

## 10. Acceptance boundary

A chapter is **built** when source/configs mount its systems, **integrated** when its ordered state and rewards work together, **continuously earned** when ordinary actions traverse it without state injection, and **accepted** only after the agent-piloted and independent-review evidence in ACCEPTANCE covers route comprehension, optional content, recovery, major fights and the intended aftermath. Real-player preference remains unmeasured without people.

Before expanding content, run one 15–30 minute agent-piloted expedition through existing systems. It checks movement, route reading, catching, direct creature combat, switching, recovery and co-op against observable criteria. The L4 skill, Strain, revised bond and normalized poise are outside this four-chapter completion pass unless the spec is explicitly revised from a failed witness; do not create a repeated cohort or harness programme.

Release verification still requires the relevant target regression, network and save/reconnect tests, including a fresh earned four-chapter save and solo/co-op witnesses for the final route. Automated walkers may prove reachability and persistence; ordinary player-camera motion and independent agent review judge presentation. Felt attachment remains unmeasured without human players, but retaining the same five companions for the full campaign is a valid route and later catches remain optional.

Primary recovered provenance is indexed file by file in `ralph/reports/PLAN-REWRITE/FINDINGS.md` B01–B33 and its archive coverage table. Current implementation evidence lives under `data/config/`, `scripts/world/`, `scripts/combat/`, `scripts/player/` and `tests/`. Archive paths were sparse-excluded from this worktree, so the checked-in recovery index is the resolvable citation rather than a nonexistent local archive path.

## 11. Minimum optional-activity implementation ledger

This is the **selected release content**, not a claim that current rows already qualify as complete activities. It is not a prerequisite for the initial brief loop check. Prefer rewards that strengthen the retained five. Existing object/quest/defeat IDs retain their flags and reward receipts. New wrapper flags below are **target IDs, not built**; declare world completion and per-character reward scope before implementation. A wrapper cannot pay an item already awarded by its source pickup/quest. Claim existing pickups through their original receipt. These activities replace the inflated per-subregion quota and do not add a second quest engine.

Shared state: hidden → discovered (physical lure/NPC knowledge) → in progress → action complete → acknowledged/rewarded. No timers, repeatable payout or abandon penalty. Existing valid actions count even if done before the conversation. On failure retain discoveries and item claims, reset only the encounter/attempt. Every target has a3–10minute detour budget beyond its approach; a longer multi-region chain accrues while traveling the main route, not in a mandatory return trip. A reward blocked by full inventory stays pending at its original authority rather than disappearing. No optional objective gates the main story.

### Meadows — eight selected activities

Source foundations are the seven local rows in `data/progression/objectives.json`, band trainer/spawn/pickup records and `scripts/world/burrow_warrens.gd`. These are **partial activity foundations**: qualifying discoverability, useful reward and acknowledgement require ordinary-play evidence.

| Region / source identity | Lure and exact completion action | Target payoff / count boundary |
|---|---|---|
| Lower Meadows: Old Bram / `band1_old_champion` | Meet the champion in the eastern fields; win his two-creature fight. | Existing one-time trainer reward plus his Pond-alpha direction/map knowledge. Count fight once; alpha is separate only if player subsequently resolves it. |
| Lower Meadows: herd / `band1_meadowhart_herd` | Rae looks west toward the existing herd; approach the actual herd within12m with a companion, not merely finish Rae's greeting. | Personal landmark/bond visit, a once-only two Small Potions and one Revive (built; F03#2 usefulness judge 6/6) and a plain saddle/traversal lead. Completion is the herd visit, not Rae's greeting; no duplicate herd spawn. |
| Lower Meadows: cart / `band1_broken_cart` | Damaged cart visible off bridge road; Coll speaks through its existing dialogue. Deliver the source item-gate cost once. | Partially built (landed from the former `ralph/meadows-payoffs` branch): the wagon straightens, gains installed timber/rope repair details and moves farther onto the shoulder with its collision. Cart-only pose metadata lives in `building_prefabs.json::prefabs.cart_repair_patch.presentation`. No new currency/item payout or road unlock. Coll has no world body; the earlier visible-Coll wording overstated the source and would require a separate permitted cast-placement decision. |
| Stone & Root: Night Watch / `band2_night_watch` | Farro describes stirred Duskhush; meet him at night and win once. | Existing trainer reward, revealed Duskhush habitat and daylight acknowledgement. Waiting for night is optional; no main gate. |
| Stone & Root: Warrens branch | See the branch-vault light beyond the required guardian; take the optional Elder Trailpup branch and resolve its existing encounter. | Existing branch rewards/evolution catalyst access, never a second main-guardian credit. Keep each pickup's original claim. |
| River Lock: nest / `band3_river_nest` | Doss's blocked bank is visible from the river loop; pay current wood/fiber repair resolution once. | Restored bank access and existing reward. Target present it as clearing/rebuilding a bank perch, not a nonexistent hunting fight or playable fishing system. |
| Upper Meadows: lost companion / `band4_lost_creature` | Follow missing-Meadowhart lead; defeat the named Tether patrol. | Actual reunited NPC/creature presentation and existing reward; never award the rescued creature to the player. Ironwood's Juno→Halder story remains additional optional interpretation, not counted twice as main-Sigil victory. |
| Hall approach: off-road elder | Visible rare habitat/alpha pin at one existing band5off-road site; catch or defeat that existing alpha. | Current once-only alpha reward/possible team choice, map marker clears; no new road fight/cache/bed. This is the required band5detour and respects its short attrition corridor. |

The Pond alpha and Ironwood story can raise Meadows to10activities if their full qualification passes; neither is required to pad the floor. The current herd greeting alone and simple discovery counter do not qualify until the action/payoff above is integrated.

**Herd implementation:** PR134 added the physical companion visit and a separate once-only item claim, now two Small Potions and one Revive (`objectives.json` `visit.rewards`: one `reward_grant` per part with source `meadowhart_herd_visit:<item>`, the completion flag on the last). It replaced the former three Basic Orbs, which the F03#2 judge found catch-only and of no use to the retained five. The herd landmark payoff (former `ralph/herd-landmark-payoff`) adds the personal `meadowhart_grazing_ground` landmark, resolved from merged spawn order1005. Walking past alone or speaking to Rae cannot discover it. Activating the watch with player and companion within12m discovers it once and credits each currently owned member through existing bond counters. A full satchel leaves the item claim pending without withholding discovery. Legacy completed visits, including those paid the old Orbs, can earn this new discovery by actually revisiting, without a second item payout. No new bond thresholds, per-creature landmark receipts, creatures or saddle unlock are added; Rae's existing Oskar/saddle lead remains. Source: `scripts/world/meadowhart_herd_visit.gd`, `map_state.gd`, `map_landmarks.json`, the objective's `visit.landmark_id`; focused and runtime evidence belongs in MEADOWS-PAYOFFS. Ordinary approach/visual qualification and full network acceptance remain open; this does not yet qualify the activity toward the six-activity minimum.

**Lost companion implementation (landed from the former `ralph/lost-companion-reunion` branch), partial:**
the previously unnamed owner is Juno, the existing high-pasture drover; this
deliberately completes the former patrol-only account with an existing cast
member. Her ordinary challenge/greeting supplies the missing-companion lead
and the existing `lost_creature_rue_met` reveal. The patrol's existing victory
flag moves one standard-size, noncombat Meadowhart display from beside that
patrol to beside Juno. Juno's dialogue then acknowledges the reunion while
preserving her own optional battle and First Ironwood lead. Patrol reward
remains50coins/one Revive through its existing authority. No rescued creature
joins the player's party. Saved world state reconstructs the corresponding
display; there is no new completion or payout flag.

Source: `lost_companion_reunion.gd` and its config, the narrow world mount,
`trainer_npc.gd::conversation_for`, Juno's `dialogue_after` config, existing
trainer/band dialogue and `objectives.json`. Out of scope: an escort simulation,
new NPC/model, capture, additional payment or progress gate. This discrete
world consequence does not claim to simulate the journey between the two
sites. Ordinary approach/discoverability, full co-op reward acceptance and
chapter-level activity qualification remain open; see MEADOWS-PAYOFFS report.

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

**Not built as local chains:** `water_objectives.json::local` contains one optional saddle-recipe hint, not any of the six three-step chains below. Foundations are `water_world.json` islands/pockets/return shortcuts, `water_characters.json` installed NPCs and existing pickup/camp/encounter consumers. These target wrappers supply the missing authored actions and consequences rather than another200scatter pickups. Each has three recorded steps; the Swim Stone/saddle reward route remains independent and cannot gate the human-swim critical path.

| Target chain / region | Three actions, lure and constraints | Payoff |
|---|---|---|
| `side_water_lantern_return` / First Shores | Pell points to Lantern Cove's visible rock arch; swim the optional legal route; claim `lantern_hidden_cache` and return to the First Shore landing. | Existing Skill CandyI pocket via original receipt; personal return-route knowledge and Pell acknowledgement. No extra candy. |
| `side_water_gull_research` / Marsh Channels | Adair names Gull Rest; reach researcher/satchel via safe optional crossing; return the recorded observations on next Brine Steps passage. | Existing `gull_research_satchel` Skill CandyII plus charted safe route. Satchel is quest flag; cannot be sold/lost as a second inventory object. |
| `side_water_cradle_care` / Tidal Cradle | Otto points to `cradle_shell_nest`; reach the dry nest and gather4Reef Stone; return to Otto with a legal owned swimmer or after declining Aquaryn. |4Reef Stone remain with player plus3berries, once, and explicit alternate-swimmer habitat/map lead. No requirement to catch Aquaryn or sixth-slot staging. |
| `side_water_garden_records` / Outer Reaches | Edda points to visible above-water Drowned Garden vault; reach via lawful mount route; bring the recorded wall account back to Salt Crown. | Existing `garden_exposed_vault` Skill CandyII and Edda explains pre-Tether dock history. No diving/oxygen and no generic chest-only conclusion. |
| `side_water_deep_watch_chart` / Tether Current | Orsen names Deep Watch; resolve optional Tidecoil by catch/defeat; operate the separate chart/return-current control. | Existing Skill CandyIII pocket plus source return-current shortcut; victory alone does not silently flip the chart flag. |
| `side_water_lastlight_shelter` / Veilfall exterior | Halen reveals a sheltered route beside Lastlight; deliver4Driftwood+4Reed Fibre to the existing legal camp; rest one assigned companion there before or after Venn. | One permanent shared sheltered creature-bed site and Halen acknowledgement. No access to interior before controls/Nerissa; resources placed on exterior side; optional cost must leave the resources needed for a saddle available to a player who chooses mounted travel. |

Additional pocket/alpha content is welcome up to10qualified activities per chapter, but does not take priority over these six, the ending or combat. Recipe and item identifiers must resolve through existing item databases at implementation; new wrapper state is explicitly named above, all geographic subjects already exist, and any unverified placement must be walked from its real approach before it is accepted.
