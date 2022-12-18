import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qronica_recorder/cubit/login_cubit.dart';
import 'package:qronica_recorder/local_storage.dart';
import 'package:qronica_recorder/login_screen.dart';
import 'package:toast/toast.dart';

import 'home_screen.dart';

class InitScreen extends StatefulWidget {
  const InitScreen({Key? key}) : super(key: key);

  @override
  State<InitScreen> createState() => _InitScreenState();
}

class _InitScreenState extends State<InitScreen> {
  @override
  Widget build(BuildContext context) {
    ToastContext().init(context);
    return BlocProvider(
      create: (context) => LoginCubit(),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarBrightness: Brightness.light,
        ),
        child: Scaffold(
              //appBar: AppBar(actions: [
              //  BlocBuilder<LoginCubit, LoginState>(
              //    builder: (context, state) {
              //      if (state.status == StatusLogin.success ||
              //          LocalStorageHelper.getValue('loggedIn') == 'true') {
              //        return SizedBox(
              //            width: 60,
              //            child: InkWell(
              //                onTap: <Widget>() {
              //                  LocalStorageHelper.clearAll();
              //                  context.read<LoginCubit>().logout();
              //                },
              //                child: const Icon(Icons.logout)));
              //      }
              //      return Container();
              //    },
              //  ),
              //]),
              body: Center(
                child: BlocBuilder<LoginCubit, LoginState>(
                  builder: (context, state) {
                    if (state.status == StatusLogin.success ||
                        LocalStorageHelper.getValue('loggedIn') == 'true') {
                      return HomeScreen();
                    } else if (state.status == StatusLogin.initial) {
                      return LoginScreen();
                    }
                    if (state.status == StatusLogin.failure) {
                      Toast.show("Correo o contraseña incorrectos",
                          duration: Toast.lengthShort,
                          backgroundColor: Colors.red,
                          gravity: Toast.bottom);
                      context.read<LoginCubit>().cleanError();
                    } else if (state.status == StatusLogin.loading) {
                      return const CircularProgressIndicator();
                    }
                    return Container();
                  },
                ),
              ),
            ),
      )
    );
  }
}
