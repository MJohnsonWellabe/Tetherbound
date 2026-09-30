# Original hosted feedback diagnostic

Executed clean source `4f4ff1ebdddfd1a4666fc6e802e6fed02c5c491c` with the original
`smoke_net_shared_wild_fight.gd --feedback` assertions. Godot exited natively
with 0 after 203.031 seconds; coordinator output ends `ALL CHECKS PASSED`.
Both peer processes exited normally in `NET_RUN.json`. The original failing
52dd incoming run remains archived separately, without deleted assertions.

The first host incoming receipt `1:1:enemy:1` records actual damage
13.6234620982535, Label text `14`, `number_seen=true`, camera present,
`behind_camera=false`, HUD present and connected. Host/local poise both equal
26.3765379017465. This diagnostic is green on the current source. It does not
establish the cause of the older missing Label or demonstrate a specific
product repair. The camera implementation changed between those executions.

The Python wrapper failed only after the engine exited and persisted its native
receipt, while printing the captured Unicode critical-symbol text to a cp1252
terminal (`UnicodeEncodeError`). Wrapper exit 1 is distinct from the recorded
Godot native exit 0. All raw captured logs and the native receipt are retained.
Text logs may be normalized from CRLF to LF by Git; original native files remain
at `D:/tetherbound/combat-guest-incoming-r2`.

Scope: actual two-process ENet shared fight, parsed gameplay input and production
receipts/HUD Labels; isolated user-data directories and the existing staged
party/position/encounter fixtures. Headless execution does not prove visible
pixels, audio quality, physical controller use, campaign earning or whole F21
acceptance. No full suite was run for this diagnostic.
