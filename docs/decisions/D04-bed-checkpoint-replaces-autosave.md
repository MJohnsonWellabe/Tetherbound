# D04. Bed checkpoint replaces the 60 second autosave

Kind: spec-conflict

`GAME_DESIGN.md` section 12 specifies autosave every 60 seconds. Amended.

Sleeping in a bed is the canonical save and writes the cloud checkpoint with a
visible confirmation. A local autosave still runs on a 60 second timer plus
`visibilitychange` and `pagehide`, as a crash net only. It never uploads.

That is also the quota design, not only a design preference: a 60 second cloud
write at 1,000 players is roughly 30,000 writes per day, over the Spark free
tier. Bed checkpoints leave about 6,600 sleeps per day of headroom.

Fainting is unchanged and still follows `GAME_DESIGN.md` section 4 exactly:
respawn at the bed, inventory drops to the satchel, pals are never dropped,
world and party and XP stay live. A faint is not a rollback to the checkpoint
blob. The checkpoint protects against a closed tab or a lost device; the
satchel rule handles death.
