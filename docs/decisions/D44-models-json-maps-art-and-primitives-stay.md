# D44. `models.json` maps every visible thing, and the primitives never leave

Kind: implementation

`src/data/models.json` is the single mapping from a visible thing to the GLB
that draws it and the scale it draws at: props, buildings, stations, characters
and pals. The primitive builders that drew all of those before M5 stay in the
codebase permanently as the per-slot fallback.

Two rules follow from the fallback being per slot rather than global.

**A failed download costs one thing its silhouette, never the boot.**
`AssetLoader.loadAll` degrades per url to null, and each consumer falls back to
its own primitive for that entry alone. One dead url means one family of trees
is cylinders again. Every url dead means the game that shipped at M4, which is
a playable game.

**Nothing waits on the network to become interactive.** Buildings, stations,
characters and pals build their colliders, anchors and placeholder geometry
synchronously and swap the model in when it lands. Boot awaits only the prop
prototypes, because those feed the first built chunks and bare terrain reads as
loading while a hole reads as broken.

Scales live here and are baked at load time, so retuning a silhouette is an
edit to this file rather than a pipeline run. The pals section additionally
carries a `clips` map from game verb to the exact AnimationGroup name inside
each GLB (D45).

The temptation is to delete the primitive builders once the models are in.
Resist it. They are the reason a bad deploy, an expired asset host or a
corrupted file degrades the game instead of ending it, and they cost nothing:
disabled prototype meshes and a handful of unreached branches.
