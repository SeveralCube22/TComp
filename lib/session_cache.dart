import 'dart:collection';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fluttertoast/fluttertoast.dart';

class SessionCache {
  static String? displayName;
  static String? sessionLink;

  static Future<bool> setSession(String link) async {
    var root = FirebaseDatabase.instance.reference().child("Sessions");
    var sessions = await root.get();
    Map<Object?, Object?> data = sessions.value;
    Map<String, Object?> rData = data.cast<String, Object?>();

    if(rData.containsKey(link)) {
      if (sessionLink != null) {
        root.child(sessionLink!).child("Players").child(displayName!).child("Status").set(false);
      }
      root.child(link).child("Players").child(displayName!).child("Status").set(true);
      root.child(link).child("Players").child(displayName!).child("Map").set("");
      sessionLink = link;
      return true;
    }
    else
     return false;
  }

  static void leave() {
    if(sessionLink != null)
      FirebaseDatabase.instance.reference()
          .child("Sessions")
          .child(sessionLink!)
          .child("Players")
          .child(displayName!)
          .child("Status")
          .set(false);
  }
}
