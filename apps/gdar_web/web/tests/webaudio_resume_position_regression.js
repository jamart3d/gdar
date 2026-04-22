/**
 * Regression: a WebAudio-promoted HTML5 track must keep reporting advancing
 * position after pause -> play. The audible buffer source can resume while
 * stale pause bookkeeping freezes currentTime at the JS layer.
 */
const fs = require('fs');
const path = require('path');

require('./mock_harness.js');

function loadScript(filename) {
    const filePath = path.join(__dirname, '..', filename);
    const code = fs.readFileSync(filePath, 'utf8');
    eval(code);
}

function assert(condition, message) {
    if (!condition) {
        console.error('FAILED:', message);
        process.exit(1);
    }
    console.log('PASSED:', message);
}

function wait(ms) {
    return new Promise((resolve) => setTimeout(resolve, ms));
}

async function expectResumePositionAdvances(engineName, engine) {
    engine.setPlaylist([{ url: 'http://test.mp3', duration: 300 }], 0);
    engine.play();
    await wait(20);

    global.__advanceMockPlayback(5);
    await wait(20);

    const beforePause = engine.getState().position;
    assert(beforePause >= 5, `${engineName} should advance before pause`);

    engine.pause();
    global.__advanceMockPlayback(3);
    await wait(20);

    const whilePaused = engine.getState().position;
    assert(
        Math.abs(whilePaused - beforePause) < 0.1,
        `${engineName} should freeze while paused`,
    );

    engine.play();
    await wait(20);
    global.__advanceMockPlayback(4);
    await wait(20);

    const afterResume = engine.getState().position;
    assert(
        afterResume > whilePaused + 3.5,
        `${engineName} should advance after resume`,
    );
}

async function run() {
    loadScript('audio_heartbeat.js');
    loadScript('audio_scheduler.js');
    loadScript('html5_audio_engine.js');
    loadScript('hybrid_html5_engine.js');

    await expectResumePositionAdvances('html5', global._html5Audio);
    await expectResumePositionAdvances('hybrid-html5', global._hybridHtml5Audio);

    process.exit(0);
}

run().catch((error) => {
    console.error(error);
    process.exit(1);
});
