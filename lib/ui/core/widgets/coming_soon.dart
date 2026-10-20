import 'package:flutter/material.dart';

/// Placeholder action for buttons whose feature arrives in a later lab.
void showComingSoon(BuildContext context, String feature) {
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text('$feature: coming in a later lab')));
}
