import type { SpeciesDef } from './Species';

/**
 * The wild pal state machine: wander, graze, flee, aggro.
 *
 * Pure. It takes a state plus what the pal can perceive and returns the next
 * state and a desired velocity; the entity applies it. That keeps the
 * behaviour testable without a scene and stops "how a pal decides" from
 * getting tangled up with "how a pal is drawn".
 */

export type PalMood = 'wander' | 'graze' | 'flee' | 'aggro';

export interface AiState {
  mood: PalMood;
  /** Seconds left before the current mood is reconsidered. */
  timer: number;
  /** Heading in radians, for wander and flee. */
  heading: number;
  /** Where it started, so it does not migrate across the world. */
  homeX: number;
  homeZ: number;
}

export interface Perception {
  distanceToPlayer: number;
  /** Bearing from the pal to the player, radians. */
  bearingToPlayer: number;
  distanceFromHome: number;
  headingHome: number;
}

export interface AiOutput {
  mood: PalMood;
  /** Desired speed as a fraction of the pal's own speed stat, 0 to 1. */
  throttle: number;
  heading: number;
}

/** Tuning that describes behaviour rather than balance. */
const WANDER_MIN_S = 2.5;
const WANDER_MAX_S = 6;
const GRAZE_MIN_S = 3;
const GRAZE_MAX_S = 7;
const FLEE_S = 3.5;
const LEASH_RADIUS = 34;
const DEFAULT_AGGRO_RANGE = 0;
/** Aggressive species notice you from here; everything else ignores you. */
const FLEE_RANGE = 9;

export function createAi(x: number, z: number, rand: () => number): AiState {
  return {
    mood: 'wander',
    timer: WANDER_MIN_S + rand() * (WANDER_MAX_S - WANDER_MIN_S),
    heading: rand() * Math.PI * 2,
    homeX: x,
    homeZ: z
  };
}

/**
 * Advance one step.
 *
 * Order of checks is the priority order: being dragged home beats reacting to
 * the player, and reacting to the player beats idling. A pal that wanders out
 * of its leash and then aggros would walk to the horizon.
 */
export function stepAi(
  state: AiState,
  def: SpeciesDef,
  perception: Perception,
  dt: number,
  rand: () => number,
  docile = false
): AiOutput {
  state.timer -= dt;

  // Leash first. Nothing else may override coming home.
  if (perception.distanceFromHome > LEASH_RADIUS) {
    state.mood = 'wander';
    state.heading = perception.headingHome;
    state.timer = Math.max(state.timer, 1);
    return { mood: 'wander', throttle: 0.6, heading: state.heading };
  }

  // A docile pal (the opening scene's scripted tuftmoth) is pinned to wander
  // and graze no matter what its species data says. Checked here rather than
  // by leaving aggroRange/flees off the species, because tuftmoth is also a
  // normal wild spawn everywhere else in the Meadows and this must not change
  // that pal's behaviour for anyone else.
  if (!docile) {
    const aggroRange = def.aggroRange ?? DEFAULT_AGGRO_RANGE;
    if (aggroRange > 0 && perception.distanceToPlayer <= aggroRange) {
      state.mood = 'aggro';
      state.heading = perception.bearingToPlayer;
      return { mood: 'aggro', throttle: 1, heading: state.heading };
    }

    // Skittish species bolt rather than stand there being approached.
    if (def.flees && perception.distanceToPlayer <= FLEE_RANGE) {
      state.mood = 'flee';
      state.timer = FLEE_S;
      state.heading = perception.bearingToPlayer + Math.PI;
      return { mood: 'flee', throttle: 1, heading: state.heading };
    }
  }

  if (state.timer > 0) {
    return {
      mood: state.mood,
      throttle: throttleFor(state.mood),
      heading: state.heading
    };
  }

  // Timer expired: pick something new.
  if (state.mood === 'graze') {
    state.mood = 'wander';
    state.timer = WANDER_MIN_S + rand() * (WANDER_MAX_S - WANDER_MIN_S);
    state.heading = rand() * Math.PI * 2;
  } else {
    state.mood = 'graze';
    state.timer = GRAZE_MIN_S + rand() * (GRAZE_MAX_S - GRAZE_MIN_S);
  }
  return { mood: state.mood, throttle: throttleFor(state.mood), heading: state.heading };
}

function throttleFor(mood: PalMood): number {
  if (mood === 'graze') return 0;
  if (mood === 'flee' || mood === 'aggro') return 1;
  return 0.45;
}
