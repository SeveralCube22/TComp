import 'dart:async';
import 'dart:io';
import 'dart:collection';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'input.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:nanoid/nanoid.dart';
import 'package:fluttertoast/fluttertoast.dart';
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

  List<String> _maps = [];
  HashMap<String, String> _sessions = HashMap();

  _MapState(this._uid, this._name) {
    FirebaseDatabase.instance
        .reference()
        .child("Campaigns")
        .child(_uid + "_" + _name)
        .child("Maps")
        .once()
        .then((dataSnapshot) {
      dataSnapshot.value.forEach((k, v) {
        _maps.add(k.toString());
      });

      setState(() {});
    });

    FirebaseDatabase.instance
        .reference()
        .child("Campaigns")
        .child(_uid + "_" + _name)
        .child("Sessions")
        .once()
        .then((dataSnapshot) {
      dataSnapshot.value.forEach((k, v) {
        _sessions.putIfAbsent(k.toString(), () => "");
      });

      setState(() {
        _sessions.putIfAbsent("Test", () => "");
      });
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
    for (int i = 0; i < 12; i++) {
      var row = List.generate(12, (index) => "cave.png");
      mRoot.child("Map Data").child("Map").child("${i}").set(row);
    }
  }

  Future<List<List<String>>> _loadMap(String mName) async {
    DataSnapshot data = await FirebaseDatabase.instance
        .reference()
        .child("Maps")
        .child("${_uid}_${_name}_${mName}")
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

  Future<void> _showInvite() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        var sessionController = TextEditingController();
        var currId = "";
        _sessions["TEST"] = "TST";
        return AlertDialog(
          title: Text("Invitation"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Row(
                    mainAxisSize: MainAxisSize.max,
                    children: <Widget>[
                      Flexible(
                          child: TextField(
                              controller: sessionController,
                              onSubmitted: (value) {
                                if(_sessions.containsKey(value)) {
                                  Fluttertoast.showToast(
                                    msg: "Session already exists",
                                    toastLength: Toast.LENGTH_LONG,
                                    gravity: ToastGravity.BOTTOM,
                                    timeInSecForIosWeb: 1
                                  );
                                }
                                else
                                  setState(() {
                                    _sessions.putIfAbsent(value, () => "");
                                    var id = nanoid(10);
                                    currId = id;
                                    FirebaseDatabase.instance
                                        .reference()
                                        .child("Campaigns")
                                        .child(_uid + "_" + _name)
                                        .child("Sessions")
                                        .child(value)
                                        .set({
                                          "Link" : id,
                                          "Players" : ""
                                        });
                                  });
                              },
                              decoration: InputDecoration(hintText: "Session"))),
                      Padding(
                          padding: EdgeInsets.only(top: 16.0),
                          child: DropdownButton<String>(
                            hint: Icon(
                                Icons.arrow_drop_down,
                                size: 30.0,
                                color: Colors.white),
                            onChanged: (String? session) {
                              setState(() async {
                                if (session != null) {
                                  sessionController.text = session;
                                  var data = await FirebaseDatabase.instance
                                                        .reference()
                                                        .child("Campaigns")
                                                        .child(_uid + "_" + _name)
                                                        .child("Sessions")
                                                        .child(session).get();
                                  currId = data.value;
                                }
                              });
                            },
                            items: _sessions.keys.map((String session) {
                              return DropdownMenuItem<String>(
                                value: session,
                                child: Row(
                                  children: <Widget>[
                                    SizedBox(
                                      width: 10,
                                    ),
                                    Text(
                                      session,
                                      style: TextStyle(color: Colors.black),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ))
                    ]),
                Text("ASDF " + currId)
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("Play"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_name), actions: <Widget>[
        Padding(
            padding: EdgeInsets.only(right: 20.0),
            child: GestureDetector(
              onTap: () => _showInvite(),
              child: Icon(Icons.insert_link_sharp,
                  size: 30.0, color: Colors.white),
            ))
      ]),
      body: ListView.builder(
        itemCount: _maps.length,
        itemBuilder: (BuildContext context, int index) {
          return Container(
              height: 50,
              margin: EdgeInsets.only(top: 5, bottom: 5, left: 20, right: 20),
              child: Row(children: [
                TextButton(
                    onPressed: () {
                      _loadMap(_maps[index]).then((map) {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (contex) => ImageLoader(
                                    path: "${_uid}_${_name}_${_maps[index]}",
                                    map: map)));
                      });
                    },
                    child: Text("${_maps[index]}"))
              ]));
        },
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: () async {
            String mName = await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => Input(hintText: "Map Name")));
            if (mName != null) {
              _maps.add(mName);
              var root = FirebaseDatabase.instance.reference();
              root
                  .child("Campaigns")
                  .child("${_uid}_${_name}")
                  .child("Maps")
                  .child(mName)
                  .set('');
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
              var name = "cave.png"; //TODO change
              FirebaseStorage.instance
                  .ref()
                  .child("${_uid}_${_name}_${mName}/assets/${name}/")
                  .putFile(file);

              setState(() {});
            }
          },
          tooltip: "Create Map",
          child: Icon(Icons.add)),
    );
  }
}
