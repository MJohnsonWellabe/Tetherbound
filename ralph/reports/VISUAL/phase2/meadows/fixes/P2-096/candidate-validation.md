# Craft action hint candidate

The independent full-resolution baseline review recorded in
`../P2-095/baseline-judge.md` found that "Craft: A / Enter" and "Leave: B / Esc"
recede at reduced size. Catalog sightings repeat the issue in three biomes.

The candidate uses the existing secondary text color and label font size for
both action hints. Bindings, hint wording, recipes and transactions are unchanged.
The local presentation flag `craft_presentation.json::readable_action_hints`
defaults to **false**, independently of the recipe-row candidate.

`tools/phase2_capture_build_systems.gd --craft-hints-preview` previews and records
the override; it can be combined with `--craft-readable-preview` for the same
native capture round. Independent before/after judgment remains pending.
**Not visually accepted or fixed.**
