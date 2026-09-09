# PR96 main release — verified publication

2026-09-09. Release run `34358304734`, attempt 1, succeeded for main
`1eef3df5a774e4fe4a2ba27751df24def522e2b7`. Both executed jobs were retrieved in
full and reviewed: build `102488518084` and Pages `102492716175`. Raw logs are
retained under `.artifacts/main-1eef3df5-release/` (1,640,909 characters).

The build log has no engine ERROR or SCRIPT ERROR. It retains installed OBJ
ambient-material warnings and the action runtime deprecation warning. The
packaged-ground probe reports terrain=yes, ground_at_spawn=0.90, player_y=2.90,
props=383004 and `export: OK`. This establishes the CI packaged-ground predicate,
not a rendered Windows playtest. Pages deployed the same SHA.

Independent public API read-back at 13:56 UTC verifies both the literal `latest`
git reference and release `target_commitish` equal this main SHA. Release id
364540334 publishes asset 552858606, `Tetherbound-windows.zip`, 694,157,216 bytes,
with reported SHA-256
`5ca71dee7fb47187d7be2cc40245f9d7ba841bff2597818fe9d2dcda1c56a97a`.
This is metadata read-back; the new archive was not downloaded locally again.

The published change is Arlo's narrow cloth contrast update. No held biome,
creature, craftsperson or new realm-transition protocol candidate is included.
Main CI is recorded separately; release success alone does not close Beta Ready.
