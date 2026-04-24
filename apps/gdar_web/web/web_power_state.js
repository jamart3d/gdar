(function () {
    'use strict';

    const _log = (window._gdarLogger || console);
    let _battery = null;
    let _charging = null;
    let _ready = false;
    let _readyPromise = null;
    let _readyResolve = null;

    function _emit() {
        try {
            window.dispatchEvent(new CustomEvent('gdar-power-state-change', {
                detail: {
                    charging: _charging,
                },
            }));
        } catch (_) {
            // CustomEvent may be unavailable in some environments.
        }
    }

    function _markReady() {
        if (_ready) return;
        _ready = true;
        if (_readyResolve) {
            _readyResolve(_charging);
            _readyResolve = null;
        }
    }

    function _ensureReadyPromise() {
        if (_readyPromise) {
            return _readyPromise;
        }

        _readyPromise = new Promise((resolve) => {
            _readyResolve = resolve;
            if (_ready) {
                _readyResolve(_charging);
                _readyResolve = null;
            }
        });

        return _readyPromise;
    }

    function _syncFromBattery() {
        if (!_battery) return;
        _charging = !!_battery.charging;
        _emit();
    }

    function _attachBatteryListeners(battery) {
        if (!battery || typeof battery.addEventListener !== 'function') {
            return;
        }
        battery.addEventListener('chargingchange', _syncFromBattery);
    }

    const api = {
        init: function () {
            _ensureReadyPromise();

            if (!navigator.getBattery) {
                _charging = null;
                _log.log(
                    '[power] Battery Status API unavailable; using battery-safe profile.');
                _emit();
                _markReady();
                return;
            }

            try {
                navigator.getBattery().then((battery) => {
                    _battery = battery;
                    _syncFromBattery();
                    _attachBatteryListeners(battery);
                    _markReady();
                }).catch((err) => {
                    _charging = null;
                    _log.warn('[power] Battery Status API failed:',
                        err && err.message);
                    _emit();
                    _markReady();
                });
            } catch (err) {
                _charging = null;
                _log.warn('[power] Battery Status API failed:',
                    err && err.message);
                _emit();
                _markReady();
            }
        },

        getCharging: function () {
            return _charging;
        },

        whenReady: function () {
            return _ensureReadyPromise();
        },
    };

    window._gdarPowerState = api;
    api.init();
})();
