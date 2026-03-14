import 'package:flutter/foundation.dart';

bool isWasmRuntime() => kIsWasm;
bool isWasmWeb() => kIsWeb && isWasmRuntime();
bool isWasmSafeMode() => isWasmWeb();
