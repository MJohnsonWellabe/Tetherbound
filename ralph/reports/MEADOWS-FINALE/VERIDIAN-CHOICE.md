# Veridian choice and herd display (F05 WO1/WO2)

Lane: Meadows finale. Row: ROADMAP F05 / ACCEPTANCE §6.1 F05, governed by card
M4. This work uses **disclosed focused fixtures**. The F01–F04 earned route
does not exist yet, so the M4 continuous-path card stays open. Nothing here
accepts F05 or M4.

## Criteria advanced

- "Solo space/capacity accept and refuse paths complete Veridian without a
  sixth slot or accidental release."
- "Full refusal produces the saved herd display" (WORLD §3.2).
- The §6 legendary rule: a once-only offer per character, never offered twice
  to the same character.

## Defects on main this closes

1. **No refusal with room on the belt.** The Stag joined silently whenever
   there was space.
2. **A co-op participant whose world had already settled lost their offer.**
   `_place_legendary()` went straight to DONE whenever `legendary_settled` was
   set. The unanswered participant is now resumed. That resume is also why a
   refusal now needs its own personal receipt (`legendary_refused`): before
   F05 a refusal left none, and the resume would otherwise re-offer a refuser.
   (Correction: an earlier draft of this report listed "a refusal at five was
   re-offered on the next load" as a defect on main. In solo it was not
   reachable, because `legendary_settled` short-circuited the chamber to DONE.
   The independent review caught this.)
3. **Found by this lane's own first smoke run, before it shipped:** the choice
   prompts sat 1.1 m up with a 1.0 m radius, measured in 3D from the feet, so
   they could never be pressed. The run went red on all five answer scenarios
   (`veridian-offer-choice-first-run-red.txt`). The geometry was corrected and
   the unit test now pins reachability.

4. **Found by independent review:** the prompts were placed at
   `ground_height_at`, which is terrain height. The Legendary Chamber stands on
   a built slab metres above the terrain, so in real play the prompts were
   under the floor and the choice could never be answered. The first smoke
   answered around the default spawn, where terrain is the floor, so it could
   not see this. The prompts are now anchored at the player's own floor. The
   smoke pulls the real lever inside the chamber, and `smoke_gate_e_finale`
   walks a player to the accept prompt and is offered it at 1.0 m.

5. **Found by the two-peer witness (WO4):** the Warden participant journal
   was never read. `_read_warden_participant_characters()` called a
   `WorldState.world_snapshot()` that does not exist, so the list was always
   empty on main and every participant was judged by the empty-journal rule.
   It now reads `reward_deliveries`, and a unit test pins that
   `world_snapshot` is absent. Fixed in `13c92555`.
6. **Found by the same witness:** an open ceremony could record an answer for
   whichever character was loaded when it closed. The answer is now recorded
   only for the character the offer was made to (`13c92555`).
7. **Found by the in-engine captures:** the "both answers are final" line was
   pushed while the join dialogue still hid the HUD, and the refusal line was
   replaced by the ceremony a frame later, so a player saw neither. The line
   now waits `choice.announce_delay` (1.0 s) after the offer opens, and a
   refusal holds the ceremony for `choice.message_hold` (2.4 s). Fixed in
   `636cf28d`; frames 04 and 06b show both lines.

## Witnesses

| Witness | Result |
|---|---|
| `tests/test_veridian_offer_choice.gd` (the rule, pure: once-only receipts, scopes, full-refusal rule for solo, mixed, partial and stranger cases, prompt reachability) | PASS locally, 160 tests / 0 failed in the selected set. The set includes flag_scopes, stronghold, legendary, dialogue_runner and quest_log. Needs the `flag_scopes.json` grant for CI. |
| `tests/smoke_veridian_offer_choice.gd`. Setup: the production Meadows world, with the player placed on the machine control inside the Legendary Chamber, pulling the real lever with `interact`. Each answer is given by standing at a prompt on the chamber floor and pressing `interact` through the live arbiter. The ceremony is driven by `ui_*` presses. After each answer there is a real `save_game`, then `load_game` into a fresh world. The no-re-offer check reads through dialogue for 240 frames, watching the join and choice stages and the ceremony seam. It is then repeated with `legendary_settled` removed, so the personal receipt alone is tested. Party size is checked every frame. | PASS on `d804518b`, all six scenarios, 28m59s. Log: `veridian-offer-choice.txt` |
| `tests/smoke_gate_e_finale.gd` (granted edit: an accept step): a full five, walked in, walks to the accept prompt on the chamber floor and is offered it | PASS locally on `8edc5c4d`: "accept prompt offered at 1.0 m" |
| `tests/smoke_boss.gd` (granted edit: an accept step through the accept prompt's `interaction_activate()`) | PASS locally on `8edc5c4d` |

Scenarios in the smoke:

| Scenario | Answer | Party after | Herd display | After reload |
|---|---|---|---|---|
| space-accept (4) | accept prompt | 5, one Veridian | absent | no re-offer, same party |
| space-refuse (4) | refuse prompt | the same 4 | stands | no re-offer, still stands |
| capacity-refuse-at-prompt (5) | refuse prompt | the same 5 | stands | no re-offer, still stands |
| capacity-accept, then let the newcomer go (5) | accept prompt, then the ceremony's "let go" on the newcomer | the same 5, nobody released | stands | no re-offer, still stands |
| capacity-accept, release slot 0 (5) | accept prompt, then the ceremony releases slot 0 | 5, slot 0 replaced by the Veridian; the other four untouched | absent | no re-offer, same party |
| save while the choice is open | none | unchanged | absent | the same unanswered choice comes back; nothing was answered for the player |

In every frame of every scenario the party never exceeded five.

## Fixtures (disclosed)

- `defeated_warden` is set directly. No Warden fight is played here;
  `smoke_boss.gd` and `smoke_gate_e_finale.gd` own that.
- The party is built with `Game.make_creature`.
- The player is placed on the machine control, and later on each prompt's
  anchor, rather than walked there. The walked version of the accept press is
  the `smoke_gate_e_finale` row above.

## Design choices, disclosed

- **Refusal input.** The spec requires refusal but does not name its input.
  After the join conversation, a world message names both answers as final.
  Accept is a prompt 2 m to the player's side, at the Stag's shoulder;
  straight ahead is inside its 2.13 m capsule, which stops 2.6 m away. Refuse
  is a prompt 2 m behind. Neither prompt is live where the player stands.
  Walking away answers nothing, and the offer waits through reloads.
- **No new dialogue.** The choice text is config (`choice.announce`,
  `choice.refused_message`). The dialogue system has no branching, and the
  stronghold's dialogue file is outside this lane's paths.
- **Herd display site.** `[390, 5860]` on the Highfield, among the ordinary
  herd around `[377.5, 5855.3]`, seen from the Highfield's authored hero
  stand `[400, 5832]`. Two earlier sites (`[408, 5862]`, `[432, 5851]`) were
  rejected on in-engine frames because the stag read as off on its own.

## Receipts

- Personal: `legendary_joined` or `legendary_refused` (player scope).
- World: `legendary_resolution:<accepted|refused>:<character_id>`, committed
  through the ledger. An unacknowledged receipt is resubmitted every 5 s, and
  also on the next session after a lost acknowledgement. A hard refusal from
  the host stops the retries for that session.
- World: `legendary_resolution:live` is written by the first live F05 answer
  or settle. Its absence is how the game recognises a world that settled
  before F05; on such a world nobody is offered again.
- The herd display is derived from the world receipts, so it is never saved on
  its own.

## Review rounds

| Round | Reviewer | Verdict | Blocking finding, and its fix |
|---|---|---|---|
| 1 (`f0bb90e5`) | independent lane review | changes | The prompts sat at terrain height, under the chamber's built floor. They now anchor at the player's floor, and the smoke runs in the chamber. |
| 2 (`8edc5c4d`) | independent lane review | approve on the code | Non-blocking items A–E fixed in `211f5591`: pre-F05 guard on every path, world-only migration, clear prompt spots, eligible-only receipts. |
| 3 (`8edc5c4d`) | coordinator, code-blind | changes | Migration could stamp a joining guest; an empty journal let a non-fighter be offered. Fixed in `eeb4adeb`: `should_migrate` and `may_receive(..., is_client)`, with unit tests that fail on `8edc5c4d`. |
| 4 (`eeb4adeb`) | independent, code-blind | changes | A no-offer settle left no live marker, so a reconnecting participant was never offered. Fixed in `b5a9af1d`: `_settle()` carries the marker, and `_is_client()` covers join preparation. |
| 5 (`b5a9af1d`) | same, re-review | **approve** | Nits only. The client-side refusal retry is kept, but the only refusal it can hit is a malformed intent. |
| 6 (`d804518b`) | independent, fresh reviewer, delta `b5a9af1d..d804518b` | **approve** | None blocking in the delta. It found one open spec gap that predates F05 (below, under "Not claimed"), a stale comment and a self-contradicting config comment (fixed in the next commit). Residual risks are recorded under "Not claimed". |

## Not claimed

- **A Warden fight started by a CLIENT.** Open, and it breaks the
  participant rule in both directions. `encounter_director.gd` pays a
  client-run Warden by the solo path (`_pay_trainer_reward`). That path writes
  no reward-journal rows, and `begin_trainer_battle` has no host-only guard.
  With an empty journal, the host is offered the Veridian as though it were
  the only player, even if it never fought, and the client who fought is
  never offered. This behaved the same way before this change, when the
  journal was never read. The fix belongs in the combat/encounter owner's
  file: either pay a client-run Warden through the journaled `reward_grant`
  path, or refuse a client's Warden challenge. It is reported to the
  coordinator.
- **A character switch while the release ceremony is open**, without a
  scene change that resets the local player. The switched-in character's
  answer is dropped rather than recorded for it. In one narrow ordering (a
  release, then taking the Veridian, then the switch) the original character
  could be offered again later. Loads change scene and reset the local
  player, so no normal path reaches this. It has no test.
- **An answer given within `choice.announce_delay` (1.0 s) of the offer
  opening** is not followed by the "both answers are final" line. Neither
  prompt is in reach from where the player stands, so in practice the line
  always comes first.

- Two peers, mixed choices, disconnect and reconnect. That is WO4, on
  `ralph/f05-coop-veridian` (the `peer_runner` probe is granted). Its run 4
  on this code records `accepted:<guest>`, `refused:<host>` and the live
  marker, with no herd display and no re-offer. It stays **red** on one
  defect outside this lane: the reconnecting guest's `slot_0` is rewritten
  with a new blank character, so the guest's personal receipt does not come
  back. That was reported to the coordinator with a STATE-REPORT.
- End-to-end: a world settled by a no-offer lever pull, followed by a
  participant reconnecting. The code path is reviewed, but no test drives it.
  WO4's witness is the place for it.
- The host checking, in `world_ledger.gd`, that a receipt's character id is
  the submitter's own (coordinator nit 6). It is requested as a shared-file
  grant.
- The earned route to the chamber.
- The herd display's visual read. In-engine frames exist (see
  `VISUAL-EVIDENCE.md`), and the code-blind judge's verdict is
  recorded there. Neither is a pass on the art bar.
- A falsification run for the smoke's re-offer check. The first-run red above
  is a different defect. The re-offer rule is pinned in the unit test.

## Migration and compatibility (declared)

- **Pre-F05 solo saves** that settled are migrated once, at build, and only
  into a WORLD receipt: a Veridian on the belt, or `legendary_joined`, counts
  as accepted, and anything else as refused. Such a save that refused now gets
  the herd display. The migration never writes a personal flag. It never runs
  on a client, including during join preparation, or with other peers
  present. That way a guest who never fought can never be recorded as having
  answered.
- **Pre-F05 co-op worlds** (settled, with no live marker) are treated as fully
  answered, so nobody is offered twice. The cost is that a participant who
  never answered there keeps the pre-F05 outcome, which was no offer.
- The migration runs at world build. A mid-session `load_game` into an
  already-built world does not run it until the next build.
