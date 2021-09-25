import 'dart:ffi';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Campaign extends StatefulWidget {
  const Campaign({Key? key}) : super(key: key);

  @override
  _CampaignState createState() => _CampaignState();
}

class _CampaignState extends State<Campaign> {
  var _campaigns = [];

  _CampaignState() {
    FirebaseDatabase.instance
        .reference()
        .child("Users")
        .child(FirebaseAuth.instance.currentUser!.uid)
        .child("Campaigns")
        .once()
        .then((dataSnapshot) {
      dataSnapshot.value.forEach((k, v) {
        print("DATA:" + k);
        _campaigns.add(k.toString());
      });
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Campaigns")),
      body: ListView.builder(
        itemCount: _campaigns.length,
        itemBuilder: (BuildContext context, int index) {
          return Container(
              height: 50,
              margin: EdgeInsets.only(top: 5, bottom: 5, left: 20, right: 20),
              child: Row(children: [Text("${_campaigns[index]}")]));
        },
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: () async {
            String name = await Navigator.push(context,
                MaterialPageRoute(builder: (context) => CampaignInput()));
            if(name != null){
              _campaigns.add(name);
              FirebaseDatabase.instance.reference().child("Users").child(FirebaseAuth.instance.currentUser!.uid).child("Campaigns").child(name).set('');
              FirebaseDatabase.instance.reference().child("Campaigns").child(FirebaseAuth.instance.currentUser!.uid + "_" + name).child("Public").set("F");
              setState(() {});
            };
          },
          tooltip: "Create Campaign",
          child: Icon(Icons.add)),
    );
  }
}

class CampaignInput extends StatefulWidget {
  const CampaignInput({Key? key}) : super(key: key);

  @override
  _CampaignInputState createState() => _CampaignInputState();
}

class _CampaignInputState extends State<CampaignInput> {
  var name = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
       child: Card(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  TextField(
                    controller: name,
                    decoration: InputDecoration(hintText: "Campaign Name"),
                  )
                ]
              )
            )
          ),
      floatingActionButton:
          FloatingActionButton(
              onPressed: (){
                Navigator.pop(context, name.text);
              },
              child: Icon(Icons.done)),
    );
  }
}
