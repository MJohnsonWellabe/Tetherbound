# F13#2 long-range pocket lures, round 2 (installed-prop wayfinding lures)

Gap: F13#2 "no long-range lure" (`../f13_2_full/PROOF.md` §2; nothing drew the eye in its 3 frames).

## Change
- Four reward-pocket groups were added to `data/config/water_local_chains.json` `wayfinding_lures`: `reed_root_hollow_marker`, `brine_upper_shelf_marker`, `salt_bell_terrace_marker` and `deep_watch_cache_marker`. Each is a Banner_2 standing banner plus a Lastlight-style lamp post, with the same builder and pieces as the F13#3 chain lures (`../f13_3_lures_r2/PROOF.md`).
- Each group stands 4–9 m from its pocket centre on the far side of the walked approach, placed by a terrain sightline check from the 40 m lure stand.
- The other four pockets already share the F13#3 chain lures:
  - lantern nook;
  - Gull satchel lamp and banner;
  - Cradle nest banner and smoke;
  - Garden vault banner and smoke.

## Walk regression
`tests/smoke_water_pocket_walk_claim.gd` (all pockets, plus the Cradle and Reed legs): **48 checks, 0 failures** (`pocket_walk.log`).

## Capture
`tools/capture_tidewake_b_pocket_lures.gd -- --out=ralph/reports/TIDEWAKE/b/f13_2_lures_r2` (xvfb, opengl3, 1280x720). All 8 frames are in this directory; `capture.log` has the stands.

## Code-blind judge (one round, no adjustment round)
The judge was a fresh `claude -p --safe-mode --tools Read` session in an isolated directory. It had only the renamed frames, the sheet and keyart. The prompt is `JUDGE_PROMPT.txt`, adapted from the F13#3 prompt for single frames. The verdict is verbatim in `JUDGE_VERDICT.txt`, and the frame mapping is in `JUDGE_FRAME_MAP.txt`.

| Pocket | Verdict |
|---|---|
| lantern_hidden_cache | WEAK: smoke column, banner "half-buried in foreground grass" |
| reed_root_hollow | WEAK: banner behind a tree cluster, not named |
| brine_upper_shelf | **NOTICEABLE**: "hanging dark blue banner ... reads unambiguously as a placed waypoint" |
| gull_research_satchel | WEAK: small banner post at the end of the gully |
| cradle_shell_nest | **NOTICEABLE**: creature beside the banner post |
| salt_bell_terrace | **NOTICEABLE**: waterfall island, with the banner post as a secondary cue |
| garden_exposed_vault | NOT NOTICEABLE: the stand is below the dune crest, and only the smoke top shows at the frame edge |
| deep_watch_tidecoil_cache | WEAK: banner "readable against open sky", but small |

**F13#2 lure gap: still open.** 3 of 8 pockets are noticeable. The lure capture tool's camera sits about 38 m out, often below a crest. It aims at the pocket centre in the left third of the frame, so these frames are close-approach views, not long-range ones. The chain frames (`../f13_3_lures_r2/`) show the same banners and smoke from the landings.
