import 'package:flutter/services.dart';

void main() {
  final event = KeyRepeatEvent(
    physicalKey: PhysicalKeyboardKey.keyA,
    logicalKey: LogicalKeyboardKey.keyA,
    timeStamp: Duration.zero,
  );
  print(event.runtimeType == KeyRepeatEvent);
}
