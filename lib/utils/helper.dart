import 'package:flutter/material.dart';

extension StateSafety on State {
  void setStateSafe(VoidCallback fn) {
    if (!mounted) return;
    // ignore: invalid_use_of_protected_member
    setState(fn);
  }
}
