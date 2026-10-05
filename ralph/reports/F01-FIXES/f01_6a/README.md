# F01#6a: the guest's Grandpa catch-supply dialogue in a two-peer opening

## Root cause

`autoload/game_state.gd::commit_original_starter()` returned false on every non-host. Every opening adoption is a typed adoption (`multiplayer.json` `redesign_ending_runtime_enabled: true`). So on the guest, `sequence_director.gd::_adopt()` kept `_pending_starter_adoption` and retried it every 3 s, indefinitely. That had three effects:

- the opening stayed modal (`owns_input()` true);
- `_refresh_lockout()` therefore disabled the interaction arbiter;
- the beat never reached `return_starter`, so pressing interact at Grandpa did nothing.

Neither reproof hypothesis was the cause. The beat is already per character (`opening:beat:` is player-scoped), and no host delta was involved.

Diagnosis on main ce961e1a: at the failed press, the guest had `beat=choose`, `starter_commit_pending=true`, `owns_input=true` and `offered_prompt=""`.

## Why the first fix was replaced

11880d39 let an admitted guest write its own starter, local-first. That opened the dialogue, but it left the host's admitted copy of the character with an empty party and no receipt. The guest's next host-staged action then met `owner_action_baseline_conflict` or `roster_mismatch`. The coordinator required the host to decide what a character is given. The design below replaces 11880d39's semantics.

## Fix, part 1: host-first original starter

- **Guest request** (`autoload/game_state.gd`). `commit_original_starter` on a client never writes locally. It holds `_original_starter_pending` and calls `session.request_original_starter(card)`. The host keeps its local commit.
- **Host staging** (`scripts/net/starter_choice_action.gd`, new). The host stages a `starter_choice` action through `scripts/net/foundation_actions.gd`. It validates the card against its own config and registry, never trusting the request:
  - the admitted party is empty;
  - the record has no earlier `starter_choice:<character>:` receipt;
  - the card decodes and round-trips exactly;
  - the species is one of the opening's starters;
  - the creature is at the configured starter level, unwounded, not fainted.

  The after-state holds the energy-free portable card, the derived loadout mirror and the receipt.
- **Owner install** (`scripts/net/character_action_owner.gd`). The installer appends the guest's own pending live instance, the object its follower pilots, never a decoded copy. It goes through the guarded `party.install_owner_capture_roster(...)` and then sets `opening:starter_granted`. A failed install rolls back through `install_owner_capture_roster([], true)`.
- **Roster guard** (`scripts/net/session.gd` `_capture_roster_allowed`). This is one of the two session.gd guard changes. It now accepts `starter_choice` as well as `wild_capture`, and requires an empty before-party for a starter. It composes with F27's capture-guard fix: the energy-free `owner_matches_after` hunk is identical to F27's. A rollback call is refused outside a rollback. The second guard change is in `_retain_owner_training_retry`, which records `capture_originals` for both actions.
- **Bounded wait and refusal recovery** (`scripts/story/sequence_director.gd`).
  - While the host answers, the opening shows a notice every `starters.admission_notice_seconds` (`data/config/opening.json`, 10 s).
  - A terminal host refusal (`homestead_action_completed`) runs `cancel_starter_adoption(code)`. It dismisses the follower, clears the pending choice and offers the picker again.
  - A world delta that lands mid-adoption no longer reopens the picker.
- **Exact records** (`scripts/creatures/essence.gd`, `scripts/net/character_record_rules.gd`). `merge_owner_passive` takes the new value when the card is unchanged, and one shared `portable_card` rule strips in-fight energy. Records are compared exactly, with no float tolerance. The smoke compares fingerprints that each peer computes from its own exact record, so the harness's JSON rounding cannot fake a match or a mismatch.

## Fix, part 2: dialogue gifts are host-delivered

A guest's `give:` effects used to land only in its local satchel. A guest now claims each gift as an authored `reward_grant`, keyed `dialogue_give:<conversation>:<item>`. The host reads the item and count from its own dialogue data. The delivery id keys the receipt by world, source and character, so each gift pays once. The guest's satchel changes only from the accepted delivery. The host and solo players keep the direct give.

The classification lives in `scripts/net/world_ledger.gd` (`DIALOGUE_GIVE_GATES` / `DIALOGUE_GIVE_REFUSED`):

| Conversation | Class | Host-side gate | Gives |
|---|---|---|---|
| grandpa_first_catch | consumable | authored item and count; once per character | orb_basic, potion_small, berries, revive |
| village_mira_shop_intro | progression | the per-character receipt (the conversation sets its own `unless` flag) | axe, pickaxe, coin, fiber |
| village_tam_tools | progression | the per-character receipt (sets `tam_tools_given`) | knife, torch, hammer |
| relay_captive_freed | progression | `requires_any: relay_captain_defeated` (a host world flag) | mill_bridge_gear |
| village_quarry_foreman_hammer | refused for guests | no NPC ladder offers it, so the host cannot verify a guest reached it | — |

A conversation that gives anything and appears in neither table is refused for guests. `tests/test_dialogue_give_delivery.gd` fails until it is classified.

## Out of scope, recorded

- **Untyped guest catch.** A guest's untyped wild catch (outside the starter path) belongs to F27 and is not changed here.
- **Rejoin admission conflict.** Lane A's rejoin conflict was pre-existing and reported separately. It did not reproduce in the host-first run: the whole-record check after the rejoin passes.
- **Test change.** `tests/test_den_groom_saved_transaction.gd` now expects an exact merge (coordinator-approved). It follows from the exact `merge_owner_passive` branch.

## Proof

Net smoke on d7950e5c, run with the env vars as `row6/VERDICT.md` records:

```
TB_NET_RUN_ID=f01op15 TB_NET_OUT_DIR=<dir> TB_NET_PEERS=2 godot --headless --path . \
  --script tests/smoke_net_meadows_identity_fresh_join.gd -- --opening-together
```

The run passed all 156 checks, exit 0 (`opening-together-hostfirst-run.txt`, `opening-together-hostfirst-SUMMARY.md`). It covers:

- both fresh openings;
- the guest's starter admitted by the host, then the catch-supply reply and the orb grant;
- after the opening and again after the rejoin:
  - the host's admitted receipt, party and flag;
  - the party and creature fingerprints;
  - the guest's whole record equal to the host's owner-passive replay of it;
- each peer's save and reload;
- the rejoin;
- road-layout agreement.

The gift rows show all four Grandpa gifts `settled` on the guest and `accepted` on the host.

Unit tests (`godot --headless --path . --script tests/run_tests.gd -- --only=...`):

- `tests/test_original_starter_guest_commit.gd`: request, admission, picker and in-flight cases.
- `tests/test_starter_choice_action.gd`: staging validation and the owner-side re-run.
- `tests/test_starter_install.gd`: the installer appends the live instance; the composed guard admits only the staged starter; rollback through the guard; a terminal refusal releases the choice.
- `tests/test_merge_owner_passive_exact.gd`
- `tests/test_dialogue_give_delivery.gd`
- `tests/test_den_groom_saved_transaction.gd` (the exact expectation above)

Local 4 vCPU, headless, Godot 4.7-stable.
