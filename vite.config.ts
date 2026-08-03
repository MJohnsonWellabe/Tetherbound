import { resolve } from 'node:path';
import { defineConfig } from 'vite';

/**
 * `base: './'` rather than `/<repo-name>/`.
 *
 * docs/03_TECHNICAL_ARCHITECTURE.md calls for the repo-name path because GitHub Pages serves a
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
    // The perf budget in docs/03_TECHNICAL_ARCHITECTURE.md is "initial bundle + first chunk
    // < 8 MB". Splitting the two vendors into their own stable-hash chunks
    // means a gameplay-only deploy does not force phones to re-download the
    // engine, and the Firebase chunk stays reachable only through the dynamic
    // imports in src/cloud/, so it never loads for a local-only player.
    rollupOptions: {
      // styleguide.html is a second entry: a living reference for the design
      // system, rendered from the same components.css the game ships. A style
      // guide maintained separately from the real stylesheet drifts within a
      // week and then actively misleads.
      input: {
        main: resolve(__dirname, 'index.html'),
        styleguide: resolve(__dirname, 'styleguide.html')
      },
      output: {
        manualChunks(id: string): string | undefined {
          // The glTF parser is 207 KB gzipped and nothing before M5 loads a
          // model, so it gets its own chunk reached only through the dynamic
          // import in AssetLoader.ts.
          if (id.includes('node_modules/@babylonjs/loaders/')) return 'babylon-gltf';
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
