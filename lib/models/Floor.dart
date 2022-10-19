import 'FloorFrame.dart';

class Floor {
  String name;
  bool selected;
  List<FloorFrame> frames;

  Floor(
    this.name, {
    this.frames = const [],
    this.selected = false,
  });

  bool hasHighlights() {
    for (FloorFrame frame in frames) {
      if (frame.highlights.isNotEmpty) {
        return true;
      }
    }
    return false;
  }
}
