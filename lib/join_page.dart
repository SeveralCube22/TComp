import 'dart:collection';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'session_cache.dart';

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
                String? name = FirebaseAuth.instance.currentUser!.displayName;
                SessionCache.displayName = name!;
                SessionCache.setSession(value);
              },
            )
          ],
        )
      ),
    );
  }
}
