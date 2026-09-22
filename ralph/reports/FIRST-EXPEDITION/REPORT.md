# First expedition implementation evidence

Branch: `ralph/first-expedition`, PR134, stacked on design PR132. Baseline is main `a49783a3d` plus the reconciled design at `7aaa14cb4`. The owner authorized implementation as a persistent goal with lower-tier agents; the earlier design-only boundary is superseded. No release, purchase, engine change or new asset generation occurred.

## Implemented scope

- `ab9df5fb7`: tap-start co-op revive in `scripts/player/downed_state.gd`. Three seconds of proximity progress continues after release. A fresh second tap owns cancellation over competing world prompts; horizontal displacement beyond0.3m cancels. Body, health, modal, session and realm checks end invalid attempts. Existing45s downed window,2.5m radius and35% recovery remain. Old hold-named config/status fields are compatibility aliases.
- Herd activity: Rae's greeting now reveals and directs, while a physical visit with a deployed companion completes the existing personal objective and pays the existing three Basic Orbs. `meadowhart_herd_visit.gd` resolves the location from merged spawn order1005; it adds neither a herd nor copied coordinates. Completion before meeting Rae is allowed. Full inventory at interaction retains the outstanding reward. Already-completed personal flags disable the activity without repayment.
- Source audit corrected WORLD's assertion of an existing cart repair reward: `cart_repair.gd::_on_tried` grants none. No new payout was invented.

## Validation

Engine: `Godot_v4.7-stable_win64_console.exe`, version `4.7.stable.official.5b4e0cb0f`. Run commands below from the repository root with that executable in place of `godot`.

| Check | Result and boundary |
|---|---|
| Baseline `godot --headless --path . --script tests/smoke_playground.gd` | Exit0, `smoke: OK` at7aaa14cb4. Existing `Parameter "material" is null` and dummy-renderer/resource shutdown leak errors remain; this is not a clean-runtime claim. |
| `godot --headless --path . --script tests/run_tests.gd -- --only=test_downed_revive.gd,test_meadowhart_herd_visit.gd` |5tests,24assertions,0failed, no engine errors. Initial revive unit fixtures failed because the synchronous runner lacked an active SceneTree/input frame; the corrected tests exercise channel state and prompt arbitration. Real input is covered by the network smoke below. |
| `godot --headless --path . --script tests/smoke_net_revive.gd` |45PASS,0FAIL,exit0; both peer logs contain no `ERROR:` or `SCRIPT ERROR`. Two separate game processes and isolated character directories. Released-button progress reached1.11s, second tap cancelled,0.4m movement cancelled, final revival happened once at35HP, no satchel appeared, and the revived player walked8.54m. This verifies the input/recovery path, not remote-host admission or Steam connectivity. |
| Content unit selectors: herd visit, flag scopes, dialogue runner, quest log |124tests,2400assertions; one failed because the new acknowledgement omitted a portrait. Added the installed Meadowhart portrait, then reran the affected dialogue checks below. Other123tests passed. |
| `godot --headless --path . --script tests/run_tests.gd -- --only=test_dialogue_runner.gd,test_dialogue_portraits.gd` |79tests,3967assertions,0failed after the portrait correction. No new portrait asset or relaxed test. |
| Current `tests/smoke_local_requests.gd` |Exit0, `local requests smoke test passed`. Herd section uses the live arbiter/parsed interact event after fixture placement: alone/out-of-radius refusal, pre-Rae discovery with full inventory, greeting-only noncompletion, once-only three-Orb completion, restoration without repayment and acknowledgement close. Other four existing local-request paths also pass. No `SCRIPT ERROR`; the distinct engine-error set is a subset of the baseline shutdown leaks, with no new error type. |
| Current `godot --headless --path . --script tests/smoke_playground.gd` |Exit0, `smoke: OK` after both implementation changes. No `SCRIPT ERROR`; the normalized distinct engine-error set matches the baseline (null material plus dummy-renderer/resource exit leaks). The existing errors remain open. |

The network run uses `TB_NET_RUN_ID=first-expedition-revive` and `TB_NET_OUT_DIR` pointing to an OS-temp directory; the existing harness supplies independent peer profiles. The local-request smoke uses an isolated OS-temp `APPDATA` profile. Raw logs remain local rather than being committed as a payload dump.

## Still open

- Actual owner fun, ordinary approach/discoverability, screenshots/readability and whether the herd moment qualifies toward the six-activity floor are not proven by scripted placement. This is a better integrated activity foundation, not a completed Meadows chapter.
- A dedicated herd landmark/bond payoff is not added. The existing South Bridge landmark at[0,1330] has35m discovery radius, while the herd center lies roughly45.5m away. Do not claim this visit guarantees that bond credit or add duplicate credit accidentally.
- The herd smoke restores the current completed progression state; it is not a disk-save/reconnect campaign. Existing character flags are reused without a new save schema.
- The inherited generic `reward_grant` validates neither the client's herd position nor companion presence. Its additional world receipt is keyed by transient peer ID; the personal completion flag guards ordinary repeat visits. Neither proves adversarial or crash-safe authority acceptance.
- `ledger_rpc.gd::_apply_player_ops` ignores inventory-add overflow. A client can fill inventory after its local capacity check but before the host grant arrives. This inherited race needs a focused transaction fix; it is not cured by the content node. A separate submitted-visit latch prevents an unrelated reward refusal from swallowing this visit's later acknowledgement.
- `_rpc_revive` still trusts direct-peer completion. Host validation and downed-player progress presentation remain unbuilt parts of the complete UX target.
- Invite co-op still needs a verified transport integration, admission checks, matching engine/export support and actual platform access. No Steam package or AppID is present in this checkout. Preserve the existing ENet path and stable character identities while implementing it.

No commercial launch decision, outside-network acceptance, four-player campaign, Ally performance or final visual bar is claimed here.
