import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qronica_recorder/cubit/login_cubit.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  static Route route() =>
      MaterialPageRoute<void>(builder: (_) => const LoginScreen());

  Widget build(BuildContext context) {
    return BlocBuilder<LoginCubit, LoginState>(
      builder: (context, state) {
        return Container(
            width: 700,
            child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Image(
                      image: AssetImage("assets/images/qronicaLogo.png")
                    ),
                    const SizedBox(
                      height: 50.0,
                    ),
                    Text(
                      "Correo",
                      style: Theme.of(context).textTheme.bodyText1?.merge(
                        const TextStyle(
                          fontWeight: FontWeight.w500, 
                          fontSize: 14,
                        ),
                        ),
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    TextField(
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        fillColor: Color(0xFFFFFFFF),
                        filled: true,
                        hintText: "correo@dominio.com", 
                        prefixIcon: Icon(Icons.mail)
                      ),
                      onChanged: (val) {
                        context.read<LoginCubit>().changeEmailAddress(val);
                      },
                    ),
                    const SizedBox(
                      height: 32,
                    ),
                    Text(
                      "Contraseña",
                      style: Theme.of(context).textTheme.bodyText1?.merge(
                        const TextStyle(
                          fontWeight: FontWeight.w500, 
                          fontSize: 14,
                        ),
                        ),
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    TextField(
                      obscureText: true,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        fillColor: Color(0xFFFFFFFF),
                        filled: true,
                        hintText: "Contraseña", 
                        prefixIcon: Icon(Icons.password)
                      ),
                      onChanged: (val) {
                        context.read<LoginCubit>().changePassword(val);
                      },
                    ),
                    const SizedBox(
                      height: 26.0,
                    ),
                    Container(
                        width: double.infinity,
                        child: RawMaterialButton(
                          fillColor: Theme.of(context).primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 20.0),
                          onPressed: () {
                            context.read<LoginCubit>().login();
                          },
                          child: const Text(
                          "Ingresar",
                          style: TextStyle(
                              fontWeight: FontWeight.w500, 
                              fontSize: 14,
                            ),
                        ),
                        ))
                  ],
                )));
      },
    );
  }
}