# Widget Test Surface Sizes

In widget tests that involve complex visual layers (gradients, glows, shaders, or custom painters) inside `RenderFlex` widgets (e.g., `ShowListCard`), the default `WidgetTester` surface size is often too small to accommodate the expanded dimensions.

### 🛡️ Rule
To prevent `computeSize` layout contract failures and `RenderFlex` overflows during test execution:

1. Always explicitly set a larger physical size in the test `setUp` or at the start of the `testWidgets` block.
2. Recommended size: `const Size(1000, 1000)`.
3. Use `addTearDown` to reset the view size if the suite contains non-visual tests.

```dart
testWidgets('visual state verification', (tester) async {
  tester.view.physicalSize = const Size(1000, 1000);
  addTearDown(tester.view.resetPhysicalSize);

  // ... build and pump ...
});
```
