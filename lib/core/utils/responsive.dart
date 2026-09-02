import 'package:flutter/material.dart';

class Responsive {
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 900;
  }
}

bool isMobile(BuildContext context) {
  return MediaQuery.of(context).size.width < 900;
}
