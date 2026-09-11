# Saddle crafting regression — legacy tournament reward repair

## Result

The owner-visible “Why can't I build a saddle anymore?” regression had a
concrete legacy-save path. Current tournament finals grant both
`tournament_won` and `recipe_saddle`, and current crafting data is healthy, but
an older save may already contain the irreversible victory flag without the
recipe entitlement added later. The final cannot pay twice, while
`CraftPanel` correctly hides unknown recipes, leaving Riding Saddle permanently
absent from that player's crafting list.

`SaveGame` now reconciles that exact earned state on load:
`tournament_won` implies `recipe_saddle`. It grants no inventory, materials,
Saddle Frame, finished saddle, fitted-creature flag, or repeat tournament
payout. The operation is idempotent and follows the existing completed-Warden
reward repair seam.

## Evidence

- Focused units: `test_meadows_realm_save_repair.gd`, `test_recipes.gd`, and
  `test_riding_saddle.gd`: **60 tests / 621 assertions / 0 failed**.
- Production UI smoke: `smoke_legacy_saddle_recipe_repair.gd`: exit 0. It writes
  the historical `tournament_won`-without-pattern state, loads it through the
  production saver, confirms neither Saddle Frame nor Riding Saddle was
  granted, opens the production Craft panel, and finds navigable rows for both
  required crafts.
- `git diff --check`: clean for all changed source and test files.

This repairs the legacy-save regression only. It does not claim the saddle is
free or available before the tournament victory and required material route.
