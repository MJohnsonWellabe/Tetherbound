# Fly carrier art: no `!is_inside_tree()` engine error on every launch

X05 (#292) saw repeated `ERROR: Condition "!is_inside_tree()"` from `fly_controller.gd:853 make_carrier_art`, called from `_launch`.
- **Cause:** the carrier art is measured before it is added to the tree. `global_transform` is unavailable there, so every carrier build logged the error, and the bounds silently used identity transforms.
- **Fix:** compose local transforms up to the art root (`_transform_to`), which is valid before the tree.

**Proof:** a probe builds the configured Galecrest capability out of the tree.
- Before (`before.log`): the engine error is logged.
- After (`after.log`): 0 errors.
- The carrier's scale (1.492754) and position (feet 2.45 m) are identical, so there is no visual change.
- `run_tests.gd --only=fly`: 10 tests, 83 assertions, 0 failed.
