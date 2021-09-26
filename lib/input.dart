import 'package:flutter/material.dart';

class Input extends StatefulWidget {
  const Input({Key? key, required this.hintText}) : super(key: key);

  final String hintText;

  @override
  _InputState createState() => _InputState(hintText);
}

class _InputState extends State<Input> {
  String _hintText;
  var _name = TextEditingController();

  _InputState(this._hintText);

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
                      controller: _name,
                      decoration: InputDecoration(hintText: _hintText),
                    )
                  ]
              )
          )
      ),
      floatingActionButton:
      FloatingActionButton(
          onPressed: (){
            Navigator.pop(context, _name.text);
          },
          child: Icon(Icons.done)),
    );
  }
}