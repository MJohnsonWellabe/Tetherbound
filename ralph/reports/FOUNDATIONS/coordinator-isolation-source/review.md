# Coordinator isolation after real autoload readiness

The harness retains its initial private-home isolation, waits for the existing
Game node's actual `ready` signal only when that node is not yet ready, then
calls the same isolation method again before reserving control ports or
spawning peers. Each existing post-spawn isolation call remains intact.
This repairs the demonstrated initialization-order fault without changing
Game initialization, world-save ownership policy, save guards or save code.

This is a source candidate allocated by ROOT, with native validation pending.
No engine, parser, import, render, export or CI job ran in Foundation. No push,
ROOT mutation, new branch, chat or agent accompanied this repair. The read-only
`git apply --check` against ROOT succeeded; it establishes patch applicability,
not engine behavior. `source-cut.json` pins the exact ROOT commit, both full
preimage Git blobs and SHA-256 hashes, candidate file hashes, minimal patch and
unchanged production source. The full preimage bytes and patch are also in
Foundation's ignored scratch at the paths in that receipt.

## Lifecycle and preservation

Godot's `SceneTree::initialize()` calls `MainLoop::initialize()` before
`root->_set_tree(this)`. The former invokes the script's `_initialize`, which
enters the smoke and harness launch synchronously. Game's subsequent `_ready`
calls `reset_for_new_game`, reclaiming world-save ownership. The prior harness
finished both child spawns and all ownership relinquishments before its first
frame await, so Game then reclaimed the blank coordinator's world.
The six added harness lines move no existing statement and preserve all
original source. The already-ready path reasserts isolation without waiting;
the ordinary early-entry path resumes after the actual ready signal. There
is no polling loop, new timeout or extra frame allowance.

Relevant engine source at the exact 4.7 commit:
[SceneTree initialization](https://github.com/godotengine/godot/blob/5b4e0cb0f/scene/main/scene_tree.cpp#L547),
[MainLoop initialization](https://github.com/godotengine/godot/blob/5b4e0cb0f/core/os/main_loop.cpp#L52).
The diagnosis and original raw CI evidence remain in
`../net-relic-ci6169-diagnosis/`; this repair does not replace that failed receipt.

The SceneTree/Game save guards, actual peer homes and world launch, ENet and
control reservations, input events, protocols, seed, steps, wall deadlines,
hello clock, heartbeat tolerances, watchdog and frame budgets are unchanged.
Production `Game._ready`, `reset_for_new_game`, ownership gates and fallback
worker are untouched. Raw native errors are not filtered or suppressed.
The foundations split-save/title-rejoin smoke and Warden fixture are untouched.
The encounter director is exclusively F22's allocation and is untouched here.

## Existing native witness

`tests/smoke_net_two_peers_boot.gd` still enters `launch` directly from its
SceneTree `_initialize`. It now observes the actual project autoload before
readiness, then requires the same node to be ready and to report world-save
ownership relinquished after both peers say hello. It also checks the actual
coordinator XDG home and, on Windows, APPDATA after spawning both children.
There is no replacement Game instance, spy, mocked ready event, source-literal
assertion, manually claimed ownership or caller-side frame delay. These five
new check sites are additions to the existing instrument smoke; all original
checks and fixtures remain byte-for-byte present.

The expected native regression discriminator is the ownership assertion:
with the original harness, the real autoload finishes ready after child
launch and reports ownership true; with the repaired harness, the post-ready
relinquishment and existing post-spawn restoration leave it false. This
expectation is source-derived and has not been run here. The early-entry check
also prevents a future caller-side wait from silently losing this coverage.
The witness does not claim a 180-second autosave stress run or a native
negative-control result.

ROOT may run the original named `two_peers_boot` smoke after F29 review using
its existing runner and budgets, and retain the original save/rejoin checks in
the consolidated validation. Parser acceptance, the native lifecycle witness
and peer/save outcomes remain open until actual ROOT evidence exists.

The Warden's separate 95-second missing-verdict failure remains unresolved.
The preserved logs and profiles contain no new live combat state capable of
proving its cause; the coordinator save fault and later disconnected-peer RPC
errors do not establish that cause. Its 5,400-frame command, five-second slack
and combat driver are unchanged; no victory or timeout waiver is claimed.
