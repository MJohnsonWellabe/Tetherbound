# Cloudreach Phase 2c integration validation

The disposition package records 20 deferred owned rows at impact >=12, zero fixed. Regional Bars A/B remain No/No. This receipt proves bounded integration checks, not visual or gameplay acceptance.

## Source and unit run

The full local suite covered all 625 discovered test files exactly once across four round-robin shards before main integration. The candidate executable source was unchanged from `0f2303feb`; the pre-merge branch tip was `c587ecca2`. Main `cf0a3b97494f3c0160ed230605932add35dd9b18` was merged as `b37e08891` after every shard terminated.

| Local log | Tests | Assertions | Failed | SHA-256 |
|---|---:|---:|---:|---|
| `unit-1.log` | 1236 | 2679175 | 1 | `cf9a017fc365f2420a5e0a1f4ee26112c5fce516fe9ac735c247ce8d8399ef63` |
| `unit-2.log` | 1416 | 903819 | 0 | `03b33cdcbc7da7665038c5e70b82ee05433a735d4bf5c25a5c4aac20539a0f41` |
| `unit-3.log` | 1366 | 257294 | 0 | `a267cc432aae38b518d3b8173cfe53d9f9be0bb5cf1e1e6c01d54a864cecfbe0` |
| `unit-4.log` | 1202 | 120451 | 0 | `e4972c6bf16ed690524c932b49c2fe731c39ca0a79cc9c408523585c28aaf967` |
| `unit-ledger-recheck.log` | 2 | 28 | 0 | `4532338a5690e2f2c2489a34bdc552d4b69384fee0d7e1ea3c6d8f05822dbcce` |
| `integration-focused.log` | 105 | 1685 | 0 | `6263089e4c96710286d3eb05b08efc68307b9e97ce6d77f25ad813ac6838bd0b` |

Shard 1 exited 1. Its only assertion failure was `test_meadows_named_location_ledger_0912.gd::test_final_polish_locations_have_complete_accepted_evidence_rounds`: four tracked historical evidence folders were absent from this sparse checkout. Restoring those folders and rerunning the entire affected file passed 2 tests / 28 assertions, exit 0. Shards 2–4 exited 0. The first failure is retained; this is not a claim that all four original processes exited 0.

The post-merge focused run at `b37e08891` exited 0: `test_fly_traversal.gd`, `test_merged_progression.gd`, `test_hud_party_vitals.gd`, `test_stormwood_surge_presentation.gd`, `test_cloudreach_aviary_architecture.gd`, `test_creature_viewport_framing.gd`, and `test_texture_import_policy.gd` (105 tests / 1,685 assertions / 0 failed). It covers incoming Fly/progression and shared presentation changes plus this lane's architecture/framing/import invariants. It does not repeat the full unit suite on the merge.

Some headless logs include teardown RID/ObjectDB/resource leak diagnostics, including the focused run. Exit codes/assertion results above are not a clean-engine-log claim. Raw logs remain local under `.artifacts/cloudreach-phase2/`; hashes identify those exact results.

## Evidence and merge checks

- `texture_import_policy.py --check`: all 424 runtime 3D texture sidecars use mode 2.
- `audit-package.py`: 20 owned rows, all deferred with named follow-up ownership; owned top-20 entries equal the catalog; all 11 compact evidence rounds verify; skyline, crown arcade and legacy tower flags remain false.
- Catalog conflicts resolved by owner: Cloudreach rows from the reviewed lane; every other row from main. STATE retains main's owned-carrier Fly closure and this lane's explicit visual debt.
- Independent final integration review by `p2_021_code_review`: other lanes and owned-carrier Fly preserved; all six executable/config/test/tool files match prior reviews. One generated-dashboard encoding regression was found. The dashboard was rebuilt using Python `-X utf8`; strict UTF-8 decoding, zero replacement characters and correct half/quarter fractions were verified.
- Existing native GPU paired and regional judge artifacts retain their FAIL / No-No verdicts and capture limits. Disabled candidates were not re-enabled or represented as accepted fixes.

PR CI and main ancestry are separate landing gates, verified through GitHub and git after this receipt; this file does not pre-claim either.

## Current-main integration after Meadows and Balance

Main `e1d036903` (Balance #413 and Meadows #417) merged cleanly as `59776928a91aa688cfec11ec151494558fd4e30b`. Incoming shared combat, dialogue-camera and HUD changes justified another focused integration run. The lane's six executable/config/test/tool files remain identical to the preceding reviewed source.

`integration-main-e1d.log`: 93 tests / 4196 assertions / 0 failed, exit 0; SHA-256 `6f20752443793624c335f0351666bbada4008292bead6a51a9dd163dbf559873`. Covered suites: alpha pins, Cloudreach aviary architecture, conversation-camera aftermath profile, creature viewport framing, texture import policy, earned Hall and relay segments, Meadows route ambush spacing, named-fight profiles/tell timing, named-trainer wild clearing, open-door prompts, stronghold Warden arena and trainer aftermath. Teardown RID/ObjectDB/resource diagnostics remain disclosed.

Independent `p2_021_code_review` rechecked this merge: no findings; exact six-file lane code unchanged, 20 deferred / 0 fixed, candidate flags off, STATE/board/F08 visual debt preserved, valid UTF-8 and clean diff. Rebuilding the dashboard produced no additional changes. All 118 reviewed Cloudreach evidence files have the same committed Git tree identity as before this main merge; the new receipt paragraph is subsequent documentation.

## Relay smoke integration repair

At head `e2ba9d3e010c516b737d0cebcaf56cd7833a6d4b`, CI run [36448522001, relay job 109018845576](https://github.com/MJohnsonWellabe/Tetherbound/actions/runs/36448522001/job/109018845576) failed its single relay attempt. The log records five of five opponents defeated after 7174 action frames and `relay_captain_defeated` set, followed by the exact captive prompt never becoming actionable and the rescue assertions failing. Stronghold and the remaining steps in that job passed. An unchanged local reproduction exited 1 with the same sequence after 7128 action frames; `.artifacts/cloudreach-phase2/relay-ci-repro.log` SHA-256 is `5b005920cd8e4a4878bdf77fe8adde19bebc010a413d980cbc0770893b7fa92f`.

Source inspection explains the sequence: the captain now declares `relay_captain_defeated_greeting` as automatic victory dialogue, and the panel retains input until the player completes it. The old smoke waited 180 frames, then attempted the captive interaction without advancing the dialogue. The failed baseline logs did not directly inspect panel state; this diagnosis combines their observed sequence with the source contract.

The repair changes only `tests/smoke_relay.gd`: require the exact configured victory dialogue to be open, advance it through the existing physical Interact press/release helper with a 64-press ceiling, and require its `completed` signal, closed panel and released input before rescue. Check the active conversation ID before every press and stop on failure. Battle limits, rescue-only flow and original rescue assertions stay intact. No gameplay, camera or authored data changes are included.

Independent `p2_021_code_review` inspected the actual diff and source: no actionable findings, `git diff --check` passed. The full changed smoke then exited 0: five of five opponents defeated after 6362 action frames, exact victory dialogue observed open and completed through Interact, `captive_rescued` set, exactly one Gear carried, Sela absent from the relay and present in the village with her changed greeting. This directly verifies the previously inferred panel state. `.artifacts/cloudreach-phase2/relay-ci-fix-final.log` SHA-256 is `e77cae5f1555d7d98c843273b6aa37b21ba4f0b9ca0f2b1fb5ec3d021f066ea5`.

The complete local failure and passing logs are retained as `relay-ci-baseline.txt` and `relay-ci-fixed.txt` beside this receipt. Both use fresh, isolated profiles and the same headless command (`--headless --path . --script tests/smoke_relay.gd`) with a distinct log destination. The first candidate process was deliberately stopped during world boot to add the independent review's per-press ID check; it supplies no test result. The final run above covers the complete reviewed repair. The engine's existing physics-interpolation deprecation warning appears in both retained logs. Actual code CI on the new head is still required before landing.
