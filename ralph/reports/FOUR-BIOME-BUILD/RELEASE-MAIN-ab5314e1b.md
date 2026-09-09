# Main ab5314 release verification

PR95 landed as `ab5314e1b081b018decc17d070fba85ee3afd210`, ancestry and
reviewed tree verified. Release34346697917 completed build102449870870 and
Pages102452747336 successfully. Both complete raw logs (1,611,349 and28,472
characters) were inspected and retained in `.artifacts/main-ab5314-ci/`;
no native/script errors occurred.

The exported runtime reports `EXPORT-CHECK terrain=yes ground_at_spawn=0.90
player_y=2.90 props=383004`. The release step uploaded the Windows asset and
updated/verified the literal rolling tag at11:49:44.7896604Z. Pages deployment
also identifies ab5314. Independent API read-back confirms release364540334
targets ab5314 and the literal latest ref resolves to that same commit. This
preserves PR93's repaired publication identity; the release object's original
publication date is not a new-build timestamp.

The current Windows asset is `552656198`, `Tetherbound-windows.zip`,
692,440,579 bytes, SHA-256
`03b3b7490a2b5101f7c5e84432df1515242eca28253201f75b7dcfdc6b7460a3`.

This is release CI/runtime evidence, not a second local Windows downloaded-exe
proof, visual acceptance or campaign completion. Main CI34346697696 separately
passed all 27 executed jobs on attempt 1; see `CI-MAIN-ab5314e1b.md`.
