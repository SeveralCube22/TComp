import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'login_page.dart';
import 'home_page.dart';

void main()
{
  runApp(MyApp());
}

class MyApp extends StatelessWidget
{
  @override
  Widget build(BuildContext context)
  {
    return FutureBuilder(
      future: Firebase.initializeApp(),
      builder: (context, snapshot) {
            if(snapshot.connectionState == ConnectionState.done)
              return FirebaseAuth.instance.currentUser == null ? LoginPage() : HomePage();
            else
              return HomePage(); //change this to an ERROR screen
        }
    );
  }
}



