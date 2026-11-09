STATUS: land (prefix bug fix plus CPU-judged HUD gain)
BRANCH: tb/item-victory-card
HEAD: (this commit)

1. Bug: Nerissa's win card doubled its prefix ("Captain Nerissa's reward:
   Captain Nerissa's reward: 150 Coin, 2 Revive"; GPU G-recheck-nerissa-win).
   Source: encounter_director `_trainer_reward_line` already writes
   "<Name>'s reward: ...", and trainer_reward_delivery.gd's routed receipt
   prefixed it again. Venn's payout takes the push_world_message path, which is
   why it was correct. Fix: `reward_receipt(title, line)` keeps a line that
   already carries a prefix. Tests in test_trainer_reward_delivery.gd: no receipt
   repeats its prefix, and routed delivery of a prefixed line shows one prefix.
2. Victory hero card (hud.json victory_focus.hero_card):
   - A victory receipt takes a centred plate in the upper third, 46% of the canvas
     wide, 12% down, with a 42 px headline and a 36 px payout line, all centred.
   - Growth-only moments keep the right-hand lane.
   - victory_focus already hides the hotbar, exploration rail, party roster and
     prompt while the plate shows.
   - Code: playground_hud.gd `hero_card_enabled`, `hero_card_rect`,
     `_set_moment_hero`.
   - Tests: tests/test_victory_hero_card.gd. HUD tests 166/0.
   - CPU quick judge hero-card-r1 (VERDICT.md, _sheet_hero_card.jpg): F39#21
     mapped 5.62 -> 6.33 (+0.71), with all three judges scoring the centred card
     higher. Shipped ON.
   - F41#21 Stormwood was not judged on CPU: the hollows fight does not reach
     its win inside the 120 s capture on either side. The same code path draws
     the Stormwood card, so GPU confirms.
   - Judges' remaining asks: hide the "Put Bramblebun away" prompt during the
     beat, and add a short light or effect flourish.
   - Harness note: quick_judge find_frame does not resolve the lifecycle
     naming (`<trainer>_resolve__win-*` ids vs `tidewake__fight__<trainer>__win.png`
     files), so the pairs were mapped by hand in round.json.
3. F41#8 arm: ralph/reports/LANES/ITEM-F41-8-ARM (GPU).
4. F38#17/F38#28 red banners: ralph/reports/LANES/ITEM-RED-BANNERS. No change;
   both are Team Tether sites.

Checks with the flag ON:
- HUD tests: test_victory_hero_card, test_trainer_reward_delivery,
  test_uiposes_victory_focus, test_progression_feed, test_hud_*,
  test_gate_f_fight_victory_receipt and the other uiposes/HUD files give
  166 tests, 0 failed.
- Co-op smokes: client_trainer_rewards, boss_rewards_each_participant,
  f27_guest_wild_win and stormwood_hosted_trainers all report ALL CHECKS PASSED.
