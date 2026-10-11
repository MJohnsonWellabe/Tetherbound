# F47 Cloudreach XP: the required route carries the curve (owner 1A)

US Central, 2026-10-11. Chain re-run 01→05 ran 10:51–12:24 CT on branch tb/ev-cloudreach-xp at d23622aed, from `cloudreach_arrival_generated` (five creatures at L31, 0 XP). Commands: `tools/earned_saves/run_cloudreach_chain.sh <start> <root>`, 1x clock.

- **Tune** (`cloudreach_encounters.json` reward_tiers): grunt (Senn, the only grunt) gets xp_bonus 0→8500; mentor (Maela, the only mentor) gets 0→10500. Voss, Veyra, elite 1600 and captain 600 are unchanged. Rematches zero xp_bonus, and the admitted cap of 40 clips overflow.
- **XP before:** arrival→stronghold paid each creature 579–1512 XP (Senn's bench share about 590, Maela's about 606, wilds 0). L31→L39 costs 18,781. Arrival was all L31; the old run lost to Voss (732 damage dealt, 1568 taken).
- **XP after:** creatures standing at the end of each fight gain about 9,090 (Senn) and about 11,100 (Maela) XP.

| Checkpoint | Levels after (terrapup, bramblebun, bramblebun, mudsnout, bramblebun) |
|---|---|
| 01 arrival gate | 31 31 31 31 31 |
| 02 broken causeways (Senn) | 35 35 35 35 31 |
| 03 flight training (Maela) | 35 39 39 39 31 |
| 04 high roost | 35 39 39 39 31 (stronghold arrival) |

- **Voss:** WON by live SPACER controller piloting with no timeout: 82 hits dealt, 27 taken; 1016 damage dealt, 1382 taken. After the fight the levels are 35 39 39 40 32, and the elite +1600 was paid.
- **Lumpy curve (for the owner):** the XP comes in two lumps, about +4 levels at Senn and about +4 at Maela.
- **Fainted members miss the bonus** (trainer_npc/encounter_director rule: living members only). The 5th creature was down at the end of both fights and stays L31. The lead was down at the end of Maela's fight and stays L35. A player who revives before the final knockout keeps the team even.
- **Ledger** (`tests/test_cloudreach_route_ledger.gd`):
  - (a) Wild defeats now use the production hybrid award (×0.35). They were credited unscaled, and on that basis the untuned data fails (lead L39 at Voss vs L40 needed).
  - (b) By coordinator ruling under 1A, the wild-phase negative controls are replaced by dropping Senn's or Maela's trainer XP. drop_candy and wild_fraction 0.25 are kept, and all four still fail.
  - The ledger ignores the L40 cap, so its L45 at Voss reads high.
- **Unit tests:** curve, chapter_curve, redesign_chapter_curve, level_curve_policy, f19_curve, cloudreach_encounters/route_ledger/no_legendary_offer, encounter_rewards, chapter_rewards, combat_round_reward and f47_exploit_matrix all pass: 0 failures after the control change. The C2 bands are untouched (no team or wild level changed; no other biome's numbers changed).
- **Not mine:** `tests/test_f19_curve.mjs` fails identically on base (Meadows band1 trainer identity).
- **Not proven here:** 05's summit and extraction tail, and Veyra (06). The ledger shows the Veyra margin only with wilds and candy.
