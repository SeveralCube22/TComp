import 'dart:collection';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class Player {
  String _name;
  String _session;
  String? _map;
  bool _status;
  late Pos _start;
  late Pos _end;
  List<Pos>? _path;

  Player(this._name, this._session, this._status);

  void putPlayer(String map) {
    FirebaseDatabase.instance.reference()
                    .child("Sessions")
                    .child(_session)
                    .child("Players")
                    .child(_name)
                    .child("Map")
                    .set(map);
    FirebaseDatabase.instance.reference()
        .child("Sessions")
        .child(_session)
        .child("Maps")
        .child(map)
        .child("Players")
        .child(_name)
        .set({"SPos": {"x": 0, "y": 0}, "EPos": {"x": 0, "y": 0} });
  }

  void removePlayer(String map) {
    FirebaseDatabase.instance.reference()
        .child("Sessions")
        .child(_session)
        .child("Players")
        .child(_name)
        .child("Map")
        .set("");
    FirebaseDatabase.instance.reference()
        .child("Sessions")
        .child(_session)
        .child("Maps")
        .child(map)
        .child("Players")
        .child(_name)
        .remove();
  }

  void storeAvatar(XFile avatar) {
    File file = File(avatar!.path);
    var name = "${_name}.png"; //TODO change
    FirebaseStorage.instance
        .ref()
        .child("Sessions/${_session}/Players/${_map!}/${name}/")
        .putFile(file);
  }

  static Future<List<Player>> loadPlayers(String session, String map) async {
    var root = FirebaseDatabase.instance.reference()
        .child("Sessions")
        .child(session);

    var status = await root.child("Players").get();
    HashMap<String, int> playerNames = HashMap();
    HashMap<dynamic, dynamic> statusVals = HashMap.from(status.value);
    statusVals.forEach((key, value) {
      if(value["Map"] == map && value["Status"])
        playerNames.putIfAbsent(key, () => 0);
    });

    var m = await root.child("Maps").child(map).child("Players").get();
    List<Player> players = List.empty(growable: true);
    HashMap<dynamic, dynamic> mPlayers = HashMap.from(m.value);
    mPlayers.forEach((key, value) {
      if(playerNames.containsKey(key)) {
        Pos startPos = Pos(value["SPos"]["x"], value["Spos"]["y"]);
        Pos endPos = Pos(value["EPos"]["x"], value["Epos"]["y"]);

        Player player = Player(key, session, true);
        player._start = startPos;
        player._end = endPos;
        players.add(player);
      }
    });

    return players;
  }

  void move() async {
    var root = FirebaseDatabase.instance.reference()
        .child("Sessions")
        .child(_session)
        .child("Maps")
        .child(_map!)
        .child("Players")
        .child(name);

    var endPos = await root.child("EPos").get();
    Pos end = Pos(endPos.value["x"], endPos.value["y"]);
    if(_start != end) {
      if(_end != end || _path == null) {
        _end = end;
        _generatePath();
      }
      _start = _path!.first;
      _path!.removeAt(0);
    }
  }

  void _generatePath() { // TODO pathfind with obstacles
    _path = List.empty(growable: true);
    while(_start.x != _end.x) {
      Pos p;
      if(_start.x < _end.x)
        p = Pos(_start.x + 1, _start.y);
      else
        p = Pos(_start.x - 1, _start.y);
    }

    while(_start.y != _end.y) {
      Pos p;
      if(_start.y < _end.y)
        p = Pos(_start.x, _start.y + 1);
      else
        p = Pos(_start.x, _start.y - 1);
    }
  }

  String get name => _name;
  String get session => _session;
  String? get map => _map;
  bool get status => _status;

  void set map(String? map) => _map = map;

}

class Pos {
  int x;
  int y;

  Pos(this.x, this.y);

  @override
  bool operator ==(Object other) {
    Pos pos = other as Pos;
    return this.x == pos.x && this.y == pos.y;
  }
}