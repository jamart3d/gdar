import 'package:flutter_test/flutter_test.dart';
import 'package:shakedown_core/services/buffer_agent_stall_policy.dart';

void main() {
  test('returns 10 seconds for visible web playback', () {
    expect(
      BufferAgentStallPolicy.stallThreshold(
        isWeb: true,
        isAppVisible: true,
      ),
      const Duration(seconds: 10),
    );
  });

  test('returns 20 seconds for hidden web playback', () {
    expect(
      BufferAgentStallPolicy.stallThreshold(
        isWeb: true,
        isAppVisible: false,
      ),
      const Duration(seconds: 20),
    );
  });

  test('returns 20 seconds for visible native playback', () {
    expect(
      BufferAgentStallPolicy.stallThreshold(
        isWeb: false,
        isAppVisible: true,
      ),
      const Duration(seconds: 20),
    );
  });
}
