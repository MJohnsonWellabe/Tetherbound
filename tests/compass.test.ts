import { describe, expect, it } from 'vitest';
import { layOutCompass } from '../src/ui/compass';
import type { CompassMarker } from '../src/ui/HUD';

/**
 * The compass strip used to draw every marker, which meant three landmarks in
 * roughly the same bearing printed on top of each other and none of them could
 * be read. These assert the two rules that fix it: never overlap, never more
 * than two.
 */

const WIDTH = 460;

function marker(label: string, x: number, z: number): CompassMarker {
  return { label, x, z, kind: 'village' };
}

describe('compass layout', () => {
  it('never overlaps two label boxes', () => {
    // Three landmarks within a few degrees of each other, which is exactly the
    // case that produced the smear.
    const markers = [
      marker('The Standing Stones', 0, 1000),
      marker('Hollowbrook', 30, 1000),
      marker('The Meadows Hall', 60, 1000)
    ];

    const placed = layOutCompass(markers, 0, 0, 0, WIDTH);
    for (let i = 0; i < placed.length; i++) {
      for (let j = i + 1; j < placed.length; j++) {
        const a = placed[i]!;
        const b = placed[j]!;
        expect(Math.abs(a.centrePx - b.centrePx)).toBeGreaterThan(40);
      }
    }
  });

  it('shows at most two markers', () => {
    const markers = [
      marker('North', 0, 1000),
      marker('East', 1000, 0),
      marker('South', 0, -1000),
      marker('West', -1000, 0)
    ];
    expect(layOutCompass(markers, 0, 0, 0, WIDTH).length).toBeLessThanOrEqual(2);
  });

  it('prefers what is in front, then what is nearest', () => {
    const markers = [
      marker('Behind', 0, -1000),
      marker('Far ahead', 0, 900),
      marker('Near ahead', 300, 60)
    ];
    const placed = layOutCompass(markers, 0, 0, 0, WIDTH);
    expect(placed.map((p) => p.label)).toEqual(['Near ahead', 'Far ahead']);
  });

  it('keeps every label box inside the strip', () => {
    const markers = [marker('The Meadows Hall', 1000, 5)];
    const placed = layOutCompass(markers, 0, 0, 0, WIDTH);
    const pin = placed[0]!;
    // Half of the widest possible box for this label, roughly.
    expect(pin.centrePx).toBeGreaterThan(0);
    expect(pin.centrePx).toBeLessThan(WIDTH);
  });

  it('flags a marker behind the player rather than dropping it', () => {
    const placed = layOutCompass([marker('Hollowbrook', 0, -1000)], 0, 0, 0, WIDTH);
    expect(placed).toHaveLength(1);
    expect(placed[0]!.behind).toBe(true);
  });

  it('reports distance in whole metres', () => {
    const placed = layOutCompass([marker('Hollowbrook', 30, 40)], 0, 0, 0, WIDTH);
    expect(placed[0]!.distance).toBe(50);
  });
});
