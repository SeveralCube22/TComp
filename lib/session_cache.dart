import 'dart:collection';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fluttertoast/fluttertoast.dart';

class SessionCache {
  static String? displayName;
  static String? sessionLink;

  static void setSession(String link) async {
    var root = FirebaseDatabase.instance.reference().child("Sessions");
    var sessions = await root.get();
    Map<Object?, Object?> data = sessions.value;
    Map<String, Object?> rData = data.cast<String, Object?>();

    print("TEST");
    if(rData.containsKey(link)) {
      print("HERE: ${sessionLink}");
      if (sessionLink != null) {
        root.child(sessionLink!).child("Players").child(displayName!).set({"Status": false});
      }
      root.child(link).child("Players").child(displayName!).set(
          {"Status": true});
      sessionLink = link;
    }
    else
      Fluttertoast.showToast(
          msg: "Session link does not exist",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1);
  }

  static void leave() {
    if(sessionLink != null)
      FirebaseDatabase.instance.reference().child("Sessions").child(sessionLink!).child("Players").child(displayName!).set({"Status": false});
  }
}
