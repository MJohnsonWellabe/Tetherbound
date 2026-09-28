# Named portrait / world-body source audit

The nine catalogued speakers have installed portraits rendered from their
actual world body profiles. The current conversation mappings use other
profiles. This supports a mapping correction without replacing world models
or generating new art; it does not establish native visual acceptance.

| Speaker | Production body profile | Existing matching plate |
|---|---|---|
| Rook | rival_trainer | juno.png |
| Lio | creature_caretaker | fenn.png |
| Maud | local_historian | old_perrin.png |
| Ondra | craftsperson | ada.png |
| Hesk | local_historian | old_perrin.png |
| Oswin | trader | corin.png |
| Warden-Elect Bryn | local_historian | old_perrin.png |
| Wen | field_researcher | maren.png |
| Tamsin | young_trainer | bryn.png |

At source `5b4f093d3`, `stormwood_chapter.gd::_npc_spec` passes each registry
`body_profile` as its world-model config key. The installed portrait tool's
`PORTRAITS` entries identify the matching rendered plates above. The names on
those files refer to other users of the same installed body; the dialogue
speaker label is separate. All matching files exist. These statements compare
source recipes, not the final rendered faces or a new character-identity design.

The registry's `portrait` field alone is not the fix: chapter mounting registers
the conversations from `data/dialogue/stormwood.json`. Several side/state
conversations also reference absent profile-named files (for example
`field_researcher.png`); `dialogue_panel.gd` leaves an absent plate hidden.
Matching only an actor-ID prefix would miss some of these side conversations.
The synthetic Wen refusal conversation separately hardcodes `old_perrin.png`.
A future gated correction must cover actual registered conversations and this
synthetic entry while preserving speaker, text, branches and completion events.

`portrait-source-mapping.json` records profile-to-plate recipes, registry paths,
actor-prefix and speaker-matched conversation paths, source-file hashes and
matching plate hashes. The audit also finds the same source mismatch for Fenn
and Neri; this is recorded without claiming additional native sightings. No
production mapping or asset changed in this audit. P2-082 remains open pending
an implemented candidate and paired world-speaker/dialogue captures.
