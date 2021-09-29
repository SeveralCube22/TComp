import 'dart:async';
import 'dart:ui' as ui;
import 'dart:collection';
import 'package:flutter/material.dart';
import 'board.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ImageLoader extends StatefulWidget {
  const ImageLoader({Key? key, required this.path, required this.map}) : super(key: key);

  final String path;
  final List<List<String>> map;

  @override
  _ImageLoaderState createState() => _ImageLoaderState();
}


class _ImageLoaderState extends State<ImageLoader> {
  HashMap<String, ui.Image?> _images = HashMap();

  @override
  initState(){
    super.initState();
    _fetchImages();
  }

  @override
  Widget build(BuildContext context) {
    return GamePage(_images, widget.map);
  }

  void _fetchImages() {
    FirebaseStorage.instance.ref().child(widget.path).listAll().then((res) {
      List<Reference> refs = res.items;
      for(int i = 0; i < refs.length; i++){
        Reference ref = refs[i];
        ref.getDownloadURL().then((url) async {
          Completer<ImageInfo> completer = Completer();
          var img = new NetworkImage(url);
          img.resolve(ImageConfiguration()).addListener(ImageStreamListener((ImageInfo info,bool _){
            completer.complete(info);
          }));
          completer.future.then((imgInfo) {
            _images[refs[i].name] = imgInfo.image;
          });
        });
      }
    });
  }
}

// ignore: must_be_immutable
class GamePage extends StatefulWidget {
  GamePage(this._images, this._map, {Key? key}) : super(key: key);

  late HashMap<String, ui.Image?> _images;
  late List<List<String>> _map;

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

  Board _board = Board(_boardRadius, _squareRadius, _squareMargin, null);

  double _scale = 1.0;
  bool _firstRender = true;
  Matrix4? _homeTransformation;
  final TransformationController _transformationController = TransformationController();
  Animation<Matrix4>? _animationReset;
  AnimationController? _controllerReset;

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
    final Offset scenePoint = _transformationController.toScene(details.localPosition);
    final BoardPoint? boardPoint = _board.pointToBoardPoint(scenePoint);
    setState(() {
      _board = _board.copyWithSelected(boardPoint!);
    });
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

  @override
  void initState() {
    super.initState();
    _controllerReset = AnimationController(
      vsync: this,
    );
    _transformationController.addListener(_onTransformationChange);
  }

  @override
  void didUpdateWidget(GamePage oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    // The scene is drawn by a CustomPaint, but user interaction is handled by
    // the InteractiveViewer parent widget.
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      appBar: AppBar(
        title: const Text('MyGameBoard'),
        actions: <Widget>[resetButton],
      ),
      body: Container(
        color: Colors.grey,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Draw the scene as big as is available, but allow the user to
            // translate beyond that to a visibleSize that's a bit bigger.
            final Size viewportSize = Size(
              constraints.maxWidth,
              constraints.maxHeight,
            );

            // The board is drawn centered at the origin, which is the top left
            // corner in InteractiveViewer, so shift it to the center of the
            // viewport initially.
            if (_firstRender) {
              _firstRender = false;
              _homeTransformation = Matrix4.identity();
              _transformationController.value = _homeTransformation!;
            }

            // TODO(justinmc): There is a bug where the scale gesture doesn't
            // begin immediately, and it's caused by wrapping IV in a
            // GestureDetector. Removing the onTapUp fixes it.
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onDoubleTap: () {print('justin double');},
              onTapUp: _onTapUp,
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
                child: CustomPaint(
                  size: _board.size,
                  painter: _BoardPainter(
                      board: _board,
                      showDetail: _scale > 1.5,
                      scale: _scale,
                      images: widget._images,
                      map: widget._map
                  ),
                  // This child gives the CustomPaint an intrinsic size.
                  child: SizedBox(
                    width: _board.size.width,
                    height: _board.size.height,
                  ),
                ),
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
    _transformationController.removeListener(_onTransformationChange);
    super.dispose();
  }
}

// CustomPainter is what is passed to CustomPaint and actually draws the scene
// when its `paint` method is called.
class _BoardPainter extends CustomPainter {
  const _BoardPainter({
    required this.board,
    required this.showDetail,
    required this.scale,
    required this.images,
    required this.map
  });

  final bool showDetail;
  final Board board;
  final HashMap<String, ui.Image?> images;
  final List<List<String>> map;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    void drawBoardPoint(BoardPoint? boardPoint) {
      /*
      final Color color = boardPoint.color.withOpacity(
        board.selected == boardPoint ? 0.7 : 1,
      );
      */
      final double opacity = board.selected == boardPoint ? 0.2 : showDetail ? 0.8 : 0.5;
      Color color = Colors.white;
      if(boardPoint != null) {
        List val = board.getVerticesForBoardPoint(boardPoint, color);
        final ui.Vertices vertices = val[0];
        List<Offset> positions = val[1];
        canvas.drawVertices(vertices, BlendMode.color, Paint());

        Offset center = positions[0].translate(
            positions[0].dx, -positions[0].dx / 2);
        double width = 32.0;

        paintImage(canvas: canvas,
            image: images[map[boardPoint.row][boardPoint.col]]!,
            rect: Rect.fromPoints(positions[0], positions[5]));

        canvas.drawLine(positions[0], positions[1], Paint());
        canvas.drawLine(positions[0], positions[4], Paint());
        canvas.drawLine(positions[4], positions[5], Paint());
        canvas.drawLine(positions[5], positions[1], Paint());
      }

      //print((positions[1].dx - positions[0].dx).toString() + " " + (positions[2].dy - positions[0].dy).toString() + "\n");

      /*
      final ui.ParagraphBuilder paragraphBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(
        fontSize: 12.0,
        height: 20.0,
        maxLines: 1,
        textAlign: TextAlign.start,
        textDirection: TextDirection.ltr,
      ));
      /*
      paragraphBuilder.pushStyle(ui.TextStyle(
        color: Colors.red,
        fontSize: 12.0,
        height: 20.0,
      ));
      */
      paragraphBuilder.addText('hello ${boardPoint.q}, ${boardPoint.r}');
      final ui.Paragraph paragraph = paragraphBuilder.build();
      final Point<double> textPoint = board.boardPointToPoint(boardPoint);
      final Offset textOffset = Offset(
        textPoint.x,
        textPoint.y,
      );
      print('justin draw at $textOffset');
      canvas.drawParagraph(paragraph, textOffset);
      */
    }

    board.forEach(drawBoardPoint);
  }

  // We should repaint whenever the board changes, such as board.selected.
  @override
  bool shouldRepaint(_BoardPainter oldDelegate) {
    return oldDelegate.board != board;
  }
}