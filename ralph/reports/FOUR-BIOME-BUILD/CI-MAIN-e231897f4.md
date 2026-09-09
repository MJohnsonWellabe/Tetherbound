# Terrain main CI — passed on attempt1

[Run34397173524](https://github.com/MJohnsonWellabe/Tetherbound/actions/runs/34397173524)
verified main `e231897f456f6dea7482c59cfa21850fccd0cee2`, 2026-09-09
19:47:43–20:46:48 UTC including queue time. All27 executed jobs and steps
passed; the two explicitly known-red full-route jobs were skipped. All27 full
raw logs (10,309,555 bytes), metadata and comparison are retained under
`.artifacts/main-e231897f4-ci/`.

The four unit shards passed3148 tests/488076 assertions. All38 network smokes
ran on invocation1/1, with no failed invocation or retry. Full-log comparison
against PR107 found no SCRIPT ERROR or new non-shutdown diagnostic class.
There are310 known native diagnostic lines, with only shutdown-resource count
variation; this is not an error-free-log claim. Windows export and packaged
ground verification passed.

The source tree is the previously verified PR107 tree
`eb91a6a078c7fc0f35db36e32f3cc672269f0ce8`. Publication of this main is
separately verified in `RELEASE-MAIN-e231897f4.md`. The newer c3e198b81 main
has its own CI34401138071 pending and a separately verified release.
No campaign or full visual acceptance follows from this regression suite.
