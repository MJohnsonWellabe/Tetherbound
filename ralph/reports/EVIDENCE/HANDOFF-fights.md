# Fights takeover handoff — tb/ev-fights
Updated Tue 13 Oct 2026, 5:36 PM CT. Persistent goal active; criteria remain open.
- Worktree: D:/tetherbound/codex-takeover-fights. Narrow non-cone source checkout initialized, clean before this batch; no assets copied. All Git uses gc.auto=0 / maintenance.auto=false.
- Read authority: coordinator a6dc9678f1bc6e08ed12671afd4ee40cdd2e01bd, #572 comments 6151843176 and 6152935182, current visual-judge and WORKFLOW 8.1 rules 9–11.
- Source batch: material helper now accepts absolute stock_override and return_to, and equips each resource's production tool (including rootstone/ironwood) through existing controller input.
- Callable draft helpers: tools/earned_saves/wip_fights/{storage_trip,kitchen,cook_feed}.gd expose run(tree,world,game,options) -> {passed,failures,transcript,receipts}; homestead_common.gd shares input-only implementation. Original .txt retained for comparison.
- Fixed draft faults: inherited run signature collision avoided; storage retains tools/Home Key and walks back to departure; Forge panel closes after channel; feed selection supports catalyst-free evolution, permanent mirrors, exact target; cook plans gather deficits; feed checks one-item consumption/species; empty feed plan fails.
- Follow-up: attuned ingredient selection reads canonical secondary outputs on essence stands and requires actual secondary inventory gain; focused regression added. Bounded bridge launcher prepared and four dry plans verified (no engine).
- Still source-only: native parse/runtime not run. gdtoolkit parsed all five changed/new helpers; inherited-method collision scan and combat.json decode passed; git diff --check passed. No engine proof or accepted criterion claimed.
- Remaining helper risks to exercise: attuned/berry gathering uses eligible live harvest nodes (never grants); packed bag and deposits; actual station placement sockets; Home Key/arch travel; cook/feed UI rows. Later-biome attachments need corresponding travel/material sources.
- Routes owns master_visit, loaner and chain seams; coordinate integration of Orin L10/Mira L20 without editing their helper. No Master chain segments claimed yet.
- South Bridge clean-tree proof remains VOID from prior commit-during-run. Existing slide fix and test_south_bridge_visual_scale remain. Need opening_team, camp_tournament, then bridge 2/2 from SAME camp checkpoint, separate fresh output roots, no commits during runs.
- Do NOT use run_chain.sh for acceptance: runner header says its copied-save/seed semantics are legacy diagnostic. Use earned_chain_runner.gd --handoff-from=<previous-piece> (one process per piece).
- F22#4 source: oreth_overflow.tell_text now says “step out of the spray”; no recapture yet. Historical Riverwatch best 6.5; new scoring needs fixed Medium/High camera set and three code-blind judges.
- F10#2 draft patch not applied: its raw render-removal restoration needs harvest/rebuild/overlap safety review; blindly applying may resurrect removed instances. Current scores Capacitor 4.5 / Rodfolk 6.5; remain open.
- Systems owns Warrens codec/refusal fix; do not duplicate. Earlier F33#2 and C2 results stay historical; no new claim.
## Bounded native queue — coordinator grants only
Set $g='C:/Users/mattj/.cache/tetherbound-tools/godot-4.7/Godot_v4.7-stable_win64_console.exe'; $p='C:/CodexTemp/tetherbound-native-service' after coordinator stages exact pushed source, preserving a clean identity.
1. Engine parse (short slot): & $g --headless --path $p --check-only --script tools/earned_saves/wip_fights/homestead_common.gd
2. Material logic: & $g --headless --path $p --script tools/run_one_test.gd -- res://tests/test_meadows_earned_material_segment.gd
3. Bridge geometry: & $g --headless --path $p --script tools/run_one_test.gd -- res://tests/test_south_bridge_visual_scale.gd
4. Root stages this exact pushed commit, then runs tools/earned_saves/run_fights_bridge_piece.ps1 -Piece opening_team -SourceCommit <40-char head> -Execute (600 s default; one granted process only).
5. Separate later slots use -Piece camp_tournament, bridge, bridge_retry with the SAME -SourceCommit and -ChainRoot. Each piece has its own absent root; both bridges load camp_tournament/camp_tournament. Launcher preserves outputs/logs, checks source before/after, rejects generated inputs and enforces capacity/time limits.
6. Outputs: C:/CodexTemp/fights-chain/<piece>/<segment>/receipt.json (bridge_retry has segment bridge); supervisor/logs in fights-chain/logs. Systems earned guardian input uses fights-chain/bridge/bridge only after receipt passes. Runtime source must stay stable across the earned chain.
Coordinator must bound each process and preserve diagnostics; missing assets/dirty source invalidate proof. No native process launched by this takeover yet.
