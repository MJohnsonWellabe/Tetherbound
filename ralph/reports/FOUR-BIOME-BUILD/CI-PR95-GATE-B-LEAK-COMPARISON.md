# PR95 Gate B shutdown comparison

Corrected head `2a971cb3a`, CI `34344633432`, job `102444136215`
completed Gate B CORE successfully and then reported eight leaked ObjectDB
instances and four resources still in use. The immediate main4830 comparison
job `102344184296` and superseded PR95 job `102440705195` did not report it.

Root fetched the complete preceding PR92 raw job `102333955325` (329,046
characters) and main8c0 job `102337719860` (328,617 characters). PR92 already
reported exactly eight ObjectDB instances at `2026-09-09T04:14:01.4287899Z`
and four resources at `04:14:01.4290885Z`; the main8c0 job did not.
The same smoke therefore exhibited this shutdown signature before the aim
change. This resolves the concern that its first observed occurrence was PR95;
it does not fix or explain the intermittent pre-existing leak. No workflow or
world rerun was used. Logs do not identify the leaked objects without verbose
output, so a specific ownership cause is not claimed.

Sources: GitHub Actions jobs in repository `MJohnsonWellabe/Tetherbound`,
PR92 CI `34309659360`, main8c0 CI `34310983183`, current PR95 CI
`34344633432`. The broader PR95 exact-head review remains pending.
