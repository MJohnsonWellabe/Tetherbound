# F17#4 independent review: M1 opening chain, seed 4, r7

**Verdict: PASS, with one caveat.** The pass is real but sits at the edge of the harness's loss budget, so it needs a confirming run (see "Robustness" below).

Criterion: "The M1 opening chain (starter, practice catch, camp, three-bed readiness, three tournament rounds) still completes on the new layout."

Evidence judged: `r7-run.log.gz`, CI render 37232841924 at commit d6f855d4: `tests/smoke_four_biome_continuous.gd -- --legacy-order-diagnostic --through-tournament --world-seed=4`. Line numbers refer to the decompressed log. I read the helpers only to learn what each line asserts. I did not re-run anything.

**Layout check.** d6f855d4 descends from the F17 village and Crossing Hall re-plan: 2efea672 merges main, followed by 25727995, 53e3e0f5, ae495e7d and the interior-fence walker fix d7a08c6c. The run is therefore on the new layout. Every commit from r2 to r7 changes only test or harness code (walker routing and steering); none changes game code. The helper segments are unchanged between d6f855d4 and HEAD.

## Checks

1. **Starter chosen through the real picker: PASS.**
   - L102: `starter picker order ["terrapup","ripplet","galewisp"]; 0 ui_right press(es) to 'terrapup'`
   - L103: `starter selected and named (terrapup, uid creature-ad37…)`
   - Before that: title, character choice, name prefill, wake and Grandpa briefing (L6–9, L70–71 in the filtered view).

2. **Practice catch was a real catch: PASS.**
   - L118: `tutorial Bramblebun combat entered`
   - L119: `Bramblebun naturally weakened to 23/93 HP`
   - L120: `live catch begins with 50 earned orbs; no HP or inventory fixture`
   - The aim and launch lines that follow show an eligible reticle and a struck target, `Wild_bramblebun_0_3`.
   - L130: `catch complete; exploration resumed with two-creature party`
   - L131: `FRESH PREFIX: title through first live catch; no seeded progress, HP pinning or reload`
   - The team stage then makes three more live catches (L165, L199, L219, each with "no HP or inventory fixture"), reaching `team_ready` at L325: 5 creatures, all level 5, `catch_retries:0`, 11 training wins.

3. **Camp placed and paid: PASS.** Most of this is proven by fail-closed code rather than by explicit log lines.
   - Materials were harvested in the world: L326–421, wood 31/30, fiber 35/34, stone 8/8, then a walk back to camp.
   - L423–426: walks to the tent stance and the campfire stance.
   - L445 transcript: `placed paid bedroll through a live green ghost inside the tent`, `placed 3 creature beds through the build menu, one per entrant; wood 1 / stone 0 / fiber 1 left`, `paid campsite and 3 beds placed`.
   - No line says "tent placed" or "campfire placed" on success. `meadows_earned_camp_segment.gd::_place_the_campsite` returns false unless both are placed, and its `_place_fixture` override fails unless the exact catalogue cost was spent (`_paid_exactly`) and a `paid:true` durable record exists (`_paid_record`).
   - The name `_place_fixture` is misleading: it is real build-menu placement (stance walk, green ghost, `build_place` tap), not a fixture.
   - The material totals fit the stated cost: about 30 wood, 8 stone and 34 fiber in, 1 / 0 / 1 left after the six pieces.

4. **Three-bed readiness and rest: PASS.**
   - The rest stage first walks to Halda (raw L447 area), where the three entrants are registered through the production picker (`_register_three_through_halda`).
   - L451, L454, L457: `bed_assigned` to distinct paid beds (bed_index 3, 4, 5) for party indices 0–2.
   - L460: `[rest] rested; day 3`.
   - Three Satchel berry feedings follow.
   - L464: `night_completed … "readiness":[]`. An empty list means `TOURNAMENT.readiness_report` found no unmet condition, so this is a pass, not a missing transcript.
   - L465: rest returns `completed:true, failures:[]` after one night.

5. **Three tournament rounds won through real fights: PASS.**
   - L472: `tournament_quarter_mira won through 2 real opponent defeats and 22 landed attacks`
   - L477: `tournament_semi_tam … 2 … 29`
   - L482: `tournament_final_oskar … 3 … 52`
   - The tournament segment only prints these lines once the trainer battle has ended and the round's won flag is set, the number of opponent `fight_exited:"won"` events equals the trainer's team size, and the hit count went up.
   - The fights are piloted by `CampaignPilot` input, with no staging. `_stand_on_the_tournament_ground` (arena teleport) and fixture staging fail closed.
   - No "recovered before …" line appears, so no mid-bracket recovery was needed.

6. **Final result: PASS.**
   - L484: `"failures":[], "reached":"tournament_won", "requested_prefix_passed":true`
   - L485: `exit=0 took=1245s`
   - `campaign_complete:false, counts_as_proof:false` is the expected marker for the `--legacy-order-diagnostic` prefix (L3: "never F49 campaign proof"). It refers to the F49 full campaign, not to this criterion, which only requires the M1 chain through the tournament.

7. **Fixtures, teleports, flag-sets and shortcuts: none that undermine the criterion.**
   - L4: the world seed is fixed (`world_seed override=4`). This is the stated test condition.
   - Revives, potions and berries come from Grandpa's authored pack: `data/dialogue/opening.json` contains `give:revive:10`, potions 3 and berries 5. Remaining counts in the log match (potions 2→1→0; revives 9→…→7; berries 4→3→2), and every use goes through the Satchel `care` path.
   - L104 mentions only "50 Basic Orbs", so the log under-reports the pack. This is cosmetic.
   - The harness picks wild targets and drives scripted controller routes (`wild_house_route_point` waypoints). That is input automation, not position writes.
   - I found no teleport, flag-set, HP pin or free-build in the log. The camp and tournament segments override every fixture method to fail.

## Suspicious or weak points (none is a failure)

- **Robustness: this is the caveat.** Training used `training_losses: 3` (L251, L290, L318), which is exactly `MAX_TRAINING_LOSSES = 3`. One more loss fails the run, and that is what happened in r6 on nearly identical code. Before the losses, pilots were entering fights at 25–26 % HP with no potions left (`depleted_stock_pilot_selected`, `care_depleted_pilot`). r7 shows the chain **can** complete on the new layout, not that it does so reliably. I agree with the README that F17#4 should be re-run once the shared rest-when-low change lands. A second pass would make this robust evidence. A fail on the same pattern would point at training attrition, not the layout.
- **Bed walk failures:** two `CONTENT WALK FAILURE` lines (L437, L442), where the creature-bed stance at (25, −37) was blocked by wild mudsnouts and a trainer_camp log. The harness moved on to the next candidate spot, as its design allows, and the beds were placed elsewhere. This is not a shortcut, but it is a minor camp-layout and wild-spawn crowding signal.
- **Edited log:** the log has OPENING_PRODUCTION diagnostics stripped, per the README, so it is not the raw CI output. Every stage verdict and result line is present and consistent. The raw log on run 37232841924 is the authority if anyone needs it.
- **Hammer line:** the README says "the hammer equipped through the hotbar", but the log has no explicit hammer-equip line. It follows from the camp stage passing, because `_equip_hammer` fails closed. The only hammer line is L140, where Tam hands it over.
- **Silent sub-stages:** the tent, campfire and Halda-registration sub-steps succeed without a transcript line. Their passes are backed by fail-closed code, not by empty transcripts that read as passes.

## Conclusion

On d6f855d4 (new village and Hall layout), seed 4, every stage of the M1 opening chain ran through production input paths: real starter picker, real practice catch, paid tent, fire, bedroll and three creature beds, a three-bed night with an empty readiness report, and three won tournament rounds. The run reached `tournament_won` with no failures. **F17#4: PASS.** The open item is to show the pass repeats: it used the full loss allowance, and the previous run failed on one more loss.
