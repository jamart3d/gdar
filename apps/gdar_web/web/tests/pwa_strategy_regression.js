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

function setGlobalProperty(name, value) {
    Object.defineProperty(global, name, {
        configurable: true,
        enumerable: true,
        writable: true,
        value,
    });
}

function resetEngineGlobals() {
    global._gdarAudio = undefined;
    global._hybridAudio = undefined;
    global._hybridHtml5Audio = undefined;
    global._html5Audio = undefined;
    global._passiveAudio = undefined;
    global._shakedownAudioStrategy = undefined;
    global._shakedownAudioReason = undefined;
    global.__mockAudioContextInstances = [];
    global.__mockAudioInstances = [];
    if (typeof global.__resetFetchCalls === 'function') {
        global.__resetFetchCalls();
    }
}

function setPwaEnvironment({
    userAgent,
    hardwareConcurrency,
    maxTouchPoints,
    devicePixelRatio,
    innerWidth,
    standalone,
    navigatorStandalone,
}) {
    setGlobalProperty('navigator', {
        userAgent,
        hardwareConcurrency,
        maxTouchPoints,
        standalone: navigatorStandalone,
        mediaSession: { setActionHandler: () => { }, metadata: {} },
    });

    setGlobalProperty('localStorage', {
        getItem: () => null,
        setItem: () => { },
        removeItem: () => { },
    });

    global.window.devicePixelRatio = devicePixelRatio;
    global.window.innerWidth = innerWidth;
    global.window.matchMedia = (query) => ({
        matches: standalone && query.includes('display-mode: standalone'),
        addListener: () => { },
        removeListener: () => { },
    });
    global.window.location.search = '';
}

function loadEngines() {
    loadScript('gapless_audio_engine.js');
    loadScript('passive_audio_engine.js');
    loadScript('hybrid_html5_engine.js');
    loadScript('hybrid_audio_engine.js');
    loadScript('html5_audio_engine.js');
    loadScript('audio_utils.js');
    loadScript('hybrid_init.js');
}

function runScenario(name, environment, expectedStrategy) {
    resetEngineGlobals();
    setPwaEnvironment(environment);
    loadEngines();

    assert(
        global._shakedownAudioStrategy === expectedStrategy,
        `${name} should default to ${expectedStrategy} strategy`,
    );
    assert(
        global._gdarAudio.engineType === expectedStrategy,
        `${name} should expose ${expectedStrategy} engine type`,
    );
}

function main() {
    runScenario(
        'installed normal Android PWA',
        {
            userAgent:
                'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 ' +
                '(KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
            hardwareConcurrency: 8,
            maxTouchPoints: 5,
            devicePixelRatio: 3,
            innerWidth: 1080,
            standalone: true,
        },
        'hybrid',
    );

    runScenario(
        'installed low-power Android PWA',
        {
            userAgent:
                'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 ' +
                '(KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
            hardwareConcurrency: 2,
            maxTouchPoints: 5,
            devicePixelRatio: 1.5,
            innerWidth: 1080,
            standalone: true,
        },
        'html5',
    );

    runScenario(
        'iOS standalone PWA',
        {
            userAgent:
                'Mozilla/5.0 (iPhone; CPU iPhone OS 17_4 like Mac OS X) ' +
                'AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 ' +
                'Mobile/15E148 Safari/604.1',
            hardwareConcurrency: 8,
            maxTouchPoints: 5,
            devicePixelRatio: 3,
            innerWidth: 390,
            standalone: false,
            navigatorStandalone: true,
        },
        'hybrid',
    );

    process.exit(0);
}

main();
