import 'package:flutter/foundation.dart';

class Highlight {
  String id;
  Uint8List data;
  bool hover;
  String name;
  int level;
  Uint8List? plan;

  Highlight({
    required this.id,
    this.hover = false,
    required this.data,
    required this.level,
    required this.name,
    this.plan,
  });
}
