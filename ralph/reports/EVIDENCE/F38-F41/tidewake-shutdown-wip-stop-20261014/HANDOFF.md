# Tidewake lane — owner stop, 14 October 2026

Implementation, tests and native work stopped on the owner's save-and-archive instruction. This is preservation, not a completed diagnostic or visual pass. The lane goal was already paused and remains paused. Do not archive this chat until root verifies the push. No stage or live lease was accessed by this lane during the stopped work.

## Source and acceptance state

- Branch: `tb/codex-look-tidewake`, checkout `D:/tetherbound/codex-look-tidewake`.
- Last functional source: `bf45595b3a06392a4633858642a63160e047e17b`, opt-in scalar shutdown resource readbacks in `tools/capture_tidewake_f13_5.gd`. Independent verdict: `PASS_SOURCE_OBSERVATION_ONLY_NATIVE_UNRUN`, review SHA `2ab5882365975aaaa422bd1279095b8c92b6a1228186bb817a030059c78304f7`.
- Previous pushed head before this preservation commit: `b4866e63ed824c9bfe02f8ce51ed0ca1c5c04e03` (evidence only). No production code changed afterward. Failing/unjudged look, current-cue and shoreline candidates remain OFF.
- Root reported its b9-to-c836 transition failed at stop time. This lane did not inspect the stage and has not bound the unfinished successor to either baseline.
- Full-world original `e006388448964301fb538209d132ff721bab1db3` shutdown **FAILED** at the 180 s cap. Its last world/Game tree-exit markers do not prove object destruction. Preserve that failure; none of the later isolated successes exonerates the full scene.
- One-region normal-quit isolation at `bf81ab6255b0b49a639bb39477e8009cb1b06793` independently **VERIFIED_PASS**: parser 1.797 s, normal quit 10.225 s, natural exit 0 and empty stderr, 47,612 cover instances alive at quit. Review SHA `dc94fb973265f5417ed61a532b133a869fd0107eeb5174e0dc6bfbfee11f0506`.
- Full-world shutdown, native typecheck of the new readbacks, candidate-on settings/controller proof, matched Medium/High captures, three blind judges, Bar A/Bar B scores and overall F13#5/T2/F39 visual acceptance remain OPEN.

## Unfinished successor — do not execute

`unfinished-successor/` preserves the exact three files being edited when the owner stopped work. They are **UNASSEMBLED, UNPARSED, UNTESTED WIP**, with no independent review and no native admission:

- `run_shutdown.ps1` is a partially transformed copy of the successful isolation supervisor. It still contains `__FULL_SOURCE_FUNCTION__` and `__RESOURCE_READBACK_FUNCTION__` placeholders and has no assembled top-level footer.
- `full_scene_helpers.ps1` contains proposed bounded Git preflight, source/readback helpers and an `Assert-CollectorReady` function that deliberately throws. There is no verified collector adapter.
- `footer.ps1` is a separate proposed admission/run/failure-cleanup tail. It has not been joined to the runner or exercised.

The draft attempts to retain lease source, reject identity mismatches, use a one-shot 5 s pipe drain, remove parameterless process waits, record forced-stop attempts, and require natural exit. These are **implementation intentions, not proven properties of the unfinished successor**. Do not assemble or test it as part of this stop/preservation action. There is no final job/admission/source binding for it.

Collector investigation found no CDB/WinDbg/ProcDump command in the checked PATH/SDK locations. PowerShell 7 could not load Appx; the Windows PowerShell compatibility query returned no WinDbg entry. No collector was verified. `C:/Windows/System32/dbghelp.dll` exists but is not a standalone verified collector. No purchase, install, attachment, dump, engine launch or native retry occurred.

## Reusable existing infrastructure

- Production capture: `tools/capture_tidewake_f13_5.gd`, reviewed source above, existing `--trace-native-teardown` option. It records actual region/count/environment summaries, native Terrain INFO and a post-root-deletion finalizer boundary. Readbacks do not measure GPU allocation or identify leak ownership. Native typecheck remains unrun.
- `frozen-readback-preparation/analyze_shutdown.py`: executable **read-only** receipt analyzer. Original local entrypoint: `D:/tetherbound/.artifacts/codex-look-tidewake/shutdown-readback-preparation-bf45595b3a/analyze_shutdown.py <receipt> --receipt-sha256 <verified hash> --require-readback`. It is an observation tool, not a process/lease/natural-exit/warning/visual acceptance oracle.
- `frozen-readback-preparation/verify_cpu.py`: existing 38-check CPU fixture; its already-recorded result is preserved. It was **not rerun after owner stop**. Synthetic counts are not native evidence. The frozen diagnostic packet is `NOT NATIVE READY`, launch disabled, packet SHA `c09d341e7cd036789792b41a1a16be3f29b6d5f9f40e5f75e21764396e9c461d`.
- `historical-isolation/supervisor/run_isolation.ps1`: successful isolated fixture supervisor, **not a full-scene substitute**. Its original entrypoint and dependencies remain at `D:/tetherbound/.artifacts/codex-look-tidewake/normal-quit-cover-bf81-r1/`. Small helper/lease/receipt scripts are preserved alongside it for reference. The historical job is saved as `.json.reference`; admission and project payload are deliberately not packaged as a runnable native job.
- Original full-world runner: `D:/tetherbound/.artifacts/codex-look-tidewake/viewport-shutdown-e006388448/native-supervisor/run_tidewake_diagnostic.ps1`. It has unbounded process/pipe waits and must **not** be reused unchanged. Its replacement is unfinished as described above.
- Bundled Python: `C:/Users/mattj/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe`. PowerShell 7: `C:/Users/mattj/.cache/codex-runtimes/codex-primary-runtime/dependencies/native/powershell/pwsh.exe`. CPU GDScript parser: `C:/CodexTemp/fights-gdtoolkit`. No tool invocation is authorized by listing these paths.

## Retained local-only artifacts

The complete artifact history remains at `D:/tetherbound/.artifacts/codex-look-tidewake/`. No cleanup or deletion was performed. Notable directories:

- `shutdown-supervisor-successor-r1/`: original unfinished three-file WIP; exact copies are tracked here.
- `shutdown-readback-preparation-bf45595b3a/`: frozen disabled preparation; small files copied here.
- `remaining-lifetimes-bbb39df2d8/`: source audit and independent review.
- `normal-quit-cover-bf81-r1/`, `normal-quit-cover-independent-cpu-r1/`, `ground-cover-delete-bf81-r1/`, `ground-cover-delete-bf81-r2/`, `terrain-delete-isolation-bf81ab6255/`, `terrain-delete-isolation-bf81ab6255-r2/`: preserve failed, blocked and successful histories separately.
- `viewport-shutdown-e006388448/`, `teardown-stack-ef06b46cc5/`: original failed full-world packet and unadmitted collector proposal.
- `settings-smoke-adfb41f1c8/`: candidate-on settings smoke preparation, still unrun.
- `D:/tetherbound/.artifacts/s/run-twdiag-e006-r1/`: original failure, logs and single shore image; small receipt/log copies are tracked here, bulk capture/home artifacts remain local.
- `D:/tetherbound/.artifacts/s/run-twquit-isolation-bf81-r1/`: successful normal-quit isolated run.
- `D:/tetherbound/.artifacts/portable-native-batch/tidewake-normal-quit-cover-bf81/`: full portable raw evidence, SHA `d439a2c46154342b196a7e7f5e9e9740423417e453d705f330babca25ab49584`, intentionally not duplicated into Git.

`preservation-manifest.json` records original paths, exact-byte hashes and sizes of the 25 copied files (176,090 bytes). These copies preserve history; embedded absolute paths and original hash manifests were not rewritten to make copies executable. No secrets, lease files or bulk generated caches were copied.

No long-running child was started during the unfinished supervisor work. All lane tool calls completed before handoff; no native child was launched. Final remote HEAD and dirty status are reported after the preservation push, outside this pre-commit document.
