# Main d3cdb57ca publication — verified

Release run [34390358670](https://github.com/MJohnsonWellabe/Tetherbound/actions/runs/34390358670) completed successfully on attempt 1, 2026-09-09 18:39:36–18:58:07 UTC, for `d3cdb57ca38acc2691c014663419389037b5209c` (PR104 after PR103 equipment).

Both executed jobs and every step were reviewed: build `102598747030`, Pages `102602202397`. Their complete raw logs total 1,654,277 decoded characters, retained with run/job metadata at `.artifacts/release-d3cdb57-ci/`. No native, script, or parse error appeared. Existing OBJ/PBR ambient-material and Actions Node deprecation warnings remain.

The Windows export passed the PE32+ and size checks: executable 109,052,928 bytes, PCK 969,469,760 bytes. The packaged Linux runtime check found Terrain3D, ground at 0.90, player at 2.90, and 383,004 props. This establishes the workflow's export check, not Windows or Ally hardware runtime acceptance.

The rolling tag was updated and verified at 18:55:28 UTC. Independent `git ls-remote origin refs/tags/latest` and release API read-back both identify the exact d3cdb57 commit. `Tetherbound-windows.zip` was updated at 18:55:27 UTC, size 694,349,456 bytes, GitHub digest `sha256:8f77c7fbe5c126698dceddb782f566c1b102752548855345cb462f70a1e21402`. Pages deployed that same commit successfully at 18:58:04 UTC.

The latest downloadable build therefore includes PR103 equipment and PR104's First Shore timber barrier. Main regression CI34390358648 is separate and remains queued at this audit. Reconnect PR106 and local terrain candidates are not in this publication. No campaign, visual, or Beta gate closes here.
