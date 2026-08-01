# D12. `worldDeltas.harvested` is a map, not an array

Kind: implementation

`ARCHITECTURE.md` types it `string[]`. Changed to `Record<string, number>`
mapping node key to the in-game day it was harvested.

Nodes respawn after 2 in-game days, so an array records every node ever
harvested for the life of the save and never shrinks. The map lets entries
older than the respawn window be pruned on serialize, which bounds the field
instead of letting a long save eventually trip the payload size guard.
