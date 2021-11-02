import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class Player {
  String _name;
  String _session;
  String? _map;
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
        .child("Players")
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
        .child("Players")
        .child(_name)
        .remove();
  }

  void storeAvatar(XFile avatar) {
    File file = File(avatar!.path);
    var name = "${_name}.png"; //TODO change
    FirebaseStorage.instance
        .ref()
        .child("Sessions/${_session}/Players/${map!}/${name}/")
        .putFile(file);
  }

  String get name => _name;
  String get session => _session;
  String? get map => _map;
  bool get status => _status;

  void set map(String? map) => _map = map;

}