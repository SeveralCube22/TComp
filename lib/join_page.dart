import 'dart:collection';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'map_board.dart';
import 'player.dart';
import 'session_cache.dart';
import 'map_membership.dart';

class Join extends StatefulWidget {
  const Join({Key? key}) : super(key: key);

  @override
  _JoinState createState() => _JoinState();
}

class _JoinState extends State<Join> {
  late Widget currentWidget;
  late Player player;
  late String? currentMap;
  late XFile? avatar;

  @override
  void initState() {
    super.initState();
    buildSelectSession();
  }

  void buildSelectSession() {
    setState(() {
      currentWidget = Scaffold(
        appBar: AppBar(title: Text("Join")),
        body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  width: 150,
                  child: TextField(
                    onSubmitted: (value) async {
                      String? name = FirebaseAuth.instance.currentUser!.displayName;
                      SessionCache.displayName = name!;
                      SessionCache.setSession(value).then((join) {
                        if(!join) {
                          Fluttertoast.showToast(
                              msg: "Session link does not exist",
                              toastLength: Toast.LENGTH_LONG,
                              gravity: ToastGravity.BOTTOM,
                              timeInSecForIosWeb: 1);
                        }
                      });
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 50),
                  child: ElevatedButton(
                      onPressed: () => getAvatar(),
                      child: Text("Choose avatar")
                  )
                ),
                ElevatedButton(
                    onPressed:() {
                      if(SessionCache.sessionLink != null && avatar != null) {
                        setState(() {
                          player = Player(SessionCache.displayName!, SessionCache.sessionLink!, true);
                          currentWidget = buildStream();
                        });
                      }
                    },
                    child: Text("Play"))
              ],
            )
        ),
      );
    });
  }

  void getAvatar() async {
    ImagePicker picker = ImagePicker();
    avatar = await picker.pickImage(source: ImageSource.gallery);
  }

 Widget buildStream() {
    return StreamBuilder(
      stream: FirebaseDatabase.instance.reference()
          .child("Sessions")
          .child(SessionCache.sessionLink!)
          .child("Players")
          .child(SessionCache.displayName!)
          .child("Map")
          .onChildChanged,
      builder: (BuildContext context, AsyncSnapshot<Event> snapshot) {
        return snapshot.data == null ? buildLoading() : buildMap();
      },
    );
  }

  Widget buildLoading() {
    return Center(child: Text("Wait for host..."));
  }

  Future<List<List<String>>?> loadMap() async {
    DataSnapshot data = await FirebaseDatabase.instance
        .reference()
        .child("Sessions")
        .child(SessionCache.sessionLink!)
        .child("Players")
        .child(SessionCache.displayName!)
        .child("Map")
        .child("Map")
        .get();

      if(data.value != "") {
        setState(() {
          currentMap = data.value;
          player.map = data.value;
          player.storeAvatar(avatar!);
        });
        return Map.loadMap(currentMap!);
      }
      return null;
  }

 Future<Widget> refreshMap() async {
    List<List<String>>? map = await loadMap();
    if(map != null)
      return ImageLoader(path: currentMap!, player: player, session: player.session, map: map);
    return buildLoading();
  }

  Widget buildMap() {
    return FutureBuilder(
      future: refreshMap(),
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        return snapshot.hasData ? snapshot.data : buildLoading();
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return currentWidget;
  }
}

