# World audio voice membership — independent source review

PASS for bounded source correctness. No new regression identified. Runtime audio behavior and FPS benefit remain OPEN.

Reviewed exact commit `27ec0b9be80ef718e9f96a7eeafb9a0fa0d6b1f4` against its parent `03f30fbe20ea979c5ff2128d59e27db1d5392326` in `D:/tetherbound/codex-perf-cpu`. Read-only Git confirmed that only `scripts/audio/world_audio.gd` changes (12 additions, 6 deletions). Inspected the full file, creature voice group/signal producer, remote-audio caller, and existing instance-ID validity use. This review wrote only this evidence file; no renderer/engine, runtime tests, timing, game-source edits or Git mutations ran.

The diff replaces `_voiced: Array` with an instance-local Dictionary keyed by `Node.get_instance_id()` (lines 164–167), and changes only membership bookkeeping in `_connect_new_creatures()` (190–202). A live Node's instance ID identifies that same object independent of its name, tree path or group membership; dictionary lookups therefore preserve the old Node-identity membership behavior. There is no static cache shared between WorldAudio instances or save/session serialization.

`_process()` still invokes `_tick_creature_voices()` every frame (142–146). That method still obtains the same creatures configuration and scans for subscriptions before decrementing/checking the idle timer (170–175). No half-second poll, discovery timer, config change or added subscription latency was introduced. This preserves the existing frame ordering; it does not prove delivery of an alert emitted before the first discovery scan.

| Lifecycle case | Source result |
|---|---|
| Newly discovered live group member | Insert its ID once, then perform the same `has_signal` check and bound signal connection. |
| Already tracked live member | Skip connecting, as the previous Array membership did. |
| Live member leaves and later reenters the group/tree | Its ID remains while valid, so reentry does not duplicate the existing connection. |
| Member is freed | The validity sweep removes its ID. Ordinary Node signal lifetime handling is unchanged. |
| Member lacks `wants_to_engage` | Still recorded before the signal check, exactly as before; a later-added signal is not retried. |
| External code disconnects a live tracked member | No reconnection is added; that is also the previous behavior, rather than a new guarantee. |

The cleanup iterates `_voiced.keys()` (an Array snapshot) and erases from the Dictionary, avoiding mutation of the collection being directly iterated. `is_instance_id_valid(id)` is already used with typed integer IDs and validity cleanup by `scripts/world/cloudreach_finale_controller.gd:247–251` in this codebase. Freed IDs no longer remain in the membership collection after that frame's sweep; live objects outside the group remain deliberately retained.

Relevant producers/callers are unchanged: `creature_body.gd` declares the `creature_voice` audio group, `wild_creature.gd:28` declares and line 407 emits `wants_to_engage`, and `remote_presentation.gd:239–247` independently routes remote sound to `world_audio` listeners. Within WorldAudio, `_on_creature_alert()` cooldown bookkeeping, `_say()` pitch/random calls and positional bus routing, idle candidate selection/timer, ambience mix/fades, footsteps, combat listeners, music and remote event dispatch are outside the changed hunks. No authority, RPC, combat outcome, durable state or save operation is added.

For `g` current group members and `m` tracked live members, the previous repeated Array membership scans plus filtering were worst-case `O(g*m + m)` per discovery pass. Dictionary membership and the key-snapshot validity sweep are expected `O(g + m)`; when both scale with the roster, this removes the quadratic membership component. The group enumeration and `keys()` allocation/sweep still occur every frame, and retained live nodes outside the group still contribute to `m`. This is a source algorithm claim, not measured elapsed cost or an FPS improvement.

No Godot parser/runtime, spawn/despawn/reentry/audio-cue or matched native performance proof was run by this review. Those acceptance limits remain OPEN.
