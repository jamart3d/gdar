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
      // Try resolving anyway to allow Flutter to boot
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
    const snap = path.join(__dirname, `idle_ui_freeze_${Date.now()}.png`);
    await page.screenshot({ path: snap });
    console.error(`[UI Freeze] ${label} - lastTick=${status.lastTick} now=${status.now}`);
    throw new Error('UI heartbeat stalled');
  }
}

server.listen(8080, async () => {
  console.log('[Server] Local Wasm test server running on port 8080...');

  // 2. Start Puppeteer
  console.log('[Puppeteer] Starting Headless Test...');
  const browser = await puppeteer.launch({
    headless: 'new',
    args: ['--autoplay-policy=no-user-gesture-required']
  });

  const page = await browser.newPage();
  await page.setViewport({ width: 1280, height: 720 });

  page.on('console', msg => {
    const text = msg.text();
    if (text.includes('[WASM]') || text.includes('[LongTask]')) {
      console.log(`[Browser Logs] -> ${text}`);
    }
  });

  // Force HTML5 engine before app scripts run (optional, but good for consistency)
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

  console.log('[Puppeteer] Beginning Idle Monitor (5 minutes)...');
  console.log('Every 1 minute, we will click a tab to simulate minimal interaction.');

  const TABS = ['library tab', 'settings tab', 'play tab'];

  const totalMinutes = 5;

  for (let minute = 1; minute <= totalMinutes; minute++) {
    process.stdout.write(`\rMinute ${minute}/5 - Idling...                      `);

    // Wait for 1 minute in 5-second chunks so we can monitor UI heartbeat
    for(let interval = 0; interval < 12; interval++) {
        await new Promise(r => setTimeout(r, 5000));
        await assertUiAlive(page, `idle-m${minute}-i${interval}`);
    }

    // Once a minute, click a tab
    const tabLabel = TABS[minute % TABS.length]; // Cycle through tabs
    process.stdout.write(`\rMinute ${minute}/5 - Clicking ${tabLabel}...        `);
    try {
      await page.click(`[aria-label="${tabLabel}"]`);
    } catch (e) {}

    await new Promise(r => setTimeout(r, 1000));
    await assertUiAlive(page, `click-${tabLabel}`);
  }

  console.log('\n[Result] 5-Minute Idle Test Complete! Wasm PWA is stable.');

  const wasmInfo = await page.evaluate(() => {
    const res = performance.getEntriesByType('resource').map(r => r.name);
    return res.some(r => r.includes('.wasm'));
  });

  if (wasmInfo) {
    console.log('[Result] ✔ Wasm resources detected.');
  }

  await browser.close();
  server.close();
});
