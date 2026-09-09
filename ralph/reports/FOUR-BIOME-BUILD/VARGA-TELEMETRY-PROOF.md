# Varga isolated telemetry proof — 2026-09-09

## Verdict

The corrected, bounded native proof passed 11 checks, exit 0, with zero matches
for `SCRIPT ERROR`, `^ERROR:` or `WARNING:` in `engine3.log`. It preserved an
accepted miss, a subsequent accepted damaging hit, and a terminal snapshot while
both the production manager and encounter authority remained active. This proves
the new collector's isolated host-strike seam, **not the cause or repair of the
historical Varga third-duel timeout**, and grants no campaign progress credit.

Only two new scripts and this report were authored. No production, configuration,
existing continuous driver, owner save or campaign progression was changed.

## Implementation and boundary

- `tests/helpers/stormwood_combat_telemetry.gd`: read-only collector retaining
  deep-copied impact history and entry/terminal observations. Captures host record,
  roster index, participants, manager action/cooldown/input guard, authority action
  deadlines, independent replica/authority/ally poses and HP, and caller-labelled
  input counts. It sends no input or snapshot requests and changes no fight state.
- `tests/smoke_stormwood_combat_telemetry.gd`: native SceneTree fixture invoking
  actual `stormwood_hosted_trainer.strike`, encounter authority validation,
  `host_move_profile`, hit geometry and production damage. Loads normalized Varga
  data through `stormwood_encounter_catalogue.trainer_specs()` and constructs her
  authored third member using `trainer_npc.creature_for`: Stormraven level 39,
  311.6 HP. Synthetic ally is Terrapup level 44.

GeometryBody instances are explicitly synthetic Node3D stand-ins using production
species height/radius definitions. Production host/engine instances are wired at
the strike seam outside SceneTree processing; no live AI, terrain, collisions,
models, network replication, admission, controller dispatch or roster completion
is exercised. The replica is deliberately one metre apart from authority to prove
independent recording, not to reproduce an observed replication fault. The host
record fixture omits level metadata, so its default level field is 1; the actual
damage target and recorded body instance are authored level 39. Do not use the
record metadata as an authored-level assertion.

The existing continuous driver's 180-second limit, 0.8 reach fraction, controller
input path, 900 ms wall cadence and 8x simulation/480 Hz settings are untouched.
This isolated fixture submits two direct intents, explicitly counted separately
from zero controller presses/releases. Its monotonic wait preserves at least
900 ms between intents. It does not demonstrate continuous-driver behavior under
accelerated simulation. No final-fight health or pose from the historical run can
be reconstructed from this fixture.

## Attempts and concrete receipts

Artifacts: `.artifacts/varga-telemetry-proof-20260909/` (ignored payloads).

1. `parse.log` passed. First runtime `engine.log` failed before any strike: the
   fixture passed raw `party` data to `team_of`, which expects normalized `team`.
   An array-index script error left the process alive; its specifically identified
   owned process was stopped. This attempt is not a pass.
2. Fixture changed to production normalized catalogue and gained a 15-second
   watchdog. `parse2.log` passed. `engine2.log` exercised miss/hit and reported
   10 checks, but contained two `snapshot` dictionary-id script errors because
   fixture `spec/team` were missing. Exit 0 is not clean evidence. Also a nominal
   0.9-second SceneTree timer yielded only 749 ms between actual host intents;
   its textual cadence check was insufficient. `telemetry2.json` retains that
   discrepancy. This attempt is not a pass.
3. Root explicitly authorized one corrected verification after the second attempt
   materially yielded impact evidence. Wired authored `spec/team`, replaced the
   timer with a monotonic wall deadline, and added an actual timestamp assertion.
   `parse3.log` passed; `engine3.log` passed 11 checks, zero failures/errors/warnings,
   exit 0. Script elapsed 919 ms; tool wall time 2.747 seconds; 15-second watchdog
   did not fire. Action 1 at host 1550 ms missed; action 2 at 2456 ms hit: **906 ms**
   interval. Production damage was 8.91611471486092; HP became
   302.683885285139/311.6. Terminal phase remained active. Both independent impact
   records survived subsequent terminal capture without duplication. No owned
   telemetry Godot process remained afterward.

All runs set APPDATA and LOCALAPPDATA to the artifact root's new `profile`
directory. No owner saves were read or copied. Exact final invocation:

```powershell
$proofRoot='C:/Projects/Tetherbound/.artifacts/varga-telemetry-proof-20260909'
$env:APPDATA="$proofRoot/profile"
$env:LOCALAPPDATA="$proofRoot/profile"
$env:TETHERBOUND_TELEMETRY_OUTPUT="$proofRoot/telemetry3.json"
& 'C:/Users/mattj/.cache/tetherbound-tools/godot-4.7/Godot_v4.7-stable_win64_console.exe' --headless --path C:/Projects/Tetherbound --script res://tests/smoke_stormwood_combat_telemetry.gd --log-file "$proofRoot/engine3.log"
```

Parse check uses the same executable, isolation and script with `--check-only`
and `--log-file "$proofRoot/parse3.log"`. No rendering-driver argument.

Final executed script SHA-256 identities:

| File | SHA-256 |
|---|---|
| collector | `5A60C6AD73C0C17766CC524BF5B9A658A0770B695112566B481C9172A9BB2DBA` |
| smoke | `5508C3254BCDBE73B6942C3888846F839C370ABB49F7073EA7AB0A52080C73F8` |
| telemetry3.json | `FA70FB209AE8AC9D5E164DD16E8E8A9BFEA73DB1351BE90E3A2B9DD9D2B14DCB` |

Shared branch moved under root's integration work; last inspected HEAD was
`3f704f88195d332983e6b4d88cec4ca9a900c321`. These new files were uncommitted
through verification. Root owns review, integration and any further authorization.

## Next diagnostic use

Attach this collector to the continuous driver's entry, each observed new host
action and failure boundary before input release/teardown, with actual input
counters; add movement request/velocity and aim-state observations as needed.
No chapter replay was authorized or performed by this proof. Preserved host
impact verdicts distinguish absent submissions, refusals, accepted misses and
damaging hits; compare authoritative and replica poses at impact rather than
inferring impact geometry from a later frame. A hit followed by authoritative
completion but local ACTIVE would instead implicate state propagation.

Existing adjacent tests remain `tests/test_stormwood_hosted_combat.gd` for
retarget/award semantics and `tests/smoke_net_stormwood_hosted_trainers.gd` for
hosted network behavior. Neither was rerun or changed for this isolated helper.
Terrain obstruction, prior-party attrition, input dispatch and mixed-clock combat
pacing remain unresolved causes of the retained Varga timeout.

## Subsequent bounded focused diagnosis

Root authorized one actual-world synthetic Varga probe. Before it, the collector
gained missing-fight/body handling and aim/velocity observations, and the minimal
fixture corrected authority level metadata to39. Revised proof passed13 checks;
the earlier hashes/11-check receipt above remain historical exact-run identities.
See `VARGA-FOCUSED-DIAGNOSIS.md` for the new identities and reproduced timeout:
200 accepted misses after the human moved to a recovery-camp coordinate and the
next-round ally staged approximately968m from Varga. The actual-world observer
also exposed freed-replica caller errors and missing ally-instance HP; those limits
are reported there and no clean-pass or historical-campaign repair is claimed.

The later finalized-death repair brief also authorized correction of those
observer gaps: active creature HP/species are now read from the manager and
freed raw body references are validated before typing. The final minimal proof
passed15 checks, including those two regression cases, in926ms with zero engine
errors. Its evidence is `.artifacts/varga-finalized-death-20260909/collector-final.log`.
No actual-world rerun with corrected observer code is claimed.
