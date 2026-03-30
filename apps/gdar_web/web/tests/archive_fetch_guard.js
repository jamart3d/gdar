const fs = require('fs');
const path = require('path');

require('./mock_harness.js');

function loadEngine(filename) {
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

const archiveTrack = {
    url: 'https://archive.org/download/gd1995-07-08.167438.matrix.davis.flac1648/08%20Eternity.mp3',
    duration: 300,
};

loadEngine('gapless_audio_engine.js');
loadEngine('audio_heartbeat.js');
loadEngine('hybrid_html5_engine.js');
loadEngine('hybrid_audio_engine.js');

const gapless = global._gdarAudio;
const hybridHtml5 = global._hybridHtml5Audio;
const hybrid = global._hybridAudio;

global._gdarIsHeartbeatNeeded = () => false;
global._gdarScheduler = { start() { } };
global._gdarMediaSession = {
    setActionHandlers() { },
    updatePlaybackState() { },
    updatePositionState() { },
    updateMetadata() { },
    forceSync() { },
};

async function main() {
    if (global.__resetFetchCalls) global.__resetFetchCalls();

    gapless.stop();
    gapless.setPlaylist([archiveTrack], 0);

    let blocked = false;
    try {
        await gapless.prepareToPlay(0);
    } catch (err) {
        blocked = /cors|blocked/i.test(String(err && err.message));
    }

    assert(blocked, 'Gapless engine rejects archive WebAudio prep before fetch.');
    assert(global.__fetchCalls.length === 0,
        'Gapless engine does not issue fetch() for archive WebAudio decode.');

    if (global.__resetFetchCalls) global.__resetFetchCalls();

    hybridHtml5.stop();
    hybridHtml5.setPlaylist([archiveTrack], 0);
    hybridHtml5.play();

    await new Promise(resolve => setTimeout(resolve, 25));

    assert(global.__fetchCalls.length === 0,
        'Hybrid HTML5 worker does not issue HEAD/fetch decode for archive tracks.');

    let hybridErrors = 0;
    hybrid.onError(() => {
        hybridErrors += 1;
    });

    hybrid.stop();
    hybrid.setPlaylist([archiveTrack, archiveTrack], 0);
    hybrid.play();

    await new Promise(resolve => setTimeout(resolve, 25));

    hybridHtml5.seekToIndex(1);
    await new Promise(resolve => setTimeout(resolve, 150));

    const hybridState = hybrid.getState();
    assert(hybridErrors === 0,
        'Hybrid boundary restore keeps archive track changes on HTML5 without surfacing playback errors.');
    assert(hybridState.playing === true && hybridState.index === 1,
        'Hybrid continues playback after archive track boundary restore fallback.');

    console.log('All archive fetch guard tests passing.');
    process.exit(0);
}

main().catch((err) => {
    console.error(err);
    process.exit(1);
});
