/**
 * Regression: active visible playback should recover state emissions even if
 * the normal RAF-driven progress loop stalls.
 */
const fs = require('fs');
const path = require('path');

require('./mock_harness.js');

function loadScript(filename) {
    const filePath = path.join(__dirname, '..', filename);
    const code = fs.readFileSync(filePath, 'utf8');
    eval(code);
}

loadScript('audio_heartbeat.js');
loadScript('audio_scheduler.js');
loadScript('html5_audio_engine.js');

function assert(condition, message) {
    if (!condition) {
        console.error('FAILED:', message);
        process.exit(1);
    }
    console.log('PASSED:', message);
}

async function run() {
    const engine = global._html5Audio;
    let callbackCount = 0;
    const flushTicks = () => new Promise((resolve) => setTimeout(resolve, 300));

    global.document.visibilityState = 'visible';
    global.document.hidden = false;

    engine.onStateChange(() => {
        callbackCount += 1;
    });

    engine.setPlaylist([{ url: 'http://test.mp3', duration: 300 }], 0);
    await engine.play();
    engine.seek(0);
    await flushTicks();

    global.__advanceMockPlayback(10);
    await flushTicks();

    const beforeStall = engine.getState().position;
    assert(beforeStall > 0, 'engine state should advance before visible stall');
    assert(callbackCount > 0, 'state callback should emit before visible stall');

    const originalRaf = global.requestAnimationFrame;
    global.requestAnimationFrame = () => 0;
    await flushTicks();

    const callbackCountAtStall = callbackCount;
    global.__advanceMockPlayback(5);
    await new Promise((resolve) => setTimeout(resolve, 1500));

    const afterStall = engine.getState().position;
    assert(
        afterStall > beforeStall,
        'engine state should keep advancing while visible progress loop is stalled',
    );
    assert(
        callbackCount > callbackCountAtStall,
        'visible stall should trigger a fresh state emission without visibilitychange',
    );

    global.requestAnimationFrame = originalRaf;
    process.exit(0);
}

run().catch((error) => {
    console.error(error);
    process.exit(1);
});
