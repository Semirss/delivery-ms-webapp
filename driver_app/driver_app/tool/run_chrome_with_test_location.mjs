// Run the Flutter driver app in Chrome with a browser-emulated test position.
// This is a local development tool. The app and server GPS rules stay intact.
import { spawn } from 'node:child_process';
import { existsSync } from 'node:fs';
import { mkdtemp, readFile, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const appDir = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const flags = new Map();
const verifyOnly = process.argv.includes('--verify-only');
const commandArgs = process.argv.slice(2).filter(arg => arg !== '--verify-only');
for (let i = 0; i < commandArgs.length; i += 2) {
  if (!commandArgs[i].startsWith('--') || !commandArgs[i + 1]) {
    throw new Error('Use --lat NUMBER --lng NUMBER [--port NUMBER].');
  }
  flags.set(commandArgs[i], commandArgs[i + 1]);
}

const latitude = Number(flags.get('--lat') ?? '8.9806');
const longitude = Number(flags.get('--lng') ?? '38.7578');
const webPort = Number(flags.get('--port') ?? '7357');
if (!Number.isFinite(latitude) || latitude < -90 || latitude > 90 ||
    !Number.isFinite(longitude) || longitude < -180 || longitude > 180 ||
    !Number.isInteger(webPort) || webPort < 1024 || webPort > 65535) {
  throw new Error('Invalid latitude, longitude, or port.');
}
for (const flag of flags.keys()) {
  if (!['--lat', '--lng', '--port'].includes(flag)) throw new Error(`Unknown option: ${flag}`);
}

const chromeCandidates = [
  process.env.CHROME_EXECUTABLE,
  'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe',
  'C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe',
].filter(Boolean);
const chromeExe = chromeCandidates.find(existsSync);
if (!chromeExe) throw new Error('Chrome was not found. Set CHROME_EXECUTABLE to chrome.exe.');

const sleep = ms => new Promise(resolve => setTimeout(resolve, ms));
const origin = `http://127.0.0.1:${webPort}`;
let flutterProcess;
let chromeProcess;
let profileDir;
let browserSocket;
let pageSocket;
let stopping = false;

async function stopProcess(child) {
  if (!child || child.exitCode !== null) return;
  if (process.platform === 'win32') {
    const killer = spawn('taskkill', ['/PID', String(child.pid), '/T', '/F'], {
      stdio: 'ignore',
    });
    await new Promise(resolve => {
      killer.once('exit', resolve);
      killer.once('error', resolve);
    });
  } else {
    child.kill('SIGTERM');
  }
}

async function cleanup() {
  if (stopping) return;
  stopping = true;
  pageSocket?.close();
  browserSocket?.close();
  await stopProcess(chromeProcess);
  await stopProcess(flutterProcess);
  if (profileDir) {
    const resolved = path.resolve(profileDir);
    const tempRoot = path.resolve(tmpdir()) + path.sep;
    if (!resolved.startsWith(tempRoot) ||
        !path.basename(resolved).startsWith('motobike-chrome-test-')) {
      throw new Error('Refusing to remove a browser profile outside the test temp directory.');
    }
    await rm(resolved, { recursive: true, force: true, maxRetries: 5, retryDelay: 250 });
  }
}

function connectCdp(url) {
  return new Promise((resolve, reject) => {
    const socket = new WebSocket(url);
    const pending = new Map();
    let nextId = 1;
    socket.addEventListener('open', () => resolve({
      socket,
      send(method, params = {}) {
        const id = nextId++;
        return new Promise((done, fail) => {
          pending.set(id, { done, fail });
          socket.send(JSON.stringify({ id, method, params }));
        });
      },
    }));
    socket.addEventListener('message', event => {
      const message = JSON.parse(event.data);
      const waiter = pending.get(message.id);
      if (!waiter) return;
      pending.delete(message.id);
      if (message.error) waiter.fail(new Error(`${message.error.message}`));
      else waiter.done(message.result);
    });
    socket.addEventListener('error', reject);
    socket.addEventListener('close', () => {
      for (const waiter of pending.values()) waiter.fail(new Error('Chrome closed.'));
      pending.clear();
    });
  });
}

async function waitForFlutter() {
  for (let attempt = 0; attempt < 180; attempt++) {
    if (flutterProcess.exitCode !== null) throw new Error('Flutter exited before the web server started.');
    try {
      const response = await fetch(origin, { signal: AbortSignal.timeout(1000) });
      if (response.ok) return;
    } catch { /* Flutter is still compiling. */ }
    await sleep(1000);
  }
  throw new Error(`Flutter did not start at ${origin} within three minutes.`);
}

async function waitForDebugPort() {
  const file = path.join(profileDir, 'DevToolsActivePort');
  for (let attempt = 0; attempt < 100; attempt++) {
    if (chromeProcess.exitCode !== null) throw new Error('Chrome exited before debugging started.');
    try {
      const [port, socketPath] = (await readFile(file, 'utf8')).trim().split(/\r?\n/);
      if (port && socketPath) return { port, socketPath };
    } catch { /* Chrome is still opening. */ }
    await sleep(100);
  }
  throw new Error('Chrome did not open its debugging port.');
}

async function main() {
  console.log(`Starting driver app at ${origin} with TEST GPS ${latitude}, ${longitude} (25 m).`);
  flutterProcess = process.platform === 'win32'
    ? spawn('cmd.exe', ['/d', '/s', '/c',
        `flutter run -d web-server --web-hostname=127.0.0.1 --web-port=${webPort}`],
      { cwd: appDir, stdio: 'inherit' })
    : spawn('flutter',
      ['run', '-d', 'web-server', '--web-hostname=127.0.0.1', `--web-port=${webPort}`],
      { cwd: appDir, stdio: 'inherit' });
  await waitForFlutter();

  profileDir = await mkdtemp(path.join(tmpdir(), 'motobike-chrome-test-'));
  chromeProcess = spawn(chromeExe, [
    `--user-data-dir=${profileDir}`,
    '--remote-debugging-port=0',
    '--remote-allow-origins=*',
    '--no-first-run',
    '--no-default-browser-check',
    'about:blank',
  ], { stdio: 'ignore' });
  const { port, socketPath } = await waitForDebugPort();
  const browser = await connectCdp(`ws://127.0.0.1:${port}${socketPath}`);
  browserSocket = browser.socket;
  await browser.send('Browser.grantPermissions', {
    origin,
    permissions: ['geolocation'],
  });
  const targetResponse = await fetch(`http://127.0.0.1:${port}/json/new?about:blank`, {
    method: 'PUT',
  });
  if (!targetResponse.ok) throw new Error('Could not create a Chrome test tab.');
  const target = await targetResponse.json();
  const page = await connectCdp(target.webSocketDebuggerUrl);
  pageSocket = page.socket;
  await page.send('Emulation.setGeolocationOverride', {
    latitude,
    longitude,
    accuracy: 25,
  });
  await page.send('Page.enable');
  await page.send('Page.navigate', { url: origin });
  await browser.send('Target.activateTarget', { targetId: target.id });
  let onAppPage = false;
  for (let attempt = 0; attempt < 50; attempt++) {
    const current = await page.send('Runtime.evaluate', {
      expression: 'location.origin',
      returnByValue: true,
    });
    if (current.result?.value === origin) {
      onAppPage = true;
      break;
    }
    await sleep(100);
  }
  if (!onAppPage) throw new Error('Chrome did not navigate to the Flutter app.');
  const probe = await page.send('Runtime.evaluate', {
    expression: `new Promise(resolve => navigator.geolocation.getCurrentPosition(
      position => resolve({ latitude: position.coords.latitude,
        longitude: position.coords.longitude, accuracy: position.coords.accuracy }),
      error => resolve({ error: error.message }), { timeout: 10000 }))`,
    awaitPromise: true,
    returnByValue: true,
  });
  const fix = probe.result?.value;
  if (!fix || fix.error || Math.abs(fix.latitude - latitude) > 0.000001 ||
      Math.abs(fix.longitude - longitude) > 0.000001 || fix.accuracy > 200) {
    throw new Error(`Chrome test GPS failed: ${fix?.error ?? 'wrong position returned'}`);
  }
  console.log(`Verified Chrome GPS: ${fix.latitude}, ${fix.longitude} (${fix.accuracy} m).`);
  if (verifyOnly) return;
  console.log('Keep this terminal open while testing. Press Ctrl+C to stop.');
  await new Promise(resolve => {
    process.once('SIGINT', resolve);
    chromeProcess.once('exit', resolve);
    flutterProcess.once('exit', resolve);
  });
}

try {
  await main();
} catch (error) {
  console.error(error.message);
  process.exitCode = 1;
} finally {
  try {
    await cleanup();
  } catch (error) {
    console.warn(`Temporary browser cleanup skipped: ${error.message}`);
  }
}
