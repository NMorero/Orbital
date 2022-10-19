import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_pixels/image_pixels.dart';
import 'package:orbital/globals.dart';
import 'package:orbital/models/Floor.dart';
import 'package:orbital/models/Highlight.dart';

import 'models/HighlightLevel.dart';

class FloorVisualizer extends StatefulWidget {
  FloorVisualizer(
    this._floor,
    this._appBarHeight,
    this._highlightsLabels,
    this._activeLevels, {
    Key? key,
  }) : super(key: key);

  final Floor _floor;
  final double _appBarHeight;
  final List<String> _highlightsLabels;
  List<HighlightLevel> _activeLevels;

  @override
  State<FloorVisualizer> createState() => _FloorVisualizerState();
}

class _FloorVisualizerState extends State<FloorVisualizer> {
  int _frameIndex = 0;
  bool _pointerDown = false;
  Offset _pointerPosition = const Offset(0, 0);
  Offset _prevPointerPosition = const Offset(0, 0);
  GlobalKey imageKey = GlobalKey();
  Color _color = Colors.white;
  Highlight? _selectedHighlight;

  final GlobalKey _maskImageKey = GlobalKey();

  void _togglePointer(bool status) {
    setState(() {
      _pointerDown = status;
    });
  }

  bool _checkLevelActive(int levelToCheck) {
    if (widget._activeLevels.isEmpty) return false;
    for (HighlightLevel level in widget._activeLevels) {
      if (levelToCheck == level.level) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    Uint8List? mask = widget._floor.frames[_frameIndex].mask;
    ImageProvider? _maskImage;

    if (mask != null) {
      _maskImage = MemoryImage(mask);
    }

    return Listener(
      onPointerDown: (e) => _togglePointer(true),
      onPointerUp: (e) => _togglePointer(false),
      onPointerMove: (e) {
        if (_pointerDown) {
          if (e.position.dx < _prevPointerPosition.dx - 50) {
            if (_frameIndex == 0) {
              _frameIndex = widget._floor.frames.length - 1;
            } else {
              _frameIndex--;
            }
            _prevPointerPosition = e.position;
          } else if (e.position.dx > _prevPointerPosition.dx + 50) {
            if (_frameIndex == widget._floor.frames.length - 1) {
              _frameIndex = 0;
            } else {
              _frameIndex++;
            }
            _prevPointerPosition = e.position;
          }
        }

        setState(() {});
      },
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            child: Image.memory(
              widget._floor.frames[_frameIndex].render,
              gaplessPlayback: true,
              height: MediaQuery.of(context).size.height - widget._appBarHeight,
            ),
          ),
          for (Highlight highlight in widget._floor.frames[_frameIndex].highlights)
            Positioned(
              top: 0,
              left: 0,
              child: Opacity(
                opacity: _checkLevelActive(highlight.level)
                    ? highlight.hover
                        ? 1.0
                        : 0.5
                    : 0.0,
                child: Image.memory(
                  highlight.data,
                  height: MediaQuery.of(context).size.height - widget._appBarHeight,
                  gaplessPlayback: true,
                ),
              ),
            ),
          Positioned(
            top: 0,
            left: 0,
            child: MouseRegion(
              onHover: (e) {
                setState(() {
                  _pointerPosition = e.position - Offset(0, 56);
                });
              },
              child: mask != null
                  ? SizedBox(
                      key: _maskImageKey,
                      child: ImagePixels(
                        imageProvider: _maskImage,
                        builder: (BuildContext context, ImgDetails img) {
                          try {
                            final RenderBox maskRenderBox = _maskImageKey.currentContext?.findRenderObject() as RenderBox;
                            double scale = maskRenderBox.size.width / img.width!.toInt();

                            _color = img.pixelColorAt!(_pointerPosition.dx ~/ scale, _pointerPosition.dy ~/ scale);
                            String id = "";
                            if (_color.value.toRadixString(16) == "ff78cb2e") {
                              id = "01";
                            } else if (_color.value.toRadixString(16) == "ffb64c27") {
                              id = "02";
                            } else if (_color.value.toRadixString(16) == "ffb52779") {
                              id = "03";
                            } else if (_color.value.toRadixString(16) == "ffb37ae9") {
                              id = "04";
                            } else if (_color.value.toRadixString(16) == "ff00a37b") {
                              id = "05";
                            } else if (_color.value.toRadixString(16) == "ffd5d853") {
                              id = "06";
                            } else if (_color.value.toRadixString(16) == "ff00c8d5") {
                              id = "07";
                            }
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (!_pointerDown) {
                                for (Highlight highlight in widget._floor.frames[_frameIndex].highlights) {
                                  if (highlight.id == id) {
                                    print(id);
                                    setState(() {
                                      _selectedHighlight = highlight;
                                    });

                                    highlight.hover = true;
                                  } else {
                                    highlight.hover = false;
                                  }
                                }

                                if (id == "") {
                                  _selectedHighlight = null;
                                }
                              }
                            });
                          } catch (e) {}

                          return Opacity(
                            opacity: 0.0,
                            child: Image.memory(
                              mask,
                              gaplessPlayback: true,
                              height: MediaQuery.of(context).size.height - widget._appBarHeight,
                            ),
                          );
                        },
                      ),
                    )
                  : Center(),
            ),
          ),
          if (_selectedHighlight != null)
            Positioned(
              top: _pointerPosition.dy - 80,
              left: _pointerPosition.dx - 50,
              child: MouseRegion(
                onExit: (e) {
                  setState(() {
                    _selectedHighlight = null;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(color: CC.white(), borderRadius: BorderRadius.all(Radius.circular(10))),
                  height: 50,
                  width: 200,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Container(
                        height: 20,
                        width: 20,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(
                            Radius.circular(50),
                          ),
                          color: widget._activeLevels.firstWhere((element) => element.level == _selectedHighlight!.level).color,
                        ),
                      ),
                      Text(_selectedHighlight!.name),
                      Container(
                        padding: EdgeInsets.all(5),
                        decoration: BoxDecoration(color: CC.success(), borderRadius: BorderRadius.all(Radius.circular(10))),
                        child: Text("DISPONIBLE"),
                      )
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
