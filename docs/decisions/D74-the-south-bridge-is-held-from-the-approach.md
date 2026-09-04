# D74 — The South Bridge is held from the approach, and the deck is railed with rope

**Date:** 2026-09-04 · **Decided by:** lane W22-BRIDGE-SIGNPOST-0904, under the
COMMON rule that a lane makes the smallest defensible call and records it rather
than stopping to ask. Sources: `docs/prompts/74-ART-REFERENCE-owner-boards-for-meshy.md`
§7, `docs/GATE2_GATE3_CLOSURE_PLAN.md` CL-B3, the owner's 2026-09-04 instruction
that the signs and bridge be brought to board 18 without Meshy.

Four small calls, none of them a new mechanic, all of them reversible in data.

## 1. The checkpoint's occupation lives on the village-side shoulders, never on the deck

`scripts/world/south_bridge.gd::_build_occupation` stands the barricade frames,
the two staked banners, the lantern and the posted sentry **in front of the
archway on the village side, on the road's shoulders (|z| ≥ 1.5 m local)**. The
deck between the rails carries nothing new. The reason is the mechanism:
`gated_crossing.gd`'s leaf is the one thing that shuts the road, and it swings
open on the real unlock. A barricade laid across the deck would either need its
own second unlock or leave the player walking into timber behind an open gate.
Flanking the road, the barricade says "held" from the approach and costs the
open crossing nothing.

## 2. Only the body stands down when the gate opens

`data/config/south_bridge_dressing.json` gates the Bridge Sentry on
`unless_flag: south_bridge_open`, the same shape `relay_site.json` uses for the
relay's sentries. The barricade, banners and lantern **stay** after the gate is
opened. A guard standing over a gate the player just opened contradicts the leaf;
a barricade and a pair of banners beside an open gate are the evidence the
crossing was held, which is the story the player walked through. The hero gate
dressing already retires on the same event (PR #39); this adds one more thing
that leaves and deliberately nothing else.

## 3. The sentry is dressing, not a second gatekeeper

The fight at the crossing is `south_bridge_grunt` (band 1 `trainers.json`), 8 m
away and untouched. The sentry has no `greeting`, so `village_npcs.gd` draws no
prompt (INTERACT-SWEEP-0903). He is on `grunt_b` so he is not a silhouette twin
of the challenger's `grunt_a` in the same frame. Making him interactive, or a
fight, would change Band 1's ladder (T3-LADDER's 24-opponent census) and is a
design decision this lane does not own.

## 4. The rope rail is authored by the shared `south_bridge` recipe, so both gated crossings carry it

`building_prefabs.json`'s `south_bridge` prefab is used by the South Bridge **and**
the Old Mill Crossing. Its picket-fence rails are replaced by a `rail` block that
`gated_crossing.gd::_build_rail` turns into squared posts on stone footings,
sagging hemp ropes and wraps at every post; the floor slabs are yawed a quarter
turn so their plank seams run across the walk. Board 18's panel is explicitly
"used for small bridges, repairs, and world connection", so one rail language on
both crossings is the intent, not a side effect. The recipe's rail **colliders are
unchanged** — the gate seals exactly as it did — and a crossing that wanted the
old fence back would delete the `rail` block and restore its fence modules in
data. `village.json`'s `footbridge` (placed by `village.gd`, not a gated
crossing) is untouched.

## What this does not decide

- Whether the hero gate's own blue banners should be oxblood (the mesh is a Meshy
  scan from the owner's board 21; changing it is a board question).
- Whether the sentry should ever speak, or the challenger stand nearer the gate.
- Anything about the Old Mill Crossing's own dressing beyond the shared rail.
