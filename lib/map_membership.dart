import 'dart:async';

import 'package:firebase_database/firebase_database.dart';

class Map {
  static initMap(var mRoot) {
    mRoot.set({
      "Map Data": {
        'Rows': 12,
        'Cols': 12,
        'Map': '',
      }
    });
    for (int i = 0; i < 12; i++) {
      var row = List.generate(12, (index) => "${i}_${index}_bg.png");
      mRoot.child("Map Data").child("Map").child("${i}").set(row);
    }
  }

  static Future<List<List<String>>> loadMap(String mapName) async {
    DataSnapshot data = await FirebaseDatabase.instance
        .reference()
        .child("Maps")
        .child(mapName)
        .child("Map Data")
        .get();
    var values = data.value;
    var mapValues = values["Map"];
    List<List<String>> map = [];
    for (int i = 0; i < 12; i++) {
      //TODO get rows and cols
      List<String> row = [];
      for (int j = 0; j < 12; j++) {
        row.add(mapValues[i][j]);
      }
      map.add(row);
    }

    var completer = Completer<List<List<String>>>();
    completer.complete(map);

    return completer.future;
  }
}