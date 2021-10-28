import 'dart:collection';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'map.dart';
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
                        FirebaseDatabase.instance.reference()
                            .child("Sessions")
                            .child(value)
                            .child("In Session")
                            .onChildChanged.listen((event) => refreshMap());
                       buildLoading();
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

  void buildLoading() {
    setState(() {
      currentWidget = Center(child: Text("Wait for host..."));
    });
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

  void refreshMap() {
    loadMap().then((map) {
      setState(() {
        currentWidget = ImageLoader(path: currentMap!, map: map);
      });
    });
  }


  @override
  Widget build(BuildContext context) {
    return currentWidget;
  }
}

