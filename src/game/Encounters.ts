import encounters from '../data/encounters.json';
import { createPal } from '../entities/Species';
import type { PalState } from '../party/PalState';

/**
 * Scripted fights: the two Tether grunts and Bracken Holt.
 *
 * Every pal built here is collared. That one flag carries three rules at once
 * (hits at 1.15x, never hesitates, cannot be caught) and it is set from the
 * data rather than from a check on who the trainer is, so a future Warden is a
 * JSON entry rather than a branch in the combat code.
 */

export interface EncounterTeamMember {
  species: string;
  level: number;
}

export interface EncounterDef {
  id: string;
  name: string;
  title?: string;
  dialogue: string;
  afterDialogue: string;
  /** Progress flag set when this fight is won. */
  flag: string;
  warden?: boolean;
  team: EncounterTeamMember[];
}

interface RawEncounter {
  name: string;
  title?: string;
  dialogue: string;
  afterDialogue: string;
  flag: string;
  warden?: boolean;
  team: EncounterTeamMember[];
}

const RAW = encounters as unknown as Record<string, RawEncounter>;

export function encounterDef(id: string): EncounterDef | undefined {
  // `$comment` and `$rewards` share the object with the encounters. Skipping
  // the sigil is cheaper than splitting the file and losing the comments.
  if (id.startsWith('$') || id === 'rewards') return undefined;
  const raw = RAW[id];
  if (!raw) return undefined;
  return {
    id,
    name: raw.name,
    dialogue: raw.dialogue,
    afterDialogue: raw.afterDialogue,
    flag: raw.flag,
    team: raw.team,
    ...(raw.title === undefined ? {} : { title: raw.title }),
    ...(raw.warden === undefined ? {} : { warden: raw.warden })
  };
}

export function encounterIds(): string[] {
  return Object.keys(RAW).filter((id) => encounterDef(id) !== undefined);
}

/**
 * Build a trainer's team.
 *
 * Variance is seeded off the encounter id and slot, so Bracken's Loamking is
 * the same Loamking on every device and on every retry. A boss whose stats
 * reroll between attempts is a boss the player cannot learn.
 */
export function buildTeam(
  def: EncounterDef,
  random: (index: number) => () => number,
  day: number,
  nowMs: number
): PalState[] {
  return def.team.map((member, index) => {
    const pal = createPal(
      member.species,
      member.level,
      day,
      nowMs,
      random(index),
      `${def.id}:${index}`
    );
    pal.collared = true;
    return pal;
  });
}

export interface RewardDef {
  flags: string[];
  badge?: { id: string; name: string };
  items: { id: string; n: number }[];
  recruit?: { species: string; level: number; dialogue: string };
  freed: number;
}

interface RawRewards {
  [key: string]: {
    flags: string[];
    badge?: { id: string; name: string };
    items?: { id: string; n: number }[];
    recruit?: { species: string; level: number; dialogue: string };
    freed?: number;
  };
}

export function rewardFor(encounterId: string): RewardDef | undefined {
  const rewards = (encounters as unknown as { rewards: RawRewards }).rewards;
  const raw = rewards?.[encounterId];
  if (!raw) return undefined;
  return {
    flags: raw.flags,
    items: raw.items ?? [],
    freed: raw.freed ?? 0,
    ...(raw.badge === undefined ? {} : { badge: raw.badge }),
    ...(raw.recruit === undefined ? {} : { recruit: raw.recruit })
  };
}
