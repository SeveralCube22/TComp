import 'package:firebase_database/firebase_database.dart';
import 'session_cache.dart';

class Player {
  String _name;
  String _session;
  bool _status;

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
        .child(_name)
        .set({"Pos": {"x": 0, "y": 0}});
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
        .child(_name)
        .remove();
  }

  String get name => _name;
  bool get status => _status;
}