# F19#5 (Meadows part): lane meadows-route, handed off to routes-west (CT, Sun 11 Oct 2026)

Command per piece: `godot --headless --path . --audio-driver Dummy --script tools/earned_saves/earned_chain_runner.gd -- --segment=<id> --save-dir=<root>/<id>/<id>/save --receipt=<root>/<id>/<id>/receipt.json [--handoff-from=<prev-root>/<prev>/<prev>] [--route-ledger]`. No TB_WORLD_SEED. Injections: 0.

Proven: `opening_team` PASS r10 @ebe1b2c7 (14:23-15:21), fixture `tests/fixtures/earned_saves/meadows_01_opening_team`.
Handoff verified: camp_tournament loaded it through the production title with an equal F49 state (5 UIDs, flags, items, mastery).
Earlier opening passes: r7 @49ad747b and r8 @275e1063 (r8's receipt missed a pending delivery; see fix 5).

Game fixes (each with focused unit tests passing):
1. d05ce689 combat_manager: reset client Energy when a host encounter binds. Before it, every wild training fight was lost with 0 hits (315 insufficient_energy refusals).
2. 67bb3047 props.json: moved cottage_b's woodpile off cottage_b_8's door approach. The trainer stepped up 0.32 m onto a log box from doorstep_26 and fell off it (4 airborne frames in a replay; 0 after).

Helper/harness alignments (coordinator-approved, disclosed):
3. ca277f4d navigator: deep-overlap bound is 2 x safe_margin (depth 0.000275, recovery 0.00151, skin 0.001). Total contact count is an observation (9 Terrain points vs CONTACTS 8). Lost-floor failures now print colliders.
4. 49ad747b navigator: MAX_REQUESTS per walk_to. r6 used 24001 over ~1979 m; MAX_QUERIES_LIFETIME (250000) stays the guard.
5. ebbcb528 runner: save, settle and compare (6 rounds x 60 frames) before export. A combat_mastery pending_owner_save delivery applied after the export save (+1 use on Load). r10 disclosed "still changing after 6 settling saves", yet the Load comparison was equal.
6. 8ba3e4cd runner and handoff: new-order `warden` (f49_warden_finale, no Rift, declines the legendary so the same five survive) and `tidewake_handoff` (Home Key, hang the Meadows relic, Tidewake portal; realm water).
7. 898be2ba rest helper: walk to Halda via the team segment's boundary_approach gate route. The camp was outside the village fence; r7 slid along FencePanelCollision_6..8 and ended 60.6 m short.

Open:
- Intermittent "lost grounded floor" near (28,-11) by village_twins_yard on the opening's third catch (r3, r9). It doesn't reproduce in an empty scene, so some dynamic body is involved. d4/r10 passed the same route.
- camp_tournament r10 @ebe1b2c7 (15:21-15:45) FAIL after materials, camp, rest, Halda registration (boundary fix worked) and `tournament_quarter_won`: standing 1.4 m from Halda/Interactable (1.52 m), her prompt never won (offer '', winner none). Log: r10.camp_tournament.log.filtered.gz. bridge and warrens were not run.
- The cross-commit resume opt-in (proof rules v2) was denied by this session's permission classifier and reverted. Pieces must share a commit.
- Infrastructure: do not run unit suites alongside the opening. The navigator's 10 ms dispatch deadline starves on 4 cores (r5).
Logs from the failed attempts: `*.filtered.gz` here.
