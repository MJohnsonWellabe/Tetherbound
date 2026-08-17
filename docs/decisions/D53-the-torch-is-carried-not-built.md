# D53 — The torch is a carried item, not a buildable

**Date:** 2026-08-16 · **Decided by:** this firing, implementing `OW12`
against the owner's report: *"torches need to be a carry able item not
placeable one."*

## What was decided

The torch is now `data/items/items.json`'s own `torch` entry — `kind: "tool"`,
equipped off the hotbar/backpack exactly like an axe or pickaxe, its mesh
reaching the trainer's hand through `scripts/player/tool_hold.gd`'s existing
generic `held_model`/`held_offset`/`held_rotation_deg` pattern. `scripts/player/torch.gd`
now owns only the light — the forward-throw SpotLight and the prop's
flickering OmniLight — and both stay dark, at any hour, unless the torch is
the equipped tool.

`data/items/buildables.json`'s placeable ground torch is retired. There is no
longer any way to plant a stationary torch in the world.

## Two owner directives, and which one wins

`OF24` was itself an explicit owner directive — *"Torch building should be
free"* — and it is not being quietly erased. `buildables.json`'s own
`_comment_free` records OF24's words verbatim, with a note appended in place
naming this decision as what superseded it. The newer word wins, the same
rule `D23` already applies to the spec versus earlier design docs, but the
older one stays legible in the file it used to govern.

OF24 also built something this decision touches a second time: before OW12,
the torch was not merely free to build — it was an **always-on kit fixture**,
attached unconditionally the moment `player_controller.gd` stood the trainer
up, with no item to lose or leave behind. That was itself a deliberate OF24
choice ("the fix must not be 'the player discovers that in the dark and then
has to craft a torch'"). OW12's own words are unambiguous that this is what
the owner now wants instead — a torch you carry OUT of the pack, not one that
is simply always there — so the kit fixture is retired along with the
placeable, not kept as a third path alongside the new item.

## Why the mesh moved into `tool_hold.gd` instead of staying in `torch.gd`

`torch.gd` used to run its own copy of "find the rig's skeleton, hang a
`BoneAttachment3D` off a bone, parent a prop to it" — the exact same shape
`tool_hold.gd` already ran for axe/pickaxe/knife, mounted at `Hips` instead of
a hand bone because the torch had never needed a hand before. Keeping both
would have meant two hand-attachment systems in one codebase, and once the
torch is equipped exactly the way any other tool is, there is no reason for
it to draw its mesh a different way. `torch.gd`'s copy is gone;
`tool_hold.gd`'s generic system draws the torch mesh the same way it draws
every other tool's, from the same `held_model`/`held_offset`/`held_rotation_deg`
data on the item. `tool_hold.gd` gained one small public accessor,
`prop_node()`, so `torch.gd` — and a smoke test — can find where the mesh
actually is without a second private field to reach into.

## The gap that got closed in the same pass

**Nothing put a `torch` in the player's satchel, in the WIP this decision was
first written against.** Tam the blacksmith's dialogue line (`OF30`,
`village.json`'s `village_tam_tools` conversation) already said *"Take the
spare torch off the wall too"* — but that line had never carried a
`give:torch` effect, because until this decision there was no torch item for
it to name. Leaving it that way would have made the whole feature this
decision builds permanently unreachable: `playground_hud.gd`'s
`_arm_torch_placement()` refuses to equip a torch that is not in the satchel,
and nothing else in the game hands one out. A carried item nothing ever
carries is not what the owner asked for. The salvage pass that finished this
branch closed the gap in the same shipping window rather than leaving it for
a separate item: the "take the spare torch off the wall" line now carries
`give:torch:1`, the same line the words already promised it on (see
`village.json`'s own `_comment_ow12_torch_give`).
`tests/test_dialogue_runner.gd::test_the_torch_is_handed_over_in_words_and_not_as_an_item`
is updated to match — the torch is now handed over as an item, not just in
words.

**Retiring the placeable still strands camp lighting at night.** The old
buildable let a player plant one or more stationary torches to light a camp
while away from it (sleeping, crafting, wandering off) — the carried torch,
by definition, only lights wherever the player is currently standing. There is
now no way to light a camp except by standing in it with a torch in hand. This
is a real, reported gap, not an oversight papered over with an invented
replacement (a camp-attached light, a lit `camp` buildable variant, etc.) —
`OW12`'s own brief asked for exactly that restraint if this happened.
