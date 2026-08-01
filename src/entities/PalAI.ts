import combat from '../data/combat.json';
import spawns from '../data/spawns.json';

/**
 * The wild pal state machine: wander, graze, flee, aggro.
 *
 * Pure and engine-free, operating on a plain struct, so the whole behaviour set
 * is testable without a scene. SpawnManager owns the structs and the meshes;
 * this file only decides where a pal wants to be next.
 *
 * The rule that shapes all four states: a pal roams around where it spawned
 * rather than drifting across the world. A player who backs off from a fight
 * and comes back should find the same Grazehorn in roughly the same field, or
 * the world stops feeling like a place.
 */

const AI = spawns.ai;

export type AiMode = 'wander' | 'graze' | 'flee' | 'aggro';

export interface WildMotion {
  x: number;
  y: number;
  z: number;
  yaw: number;
  /** Where this pal spawned. It roams around here, not away from here. */
  homeX: number;
  homeZ: number;
  mode: AiMode;
  timerMs: number;
  targetX: number;
  targetZ: number;
  /** Whether it actually moved this step, for the bob animation. */
  moving: boolean;
}

export interface AiTraits {
  aggressive: boolean;
  skittish: boolean;
}

export interface AiContext {
  playerX: number;
  playerZ: number;
  dtMs: number;
  heightAt: (x: number, z: number) => number;
  rng: () => number;
}

export function createMotion(x: number, y: number, z: number, yaw: number): WildMotion {
  return {
    x,
    y,
    z,
    yaw,
    homeX: x,
    homeZ: z,
    mode: 'graze',
    timerMs: 0,
    targetX: x,
    targetZ: z,
    moving: false
  };
}

function pickRoamTarget(m: WildMotion, rng: () => number): void {
  const angle = rng() * Math.PI * 2;
  const radius = rng() * AI.roamRadius;
  m.targetX = m.homeX + Math.cos(angle) * radius;
  m.targetZ = m.homeZ + Math.sin(angle) * radius;
}

/** Shortest-path angle step, so a pal never turns the long way round. */
function turnToward(current: number, target: number, maxStep: number): number {
  let diff = ((target - current + Math.PI) % (Math.PI * 2)) - Math.PI;
  if (diff < -Math.PI) diff += Math.PI * 2;
  return current + Math.max(-maxStep, Math.min(maxStep, diff));
}

/**
 * Advance one pal by one step.
 *
 * `hpFraction` drives the flee state: anything hurt runs, and skittish species
 * run from the player's approach alone. Aggression is checked before fear so a
 * wounded Ashmane still breaks off rather than charging to its death, which is
 * the behaviour that makes a rare spawn escapable instead of a guaranteed
 * fight the player did not choose.
 */
export function stepMotion(
  m: WildMotion,
  traits: AiTraits,
  hpFraction: number,
  ctx: AiContext
): void {
  const dt = ctx.dtMs / 1000;
  const toPlayerX = ctx.playerX - m.x;
  const toPlayerZ = ctx.playerZ - m.z;
  const playerDistance = Math.hypot(toPlayerX, toPlayerZ);

  m.timerMs -= ctx.dtMs;

  const hurt = hpFraction <= combat.flee.hpFraction;
  const crowded = traits.skittish && playerDistance < AI.skittishRange;

  if (hurt || crowded) {
    m.mode = 'flee';
  } else if (m.mode === 'flee' && playerDistance > AI.fleeUntilDistance) {
    m.mode = 'graze';
    m.timerMs = AI.grazeMsMin;
  } else if (traits.aggressive && playerDistance < combat.encounter.aggroRange) {
    m.mode = 'aggro';
  } else if (m.mode === 'aggro' && playerDistance >= combat.encounter.aggroRange) {
    m.mode = 'wander';
    m.timerMs = 0;
  }

  let speed = 0;
  let desiredX = m.x;
  let desiredZ = m.z;

  switch (m.mode) {
    case 'flee': {
      speed = AI.fleeSpeed;
      // Directly away. A clever escape arc would only make it harder to read
      // what the pal is doing at phone size.
      const len = playerDistance || 1;
      desiredX = m.x - (toPlayerX / len) * 10;
      desiredZ = m.z - (toPlayerZ / len) * 10;
      break;
    }
    case 'aggro': {
      speed = AI.aggroSpeed;
      desiredX = ctx.playerX;
      desiredZ = ctx.playerZ;
      break;
    }
    case 'graze': {
      if (m.timerMs <= 0) {
        m.mode = 'wander';
        m.timerMs = AI.wanderMsMax;
        pickRoamTarget(m, ctx.rng);
      }
      break;
    }
    case 'wander': {
      speed = AI.wanderSpeed;
      desiredX = m.targetX;
      desiredZ = m.targetZ;
      const arrived = Math.hypot(m.targetX - m.x, m.targetZ - m.z) < AI.arriveDistance;
      if (arrived || m.timerMs <= 0) {
        m.mode = 'graze';
        m.timerMs = AI.grazeMsMin + ctx.rng() * (AI.grazeMsMax - AI.grazeMsMin);
        speed = 0;
      }
      break;
    }
  }

  if (speed <= 0) {
    m.moving = false;
    m.y = ctx.heightAt(m.x, m.z);
    return;
  }

  const dx = desiredX - m.x;
  const dz = desiredZ - m.z;
  const distance = Math.hypot(dx, dz);
  if (distance < 1e-4) {
    m.moving = false;
    return;
  }

  const stepDistance = Math.min(speed * dt, distance);
  m.x += (dx / distance) * stepDistance;
  m.z += (dz / distance) * stepDistance;
  m.y = ctx.heightAt(m.x, m.z);
  m.yaw = turnToward(m.yaw, Math.atan2(dx, dz), AI.turnRate * dt);
  m.moving = true;
}

/** True when this pal is close enough to start a fight by walking into it. */
export function withinEncounterRange(m: WildMotion, playerX: number, playerZ: number): boolean {
  return Math.hypot(playerX - m.x, playerZ - m.z) <= combat.encounter.triggerRange;
}

/** Aggressive species start the fight themselves from further out. */
export function wantsToEngage(
  m: WildMotion,
  traits: AiTraits,
  playerX: number,
  playerZ: number
): boolean {
  if (m.mode === 'flee') return false;
  const distance = Math.hypot(playerX - m.x, playerZ - m.z);
  if (distance <= combat.encounter.triggerRange) return true;
  return traits.aggressive && distance <= combat.encounter.aggroRange;
}

export const AI_CONFIG = AI;
