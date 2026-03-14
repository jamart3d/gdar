import 'package:flutter/cupertino.dart';

class FruitActivityIndicator extends StatelessWidget {
  final double radius;
  final Color? color;

  const FruitActivityIndicator({
    super.key,
    this.radius = 10.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoActivityIndicator(
      radius: radius,
      color: color,
    );
  }
}
