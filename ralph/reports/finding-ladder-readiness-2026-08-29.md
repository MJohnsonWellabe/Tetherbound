# Finding — §10 readiness across the whole challenge ladder, 2026-08-29

`ralph/T3-STRONGHOLD`, third unit of work this session. Scope handed over by
a coordinator check-in: extend the readiness-signal pattern just built for
the three Captains to the rest of spec §3's ten-rung ladder — South Bridge,
the Warrens Guardian, Captain Vance at the Relay, the Meadows Hall gauntlet,
and the Warden.

## Merge first

`origin/main` had moved to `961a8c02` (LAND-0829A's integration: seven lanes,
the Warrens fix, a scatter re-bake, and `pasture_drover_juno`'s 12/12 → 13/13
level fix). Merged clean, no conflicts — this branch's edits stay inside
files that landing branch does not touch (`stronghold_climax.gd`, the two
test files, `data/dialogue/trainers.json`, `ralph/reports/`). Re-ran the
targeted suites after the merge (`test_trainers_data.gd`,
`test_grass_field.gd`) — clean.

## Rung by rung

| rung | trainer/id | carrier | verdict |
|---|---|---|---|
| South Bridge | `south_bridge_grunt` | `south_bridge_grunt_challenge` | added |
| Warrens Guardian | (wild boss, not a trainer row) | `warrens_watch_pell`'s `_defeated` line, the last thing said before the dungeon mouth | added |
| Captain Vance | `relay_captain` | `relay_captain_challenge` | added |
| Meadows Hall gauntlet | `stronghold_patrol` (first of three) | `stronghold_patrol_defeated` | added |
| Warden | `warden_aldis` | `stronghold_elite_defeated` (Keeper Hald, the last conversation before him) | **already adequate — not touched** |

**The Warden already had one.** `stronghold_elite_defeated`'s existing
second line — "Rest your five first. He fields more than I do, and he'll
wait" — is exactly §10's ask (a rest recommendation plus a team-size
expectation), delivered at exactly the point §10 wants it (the last
conversation before the fight it is about). Per this lane's own standing
instruction, this is reported as already met with the line quoted above as
evidence, not touched.

**The Warrens Guardian is not a trainer.** `data/config/burrow_warrens.json`
builds it as a wild boss (an alpha-presented Burrowback, catchable like any
wild encounter — CLAUDE.md's rule, catching stays available in wild combat),
so it has no `challenge`/`defeated` conversation pair of its own to carry a
signal. The natural carrier is `warrens_watch_pell`'s own `_defeated` line —
Pell stands at the dungeon mouth and is the last thing the player hears
before walking in, the same structural role Verrick/Hald play for the Hall
gauntlet and the Warden.

## What each line says, and why

- **South Bridge** (`south_bridge_grunt_challenge`): "Two of mine, nothing
  special. If that string at your heel is worth anything at all, this won't
  take long." — reassurance, not warning. Spec §4's own design intent for
  this fight is "I can beat their lowest-level people," so the honest signal
  here is *small and unremarkable*, not a danger cue.
- **Warrens Guardian** (`warrens_pell_defeated`): "Bigger than the ones
  you've been fighting on the way in, and it knows a heavier trick than they
  do. One answer won't be enough if it's the only one you've got." — matches
  `burrow_warrens.json`'s own design intent (a signature move the ordinary
  wild burrowbacks do not carry) and the band's own trainer-ladder comment
  ("a five carrying nothing that answers Ground finds out here").
- **Captain Vance** (`relay_captain_challenge`): "Three of mine, and I don't
  send the weakest out first. If your five are still worn from the walk up
  here, that was the place to fix it, not this one." — team-size expectation
  plus an explicit rest-before-committing cue, matching §7's own "practical
  camp/recovery opportunity before commitment" ask for this approach.
- **Meadows Hall gauntlet** (`stronghold_patrol_defeated`): "Three of us
  stand between here and the Warden, and none of us fields less than the
  last. Bring your whole five in, not just your best one." — endurance-
  sequence framing (matches `data/progression/objectives.json`'s own
  "Fight through the guard inside Meadows Hall. 0/3" count, which already
  signals the sequence-length half of this on its own) plus a "use your
  whole roster" cue this rung did not have yet.

None of this is a new stat, a new UI element, or a level lock — every line
above is inserted into a conversation the player already reads before or
during a fight that already exists, matching §10's own explicit sizing
guidance and the exact device this lane already used for the three Captains.

## New test coverage

`tests/test_trainers_data.gd::test_the_wider_ladder_carries_its_own_
readiness_signal` pins all five rungs (four new lines, one pre-existing one)
against the real dialogue table, so a future rewrite of any of these
conversations cannot silently drop the signal. Needed one small addition to
support it: `_joined_conversation_text()`, because `south_bridge_grunt_
challenge`'s last line is a `{text, effect}` Dictionary (the one that
triggers the battle) rather than a plain String, which a naive `" ".join()`
over raw lines does not handle — mirrors the same String/Dictionary branch
`dialogue_runner.gd::line()` already makes, rather than inventing new
parsing.

`test_trainers_data.gd` (50 tests, 1252 assertions) and a broader targeted
sweep (`dialogue_runner`, `progression_state`, `quest_log`: 121 tests, 1512
assertions) both pass clean.

## What this pass did not do

No trainer's team, level, reward, or position changed. No new dialogue
system, objective mechanic, or numeric stat was built — every signal above
reuses `dialogue_runner.gd`'s existing conversation table and (for the Hall
gauntlet's sequence-length half) `objectives.json`'s existing `count_flags`
feature. Did not touch `band4`'s `harvest.json`/`spawns.json` (T3-RELAY) or
`spawns.json` in bands 1/3/5 (T3-REWARD).
