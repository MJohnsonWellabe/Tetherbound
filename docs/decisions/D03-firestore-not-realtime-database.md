# D03. Cloud store is Firestore, not Realtime Database

Kind: spec-conflict

GolfModel uses RTDB, so this diverges from the house pattern deliberately.

RTDB deletes empty arrays, empty objects and nulls on write and returns them as
`undefined` on read. A fresh Tetherbound save has ten fields where empty is the
normal, correct state: 24 null inventory slots, plus empty `party`,
`releasedLedger`, `structures`, `badges`, `flags`, `buffs`, `harvested` and
`bossesDown`. GolfModel's `migrateProfile` exists largely to backfill what RTDB
ate, and the one path where it did not, a throw inside the merge was swallowed
and reported to the player as "offline" while the write never happened.

Firestore preserves all of it, has a 1 MiB document ceiling that doubles as a
testable size budget, bills per operation (which suits one write per bed
sleep), and can express the party cap in its rules language.
