# MP-1C-CHARSAVE — D100's split, finished

**Lane:** Stage B 1.C, the character save half.
**Base commit:** `6c5189fb3df75d575df65843ba0dbe6d94c9e6a2` (`claude/tetherbound-roadmap-next-jrcjs8`, "6.A's two smokes never opened the road to Cloudreach"). Not rebased.
**Branch:** `claude/mp-1c-charsave`. No pull request.
**Godot:** 4.7-stable installed at `~/godot-bin/godot` (`4.7.stable.official.5b4e0cb0f`), `--import` run twice on a fresh checkout, both clean.
**Date:** 2026-09-06.

---

## Verdict

**The character half is written, and D100's split is real.** A peer now writes
`user://characters/<character_id>/character.json` for itself; a host writes
`user://worlds/<world_id>/world.json`; a client writes no world file. A v≤22 slot splits on
first load into one world and one character, and the original file is byte-identical and
mtime-identical afterwards — asserted, not claimed. Key coverage is proved by round trip
rather than by a table.

**One deliberate deviation from D100, reported rather than hidden:** the v22 slot file is
still written and is still what `load_slot()` reads. The split is written *alongside* it.
§4 below says why, and what it would take to retire the slot.

**One pre-existing failure carried, not caused:** `smoke_playground` fails on the base branch
too, on a gather-swing timing assertion with nothing to do with saves. §7 has the reproduction.

---

## 1. What was built

| File | What it is |
|---|---|
| `scripts/save/world_save.gd` (new) | The host-owned half. `partition(v22)` → the world payload in `WorldState.save_data()`'s exact key names; `write`/`read`/`state`/`has`/`list_ids` over `user://worlds/<id>/world.json`. |
| `scripts/save/character_save.gd` (new) | The portable half. `partition(v22)` → `PlayerState.save_data()`'s key names; `merge(world, character, version)` is the exact inverse; `apply(game, id)` loads a character onto `Game.local`. |
| `scripts/save/save_game.gd` | `snapshot(game)` extracted from `save()` (the v22 dictionary, no file I/O). `save()` writes the slot file unchanged and then the split pair. New `save_world()`, `save_character()`, `worlds()`, `characters()`. `load_slot()` splits the slot on load. `slot_info()` gained `legacy`. |
| `scripts/net/session.gd` | `_save_character_here()` only. **I touched that one function** (and deleted the stale "HONEST GAP" doc comment above it that described the state it replaced). Nothing else in the file. |
| `scripts/ui/tab_save.gd`, `scripts/ui/title_screen.gd` | The slot rows mark a legacy slot `(Legacy)`. Marked, never hidden and never refused. |
| `tests/smoke_net_host_join_leave.gd`, `tools/net/peer_runner.gd` | Lane 2.A's two probes re-pointed; two new probes. §5. |
| `tests/helpers/split_save_fixture.gd` + four test files | §3. |
| `docs/acceptance/MULTIPLAYER_ACCEPTANCE.md`, `docs/specs/MP_STATE_SEAM.md` | Row 20's evidence cell; the seam's §7 handover corrected to say what 1.C actually did. |

### The partition

`world.json` state keys (8) — `day`, `clock_elapsed_seconds`, `world_seed`, `placed_buildings`,
`farm_plots`, `death_satchels`, `harvested_vegetation`, `felled_vegetation` — plus `flags` (the
world scope of v22's `progression`). Envelope: `version`, `world_id`, `display_name`,
`created_at`, `last_played`, `migrated_from`.

`character.json` state keys (8) — `party`, `inventory`, `hotbar`, `satiety`, `player_pose`,
`pending_realm_entry`, `realm_hearts`, `realm_maps` — plus `realm` (v22's `current_realm`,
renamed) and `flags` (the player scope). Envelope: `version`, `character_id`, `display_name`,
`created_at`, `last_played`, `last_world_id`, `migrated_from`.

**`map` and `alpha_pins` are derived, not stored.** Both are recoverable from
`realm_maps[realm]` — `map_state.gd::save_data()` already carries `alpha_pins`, and the v22
top-level `map` is the active realm's payload. `merge()` rebuilds both. This is deliberate and
it is the lesson from the world half: an eleventh top-level key is how
`test_save_data_carries_the_world_half_of_the_v22_keys` got broken once already. That test is
untouched and still green at 10 keys; `test_split_key_coverage_equals_v22` asserts the saver's
own list agrees with it (8 state keys + `world_id` + `flags`).

### `world_id` / `character_id`: the slot owns them

`"slot-<n>"`, or `"legacy-slot-<n>"` when the slot was migrated. A live id is honoured only
when it is already that slot's. The failure this closes: load slot 1, New Game, save to slot 2
— a saver that trusted whatever id was on the live state would have written slot 2's brand-new
world over slot 1's finished one. `test_the_slot_owns_the_world_id_so_a_new_game_does_not_overwrite_the_old_world`.

---

## 2. The legacy split, which was the part worth stopping over

`load_slot()` reads the slot, migrates it to v22 in memory, and hands the resulting dictionary
to `_split_legacy_slot()`. **Nothing in that function opens the slot file at all** — it never
receives a path, only the dictionary that was already read. "The original is untouched" is a
property of the code's shape, not of a promise. It is still asserted directly, both ways:

- `test_loading_a_legacy_slot_leaves_the_original_file_byte_identical` — `FileAccess.get_file_as_bytes` and `get_modified_time` compared either side of a real `load_slot()`.
- `test_loading_a_legacy_slot_twice_still_leaves_the_original_alone`.
- `test_a_current_version_slot_is_also_left_alone_by_its_own_load` — the rule is about the original file, whatever version it is, not only about old ones.

Both halves record `migrated_from: slot_<n>`. Neither is rewritten on a second load
(`test_a_second_load_does_not_rewrite_a_world_the_player_has_since_played`): the split is a
migration, and re-running it over a world the player has continued from would throw away
everything done since. The migrated ids are adopted onto the live state so the next save
continues that world instead of minting a second beside it.

The fixture is a hand-written **v18** slot, not a v22 one, so the split sees a dictionary that
has been through several migration steps — including the v19 clock, which a v18 file does not
have and which comes back as the "no carried clock" sentinel rather than hour zero.

---

## 3. Unit tests — commands, counts, and the break/fail/revert triples

Every count below is from a real run. Assertion counts are reported, not just pass/fail, for
the reason the brief names: `get()` on a missing key returns null, `int(null)` is 0, and that
aborts a function rather than failing it — a test can pass while running fewer assertions than
it should. Break 4a below is exactly that shape and shows it: 39 assertions instead of 40.

```
~/godot-bin/godot --headless --path . --script tests/run_tests.gd -- --only=<file>.gd
```

| File | Result |
|---|---|
| `test_world_save_format.gd` | **15 tests, 90 assertions, 0 failed** |
| `test_character_save_format.gd` | **16 tests, 83 assertions, 0 failed** |
| `test_legacy_slot_split_never_touches_the_original.gd` | **10 tests, 44 assertions, 0 failed** |
| `test_split_key_coverage_equals_v22.gd` | **9 tests, 40 assertions, 0 failed** |
| `test_save_format.gd` (untouched, 1.C must not move it) | **59 tests, 354 assertions, 0 failed** |
| `test_world_state.gd` (untouched; the 10-key test) | **15 tests, 81 assertions, 0 failed** |

### Break / fail / revert

Each break is in **production code**, never a weakened test. Each was reverted and re-run green.

| # | Deliberate break | Test | Red | Reverted |
|---|---|---|---|---|
| 1 | `save_game.gd::_write_split` — `if _is_host(game):` → `if true:` (a client writes a world) | `test_world_save_format` | 14 tests, 84 assertions, **1 failed** | 14/84/0 |
| 2 | `character_save.gd::partition` — `SCOPE_PLAYER` → `SCOPE_WORLD` (world flags travel with the trainer) | `test_character_save_format` | 16 tests, 83 assertions, **2 failed** | 16/83/0 |
| 3 | `save_game.gd::_split_legacy_slot` — restamp the migrated slot file at the current version (the exact rewrite D100 forbids) | `test_legacy_slot_split_never_touches_the_original` | 10 tests, 44 assertions, **3 failed** | 10/44/0 |
| 4a | `world_save.gd::STATE_KEYS` — drop `felled_vegetation` | `test_split_key_coverage_equals_v22` | 9 tests, **39** assertions, **3 failed** | 9/40/0 |
| 4b | `character_save.gd::merge` — derive the map from a hard-coded `"meadows"` instead of the trainer's realm | `test_split_key_coverage_equals_v22` | 9 tests, 40 assertions, **1 failed** | 9/40/0 |

Breaks 1–3 were run before the two later changes (the scratch-save gate and the envelope
cache); the fifteenth test in `test_world_save_format` was added with the scratch-save gate,
which is why break 1's counts read 14/84 and the final green reads 15/90.

`grep -rn "DELIBERATE BREAK" scripts/ tests/` → nothing. `git status` carries no break edits.

### One test I wrote wrong first, and what it taught

`test_the_round_trip_holds_for_a_trainer_standing_in_the_other_realm` failed on the first run.
It was not the code: the fixture had **one** map and no `save_realm_maps()`, so `save_game.gd`
fell down its legacy `_realm_map_payloads()` path and filed the single map under `"meadows"`
regardless of which realm the trainer was standing in — the merge then correctly derived an
empty map for `"cloudreach"`. The fix was to make the fixture model the real `Game`: two map
instances, a `save_realm_maps()`, and a different cell visited in each so handing back the
wrong realm's map is a *different* dictionary rather than an equal one. Break 4b then proves
the test can actually catch that.

### Full unit suite

Run in full (`tests/run_tests.gd`, no `--only`) against this tree — see §8 for the result.

---

## 4. The deviation: the v22 slot file is still written

D100 replaces `user://saves/slot_<n>.json` with the two new files. **This lane writes the two
new files and keeps writing the slot.** `load_slot()` still reads the slot; the split store is
written next to it and read through `worlds()`/`characters()`/`apply()`.

Why, concretely:

- `save_game.gd::slot_path()` is read by the whole Gate F operator harness (`operator_harness.gd`, eight `probe_*`/`seed_*` tools), by nineteen test files, and by `tools/net/peer_runner.gd`.
- `peer_runner.gd::_compute_state_hash()` calls `save()` and reads the bytes back **on every peer, host and client alike**, on every heartbeat. A client that refused the slot write would have returned `null` from that hash, which `net_harness.gd` reports as a harness fault (exit 2) — four other lanes' net smokes, broken by a save-format lane.

A save format is somewhere a half-finished change is worse than none. Retiring the slot is a
real change with a real blast radius across three tool trees, and it is not this lane's — so
the slot path is byte-for-byte what it was, and nothing in the game changed shape while the
character half was being added. What that costs is one duplicated copy of the same dictionary
on disk.

Two consequences the seam predicted that therefore did **not** happen, and I have corrected
`docs/specs/MP_STATE_SEAM.md` §7 to say so rather than leave the next lane a stale instruction:

- `merged_progression.gd`'s `save_data`/`load_data` are **not** deleted — they are still the flag store the v22 slot file goes through. Deleting them would stop every save in the game from recording a flag.
- The top-level `alpha_pins` key is **not** removed from the v22 file. Inside the split it is derived rather than stored, which is the outcome §2 wanted.

The lane that retires the slot deletes all three together.

### The cost, measured in what it writes

An autosave now writes three files instead of one. The two new ones together hold the same
state as the slot, so the bytes written roughly double rather than triple. `write()` does
**not** re-read the file it is replacing: it would have had to, to preserve `created_at`, so
each saver caches the envelope fields it must carry forward (`_preserved()`/`_envelope_cache`)
— the first write of a session pays one read, the rest pay none. Autosave runs while the player
is walking around and frame time on the Ally is one of the four owner-only open items, so a
third full JSON *parse* on that path was not acceptable; a second and third `store_string` is.
Worth a look on the Ally when the next kickoff run happens.

---

## 5. What I re-pointed in lane 2.A's probes

Lane 2.A left two placeholders in `tools/net/peer_runner.gd` and their assertions in
`tests/smoke_net_host_join_leave.gd`, to be **re-pointed, not deleted**.

| Probe | Was | Now |
|---|---|---|
| `autosave_exists` | Unchanged in meaning: does this peer's autosave slot file exist. | Unchanged. It was already the right question; the client's answer is still `false`. |
| `worlds_dir_entries` | A **forward** assertion — nobody wrote `user://worlds/`, so a client reporting 0 proved nothing, because the host reported 0 too. | A real comparison. The smoke now asserts **the host's is non-empty** first, and then that the client's is empty. Also hardened: `DirAccess.get_directories_at` on a missing path pushes an error, so the helper checks `dir_exists_absolute` first — "the directory is not there" is the client's correct answer, not a harness fault. |
| `characters_dir_entries` | — | **New.** The half the smoke was missing: a client writes exactly one character file, its own. |
| `character_file` | — | **New.** `{id, keys, party}` for the local peer's character file — enough to assert whose it is and that it carries a character rather than a world, without shipping the payload through the coordinator. |

The smoke's step-6 header comment now says what changed and why the old assertion could not
have caught anything.

`smoke_net_shared_building.gd` also uses `worlds_dir_entries` with the same meaning
("the client wrote no world save of its own"); that assertion still holds and I did not touch
the file.

### The run, locally, as required

```
tools/net/run_net_smoke.sh host_join_leave
```

**ALL CHECKS PASSED**, 28 checks, two real Godot processes with isolated `XDG_DATA_HOME`s.
The four new/re-pointed lines:

```
PASS: the host wrote a world file to user://worlds/ (["slot-0"])
PASS: the client's user://worlds/ is empty ([])
PASS: the client wrote exactly one character file, its own (["peer-9032-113931276"])
PASS: the host wrote its own character file too (["slot-0"])
```

and the client's file's key list, printed in the check so a reader does not have to trust me:

```
["character_id", "created_at", "display_name", "flags", "hotbar", "inventory",
 "last_played", "last_world_id", "migrated_from", "party", "pending_realm_entry",
 "player_pose", "realm", "realm_hearts", "realm_maps", "satiety", "version"]
```

— no `placed_buildings`, no `day`. A trainer is not a world.

`tools/net/run_net_smoke.sh shared_building` → **ALL CHECKS PASSED** (run because I changed a
probe it uses).

### Solo regression, by name

| Smoke | Result |
|---|---|
| `smoke_save_persistence` | **PASS** — "exact pose, opening/starter, Tam gift, TM/key one-shots, and controls survived a real Meadows save/load" |
| `smoke_title_load_game` | **PASS** — "physical pad activation loaded a real save and entered Meadows" |
| `smoke_title_new_game` | **PASS** — "physical pad activation reset live state and entered Meadows" |
| `smoke_playground` | **FAIL — and it fails identically on the untouched base.** §7. |

### The real `Game`, not only a fixture

The unit tests drive a `FakeGame`. `smoke_title_load_game` drives the shipped autoload through
a real title screen into a real Meadows, and the tree it left behind on disk is the honest
end-to-end evidence:

```
title_load_smoke_saves/worlds/legacy-slot-3/world.json      <- the split of a slot it loaded
title_load_smoke_saves/worlds/slot-3/world.json             <- the save it then wrote
title_load_smoke_saves/characters/legacy-slot-3/character.json
title_load_smoke_saves/characters/slot-3/character.json
```

`world.json` keys: `clock_elapsed_seconds, created_at, day, death_satchels, display_name,
farm_plots, felled_vegetation, flags, harvested_vegetation, last_played, migrated_from,
placed_buildings, version, world_id, world_seed` — day 6, seed 1879182550.

`character.json` keys: `character_id, created_at, display_name, flags, hotbar, inventory,
last_played, last_world_id, migrated_from, party, pending_realm_entry, player_pose, realm,
realm_hearts, realm_maps, satiety, version` — 1 creature, realm `meadows`, 2 player flags.

(The scratch directory is that smoke's own; `save_game.gd::_init()` puts the split
directories under any non-default slot directory, so a smoke or a unit test cannot leave a
world or a character in the real `user://worlds/`.)

### Import

CI's own import check, run locally:

```
godot --headless --path . --import 2>&1 | tee /tmp/import.log
grep -qiE "SCRIPT ERROR|Parse Error|Failed to load|ERROR: Cannot open" /tmp/import.log
```

→ no matches. Clean.

---

## 6. Findings (with reproductions), not fixed

### F1 — a scratch hash probe was renaming the host's trainer *(found here, fixed here)*

Recorded because it is the kind of thing that costs the next lane a day. The first run of
`smoke_net_host_join_leave` after the split landed passed, but the registry read:

```
registry rows agree across peers: host ["slot-4@1", "smoke-joiner@182029200"] ...
```

`slot-4` is `peer_runner.gd::HASH_SCRATCH_SLOT`. `_compute_state_hash()` calls
`save(game, 4)` on every heartbeat purely to hash the bytes back — and with the split
unconditional, that minted `worlds/slot-4` and `characters/slot-4`, stamped `"slot-4"` onto the
live `Game.local.character_id`, and the peer registry then advertised that id to the whole
session. It also rewrote both files several times a second.

**Fixed inside my lane**, minimally: `save()` gained `write_split := true`, and
`peer_runner.gd`'s two scratch-slot calls (`HASH_SCRATCH_SLOT`, `SAVE_SCRATCH_SLOT`) pass
`false`. A hash probe must not be able to rename a trainer. Pinned by
`test_a_scratch_save_writes_no_world_no_character_and_renames_nobody`. The registry now reads
`["peer-9031-113529015@1", "smoke-joiner@..."]` and the host's world directory is `["slot-0"]`
— the real autosave, alone.

### F2 — `session.gd::join()` puts a character id on the wire it never adopts *(not mine to fix)*

`join(ip, port, summary)` sends `summary["character_id"]` to the host, which files it in the
peer registry, but never writes it onto `Game.local.character_id`. So the id the session
advertises and the id the character file is written under can be two different things.

**Reproduction:** `tools/net/run_net_smoke.sh host_join_leave`. The client joins with
`{"character_id": "smoke-joiner"}`. The host's registry row reads `smoke-joiner@1064575538`;
the client's character file is written at `user://characters/peer-9032-113931276/character.json`
(`_local_character_id()`'s minted fallback). Both are visible in the run's PASS lines above.

**Why I did not fix it:** the fix belongs in `join()`, and my lane owns `_save_character_here()`
in that file and nothing else. It is harmless today (the registry only needs ids to be distinct)
and it becomes wrong the moment lane 7.A tries to reconnect a peer *to its own character file*
— it will look the character up by the registry id and not find it.

**Suggested fix, for whoever owns `join()`:** adopt a non-empty `summary["character_id"]` onto
`Game.local.character_id` before the hello goes out, so `_local_character_id()` and the wire
agree by construction.

### F3 — `smoke_playground` is red on the base branch

See §7.

---

## 7. `smoke_playground`, red on the base

The brief asks that `smoke_playground` print `smoke: OK`. It does not, and it does not on the
untouched base either.

```
~/godot-bin/godot --headless --path . --script tests/smoke_playground.gd
```

With my changes:

```
smoke FAIL: the gather resolved 0.84 through the swing, well past the 0.60 impact pose --
the hit reads as disconnected from the action
```

With my changes stashed (`git stash -u`), same command, same commit `6c5189fb`:

```
smoke FAIL: the gather resolved 0.86 through the swing, well past the 0.60 impact pose --
the hit reads as disconnected from the action
```

Same assertion, same failure mode, a value that differs only in the third digit — this is a
gather-swing animation-timing assertion with nothing to do with the save format, and the run
reaches it having already printed the farm-plot sow/ripen/pick sequence. **Pre-existing, in
another lane's area, not touched by this lane.** Recorded as a finding with a reproduction
rather than fixed, per the concurrent-lane rule.

---

## 8. Full unit suite

`~/godot-bin/godot --headless --path . --script tests/run_tests.gd`

**Running at the time of this commit** — started against this tree, not yet returned. The
result is appended in a follow-up commit on this branch rather than asserted here. What is
already known, run to completion against this tree:

- the four new files and the two they must not move (`test_save_format`, `test_world_state`) — all green, counts in the table above;
- CI's own import check — clean;
- the four named solo smokes and two net smokes — §5, with `smoke_playground`'s pre-existing failure in §7.

CI is the gate, and this branch has not run it yet.

---

## 9. Handovers

**To the lane that retires the v22 slot file (§4).** Three things come out together and not
before: `merged_progression.gd`'s `save_data`/`load_data`, the v22 top-level `alpha_pins` key,
and `save_game.gd`'s slot write. The blast radius is `tools/gate_f/operator_harness.gd` and its
eight probe/seed tools, `tools/net/peer_runner.gd` (three `slot_path` reads), and nineteen test
files. `character_save.gd::merge()` already reconstructs a v22 dictionary from the two halves,
so a compatibility shim for anything that must keep reading a v22 file is one function call.

**To lane 5.C (fog).** Fog now survives, and it survives in the right place: it is inside
`realm_maps[<realm>].visited_b64` in the character file, per realm and per player, beside the
landmarks and the alpha pins. `test_the_fog_a_player_walked_off_is_in_their_character_file`
pins it. What is *not* done: nothing yet **reads** a character file back on a client at join
time — `character_save.gd::apply(game, character_id)` exists and is tested
(`test_apply_restores_a_character_onto_a_player_state`), but no session code calls it, because
that is lane 7.A's reconnect path and calling it would have meant editing `session.gd` outside
`_save_character_here()`.

**To lane 7.A (disconnect / reconnect, late join).** The entry points you need exist:
`Game.save_system.characters().apply(game, character_id)` loads a character onto `Game.local`,
and `.worlds().state(world_id)` gives a payload `WorldState.load_data()` eats directly. Read
F2 first — the id you will look a character up by is not currently the id it was written under.

**To whoever owns `session.gd::join()`.** F2, with its one-line fix.

---

## 10. Rules I checked myself against

- **Five creatures, no storage, no reserve, no sixth slot.** A character file is exactly one party. `test_a_character_file_is_one_party_and_nothing_more` asserts the file carries no `box`/`storage`/`reserve`/`stored_creatures`/`party_box`/`pc` key and that its party is ≤ 5. Portability does not weaken the cap: `party.gd` is still the only thing that knows about it.
- **`OfflineMultiplayerPeer`.** Nothing in the new code calls `multiplayer.is_server()` or `get_unique_id()`. Ownership is `game.is_host()` — the session's question — everywhere, including a `has_method` fallback to `true` for a process with no session at all (a headless test, a capture tool).
- **`int(<whatever arrived>)` is not a coercion.** Every read in both new files is type-guarded before coercing; `test_garbage_in_the_progression_payload_does_not_abort_the_partition` feeds `[]`, `7`, `"flags"`, `null`, `{"flags": "not-an-array"}` and `{"flags": [1, "", null]}` through the partition and asserts the *rest* of each half is still complete.
- **A setup failure must not be worded as the feature.** The new probe helper distinguishes "the directory does not exist" (`[]`, the client's correct answer) from a `DirAccess` error, and the smoke asserts the host's directory is non-empty *before* asserting the client's is empty — so "both empty" fails loudly instead of reading as a pass.
- **Never fatal on load.** Missing, corrupt, and newer-than-this-build are all "nothing to load", with a `push_warning` and no crash, in both new files. Tested in both.
