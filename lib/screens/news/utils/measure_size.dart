import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class RenderMeasureSize extends RenderProxyBox {
  RenderMeasureSize(this.onChange);
  ValueChanged<Size> onChange;
  Size? _old;

  @override
  void performLayout() {
    super.performLayout();
    final newSize = child?.size ?? Size.zero;
    if (_old == newSize) return;
    _old = newSize;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onChange(newSize);
    });
  }
}

class MeasureSize extends SingleChildRenderObjectWidget {
  final ValueChanged<Size> onChange;

  const MeasureSize({super.key, required this.onChange, required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderMeasureSize(onChange);

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderMeasureSize renderObject,
  ) {
    renderObject.onChange = onChange;
  }
}
