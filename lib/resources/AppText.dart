import 'package:flutter/material.dart';

class AppText {
  static const TextStyle baseText = TextStyle(
    color: Colors.white, // Common white color
    fontWeight: FontWeight.bold,
  );

  static TextStyle mainText = baseText.copyWith(
    fontSize: 27,
  );

  static TextStyle secondaryText = baseText.copyWith(
    fontSize: 20,
  );
}
