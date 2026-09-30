F27#0 — nine stackable items

The catalogue adds Ground, Water, Air, Electric, Fire, Dark, Ice and Psychic
Essence plus Tether Candy. Essence stacks hold 999; Candy stacks hold 99.
Essence IDs/types/stack limits match F16's canonical schema. Every prior item
definition, ID and other catalogue key is unchanged. Existing installed icon
paths are reused. Tether Candy has kind `training` without `level_up`, so this
change does not enable generic candy spending.

The exact acceptance wording is: "Eight type essences (ground, water, air,
electric, fire, dark, ice, psychic) and Tether Candy exist as stackable items."

Main baseline: `1daa6dfff5ac4aa509e627c5e2f2fd2cff7ce972`.
Candidate items blob, after LF normalization, SHA256:
`16d7394713a57a37212a2417d8cd5f399db9ef523478975d29cba6e79d54cadc`.

| Proof | Observed | Scope |
|---|---|---|
| Parsed candidate against main catalogue | Exactly nine additions; zero removals or prior field changes | F27#0 data only |
| F16 schema comparison | Eight exact essence IDs/types; stack999; Candy stack99 | Canonical IDs and stackability declarations |
| Actual ItemDB/PlayerState/Inventory source trace | Default ItemDB reads this catalogue; canonical inventory receives that DB; add/move ask stack_size and merge same-ID stacks | Unchanged production registration/stack path |
| Independent draft review | PASS literal item existence/stackability, with static-only disclosure | Raw report archived in f27-item-cut-draft-review.txt |

The independent draft review used main `a6fbdb5bac7d3af93a59e45c246399943b9ee813`.
The candidate items blob is identical at the newer main baseline above, and
`autoload/item_db.gd`, `autoload/inventory.gd`, `autoload/game_state.gd`,
`autoload/player_state.gd` and `project.godot` are unchanged between those
baselines. Its production source trace therefore still applies. The raw report
is archived byte-faithfully; exact committed-cut review is still required.

No Godot constructor, gameplay inventory operation, player UI, acquisition,
Altar spend, save/reload or two-peer path was run. F27#0 names a data fact;
the independent reviewer explicitly accepted the unchanged loader/stack path
under RD-36/RD-37 without a new engine check. This report does not imply any
other F27 criterion passes. Board credit remains pending exact review and
merge to main. No test was skipped, disabled or quarantined.

This cut contains no seeds, attuned ingredients, Forge materials, old-item
rename, F28 recipes, runtime scripts, config, scenes, save/autoload changes or
UI activation. All further training work is preserved in pushed immutable tag
`tb-training-wip-before-f27-items-cut-20260930` at
`657092e5e58e3afa9df8f412b76f9e7cd3c82c52` and is outside this cut.
