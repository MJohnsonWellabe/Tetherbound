# D09. Firestore runs with `memoryLocalCache`

Kind: implementation

Firestore's persistent cache resolves `setDoc()` locally while offline. With it
enabled, the bed ceremony would print "Saved to your account" for a write
sitting in a queue that may never land.

Offline coverage comes from the local checkpoint mirror instead. A failed write
is reported as a failed write. A save layer that lies about durability is worse
than one that has none.
