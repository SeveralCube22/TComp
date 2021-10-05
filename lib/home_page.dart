import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'login_page.dart';
import 'campaign_page.dart';

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
                          Icons.logout_sharp,
                          size: 30.0,
                          color: Colors.white
                        ),
                      )
                  )
                ]
            ),
            body: Center(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      ElevatedButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => Campaign()));
                          },
                          child: Text("My Campaigns")
                      ),
                      ElevatedButton(
                          onPressed: () {

                          },
                          child: Text("Join Campaign")
                      )
                    ],
                  )
                )
            )
        )
    );
  }
}


