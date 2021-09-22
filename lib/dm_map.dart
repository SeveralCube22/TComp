import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DM_Map extends StatefulWidget {
  const DM_Map({Key? key}) : super(key: key);

  @override
  _DM_MapState createState() => _DM_MapState(10);
}

class _DM_MapState extends State<DM_Map> {
  int _rows;

  late List<List> _map;

  _DM_MapState(this._rows) {
    _map = List.generate(
        _rows, (i) => List.generate(_rows, (j) => "", growable: true));
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
