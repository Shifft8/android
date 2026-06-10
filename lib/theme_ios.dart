import 'package:flutter/cupertino.dart';

class IOSTheme {
  static const Color primaryColor = CupertinoColors.systemBlue;
  static const Color backgroundColor = CupertinoColors.systemBackground;
  static const Color secondaryBackground = CupertinoColors.secondarySystemBackground;

  static const TextStyle titleStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: CupertinoColors.label,
    fontFamily: '.SF Pro Display',
  );

  static const TextStyle bodyStyle = TextStyle(
    fontSize: 16,
    color: CupertinoColors.label,
    fontFamily: '.SF Pro Text',
  );

  static const TextStyle secondaryStyle = TextStyle(
    fontSize: 14,
    color: CupertinoColors.secondaryLabel,
    fontFamily: '.SF Pro Text',
  );
}
