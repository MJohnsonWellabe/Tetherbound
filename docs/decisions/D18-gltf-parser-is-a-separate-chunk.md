# D18. The glTF parser is a separate on-demand chunk

Kind: implementation

There are two engine facades, not one. `src/core/babylon.ts` holds the engine
symbols; `src/core/babylonLoaders.ts` holds the glTF loader and its extensions,
and is reached only through a dynamic import inside `AssetLoader.ts`.

Measured: folding the loaders into the main facade grew the engine chunk from
1.56 MB raw / 359 KB gzipped to 2.51 MB / 566 KB. That is 207 KB gzipped of
parser on the boot path for something no milestone before M5 touches, because
`ASSETS.md` puts every real model behind M5 and everything before it is colored
primitives.

`tests/bundle.test.ts` enforces both halves: no file outside the two facades may
import `@babylonjs`, and no file may import `babylonLoaders` statically, since a
static import would quietly pull the parser back into the boot chunk.
