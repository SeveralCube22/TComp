import 'dart:collection';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'map_board.dart';
import 'session_cache.dart';
import 'map_membership.dart';

class Join extends StatefulWidget {
  const Join({Key? key}) : super(key: key);

  @override
  _JoinState createState() => _JoinState();
}

class _JoinState extends State<Join> {
  late Widget currentWidget;
  late String? currentMap;

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
              children: <Widget>[
                TextField(
                  onSubmitted: (value) async {
                    String? name = FirebaseAuth.instance.currentUser!.displayName;
                    SessionCache.displayName = name!;
                    SessionCache.setSession(value).then((join) {
                      if(join) {
                        setState(() {
                          currentWidget = buildStream();
                        });
                      }
                      else {
                        Fluttertoast.showToast(
                            msg: "Session link does not exist",
                            toastLength: Toast.LENGTH_LONG,
                            gravity: ToastGravity.BOTTOM,
                            timeInSecForIosWeb: 1);
                      }
                    });
                  },
                )
              ],
            )
        ),
      );
    });
  }

 Widget buildStream() {
    return StreamBuilder(
      stream: FirebaseDatabase.instance.reference()
          .child("Sessions")
          .child(SessionCache.sessionLink!)
          .child("In Session")
          .onChildChanged,
      builder: (BuildContext context, AsyncSnapshot<Event> snapshot) {
        print("HERE: ${snapshot.data}");
        return snapshot.data == null ? buildLoading() : buildMap();
      },
    );
  }

  Widget buildLoading() {
    return Center(child: Text("Wait for host..."));
  }

  Future<List<List<String>>> loadMap() async {
    DataSnapshot data = await FirebaseDatabase.instance
        .reference()
        .child("Sessions")
        .child(SessionCache.sessionLink!)
        .child("Players")
        .child(SessionCache.displayName!)
        .child("Map")
        .get();

      setState(() {
        currentMap = data.value;
      });
      return Map.loadMap(currentMap!);
  }

 Future<Widget> refreshMap() async {
    List<List<String>> map = await loadMap();
    return ImageLoader(path: currentMap!, map: map);
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

