import 'dart:ui' as ui;

import 'package:shakedown_core/steal_screensaver/steal_config.dart';

void applyStealShaderUniforms({
  required ui.FragmentShader shader,
  required ui.Size size,
  required double time,
  required StealConfig config,
  required double effectiveLogoScale,
  required ui.Offset renderedLogoPos,
  required double scaleEnergy,
  required double midEnergy,
  required double colorEnergy,
  required double overallEnergy,
  required List<ui.Color> colors,
  required ui.Image logoTexture,
}) {
  var idx = 0;
  final sw = size.width.clamp(1.0, 20000.0);
  final sh = size.height.clamp(1.0, 20000.0);
  shader.setFloat(idx++, sw);
  shader.setFloat(idx++, sh);
  shader.setFloat(idx++, time);
  shader.setFloat(idx++, config.flowSpeed.clamp(0.0, 5.0));
  shader.setFloat(idx++, 0.0);
  shader.setFloat(idx++, config.pulseIntensity.clamp(0.0, 5.0));
  shader.setFloat(idx++, config.heatDrift.clamp(0.0, 5.0));
  shader.setFloat(idx++, effectiveLogoScale);
  shader.setFloat(idx++, config.blurAmount.clamp(0.0, 1.0));
  shader.setFloat(idx++, config.flatColor ? 1.0 : 0.0);
  shader.setFloat(idx++, config.logoAntiAlias ? 1.0 : 0.0);
  shader.setFloat(idx++, config.performanceLevel.toDouble());
  shader.setFloat(idx++, renderedLogoPos.dx);
  shader.setFloat(idx++, renderedLogoPos.dy);
  shader.setFloat(idx++, scaleEnergy.clamp(0.0, 5.0));
  shader.setFloat(idx++, midEnergy.clamp(0.0, 5.0));
  shader.setFloat(idx++, colorEnergy.clamp(0.0, 5.0));
  shader.setFloat(idx++, overallEnergy.clamp(0.0, 5.0));

  for (final color in colors) {
    shader.setFloat(idx++, color.r);
    shader.setFloat(idx++, color.g);
    shader.setFloat(idx++, color.b);
  }

  shader.setImageSampler(0, logoTexture);
}
