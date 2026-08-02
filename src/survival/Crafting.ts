import recipes from '../data/recipes.json';
import { add, count, hasRoomFor, remove, type Slots } from './Inventory';

/**
 * Recipe resolution. Pure and engine-free.
 *
 * `canCraft` reports WHY something cannot be crafted rather than just that it
 * cannot. The crafting panel shows the missing pieces, and a UI that can only
 * say "no" makes players guess.
 */

export interface Ingredient {
  id: string;
  n: number;
}

export interface Recipe {
  output: Ingredient;
  cost: Ingredient[];
  /** Station id required, or null for hand-crafting anywhere. */
  station: string | null;
  /** Tier-2 gate: the station must be under a roof. */
  roof?: boolean;
  /** Progress flag required, e.g. the Meadow Sigil for Truestone Orbs. */
  requiresFlag?: string;
}

export interface CraftContext {
  /** Station the player currently stands at, or null. */
  station: string | null;
  hasRoof: boolean;
  flags: readonly string[];
}

export type CraftBlock =
  | { reason: 'unknown-recipe' }
  | { reason: 'missing-ingredients'; missing: Ingredient[] }
  | { reason: 'wrong-station'; needs: string }
  | { reason: 'needs-roof' }
  | { reason: 'locked'; flag: string }
  | { reason: 'no-room' };

export type CraftCheck = { ok: true; recipe: Recipe } | { ok: false; block: CraftBlock };

const RECIPES = recipes as unknown as Record<string, Recipe>;

export function recipeIds(): string[] {
  return Object.keys(RECIPES).filter((k) => !k.startsWith('$'));
}

export function getRecipe(id: string): Recipe | undefined {
  if (id.startsWith('$')) return undefined;
  return RECIPES[id];
}

export function canCraft(slots: Slots, id: string, ctx: CraftContext): CraftCheck {
  const recipe = getRecipe(id);
  if (!recipe) return { ok: false, block: { reason: 'unknown-recipe' } };

  if (recipe.requiresFlag && !ctx.flags.includes(recipe.requiresFlag)) {
    return { ok: false, block: { reason: 'locked', flag: recipe.requiresFlag } };
  }

  // Station before ingredients: "you need a campfire" is more useful than
  // "you need 2 raw meat" when the player is standing in a field with meat.
  if (recipe.station !== null && ctx.station !== recipe.station) {
    return { ok: false, block: { reason: 'wrong-station', needs: recipe.station } };
  }
  if (recipe.roof && !ctx.hasRoof) {
    return { ok: false, block: { reason: 'needs-roof' } };
  }

  const missing: Ingredient[] = [];
  for (const need of recipe.cost) {
    const have = count(slots, need.id);
    if (have < need.n) missing.push({ id: need.id, n: need.n - have });
  }
  if (missing.length > 0) {
    return { ok: false, block: { reason: 'missing-ingredients', missing } };
  }

  // Checked before consuming anything, because a craft that eats the cost and
  // then cannot place the output has destroyed the player's materials.
  if (!hasRoomFor(slots, recipe.output.id, recipe.output.n)) {
    return { ok: false, block: { reason: 'no-room' } };
  }

  return { ok: true, recipe };
}

/**
 * Craft. All-or-nothing: on any failure the satchel is untouched.
 *
 * The room check happens inside `canCraft` before a single ingredient is
 * consumed. Consuming first and discovering afterwards that the output does
 * not fit is how players lose materials to a full bag.
 */
export function craft(slots: Slots, id: string, ctx: CraftContext): CraftCheck {
  const check = canCraft(slots, id, ctx);
  if (!check.ok) return check;

  for (const need of check.recipe.cost) {
    // Guaranteed by canCraft, but asserting here means a future refactor that
    // separates the two cannot silently half-consume a cost.
    if (!remove(slots, need.id, need.n)) {
      return { ok: false, block: { reason: 'missing-ingredients', missing: [need] } };
    }
  }

  const leftover = add(slots, check.recipe.output.id, check.recipe.output.n);
  if (leftover > 0) {
    // Should be unreachable given hasRoomFor. Loud rather than silent, because
    // the alternative is quietly deleting what the player just made.
    console.error(`[craft] ${id} produced ${leftover} items with nowhere to go`);
  }
  return check;
}

/** Everything craftable right now, for the panel's "available" section. */
export function availableRecipes(slots: Slots, ctx: CraftContext): string[] {
  return recipeIds().filter((id) => canCraft(slots, id, ctx).ok);
}
