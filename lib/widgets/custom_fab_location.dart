import 'package:flutter/material.dart';

/// Custom FloatingActionButtonLocation that positions the FAB
/// cleanly above the custom floating bottom navigation bar.
class FloatingAboveBarFabLocation extends FloatingActionButtonLocation {
  final double bottomOffset;
  final double rightOffset;

  const FloatingAboveBarFabLocation({
    this.bottomOffset = 96.0,
    this.rightOffset = 20.0,
  });

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final double fabX = scaffoldGeometry.scaffoldSize.width -
        scaffoldGeometry.floatingActionButtonSize.width -
        rightOffset;
    final double fabY = scaffoldGeometry.scaffoldSize.height -
        scaffoldGeometry.floatingActionButtonSize.height -
        bottomOffset;
    return Offset(fabX, fabY);
  }
}

