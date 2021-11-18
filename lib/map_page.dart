import 'dart:async';
import 'dart:io';
import 'dart:collection';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'player.dart';
import 'input.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'map_board.dart';
import 'map_membership.dart';
import 'invitation_page.dart';

class MapPage extends StatefulWidget {
  const MapPage({Key? key, required this.uid, required this.name})
      : super(key: key);

  final String uid;
  final String name;

  @override
  _MapPageState createState() => _MapPageState(uid, name);
}

class _MapPageState extends State<MapPage> {
  String _uid;
  String _name;
  bool inSession = false;
  String? session = null;
  String? sessionLink = null;
  List<PlayerState> players = [];

  List<String> _maps = [];
  HashMap<String, String> _sessions = HashMap();

  _MapPageState(this._uid, this._name) {
    FirebaseDatabase.instance
        .reference()
        .child("Campaigns")
        .child(_uid + "_" + _name)
        .child("Maps")
        .once()
        .then((dataSnapshot) {
          if(dataSnapshot.value != "") {
            dataSnapshot.value.forEach((k, v) {
              _maps.add(k.toString());
            });
          }
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
              sessionLink = res.sessionLink;
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
                          return CheckboxListTile(
                              title: Text("${players[index].player.name} ${players[index].currMap == null ? "" : "(In ${players[index].currMap!.split("_")[2]})"}"),
                              value: players[index].state,
                              onChanged: (newValue) {
                                if(newValue != null) {
                                  if(newValue) {
                                    players[index].player.putPlayer(map);
                                    setState(() {
                                      players[index].currMap = map;
                                      players[index].state = true;
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
                      Map.loadMap("${_uid}_${_name}_${_maps[index]}").then((map) {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (contex) => ImageLoader(
                                    path: "${_uid}_${_name}_${_maps[index]}",
                                    player: null,
                                    session: inSession ? sessionLink : null,
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
              Map.initMap(mRoot);


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


