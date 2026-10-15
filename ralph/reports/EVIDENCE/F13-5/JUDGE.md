# F13#5 Tidewake currents, docks and Veilfall distance: re-capture and code-blind judge (5:36 AM CT Tue 13 Oct)

Capture: tb/ev-visual 26f948ad, tools/capture_tidewake_f13_5.gd (Compatibility, 1280x720, production camera, day; disclosed teleport poses and mid-chapter story flags), 16 frames; sheet _sheet-r5.png. One fresh code-blind judge, frames and docs/reference only.

**Verdict: FAIL** — (a) Veilfall distance PASS, (b) inhabited docks FAIL, (c) currents FAIL. Holds for the F39 catalog pass; this lane records and stops.
- (a) Veilfall reads on the horizon from First Shore and gains scale and cliff detail at Tidal Cradle and Sluice Isle. Minor: heavy fog at First Shore; at Sluice Isle the companion fills half the frame and clips the trainer and fence.
- (b) Six of seven docks are the same short pier with 2-3 tiny NPCs and crates; no boats, lights or stalls; docks distinguishable only by backdrop. Greybox: pale-blue cube on a tan slab at Shellwatch, a white slab at Salt Crown, a large cube/box/stick at Sluice Isle (the eastern sluice). Large empty sand foregrounds.
- (c) The three currents read as calm water with a dozen white flecks hovering above the surface that shift a few pixels between the 0.5 s pair; no streaks, foam bands or direction; the strongest current (1.3 m/s) looks the same as the 0.3 m/s ones.
- Other: overlapping creatures at Sluice Isle; a ghosted see-through creature in the first current's second frame. No oxblood.

## Restart Look: next fixed F13#5/F39 route prepared, native UNRUN

15October, current restart-look source5e9f2fe29f15af24956794af13bc7603100eb75a (evidence-only successors do not change these game/capture files). Same tb/look checkout/task; no revival of the archived Tidewake lane, stage access, new runner or capture edits. F38 remains OPEN/render-blocked and its5.67 round is VOID for acceptance.

**Preserved failure, not readiness:** the original full-world e006388448964301fb538209d132ff721bab1db3 run rendered one shore-day image at1920x1080/Forward+ on Godot4.7/GTX1060, then failed natural shutdown at180s. Its actual stdout reports fixed_views_returned/quit_requested/quit_returned near59.6s and world/Game tree exits near73.0s; those markers do not prove process exit. The successful one-region isolation does not exonerate the full scene. Compared with that source, current water_world.gd, water_vegetation.gd and grass_field.gd have no source delta. The capture script adds optional shutdown observations and binds ground cover to the fixed camera before capture; normal quit remains unchanged. The retained runtime interpolation patch may remove its deprecated-call warning, but is not evidence of a shutdown repair. No new readiness or supported natural-exit claim is made.

**Actual required local resources:** current Water scene loads res://data/terrain/water. Only its manifest was materialized;32 tracked files were missing. Normal Git restore from currentHEAD restored precisely those missing files at04:55:12CT:31 terrain3d region resources and surface_height.res. No existing file overwritten, no bake/import/source change. The committed manifest records31 regions while water_world.json declares78; this discrepancy is retained, not normalized or silently certified. All13 configured Water vegetation model sources and their existing imported scene/mesh references are present. Presence does not prove runtime/world completeness. This restoration is new to this checkout; it does not itself repair the historical teardown failure.

**Existing commands for a future grant — NOT executed.** All use executable C:/Users/mattj/.cache/tetherbound-tools/godot-4.7/Godot_v4.7-stable_win64.exe and APPDATA=D:/tetherbound/restart-look/.artifacts/f17-direct/user, own checkout, Forward+/Vulkan. Windows launch retains WindowStyle Hidden and the grant's actual child bound; no existing180s failed shutdown cap is raised by this preparation. Each actual argv and pushedSHA must be recorded at execution. No candidate is persisted ON.

Required existing parser for the capture script's changes since the preserved native attempt, only once native authority is granted:
```text
--headless --path D:/tetherbound/restart-look --check-only --script res://tools/capture_tidewake_f13_5.gd
--log-file D:/tetherbound/restart-look/.artifacts/look30-tidewake-parser.log
```
Only the coordinator's specifically allowed `Identifier not found: Game` autoload false positive may be classified as such; no other parser failure is waived.

F13#5 function matrix, Medium baseline (High uses --preset=High and a distinct high-baseline output/log):
```text
--path D:/tetherbound/restart-look --rendering-method forward_plus --rendering-driver vulkan --resolution 1920x1080
--log-file D:/tetherbound/restart-look/.artifacts/look30-f13-medium-baseline.log
--script res://tools/capture_tidewake_f13_5.gd --
--out=D:/tetherbound/restart-look/.artifacts/look30-f13-medium-baseline
--preset=Medium --only=veilfall,docks,currents
```
This unchanged path has3 Veilfall views,7 mandatory dock views and3 currents with shore/swimmer four-frame strips:34 expected JPGs, not the old16-frame count. It uses production CameraRig, disclosed mid-chapter flags and live current drift. Actual raster size, loaded terrain/vegetation, errors, frame count and natural exit remain unproved. It does not supply >=200 frames or full F39 weather/fight coverage. A later matched current-cue candidate arm adds only the already-existing --tidewake-current-candidate and a fresh candidate output/log; that preview changes the cue, not current strength or dock art.

Preserved fixed current-cue sample (four human-swimming views), if selected by root instead of the full function matrix:
```text
--path D:/tetherbound/restart-look --rendering-method forward_plus --rendering-driver vulkan --resolution 1920x1080
--log-file D:/tetherbound/restart-look/.artifacts/look30-t2-medium-baseline.log
--script res://tools/capture_tidewake_f13_5.gd --
--out=D:/tetherbound/restart-look/.artifacts/look30-t2-medium-baseline --preset=Medium
--camera-set=res://tools/visual_judge/camera_sets/T2-current.json --capture-size=1920x1080
--source-sha=<actual-pushed-HEAD-at-launch>
```
A candidate adds only --tidewake-current-candidate and fresh paths; do not add --restored-currents to an adverse-current comparison. Fixed F39 look sample uses the same command with --camera-set=res://tools/visual_judge/camera_sets/F39-look.json and fresh look30-f39-<preset>-<arm> paths; its6 clear-weather views are an initial sample only. The existing process-local --tidewake-look-candidate selects that look arm; it is distinct from the current cue and shoreline candidate and should not be bundled into an unattributable change. Medium/High remain explicit and separate.

The placeholders above are the actual execution-time Git identity, not a stage/source-admission protocol. No source pin, job manifest, hash inventory, validator, teardown collector or new harness was created. The full existing capture_f39_tidewake_matrix.gd route is preserved separately, not claimed ready through these small samples. Current tidewake_look.enabled, water_current_cue.enabled and water_dune_cover.shore_ecology_candidate.enabled remain false. Historical dock/current failures still need real game improvement and three fresh blind judges; no old single-judge verdict closes them. **Await root Look30 decision/grant; unresolved full-world shutdown must be explicitly retained if a direct attempt is authorized. No native since turn26 release.**
### Turn30 actual parser/resource blocker before direct capture

At05:15:20CT, existing Godot --headless --path D:/tetherbound/restart-look --check-only --script res://tools/capture_tidewake_f13_5.gd returned0 but logged real missing-preload errors for pump_station.tscn and heart_crystal.tscn. Classified FAIL, no waiver. Normal Git restoration recovered10 missing tracked files comprising those scenes and their direct GLB/shader/texture/import metadata dependencies, preserving existing files. The same parser at05:16:20CT then reproduced the narrower missing imported .scn resources for both GLBs; exit0 again does not make that pass. Minimum existing route is Godot's ordinary headless editor --import to materialize the required imported resources, with no new import script, source edit, bake, validator or capture change. A plain source restore cannot create those generated imports. Immediately after a successful import, rerun the existing parser and execute the granted direct Medium baseline. Preserve all parser/import logs and any unrelated errors; no blanket clean-runtime claim.
The first actual Medium function run at05:18:19–05:20:45CT, PID20132, completed34 JPGs and exited naturally0 within180s. This is successful full-world process exit on the actual current checkout, not proof that every historical exit case is repaired. The raster is1920x1061: the legacy non-fixed branch does not lock viewport dimensions and window chrome reduced client height. Runtime logs also name missing creature/Veilfall/cloth/nature resources. One justified retry will keep script/stands/preset/resolution/cap unchanged, add Godot's existing --fullscreen to obtain the requested client raster, and use normally restored exact missing tracked paths plus direct TSCN dependencies from this log. No generated images are resized. Original34 images/errors remain unchanged; they cannot serve as the restored/fullscreen matched baseline. Normal existing --import follows resource restoration; no new source/capture/harness or art tuning. No further actual capture retry is available if this attempt fails.
### Turn30 direct function matrix, actual result (15 October CT)

Source for every native child: `b52b06177633516b81002a20788149646e69b39a`, pushed tb/look. Existing `tools/capture_tidewake_f13_5.gd` unchanged. No source/candidate configuration changes between the corrected paired captures. Executable and APPDATA are exactly those recorded above; direct Start-Process, WindowStyle Hidden, each actual render child bound180s unchanged.

After the first two parser failures, the existing importer PID19232 ran05:17:12–05:17:37, natural0. Parser PID43124 then ran05:17:47–05:18:03, natural0 with no logged parse errors. For the single raster retry, normal Git restoration recovered29 actual missing paths plus10 direct scene dependencies; existing importer PID63784 ran05:22:11–05:23:04, natural0. These are ordinary checkout/import materializations, not source fixes or new infrastructure. Original parser/import/runtime failures remain preserved.

All actual render commands use this prefix, with each row's log/output/preset and candidate argument:
```text
C:/Users/mattj/.cache/tetherbound-tools/godot-4.7/Godot_v4.7-stable_win64.exe
--path D:/tetherbound/restart-look --rendering-method forward_plus --rendering-driver vulkan
--resolution 1920x1080 --fullscreen
--log-file D:/tetherbound/restart-look/.artifacts/<stem>.log
--script res://tools/capture_tidewake_f13_5.gd --
--out=D:/tetherbound/restart-look/.artifacts/<stem> --preset=<preset> --only=veilfall,docks,currents
```
The original first attempt omitted only --fullscreen and used stem look30-f13-medium-baseline; actual1920x1061, so excluded from the matched comparison. Candidate rows append exactly `--tidewake-current-candidate`; baseline rows append nothing. No look/shore candidate flags or restored-current flags were passed.

| Stem | Preset / arm | PID | Actual start/end CT | Result |
|---|---|---|---|---|
| look30-f13-medium-baseline | Medium baseline, original raster failure |20132|05:18:19.400–05:20:45.924|34 JPGs,1920x1061,natural0; retained, not matched baseline|
| look30-f13-medium-baseline-retry | Medium baseline, sole retry |28768|05:23:17.333–05:25:47.374|34 JPGs,natural0|
| look30-f13-medium-candidate | Medium current cue |29692|05:26:04.131–05:28:34.546|34 JPGs,natural0|
| look30-f13-high-baseline | High baseline |14932|05:28:49.166–05:31:21.753|34 JPGs,natural0|

**Coverage failure:** actual original images for all three nominal swimmer viewpoints show a standing trainer at the shoreline; current-cue HUD is absent. Their filenames and the script's CAPTURE OK marker do not establish swimming or visible candidate-branch execution. Do not score or accept swimmer cue from these pairs. Runtime population also varies between runs, so differences in ambient species are not an attributable candidate improvement. This matrix is daytime, not full F39 weather/night/fight coverage or the required>=200 frames.

**Runtime remains unclean:** corrected captures still log missing limestone_spire_2.obj/Veilfall kitbash piece, missing installed Captain Nerissa encounter and NPC configs with no usable model. The original non-fullscreen run additionally logged missing creature resources during ambient spawning; preserve that exact log. Landmark completeness and inhabited-dock acceptance cannot pass with missing participants/pieces. No further asset correction or capture retry this turn. The three fresh blind judges evaluate delivered images only, separately from these failed runtime/coverage gates. Zero criteria closed; all production candidates remain OFF.

High candidate stem `look30-f13-high-candidate`, PID7560, ran05:31:54.782–05:34:25.063CT,34 JPGs, natural0. All136 corrected Medium/High original JPGs were inspected for raster dimensions:1920x1080. The original34 wrong-raster JPGs remain separate. **END30 native released for Fights31 at05:34:48CT; live Godot process census empty.** No further native/import or T2 attempt in this turn. Actual render turn used five children, one justified retry; each natural exit was within180s.

Original170 JPGs, all turn30 parser/import/render logs,18 neutral contact sheets and SHA256SUMS are preserved in `turn30-direct.zip` (relative artifact paths inside). Full-resolution paired originals remain local under `.artifacts/look30-blind/`; sheets are presentation thumbnails, originals unchanged. Neutral mapping held from judges: A=current-cue candidate, B=baseline. Three independent fresh Tidewake judgments requested after native release; two use prior Meadows-only blind judge agents because the new-agent thread limit rejected a second new agent. Neither reused judge has Tidewake source/history or this round's mapping. No previous scores are reused.

**Next Look34 proof (UNRUN, no native authority implied):** use the already-preserved T2-current command above at1920x1080, existing script AS-IS, with `--fullscreen`, fresh `look34-t2-<preset>-<arm>` log/output paths and actual pushed sourceSHA. Medium baseline first, then matched `--tidewake-current-candidate`, High pair if granted. Fixed route asserts actual human swimming/current and candidate cue visibility; it is a distinct existing supported route, not a recapture of unchanged dry-shore frames. Do not suppress or modify its assertions. Mounted/combat/modal/diving/co-op/restored-current and other required T2 witnesses remain separate. No edits to capture, no cap increase, no score for an unexercised branch.

### Turn30 three independent blind verdicts and game response

All three judges inspected18 sheets covering136 corrected originals, the Tidewake boards, dunes direction, keyart and Palworld/Valheim references. J1 additionally opened4 originals; J2 andJ3 opened8 each. All returned **A/B TIE, FAIL** on both presets; no consistent preset improvement. Original rubric was ART_DIRECTION's **Bar A=creature/world appeal** and **Bar B=light/atmosphere**, clarified explicitly before aggregation:

| Judge | Medium baseline A/B bars | Medium candidate A/B bars | High baseline A/B bars | High candidate A/B bars |
|---|---|---|---|---|
| tidewake30_blind1 |4.5 /4.0|4.5 /4.0|4.5 /4.0|4.5 /4.0|
| meadows22_blind_1, fresh Tidewake review |5.0 /4.8|5.0 /4.8|5.0 /4.8|5.0 /4.8|
| meadows22_blind_2, fresh Tidewake review |4.8 /5.0|4.8 /5.0|4.8 /5.0|4.8 /5.0|
| Mean; min–max; spread |4.7667 [4.5,5.0],0.5 /4.6000 [4.0,5.0],1.0|same|same|same|

The skill uses another Bar B label for shipped-game reference comparison. Do not mix that with atmosphere scores: the two still-blind reused agents separately clarified own-art/shipped-game reference scores5.0/4.7 and4.8/4.5, tied on both arms/presets. No three-judge aggregate is claimed for that separate reference comparison because J1 had already moved to source review and correctly refused rescoring after code exposure. All three original blind verdicts fail both actual ART_DIRECTION bars;8.5 unchanged. Gain=0 for this delivered subset, **not a current-cue improvement round**, because the cue branch was not visibly exercised.

Shared concrete findings: (1) `current_salt_crown_to_sluice_isle` and shore-side `swim_*` images show oversized opaque chevrons, regular dashed boundaries, orange boxes and cyan triangular forms over comparatively calm water: direction is readable but resembles a marked obstacle course. (2) `dock_reedhaven`, Brine Steps, Shellwatch and Salt Crown repeat small jetties/people/cargo within bare sand; Reedhaven's grass obscures the approach, no sheltered working-space hierarchy. Sluice's blue control block remains visibly unfinished. (3) Veilfall is visible and grows with approach, but reads as a smooth steep mound with strips of falls and projecting chunks, rather than the board's stepped inhabited mountain; First Shore hides most behind a dune and Sluice crops the crown. Geometry/composition needed, not tint alone. Creature population/overlap confounds remain. No judge claims swimming, mounted traversal, current force, motion quality, night/weather/fight, full landmark or fullbiome acceptance.

**Player-visible game response, stated before editing:** make the Reedhaven landing read as a sheltered working place from the dock approach. `water_dock_dressing.gd` now reads a narrowly scoped workplace section only under the existing OFF `tidewake_look.enabled` gate/process-local `--tidewake-look-candidate` preview. One exact anchor gets an installed Fantasy Props covered stall, adjacent workbench and waiting bench. Neutral sailcloth replaces only the installed MI_Banner material; authored timber/metal remain. Positions mirror to the side away from existing return ramps, using the existing ground sampler; no collisions, NPC changes, current strength, interactions, persistence or networking changes. Tunables stay in `tidewake_look.json`. This is distinct from the current HUD cue arm; do not enable the look flag during the next isolated cue comparison.

Validation: JSON parses; exact departure anchor and three existing installed glTF assets/material name confirmed; scoped diff check passes. Independent changed-source review by tidewake30_blind1 after its blind verdict: bounded PASS, defaultOFF/local presentation/material isolation; **no native parser/import/render** afterEND30. Review noted original0.9m bench seat was oversized; reduced config to0.55m (about2.86m long from installed bounds). Adjacent workbench intentionally sits outside the shallow canopy rather than overlapping the stall's built-in counter. Full-footprint terrain contact, visibility through grass, cloth match at runtime, spacing and route readability remain UNPROVED. No new asset, harness, capture-script change or stage operation.

Next: Look34's existing T2 fixed route first, under a new root native grant, for actual swimming/cue witness. The Reedhaven workplace separately requires matched existing dock views with the Tidewake look arm on Medium/High and three blind judges, followed by the full required F13/F39 proof/landing. Game candidate is unrendered and OFF. **Zero criteria closed.** F38 stays OPEN/render-blocked with its old scores VOID; F17 stays explicitly parked OPEN/OFF. No acceptance is inferred from these source/evidence commits.


### Next fixed-queue selection after Look54 - F13#5 inhabited Reedhaven landing

Root15Oct14:18CT directed CPUselection afterF17's second-flatarchitecture/signagepark. F38#0 remainsrender-blocked by two actualturn26restored-world allocationfailures beforeframes; its prior5.67score isVOID. No thirdallocationattempt/profiling is proposed. The next eligible fixedqueue criterion isF13#5, bounded work package=inhabiteddockread atReedhaven, onebiomeTidewake. FullF13#5 remainsopen forcurrents/inhabiteddocks/Veilfall; noF39advance orclaimthatone dock closeswholecriterion.

Concrete expected player-visible improvement: the Reedhaven landing reads as a sheltered working place, with the already-authored installedFantasy stall, workbench and waitingbench grouped beside cargo and outside the departure/return corridor. This candidate alreadyexists atcurrentpushedsource1f405f5079, reviewedbutunrendered fromturn30, under tidewake_look.enabled=false. No speculative additional artchange before witnessingit. Preserve its priorreview; do not re-reviewunchangedcode to staybusy. Currentcue and shoreecology candidates remainOFF.

Existing boundedproof proposed for explicitLook58 grant: tools/capture_tidewake_f13_5.gd AS-IS, --only=docks. It emits the same sevenmandatorydockapproach views as turn30, from20m inland withproductionCameraRig and disclosedmid-chapterflags. Turn30 actualMedium/High functionruns reachednatural0 inside180s and supplied1920x1080 with--fullscreen, so this is a preserved executablepath, not a newharness. No current/swimmerframes are used to infercueexecution. Compare matchedMedium/High baseline/candidate, 7JPGseach=28originals, threefreshcode-blindjudgesbotharms/current7.5BarA/reportBarB. Ambientpopulationisnotlocked, so onlystaticworkplacecomposition is attributable; no populationimprovementclaim.

To isolate the threeprops rather than bundle lighting: botharms use existing --tidewake-look-candidate and identicallookconfig. At a pushed diagnostic controlcommit, only dock_workplace.props is empty; at candidatecommit restore the existingthreeprops. This uses the existing gameconfig and builder's emptyarray behavior, no fileoverlay/newflag/captureedit. Restore exact allOFFproductionconfig and pushbeforeEND. Existing180s perchildbound, oneactualfailure retry, latestrootresourcebudget apply withoutchange. If actualruntimefails, preservefailureandstop as directed; no automaticrepairproject. Changedgame-scriptcheck-only, if required, uses the existingGodotcheck-only route under the grant, never now.

Proposed actualargv pattern (UNRUN): `--path D:/tetherbound/restart-look --rendering-method forward_plus --rendering-driver vulkan --resolution 1920x1080 --fullscreen --log-file D:/tetherbound/restart-look/.artifacts/look58-docks-RUN.log --script res://tools/capture_tidewake_f13_5.gd -- --out=D:/tetherbound/restart-look/.artifacts/look58-docks-RUN --preset=PRESET --only=docks --tidewake-look-candidate`. Existing executable C:/Users/mattj/.cache/tetherbound-tools/godot-4.7/Godot_v4.7-stable_win64.exe, APPDATA=D:/tetherbound/restart-look/.artifacts/f17-direct/user. ActualSHA/commands/times will be recorded only ifexecuted. Neitherlookflag norpropsmodified for thisCPUproposal.

Unresolvedprooflimits: turn30 missingNerissa/NPCmodel/limestonepieces remain historicalruntimefailures until actualcurrentlogs/images establishotherwise. No clean-runtime claim or assetinventorygate. The seven dockviews do not supplyswimming/currentforce, Veilfallclose/distance, weather/night/fight orF39>=200-framecoverage. A docksubsetpasscannotactivate the wholeTidewakelookrecipe orcloseF13#5. Requiredremainingproofandlandingstillgovern. Zero criteria closed. This is rootrequested selection of existinggamework and concreteproof, not a newtooling/reporting task. No native sinceLook54END14:08:37CT; waitfornextgrant.


### Look58 CPU preparation - root approved, native grant still pending

Root approved23fa9641e0 selection: F13#5Reedhaven workplace, sameTidewakelightingbotharms, sevenexistingviews/fourruns/28images/threeblindjudges. Current game config/script remainunchanged andOFF; no additional reviewofunchangedsource. Game/source basis is23fa9641e08d6583691e154ff35f9a870481c765; actual previewSHAs will be newlycommitted/pushed at execution, never relabel historicalsource. Control changes only tidewake_look.dock_workplace.props to[]; candidate restores the exactthreeexistingprops. Both use existing --tidewake-look-candidate, leaving everyotherlookvalue andproductionflagsidentical. No currentcue/shorecandidateflag. Namedprops: ReedhavenCoveredWorkplace[7.6,1.0]/height3.1; ReedhavenWorkBench[7.6,-0.6]/height0.95; ReedhavenWaitingBench[5.8,4.3]/height0.55, at reedhaven_to_brine_steps_departure. No sourceedit now, no newpreviewfacility.

Exactexistingcamera derivation: each mandatorydock safe_position is the look target; standXZ is20m toward its islandcenter. Existing _pose sets actualY=max(ground_height_at,anchorY)+0.3 andproductionrigyaw towardtarget; existing _shot settles240frames, repeats_pose, settles60frames andgrabs. No authoredpitch/FOV override orscriptchange. Derived standXZ below is source arithmetic, NOT observedplayer/cameraposition; runtime logs/images remain authoritative.

| Existing output | Derived stand X,Z metres | Target anchor X,Y,Z metres |
|---|---|---|
|dock_first_shore.jpg|0.000, 142.000|0.000, 1.929, 162.000|
|dock_reedhaven.jpg|125.788, 505.889|143.505, 1.929, 515.169|
|dock_brine_steps.jpg|387.711, 808.530|383.462, 1.929, 828.074|
|dock_shellwatch.jpg|423.325, 1231.481|436.920, 1.929, 1246.150|
|dock_tidal_cradle.jpg|572.067, 1711.431|560.542, 1.929, 1727.776|
|dock_salt_crown.jpg|312.680, 2461.060|327.336, 1.929, 2474.669|
|dock_sluice_isle.jpg|728.413, 3180.727|718.763, 1.929, 3198.245|

Resourceproposal from actualturn30 seven-dock originals: Mediumcontrol2,271,746B; Mediumcandidate2,272,475B; Highcontrol2,255,584B; Highcandidate2,256,973B, total9,056,778B. CurrentDfree20.55GiB. ProposedTurn58totalgrowthcap128MiB (0.125GiB), including freshimages/logs, fourpairedsheets, requiredarchive andGitcopies; nativePNGconversion notneeded. Neutralfullresolutionnames use hardlinks, no payloadcopies. Expectedgrowthroughly50-65MiB, but the128MiB ceiling is a cap, not guaranteedusage. Keep existingD>=20GiB floor; if actualcapacity is insufficient atgrant/execution, leaveproofunrun or stop rather than deleteuniqueevidence or silentlyraisebudget. No cleanup, extraarchives, largeCwrites or newprofiling. Actualtime/resourcecapsotherwiseunchanged. Fourserialchildren at existing180s each, oneactualfailure retryifneeded andauthorized. Latestgrant maytighten these bounds.

Execution remains exactly the existing command documentedabove, with fresh look58-docks-{medium-base,medium-workplace,high-base,high-workplace} outputs and matchingMedium/High preferences. Each mustyieldseven1920x1080originals andnaturalexit, errorsretained. BeforeCPUjudges: restore exactOFFconfig,push,recordEND andnativecensus/yield. Runtime/resource/geometry/population/coverage limitations fromturn30remainexplicit; no dryshoreframes qualifyasswimming, andno docksubset closesfullF13/F39. CPUpreparationcomplete; no native beforegrant and no toolingwork whilewaiting.


### Look58 direct Reedhaven workplace proof — 15 Oct 15:04–15:13 CT

Root authorized the exact seven-dock comparison with a 128 MiB total D-growth cap, D>=20 GiB, unchanged 180-second child bounds and one actual-failure retry. No retry was needed. Control source `7e116b23b05644a3140e83272b0f67675c728280` has only `dock_workplace.props=[]`; candidate `677cc19cde6d4df7bf463766263eaf01cb0a0efa` restores the three existing props. Both pushed before launch. Both use the same process-local Tidewake look preview; all lighting, materials, cameras, gameplay flags and source scripts are identical between arms. The production look flag remains false. No capture edits, imports, restoration of runtime assets, new tools, stage work or generation occurred.

Actual executable: `C:/Users/mattj/.cache/tetherbound-tools/godot-4.7/Godot_v4.7-stable_win64.exe`. APPDATA=`D:/tetherbound/restart-look/.artifacts/f17-direct/user`. Common actual argv: `--path D:/tetherbound/restart-look --rendering-method forward_plus --rendering-driver vulkan --resolution 1920x1080 --fullscreen --log-file D:/tetherbound/restart-look/.artifacts/look58-docks-RUN.log --script res://tools/capture_tidewake_f13_5.gd -- --out=D:/tetherbound/restart-look/.artifacts/look58-docks-RUN --preset=PRESET --only=docks --tidewake-look-candidate`. Each preset also had its matching ordinary graphics preference. Existing capture code chooses the requested preset and rejects unavailable/restart-required combinations; actual logs identify Forward+ Vulkan GTX1060 3GB.

| RUN | PRESET | Source | Actual CT interval | PID | Exit / frames | Diagnostic lines |
|---|---|---|---|---:|---|---:|
|medium-base|Medium|7e116b23b0|15:04:31–15:06:34|22500|natural 0 / 7 JPGs|27|
|high-base|High|7e116b23b0|15:07:11–15:08:32|11356|natural 0 / 7 JPGs|27|
|medium-workplace|Medium|677cc19cde|15:09:30–15:10:47|17860|natural 0 / 7 JPGs|27|
|high-workplace|High|677cc19cde|15:11:34–15:12:51|43480|natural 0 / 7 JPGs|25|

All 28 original JPGs are 1920x1080. All runs log CAPTURE OK frames=7 and natural teardown. The legacy seven-view route writes no JSON manifest; no manifest or clean-runtime result is invented. Every run retains missing `assets/environment/cloudreach/limestone_spire_2.obj`, missing installed Captain Nerissa encounter and unusable NPC model errors. Every run also retains the warning that water_mirejaw was reduced to 3.28m despite its 3.55m collider allowance. Those are unresolved game/runtime issues, not waived warnings. No unrelated correction was made between matched arms. The visible Reedhaven workplace establishes actual candidate geometry execution; ambient creature species/poses vary and are not attributable to it.

Candidate source already restores the exact original OFF config bytes; confirmed at native end and push returned up-to-date. **Turn58 END / yield Fights59 at15:13:34 CT**, actual Win32_Process census empty for Godot/Blender, BEFORE CPU judges. No native calls after END. Dfree20.38 GiB then versus20.41 at grant. Two tracked Water art boards were normally materialized for judge reference (about6.12MB); these are documentation images, not runtime changes. Neutral original names are hardlinks, and four sheets use existing tools/sheet.py.

All originals and logs remain under `.artifacts/look58-docks-{medium,high}-{base,workplace}`; neutral hardlinks/sheets under `.artifacts/look58-neutral`. Required preservation `turn58-direct.zip` contains 28 originals, four unchanged logs, four sheets and SHA256SUMS.txt; all36 payload hashes verified. Archive size16,037,035 bytes. Medium Reedhaven hashes: control `faec76b5d218d27b327266a786f7fa42d8af8d8f287bb263d86b4117584f9a0e`; candidate `452907092b6aeb16c8e93fa5879cda8145c0156a5a084d7d459d5241f65ac689`. High: control `c25128f9a11bb6b88f8bb66aa01f1ccaf2b65c70b6fa8cdddd2e3820571003c9`; candidate `3a4392715f9b3ac84739bb66442461359dc94085a1d74ad0cfa852658dfe2ec4`. Exact log hashes are in the same preserved sums file.

Neutral mapping withheld from three fresh judges: A=workplace candidate, B=empty-workplace control, both presets. Judges receive all four sheets/28 originals, actual Water boards/keyart/Palworld references and ART_DIRECTION's current Bar A appeal / Bar B light definitions. Overall seven-dock and per-dock Bar A scores requested separately; a localized improvement is not whole-criterion acceptance. Current threshold7.5 unchanged. Actual Iona post is not covered; no trench/placeholder resolution claim. These daylight dock views prove no swimming/current force, Veilfall journey, night/weather/fight, earned arrival, performance or full F39 coverage. Historical dry-shore swimmer failures remain preserved. F13#5 and F39 stay OPEN; all candidates OFF; zero criteria closed. Fresh verdict pending.


### Look58 final three-judge panel — workplace remains OFF

All three fresh independent judgments are complete. Each inspected all four neutral sheets (28 images), actual Tidewake boards, keyart and Palworld references, plus native originals (hall34_blind3: six; hall50_blind3 and meadows22_blind_2: fourteen each). No judge received source, arm mapping or another verdict before returning its verdict. Mapping is now disclosed: A=three-prop workplace candidate; B=empty-workplace control. All three narrowly prefer A because Reedhaven's canopy gives the landing a recognizable inhabited destination. Medium and High received identical scores; this is not evidence of a preset-quality gain.

| Judge | Candidate Bar A, Medium / High | Control Bar A, Medium / High | Bar B, either arm/preset | Reedhaven candidate / control Bar A |
|---|---|---|---|---|
| hall34_blind3 |5.0 / 5.0|4.9 / 4.9|4.5|5.6 / 5.1|
| hall50_blind3 |4.6 / 4.6|4.5 / 4.5|4.0|5.2 / 4.6|
| meadows22_blind_2 |4.7 / 4.7|4.6 / 4.6|4.5|5.3 / 4.9|

Seven-dock Bar A mean: candidate **4.7667**, range4.6–5.0, spread0.4; control **4.6667**, range4.5–4.9, spread0.4. Paired gain **+0.1000** on both presets. Bar B mean **4.3333** for both arms/presets, range4.0–4.5, spread0.5. Every judge fails the current7.5 Bar A bar and the atmosphere target. These are panel-reported overall scores, not a substitute calculation from rounded per-dock scores.

| Dock | Candidate Bar A mean [range]; spread | Control Bar A mean [range]; spread | Paired mean gain |
|---|---|---|---|
| First Shore |5.5667 [5.4,5.8];0.4|5.4667 [5.2,5.8];0.6|+0.1000, NOT attributable to workplace|
| Reedhaven |5.3667 [5.2,5.6];0.4|4.8667 [4.6,5.1];0.5|+0.5000|
| Brine Steps |4.7667 [4.6,5.0];0.4|same|0|
| Shellwatch |4.3333 [4.2,4.6];0.4|same|0|
| Tidal Cradle |4.9333 [4.8,5.2];0.4|same|0|
| Salt Crown |4.5333 [4.4,4.8];0.4|same|0|
| Sluice Isle |3.7333 [3.6,3.8];0.2|same|0|

Per-dock results above apply identically to Medium and High. meadows22_blind_2 also preferred a First Shore sign in A; preserve that observation but do not attribute it to this treatment: the controlled source delta affects Reedhaven only. The other two judges tie First Shore. Fresh ambient creature populations/poses differ, so neither actors nor that nonlocal observation establishes workplace causality. No claim that other docks improved.

Shared defects are concrete: enormous white arrows and yellow dashed water boundaries overpower small timber destinations; Brine Steps, Shellwatch and Salt Crown lack distinctive occupied working clusters; Shellwatch/Sluice's plain block-and-post structures read unfinished, and the Sluice foreground block hides the trainer. Abrupt dune cuts, broad uniform water and Veilfall's simple mound/strip waterfalls flatten the setting. Pale dunes and coastal grass are appropriate; converting Tidewake to Meadows grass is not the remedy. All judges favor installed scene/material/prop work first. A convincing sluice kitbash is needed; these images do not establish a need for newly generated hero art.

Disposition: the workplace's first actual improvement round gives a localized Reedhaven gain of0.5, but the seven-dock gain is only0.1 and all scores remain below bar. Do not conflate these scopes or count the prior unexercised current-cue diagnostic as another workplace round. Keep the candidate OFF. F13#5/F39 remain OPEN, zero closures; no full-biome, performance, current-motion, swimming, night/weather/fight, Iona-post or clean-runtime acceptance. The retained missing limestone piece/Nerissa/NPC model errors and Mirejaw scale warning remain unresolved, despite four natural0 exits and28 valid frames.

Next bounded game/proof action for root selection: improve one unfinished dock mechanism/working cluster with the installed coherent family, or address dominant water-route graphics while preserving navigation; scope one change and state its visible result before editing. Do not spend another turn recapturing the unchanged workplace. Any next native proof requires a new grant and the preserved fixed views, full-resolution paired images and three fresh blind verdicts; the remaining complete F13/F39 proof and landing are still required. No native before the root's next Look turn62; Fights59 owns the released slot, followed by Creatures60/Routes61. Turn58 already ended15:13:34CT. Total observed D growth including preservation/Git is about61MiB, within128MiB; no additional payload copies or cleanup performed. No alternate cleanup attempt after root's reported automatic-review rejection.


### Next F13#5 game change — eastern sluice mechanism, Turn62 proof proposed

Root acknowledged7cd36c0986 and authorized CPU implementation of one selected dock defect, with scoped source review and no native before62. Expected visible result stated before edits: the actual foreground eastern-control block becomes a recognizable low timber-and-metal winding mechanism with an open handwheel, improving the occupied dock's purpose and reducing its solid obstruction of the trainer. Turn58 high_A_dock_sluice_isle.jpg visibly identifies this interaction as "Open the eastern sluice"; all three judges independently called its box-and-post silhouette unfinished. This is one control, not a cure for water graphics, other docks, missing NPCs or Veilfall.

Game change: water_dock_actions.gd checks the existing Tidewake look gate and exact configured action_id before replacing only the equipment visual. tidewake_look.json adds local sluice_winch tunables; enabled remains false. Installed Floor_WoodDark and Roof_Log form a low deck/support/bearing frame, installed Barrel supplies the drum and Chain_Coil the spare chain, with a small iron ring/spokes/axle. Source assets are untouched; no new generated asset or payload. Geometry is centred using existing render_bounds, materials use the existing Tidewake family. Original interaction origin/label/range, activation, transactions, world flags, progression and collision remain unchanged. The old visual remains the OFF/default and load-failure fallback; missing model logs remain errors, never a passing candidate result. No changes to workplace, lighting, water, capture scripts, native tooling or other lane source.

CPU validation: config parses, OFF gate retained, four distinct referenced installed glTFs present, scoped diff check clean. Independent source review by sluice62_source_review: bounded PASS, no concrete GDScript/API error; isolated gate, local material instances and coherent support/beam/drum/axle geometry. Corrected size lookup to piece["size"] to avoid Dictionary method/key ambiguity. Reviewer inspected installed node transforms/import collision settings. No native parser/import/render was run. Reviewer is now source-aware and must not blind-judge this candidate. Remaining actual-proof risks: rotated visual footprint exceeds old axis-aligned base, original equipment has no collision, trainer overlap/ground contact/handwheel readability/fixed-camera occlusion and mechanical appearance are unproved. No claim of visual improvement yet.

Proposed existing Turn62 proof, only under a new root grant: unchanged tools/capture_tidewake_f13_5.gd, --only=docks, seven fixed views, matched Medium/High at1920x1080/fullscreen,28 fresh JPGs. Both arms use --tidewake-look-candidate and identical lighting/workplace/config; pushed control changes only sluice_winch.action_id to an empty string, then pushed candidate restores sluice_east_control. This uses existing game selection, not a new capture option/overlay/tool. Actual SHA and commands will be recorded when executed. Same executable/APPDATA and preserved command pattern as Turn58, fresh look62-docks-{medium-base,medium-winch,high-base,high-winch} output/log stems. Preserve existing180s child cap and root's latest retry/resource limits; no native now. Restore exact OFF production config before END. Three fresh independent code-blind judges score both complete seven-dock sets and Sluice Isle separately, report current7.5 Bar A mean/spread and Bar B; no fixed-camera change or subset closure. Inspect actual images/logs for the named risks and unresolved runtime errors. The full required F13/F39 evidence and landing remain open.

Resource scope: only these two game files plus this existing note change during CPU work; no large payloads/restoration/cleanup/copies. Root reported D20.27GiB; proposed fresh proof retains the prior128MiB total growth ceiling including preservation and push, and D>=20GiB, subject to latest grant. Nothing here authorizes a native launch or claims missing Veilfall/Nerissa/NPC resources fixed. All candidates OFF; zero criteria closed.
