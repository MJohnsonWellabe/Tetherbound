# D15. The save payload is one opaque compressed string

Kind: implementation

The checkpoint document carries a single gzip plus base64 string rather than
mirroring `SaveV1` field by field.

Four reasons: the round trip is byte-identical with no SDK type coercion; one
codec serves localStorage, the cloud and the section 12 export string, so the
required round-trip test covers all three at once; a 30 KB string does not
generate index entries on every write; and the compression puts the 1 MiB
ceiling out of reach.

Accepted limit: the rules cannot inspect a compressed payload, so a hand-built
document could claim a party of 5 in its header and hold 6 in the blob. That is
acceptable in a single-player game with no leaderboard and no economy, and
`parseSave()` clamps to 5 on every load path regardless. `Party.add()` remains
the sole enforcement point per `CLAUDE.md`; the rules and the parser are
rejection points for corrupt data, not a second enforcement path.
