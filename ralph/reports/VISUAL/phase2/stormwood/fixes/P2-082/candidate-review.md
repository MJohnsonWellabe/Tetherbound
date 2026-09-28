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

`tools/phase2_capture_stormwood_people.gd` prepares 24 explicit conversation
rows, each with a post and panel image: eleven arrivals, eight progress/aftermath
rows and five synthetic Wen/Bryn panels. A baseline/candidate pair is 96 images
across two production-world boots. The plan probe verifies 24 unique rows.
The fixture disconnects the chapter's dialogue-finished progression callback
and disables its arrival polling, while preserving panel/camera callbacks.
Every row records progression flags before and after close and fails on a
change. Direct starts bypass earned story prerequisites; these are presentation
fixtures only. Portrait and opening gates toggle together for this comparison,
and the trainer gate stays off.
The people fixture waits for any active production conversation-camera blend
to finish before saving, with a bounded failure instead of a partial-blend
image. A legitimately inactive push-in remains possible; active/blend/fallback
and shot metadata record what actually happened. These changes affect capture
timing only, not the production camera's target, lens or behavior.
