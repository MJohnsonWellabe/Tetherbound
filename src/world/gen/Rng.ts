/**
 * Deterministic pseudo-random numbers for world generation.
 *
 * CLAUDE.md hard constraint 6: no `Math.random()` in world generation, seeded
 * RNG only. The reason is not purity for its own sake. A save file stores the
 * seed plus deltas, not the terrain, so the same seed has to rebuild the same
 * world on every device forever. It also makes a bug report reproducible from
 * one string, and lets players share seeds.
 *
 * Pure, engine-free, and heavily tested, because a subtle non-determinism here
 * surfaces as "my house is inside a hill now" three milestones later.
 */

/**
 * FNV-1a over a string, mixed with any number of integer coordinates.
 *
 * The integers are folded in with distinct odd multipliers so that (2, 3) and
 * (3, 2) do not collide. A symmetric hash would mirror the whole world across
 * the diagonal, which looks convincing enough at a glance to survive review.
 */
export function hashSeed(worldSeed: string, ...coords: number[]): number {
  let h = 0x811c9dc5;
  for (let i = 0; i < worldSeed.length; i++) {
    h ^= worldSeed.charCodeAt(i);
    h = Math.imul(h, 0x01000193);
  }
  for (let i = 0; i < coords.length; i++) {
    // `| 0` first: a fractional coordinate would make the hash depend on float
    // representation, which is exactly the kind of thing that differs between
    // a phone and a laptop.
    let c = (coords[i] ?? 0) | 0;
    // Spread the low bits of small coordinates before mixing, or chunk (0,1)
    // and (1,0) end up suspiciously similar.
    c = Math.imul(c ^ (c >>> 16), 0x45d9f3b);
    h ^= c + 0x9e3779b9 + (i + 1) * 0x85ebca6b;
    h = Math.imul(h, 0x01000193);
  }
  return h >>> 0;
}

/**
 * mulberry32. Small, fast, and good enough for scatter and spawn decisions.
 * Not cryptographic, and not trying to be.
 */
export function mulberry32(seed: number): () => number {
  let a = seed >>> 0;
  return function next(): number {
    a = (a + 0x6d2b79f5) >>> 0;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

/**
 * The per-chunk generator. Every placement decision inside a chunk derives
 * from this, so a chunk generates identically whether it is the first one
 * streamed in or the fiftieth, and regardless of what the player did meanwhile.
 */
export function chunkRng(worldSeed: string, chunkX: number, chunkZ: number): () => number {
  return mulberry32(hashSeed(worldSeed, chunkX, chunkZ));
}

/** A named sub-stream, so adding a new pass does not shift existing output. */
export function subRng(worldSeed: string, label: string, ...coords: number[]): () => number {
  return mulberry32(hashSeed(`${worldSeed}:${label}`, ...coords));
}

/** Uniform float in [min, max). */
export function range(rng: () => number, min: number, max: number): number {
  return min + rng() * (max - min);
}

/** Uniform integer in [min, max], inclusive at both ends. */
export function rangeInt(rng: () => number, min: number, max: number): number {
  return Math.floor(min + rng() * (max - min + 1));
}

/** Pick one element. Returns undefined only for an empty list. */
export function pick<T>(rng: () => number, items: readonly T[]): T | undefined {
  if (items.length === 0) return undefined;
  return items[Math.floor(rng() * items.length)];
}

/**
 * Pick by weight. Weights need not sum to 1. Non-positive weights are skipped
 * so a species with weight 0 is genuinely never chosen rather than rare.
 */
export function pickWeighted<T>(
  rng: () => number,
  items: readonly T[],
  weightOf: (item: T) => number
): T | undefined {
  let total = 0;
  for (const item of items) {
    const w = weightOf(item);
    if (w > 0) total += w;
  }
  if (total <= 0) return undefined;

  let roll = rng() * total;
  for (const item of items) {
    const w = weightOf(item);
    if (w <= 0) continue;
    roll -= w;
    if (roll <= 0) return item;
  }
  // Floating point can leave a sliver. Fall back to the last positive weight.
  for (let i = items.length - 1; i >= 0; i--) {
    const item = items[i];
    if (item !== undefined && weightOf(item) > 0) return item;
  }
  return undefined;
}
