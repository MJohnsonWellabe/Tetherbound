import { describe, expect, it } from 'vitest';
import { PROD_HOSTNAMES, resolveEnv, resolveEnvName } from '../src/config/env';

/**
 * The environment resolver decides whether a page load talks to the real
 * backend. Getting it wrong in either direction is bad in a quiet way: a dev
 * session writing to real players' saves, or a live build silently running
 * local-only and losing everyone's progress. So the rules get asserted.
 */

const NONE: Record<string, string | undefined> = {};

describe('resolveEnvName', () => {
  it('treats the Pages host as production', () => {
    expect(resolveEnvName('mjohnsonwellabe.github.io', '')).toBe('prod');
  });

  it('treats localhost as dev', () => {
    expect(resolveEnvName('localhost', '')).toBe('dev');
  });

  it('treats a LAN IP as dev', () => {
    // `npm run dev --host` serves on a DHCP address so a phone can load it.
    // That host is unknowable at build time, which is the whole reason this
    // resolver is hostname-keyed rather than a build flag.
    expect(resolveEnvName('192.168.1.47', '')).toBe('dev');
  });

  it('treats an unknown host as dev, never prod', () => {
    // Failing closed matters more than failing convenient: an unrecognised
    // host must not get write access to real save data.
    expect(resolveEnvName('some-fork.example.com', '')).toBe('dev');
  });

  it('honours an explicit override', () => {
    expect(resolveEnvName('localhost', '?env=prod')).toBe('prod');
    expect(resolveEnvName('mjohnsonwellabe.github.io', '?env=dev')).toBe('dev');
  });

  it('ignores a nonsense override rather than throwing', () => {
    expect(resolveEnvName('localhost', '?env=banana')).toBe('dev');
  });
});

describe('resolveEnv', () => {
  it('enables the cloud in production', () => {
    const env = resolveEnv('mjohnsonwellabe.github.io', '', NONE);
    expect(env.cloudEnabled).toBe(true);
    expect(env.firebase.projectId).toBe('tetherbound-5fdd8');
    expect(env.firebase.apiKey).not.toBe('');
  });

  it('runs local-only in dev with no dev project configured', () => {
    const env = resolveEnv('localhost', '', NONE);
    expect(env.cloudEnabled).toBe(false);
    expect(env.firebase.apiKey).toBe('');
  });

  it('lets ?cloud=off force local-only anywhere', () => {
    // The reproduction switch for "it works for me but not for them".
    expect(resolveEnv('mjohnsonwellabe.github.io', '?cloud=off', NONE).cloudEnabled).toBe(false);
  });

  it('throws on a partial dev config rather than half-connecting', () => {
    expect(() => resolveEnv('localhost', '', { VITE_DEV_FIREBASE_API_KEY: 'k' })).toThrow(
      /incomplete/i
    );
  });

  it('accepts a complete dev config', () => {
    const env = resolveEnv('localhost', '', {
      VITE_DEV_FIREBASE_API_KEY: 'k',
      VITE_DEV_FIREBASE_AUTH_DOMAIN: 'd',
      VITE_DEV_FIREBASE_PROJECT_ID: 'p',
      VITE_DEV_FIREBASE_APP_ID: 'a'
    });
    expect(env.cloudEnabled).toBe(true);
    expect(env.firebase.projectId).toBe('p');
  });

  it('keeps authDomain matching the project, which is what Google checks', () => {
    const env = resolveEnv('mjohnsonwellabe.github.io', '', NONE);
    expect(env.firebase.authDomain).toBe(`${env.firebase.projectId}.firebaseapp.com`);
  });

  it('lists exactly one production hostname', () => {
    // A stray entry here is a silent grant of production write access.
    expect(PROD_HOSTNAMES).toEqual(['mjohnsonwellabe.github.io']);
  });
});
