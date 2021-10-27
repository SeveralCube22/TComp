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
  }

  void removePlayer(String map) {
    FirebaseDatabase.instance.reference()
        .child("Sessions")
        .child(_session)
        .child("Players")
        .child(_name)
        .child("Map")
        .set("");
  }

  String get name => _name;
  bool get status => _status;
}