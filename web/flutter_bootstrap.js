{{flutter_js}}
{{flutter_build_config}}

(async () => {
  try {
    await _flutter.loader.load({
      serviceWorkerSettings: {
        serviceWorkerVersion: {{flutter_service_worker_version}},
      },
      config: {
        renderer: "canvaskit",
      },
    });
  } catch (e) {
    console.warn('[Bootstrap] CanvasKit renderer unavailable, falling back.', e);
    await _flutter.loader.load({
      serviceWorkerSettings: {
        serviceWorkerVersion: {{flutter_service_worker_version}},
      },
    });
  }
})();
