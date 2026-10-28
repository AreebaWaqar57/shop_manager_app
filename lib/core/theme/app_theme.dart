import 'package:flutter/material.dart';

/// One place for the Material 3 look of the whole app.
class AppTheme {
  AppTheme._();

  static const Color _seed = Colors.indigo;

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorSchemeSeed: _seed,
    brightness: Brightness.light,
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    colorSchemeSeed: _seed,
    brightness: Brightness.dark,
  );
}