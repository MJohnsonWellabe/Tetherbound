# Rejoin audit: guest grants that the host's held record does not carry

This audit is the evidence behind the owner ruling "co-op rejoin: guest wins unless behind" (2026-10-05, STATE §0).

**Method.**
- An independent agent read the code (read-only) at `tb/f17` 83cb8cb1.
- For each path where a co-op guest gains or changes something, it asked one question: does the host's held record for that guest (`character_authority._records`) receive the result?
- Verdicts:
  - **A**: yes, through a host action, owner-passive replay or reward-delivery replay.
  - **B**: no, the change is on the guest's side only.
  - **C**: a co-op guest cannot reach this path.

**Context.**
- **Why it was run:** #544 first made a returning guest adopt the host's held record ("held record wins"). CI then lost data:
  - `smoke_net_veridian_choices`: an accepted legendary disappeared.
  - `smoke_net_home_creature_bed`: a bed heal and a fixture starter disappeared.
  
  The rejoin change was reverted in 83cb8cb1.
- **Under the new ruling:** the B cases below are kept on rejoin. A guest-side grant carries no host receipt, so the guest's record is not "behind". It is lost only if the record is also behind for another reason.

## Findings

| # | Path | Verdict | Evidence | Under "held record wins" |
|---|---|---|---|---|
| 1a | Ordinary catch, free slot (`encounter_director.gd:7002`, `tab_creatures.gd:1968`) | B | `_resolve_catch` adds the creature locally. For a guest, the host journals only a research or bounty duty (`session.gd:782-815`) | The caught creature is lost |
| 1b | `foundation_capture` / `capture_gate` / `install_owner_capture_roster` | C today, A when enabled | Needs `foundation_capture_traits` from an alpha body. `alpha_respawns.json` `runtime_enabled: false`. When enabled, `wild_capture` stages `_replace_record` | — |
| 2 | Full-belt release, paid (`essence_release_service.gd:375`) | Partly A | The host's `essence_release` removes the released creature and pays essence. Adding the newcomer is local only | The newcomer is lost; the belt is one short |
| 2 | Full-belt release, unpaid (`essence_release_service.gd:334`) | B | Local `remove_at` and `add` | The released creature comes back; the newcomer is lost |
| 3 | Legacy release ceremony (`tab_creatures.gd:2619`) | B | Plain local add | As row 2 |
| 4 | Stormwood legendary Fulgocobra (`stormwood_ending.gd:586`) | B locally; a world receipt exists | `stormwood:legendary_resolution:accepted:<character>` is written through the ledger | Lost unless vouched. Edge case: a disconnect before `ending_settled` leaves no receipt |
| 4b | Meadows Veridian / Cloudreach Solmane (`stronghold_climax.gd:1402`) | B locally; a world receipt exists | `legendary_resolution:accepted:<character>` (CI 37389014698, `veridian_choices`) | Lost |
| 5 | Late-arrival starter (`sequence_director.gd:2227`, via `_hand_a_late_arrival_a_companion`) | B (reachable) | A joiner with an empty party in a world that has moved on. Also sets the player flag `opening:starter_granted` | **Worst case:** the starter is lost, and the flag keeps it from ever being granted again. Zero creatures |
| 5b | Opening starter adoption (`sequence_director.gd:1924`) | C for a guest | `commit_original_starter` returns false when not host | — |
| 6 | Oskar's creature swap (`creature_trade.gd:148`) | B | Local remove and add, plus a player flag | The old creature comes back, Oskar's is lost, and the swap stays used up |
| 7 | Tidewake Aquaryn / Guardian claims (`water_capture_transaction.gd:45/51`) | B | `settle` is local; "the host never adds to a guest's party" (`water_capture_claims.gd:398-408`) | Lost |
| 7b | Tidewake legendary (`water_guardian_reward.gd`, `water_abyssal_guardian`) | B, no receipt | Nothing writes `tidewake:legendary_resolution:*`. The only record is `water_claim:guardian:offered:<sha256>`, which is the same for accept, refuse or ack | Lost, and no receipt can vouch for it |
| 8 | Dialogue gifts (`sequence_director._give_items:1159`) | B | Local `inventory.add`. Examples: Mira's tools and coin, Tam's tools, Nessa's berries, Sela's `mill_bridge_gear`, Grandpa's pack. All gated by player flags | Lost and never offered again. Losing `mill_bridge_gear` can block the crossing |
| 8 | Tournament round rewards | B | Rounds are excluded from host routing (`encounter_director.gd:8043`); paid locally | Coins and items lost |
| 8 | Other trainer victories | A | `trainer_victory` goes to the host, which journals per-character deliveries | — |
| 8 | Field crafting (`game_state.craft`, `field_allowed`) | B | Local debit and grant. Station crafts are A | Crafted items lost, materials restored |
| 8 | Shop buy and sell (`trade_db.gd:140-190`) | B | Local | Rolled back |
| 8 | Shared chest (`storage_container._settle:244`) | B | Only the chest side rides the ledger | Withdrawals destroyed; deposits duplicated |
| 8 | Burrow Warrens heartstone (`burrow_warrens.gd:7511`) | B | Local add | The one-of-a-kind catalyst is lost |
| 8 | Ledger `item_grant` / `item_take` player ops (`ledger_rpc.gd:1040-1049`) | B | Dropped-item pickups, unregistered pickups and harvests, `transfer_item`, `drop_item`, Doss / river-nest / Stormwood arch costs | Grants lost; costs restored (duplication) |
| 8 | Registered pickups, harvest nodes, felled piles, Stormwood harvest, ripplet finds | A | Reward delivery or gather batch | — |
| 9 | Armor equip and unequip (`tab_backpack.gd:732/1432`) | B | Local | Reverts |
| 9 | Legacy evolution (`tab_creatures.gd:1845`) | B | Local species change and catalyst spend | The evolution reverts |
| 9 | Tool wear, orb throws, eating, nicknames, party order, bed and dialogue heals | B | Local changes to portable fields (bed heal: `game_state._tick_creature_bed_recovery`) | Rolls back |
| 9 | Research log, relics, teaching, gear, loadout, mastery, essence, release receipts, bounties | A | Host actions (`foundation_actions.ACTIONS`, research `_commit_saved`) | — |
| 9 | Creature XP from a guest's own local trainer fight | Probably B (not fully traced) | Legacy local loop unless durable trainer rewards or host-owned XP apply | XP and levels revert |

## Most likely to be hit first (B)

1. Field crafting, orb throws and tool wear: every session.
2. A catch with a free belt slot: every co-op catch.
3. A catch at a full belt: the newcomer is always lost.
4. Shop trades and shared-chest moves (items destroyed or duplicated).
5. Dialogue gifts (permanent: their player flags block a re-offer). `mill_bridge_gear` can block progress.
6. Tournament round rewards.
7. Armor, renames and party order (they revert; nothing is lost).
8. The Tidewake Guardian and Aquaryn claims (no world receipt to vouch with).
9. Legacy evolution and the heartstone.
10. Oskar's swap.
11. Item transfer or drop between players.
12. A fresh-character late-arrival starter. It is rare but catastrophic: zero creatures, never granted again.

## A second, live-session problem, independent of the rejoin rule

Every B change also makes the guest's portable projection differ from the host's owner-passive replay.
- **What breaks:** the next host-checkpointed action freezes on the guest's full projection hash (`owner_passive_sync.gd:1082`). The host then sets `owner_passive_exact_projection_conflict` (line 823).
- **How long:** until the guest reconnects. Until then the host refuses every owner-passive action: station craft, feast, relic hang, master chest, essence release and research events.
- **Root cause:** nothing writes these guest changes into `_records`. Rebases require the host state to match, and the replay handles only condition, discovery, vitals and `reward_delivery_applied`.

The rejoin ruling does not address this. It is a separate co-op item to schedule. One option: replay these changes, or route them through the host as owner-passive or Foundation actions.

## On current main (rejoin admission reverted)

- A rejoin whose record differs outside the passive fields is refused by owner-passive admission (`owner_passive_sync.gd` `admitted`).
- The player sees "care and Altar actions are paused until you rejoin". The held record lives in host memory for the whole world session, so every later rejoin is refused too.
- The guest keeps its own file, so nothing is lost, but its owner-passive actions stay paused. STATE lists this as an open co-op item ("returning-guest divergence").
