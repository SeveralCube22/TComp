import 'dart:async';
import 'dart:io';
import 'dart:collection';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'player.dart';
import 'input.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'map.dart';
import 'invitation_page.dart';

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
  bool inSession = false;
  String? session = null;
  List<PlayerState> players = [];

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

  AppBar buildAppBar() {
    Widget w;
    if (inSession)
      w = Center(child: Text(session!, textScaleFactor: 1.5,),);
    else {
      w = GestureDetector(
        onTap: () async {
          Result res = await Navigator.push(context, MaterialPageRoute(builder: (context) =>
                      Invitation(sessions: _sessions, uid: _uid, name: _name)));
          if(res.inSession) {
            setState(() {
              inSession = true;
              session = res.session;
              res.players.forEach((element) {
                players.add(PlayerState(element, null));
              });
            });
          }
        },
        child: Icon(Icons.insert_link_sharp, size: 30.0, color: Colors.white),
      );
    }
    return AppBar(title: Text(_name), actions: <Widget>[
      Padding(padding: EdgeInsets.only(right: 20.0), child: w)
    ]);
  }

  Future<void> _showMyDialog(List<PlayerState> players, String map) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Load Players"),
          content: Container(
            width: 100,
            height: 100,
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) => Column(
                  children: <Widget>[
                    ListView.builder(
                        itemCount: players.length,
                        scrollDirection: Axis.vertical,
                        shrinkWrap: true,
                        itemBuilder: (BuildContext context, int index) {
                          players[index].state = players[index].currMap == map;
                          print("HERE ${players[index].state}");
                          return CheckboxListTile(
                              title: Text("${players[index].player.name} ${players[index].currMap == null ? "" : "(In ${players[index].currMap!.split("_")[2]})"}"),
                              value: players[index].state,
                              onChanged: (newValue) {
                                print("${newValue}");
                                if(newValue != null) {
                                  if(newValue) {
                                    players[index].player.putPlayer(map);
                                    setState(() {
                                      players[index].currMap = map;
                                      players[index].state = true;
                                      print("STATE ${players[index].state}");
                                    });
                                  }
                                  else {
                                    players[index].player.removePlayer(map);
                                    setState(() {
                                      players[index].currMap = null;
                                      players[index].state = true;
                                    });
                                  }
                                }
                              },
                              controlAffinity: ListTileControlAffinity.leading,  //  <-- leading Checkbox
                          );
                        })
                  ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("Done"),
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
      appBar: buildAppBar(),
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
                    onLongPress: () {
                      if(inSession) {
                        String map = "${_uid}_${_name}_${_maps[index]}";
                        _showMyDialog(players, map);
                      }
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

class PlayerState {
  Player player;
  String? currMap;
  late bool state;

  PlayerState(this.player, this.currMap);

}


