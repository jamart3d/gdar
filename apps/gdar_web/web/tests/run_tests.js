/**
 * Regression Tests for Audio Engines
 */
const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');

function assert(condition, message) {
    if (!condition) {
        throw new Error(message);
    }
    console.log('PASSED:', message);
}

function runStandalone(scriptName) {
    console.log(`\n--- Running ${scriptName} ---\n`);
    const result = spawnSync(
        process.execPath,
        [path.join(__dirname, scriptName)],
        { stdio: 'inherit' },
    );

    assert(
        result.status === 0,
        `${scriptName} should exit successfully`,
    );
}

function loadEngine(filename) {
    const filePath = path.join(__dirname, '..', filename);
    const code = fs.readFileSync(filePath, 'utf8');
    eval(code);
}

function wait(ms) {
    return new Promise((resolve) => setTimeout(resolve, ms));
}

require('./mock_harness.js');

loadEngine('gapless_audio_engine.js');
loadEngine('passive_audio_engine.js');
loadEngine('hybrid_html5_engine.js');
loadEngine('hybrid_audio_engine.js');
loadEngine('html5_audio_engine.js');

const gaplessEngine = global._gdarAudio;
const hybridHtml5Engine = global._hybridHtml5Audio;
const hybridEngine = global._hybridAudio;
const html5Engine = global._html5Audio;

async function testPauseResumeMath(engineName, engineObj) {
    if (global.__mockAudioContextInstances) {
        global.__mockAudioContextInstances.forEach((ctx) => {
            ctx.currentTime += 1;
        });
    }

    engineObj.stop();
    engineObj.setPlaylist([{ url: 'http://test.mp3', duration: 300 }], 0);
    engineObj.play();

    await wait(250);

    if (!global.__mockAudioContextInstances) {
        console.log(
            `Test warning: __mockAudioContextInstances not found. Skipping ${engineName}.`,
        );
        return;
    }

    global.__mockAudioContextInstances.forEach((ctx) => {
        ctx.currentTime += 10;
    });

    const stateWhilePlaying = engineObj.getState();
    console.log(`${engineName} state while playing:`, stateWhilePlaying);
    assert(
        stateWhilePlaying.position >= 10,
        `${engineName} position should increment during playback`,
    );

    engineObj.pause();
    await wait(50);

    global.__mockAudioContextInstances.forEach((ctx) => {
        ctx.currentTime += 5;
    });

    const stateWhilePaused = engineObj.getState();
    console.log(`${engineName} state while paused:`, stateWhilePaused);
    assert(
        Math.abs(stateWhilePaused.position - stateWhilePlaying.position) < 0.1,
        `${engineName} position should freeze when paused`,
    );

    engineObj.play();
    await wait(50);

    const stateAfterResume = engineObj.getState();
    assert(
        Math.abs(stateAfterResume.position - stateWhilePlaying.position) < 0.1,
        `${engineName} position should resume from the paused position`,
    );

    console.log(`DONE: ${engineName} pause/resume math verification passed.`);
}

async function main() {
    runStandalone('stalled_progress_regression.js');
    runStandalone('visible_stalled_progress_regression.js');
    runStandalone('webaudio_resume_position_regression.js');
    runStandalone('append_tracks_regression.js');

    console.log('\n--- Running Hybrid Engine Regression Tests ---\n');

    let html5Synced = false;
    const originalHybridHtml5SyncState = hybridHtml5Engine.syncState;
    hybridHtml5Engine.syncState = (index, position, shouldPlay) => {
        html5Synced = true;
        assert(
            shouldPlay === true,
            'hybrid HTML5 engine should be started with play=true during handoff',
        );
        return originalHybridHtml5SyncState.call(
            hybridHtml5Engine,
            index,
            position,
            shouldPlay,
        );
    };

    hybridEngine.stop();
    hybridEngine.setPlaylist([{ url: 'http://test.mp3', duration: 300 }], 0);
    hybridEngine.play();
    hybridEngine.seekToIndex(0);

    assert(
        html5Synced === true,
        'hybrid engine should sync background HTML5 state during seekToIndex',
    );

    hybridHtml5Engine.syncState = originalHybridHtml5SyncState;
    hybridEngine.pause();

    console.log('DONE: Hybrid Engine basic sync verification passed.');

    console.log('\n--- Running Gapless Engine Regression Tests ---\n');

    gaplessEngine.stop();
    gaplessEngine.setPlaylist([{ url: 'http://test.mp3', duration: 300 }], 0);
    gaplessEngine.play();
    gaplessEngine.play();

    assert(
        gaplessEngine.getState().playing === true,
        'gapless engine should remain in playing state after redundant play()',
    );

    console.log('DONE: Gapless Engine basic guard verification passed.');

    console.log('\n--- Running Pause/Resume Math Tests ---\n');

    html5Engine.init();

    await testPauseResumeMath('HTML5 Engine', html5Engine);
    await testPauseResumeMath('Gapless Engine', gaplessEngine);
    await testPauseResumeMath('Hybrid Engine', hybridEngine);

    console.log('\nAll tests passing!');
    process.exit(0);
}

main().catch((error) => {
    console.error('FAILED:', error && error.stack ? error.stack : error);
    process.exit(1);
});
