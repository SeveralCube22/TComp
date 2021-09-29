import 'dart:io';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'input.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart'as path;
import 'package:permission_handler/permission_handler.dart';
import 'map.dart';

class Map extends StatefulWidget {
  const Map({Key? key, required this.uid, required this.name})
      : super(key: key);

  final String uid;
  final String name;

  @override
  _MapState createState() => _MapState(uid, name);
}

class _MapState extends State<Map> {
  String _uid;
  String _name;

  var _maps = [];

  _MapState(this._uid, this._name) {
    FirebaseDatabase.instance
        .reference()
        .child("Campaigns")
        .child(_uid + "_" + _name)
        .child("Maps")
        .once()
        .then((dataSnapshot) {
      dataSnapshot.value.forEach((k, v) {
        print("DATA:" + k);
        _maps.add(k.toString());
      });

      setState(() {});
    });
  }

  _initMap(var mRoot) {
    mRoot.set({
      "Map Data": {
        'Rows': 12,
        'Cols': 12,
        'Map': '',
      }
    });
    for(int i = 0; i < 12; i++){
      var row = List.generate(12, (index) => "cave.png");
      mRoot.child("Map Data").child("Map").child("${i}").set(row);
    }
  }

  List<List<String>> _loadMap(String mName) {
    var root = FirebaseDatabase.instance.reference();
    root.child("Campaigns").child("${_uid}_${_name}").child("Maps").child(mName).set('');
    var mRoot = root.child("Maps").child("${_uid}_${_name}_${mName}").child("Map Data").child("Map");
    //TODO get rows, cols

    List<List<String>> res = [];
    for(int i = 0; i < 12; i++) {
      List<String> l = [];

      var root = mRoot.child("${i}").once().then((data) {
        int j = 0;
        data.value.forEach((k, v) {
          l.add(v.toString());
        });
      });
      res.add(l);
    }
    return res;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_name)),
      body: ListView.builder(
        itemCount: _maps.length,
        itemBuilder: (BuildContext context, int index) {
          return Container(
              height: 50,
              margin: EdgeInsets.only(top: 5, bottom: 5, left: 20, right: 20),
              child: Row(children: [
                TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (contex) => ImageLoader(path: "${_uid}_${_name}_${_maps[index]}", map: _loadMap(_maps[index])))),
                    child: Text("${_maps[index]}")
                )
              ]));
        },
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: () async {
            String mName = await Navigator.push(context,
                MaterialPageRoute(builder: (context) => Input(hintText: "Map Name")));
            if(mName != null){
              _maps.add(mName);
              var root = FirebaseDatabase.instance.reference();
              root.child("Campaigns").child("${_uid}_${_name}").child("Maps").child(mName).set('');
              var mRoot = root.child("Maps").child("${_uid}_${_name}_${mName}");
              mRoot.child("Public").set("F");
              mRoot.child("Maps").set("");
              _initMap(mRoot);

              var status = await Permission.storage.status;
              if (!status.isGranted) {
                await Permission.storage.request();
              }


              File file = File('/storage/emulated/0/Download/cave.png');
              //print(file.readAsString());
              FirebaseStorage.instance.ref().child("${_uid}_${_name}_${mName}").putFile(file);

              setState(() {});
            }
          },
          tooltip: "Create Map",
          child: Icon(Icons.add)),
    );
  }
}


