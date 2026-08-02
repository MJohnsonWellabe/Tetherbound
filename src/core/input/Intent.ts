/**
 * The intent layer from ARCHITECTURE.md.
 *
 * Gameplay reads this and nothing else. It never sees a KeyboardEvent, a
 * PointerEvent, or a device capability check. Touch and desktop are two
 * writers into one struct, which is what keeps a feature from accidentally
 * becoming keyboard-only.
 *
 * Pure types and helpers, no DOM, so the combat and movement systems that
 * consume intent stay testable headless.
 */

export type DodgeDir = -1 | 0 | 1;
export type PartySlot = 1 | 2 | 3 | 4 | 5 | null;

/**
 * The dodge value for an input with no inherent left/right lean: the A
 * button and Space bar, a straight-back hop rather than a lunge either way.
 * `DodgeDir` has no fourth "directionless" value, and CombatMode only ever
 * checks `dodge !== 0` to open the dodge window (src/combat/CombatMode.ts);
 * direction only matters to the shoulder/A-D dodges and to BuildMode's reuse
 * of this field for rotation. So this picks 1, matching the single on-screen
 * dodge button in CombatScreen.ts, which has the same "one button, no
 * direction" shape and already settled on the same answer.
 */
export const NEUTRAL_DODGE: DodgeDir = 1;

export interface Intent {
  /** Desired movement in camera space. Each axis -1..1, magnitude clamped to 1. */
  move: { x: number; y: number };
  /** Look delta accumulated since the last frame, in radians. */
  look: { x: number; y: number };
  sprint: boolean;
  jump: boolean;
  interact: boolean;
  /**
   * The one combat verb. `heldMs` drives the power-attack charge, so it has to
   * survive across frames rather than being a per-frame edge.
   */
  primary: { down: boolean; heldMs: number };
  /** Edge-triggered. Set for exactly one frame when a dodge is committed. */
  dodge: DodgeDir;
  /** Edge-triggered. The party slot the player asked to swap to. */
  slot: PartySlot;
  /**
   * Edge-triggered. Throw an orb.
   *
   * Its own channel rather than a modifier on `primary`, because the throw is
   * always available from the first frame of a fight (CLAUDE.md hard constraint
   * 3) and must never queue behind an attack's charge.
   */
  throwOrb: boolean;
  /**
   * Edge-triggered. Open or close the pause menu.
   *
   * Reachable from exploring, dialogue and a fight alike, so nothing gates it
   * the way `interact` is gated by whichever system currently owns that
   * button. There is exactly one pause menu and it never has to compete.
   */
  pause: boolean;
}

/**
 * What the input layer should read the same gestures as.
 *
 * In `explore`, A/D strafe and a horizontal swipe rotates the camera. In
 * `combat`, the player never controls pal movement (GAME_DESIGN.md section 7),
 * so the same inputs mean dodge instead. One flag, set by CombatMode, rather
 * than every consumer branching on game state.
 */
export type InputMode = 'explore' | 'combat';

export function neutralIntent(): Intent {
  return {
    move: { x: 0, y: 0 },
    look: { x: 0, y: 0 },
    sprint: false,
    jump: false,
    interact: false,
    primary: { down: false, heldMs: 0 },
    dodge: 0,
    slot: null,
    throwOrb: false,
    pause: false
  };
}

/**
 * Clear the edge-triggered fields after a frame has consumed them.
 *
 * `jump`, `interact`, `dodge`, `slot`, `throwOrb` and `pause` are events, not
 * states. Leaving them set means one tap reads as a held button for as long
 * as the frame rate allows, which is how a single jump press becomes a hover.
 */
export function clearEdges(intent: Intent): void {
  intent.jump = false;
  intent.interact = false;
  intent.dodge = 0;
  intent.slot = null;
  intent.throwOrb = false;
  intent.pause = false;
  intent.look.x = 0;
  intent.look.y = 0;
}

/** Clamp a stick vector to the unit circle so diagonals are not faster. */
export function clampStick(x: number, y: number): { x: number; y: number } {
  const mag = Math.hypot(x, y);
  if (mag <= 1) return { x, y };
  return { x: x / mag, y: y / mag };
}

/**
 * Map raw stick displacement to movement, with a dead zone and a response
 * curve.
 *
 * The dead zone exists because a thumb resting on glass is never truly still,
 * and without it the player drifts while standing. Rescaling the remainder to
 * the full 0..1 range afterwards means the first pixel past the dead zone is
 * still a slow walk rather than a jump to 30% speed.
 */
export function applyDeadZone(x: number, y: number, deadZone: number): { x: number; y: number } {
  const mag = Math.hypot(x, y);
  if (mag < deadZone) return { x: 0, y: 0 };
  const scaled = Math.min((mag - deadZone) / (1 - deadZone), 1);
  return { x: (x / mag) * scaled, y: (y / mag) * scaled };
}
