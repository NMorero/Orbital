import 'package:flutter/foundation.dart';
import 'package:orbital/models/Highlight.dart';

class FloorFrame {
  Uint8List render;
  Uint8List? mask;

  List<Highlight> highlights;

  FloorFrame({
    required this.highlights,
    this.mask,
    required this.render,
  });
}
