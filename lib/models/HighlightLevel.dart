import "package:flutter/material.dart";

class HighlightLevel {
  int level;
  Color color;
  bool active;

  HighlightLevel(
    this.level,
    this.color, {
    this.active = true,
  });
}
