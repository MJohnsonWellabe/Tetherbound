# Terrain main release — verified 2026-09-09

[Release 34397173485](https://github.com/MJohnsonWellabe/Tetherbound/actions/runs/34397173485) completed on attempt1,19:47:43–20:07:23 UTC, for `e231897f456f6dea7482c59cfa21850fccd0cee2`. Both jobs and all executed steps passed. Both complete raw logs (1,654,738 bytes) are retained under `.artifacts/release-e231897f4-ci/`; no native ERROR, SCRIPT ERROR or parse-error line appears.

The Windows package contains a109,052,928-byte executable and971,578,884-byte PCK. The packaged Linux runtime check found terrain, ground at spawn0.90, player Y2.90 and383,004 props. This does not replace Windows hardware playtesting.

The release API and `git ls-remote origin refs/tags/latest` independently identified this exact commit at verification. The ZIP is695,685,885 bytes, updated20:01:54 UTC, with digest `sha256:858a7ecfc540fff72696a5fdb3f592afbb76eb19950eb9c08ba03f22f60f5007`. Pages raw logs identify the same build version and report successful deployment at20:07:19 UTC.

The published build includes the equipment, First Shore timber barrier, title-flow reconnect and terrain mipmap corrections. Terrain PR CI and exact landing tree were reviewed before merge; main CI34397173524 remains a separate pending verification. Creature mipmap changes are held and are not included. Publication does not close the continuous earned campaign or C6.
