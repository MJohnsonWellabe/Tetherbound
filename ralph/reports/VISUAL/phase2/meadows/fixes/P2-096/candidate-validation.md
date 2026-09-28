# Craft action hint candidate

The independent full-resolution baseline review recorded in
`../P2-095/baseline-judge.md` found that "Craft: A / Enter" and "Leave: B / Esc"
recede at reduced size. Catalog sightings repeat the issue in three biomes.

The current candidate uses the existing secondary text color and FONT_PROMPT (30 logical pixels) for both action hints. Bindings, hint wording, recipes and transactions are unchanged.
The local presentation flag `craft_presentation.json::readable_action_hints`
defaults to **false**, independently of the recipe-row candidate.

`tools/phase2_capture_build_systems.gd --craft-hints-preview` previews and records
the override; it can be combined with `--craft-readable-preview` for the same
native capture round. A prior version has a scoped 1080p verdict below; the final surrounding-layout version remains unaccepted.
**Not visually accepted or fixed.**

## Independent source review

Review of d1ca575208e39961dbc7ba806c42ba30710b40f0 found no actionable issue.
The flag remains independently default-off; its false branches preserve the
previous size/color. Only the two existing labels change presentation when
true. Rows-only, hints-only and combined capture previews set and disclose the
respective overrides correctly. Crafting and input handlers are unchanged.
`git diff --check` passed. This review did not render or claim visual acceptance.

## Dirty follow-up, 2026-09-28

The two candidate hint labels now use `UITokens.FONT_PROMPT` (30 authored pixels), satisfying the20px-at720 prompt floor; false branches remain `FONT_TINY` and colors unchanged. Both-flags controller-input-path smoke passed using synthetic joypad events, not physical pad input. The initial combined native Meadows pair completed but exposed missing recipe-row text in P2-095, so the six-frame batch was stopped after two frames and no visual acceptance is claimed for either row. Evidence remains under P2-095/craft-pair. The separate corrected one-frame Meadows retry subsequently completed and received the scoped verdict below; both shipping flags stay false.

Corrected one-frame Meadows retry subsequently completed at1920×1080 with both actual preview flags true and zero manifest failures. Its capture/profile/source/cleanup receipt is recorded with P2-095; raw frame is `../P2-095/craft-retry/meadows-candidate/meadows__system__crafting.jpg`. It was compared with the preserved baseline as recorded below. This older frame does not verify the later typography/count-preserving layout or native 720p appearance.

The subsequent independent blind verdict passed those frozen candidate Craft/Leave hints at1080 and failed baseline hints at a glance. It is scoped to that source snapshot/image, with no720p, other-realm or hardware acceptance. The later P2-095 typography/owned-count revision changes the surrounding layout and therefore requires a new comparison. Its source review and164-case synthetic layout/controller-event evidence are recorded in the P2-095 report; prompts remain30 authored pixels and both production flags stay false. Both older images received narrow Bar A YES and Bar B NO. Full Bars A/B are required for visual-row closure, so the scoped hint PASS cannot close P2-096. It remains open pending the final candidate evidence across its recorded sightings.

## Frozen final source and incomplete native batch

Exact shared source SHA256: `scripts/ui/craft_panel.gd` `0e28add730974b159ef5a8158aadc11287150c7ca1d7749511f568644ee5f1b0`; config `87ab87a3a72af39ad5c0a4d031d2974b8696f5d84fda6cd02278a86763031fba`; smoke `d42ef30a5b9fea6befed0d667d870429b6c2b1bf9a821c96b99b9109a7c961b9`. Independent source review found no actionable issue. The combined candidate passed 164 synthetic recipe/count/raster cases covering 1,696 labels, including Craft/Leave font floors, panel safe fit and real input-path craft-count refresh; the old-size negative produced 100 expected containment failures. These are numerical/synthetic-input results, not native acceptance.

Final 14-frame package stopped in session 26483 (exit 1), local run `.artifacts/phase2-meadows/crafting-native-final/craft-final-20260928T163154Z-51b85f86`: three realm 1080p pairs and four matched 720p stress views. Only the first valid Meadows baseline completed; no candidate launched. A PowerShell single-element array-unwrapping error in the launcher mis-compared the expected recipe. Cleanup was confirmed and the lock released; the narrow launcher correction requires source recheck before another explicitly scheduled attempt. No final-batch completion or visual verdict is claimed. See the P2-095 report for fixture disclosure and exact receipts. ACCEPTANCE §6.1 permits the computer Compatibility profile disclosed as "computer capture, no Ally hardware"; physical hardware is not an additional Phase 2 gate. Both flags remain false and P2-096 remains open.

R2 follow-up: independently reviewed launcher `879c4287eb41855f168ecaddbc9caafd40301f8c4631bea479cfb899fbbde5fc` preserves that valid baseline and schedules 13 new frames in 7 processes (14 total comparison images). The corrected array-valued recipe validator passed the actual saved baseline, singleton/four-ID checks and wrong-recipe negative. Original source pins, immutable baseline image/manifest hashes and identical fixture were independently verified. Session 65018 subsequently terminated; its exact partial outcome is recorded below. Exact source/reuse receipt: `.artifacts/phase2-meadows/crafting-native-final-r2/independent-r2-source-review.json`.


## R2 terminal fixture failure and bounded correction

R2 terminal outcome: session 65018 exited 1 after all three valid 1080p baseline/candidate pairs completed. These six images preserve the final candidate, with source-informed factual audits finding complete target names, owned counts and hints; no blind verdict is claimed. FOV is 65 degrees in Meadows and 70 in Cloudreach/Stormwood, equal within each pair. The four 720p baseline images are **invalid selected-row stress evidence**: the requested detail changes, but the rebuilt list remains at its top and the requested row is offscreen. They remain preserved as fixture-failure evidence. The final 720p candidate exited 1 before saving any of its four frames, rejecting `Cliffglass Bracing (pickaxe)` geometry. Therefore the truthful outcome is six valid 1080p images, four invalid 720p fixture images and zero candidate 720p images, not ten valid comparison frames.

The isolated headless exact-lifecycle probe reproduces `_build(); _select(); grab_focus()` before layout: scroll stays 0, selected row y=1525 and name y=1531, outside the scroll viewport y=229..869. Calling `ensure_control_visible` after layout changes scroll to 864 and places the same row at y=661, with the name and three-line cost fully contained. This differs from the earlier 164-case smoke, which navigated an already settled list using synthetic joypad events. No production typography change is justified by this fixture-timing failure. Native failed-label metrics/image were not saved in R2; a separate diagnostic fixture will retain them without weakening the guard. Both sides of the corrected stress fixture must require the selected row to be focused and fully visible while permitting baseline text/font defects.

All 23 source pins still matched after terminal cleanup. Owned launcher and engine PIDs and their children were absent, cleanup was confirmed, the matching lock was released, and coordinator/Tidewake/Stormwood were explicitly notified. No automatic reclaim or full-batch retry. Exact receipt: `.artifacts/phase2-meadows/crafting-native-final-r2/craft-final-20260928T164406Z-38765b49/terminal-outcome.json`; CPU probe: `.artifacts/phase2-meadows/crafting-720-diagnostic/rebuild-focus-probe.json`. Earlier evidence remains immutable. Both flags remain false; the rows remain open pending valid 720p and independent visual evidence.


Independent focused reproduction: `crafting-native-final-r2/focus_lifecycle_repro.gd` completed 8 headless samples (two recipes × two preview states × immediate/settled selection). Immediate rebuild/focus left the selected row offscreen with scroll 0 despite correct focus ownership; waiting six layout frames before selection/focus restored row and label containment for both variants. Cliffglass candidate name retained 1/1 lines at font 27; its issue was viewport placement, not a lower font floor. This independently reproduces the saved baseline geometry and supports a capture-fixture lifecycle correction only. Exact independent measurements and scope: `.artifacts/phase2-meadows/crafting-native-final-r2/{focus-lifecycle-repro.json,independent-720-lifecycle-diagnosis.json}`. No production typography change, source-informed visual PASS or 720p acceptance follows.

## Corrected R3 native 720p completion

The fixture-only preselection layout wait was independently reproduced and reviewed. R3 session 33315 exited 0: both direct native processes (8088 baseline, 14520 candidate) exited 0 and produced four frames each with complete manifests and zero failures. Actual raster/window is 1280x720, authored canvas 1920x1080 and measured stretch 0.666667. Both sides show the requested row focused and contained with matching selected detail. Candidate body text measures at least18 raster pixels, prompts20, and headings/selected quantities24; all recorded candidate labels are complete. Scene, camera/FOV, legal stock and pose checks passed within each pair. These native receipts support factual comparison, not an independent visual verdict.

All24 current pins and20 retained evidence/provenance hashes matched. Both owned native processes, the launcher and children were absent after normal cleanup; the matching lock was released and Tidewake/coordinator received explicit handoff. The six valid1080 original images preserve their original fixture hashes and provenance. The eight new720 images use the separately reviewed R3 fixture; no identical-fixture claim is made across these batches. The earlier invalid720 images remain preserved and are excluded.

Receipt: `.artifacts/phase2-meadows/crafting-native-stress-r3/craft-stress-20260928T171833Z-006d2fd3/terminal-native-receipt.json`. A fresh neutral packet with14 original images/seven pairs is at `crafting-native-stress-r3/judge-neutral-final`; private mapping and factual audits are outside it. Peer factual pixel review found no blank/clipped/incorrect-selection capture defect. Fresh independent blind visual review remains pending. Both candidate flags remain false; no catalog/STATE closure or visual PASS is claimed.

## Scoped acceptance and landing preparation

The final independent blind verdict is mapped and verified: A is the candidate, B baseline; all14 original/neutral hashes, original manifest hashes/actual flags and the sealed30-file inventory match. Candidate passes this item's scoped UI requirement across Meadows/Cloudreach/Stormwood1080 and all four true720 stress states. Baseline fails. Full immutable verdict, exact original-image/manifest hashes and the two contact sheets for the distinct 1080 and corrected R3 720 capture rounds are in `../P2-095/accepted-ui-comparison/` (from P2-095, use `accepted-ui-comparison/`). The fourteen per-frame originals remain local at `.artifacts/phase2-meadows/crafting-native-stress-r3/judge-neutral-final/`; they and its extra README are excluded from the landing allowlist under WORKFLOW section 9.

Per-item acceptance is separate from regional bars: Meadows/Cloudreach BarA narrowly yes, Stormwood BarA no, all BarB no. No regional or whole-board closure follows. The three ranked regional gaps remain terrain/approach material transitions, Stormwood chapter lighting/material identity, and readable creature/trainer subjects.

After terminal dialogue cleanup and explicit owner authorization, the two crafting presentation flags were enabled locally. The production panel remains the exact judged source SHA0e28add730974b159ef5a8158aadc11287150c7ca1d7749511f568644ee5f1b0; config geometry is unchanged. A shipping-config version of the existing smoke removes all manual flag assignments and asserts normal _ready config loading. It passed164cases/1696labels/zero failures, with cases and every label measurement exactly equal to the reviewed candidate. It retains synthetic joypad transaction/count-refresh checks; no hardware claim. Unrelated candidate flags remain unchanged/off. Catalog status remains pending an implementation commit/landing; no Git metadata was modified.

### Final shipping test modes and publication limit

The ordinary tracked `tests/smoke_craft_panel_controller.gd` invocation passes with the enabled shipping config. Its explicit `--baseline-presentation` mode sets both presentation flags false after `_ready`, rebuilds, and passes the same synthetic navigation/craft/refreshed-focus/close path; combining that option with `--readable-recipe-rows` is rejected. The existing extended readable coverage is unchanged. The final test-only mode addition is SHA256 `86da60d7e7b69f9ee4995542788cfccef35190faf48c2555d9342a6e543e0638`; the judged production panel remains unchanged. Logs are `.artifacts/phase2-meadows/crafting-landing/tracked-{default,baseline}-smoke.log`. These are local-source checks, not a current-main integration suite.

The lean landing allowlist contains three implementation files, the two existing validation reports, the unchanged blind verdict, the original-image/manifest hash receipt and `_sheet1080.png` / `_sheet720.png`, one sheet for each distinct captured comparison round. Promoted sheets are byte-identical to neutral `overview-1080.png` / `overview-720.png`; the receipt records that mapping. Per-frame originals and redundant status/README files remain local and are excluded under WORKFLOW section 9.

Publication is authorized now as atomic accepted crafting commits and a draft PR, with no auto-merge while Cloudreach #414 runs. It remains blocked by the actual root GitHub write approval-policy rejection and local Git-write restriction; no alternate identity or CLI route may bypass them. No implementation commit or catalog closure is claimed. Definitive current-main integration and CI remain pending. The exact-main source patches use base `e35e26118ab333722e818a174310b5472201be4d`; they preserve newer camera/HUD/catalog/STATE files. A read-only size probe encountered Git partial-clone lazy fetching and was stopped; subsequent reads disable lazy fetching, and no archive, checkout, explicit fetch or publication operation is used to bypass the restriction.

Final source preservation adds only the byte-exact final 1080p and corrected 720p capture fixtures plus their false capture-era config under `P2-095/accepted-ui-comparison/sources/`. The existing evidence receipt maps preserved copies to original local paths, seed 2042, baseline/candidate arguments, isolated profiles and native raster settings. This does not rewrite prior fixture hashes or claim current-main captures. The accepted crafting allowlist is now twelve files; faint/catch candidate sources and their authored donor are separately unjudged WIP, not accepted craft implementation.
