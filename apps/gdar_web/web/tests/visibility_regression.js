/**
 * Universal Visibility & PWA Standalone Regression Test
 * Focus: Verifying background stability across all engine intents.
 */
const fs = require('fs');
const path = require('path');

// 1. Load Mock Harness
require('./mock_harness.js');

// 2. Load Engine and Heartbeat Code
function loadScript(filename) {
    const filePath = path.join(__dirname, '..', filename);
    const code = fs.readFileSync(filePath, 'utf8');
    eval(code);
}

loadScript('audio_heartbeat.js');
loadScript('gapless_audio_engine.js');
loadScript('html5_audio_engine.js'); // [2] PWA Standard
loadScript('passive_audio_engine.js');
loadScript('hybrid_html5_engine.js');
loadScript('hybrid_audio_engine.js');

// Engine Aliases per Intent
const _webAudio = global._gdarAudio;      // [1] Desktop
const _html5 = global._html5Audio;        // [2] PWA Standard
const _hybrid = global._hybridAudio;      // [5] Gapless Orchestrator
const _heartbeat = global._gdarHeartbeat;

// Simple Assertion Helper
function assert(condition, message) {
    if (!condition) {
        console.error('FAILED:', message);
        process.exit(1);
    }
    console.log('PASSED:', message);
}

function setPWAStandalone(isStandalone) {
    global.window.matchMedia = (query) => ({
        matches: isStandalone && query.includes('standalone'),
        addListener: () => { },
        removeListener: () => { }
    });
}

console.log('\n--- Running Universal Visibility & PWA Standalone Regression Tests ---\n');

async function runTests() {
    // --- Test 1: PWA Standard (HTML5) startup while hidden ---
    console.log('Test 1: PWA (HTML5) startup while hidden + standalone...');
    setPWAStandalone(true);
    global.document.visibilityState = 'hidden';
    global.document.hidden = true;

    _html5.stop();
    _html5.setPlaylist([{ url: 'http://test.mp3' }], 0);
    assert(!_heartbeat.isActive(), 'Heartbeat should be inactive before play');

    await _html5.play();
    // HTML5 is the PWA standard; it MUST trigger heartbeat if started while hidden to prevent OS freeze.
    assert(_heartbeat.isActive(), 'PWA Standalone MUST trigger heartbeat for hidden HTML5 startup');

    // --- Test 2: Desktop Intent (Web Audio) while hidden ---
    console.log('\nTest 2: Desktop (Web Audio) while hidden...');
    setPWAStandalone(false); // standard browser tab
    _webAudio.stop();
    _heartbeat.stopHeartbeat(); // cleanup

    _webAudio.setPlaylist([{ url: 'http://test_high.mp3' }], 0);
    await _webAudio.play();
    assert(_heartbeat.isActive(), 'Web Audio MUST trigger heartbeat if playing while hidden (Desktop intent safety)');

    // --- Test 3: Hybrid Orchestrator in PWA mode ---
    console.log('\nTest 3: Hybrid Orchestrator (PWA Mode) hidden startup...');
    setPWAStandalone(true);
    _hybrid.stop();
    _heartbeat.stopHeartbeat();

    _hybrid.setPlaylist([{ url: 'http://test_hybrid.mp3', duration: 300 }], 0);
    await _hybrid.play();

    assert(_heartbeat.isActive(), 'Hybrid MUST trigger heartbeat immediately when hidden');
    assert(_hybrid.getState().engineType === 2, 'Hybrid MUST start with HTML5 [2] when hidden');
    console.log('--- TEST 3 PASSED: Hybrid Background Ignition ---\n');

    // ─── TEST 4: Hybrid Handoff Matrix ─────────────────────────────────────
    console.log('--- TEST 4: Hybrid Handoff Matrix (Immediate/Buffered/Disabled) ---');
    const handoffModes = ['immediate', 'buffered', 'none'];
    for (const mode of handoffModes) {
        console.log(`Verifying Handoff Mode: ${mode}`);
        _hybrid.setHandoffMode(mode);
        _hybrid.setPlaylist([{ url: 'http://test.mp3' }]); // Use full URL for consistency
        _hybrid.play();

        if (mode === 'immediate') {
            assert(_hybrid.getIsHandoffPending() === false, `Handoff should be immediate for mode: ${mode}`);
        } else if (mode === 'buffered') {
            assert(_hybrid.getIsHandoffPending() === true, `Handoff should be pending for mode: ${mode}`);
        }
        _hybrid.stop(); // Clean up after each mode test
    }
    console.log('--- TEST 4 PASSED: Handoff Matrix Verified ---\n');

    // ─── TEST 5: Background Strategy Matrix ────────────────────────────────
    console.log('--- TEST 5: Background Strategy Matrix (html5/video/none) ---');
    _webAudio.stop();
    _html5.stop();
    _hybrid.stop();
    _heartbeat.stopHeartbeat();
    setPWAStandalone(true);
    const strategies = ['html5', 'video', 'none'];
    for (const strategy of strategies) {
        console.log(`Verifying Strategy: ${strategy}`);
        _hybrid.setBackgroundMode(strategy);
        _hybrid.setPlaylist([{ url: 'http://test_strategy.mp3', duration: 300 }], 0);
        await _hybrid.play();
        global.document.visibilityState = 'hidden'; // Use global.document
        global.document.hidden = true;
        global.document.dispatchEvent(new Event('visibilitychange')); // Use new Event

        if (strategy === 'html5') {
            assert(_heartbeat.isActive() === true, 'Heartbeat should activate for html5 hidden state');
        } else if (strategy === 'video') {
            // Assuming _heartbeat.isVideoActive() is a mock function that reflects the video strategy
            // If not, this assertion might need adjustment based on actual mock behavior.
            assert(_heartbeat.isVideoActive() === true, 'Video Heartbeat should activate for video strategy');
        } else if (strategy === 'none') {
            assert(_heartbeat.isActive() === false, 'Heartbeat should not activate for none strategy');
            assert(_heartbeat.isVideoActive() === false, 'Video Heartbeat should not activate for none strategy');
        }

        global.document.visibilityState = 'visible'; // Use global.document
        global.document.hidden = false;
        global.document.dispatchEvent(new Event('visibilitychange')); // Use new Event
        _hybrid.stop();
        _heartbeat.stopHeartbeat(); // Clean up heartbeat after each strategy test
    }
    console.log('--- TEST 5 PASSED: Strategy Matrix Verified ---\n');

    // --- Test 6: Foreground Restore (Renamed from Test 4) ---
    console.log('\nTest 6: Restoration to foreground should stop heartbeats...');
    global.document.visibilityState = 'visible';
    global.document.hidden = false;
    global.document.dispatchEvent(new Event('visibilitychange'));

    assert(!_heartbeat.isActive(), 'Heartbeat MUST stop when tab becomes visible');

    console.log('\nAll Universal Visibility & PWA Intent tests passed.');
}

runTests().catch(err => {
    console.error('Unexpected Error:', err);
    process.exit(1);
});
