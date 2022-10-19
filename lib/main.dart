import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:orbital/globals.dart';
import 'package:orbital/models/FloorFrame.dart';
import 'package:orbital/models/Highlight.dart';
import 'package:orbital/models/HighlightLevel.dart';

import 'FloorVisualizer.dart';
import 'models/Floor.dart';

void main() {
  runApp(const OrbitalApp());
}

class OrbitalApp extends StatelessWidget {
  const OrbitalApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Orbital App',
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Floor> _floors = [];
  List<String> _floorsLabels = [];
  List<String> _highlightsLabels = [];
  final List<HighlightLevel> _highlightLevels = [
    HighlightLevel(
      1,
      const Color.fromRGBO(228, 236, 117, 1),
    ),
    HighlightLevel(
      2,
      const Color.fromRGBO(106, 106, 103, 1.0),
    ),
    HighlightLevel(
      3,
      const Color.fromRGBO(115, 165, 115, 1),
    ),
    HighlightLevel(
      4,
      const Color.fromRGBO(255, 155, 172, 1),
    ),
  ];
  String? _selectedFloor;
  double _loadingProgress = 0.0;

  Future _initImages() async {
    // final dir = Directory('${Directory.current.path}/assets/floors');
    // final List<FileSystemEntity> entities = await dir.list(recursive: true).toList();
    // print(entities);

    List<Floor> floors = [];
    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifestMap = json.decode(manifestContent);

    final floorPaths = manifestMap.keys.where((String key) => key.contains('/floors')).toList();

    final List<String> floorsLabels = [];
    for (String path in floorPaths) {
      if (!floorsLabels.contains(path.split("/")[2])) {
        floorsLabels.add(path.split("/")[2]);
      }
    }
    final List<String> highlightsLabels = [];
    final highlightsPaths = manifestMap.keys.where((String key) => key.contains('/highlights')).toList();
    for (String path in highlightsPaths) {
      if (!highlightsLabels.contains(path.split("/").last.split("_")[0])) {
        highlightsLabels.add(path.split("/").last.split("_")[0]);
      }
    }
    double percentageByFloor = 100 / floorsLabels.length;
    var jsonText = await rootBundle.loadString('assets/resources/data.json');
    Map<String, dynamic> allUnits = json.decode(jsonText);
    for (String floor in floorsLabels) {
      Map<String, dynamic>? units = allUnits[floor];
      Floor newFloor = Floor(floor);
      List<FloorFrame> frames = [];

      final floorFiles = manifestMap.keys.where((String key) => key.contains(floor)).toList();
      final rendersPaths = floorFiles.where((String key) => key.contains('renders')).toList();
      final masksPaths = floorFiles.where((String key) => key.contains('masks')).toList();
      final highlightsPaths = floorFiles.where((String key) => key.contains('highlights')).toList();
      final plansPaths = floorFiles.where((String key) => key.contains('plans')).toList();
      double percentageByRender = percentageByFloor / rendersPaths.length;

      for (String render in rendersPaths) {
        List<String> renderPathSplit = render.split("/");
        String? maskPath;
        ByteData? maskData;
        Uint8List? maskDataBytes;
        if (masksPaths.isNotEmpty) {
          maskPath = masksPaths.firstWhere((String key) => key.contains(renderPathSplit.last.replaceFirst(".jpg", "")), orElse: () => 'null');

          maskData = await rootBundle.load(maskPath);
          maskDataBytes = maskData.buffer.asUint8List();
        }
        List<String> renderHighlights = highlightsPaths.where((String key) => key.contains(renderPathSplit.last.replaceFirst(".jpg", ""))).toList();
        ByteData renderData = await rootBundle.load(render);
        Uint8List renderDataBytes = renderData.buffer.asUint8List();
        List<Highlight> highlights = [];
        for (String highlight in renderHighlights) {
          ByteData highlightData = await rootBundle.load(highlight);
          Uint8List highlightDataBytes = highlightData.buffer.asUint8List();
          String highlightId = highlight.split("/").last.split("_")[0];
          List<String> planPath = plansPaths.where((element) => element.startsWith(highlightId)).toList();
          Uint8List? planDataBytes;
          if (planPath.isNotEmpty) {
            ByteData planData = await rootBundle.load(planPath[0]);
            planDataBytes = planData.buffer.asUint8List();
          }

          if (units != null) {
            highlights.add(Highlight(
                id: highlightId,
                data: highlightDataBytes,
                level: units["units"][highlightId]["level"],
                name: units["units"][highlightId]["name"],
                plan: planDataBytes));
          } else {
            highlights.add(Highlight(id: highlightId, data: highlightDataBytes, level: 99, name: "", plan: planDataBytes));
          }
        }
        FloorFrame frame = FloorFrame(highlights: highlights, render: renderDataBytes, mask: maskDataBytes);
        frames.add(frame);
        setState(() {
          _loadingProgress += percentageByRender;
        });
      }
      newFloor.frames = frames;
      floors.add(newFloor);
    }
    setState(() {
      _floors = floors;
      _floorsLabels = floorsLabels;
      _selectedFloor = floorsLabels[0];
      _highlightsLabels = highlightsLabels;
    });
  }

  @override
  void initState() {
    _initImages();
    super.initState();
  }

  final AppBar _appBar = AppBar(
    title: Row(
      children: [
        Image.asset(
          "assets/resources/logo.png",
          width: 150,
        ),
        Container(
          width: 1,
          height: 100,
          color: CC.grey(),
        ),
        Container(
          decoration: BoxDecoration(
            color: Color.fromRGBO(156, 116, 126, 1),
          ),
          width: 150,
          height: 100,
          child: Center(
            child: Text(
              "MAQUETTE",
              style: TextStyle(
                color: CC.white(),
                fontSize: 15,
              ),
            ),
          ),
        ),
        Container(
          width: 1,
          height: 100,
          color: CC.grey(),
        )
      ],
    ),
    backgroundColor: CC.white(),
  );

  @override
  Widget build(BuildContext context) {
    Floor? currentFloor;
    if (_selectedFloor != null) {
      currentFloor = _floors.firstWhere((floor) => floor.name == _selectedFloor!);
    }
    return Scaffold(
      appBar: _appBar,
      backgroundColor: CC.white(),
      body: Center(
        child: _selectedFloor != null
            ? Row(
                children: [
                  Expanded(
                    child: FloorVisualizer(
                      currentFloor!,
                      _appBar.preferredSize.height,
                      _highlightsLabels,
                      _highlightLevels.where((element) => element.active == true).toList(),
                    ),
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.2,
                    decoration: BoxDecoration(
                      color: CC.white(),
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(10),
                          topRight: Radius.circular(10),
                          bottomLeft: Radius.circular(10),
                          bottomRight: Radius.circular(10)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 5,
                          blurRadius: 7,
                          offset: Offset(0, 3), // changes position of shadow
                        ),
                      ],
                    ),
                    child: ListView(
                      padding: EdgeInsets.only(top: 20),
                      children: <Widget>[
                        if (currentFloor.hasHighlights())
                          Column(
                            children: [
                              Text(
                                "PIECES",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.normal,
                                  color: CC.grey(opacity: 0.8),
                                ),
                              ),
                              for (HighlightLevel level in _highlightLevels)
                                Container(
                                  width: 100,
                                  margin: const EdgeInsets.only(top: 15),
                                  decoration: BoxDecoration(
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.5),
                                        spreadRadius: 0,
                                        blurRadius: 2,
                                        offset: const Offset(0, 2), // changes position of shadow
                                      ),
                                    ],
                                  ),
                                  child: TextButton(
                                    style: ButtonStyle(
                                        padding: MaterialStateProperty.resolveWith((states) => EdgeInsets.fromLTRB(10, 20, 10, 20)),
                                        backgroundColor: MaterialStateProperty.resolveWith((states) => Colors.white)),
                                    onPressed: () {
                                      setState(() {
                                        level.active = !level.active;
                                      });
                                    },
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                            width: 25,
                                            height: 25,
                                            margin: EdgeInsets.only(right: 10),
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.all(Radius.circular(50)),
                                              color: level.color,
                                            ),
                                            child: level.active
                                                ? Icon(
                                                    Icons.check,
                                                    color: CC.white(),
                                                    size: 20,
                                                  )
                                                : Center()),
                                        Text(
                                          "T${level.level}",
                                          style: TextStyle(
                                            color: CC.grey(opacity: 0.8),
                                            fontSize: 15,
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        Divider(
                          height: 10,
                          color: CC.white(),
                        ),
                        Column(
                          children: [
                            Text(
                              "ETAGES",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.normal,
                                color: CC.grey(opacity: 0.8),
                              ),
                            ),
                            for (String floorLabel in _floorsLabels)
                              Container(
                                width: 180,
                                margin: const EdgeInsets.only(top: 15),
                                decoration: BoxDecoration(
                                  boxShadow: [
                                    if (_selectedFloor != floorLabel)
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.5),
                                        spreadRadius: 0,
                                        blurRadius: 2,
                                        offset: const Offset(0, 2), // changes position of shadow
                                      ),
                                  ],
                                ),
                                child: TextButton(
                                  style: ButtonStyle(
                                      padding: MaterialStateProperty.resolveWith((states) => EdgeInsets.fromLTRB(10, 20, 10, 20)),
                                      backgroundColor: MaterialStateProperty.resolveWith(
                                          (states) => _selectedFloor == floorLabel ? CC.lightGray() : Colors.white)),
                                  onPressed: () {
                                    setState(() {
                                      _selectedFloor = floorLabel;
                                    });
                                  },
                                  child: Text(
                                    floorLabel.toUpperCase(),
                                    style: TextStyle(
                                      color: CC.grey(opacity: 0.8),
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        )
                      ],
                    ),
                  )
                ],
              )
            : Center(
                child: Container(
                  width: 400,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Cargando"),
                      LinearProgressIndicator(
                        value: _loadingProgress / 100,
                      )
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
