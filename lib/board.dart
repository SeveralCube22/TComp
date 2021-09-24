import 'dart:collection' show IterableMixin;
import 'dart:math';
import 'dart:ui' show Vertices;
import 'package:flutter/material.dart' hide Gradient;
import 'package:vector_math/vector_math_64.dart' show Vector3;

class Board extends Object with IterableMixin<BoardPoint?> {
  int _boardWidth;
  double _squareWidth;
  double _squareMargin;
  List<Offset> _positionsForSquareAtOrigin = <Offset>[];
  List<BoardPoint> _boardPoints = <BoardPoint>[];
  BoardPoint? selected;

  Board(this._boardWidth, this._squareWidth, this._squareMargin,  List<BoardPoint>? boardPoints, {this.selected})
      : assert(_boardWidth > 0),
        assert(_squareWidth > 0),
        assert(_squareMargin >= 0) {
    Point<double> squareStart = Point<double>(0, 0);
    double squareWidthPadded = _squareWidth + _squareMargin;
    _positionsForSquareAtOrigin.addAll(<Offset>[
      Offset(squareStart.x, squareStart.y),
      Offset(squareStart.x + squareWidthPadded, squareStart.y),
      Offset(squareStart.x + squareWidthPadded, squareStart.y + squareWidthPadded),
      Offset(squareStart.x, squareStart.y),
      Offset(squareStart.x, squareStart.y + squareWidthPadded),
      Offset(squareStart.x + squareWidthPadded, squareStart.y + squareWidthPadded),
    ]);

    if(boardPoints != null)
      _boardPoints.addAll(boardPoints);
    else {
      for (int i = 0; i < _boardWidth; i++)
        for (int j = 0; j < _boardWidth; j++)
          _boardPoints.add(BoardPoint(i, j));
    }
  }

  @override
  Iterator<BoardPoint?> get iterator => _BoardIterator(_boardPoints);

  Size get size {
    return Size(
      _boardWidth * _squareWidth * 2,
      _boardWidth * _squareWidth * 2,
    );
  }

  BoardPoint? pointToBoardPoint(Offset point) {
    int row = point.dx ~/ _squareWidth;
    int col = point.dy ~/ _squareWidth;

    if(row >= 0 && row < _boardWidth &&
      col >= 0 && col < _boardWidth)

      return BoardPoint(row, col);

    else
      return null;
  }

  Board copyWithSelected(BoardPoint boardPoint) {
    if (selected == boardPoint) {
      return this;
    }
    final Board nextBoard = Board(_boardWidth, _squareWidth, _squareMargin, _boardPoints, selected: boardPoint);
    return nextBoard;
  }

  Point<double> boardPointToPoint(BoardPoint point) {
    return Point<double>((point._row * _squareWidth).toDouble(),
        (point._col * _squareWidth).toDouble());
  }

  List getVerticesForBoardPoint(BoardPoint boardPoint, Color color) {
    final Point<double> centerOfHexZeroCenter = boardPointToPoint(boardPoint);

    final List<Offset> positions = _positionsForSquareAtOrigin.map((offset) {
      return offset.translate(centerOfHexZeroCenter.x, centerOfHexZeroCenter.y);
    }).toList();

    return [Vertices(
        VertexMode.triangles,
        positions,
        colors: List<Color>.filled(positions.length, Colors.white),
      ),
      positions
    ];
  }
}

class BoardPoint {
  int _row;
  int _col;
  Color? color;

  BoardPoint(this._row, this._col, {this.color});

  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is BoardPoint && other._row == _row && other._col == _col;
  }

  Vector3 get cubeCoordinates {
    return Vector3(
      _row.toDouble(),
      _col.toDouble(),
      0.0,
    );
  }
}

class _BoardIterator extends Iterator<BoardPoint?> {
  _BoardIterator(this.boardPoints);

  late final List<BoardPoint> boardPoints;
  int? currentIndex;

  @override
  BoardPoint? current;

  @override
  bool moveNext() {
    if (currentIndex == null) {
      currentIndex = 0;
    } else {
      currentIndex = currentIndex! + 1;
    }

    if (currentIndex! >= boardPoints.length) {
      current = null;
      return false;
    }

    current = boardPoints[currentIndex!];
    return true;
  }
}
