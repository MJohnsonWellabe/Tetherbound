# D19. Scatter uses a global jittered grid, not per-chunk Poisson-disk

Kind: implementation

`ARCHITECTURE.md` asks for "Poisson-disk scatter ... from a deterministic
per-chunk RNG". Implemented as a global jittered grid with priority-based
suppression instead, which satisfies the intent and fixes a flaw in the letter
of it.

Running Bridson's algorithm inside each chunk spaces samples only against
others in the same chunk, so props clump along every chunk seam. Worse, the
result depends on which chunks happen to be resident, so walking away and back
regenerates a different layout, and a save that recorded "harvested node #7"
would point at a different bush.

Instead every cell of a global grid derives one candidate and one priority from
`hash(seed, cellX, cellZ)`, and a candidate survives if no higher-priority
candidate within `minDistance` exists nearby. Because acceptance compares
against a fixed neighbourhood using a deterministic priority, it is
order-independent: a cell resolves identically whether evaluated first, last,
or in a chunk loaded alone. Chunk seams stop existing as a concept, and every
point carries a stable key that `worldDeltas` can reference across sessions.

`tests/scatter.test.ts` asserts the property directly: sampling a region whole
equals sampling it in quarters, and equals sampling it on a different grid
offset.
