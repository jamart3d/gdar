const puppeteer = require('puppeteer');
const http = require('http');
const fs = require('fs');
const path = require('path');

// 1. Start Local Wasm Server
const mimeTypes = {
  '.html': 'text/html',
  '.js': 'text/javascript',
  '.css': 'text/css',
  '.json': 'application/json',
  '.png': 'image/png',
  '.wasm': 'application/wasm',
  '.mjs': 'text/javascript',
  '.ttf': 'font/ttf',
  '.otf': 'font/otf'
};

const server = http.createServer((request, response) => {
  response.setHeader('Cross-Origin-Embedder-Policy', 'require-corp');
  response.setHeader('Cross-Origin-Opener-Policy', 'same-origin');

  let filePath = path.join(__dirname, '../../build/web', request.url.split('?')[0]);
  if (filePath.endsWith(path.sep) || filePath.endsWith('web')) {
    filePath = path.join(filePath, 'index.html');
  }

  const extname = String(path.extname(filePath)).toLowerCase();
  const contentType = mimeTypes[extname] || 'application/octet-stream';

  fs.readFile(filePath, (error, content) => {
    if (error) {
      response.writeHead(404);
      response.end();
    } else {
      response.writeHead(200, { 'Content-Type': contentType });
      response.end(content, 'utf-8');
    }
  });
});

async function assertUiAlive(page, label) {
  const status = await page.evaluate(() => {
    const hb = window.__uiHeartbeat || { ticks: 0, lastTick: 0 };
    return { ticks: hb.ticks, lastTick: hb.lastTick, now: performance.now() };
  });

  const stalled = !status.lastTick || (status.now - status.lastTick) > 1000;
  if (stalled) {
    const snap = path.join(__dirname, `ui_freeze_${Date.now()}.png`);
    await page.screenshot({ path: snap });
    console.error(`[UI Freeze] ${label} - lastTick=${status.lastTick} now=${status.now}`);
    await dumpWebErrorLog(page, 'ui-freeze');
    throw new Error('UI heartbeat stalled');
  }
}

async function assertNoUiFreezeWithAudio(page, label) {
  const status = await page.evaluate(() => {
    const hb = window.__uiHeartbeat || { ticks: 0, lastTick: 0 };
    const audio = window._gdarAudio;
    const state = audio && audio.getState ? audio.getState() : null;
    return {
      now: performance.now(),
      lastTick: hb.lastTick,
      position: state ? state.position || 0 : 0,
      playing: state ? !!state.playing : false
    };
  });

  const uiFrozen = !status.lastTick || (status.now - status.lastTick) > 1000;
  if (uiFrozen && status.playing) {
    const snap = path.join(__dirname, `ui_freeze_audio_${Date.now()}.png`);
    await page.screenshot({ path: snap });
    console.error(`[UI Freeze + Audio] ${label} - position=${status.position}`);
    await dumpWebErrorLog(page, 'ui-freeze-audio');
    throw new Error('UI frozen while audio playing');
  }
}
async function dumpWebErrorLog(page, label) {
  const snapshot = await page.evaluate(() => {
    if (typeof window.gdarDumpErrors === 'function') {
      return window.gdarDumpErrors();
    }
    return null;
  });

  const payload = {
    label,
    timestamp: new Date().toISOString(),
    entries: Array.isArray(snapshot) ? snapshot : []
  };

  const filePath = path.join(__dirname, `web_error_log_${Date.now()}.json`);
  fs.writeFileSync(filePath, JSON.stringify(payload, null, 2));
  console.log(`[Errors] Saved web error log to ${filePath}`);
  return payload.entries.length;
}

function dumpBrowserErrors(consoleErrors, pageErrors, label) {
  const payload = {
    label,
    timestamp: new Date().toISOString(),
    consoleErrors,
    pageErrors
  };
  const filePath = path.join(__dirname, `browser_errors_${Date.now()}.json`);
  fs.writeFileSync(filePath, JSON.stringify(payload, null, 2));
  console.log(`[Errors] Saved browser error log to ${filePath}`);
}

server.listen(8080, async () => {
  console.log('[Server] Local Wasm test server running on port 8080...');

  // 2. Start Puppeteer
  console.log('[Puppeteer] Starting Headless Test...');
  let browser = null;
  let page = null;
  const consoleErrors = [];
  const pageErrors = [];
  browser = await puppeteer.launch({
    headless: 'new',
    args: ['--autoplay-policy=no-user-gesture-required']
  });

  page = await browser.newPage();
  await page.setViewport({ width: 1280, height: 720 });

  page.on('console', msg => {
    const text = msg.text();
    if (msg.type() === 'error') {
      consoleErrors.push({
        timestamp: new Date().toISOString(),
        text
      });
    }
    if (text.includes('[hybrid]') || text.includes('AudioProvider') || text.includes('suspended') || text.includes('[LongTask]') || text.includes('[WASM]')) {
      console.log(`[Browser Logs] -> ${text}`);
    }
  });

  page.on('pageerror', error => {
    pageErrors.push({
      timestamp: new Date().toISOString(),
      message: error.message,
      stack: error.stack
    });
    console.error(`[PageError] ${error.message}`);
  });

  // Force HTML5 engine before app scripts run
  await page.evaluateOnNewDocument(() => {
    try {
      localStorage.setItem('flutter.audio_engine_mode', '"html5"');
      localStorage.setItem('audio_engine_mode', '"html5"');
    } catch (_) { }
  });

  console.log('[Puppeteer] Navigating to Wasm build...');
  try {
    await page.goto('http://localhost:8080', { waitUntil: 'networkidle2' });
  } catch (e) {
    console.error('Failed to load.', e);
    await browser.close();
    server.close();
    return;
  }

  console.log('[Puppeteer] Waiting 5s for Flutter Wasm initialization...');
  await new Promise(r => setTimeout(r, 5000));

  await page.mouse.click(200, 200);
  await new Promise(r => setTimeout(r, 1000));

  // Install UI heartbeat + long task observer + wasm markers
  await page.evaluate(() => {
    window.__uiHeartbeat = { ticks: 0, lastTick: performance.now(), frozen: false };
    function beat() {
      window.__uiHeartbeat.ticks += 1;
      window.__uiHeartbeat.lastTick = performance.now();
      requestAnimationFrame(beat);
    }
    requestAnimationFrame(beat);

    try {
      const observer = new PerformanceObserver((list) => {
        for (const entry of list.getEntries()) {
          if (entry.duration > 200) {
            console.warn(`[LongTask] ${entry.duration.toFixed(1)}ms`);
          }
        }
      });
      observer.observe({ entryTypes: ['longtask'] });
    } catch (_) { }

    try {
      const res = performance.getEntriesByType('resource');
      const wasm = res.filter(r => r.name.includes('.wasm'));
      console.log(`[WASM] resources=${wasm.length}`);
    } catch (_) { }
  });

  await assertUiAlive(page, 'post-init');

  await page.evaluate(() => {
    if (typeof window.syncState === 'function' && !window._playing) {
      console.log('[hybrid] Forcing playback via JS test hook for testing...');
      window.syncState(1, 0, true);
    }
  });

  await new Promise(r => setTimeout(r, 2000));
  await assertUiAlive(page, 'post-play');

  console.log('[Puppeteer] Beginning visual state stress cycle (20 cycles)...');
  let successCount = 0;
  const CYCLES = 20;

  for (let i = 1; i <= CYCLES; i++) {
    process.stdout.write(`\rCycle ${i}/${CYCLES} - Hiding tab...         `);

    await page.evaluate(() => {
      Object.defineProperty(document, 'visibilityState', { get: () => 'hidden', configurable: true });
      Object.defineProperty(document, 'hidden', { get: () => true, configurable: true });
      document.dispatchEvent(new Event('visibilitychange'));
    });

    await new Promise(r => setTimeout(r, 400));
    process.stdout.write(`\rCycle ${i}/${CYCLES} - Restoring tab...       `);

    await page.evaluate(() => {
      Object.defineProperty(document, 'visibilityState', { get: () => 'visible', configurable: true });
      Object.defineProperty(document, 'hidden', { get: () => false, configurable: true });
      document.dispatchEvent(new Event('visibilitychange'));
    });

    await new Promise(r => setTimeout(r, 400));
    await assertUiAlive(page, `visibility-cycle-${i}`);
    successCount++;
  }

  console.log(`\n\n[Result] Visibility Stress Complete. ${successCount}/${CYCLES} cycles survived.`);

  console.log('[Puppeteer] Beginning Fruit Tab Stress (15 cycles)...');
  const TABS = ['library tab', 'settings tab', 'play tab', 'random tab'];
  for (let i = 1; i <= 15; i++) {
    process.stdout.write(`\rTab Cycle ${i}/15...                     `);
    const tabLabel = TABS[Math.floor(Math.random() * TABS.length)];
    try {
      // Flutter can render several spans for the same label. Click the one with role=button if possible
      // or just any match. Puppeteer click() handles visibility checks.
      await page.click(`[aria-label="${tabLabel}"]`);
    } catch (e) {
      // In case the button is not visible yet or tree is rebuilding
    }
    await new Promise(r => setTimeout(r, 600));
    await assertUiAlive(page, `tab-stress-${i}`);
    await assertNoUiFreezeWithAudio(page);
  }
  console.log('\n[Result] Tab Stress Complete.');

  console.log('[Puppeteer] Beginning track transition stress (10 transitions)...');
  const TRANSITIONS = 10;
  for (let i = 1; i <= TRANSITIONS; i++) {
    process.stdout.write(`\rTransition ${i}/${TRANSITIONS} - Next track...      `);
    await page.evaluate(() => {
      try {
        const engine = window._gdarAudio;
        if (!engine) return;
        const state = engine.getState ? engine.getState() : { index: 0 };
        const next = (state.index || 0) + 1;
        if (engine.seekToIndex) engine.seekToIndex(next);
      } catch (_) { }
    });
    await new Promise(r => setTimeout(r, 2500));
    await assertUiAlive(page, `track-transition-${i}`);
  }

  console.log('\n[Result] Track transition stress complete.');

  console.log('[Puppeteer] Beginning extended playback monitor (5 minutes)...');
  const start = Date.now();
  const durationMs = 5 * 60 * 1000;
  while (Date.now() - start < durationMs) {
    await new Promise(r => setTimeout(r, 2000));
    await assertUiAlive(page, 'extended-playback');
    await assertNoUiFreezeWithAudio(page, 'extended-playback');
  }

  const wasmInfo = await page.evaluate(() => {
    const cfg = window._flutter_buildConfig || null;
    const res = performance.getEntriesByType('resource').map(r => r.name);
    const hasWasm = res.some(r => r.includes('.wasm'));
    return { cfg, hasWasm };
  });

  if (wasmInfo.hasWasm) {
    console.log('[Result] ? Wasm resources detected.');
  } else {
    console.log('[Result] ?? No Wasm resource detected. Check build config or server headers.');
  }

  await dumpWebErrorLog(page, 'final');
  await browser.close();
  dumpBrowserErrors(consoleErrors, pageErrors, 'final');
  server.close();
});














