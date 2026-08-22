# Superseded `ralph/**` branches — verified, not assumed

Checked 2026-08-22 against `origin/main` at `a22534ff` (integration-ABC).

The brief said these were stale and to "delete them from origin once you've
confirmed their content really is on main, rather than re-shipping". This file
is that confirmation, and the record of why deleting them from a session does
not work.

## Verdict

| Branch | Tip | On main? | Verdict |
|---|---|---|---|
| `ralph/integration-3` | `0e74163e` | ancestor of main | **SUPERSEDED** — fully merged, nothing to check |
| `ralph/TOURNAMENT-1` | `4a0ac01e` | not an ancestor | **SUPERSEDED** — see below |
| `ralph/TOURNAMENT-2` | `43a4e6be` | not an ancestor | **SUPERSEDED** — see below |
| `ralph/HUD-GLYPHS` | `f2305674` | not an ancestor | **SUPERSEDED** — see below |
| `ralph/HUD-LAYOUT` | `0f115222` | not an ancestor | **SUPERSEDED** — see below |
| `ralph/HUD-POPUP` | `9b7fbc21` | not an ancestor | **SUPERSEDED** — see below |
| `ralph/WEATHER-LIGHT` | `f74b21cf` | not an ancestor | **SUPERSEDED** — see below |
| `ralph/DPAD-COLLISION` | `da4fbc39` | not an ancestor | **SUPERSEDED** — see below |

## Why ancestry was the wrong question

integration-ABC was a MANUAL consolidation, so seven of the eight are not
ancestors of `main` and every one of them reports commits "not on main" —
3 to 18 of them. Taken at face value that reads as unmerged work. It is not.

Comparing tip trees against `main` instead, all seven share one signature:

```
+301  -41   scripts/ui/combat_hud.gd
+80   -8    tools/capture_combat_actions.gd
+22   -17   data/config/menu.json
+27   -44   project.godot
```

`main` is ~260 lines SHORTER in `combat_hud.gd` than every one of them, which
is the shape of dropped work. It is not dropped work.

**Those 260 lines are D32's hold-to-open party selector** —
`SWITCH_HOLD_THRESHOLD`, `combat_switch_left`/`combat_switch_right`,
`_selector_open`, `SELECTOR_ROWS` and the panel that drew it.
`ralph/OWNER_DIRECTIVES_2026-08-22.md` §1 bans held buttons outright ("don't
make a user hold a button down for any action") and CONTROLLER-MAP retired that
chord deliberately. `main` has **zero** references to any of those identifiers,
and `combat_switch_left` **is not an action in `project.godot` at all** any
more. The only two mentions surviving on `main` are historical comments in
`input_glyph.gd` and `test_controls.gd` explaining the removal.

So `main` is shorter on purpose, and these branches are older than the decision.

Everywhere else `main` is clearly ahead: `playground_hud.gd` (+117 −891 going
main→branch, i.e. `main` carries ~774 lines they do not), `party_strip.gd`
(−341), `chapter_rewards.json` (−232), the Band 1–5 `spawns.json`/`trainers.json`
tables, and `test_tournament.gd`.

TOURNAMENT-1 and TOURNAMENT-2 additionally carry their own
"superseded"/"handover" commits saying so.

## Deleting them needs a workflow, not a session

`ralph/conventions.md` says branches cannot be deleted from a session, and it is
right, in a way worth writing down because the failure is SILENT:

```
$ git push origin --delete ralph/TOURNAMENT-1
Everything up-to-date
$ git ls-remote --heads origin refs/heads/ralph/TOURNAMENT-1
refs/heads/ralph/TOURNAMENT-1
```

The git proxy reports success and does nothing. A session that does not verify
afterwards will believe it cleaned up. The GitHub MCP surface has
`create_branch` but no delete, so the API route is closed too.

**These eight are safe to delete by whatever can delete them** — a GitHub
Actions run, or a human. The analysis above is the part that does not need
repeating.
