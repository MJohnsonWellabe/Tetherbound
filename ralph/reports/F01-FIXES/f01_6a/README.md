# F01#6a: the guest's Grandpa catch-supply dialogue in a two-peer opening

**Root cause.** In `autoload/game_state.gd`, `commit_original_starter()` returned false on every non-host (`not is_host()`). `multiplayer.json` sets `redesign_ending_runtime_enabled: true`, so every opening adoption is a typed adoption that goes through that commit. On the guest, `sequence_director.gd::_adopt()` therefore stored `_pending_starter_adoption` and retried it every 3 s forever.

That pending commit had three effects:
- it kept `owns_input()` true and the opening modal;
- with the opening modal, `_refresh_lockout()` disabled the interaction arbiter;
- the beat never reached `return_starter`.

Grandpa's interact did nothing. Neither reproof hypothesis was the cause: the beat is already per character (`opening:beat:` is a player-scoped flag), and no host delta was involved.

Diagnosis on main ce961e1a, with the new probe fields: the guest's state at the failed press was `beat=choose`, `starter_commit_pending=true`, `owns_input=true` and `offered_prompt=""`.

**Fix.** The starter is a character fact. `original_starter_writer_ready()` admits the host, or an admitted client whose host snapshot has applied (`session.client_character_save_ready()`, the same gate a client's own character save uses). The commit then writes only that character's file (`save_character_prepared`, character-only). A pending joiner is still refused.

**Proof.**
- `TB_NET_RUN_ID=f01op2 TB_NET_OUT_DIR=<dir> TB_NET_PEERS=2 godot --headless --path . --script tests/smoke_net_meadows_identity_fresh_join.gd -- --opening-together`: 144 checks, ALL CHECKS PASSED (`opening-together-run1.txt`). The run covered both fresh openings through the guest's catch-supply reply and the orb grant, each peer's production save and reload, the rejoin, and the road-layout agreement after the rejoin.
- Unit tests:
  - `tests/test_original_starter_guest_commit.gd` (new): an admitted guest may write, a pending joiner may not, the host still may, and the guest's write is character-only with no world slot.
  - The related opening, story, starter and quest units also pass: 139 tests, 0 failed.

Local 4 vCPU, headless, Godot 4.7-stable.
