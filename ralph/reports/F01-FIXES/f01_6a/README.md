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
  - the creature is at the configured starter level, unwounded, not fainted;
  - the card equals the starter the host rebuilds from its own species data and starter level, apart from uid and nickname. No base stat, IV, boost, xp, bond, shiny flag or shared history can ride in on a card that round-trips.

  The after-state holds the energy-free portable card, the derived loadout mirror and the receipt.
- **Stable retries.** Every retry re-sends the card from the first request. A late refusal cannot release a starter the host has already journalled: `cancel_original_starter_request` returns false once a `starter_choice` row exists.
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
| village_nessa_overlook_gift | consumable | authored item and count; once per character (the conversation sets `nessa_overlook_gift_taken`) | berries |
| village_mira_shop_intro | progression | the per-character receipt (the conversation sets its own `unless` flag) | axe, pickaxe, coin, fiber |
| village_tam_tools | progression | the per-character receipt (sets `tam_tools_given`) | knife, torch, hammer |
| relay_captive_freed | progression | `requires_any: relay_captain_defeated` (a host world flag) | mill_bridge_gear |
| village_quarry_foreman_hammer | refused for guests | no NPC ladder offers it, so the host cannot verify a guest reached it | — |

The scan covers `data/dialogue` recursively, including `bands/`, which the runner also plays. A conversation that gives anything and appears in neither table is refused for guests. `tests/test_dialogue_give_delivery.gd` fails until it is classified.

## Independent review

The first review returned CHANGES REQUESTED with two blocking findings, both fixed in 2d69daf5:

1. **Inflated starter cards passed the freshness check.** A card could round-trip and still carry inflated stats or history. Fixed by the exact canonical comparison above. Covered by `test_an_inflated_card_that_round_trips_is_refused`, which needs at least 8 tampered fields to reach the host's check.
2. **The gift scan was not recursive.** It missed `data/dialogue/bands/`, so a guest's claim for Nessa's band1 gift was refused while its flag was still set locally. Fixed by the recursive scan and the classification above; the classification test now asserts the band gift is scanned.

Two non-blocking findings were also fixed:

- Retries now re-send one stored card, and a late refusal no longer releases a journalled starter. Covered by `test_a_journalled_starter_is_never_released_by_a_late_refusal`.
- A stale comment and stale test names were updated.

A second, fresh review of 2d69daf5 returned **APPROVE**. Its non-blocking findings were handled as follows:

- **Fixed:** the host caps the starter nickname at the naming grid's `MAX_LENGTH` and refuses control characters (`invalid_starter_nickname`).
- **Fixed:** the retry comment no longer claims the install tolerates drift.
- **Fixed:** the inflation test now requires the freshness rule itself to refuse at least 6 of the fields.
- **Fixed (coordinator condition 3):** a starter row that stays pending no longer strands the opening. After `starters.admission_retry_after_seconds` (45 s, `data/config/opening.json`), the automatic retries stop and the guest is told plainly that Interact asks again. The retry (`game_state.gd retry_original_starter`) does one of three things:
  - re-sends the first card when nothing is journalled;
  - re-runs this owner's install of a pending row;
  - when the follower no longer equals the host's staged card, which the installer would refuse forever, adopts the host's card as the pending instance and rebuilds the follower from it.

  A definite host refusal still resets cleanly to the picker. The tests are:
  - `test_the_wait_is_bounded_and_then_offers_a_clear_retry`
  - `test_the_retry_rearms_the_wait_and_asks_again`
  - `test_a_readopted_card_replaces_the_follower`
  - the three `test_a_retry_*` cases
  - `test_a_terminal_host_refusal_releases_the_choice`

Residual risk carried from the first review (non-blocking):

- **Mira's and Tam's progression gifts** have no host-side prerequisite beyond the per-character receipt. A modified guest could claim the starting tools early. Each still pays only once per character. The coordinator accepted this as residual: the gifts are offered from the first visit.
- **Non-terminal host replies** (busy, awaiting) are now bounded by the same retry above.

The live race in the opening smoke was a harness bug, not a product bug. It reproduced only when two smokes shared the CPU (op14, op16). The dialogue dismiss loop sent raw press edges, and a slow process frame flushed the last press after the box had closed, which reopened Grandpa's walk-out hint. Local diagnostics caught the arbiter firing on that fresh press at physics frame 2648. The loop now uses the shared F11#3 tap.

## Out of scope, recorded

- **Untyped guest catch.** A guest's untyped wild catch (outside the starter path) belongs to F27 and is not changed here.
- **Rejoin admission conflict.** Lane A's rejoin conflict was pre-existing and reported separately. It did not reproduce in the host-first run: the whole-record check after the rejoin passes.
- **Test change.** `tests/test_den_groom_saved_transaction.gd` now expects an exact merge (coordinator-approved). It follows from the exact `merge_owner_passive` branch.

## Proof

Net smoke on 2d69daf5 (the review fixes), run alone with the env vars as `row6/VERDICT.md` records. The earlier pre-review run on d7950e5c, op15, also passed 156 of 156.

```
TB_NET_RUN_ID=f01op17 TB_NET_OUT_DIR=<dir> TB_NET_PEERS=2 godot --headless --path . \
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

## Part 3: gifts held behind Grandpa's Home Key (F18), on main after #547

**Cause.** F18 holds Grandpa's spoken effects until the Home Key's owe/deliver settles (`sequence_director.gd` `_f18_pending_effects`). The held batch applied after the dialogue box had closed, when `_speaking_conversation_id()` is empty, so an admitted guest's `give:` claims were dropped ("has no conversation to claim it under"). In the opening-together smoke the guest got 0 orbs.

**Fix.** Each drained batch is queued with the conversation that spoke it (`_f18_later_batches`). A held batch applies alone under its own name; batches spoken while it waits apply after it, one per drain, in order. A batch with no name is refused, never claimed under whichever conversation is open later. The owner-changed drop clears the queue with the held batch. Host and solo are unchanged apart from that ordering. F18 reviewed the shape (its hold can span two conversations, which is why batches no longer merge).

**Measured.** The guest's Basic Orbs arrive about 3.7 s (3664 ms, instrumented local run) after the box closes. Recorded as a UX follow-up in STATE §4.

**Tests.** `tests/test_guest_held_gift_claims.gd`, five cases: the held gift after the box closed; an open conversation; a conversation spoken while one is held (fails on the merged shape); the played shape, key on line 0 and gifts on later lines; an unnamed batch never claimed under another conversation (fails with the old fallback). With `test_opening_gift_waits_for_owner`, `test_opening_home_key` and `test_dialogue_give_delivery`: 33 tests, 209 assertions, 0 failed.

**Smoke fixtures (coordinator-approved, no assertion weakened).**
- Opening-together: the orb assert re-polls up to 20 × 60 frames for the late gift. Standing by Grandpa with the key held opens the `lesson_home_key` card, which owns input; each viewer reads it through with the production `ui_accept` (at most 8 pages) before the full-map step.
- Join/reload layout check: road layout agreement is now asserted after the fresh join and after each peer's save and reload, as well as after the rejoin and the cold reconnect.
- `smoke_net_harness_max_hp` (the shard-17 race on #547: the host's live wild struck the guest before the "before" read): a disclosed host-side hold of the wild's own swings, on the CombatManager and the director's shared host fight runtime, from just before the guest joins until the scripted hit has been read; plus a named check that no unscripted hit landed first.

**Independent review.** APPROVE-WITH-NITS (static; the reviewer's worktree hit a full disk). Fixed: the conversation fallback (finding 1), the played-shape test (5), the release check (6), a queue comment (2). Recorded, not changed: a guest's satchel room is preflighted per batch against gifts the host has not delivered yet (3); a mid-session load drops queued batches with the held one, as before (4).

**Proof on 5fd6937c** (local, 4 vCPU, headless, Godot 4.7-stable, each run alone):

| Run | Result |
|---|---|
| opening-together 1/3, 2/3, 3/3 | ALL CHECKS PASSED, 158 assertions each; road layout `00cf42f4bb81` (47 bands / 289 points) equal on both peers after the join, the reloads and the rejoin |
| meadows_identity_fresh_join (default mode) | ALL CHECKS PASSED |
| harness_max_hp ×2 (with the shared-runtime hold) | ALL CHECKS PASSED; guest at 134.40/134.40 immediately before the scripted hit |

The first harness run on 5fd6937c, with the hold on the CombatManager only, failed the new named check (an unscripted hit landed: 126.08/134.40). That showed the shared fight runs its own enemy AI; the hold now covers it.
