import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qronica_recorder/cubit/login_cubit.dart';
import 'package:qronica_recorder/home_screen.dart';
import 'package:qronica_recorder/init_screen.dart';
import 'package:qronica_recorder/library_screen.dart';
import 'package:qronica_recorder/local_storage.dart';
import 'package:qronica_recorder/login_screen.dart';
import 'package:qronica_recorder/player_screen.dart';
import 'package:qronica_recorder/recorder_screen.dart';
import 'package:toast/toast.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    ToastContext().init(context);
    return BlocProvider(
      create: (context) => LoginCubit(),
      child: BlocBuilder<LoginCubit, LoginState>(
        builder: (context, state) {
          return MaterialApp( 
            debugShowCheckedModeBanner: false,
            initialRoute: "/",
            routes: {
              '/': (_) => const InitScreen(),
              '/recorderScreen' :(_) => RecorderScreen(),
              '/playerScreen' : (_) => PlayerScreen()
            },
          );
        },
      ),
    );
  }
}
