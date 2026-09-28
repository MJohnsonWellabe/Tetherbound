# Installed portrait mapping candidate

The separate `npc_portraits.enabled=false` gate in
`stormwood_dialogue_presentation.json` maps seven existing body profiles to
their already-installed portrait plates. Chapter mounting applies the mapping
to the exact registered speaker names, including side/state conversations and
the synthetic Wen guardian refusal. The four Glass for Bryn activity panels
register later; a second pass updates only those exact registered IDs after
their mount, preserving other chapters' tables. It covers the nine catalogued speakers
plus Fenn and Neri, who use the same affected profiles. No world body, name,
dialogue text, choice, requirement, completion event or progression flag changes.
Missing candidate plates preserve the original path.

The focused enabled-overlay and existing NPC suites pass 7 tests / 613
assertions without diagnostics (`.tmp/stormwood-phase2/portrait-candidate-tests-r2.log`).
They verify actual authored conversations, generated refusal and all four later
Bryn activity conversations, preservation
of all non-portrait fields, disabled behavior and a missing-file fallback.
They do not establish panel appearance or prove ordinary interactions.

Independent source reviewer `stormwood_dialogue_review` verified the seven
profile recipes and installed plate hashes. Review found the four later Bryn
registrations and stale dialogue-camera metadata; both were corrected and the
final bounded recheck found no remaining source/evidence issue.

The existing dialogue recorder now records the actual camera transform,
speaker and displayed portrait at the dialogue image, instead of inheriting
the post frame's camera metadata. The production camera and panel behavior
are unchanged. Native baseline/candidate post and dialogue pairs, side/state
panel checks and independent identity review remain required. P2-082 remains
open, and the candidate is off.
