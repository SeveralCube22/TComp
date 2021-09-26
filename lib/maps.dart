import 'dart:io';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'input.dart';
import 'package:firebase_storage/firebase_storage.dart';

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
                    onPressed: () => null,
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
              // File file = File("C:\\Users\\manam\\Desktop\\Repo\\Android Studio\\tcomp\\assets\\cave.png");
              // print("HERE " + file.toString() + " " + file.path);
              // FirebaseStorage.instance.ref().child("${_uid}_${_name}_${mName}").putString("TEST");
              setState(() {});
            }
          },
          tooltip: "Create Map",
          child: Icon(Icons.add)),
    );
  }
}


