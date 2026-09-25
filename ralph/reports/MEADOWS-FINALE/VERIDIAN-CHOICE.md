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

## Witnesses

| Witness | Result |
|---|---|
| `tests/test_veridian_offer_choice.gd` (the rule, pure: once-only receipts, scopes, full-refusal rule for solo, mixed, partial and stranger cases, prompt reachability) | PASS locally, 160 tests / 0 failed in the selected set. The set includes flag_scopes, stronghold, legendary, dialogue_runner and quest_log. Needs the `flag_scopes.json` grant for CI. |
| `tests/smoke_veridian_offer_choice.gd`. Setup: the production Meadows world, with the player placed on the machine control inside the Legendary Chamber, pulling the real lever with `interact`. Each answer is given by standing at a prompt on the chamber floor and pressing `interact` through the live arbiter. The ceremony is driven by `ui_*` presses. After each answer there is a real `save_game`, then `load_game` into a fresh world. The no-re-offer check reads through dialogue for 240 frames, watching the join and choice stages and the ceremony seam. It is then repeated with `legendary_settled` removed, so the personal receipt alone is tested. Party size is checked every frame. | See the PR evidence table for the run on the current commit. Log: `veridian-offer-choice.txt` |
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
- **Herd display site.** `[408, 5862]` on the Highfield, 25 m from the herd
  bull (band 4 spawn order 4101), toward -x/+z. **Not yet captured in engine: the
  frame check is open.**

## Receipts

- Personal: `legendary_joined` or `legendary_refused` (player scope).
- World: `legendary_resolution:<accepted|refused>:<character_id>`, committed
  through the ledger. A client that lost the host acknowledgement resubmits it
  on its next session.
- The herd display is derived from the world receipts, so it is never saved on
  its own.

## Not claimed

- Two peers, mixed choices, disconnect at the claim acknowledgement, and
  reconnect. That is WO4, which needs a `peer_runner` probe grant.
- The earned route to the chamber.
- The herd display's visual read.
- A falsification run for the smoke's re-offer check. The first-run red above
  is a different defect. The re-offer rule is pinned in the unit test.

## Migration and compatibility (declared)

- **Pre-F05 solo saves** that settled are migrated once, at build: a Veridian
  on the belt, or `legendary_joined`, is recorded as accepted; anything else as
  refused. Such a save that refused now gets the herd display.
- **Pre-F05 co-op worlds** (settled, but with no `legendary_resolution:`
  receipts) are treated as fully answered, so nobody is offered twice. The
  cost is that a participant who never answered there keeps the pre-F05
  outcome, which was no offer.
- The migration runs at world build. A mid-session `load_game` into an
  already-built world does not run it until the next build.
