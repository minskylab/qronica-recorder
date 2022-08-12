import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qronica_recorder/login_screen.dart';
import 'package:qronica_recorder/recorder_screen.dart';
import 'package:record/record.dart';

import 'package:qronica_recorder/audio_player.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyAqbVqvulnU-LcBmlT2EVCFKMGs8ZL2HmY",
      projectId: "qronica-7036c",
      messagingSenderId: "548636835753",
      appId: "1:548636835753:web:deb6b844dea28cab99ceb8",
        storageBucket: "qronica-7036c.appspot.com",
      )
  );
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
        future: getUser(),
        builder: (BuildContext context, AsyncSnapshot<bool> snapshot){
                    if (snapshot.data == true){
                        return RecorderScreen();
                    }
                      /// other way there is no user logged.
                      return MaterialApp(
                      home: Scaffold(
                        body: Center(
                          child: LoginScreen(),
                        ),
                      ),
                    );
          }
      );
  }

  Future<bool> getUser() async{
    User? user =  FirebaseAuth.instance.currentUser;
    print(user);
    if (user!=null){
      return true;
    }
    return false;
  }
}
