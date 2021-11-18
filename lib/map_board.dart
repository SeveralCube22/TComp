import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'dart:collection';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'board.dart';
import 'player.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class ImageLoader extends StatefulWidget {
  const ImageLoader({Key? key, required this.path, required this.map, required this.session, required this.player}) : super(key: key);

  final String path;
  final List<List<String>> map;
  final String? session;
  final Player? player;

  @override
  _ImageLoaderState createState() => _ImageLoaderState();
}

enum Objects {
  Player,
  Object,
}

class MapObj {
  String? name;
  Objects? type;
  bool occupied;

  MapObj(this.name, this.type, this.occupied);
}

class Data {
  static String map = "";
  static String? session;
  static Player? player;
}

class _ImageLoaderState extends State<ImageLoader> {
  HashMap<String, ui.Image?> _images = HashMap();
  late List<List<MapObj>> objMap;

  @override
  initState(){
    super.initState();
    _fetchBackgroundImages();
    Data.map = widget.path;
    Data.session = widget.session;
    Data.player = widget.player;

    objMap = List.generate(widget.map.length, (i) =>
        List.generate(
            widget.map[i].length, (index) => MapObj(null, null, false)));
    if(widget.session != null) {
      _fetchObjectImages(true);
      _fetchObjectImages(false);
      //_buildObjectMap(true);
      //_buildObjectMap(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GamePage(_images, widget.map, objMap);
  }

  void _fetchBackgroundImages() async {
    ListResult res = await FirebaseStorage.instance.ref().child("${widget.path}/assets/").listAll();
    List<Reference> refs = res.items;
    for (int i = 0; i < refs.length; i++) {
      Reference ref = refs[i];
      ref.getDownloadURL().then((url) async {
        Completer<ImageInfo> completer = Completer();
        var img = new NetworkImage(url);
        img.resolve(ImageConfiguration()).addListener(ImageStreamListener((ImageInfo info, bool _) {
          completer.complete(info);
        }));
        completer.future.then((imgInfo) {
          print("BG: ${refs[i].name}");
          setState(() {
            _images[refs[i].name] = imgInfo.image;
          });
        });
      });
    }
  }

  void _fetchObjectImages(bool player) async {
    ListResult res =  await FirebaseStorage.instance.ref().child("Sessions/${widget.session}/${player ? "Players" : "Objects"}/${widget.path}/").listAll();
    List<Reference> refs = res.items;
    print("DEBUG OBJ HERE ${refs.length}");
    for (int i = 0; i < refs.length; i++) {
      Reference ref = refs[i];
      print("BUILD IMAGE ${ref.name}");
      ref.getDownloadURL().then((url) async {
        Completer<ImageInfo> completer = Completer();
        var img = new NetworkImage(url);
        img.resolve(ImageConfiguration()).addListener(
            ImageStreamListener((ImageInfo info, bool _) {
              completer.complete(info);
            }));
        completer.future.then((imgInfo) {
          setState(() {
            _images[refs[i].name] = imgInfo.image;
          });
        });
      });
    }
  }

  void _buildObjectMap(bool player) async {
   DataSnapshot data = await FirebaseDatabase.instance.reference()
        .child("Sessions")
        .child(widget.session!)
        .child("Maps")
        .child(widget.path)
        .child("${player ? "Players" : "Objects"}")
        .get();

   HashMap<dynamic, dynamic> map = HashMap.from(data.value);
   map.forEach((key, value) {
     MapObj map = MapObj("${key.toString()}.png", player ? Objects.Player : Objects.Object, true);
     int x = value["${player ? "SPos" : "Pos"}"]["x"];
     int y = value["${player ? "SPos" : "Pos"}"]["y"];
     setState(() {
       objMap[x][y] = map;
     });
   });
  }
}

class GamePage extends StatefulWidget {
  GamePage(this._images, this._map, this._objMap, {Key? key}) : super(key: key);

  late HashMap<String, ui.Image?> _images;
  late List<List<String>> _map;
  late List<List<MapObj>> _objMap;

  List<Offset?> drawPoints = List.empty(growable: true);

  @override
  _GamePageState createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> with TickerProviderStateMixin {
  // The radius of a hexagon tile in pixels.
  static const _squareRadius = 32.0;
  // The margin between hexagons.
  static const _squareMargin = 0.0;
  // The radius of the entire board in hexagons, not including the center.
  static const _boardRadius = 12;

  List<Player>? players;
  AnimationController? controller;
  late Widget boardWidget;
  late XFile? currObj;

  Board _board = Board(_boardRadius, _squareRadius, _squareMargin, null);

  double _scale = 1.0;
  bool _firstRender = true;
  bool _drawable = false;
  Matrix4? _homeTransformation;
  final TransformationController _transformationController = TransformationController();
  Animation<Matrix4>? _animationReset;
  AnimationController? _controllerReset;

  _GamePageState() {
    if(Data.session != null) {
      _loadDraw();
      FirebaseDatabase.instance
          .reference()
          .child("Sessions")
          .child(Data.session!)
          .child("Maps")
          .child(Data.map)
          .child("Draw")
          .onChildChanged
          .listen((event) => _loadDraw());
    }
  }

  @override
  void initState() {
    super.initState();

    if(Data.session != null) {
      controller = AnimationController(
        vsync: this,
        duration: Duration(seconds: 5),
      )..repeat();
      _loadPlayers();
      boardWidget = buildAnimation();
    }
    else {
      boardWidget = buildCustomPainter();
    }

    _controllerReset = AnimationController(
      vsync: this,
    );
    _transformationController.addListener(_onTransformationChange);
  }

  void _loadPlayers() async {
    List<Player> temp = await Player.loadPlayers(Data.session!, Data.map);
    setState(() {
      players = temp;
    });
  }

  void _loadDraw() async {
    var data = await FirebaseDatabase.instance.reference()
        .child("Sessions")
        .child(Data.session!)
        .child("Maps")
        .child(Data.map)
        .get();

    if(data.value["Draw"]["Draw"] != null) {
      List<dynamic> values = data.value["Draw"]["Draw"];
      List<Offset?> temp = List.empty(growable: true);
      values.forEach((value) {
        if (value["x"] != "") {
          double x = double.parse(value["x"]);
          double y = double.parse(value["y"]);
          temp.add(Offset(x, y));
        }
        else
          temp.add(null);
      });
      setState(() {
        widget.drawPoints = temp;
      });
    }
  }

  // Handle reset to home transform animation.
  void _onAnimateReset() {
    _transformationController.value = _animationReset!.value;
    if (!_controllerReset!.isAnimating) {
      _animationReset?.removeListener(_onAnimateReset);
      _animationReset = null;
      _controllerReset!.reset();
    }
  }

  // Initialize the reset to home transform animation.
  void _animateResetInitialize() {
    _controllerReset!.reset();
    _animationReset = Matrix4Tween(
      begin: _transformationController.value,
      end: _homeTransformation,
    ).animate(_controllerReset!);
    _controllerReset!.duration = const Duration(milliseconds: 400);
    _animationReset!.addListener(_onAnimateReset);
    _controllerReset!.forward();
  }

  // Stop a running reset to home transform animation.
  void _animateResetStop() {
    _controllerReset!.stop();
    _animationReset?.removeListener(_onAnimateReset);
    _animationReset = null;
    _controllerReset!.reset();
  }

  void _onScaleStart(ScaleStartDetails details) {
    // If the user tries to cause a transformation while the reset animation is
    // running, cancel the reset animation.
    if (_controllerReset!.status == AnimationStatus.forward) {
      _animateResetStop();
    }
  }

  void _onTapUp(TapUpDetails details) {
    final Offset scenePoint = _transformationController.toScene(
        details.localPosition);
    final BoardPoint? boardPoint = _board.pointToBoardPoint(scenePoint);

    if (boardPoint != null) {
      if (Data.player != null) {
        Data.player!.end = Pos(boardPoint.row, boardPoint.col);
      }
      else {
        if(Data.session == null) {
          _saveBackground(boardPoint!);
        }
        else {

        }
      }
    }
  }

  void _onTransformationChange() {
    final double currentScale = _transformationController.value.getMaxScaleOnAxis();
    if (currentScale != _scale) {
      setState(() {
        _scale = currentScale;
        //print(_scale.toString() + "\n");
      });
    }
  }

  void _onPanStart(DragStartDetails details) {
    final point =_transformationController.toScene(
      details.localPosition,
    );
    setState(() {
      if (widget.drawPoints == null) {
        widget.drawPoints = List.empty(growable: true);
      }
      widget.drawPoints.add(point);
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final point = _transformationController.toScene(
      details.localPosition,
    );
    setState(() {
      widget.drawPoints.add(point);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      widget.drawPoints.add(null);
      if(Data.session != null)
        _saveDraw();
    });
  }

  void _saveDraw() {
    var root = FirebaseDatabase.instance.reference()
        .child("Sessions")
        .child(Data.session!)
        .child("Maps")
        .child(Data.map)
        .child("Draw")
        .child("Draw"); //doing this because for some reason, listener doesn't work without it

    for(int i = 0; i < widget.drawPoints.length; i++) {
      var point = widget.drawPoints[i];
      root.child("${i}").set({"x" : "${point == null ? "" : point.dx}", "y" : "${point == null ? "" : point.dy}"});
    }
  }


  @override
  void didUpdateWidget(GamePage oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  CustomPaint buildCustomPainter() {
    return CustomPaint(
      size: _board.size,
      painter: _BoardPainter(
          board: _board,
          showDetail: _scale > 1.5,
          scale: _scale,
          images: widget._images,
          map: widget._map,
          objMap: widget._objMap,
          players: players,
          drawnPoints: widget.drawPoints
      ),
      // This child gives the CustomPaint an intrinsic size.
      child: SizedBox(
        width: _board.size.width,
        height: _board.size.height,
      ),
    );
  }

  Widget buildAnimation() {
    return AnimatedBuilder(
      animation: controller!,
      builder: (_, __) {
        if(players != null)
          players!.forEach((player) { player.move(); });
        //_updateMapObj();
        return buildCustomPainter();
      },
    );
  }

  Widget _buildDrawableIcon() {
    return Data.player == null ? IconButton(
      icon: _drawable ? Icon(Icons.palette_rounded) : Icon(Icons.palette_outlined),
      onPressed: () {
        setState(() {
          _drawable = !_drawable;
        });
      },
    ) : Container();
  }

  Widget _buildMapEdit() {
    return Data.player == null ? IconButton(
      icon: Icon(Icons.add_outlined),
      onPressed: () async {
        ImagePicker picker = ImagePicker();
        currObj = await picker.pickImage(source: ImageSource.gallery);
      }
    ) : Container();
  }

  void _saveBackground(BoardPoint point) async {
    File file = File(currObj!.path);
    var name = "${point.row}_${point.col}_bg.png"; // TODO change so that user gives asset name
    FirebaseStorage.instance
        .ref()
        .child("${Data.map}/assets/${name}/")
        .putFile(file);

    List<int> imageBase64 = file.readAsBytesSync();
    String imageAsString = base64Encode(imageBase64);
    var uint8list = base64.decode(imageAsString);

    ui.Codec codec = await ui.instantiateImageCodec(uint8list);
    ui.FrameInfo frame = await codec.getNextFrame();
    widget._images.putIfAbsent(name, () => frame.image);

    widget._map[point.row][point.col] = name;
  }


  @override
  Widget build(BuildContext context) {
    // The scene is drawn by a CustomPaint, but user interaction is handled by
    // the InteractiveViewer parent widget.
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      appBar: AppBar(
        title: const Text('MyGameBoard'),
        actions: <Widget>[resetButton, _buildDrawableIcon(), _buildMapEdit()],
      ),
      body: Container(
        color: Colors.grey,
        child: LayoutBuilder(
          builder: (context, constraints) {

            final Size viewportSize = Size(
              constraints.maxWidth,
              constraints.maxHeight,
            );

            if (_firstRender) {
              _firstRender = false;
              _homeTransformation = Matrix4.identity();
              _transformationController.value = _homeTransformation!;
            }

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: _onTapUp,
              onPanStart: _drawable && Data.player == null ? _onPanStart : null,
              onPanUpdate: _drawable && Data.player == null ? _onPanUpdate : null,
              onPanEnd: _drawable && Data.player == null ? _onPanEnd : null,
              child: InteractiveViewer(
                onInteractionUpdate: (ScaleUpdateDetails details) {
                  //print('justin onInteractionUpdate ${details.scale}');
                },
                transformationController: _transformationController,
                //boundaryMargin: EdgeInsets.all(500.0),
                boundaryMargin: EdgeInsets.fromLTRB(
                  _board.size.width * 2,
                  _board.size.height * .75,
                  _board.size.width * 2,
                  _board.size.height * 4,
                ),
                minScale: 0.01,
                onInteractionStart: _onScaleStart,
                  panEnabled: !_drawable,
                  scaleEnabled: !_drawable,
                child: boardWidget
              ),
            );
          },
        ),
      ),
      //persistentFooterButtons: [resetButton, editButton],
    );
  }

  IconButton get resetButton {
    return IconButton(
      onPressed: () {
        setState(() {
          _animateResetInitialize();
        });
      },
      tooltip: 'Reset',
      color: Theme.of(context).colorScheme.surface,
      icon: const Icon(Icons.replay),
    );
  }

  @override
  void dispose() {
    _controllerReset!.dispose();
    if(controller != null)
      controller!.dispose();
    _transformationController.removeListener(_onTransformationChange);
    super.dispose();
  }
}

class _BoardPainter extends CustomPainter {
  const _BoardPainter({
    required this.board,
    required this.showDetail,
    required this.scale,
    required this.images,
    required this.map,
    required this.objMap,
    required this.players,
    required this.drawnPoints,
  });

  final bool showDetail;
  final Board board;
  final HashMap<String, ui.Image?> images;
  final List<List<String>> map;
  final List<List<MapObj>> objMap;
  final List<Player>? players;
  final double scale;
  final List<Offset?>? drawnPoints;

  @override
  void paint(Canvas canvas, Size size) {
    void drawBoardPoint(BoardPoint? boardPoint) {
      final double opacity = board.selected == boardPoint ? 0.2 : showDetail ? 0.8 : 0.5;
      Color color = Colors.white;
      if(boardPoint != null) {
        List val = board.getVerticesForBoardPoint(boardPoint, color);
        final ui.Vertices vertices = val[0];
        List<Offset> positions = val[1];
        canvas.drawVertices(vertices, BlendMode.color, Paint());

        var bgImg = images[map[boardPoint.row][boardPoint.col]];
        if(bgImg != null)
          paintImage(canvas: canvas,
              image: bgImg,
              rect: Rect.fromPoints(positions[0], positions[5]));

        if(Data.session != null) {
          // MapObj m = objMap[boardPoint.row][boardPoint.col];
          Pos curr = Pos(boardPoint.row, boardPoint.col);
          String? name;
          if(players != null) {
            players!.forEach((element) {
              if (curr == element.start)
                name = element.name;
            });
            var objImg = images["${name}.png"];
            if (objImg != null)
              paintImage(canvas: canvas,
                  image: objImg,
                  rect: Rect.fromPoints(positions[0], positions[5]));
          }
        }

        canvas.drawLine(positions[0], positions[1], Paint());
        canvas.drawLine(positions[0], positions[4], Paint());
        canvas.drawLine(positions[4], positions[5], Paint());
        canvas.drawLine(positions[5], positions[1], Paint());
      }
    }

    board.forEach(drawBoardPoint);
    if(drawnPoints != null) {
      Paint paint = Paint()
        ..color = Colors.black
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round;
      for(int i = 0; i < drawnPoints!.length - 1; i++) {
        if (drawnPoints![i] != null && drawnPoints![i + 1] != null) {
          canvas.drawLine(drawnPoints![i]!, drawnPoints![i +1]!, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_BoardPainter oldDelegate) {
    return true;
  }
}