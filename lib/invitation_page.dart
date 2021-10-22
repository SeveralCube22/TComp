import 'package:firebase_database/firebase_database.dart';
import "package:flutter/material.dart";
import 'package:nanoid/nanoid.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:collection';

class Invitation extends StatefulWidget {
  const Invitation(
      {Key? key, required this.session, required this.uid, required this.name})
      : super(key: key);

  final String? session;
  final String uid, name;

  @override
  _InvitationState createState() => _InvitationState();
}

class _InvitationState extends State<Invitation> {
  Widget? sessionWidget;
  bool sessionEdit = true;

  String currId = "";
  List<Player> players = [];

  void initState() {
    super.initState();
    sessionWidget = widget.session == null ? _buildSessionWidget(true) : _buildSessionWidget(false);
    if(widget.session != null) {
      _getCurrId().then((value) {
        currId = value;
        _refreshPlayers();
        FirebaseDatabase.instance.reference().child("Sessions").child(currId).child("Players").onChildChanged.listen((event) => _refreshPlayers());
      });
    }
  }

  void _refreshPlayers() {
    FirebaseDatabase.instance
        .reference()
        .child("Sessions")
        .child(currId)
        .child("Players")
        .once().then((data) {
      List<Player> temp = [];
      data.value.forEach((key, value) {
        String name = key;
        var player = value;
        bool status = player["Status"];
        temp.add(Player(name, status));
      });
      players = temp;
      setState(() {
      });
    });
  }

  Future<String> _getCurrId() async {
    var session = await FirebaseDatabase.instance.reference()
        .child("Campaigns")
        .child(widget.uid + "_" + widget.name)
        .child("Sessions")
        .child(widget.session!)
        .child("Link")
        .get();

    return session.value;
  }

  /* TODO
      - Text field is still editable after on submit.
   */
  Widget _buildSessionWidget(bool edit) {
    var controller = TextEditingController();
    controller.text = edit ? "" : widget.session!;
    return Flexible(
        child: Container(
            width: 100.0,
            child: TextField(
                controller: controller,
                enabled: edit,

                onSubmitted: (value) {
                  setState(() {
                    if(sessionEdit) { // Temporary solution to prevent adding sessions every time user changes and clicks enter
                      var id = nanoid(10);
                      currId = id;
                      var root = FirebaseDatabase.instance.reference();
                      root.child("Campaigns")
                          .child(widget.uid + "_" + widget.name)
                          .child("Sessions")
                          .child(value)
                          .set({"Link": id});
                      root.child("Sessions")
                          .child(id)
                          .set({"Players": "", "In Session": false});
                      sessionEdit = false;
                    }
                  });
                },
                decoration: InputDecoration(hintText: edit ? "Session" : ""))));
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Invitation")),
      body: Center(
        child: Wrap(alignment: WrapAlignment.center, runSpacing: 30, children: <Widget>[
          Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                sessionWidget!, ]),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[Text("Session Link: "), SelectableText(currId)],),
          Container(
            height: 200,
            child: ListView.builder(
                itemCount: players.length,
                itemBuilder: (context, index) {
                  return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(Icons.circle,
                            color: (players[index].status ? Colors.green : Colors.red),
                            size: 20.0),
                        Text(players[index].name)
                      ]
                  );
                }
            ),
          ),
          ElevatedButton(onPressed:() => null, child: Text("Play"))
        ]),
      ),
    );
  }
}

class Player {
  String name;
  bool status;

  Player(this.name, this.status);
}



