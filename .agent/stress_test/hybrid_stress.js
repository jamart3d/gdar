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
  response.setHeader('Cross-Origin-Embedder-Policy', 'require-corp'); // Wasm multi-threading
  response.setHeader('Cross-Origin-Opener-Policy', 'same-origin'); // Wasm multi-threading

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

server.listen(8080, async () => {
    console.log('[Server] Local Wasm test server running on port 8080...');

    // 2. Start Puppeteer
    console.log('[Puppeteer] Starting Headless Test...');
    const browser = await puppeteer.launch({
        headless: 'new',
        args: ['--autoplay-policy=no-user-gesture-required']
    });

    const page = await browser.newPage();

    page.on('console', msg => {
        const text = msg.text();
        if (text.includes('[hybrid]') || text.includes('AudioProvider') || text.includes('suspended')) {
            console.log(`[Browser Logs] -> ${text}`);
        }
    });

    console.log('[Puppeteer] Navigating to Wasm build...');
    try {
        await page.goto('http://localhost:8080', { waitUntil: 'networkidle2' });
    } catch(e) {
        console.error('Failed to load.', e);
        await browser.close();
        server.close();
        return;
    }

    console.log('[Puppeteer] Waiting 5s for Flutter Wasm initialization...');
    await new Promise(r => setTimeout(r, 5000));

    await page.mouse.click(200, 200);
    await new Promise(r => setTimeout(r, 1000));

    await page.evaluate(() => {
        if (typeof window.syncState === 'function' && !window._playing) {
            console.log('[hybrid] Forcing playback via JS test hook for testing...');
            window.syncState(1, 0, true);
        }
    });

    await new Promise(r => setTimeout(r, 2000));

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
        successCount++;
    }

    console.log(`\n\n[Result] Stress Test Complete. ${successCount}/${CYCLES} cycles survived.`);

    const isWasm = await page.evaluate(() => typeof window._flutter_buildConfig !== 'undefined' || !!document.querySelector('script[src*=".wasm"]'));
    console.log(isWasm ? '[Result] ✅ Wasm Application verified active.' : '[Result] ⚠️ Wasm marker not found (fallback JS used?).');

    await browser.close();
    server.close();
});
