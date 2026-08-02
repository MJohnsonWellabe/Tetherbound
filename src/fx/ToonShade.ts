import { Material, MaterialPluginBase } from '../core/babylon';
import lighting from '../data/lighting.json';

/**
 * Toon shading for pals, NPCs and the player rig (ASSETS.md D24: "Palworld
 * and Pokemon on Switch", not photoreal PBR response).
 *
 * The glTF loader (src/core/babylonLoaders.ts) hands every rigged model a
 * PBRMaterial, so this hooks PBRMaterial's fragment shader through the
 * MaterialPluginBase API instead of writing a whole replacement shader:
 * one injected helper function plus one injected block at the
 * CUSTOM_FRAGMENT_BEFORE_FOG point PBRMaterial already exposes for exactly
 * this kind of post-lighting recolor (see pbrBlockFinalColorComposition in
 * @babylonjs/core/Shaders/ShadersInclude).
 *
 * At that point `diffuseBase` (the accumulated N-dot-L * shadow * light
 * color term, summed across every light and already shadow-attenuated) and
 * `finalColor` (the fully composited pre-fog pixel) are both still in scope
 * as ordinary local GLSL variables, because the marker sits later in the
 * same function body. The plugin takes diffuseBase's luminance, quantizes it
 * into a few discrete bands with a soft edge, and rescales finalColor by the
 * quantized-over-raw ratio. That bands the lit brightness of a pixel while
 * leaving its hue, its texture/vertex-color tint, and the shadow term
 * (already folded into diffuseBase before this ever runs) untouched.
 */

interface ToonConfig {
  enabled: boolean;
  bands: number;
  edgeSoftness: number;
  rimStrength: number;
  rimPower: number;
}

/** src/data/lighting.json is game-facing tuning; this file owns no numbers. */
const RAW = (lighting as { toon?: Partial<ToonConfig> }).toon ?? {};

/** Clamp bad or missing data to something that still compiles and renders. */
function config(): ToonConfig {
  return {
    enabled: RAW.enabled ?? true,
    bands: Math.max(1, Math.round(RAW.bands ?? 3)),
    // 0.5 would touch the neighbouring band's own transition; keep it short of that.
    edgeSoftness: Math.min(0.49, Math.max(0, RAW.edgeSoftness ?? 0.12)),
    rimStrength: Math.max(0, RAW.rimStrength ?? 0.06),
    rimPower: Math.max(0.01, RAW.rimPower ?? 2.5)
  };
}

/**
 * `?toon=0` forces the effect off and `?toon=1` forces it on, for an
 * apples-to-apples comparison against the same build without a rebuild.
 * Mirrors the `?stats=1` pattern in src/core/Stats.ts.
 */
function resolveEnabled(cfg: ToonConfig, search: string): boolean {
  const forced = new URLSearchParams(search).get('toon');
  if (forced === '0') return false;
  if (forced === '1') return true;
  return cfg.enabled;
}

const CFG = config();

/** Decided once at module load; every mount call in a session agrees. */
export const TOON_SHADING_ENABLED: boolean = resolveEnabled(
  CFG,
  typeof location === 'undefined' ? '' : location.search
);

const PLUGIN_NAME = 'ToonShade';

class ToonShadePlugin extends MaterialPluginBase {
  constructor(material: Material, cfg: ToonConfig) {
    // addToPluginList=true, enable=true: MaterialPluginBase defaults `enable`
    // to false (it exists for plugins toggled after construction), and a
    // plugin that never activates never runs its shader code.
    super(material, PLUGIN_NAME, 200, undefined, true, true);
    this.bands = cfg.bands;
    this.edgeSoftness = cfg.edgeSoftness;
    this.rimStrength = cfg.rimStrength;
    this.rimPower = cfg.rimPower;
  }

  private readonly bands: number;
  private readonly edgeSoftness: number;
  private readonly rimStrength: number;
  private readonly rimPower: number;

  override getClassName(): string {
    return 'ToonShadePlugin';
  }

  override getCustomCode(shaderType: string): Record<string, string> | null {
    if (shaderType !== 'fragment') return null;

    const bands = this.bands.toFixed(1);
    const softness = this.edgeSoftness.toFixed(4);
    const rimStrength = this.rimStrength.toFixed(4);
    const rimPower = this.rimPower.toFixed(2);

    return {
      // A named helper, not inlined, so the before-fog block stays one clear
      // read: quantize, rescale, lift the rim.
      CUSTOM_FRAGMENT_DEFINITIONS: `
float tbShadeBand(float x) {
  float bands = ${bands};
  float lo = floor(x * bands);
  float hi = lo + 1.0;
  // A hard floor() here is what makes a cel-shaded edge crawl and alias
  // frame to frame as the sun moves or the creature turns; smoothstep across
  // a narrow window keeps the step but lets it settle instead of shimmer.
  float t = smoothstep(0.5 - ${softness}, 0.5 + ${softness}, fract(x * bands));
  return mix(lo, hi, t) / bands;
}`,
      // finalColor and diffuseBase are locals already alive in this scope;
      // see the class doc comment for exactly where and why.
      CUSTOM_FRAGMENT_BEFORE_FOG: `
{
  float tbLum = dot(diffuseBase, vec3(0.299, 0.587, 0.114));
  float tbBanded = tbShadeBand(tbLum);
  // Rescale rather than replace: this keeps diffuseBase's own hue (colored
  // lights, warm/cool time-of-day tint) instead of flattening it to grey.
  float tbScale = tbLum > 0.0005 ? tbBanded / tbLum : 1.0;
  finalColor.rgb *= tbScale;
  // Cheap fresnel rim so a creature's silhouette lifts off a same-toned
  // background; understated on purpose (ASSETS.md: outline/rim is optional
  // and only if it stays inexpensive).
  float tbRim = pow(1.0 - clamp(dot(normalW, viewDirectionW), 0.0, 1.0), ${rimPower});
  finalColor.rgb += tbRim * ${rimStrength};
}`
    };
  }
}

/**
 * Apply toon shading to `material` if the config/URL says to, and if it
 * is not already applied. Safe to call more than once on the same shared
 * material (species share one material across every individual pal), and a
 * no-op when the effect is off, so callers never need to check first.
 */
export function applyToonShading(material: Material): void {
  if (!TOON_SHADING_ENABLED) return;
  if (material.pluginManager?.getPlugin(PLUGIN_NAME)) return;
  new ToonShadePlugin(material, CFG);
}
