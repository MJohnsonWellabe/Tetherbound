# MP-2A-SESSION — report

**Lane:** 2.A Session (Opus) · **Branch:** `worktree-agent-a7f9f10a3968b2339`, commit `d964a95f`
on `claude/tetherbound-roadmap-next-jrcjs8` at `bd8bd062`; merged as `45e1c5ad` · **Brief:**
`ralph/briefs/MP-W2/2A-SESSION.md` · **Contracts:** D95, D97, D100, D105,
`docs/specs/MP_NET_HARNESS_CONTRACT.md` §4. Written by Fable from the lane's completion report
(the lane's tooling refused a `.md`).

**Base note.** The provisioned worktree was on `d72580b5`, which lacks the Wave 1 state split.
The lane reset to the branch tip as briefed and confirmed `world_state.gd`, `player_state.gd`
and `net_harness.gd` present before starting.

## One line per item, up front

| Item | Verdict |
|---|---|
| 1 `host/join/leave/kick/is_host/peer_count/peers` + four signals, ENet, two channels | **done** — `scripts/net/session.gd`; `CHANNEL_LEDGER 1`, `CHANNEL_SNAPSHOT 2` (D95) |
| 2 Registry, host-authoritative, replicated whole | **done** — `scripts/net/peer_registry.gd`, pure; peer id ↔ character id ↔ display name ↔ realm, plus Wave 4/5 `sleeping`/`downed` placeholders |
| 3 Handshake: hello → snapshot → registry; no intents before `snapshot_applied` | **done** — snapshot on its own channel, sent before the registry; gate is `Session.snapshot_ready()` |
| 4 Host exit saves the world; clients return to title; a client never writes `user://worlds/` | **done, with the gap in Finding 3** |
| 5 D100 autosave ownership at the four sites | **done** — all route through `Game.autosave_here()` |
| 6 `enter_realm()` refuses in a multi-peer session (D97 interim) | **done** — message and `false`, before any state is touched |
| 7 Host clock (D105) | **done** — replicated once a second; `Game.advance_day()` refuses on a client |
| 8 Solo is a one-peer session | **done** — one hook in `title_screen.gd::_enter_world()`, the funnel Start and Load already share |
| 9 `Game.local_player()` with `find_player()` alias | **already on the base** (`game_state.gd:521-529`), verified not rewritten |
| 10 `host`/`join`/`leave`/`expect_peers`/`wait_flag` step arms | **done** — plus a real `probe session` and two D100 probes |

## Commands

```
godot --headless --path . --import                                 ×2, exit 0
godot --headless --path . --check-only --script <each changed .gd>  7/7 clean
godot --headless --path . --script tests/smoke_playground.gd        exit 0, "smoke: OK"
tools/net/run_net_smoke.sh host_join_leave  → run 1 exit 2 (the red, Finding 1)
                                            → run 2 21/21 PASS, exit 0
```

Zero `^ERROR:` lines in either peer log. Nothing else was run: CI is the gate
(plan §7, cut back on the owner's instruction 2026-09-06).

## Findings

1. **Seen red once.** The first run died before any step: `Parse Error: Identifier
   "DEFAULT_STEP_BUDGET_FRAMES" not declared` — that const belongs to the coordinator, which
   runs in a different process. Replaced with the peer's own `NET_STEP_BUDGET_FRAMES := 3000`.
2. **`Session` is deliberately coroutine-free.** Both `game_state.gd` and `peer_runner.gd` reach
   it through `Object.call()` (no `class_name`), and a suspended call through `call()` works
   until it silently does not. Every entry point returns immediately; callers poll
   `snapshot_ready()`, `handshake_failed()`, `is_active()`. Signal-set flags use a Dictionary
   box, honouring the ENet spike's lambda-capture finding. A leaving **host** holds its socket
   open for `CLOSE_FLUSH_FRAMES` (6) so the reliable `session_ended` packet gets off the wire.
3. **Honest gap: a client writes nothing on leave, because there is nothing to write.** D100
   says each peer saves its own character; the character file does not exist until the
   save-split lane, and today's single v22 file carries world keys, so calling it from a client
   is what D100 forbids. The smoke asserts the client's autosave slot stays **absent**, and that
   `user://worlds/` stays empty is a **forward assertion** — no one writes that directory yet,
   and it is written now so that the day a host does, a client that also does fails here instead
   of shipping. Both are for the save-split lane to **re-point, not delete**.
4. **The D105 clock gate lives in `advance_day()`,** not `world_look.gd` (which this lane does
   not own, and which only covers the passive roll). One gate covers the passive roll, rest, and
   anything later; on a client it returns the replicated `day` unchanged.
5. **Two channels on the wire are ENet 3 and 4** (Godot reserves three system channels), hence
   `channel_count = 2`. ENet gives no cross-channel ordering, so a joiner may see the registry
   before the snapshot — harmless precisely because `snapshot_ready()` is the gate, not the
   registry.
6. **`is_host()` is `_mode != "client"`, not `multiplayer.is_server()`.** The latter needs a live
   peer to mean anything and would read false in every headless test, capture tool and editor
   run, turning all four D100 sites off.

## Handover

- **2.C:** `Game.local_player()` was already present. The session is `Game.session`
  (`/root/Game/Session`), never an autoload; `Game.is_host()` and `Game.is_multi_peer()` answer
  safely before it is mounted. `Session.peer_joined(peer_id, character_id)` / `peer_left(peer_id)`
  are the signals a rig spawner wants.
- **Save-split lane:** `Session._save_character_here()` and the smoke's `autosave_exists` /
  `worlds_dir_entries` probes are the three places to re-point (Finding 3).
- **6.A:** the `enter_realm` refusal is one `is_multi_peer()` guard at the top of
  `game_state.gd::enter_realm()`, with the D97 reference in its comment.
