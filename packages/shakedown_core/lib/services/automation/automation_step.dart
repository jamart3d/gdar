enum AutomationStepType { playRandomShow, sleep, setSetting, launchScreensaver }

class AutomationStep {
  final AutomationStepType type;
  final int? seconds;
  final String? key;
  final String? value;

  const AutomationStep._({
    required this.type,
    this.seconds,
    this.key,
    this.value,
  });

  const AutomationStep.playRandomShow()
    : this._(type: AutomationStepType.playRandomShow);

  const AutomationStep.sleep({required int seconds})
    : this._(type: AutomationStepType.sleep, seconds: seconds);

  const AutomationStep.setSetting({required String key, required String value})
    : this._(type: AutomationStepType.setSetting, key: key, value: value);

  const AutomationStep.launchScreensaver()
    : this._(type: AutomationStepType.launchScreensaver);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AutomationStep &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          seconds == other.seconds &&
          key == other.key &&
          value == other.value;

  @override
  int get hashCode =>
      type.hashCode ^ seconds.hashCode ^ key.hashCode ^ value.hashCode;
}
