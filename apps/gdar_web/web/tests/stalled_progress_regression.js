/**
 * Regression: active engine position continues moving, but Dart-facing
 * state callbacks stop until a manual playlist reset.
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
loadScript('gapless_audio_engine.js');
loadScript('html5_audio_engine.js');
loadScript('hybrid_html5_engine.js');
loadScript('hybrid_audio_engine.js');

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

    engine.onStateChange(() => {
        callbackCount += 1;
    });

    engine.setPlaylist([{ url: 'http://test.mp3', duration: 300 }], 0);
    await engine.play();
    engine.seek(0);
    await flushTicks();

    global.__advanceMockPlayback(10);
    await flushTicks();
    const beforeFreeze = engine.getState().position;
    assert(beforeFreeze > 0, 'engine state should advance before freeze');

    global.__suspendStateCallbacks(true);
    global.__advanceMockPlayback(5);
    await flushTicks();
    const afterFreeze = engine.getState().position;

    assert(
        afterFreeze > beforeFreeze,
        'engine state should still advance while callbacks are frozen',
    );
    assert(callbackCount > 0, 'state callback should have emitted before freeze');

    console.log({
        engineType: engine.engineType,
        state: engine.getState(),
    });

    global.__resumeStateCallbacks();
    global.document.visibilityState = 'visible';
    global.document.hidden = false;
    global.document.dispatchEvent(new Event('visibilitychange'));

    setTimeout(() => {
        assert(
            callbackCount > 1,
            'visibility restore should cause a fresh state emission',
        );
        process.exit(0);
    }, 0);
}

run().catch((error) => {
    console.error(error);
    process.exit(1);
});
