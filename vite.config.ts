import { defineConfig } from 'vite';

/**
 * `base: './'` rather than `/<repo-name>/`.
 *
 * ARCHITECTURE.md calls for the repo-name path because GitHub Pages serves a
 * project site from a subpath. Relative URLs satisfy that without hard-coding
 * the repo name, and they also survive `vite preview`, a custom domain, and
 * the LAN URL a phone hits during `npm run dev --host`. One less thing to get
 * wrong on a rename.
 */
export default defineConfig({
  base: './',
  server: {
    host: true,
    port: 5173
  },
  build: {
    target: 'es2022',
    // The perf budget in ARCHITECTURE.md is "initial bundle + first chunk
    // < 8 MB". Splitting the two vendors into their own stable-hash chunks
    // means a gameplay-only deploy does not force phones to re-download the
    // engine, and the Firebase chunk stays reachable only through the dynamic
    // imports in src/cloud/, so it never loads for a local-only player.
    rollupOptions: {
      output: {
        manualChunks(id: string): string | undefined {
          if (id.includes('node_modules/@babylonjs/')) return 'babylon';
          if (id.includes('node_modules/firebase/') || id.includes('node_modules/@firebase/')) {
            return 'firebase';
          }
          return undefined;
        }
      }
    },
    // The warning measures raw bytes, but the wire cost is gzip. The Babylon
    // chunk sits around 1.6 MB raw / 360 KB gzipped, which is inside budget.
    // Set the threshold where a real regression would trip it instead of
    // crying wolf on every build.
    chunkSizeWarningLimit: 1700
  },
  test: {
    include: ['tests/**/*.test.ts'],
    environment: 'node'
  }
});
