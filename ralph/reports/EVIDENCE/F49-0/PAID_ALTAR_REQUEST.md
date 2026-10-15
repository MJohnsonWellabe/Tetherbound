# Bounded paid Altar proof request - native OPEN
One retained UID per process, at most19 payments. No accepted predecessor is currently bound; the active direct-run frontier is `opening_team`.

## 14 Oct GPU turn 4 direct-run result (owner override)
The newer owner direct-run rule supersedes this file's old stage, lease and resource-floor requests. Routes used its granted GPU turn in `D:/tetherbound/restart-routes`. The first direct invocation was:
```powershell
& 'C:/Users/mattj/.cache/tetherbound-tools/godot-4.7/Godot_v4.7-stable_win64_console.exe' --headless --path 'D:/tetherbound/restart-routes' --script 'tools/earned_saves/earned_chain_runner.gd' -- '--segment=opening_team' '--save-dir=D:/tetherbound/.artifacts/restart-routes/f49-turn4-aaea/opening_team/save' '--receipt=D:/tetherbound/.artifacts/restart-routes/f49-turn4-aaea/opening_team/receipt.json'
```
Source `aaea027840c2a0e26b7c1a3b41d2b239f64a5d1d`: `opening_team` printed `passed:false`, failure `opening: the real wake-up prompt could not be reached and activated`. World resource preloads failed because this checkout had no Godot import cache. Failed earned pieces print proof/results but do not export an accepted receipt/checkpoint.

Godot's normal `--headless --path D:/tetherbound/restart-routes --editor --import` completed with exit 0. Fights' pushed game-source type fix was then fast-forwarded from `tb/fights` into this checkout; no proof was running during that update. The one direct retry used the same command above with `f49-turn4-d6-retry` substituted for `f49-turn4-aaea`, at exact source `d6c9e041355fb7fbec906a944109d3218363f15a`. It exited 1, again reporting `the real wake-up prompt could not be reached and activated`. Its world log also reported no ground under an authored Bramblebun spawn and absent character/creature models. It produced no accepted receipt/checkpoint.

The checkout's sparse rules had retained `data/terrain/playground/manifest.json` but omitted its tracked Terrain3D `.res` files, as well as `assets/characters` and `assets/creatures`. After the retry, normal `git sparse-checkout add` materialized those three actual runtime paths; the Terrain3D files and the named Bramblebun and Warden models are now present. The one-retry turn limit ended the native slot before another run. `camp_tournament`, `bridge` and `training_t1_altar_1` were **not run**. Next direct GPU turn starts a fresh `opening_team` on the actual source SHA, then advances only through passing saved predecessors. F49#0 remains OPEN and its active completion goal remains in force.

## Routes restart, F49#0
Game change on `tb/routes`: chapter quest guidance now names Orin, Mira, Ione and Aster at their authored approaches, tells the player to win, open the recipe chest, cook at the homestead Kitchen and feed a matching feast. The existing Rowan row is retained. `quest_log.gd` now maps the canonical Tidewake Master biome to the runtime `water` realm so Ione's map beacon appears. Advice grants nothing and never gates travel. Static JSON parse, configured objective-flag lookup and `git diff --check` passed; native quest presentation and the earned route remain UNRUN.

Next native request: direct-run `opening_team` on the actual Routes checkout with the now materialized runtime terrain, character and creature files. Follow with `camp_tournament`, `bridge` and `training_t1_altar_1` only through their accepted saved predecessors on the same source. Each existing piece has a 600-second ceiling. Do not use the generated Meadows boundary. The actual chain must still witness each Master win, recipe chest, Kitchen cook/feed and matched chapter seam. Zero criteria closed by the guidance change or these failed opening attempts.
## Next earned frontier
Historical bridge clean-tree proof is VOID. Use the existing earned game runner directly for `opening_team`, `camp_tournament` and `bridge` on one unchanged source; advance only on each actual PASS and saved checkpoint.
First paid request: training_t1_altar_1 from that accepted bridge. Never substitute the historical fixture.
Exact engine arguments: set $Output = Join-Path $OutputRoot training_t1_altar_1, with $OutputRoot absent; resolve other variables from admitted proof:
```powershell
$engineArgs = @('--headless', '--path', $Project, '--script', 'tools/earned_saves/earned_chain_runner.gd', '--', '--training-profile=meadows_training_v1', '--segment=training_t1_altar_1', "--handoff-from=$AcceptedBridge", "--save-dir=$Output/save", "--receipt=$Output/receipt.json")
```
Use the existing 600-second piece limit. Runner verifies complete saved prefix/hashes before production Load; ordered five, inventory, realm and persisted training must match. Never lighten earned assertions.
Require profile meadows_training_v1, PASS piece_proof, saved output, unchanged other four/history and actual accepted durable payment journal/receipt plus exact debit for each selected level. Insufficient earned funds must FAIL.
After inspected PASS schedule slot2 from actual slot1 output, then3/4/5 separately; never reuse bridge for a later slot. Follow fixed Master/Kitchen/feed order; cap alone proves no feast.
## Later chapter requests - no eligible saved predecessor bound yet
Source exposes training_t3_altar_1..5, training_t4_altar_1..5 and training_t5_altar_1..5 via tidewake_piece_runner.gd, all physically in Meadows.
```powershell
$engineArgs = @('--headless', '--path', $Project, '--script', 'tools/earned_saves/tidewake_piece_runner.gd', '--', "--segment=training_t${Tier}_altar_${Slot}", "--from=$AcceptedPrevious", "--out=$Output")
```
Each process ceiling600seconds. Slot1 requires actual training_tN_preparehome PASS; slots2..5 require immediately preceding same-tier slot PASS, preparereturn requires slot5. Runner rejects wrong/missing predecessor or different source commit before copying save or opening title. Preserve the existing piece output and saved proof.
Require predecessor PASS, complete route/training snapshot, exact Load match, five retained UIDs, current cap and all prior breakthroughs/wins/recipes. Current-tier Master win is not required before training.
Generated raise-level/member/ending switches are refused. Preserve generated/unproven ancestry; success cannot make it earned. Legacy Tidewake05/Cloudreach06/Stormwood07/09 fixtures lack prior history and are ineligible.
Source adds training_tN_preparehome (actual chapter Home Key, prior history required) and training_tN_preparereturn (actual arch, all five at cap required), each a separate600s request through the same runner. Neither requires current Master win. Return ends at production-selected chapter arrival, no Master-stance guarantee; native travel/resource/UI proof remains OPEN. No relocation/inventory injection.
## Focused checks
Next scoped native batch: tests/test_altar_training_piece.gd, tests/test_chapter_homestead.gd, tests/test_f49_training_prefix.gd. New coverage: all15 later slots, each missing prior win/recipe, wrong realm/history and invalid slot syntax.
Negative native case on a copied predecessor: alter receipt training only; require FAIL before helper input and no accepted PASS receipt. Tidewake retains its copied Load save under the failed output; it is not an accepted checkpoint. Preserve original predecessor.
Frozen NEXT_HANDOFF.json source/hash pins are historical diagnostic data, not an earned predecessor. The direct opening attempts above failed; no criterion closed.
