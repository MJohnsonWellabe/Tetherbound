# F08#5 Solmane: freed after Veyra, one offer to each finale participant

Owner ruling (#356 5858140459): Solmane works exactly like the Meadows Veridian. It reuses `scripts/world/stronghold_climax.gd` as a second instance (`CloudreachSolmaneClimax`, config `data/config/cloudreach_solmane_climax.json`), with receipts prefixed `cloudreach:`. There is no second system. Solmane is never wild: the summit wild tables hold tempestwing.

## Two peers, `two-peer-run3/` (PASS, exit 0)
The scenario is `tools/net/proof_scenarios/f08_5_solmane_two_peer.json`.

- **Answers:** the host (four in party) accepts and ends with five, Solmane included. The guest (five in party) refuses and keeps the same five uids.
- **Receipts:** each character gets its own world receipt.
- **Disconnect:** the guest's link drops, and the guest rejoins as the same character with no second offer.
- **Host restart:** the host restarts and reloads from Load, and both receipts persist. The host is not offered Solmane again.
- **Saved characters:** the host's saved character holds Solmane; the guest's does not. A negative control shows that this check reads real content.

The rows marked `expect FAIL` are expected refusals, with stage `done`. These are the no-second-offer checks, the negative control, and the `enter_realm` rows that fire when the peer is already in Cloudreach.

Disclosed fixtures:
- `story_flag` sets chapter flags through Veyra's defeat.
- `veridian_fixture` journals both peers as Veyra participants.
- The freeing is set as a world fact; the solo smoke presses the lever itself.
- `party_grant` fills the belts.
- Teleports place each trainer in the chamber.
- The answer calls the prompts' own `accept_offer`/`refuse_offer` handlers.

Harness fixes along the way:
- **run1:** the dialogue clear knew only Meadows' SequenceDirector. It now falls back to the world's DialoguePanel.
- **run2:** `title_load` had the default budget and Cloudreach loads slower. It now has 20000 frames, the same as the rejoin step.

## Solo
`tests/smoke_cloudreach_solmane_offer_choice.gd` is the Veridian solo smoke run against the Cloudreach instance. It covers accept/refuse with space, refuse at five, accept at five then let the newcomer go, accept at five releasing one, and a save while the choice is open. Each case includes a real reload. See `solo.txt`.
