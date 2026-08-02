import { AssetContainer, Scene } from './babylon';

/**
 * The glTF parser is fetched on first use, not at boot. Memoized so a burst of
 * concurrent loads triggers one chunk download rather than one per model.
 */
let loaderModule: Promise<typeof import('./babylonLoaders')> | null = null;
function ensureLoaders(): Promise<typeof import('./babylonLoaders')> {
  if (!loaderModule) loaderModule = import('./babylonLoaders');
  return loaderModule;
}

/**
 * glTF loading with a per-scene cache.
 *
 * Two failure modes this exists to prevent, both of which the sibling
 * GolfModel project shipped and had to fix:
 *
 * 1. A load that resolves after its scene was disposed. The container gets
 *    attached to a dead scene, its meshes never render, and nothing errors.
 *    Guarded by checking `scene.isDisposed` on resolve and throwing
 *    SceneGoneError, which callers treat as "abandon quietly" rather than
 *    "something is broken".
 *
 * 2. A cached rejected promise. The obvious cache stores the promise and
 *    returns it forever, so one failed fetch on a flaky connection pins that
 *    model as broken for the rest of the session with no way to retry. Every
 *    rejection is evicted so the next request actually re-fetches.
 *
 * The cache is a WeakMap keyed on Scene, so a disposed scene takes its cache
 * with it instead of holding containers alive.
 */

export class SceneGoneError extends Error {
  constructor(url: string) {
    super(`Scene was disposed while loading ${url}`);
    this.name = 'SceneGoneError';
  }
}

export class AssetTimeoutError extends Error {
  constructor(url: string, ms: number) {
    super(`Timed out after ${ms}ms loading ${url}`);
    this.name = 'AssetTimeoutError';
  }
}

/** A model that never arrives must not hold the boot sequence open forever. */
const DEFAULT_TIMEOUT_MS = 15_000;

const caches = new WeakMap<Scene, Map<string, Promise<AssetContainer>>>();

function cacheFor(scene: Scene): Map<string, Promise<AssetContainer>> {
  let cache = caches.get(scene);
  if (!cache) {
    cache = new Map();
    caches.set(scene, cache);
  }
  return cache;
}

function withTimeout<T>(promise: Promise<T>, ms: number, url: string): Promise<T> {
  return new Promise<T>((resolve, reject) => {
    const timer = setTimeout(() => reject(new AssetTimeoutError(url, ms)), ms);
    promise.then(
      (value) => {
        clearTimeout(timer);
        resolve(value);
      },
      (err: unknown) => {
        clearTimeout(timer);
        reject(err instanceof Error ? err : new Error(String(err)));
      }
    );
  });
}

/**
 * Load a glTF/glb into an AssetContainer, cached per scene.
 *
 * The container is NOT added to the scene. Callers instantiate from it, which
 * is what lets one download back many placed copies.
 */
export function loadContainer(
  scene: Scene,
  url: string,
  timeoutMs = DEFAULT_TIMEOUT_MS
): Promise<AssetContainer> {
  const cache = cacheFor(scene);
  const hit = cache.get(url);
  if (hit) return hit;

  const load = ensureLoaders().then(({ LoadAssetContainerAsync }) =>
    LoadAssetContainerAsync(url, scene)
  );

  const pending = withTimeout(load, timeoutMs, url).then((container) => {
    if (scene.isDisposed) {
      // Nothing will ever render this. Release the GPU resources rather than
      // leaving them attached to a dead scene.
      container.dispose();
      throw new SceneGoneError(url);
    }
    return container;
  });

  // Evict on rejection so a retry can actually re-fetch. Caching the failure
  // is what pins a model as permanently broken after one bad connection.
  pending.catch(() => {
    if (cache.get(url) === pending) cache.delete(url);
  });

  cache.set(url, pending);
  return pending;
}

/**
 * Load a model bypassing the cache: a container the caller OWNS outright.
 *
 * For rigged entities. `instantiateModelsToScene` on a shared container
 * mis-maps bone indices for files with multiple skins or bone/joint count
 * mismatches, and a handful of stretched triangles turns a bird into a
 * screen-filling shard (D56). A fresh parse per entity is exactly what the
 * pack authors' own viewers do; the browser HTTP cache still makes the
 * download itself free after the first fetch.
 */
export function loadContainerOwned(
  scene: Scene,
  url: string,
  timeoutMs = DEFAULT_TIMEOUT_MS
): Promise<AssetContainer> {
  const load = ensureLoaders().then(({ LoadAssetContainerAsync }) =>
    LoadAssetContainerAsync(url, scene)
  );
  return withTimeout(load, timeoutMs, url).then((container) => {
    if (scene.isDisposed) {
      container.dispose();
      throw new SceneGoneError(url);
    }
    return container;
  });
}

/**
 * Load several models, reporting progress. A single failure does not fail the
 * batch: a missing prop should degrade the scene, not refuse to start the game.
 * Rejected entries come back as null and are logged.
 */
export async function loadAll(
  scene: Scene,
  urls: readonly string[],
  onProgress?: (done: number, total: number) => void
): Promise<Map<string, AssetContainer | null>> {
  const out = new Map<string, AssetContainer | null>();
  let done = 0;
  await Promise.all(
    urls.map(async (url) => {
      try {
        out.set(url, await loadContainer(scene, url));
      } catch (err) {
        if (!(err instanceof SceneGoneError)) {
          console.warn(`[assets] failed to load ${url}:`, err);
        }
        out.set(url, null);
      } finally {
        done++;
        onProgress?.(done, urls.length);
      }
    })
  );
  return out;
}

/** Drop a scene's cache and dispose everything it holds. */
export function disposeCache(scene: Scene): void {
  const cache = caches.get(scene);
  if (!cache) return;
  for (const pending of cache.values()) {
    // Containers still in flight dispose when they land and find the scene
    // gone; the catch keeps an unhandled rejection off the console.
    pending.then(
      (c) => c.dispose(),
      () => undefined
    );
  }
  cache.clear();
  caches.delete(scene);
}

/** Cached entry count, for the disposal soak test. */
export function cacheSize(scene: Scene): number {
  return caches.get(scene)?.size ?? 0;
}
