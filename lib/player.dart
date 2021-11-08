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
  late int _speed;

  Player(this._name, this._session, this._status) {
    _speed = 10;
  }

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
        Pos startPos = Pos(value["SPos"]["x"], value["SPos"]["y"]);

        Player player = Player(key, session, true);
        player._map = map;
        player._start = startPos;
        player._end = startPos;
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
      if(!_path!.isEmpty) {
        _start = _path!.first;
        updateStart(_start);
        _path!.removeAt(0);
      }
    }
  }

  void updateStart(Pos pos) {
    var root = FirebaseDatabase.instance.reference()
        .child("Sessions")
        .child(_session)
        .child("Maps")
        .child(map!)
        .child("Players")
        .child(_name)
        .child("SPos");

    root.child("x").set(pos.x);
    root.child("y").set(pos.y);
  }

  void _generatePath() { // TODO pathfind with obstacles
    _path = List.empty(growable: true);
    int currX = _start.x;
    while(currX != _end.x) {
      Pos p;
      int x = currX;
      if(currX < _end.x)
        p = Pos(currX++, _start.y);
      else
        p = Pos(currX--, _start.y);
      for(int i = 0; i < _speed; i++) {
        _path!.add(Pos(x, _start.y));
      }
      _path!.add(p);
    }
    _path!.add(Pos(_end.x, _start.y));

    int currY = _start.y;
    while(currY != _end.y) {
      Pos p;
      int y = currY;
      if(currY < _end.y)
        p = Pos(currX, currY++);
      else
        p = Pos(currX, currY--);
      for(int i = 0; i < _speed; i++) {
        _path!.add(Pos(currX, y));
      }
      _path!.add(p);
    }
    _path!.add(Pos(currX, _end.y));
  }

  String get name => _name;
  String get session => _session;
  String? get map => _map;
  bool get status => _status;
  Pos get start => _start;

  void set map(String? map) => _map = map;
  void set end(Pos pos) {
    var root = FirebaseDatabase.instance.reference()
        .child("Sessions")
        .child(_session)
        .child("Maps")
        .child(map!)
        .child("Players")
        .child(_name)
        .child("EPos");

    root.child("x").set(pos.x);
    root.child("y").set(pos.y);
  }
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