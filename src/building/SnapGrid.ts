import pieces from '../data/pieces.json';

/**
 * Socket matching for the build grid.
 *
 * Pure. Given a desired position and the pieces already placed, it returns
 * where the piece actually goes and whether the placement is legal. The ghost
 * preview and the real placement both call this, which is what stops the
 * preview from lying about where a piece will land.
 *
 * No structural integrity in v0.1: GAME_DESIGN.md section 8 cuts it
 * deliberately, and DECISIONS.md records that the game is better for it.
 */

export interface PieceDef {
  name: string;
  tier: string;
  size: [number, number, number];
  cost: { id: string; n: number }[];
  sockets: string[];
  accepts: string[];
}

export interface PlacedPiece {
  pieceId: string;
  x: number;
  y: number;
  z: number;
  rot: number;
  /** Real ms at placement, for the refund grace period. */
  placedAtMs: number;
}

export interface SnapResult {
  x: number;
  y: number;
  z: number;
  rot: number;
  valid: boolean;
  /** Why it is invalid, for the ghost tint and the HUD. */
  reason?: 'no-support' | 'occupied' | 'too-steep';
}

const PIECES = pieces.pieces as unknown as Record<string, PieceDef | undefined>;

export function pieceDef(id: string): PieceDef | undefined {
  return PIECES[id];
}

export function pieceIds(): string[] {
  return Object.keys(PIECES);
}

/** Round to the build grid, so pieces line up without needing to be perfect. */
export function snapToGrid(value: number): number {
  return Math.round(value / pieces.gridSize) * pieces.gridSize;
}

/**
 * Work out where a piece goes.
 *
 * A piece needs support: either flat enough ground, or an existing piece whose
 * socket it accepts within `snapRadius`. That is the whole rule, and it is
 * deliberately loose. A strict system here is what makes voxel builders feel
 * like fighting the game.
 */
export function resolvePlacement(
  pieceId: string,
  desiredX: number,
  desiredY: number,
  desiredZ: number,
  rot: number,
  placed: readonly PlacedPiece[],
  groundHeight: number,
  groundSlope: number
): SnapResult {
  const def = pieceDef(pieceId);
  if (!def) return { x: desiredX, y: desiredY, z: desiredZ, rot, valid: false, reason: 'no-support' };

  const x = snapToGrid(desiredX);
  const z = snapToGrid(desiredZ);

  // Nearest compatible neighbour wins, so a wall lands on the floor under the
  // cursor rather than on one across the room.
  let best: PlacedPiece | null = null;
  let bestDist = pieces.snapRadius + pieces.gridSize;
  for (const other of placed) {
    const otherDef = pieceDef(other.pieceId);
    if (!otherDef) continue;
    if (!def.accepts.some((socket) => otherDef.sockets.includes(socket))) continue;
    const d = Math.hypot(other.x - x, other.z - z);
    if (d < bestDist) {
      bestDist = d;
      best = other;
    }
  }

  if (occupied(x, desiredY, z, placed, pieceId)) {
    return { x, y: desiredY, z, rot, valid: false, reason: 'occupied' };
  }

  if (best) {
    const y = best.y + supportOffset(best.pieceId, def);
    return { x, y, z, rot, valid: true };
  }

  // No neighbour: fall back to the ground, if it is flat enough to build on.
  if (!def.accepts.includes('ground')) {
    return { x, y: desiredY, z, rot, valid: false, reason: 'no-support' };
  }
  if (groundSlope > MAX_BUILD_SLOPE) {
    return { x, y: groundHeight, z, rot, valid: false, reason: 'too-steep' };
  }
  return { x, y: groundHeight, z, rot, valid: true };
}

/** How far above its support a piece sits. Floors stack, walls stand on top. */
function supportOffset(supportId: string, def: PieceDef): number {
  const support = pieceDef(supportId);
  if (!support) return 0;
  if (def.sockets.includes('floor')) return support.size[1];
  return support.size[1];
}

function occupied(
  x: number,
  y: number,
  z: number,
  placed: readonly PlacedPiece[],
  pieceId: string
): boolean {
  const def = pieceDef(pieceId);
  if (!def) return false;
  return placed.some(
    (p) =>
      p.pieceId === pieceId &&
      Math.abs(p.x - x) < 0.1 &&
      Math.abs(p.z - z) < 0.1 &&
      Math.abs(p.y - y) < Math.max(0.1, def.size[1] * 0.5)
  );
}

/** Refund for removing a piece, per the grace period in section 8. */
export function refundFor(
  pieceId: string,
  placedAtMs: number,
  nowMs: number
): { id: string; n: number }[] {
  const def = pieceDef(pieceId);
  if (!def) return [];
  const fraction =
    nowMs - placedAtMs <= pieces.fullRefundMs
      ? pieces.fullRefundFraction
      : pieces.lateRefundFraction;
  return def.cost
    .map((c) => ({ id: c.id, n: Math.floor(c.n * fraction) }))
    .filter((c) => c.n > 0);
}

/** Degrees. Steeper than this and a floor would float at one corner. */
const MAX_BUILD_SLOPE = 22;

export const BUILD_CONFIG = pieces;
