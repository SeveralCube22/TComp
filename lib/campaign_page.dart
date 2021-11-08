import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'map_page.dart';
import 'input.dart';

class Campaign extends StatefulWidget {
  const Campaign({Key? key}) : super(key: key);

  @override
  _CampaignState createState() => _CampaignState();
}

class _CampaignState extends State<Campaign> {
  var _campaigns = [];
  String _uid = FirebaseAuth.instance.currentUser!.uid;

  _CampaignState() {
    FirebaseDatabase.instance
        .reference()
        .child("Users")
        .child(FirebaseAuth.instance.currentUser!.uid)
        .child("Campaigns")
        .once()
        .then((dataSnapshot) {
      dataSnapshot.value.forEach((k, v) {
        _campaigns.add(k.toString());
      });
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("My Campaigns")),
      body: ListView.builder(
        itemCount: _campaigns.length,
        itemBuilder: (BuildContext context, int index) {
          return Container(
              height: 50,
              margin: EdgeInsets.only(top: 5, bottom: 5, left: 20, right: 20),
              child: Row(children: [
                TextButton(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                MapPage(uid: _uid, name: _campaigns[index]))),
                    child: Text("${_campaigns[index]}"))
              ]));
        },
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: () async {
            String name = await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => Input(hintText: "Campaign Name")));
            if (name != null) {
              _campaigns.add(name);
              var root = FirebaseDatabase.instance.reference();
              root
                  .child("Users")
                  .child(_uid)
                  .child("Campaigns")
                  .child(name)
                  .set('');
              var cRoot = root.child("Campaigns").child("${_uid}_${name}");
              cRoot.child("Public").set("F");
              cRoot.child("Maps").set("");
              cRoot.child("Sessions").set("");
              setState(() {});
            }
          },
          tooltip: "Create Campaign",
          child: Icon(Icons.add)),
    );
  }
}
