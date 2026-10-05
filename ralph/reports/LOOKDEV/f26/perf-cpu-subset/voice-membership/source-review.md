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

## Proposal readiness: skip a provably redundant validity sweep

**PASS for the revised proposal's source logic; implementation and FPS benefit remain unproved.** The requested base is HEAD `dbe3bbb73c`, with settlement batching disabled. This review read current WorldAudio and searched `_voiced` / `_connect_new_creatures` consumers in scripts, tests and tools. Only WorldAudio owns/uses `_voiced`; the only discovered call is the same every-frame `_tick_creature_voices` call. No save, public result or remote caller exposes its membership count. No game source, Git state, engine job or test was changed; only this evidence addendum was written.

The reviewed proposal replaces the earlier added-only cleanup idea: retain the one returned group Array in `creatures`, run the existing discovery/insertion/signal-connection loop over that Array unchanged, and **after that loop** return when `_voiced.size() == creatures.size()`. Otherwise run the existing key-snapshot validity sweep unchanged. An early return before discovery, clearing live outside-group IDs, or cleanup only on new registration is not part of this PASS.

Let G be the set of current group instance IDs and V the Dictionary key set after discovery. The unchanged loop ensures G is a subset of V. Each group node appears once: Godot 4.7 `Node::add_to_group` returns when that node already belongs, and SceneTree returns its ordered group-node collection ([node.cpp:2303–2315](https://raw.githubusercontent.com/godotengine/godot/4.7-stable/scene/main/node.cpp), [scene_tree.cpp:1498–1511](https://raw.githubusercontent.com/godotengine/godot/4.7-stable/scene/main/scene_tree.cpp)). Distinct live objects have distinct occupied slots. Equal cardinalities therefore imply V = G, so every stored ID belongs to the current live group and the validity sweep would erase nothing. Discovery contains no await or callback emission; its existing direct connection does not introduce a new scheduling point. The size check must use this exact snapshot, not a second independently collected group count.

| Case | Revised proposal |
|---|---|
| All tracked bodies are current live group members | Scan/connect in the existing order; skip only the redundant `keys()` allocation and validity calls. |
| New live member appears | Insert/register in that same frame, before deciding whether cleanup is redundant. |
| A tracked body is freed | Its extra cached ID makes V larger than G; run the original sweep and remove it in that frame. |
| All tracked bodies are freed, no new body appears | G has size zero, V is nonempty; cleanup still runs immediately. |
| Both collections are empty | Return after the empty discovery loop; original cleanup was an empty loop. |
| Live tracked body leaves the group | V is larger; original sweep retains that valid ID. Reentry still cannot duplicate its connection. |
| Missing signal or external manual disconnect | Original record-before-signal-check / no-retry behavior remains unchanged. |

Primary engine source confirms generation-based identity: ObjectDB increments a validator, combines it with the slot, invalidates the freed slot, and validates the generation on lookup ([object.cpp:2283–2350](https://raw.githubusercontent.com/godotengine/godot/4.7-stable/core/object/object.cpp), [object.h:813–863](https://raw.githubusercontent.com/godotengine/godot/4.7-stable/core/object/object.h)). Ordinary slot reuse therefore does not let a stale ID suppress discovery of a new body. This is not an absolute never-reuse guarantee: the validator has 39 bits and wraps after `2^39 - 1` nonzero generations. The revised proposal preserves the existing cleanup schedule whenever an extra cached ID exists; it does not introduce the earlier proposal's indefinitely delayed cleanup or widen the existing dictionary-membership identity contract.

The proposal leaves alert cooldown fields, random calls, idle timer, mix/config, remote routing, authority and save behavior untouched. Worst-case expected complexity remains O(g + m); when V = G the discovery remains O(g), while the key-snapshot allocation and m validity checks are omitted. Retained live outside-group IDs still cause the original sweep every frame. This establishes which source work is avoidable, not its measured cost or an FPS recovery. Parent owns the source implementation and subsequent native proof. Independent CPU readiness review complete and idle.

## Implemented cardinality guard

**PASS for bounded implementation readiness.** Read the actual stable `world_audio.gd:164–207`: one `creatures` snapshot at line 191 feeds the unchanged full discovery/registration loop, and the size guard at lines 201–202 follows every insertion/connection. The original key-snapshot validity sweep at lines 205–207 remains the unequal-count branch. No added-only cleanup, timer or discovery shortcut was substituted. All-freed/no-new-spawn and live group-leave/reentry cases therefore follow the reviewed proof above. The membership comment now accurately says existing scan ordering is preserved instead of guaranteeing a first alert that could precede discovery. `performance.json:41` still has `static_batch_settlements: false`.

Parent reported the implementation as the sole working source change, seven additions/two deletions; this follow-up read the implementation directly and did not run Git or independently audit unrelated files. Existing audio callback/mix evidence applies to unchanged paths; discovery/freed-branch conclusions here are source reasoning only. No new smoke test, fixture, parser, renderer, export or timing was run by this reviewer. Export/parser/runtime and matched FPS proof remain separate parent-owned gates. Only this addendum was written; CPU review finished and idle before native FPS.
