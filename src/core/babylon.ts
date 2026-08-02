/**
 * THE ONLY FILE ALLOWED TO IMPORT FROM @babylonjs.
 *
 * `import { Mesh } from '@babylonjs/core'` reads nicely and costs a fortune:
 * the barrel is a side-effecting module graph that pulls the entire engine in
 * whether you touch it or not. Measured on the sibling GolfModel project, the
 * barrel produced a 6.75 MB raw / 1.48 MB gzipped vendor chunk for a game that
 * used 33 symbols; deep imports cut it to 682 KB gzipped. That is most of
 * ARCHITECTURE.md's entire 8 MB first-load budget, recovered by an import
 * style.
 *
 * So: every Babylon symbol the game uses is deep-imported here exactly once
 * and re-exported. `tests/bundle.test.ts` fails the build if any other file
 * under src/, or any HTML entry point, imports '@babylonjs/...' directly.
 *
 * Adding a symbol is a deliberate act. Import the narrowest path that provides
 * it, never the barrel, and never `Meshes/meshBuilder` (which registers every
 * builder including greased lines and Goldberg polyhedra).
 *
 * Side-effect imports at the bottom register optional engine capabilities.
 * They have no exports and must not be removed as "unused".
 */

// --- engine and scene ------------------------------------------------------
export { Engine } from '@babylonjs/core/Engines/engine';
export { Scene } from '@babylonjs/core/scene';
export { EngineStore } from '@babylonjs/core/Engines/engineStore';

// --- math ------------------------------------------------------------------
export { Vector2, Vector3, Quaternion, Matrix } from '@babylonjs/core/Maths/math.vector';
export { Color3, Color4 } from '@babylonjs/core/Maths/math.color';
export { Scalar } from '@babylonjs/core/Maths/math.scalar';
// Vector3.Project needs one of these to map a world point to a pixel. The
// floating damage numbers are DOM nodes, so they need that mapping every frame.
export { Viewport } from '@babylonjs/core/Maths/math.viewport';

// --- scene graph -----------------------------------------------------------
export { Node } from '@babylonjs/core/node';
export { TransformNode } from '@babylonjs/core/Meshes/transformNode';
export { AbstractMesh } from '@babylonjs/core/Meshes/abstractMesh';
export { Mesh } from '@babylonjs/core/Meshes/mesh';
export { VertexData } from '@babylonjs/core/Meshes/mesh.vertexData';
export { VertexBuffer } from '@babylonjs/core/Buffers/buffer';

// --- geometry builders -----------------------------------------------------
// Individually imported. `Meshes/meshBuilder` registers all ~20 builders.
export { CreateGround, CreateGroundFromHeightMap } from '@babylonjs/core/Meshes/Builders/groundBuilder';
export { CreateBox } from '@babylonjs/core/Meshes/Builders/boxBuilder';
export { CreateSphere } from '@babylonjs/core/Meshes/Builders/sphereBuilder';
export { CreateCylinder } from '@babylonjs/core/Meshes/Builders/cylinderBuilder';
export { CreateCapsule } from '@babylonjs/core/Meshes/Builders/capsuleBuilder';
export { CreatePlane } from '@babylonjs/core/Meshes/Builders/planeBuilder';
export { CreateLines } from '@babylonjs/core/Meshes/Builders/linesBuilder';
export { CreateTorus } from '@babylonjs/core/Meshes/Builders/torusBuilder';

// --- materials and textures ------------------------------------------------
export { Material } from '@babylonjs/core/Materials/material';
export { StandardMaterial } from '@babylonjs/core/Materials/standardMaterial';
export { Texture } from '@babylonjs/core/Materials/Textures/texture';
export { DynamicTexture } from '@babylonjs/core/Materials/Textures/dynamicTexture';
// The toon-shading plugin (src/fx/ToonShade.ts) hooks the lit-material
// fragment shader through the plugin API rather than writing a whole custom
// shader.
export { MaterialPluginBase } from '@babylonjs/core/Materials/materialPluginBase';

// --- lights and shadows ----------------------------------------------------
export { DirectionalLight } from '@babylonjs/core/Lights/directionalLight';
export { HemisphericLight } from '@babylonjs/core/Lights/hemisphericLight';
export { ShadowGenerator } from '@babylonjs/core/Lights/Shadows/shadowGenerator';

// --- cameras ---------------------------------------------------------------
export { FreeCamera } from '@babylonjs/core/Cameras/freeCamera';

// --- particles -------------------------------------------------------------
// The CPU particle system, not the GPU one. GPU particles need a WebGL2 compute
// path and a fallback for devices without it, which is two code paths and a
// vertex-buffer upload for bursts of a dozen chips. See src/fx/Particles.ts.
export { ParticleSystem } from '@babylonjs/core/Particles/particleSystem';

// --- picking and culling ---------------------------------------------------
export { Ray } from '@babylonjs/core/Culling/ray';
export { BoundingInfo } from '@babylonjs/core/Culling/boundingInfo';

// --- misc ------------------------------------------------------------------
export { Observable } from '@babylonjs/core/Misc/observable';
export type { Observer } from '@babylonjs/core/Misc/observable';
export type { Nullable } from '@babylonjs/core/types';
export { Tools } from '@babylonjs/core/Misc/tools';
export { AssetContainer } from '@babylonjs/core/assetContainer';
// Skeletal animation playback for the rigged creatures and characters.
export { AnimationGroup } from '@babylonjs/core/Animations/animationGroup';
export { Skeleton } from '@babylonjs/core/Bones/skeleton';
export { SceneInstrumentation } from '@babylonjs/core/Instrumentation/sceneInstrumentation';

// --- side-effect registrations ---------------------------------------------
// Thin instances are how every scatter prop renders (see world/Scatter.ts).
// The methods are patched onto Mesh.prototype by this module.
import '@babylonjs/core/Meshes/thinInstanceMesh';
// Shadow support needs the material defines injected.
import '@babylonjs/core/Lights/Shadows/shadowGeneratorSceneComponent';
// getEngine().getGlInfo() and friends, used by the ?stats=1 overlay.
import '@babylonjs/core/Engines/Extensions/engine.query';

// glTF loading is deliberately NOT here. See src/core/babylonLoaders.ts.
