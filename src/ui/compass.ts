import type { CompassMarker } from './HUD';

/**
 * Where compass labels go, and which ones get dropped.
 *
 * Pure, because the bug it fixes is a geometry bug and geometry is testable.
 * Three landmarks that happen to lie in the same direction used to be drawn at
 * the same place on the strip, so "The Standing Stones", "Hollowbrook" and
 * "The Meadows Hall" overprinted into one unreadable smear. The strip has room
 * for two labels at handheld reading size, so it shows two.
 */

/** Half the field of view either side maps across the whole strip. */
const HALF_FOV = Math.PI * 0.75;

/** Two is what fits at 12px without crowding. */
const MAX_PINS = 2;

/** Clear space kept between two label boxes, in px. */
const GUTTER = 14;

/** The strip has rounded ends; a label pushed into one gets its edge shaved. */
const EDGE_PAD = 14;

/** Compass rose, clockwise from north. */
const CARDINALS = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'] as const;

/*
 * Label widths are estimated rather than measured: measuring means a layout
 * read per marker per frame, and the estimate only has to be good enough to
 * decide whether two boxes touch. Values are for the 12px UI face and the 12px
 * monospace distance line.
 */
const LABEL_CHAR_PX = 7.2;
const DIST_CHAR_PX = 7.4;
const PIN_CHROME_PX = 20;

export interface CompassCandidate {
  label: string;
  kind: CompassMarker['kind'];
  /** Metres, rounded. */
  distance: number;
  /** Behind the player, so the label is faded but still says which way to turn. */
  behind: boolean;
  /** Centre of the label box, in px from the left edge of the strip. */
  centrePx: number;
}

/**
 * Place markers along a strip `widthPx` wide, dropping any label that would
 * collide with one already placed and capping the result at MAX_PINS.
 *
 * Priority is "in front of you" first, then nearest, because a landmark you are
 * walking towards is the one you are navigating by.
 */
export function layOutCompass(
  markers: readonly CompassMarker[],
  playerX: number,
  playerZ: number,
  yaw: number,
  widthPx: number
): CompassCandidate[] {
  const ranked = markers
    .map((marker) => {
      const bearing = Math.atan2(marker.x - playerX, marker.z - playerZ);
      let relative = bearing - yaw;
      while (relative > Math.PI) relative -= Math.PI * 2;
      while (relative < -Math.PI) relative += Math.PI * 2;

      const t = Math.max(-1, Math.min(1, relative / HALF_FOV));
      const distance = Math.round(Math.hypot(marker.x - playerX, marker.z - playerZ));
      return {
        marker,
        distance,
        behind: Math.abs(relative) > HALF_FOV,
        boxPx: boxWidth(marker.label, distance),
        idealPx: widthPx * (0.5 + t * 0.5)
      };
    })
    .sort((a, b) => {
      if (a.behind !== b.behind) return a.behind ? 1 : -1;
      return a.distance - b.distance;
    });

  const placed: CompassCandidate[] = [];
  const boxes: Array<{ min: number; max: number }> = [];

  for (const item of ranked) {
    if (placed.length >= MAX_PINS) break;

    const half = item.boxPx / 2;
    // Clamped so a label at the edge of the strip is not sliced in half by the
    // strip's own overflow rule.
    const low = Math.min(half + EDGE_PAD, widthPx / 2);
    const high = Math.max(widthPx - half - EDGE_PAD, widthPx / 2);
    const centre = clamp(item.idealPx, low, high);
    const min = centre - half;
    const max = centre + half;
    if (boxes.some((b) => min < b.max + GUTTER && max > b.min - GUTTER)) continue;

    boxes.push({ min, max });
    placed.push({
      label: item.marker.label,
      kind: item.marker.kind,
      distance: item.distance,
      behind: item.behind,
      centrePx: centre
    });
  }

  return placed;
}

/**
 * The eight rose marks, in the same bearing space as the pins.
 *
 * Without them a strip with one landmark on it is a mostly empty rectangle and
 * nothing says which way you are pointing.
 */
export function layOutCardinals(yaw: number, widthPx: number): CardinalMark[] {
  const marks: CardinalMark[] = [];
  for (let i = 0; i < CARDINALS.length; i++) {
    const bearing = (i / CARDINALS.length) * Math.PI * 2;
    let relative = bearing - yaw;
    while (relative > Math.PI) relative -= Math.PI * 2;
    while (relative < -Math.PI) relative += Math.PI * 2;
    if (Math.abs(relative) > HALF_FOV) continue;

    // A rose letter half eaten by the strip border reads as damage, so the
    // ones that would land on an edge are dropped instead.
    const centrePx = widthPx * (0.5 + (relative / HALF_FOV) * 0.5);
    if (centrePx < EDGE_PAD || centrePx > widthPx - EDGE_PAD) continue;

    marks.push({
      label: CARDINALS[i] as string,
      centrePx,
      major: i % 2 === 0
    });
  }
  return marks;
}

export interface CardinalMark {
  label: string;
  centrePx: number;
  /** N, E, S and W read louder than the diagonals. */
  major: boolean;
}

function boxWidth(label: string, distance: number): number {
  const head = label.length * LABEL_CHAR_PX + PIN_CHROME_PX;
  const dist = `${distance} m`.length * DIST_CHAR_PX;
  return Math.max(head, dist);
}

function clamp(value: number, low: number, high: number): number {
  return Math.max(low, Math.min(high, value));
}
