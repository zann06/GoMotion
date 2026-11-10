#!/usr/bin/env node
/**
 * Captures the README screenshot gallery from a release web build.
 *
 * GoMotion is a Flutter app, and the Dart widget tester draws placeholder
 * "Ahem" glyphs instead of real text, so a screenshot has to come from a real
 * browser. This script drives headless Chrome over the DevTools protocol:
 *
 *   1. serve `build/web` so that the app lives at `<base>/` (see below),
 *   2. launch Chrome with `--force-prefers-reduced-motion` so every entrance
 *      animation is already settled (deterministic pixels, no motion blur),
 *   3. for each route, set `location.hash` and capture the viewport.
 *
 * Requirements: Node 20+ (global `fetch` and `WebSocket`) and Chrome.
 *
 * Usage:
 *   node tool/capture_screenshots.mjs --url http://127.0.0.1:8090/GoMotion/ \
 *     --out screenshots
 *
 * The app is built with `--base-href /GoMotion/`, so the local server must
 * expose `build/web` as a `/GoMotion/` directory. Either run the server from a
 * staging folder that contains it, or use `flutter build web --release` with
 * `--base-href /` for a local-only capture.
 *
 * Everything here is development tooling. Nothing in this file ships in the
 * app, and nothing in it talks to a network service: Chrome only loads the
 * local build.
 */

import { spawn } from 'node:child_process';
import { mkdir, rm, writeFile } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import os from 'node:os';
import path from 'node:path';

/** Viewport used for every capture: a tall phone in portrait. */
const VIEWPORT = { width: 430, height: 932, scale: 2 };

/**
 * `settle` is how long to wait after the route change before capturing.
 *
 * `reduced: false` marks the one shot that needs real motion. The splash hands
 * off when its entrance controller completes, and Flutter collapses an
 * `AnimationController` to zero duration when animations are disabled, so under
 * reduced motion the splash is gone before the first frame can be captured.
 * Playing it with motion on gives a stable, mid-fill frame to photograph.
 */
const SHOTS = [
  { file: '01-splash.png', route: '/splash', settle: 900, reduced: false, note: 'cold-start splash' },
  { file: '02-home.png', route: '/', settle: 1400, note: 'dashboard' },
  { file: '03-welcome.png', route: '/welcome', settle: 1000, note: 'welcome / onboarding' },
  { file: '04-destination-search.png', route: '/destination/search', settle: 1000, note: 'destination search' },
  { file: '05-gofood.png', route: '/food', settle: 1400, note: 'GoFood browse' },
  { file: '06-gofood-menu.png', route: '/food/restaurant/rest_nori', settle: 1400, note: 'GoFood restaurant menu' },
  { file: '07-gosend.png', route: '/send', settle: 1200, note: 'GoSend form' },
  { file: '08-activity.png', route: '/activity', settle: 1000, note: 'activity empty state' },
  { file: '09-rewards.png', route: '/rewards', settle: 1000, note: 'rewards catalogue' },
  { file: '10-profile.png', route: '/profile', settle: 1000, note: 'profile' },
  { file: '11-settings.png', route: '/settings', settle: 1000, note: 'settings' },
  { file: '12-about.png', route: '/about', settle: 1000, note: 'about / offline disclosure' },
];

const CHROME_CANDIDATES = [
  process.env.CHROME_PATH,
  'C:/Program Files/Google/Chrome/Application/chrome.exe',
  'C:/Program Files (x86)/Google/Chrome/Application/chrome.exe',
  '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
  '/usr/bin/google-chrome',
  '/usr/bin/chromium',
].filter(Boolean);

function parseArgs(argv) {
  const args = { url: 'http://127.0.0.1:8090/GoMotion/', out: 'screenshots', port: 9333 };
  for (let index = 0; index < argv.length; index += 1) {
    const key = argv[index];
    const value = argv[index + 1];
    if (key === '--url' && value) args.url = value.endsWith('/') ? value : `${value}/`;
    if (key === '--out' && value) args.out = value;
    if (key === '--port' && value) args.port = Number(value);
  }
  return args;
}

function findChrome() {
  const found = CHROME_CANDIDATES.find((candidate) => existsSync(candidate));
  if (!found) {
    throw new Error(
      'Chrome was not found. Set CHROME_PATH to the browser executable.',
    );
  }
  return found;
}

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

/** Minimal DevTools-protocol client over the page target's WebSocket. */
async function connect(port) {
  const deadline = Date.now() + 20_000;
  let target = null;
  while (!target) {
    if (Date.now() > deadline) throw new Error('Chrome did not expose a page target.');
    try {
      const response = await fetch(`http://127.0.0.1:${port}/json/list`);
      const targets = await response.json();
      target = targets.find((entry) => entry.type === 'page') ?? null;
    } catch {
      // Chrome is still starting up.
    }
    if (!target) await sleep(200);
  }

  const socket = new WebSocket(target.webSocketDebuggerUrl);
  await new Promise((resolve, reject) => {
    socket.addEventListener('open', resolve, { once: true });
    socket.addEventListener('error', reject, { once: true });
  });

  let nextId = 0;
  const pending = new Map();
  socket.addEventListener('message', (event) => {
    const message = JSON.parse(event.data);
    const entry = pending.get(message.id);
    if (!entry) return;
    pending.delete(message.id);
    if (message.error) entry.reject(new Error(`${message.error.message}`));
    else entry.resolve(message.result);
  });

  const send = (method, params = {}) =>
    new Promise((resolve, reject) => {
      const id = (nextId += 1);
      pending.set(id, { resolve, reject });
      socket.send(JSON.stringify({ id, method, params }));
    });

  return { send, close: () => socket.close() };
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const chrome = findChrome();
  const profile = path.join(os.tmpdir(), `gomotion-shots-${process.pid}`);
  const outDir = path.resolve(args.out);
  await mkdir(outDir, { recursive: true });

  const child = spawn(
    chrome,
    [
      '--headless=new',
      `--remote-debugging-port=${args.port}`,
      `--user-data-dir=${profile}`,
      `--window-size=${VIEWPORT.width},${VIEWPORT.height}`,
      // Screenshot determinism: no entrance motion still in flight.
      '--force-prefers-reduced-motion',
      '--hide-scrollbars',
      '--no-first-run',
      '--no-default-browser-check',
      '--disable-extensions',
      '--allow-file-access-from-files',
      'about:blank',
    ],
    { stdio: 'ignore' },
  );

  let client;
  try {
    client = await connect(args.port);
    await client.send('Page.enable');
    await client.send('Runtime.enable');
    await client.send('Emulation.setDeviceMetricsOverride', {
      width: VIEWPORT.width,
      height: VIEWPORT.height,
      deviceScaleFactor: VIEWPORT.scale,
      mobile: true,
    });
    await client.send('Emulation.setTouchEmulationEnabled', { enabled: true });
    await client.send('Emulation.setEmulatedMedia', {
      features: [{ name: 'prefers-reduced-motion', value: 'reduce' }],
    });

    console.log(`Loading ${args.url}`);
    await client.send('Page.navigate', { url: args.url });

    // Wait for the Flutter engine to attach its view to the DOM.
    const readyDeadline = Date.now() + 45_000;
    for (;;) {
      const { result } = await client.send('Runtime.evaluate', {
        expression:
          "!!document.querySelector('flt-glass-pane, flt-scene-host, flutter-view, flt-semantics-placeholder')",
        returnByValue: true,
      });
      if (result.value === true) break;
      if (Date.now() > readyDeadline) throw new Error('The Flutter view never appeared.');
      await sleep(250);
    }
    // Give the first frame, fonts, and any cold-start work time to finish.
    await sleep(2500);

    for (const shot of SHOTS) {
      // Per-shot motion setting: everything is settled under reduced motion,
      // except the one shot that is only reachable while animating (splash).
      await client.send('Emulation.setEmulatedMedia', {
        features: [
          {
            name: 'prefers-reduced-motion',
            value: shot.reduced === false ? 'no-preference' : 'reduce',
          },
        ],
      });
      const hash = `#${shot.route}`;
      await client.send('Runtime.evaluate', {
        expression: `location.hash = ${JSON.stringify(hash)}; true`,
        returnByValue: true,
      });
      await sleep(shot.settle);
      const { data } = await client.send('Page.captureScreenshot', {
        format: 'png',
        captureBeyondViewport: false,
      });
      const file = path.join(outDir, shot.file);
      await writeFile(file, Buffer.from(data, 'base64'));
      console.log(`  ${shot.file}  ${shot.route}  (${shot.note})`);
    }

    console.log(`\nSaved ${SHOTS.length} screenshots to ${outDir}`);
  } finally {
    client?.close();
    child.kill();
    await sleep(300);
    await rm(profile, { recursive: true, force: true }).catch(() => {});
  }
}

main().catch((error) => {
  console.error(`capture failed: ${error.message}`);
  process.exitCode = 1;
});