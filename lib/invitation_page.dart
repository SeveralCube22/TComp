import 'package:firebase_database/firebase_database.dart';
import "package:flutter/material.dart";
import 'package:nanoid/nanoid.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:collection';
import 'player.dart';

class Invitation extends StatefulWidget {
  const Invitation(
      {Key? key, required this.sessions, required this.uid, required this.name})
      : super(key: key);

  final HashMap<String, String> sessions;
  final String uid, name;

  @override
  _InvitationState createState() => _InvitationState();
}

class _InvitationState extends State<Invitation> {
  var sessionController = TextEditingController();
  var currId = "";
  String? currSession;

  List<Player> players = [];

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
        temp.add(Player(name, currId, status));
      });
      players = temp;
      setState(() {

      });
    });
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
                Flexible(
                    child: Container(
                        width: 100.0,
                        child: TextField(
                            controller: sessionController,
                            onSubmitted: (value) {
                              if (widget.sessions.containsKey(value)) {
                                Fluttertoast.showToast(
                                    msg: "Session already exists",
                                    toastLength: Toast.LENGTH_LONG,
                                    gravity: ToastGravity.BOTTOM,
                                    timeInSecForIosWeb: 1);
                              } else
                                setState(() {
                                  widget.sessions.putIfAbsent(value, () => "");
                                  var id = nanoid(10);
                                  currId = id;
                                  currSession = value;
                                  var root = FirebaseDatabase.instance
                                      .reference();
                                  root.child("Campaigns")
                                      .child(widget.uid + "_" + widget.name)
                                      .child("Sessions")
                                      .child(value)
                                      .set({"Link": id});
                                  root.child("Sessions")
                                      .child(id)
                                      .set({"Players": "", "In Session":  {"In Session": false }});
                                });
                            },
                            decoration: InputDecoration(hintText: "Session")))),
                Padding(
                    padding: EdgeInsets.only(top: 16.0),
                    child: DropdownButton<String>(
                      hint: Icon(Icons.arrow_drop_down,
                          size: 30.0, color: Colors.white),
                      onChanged: (String? session) async {
                        if (session != null) {
                          var data = await FirebaseDatabase.instance
                              .reference()
                              .child("Campaigns")
                              .child(widget.uid + "_" + widget.name)
                              .child("Sessions")
                              .child(session)
                              .child("Link")
                              .get();

                          setState(() {
                            sessionController.text = session;
                            currId = data.value;
                            currSession = session;
                          });

                          _refreshPlayers();
                          FirebaseDatabase.instance.reference().child("Sessions").child(currId).child("Players").onChildChanged.listen((event) => _refreshPlayers());
                        }
                      },
                      items: widget.sessions.keys.map((String session) {
                        return DropdownMenuItem<String>(
                          value: session,
                          child: Row(
                            children: <Widget>[
                              SizedBox(
                                width: 10,
                              ),
                              Text(
                                session,
                                style: TextStyle(color: Colors.black),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ))
              ]),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[Text("Session Link: "), SelectableText(currId)],
          ),
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
          ElevatedButton(
              onPressed:() {
                Result res = Result();
                if(currSession == null)
                  res.inSession = false;
                else {
                  res.inSession = true;
                  res.session = currSession!;
                  res.players = players;
                  FirebaseDatabase.instance.reference() // TODO session cache to detect when DM leaves session
                                  .child("Sessions")
                                  .child(currId)
                                  .child("In Session")
                                  .child("In Session")
                                  .set(true);
                }
                Navigator.pop(context, res);
              },
              child: Text("Play"))
        ]),
      ),
    );
  }
}

class Result {
  late bool inSession;
  late String session;
  late List<Player> players;
}