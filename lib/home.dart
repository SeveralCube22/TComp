import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'login.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomeScreen()
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
            appBar: AppBar(
                title: Text("Home"),
                actions: <Widget> [
                  Padding(
                      padding: EdgeInsets.only(right: 20.0),
                      child: GestureDetector(
                        onTap: () {
                          Future.wait([FirebaseAuth.instance.signOut(), GoogleSignIn().signOut()])
                                .whenComplete(() =>  Navigator.pushReplacement(context,
                                                                               MaterialPageRoute(builder: (context) => LoginPage())));
                        },
                        child: Icon(
                          Icons.account_circle,
                          size: 30.0,
                        ),
                      )
                  )
                ]
            ),
            body: Center(
                child: Text("Home")
            )
        )
    );
  }
}

