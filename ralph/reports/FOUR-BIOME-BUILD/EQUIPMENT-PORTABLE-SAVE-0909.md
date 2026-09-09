# Equipment portable-save validation — 2026-09-09

## Scope

This focused validation owns only `tests/test_equipment_portable_save.gd` and this
report. It does not change save, equipment, player, world or network production code.

The cases use the real `PlayerState`, `PlayerEquipment`, `ItemDB`, `SaveGame`,
`CharacterSave` and `WorldSave` classes under an isolated
`user://test_equipment_portable_save/` tree. They cover:

- a real version-1 portable character file with no `equipment` field;
- a version-2 character file written to disk and applied to a fresh player;
- switching one live player between two disk-backed character identities, then reset;
- merging a disk-backed host world partition with a different guest character
  partition.

The boundary under test is local serialization and partition ownership. No multiplayer
peer was launched, so this report makes no network replication or reconnect claim.

## Expected contract

Missing v1 equipment loads as empty worn state. A v2 worn item stays in its authored
slot without also appearing in inventory. Applying a second character clears the first
character's slots, and reset clears all five. During split merge, day, seed and placed
world records come from the selected world while equipment comes from the guest
character.

## Evidence

The focused Godot 4.7 headless run completed from
`2026-09-09T17:38:42.6722157Z` to `17:38:45.3685256Z`, exit 0:

- 4 tests / 35 assertions / 0 failed;
- zero `ERROR`, `SCRIPT ERROR` or `WARNING` lines across console, stderr and engine
  logs;
- no pre-existing or remaining Godot process;
- launch guard sampled 56.31% system commit and 252 processes;
- isolated scratch data was removed after every case.

The v1 case wrote a real version-1 `character.json` without `equipment`, read it
through `CharacterSave`, and applied it over a player already wearing insulated boots.
All five worn slots reset and the v1 character identity loaded. The v2 case wrote the
real current portable envelope and payload, read it from disk, then applied it to a new
`PlayerState`; the vest remained worn and did not also appear in inventory. The switch
case applied two distinct disk-backed characters to one player, proving the second
character clears the first character's boots before loading its vest; `reset()` then
cleared all five slots. The partition case wrote a host world and a guest character to
their separate real split stores, read both states, and merged them: host day 8, seed
111 and `host-dock` building survived, while the guest insulated helm survived and the
host's boots did not cross into the merged character state.

No production defect was found. The result establishes local disk and partition
behavior only; no peer process or reconnect path was exercised.

- test SHA-256:
  `8304EB8914138C7300924C19C8A92400E12BCB40FD37474B6B4253CF991204FB`;
- console SHA-256:
  `0C4F8FA1A7152F4FC4BC545A191290AE98B6DDC7218A69432174DCEB933617C0`;
- stderr SHA-256:
  `E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855`;
- engine-log SHA-256:
  `A724B0AFEA9C72E87206B752873914EC1CE5C44417C2A8BA8FA1C2752BFC960B`;
- receipt SHA-256:
  `5F948944D7B36140B301A968F860D1CE3B772EACE048268FBAB7FD969F912B90`;
- retained evidence root: `.artifacts/equipment-portable-save-0909`.
