import 'dart:collection';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class Join extends StatefulWidget {
  const Join({Key? key}) : super(key: key);

  @override
  _JoinState createState() => _JoinState();
}

class _JoinState extends State<Join> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Join")),
      body: Center(
        child: Column(
          children: <Widget>[
            TextField(
              onSubmitted: (value) async {
                var root = FirebaseDatabase.instance.reference()
                    .child("Sessions")
                    .child(value)
                    .child("Players");
                String? name = FirebaseAuth.instance.currentUser!.displayName;

                var data = await root.get();
                try {
                  var players = data.value;
                  bool found = false;
                  players.forEach((key, value) {
                    if (key == name!) {
                      found = true;
                      var playerInfo = value;
                      playerInfo["Status"] = true;
                    }
                  });
                  if (!found) {
                    root.child(name!).set({"Status": true});
                  }
                }
                catch(e) {
                  root.child(name!).set({"Status": true});
                }
              },
            )
          ],
        )
      ),
    );
  }
}
