import { defineConfig } from '@playwright/test';

/**
 * Smoke specs. These are NOT unit tests: vitest owns pure logic, and this owns
 * "does the thing actually boot and render in a browser".
 *
 * Deliberately separate from `npm run test` and from the deploy workflow, for
 * the reason the sibling GolfModel project learned the hard way: a headless
 * WebGL render is flakier than any pure test, and a flaky render must never be
 * able to block a deploy. Run it yourself, read the screenshots.
 *
 * Software WebGL via SwiftShader, because there is no GPU on CI. That makes
 * frame timings meaningless here, so nothing in these specs asserts on FPS.
 */
export default defineConfig({
  testDir: 'tests/smoke',
  outputDir: 'tests/smoke/.output',
  timeout: 90_000,
  // One worker. Parallel software-WebGL contexts starve each other and turn
  // real failures into timeouts.
  workers: 1,
  fullyParallel: false,
  reporter: [['list']],
  use: {
    baseURL: 'http://localhost:4173',
    // A phone, since CLAUDE.md says test at 390x844 before anything wider.
    viewport: { width: 390, height: 844 },
    deviceScaleFactor: 2,
    hasTouch: true,
    isMobile: true,
    screenshot: 'only-on-failure',
    launchOptions: {
      // Point at the Chromium already on the machine rather than letting
      // Playwright fetch a build matched to its own version. Environments that
      // preinstall a browser pin a specific revision, and `playwright install`
      // either fails or silently downloads a second copy.
      ...(process.env.CHROMIUM_PATH ? { executablePath: process.env.CHROMIUM_PATH } : {}),
      args: [
        '--use-gl=angle',
        '--use-angle=swiftshader',
        '--enable-unsafe-swiftshader',
        '--disable-lcd-text'
      ]
    }
  },
  webServer: {
    command: 'npm run preview -- --port 4173 --strictPort',
    url: 'http://localhost:4173',
    reuseExistingServer: true,
    timeout: 120_000
  }
});
