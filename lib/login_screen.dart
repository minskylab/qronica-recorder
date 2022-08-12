import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:qronica_recorder/recorder_screen.dart';

class LoginScreen extends StatefulWidget {
  LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  static Future<User?> login({
    required String email,
    required String password,
    required BuildContext context}) async {
    FirebaseAuth auth = FirebaseAuth.instance;
    User? user;
    try {
      UserCredential userCredential = await auth.signInWithEmailAndPassword(email: email, password: password);
      user = userCredential.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found')
      {
        print("User not found");
      }
    }
    return user;
  } 

  @override
  Widget build(BuildContext context) {
    TextEditingController _emailController =  TextEditingController();
    TextEditingController _passwordController = TextEditingController();  
    return Container(
      width: 700,
      child:Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Qronica",
            style: TextStyle(
              color: Colors.black,
              fontSize: 25.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(
            height: 44.0,
          ),
          TextField(
            controller : _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              hintText: "Correo",
              prefixIcon: Icon(Icons.mail)
            ),
          ),
          const SizedBox(
            height: 26.0,
          ),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              hintText: "Contraseña",
              prefixIcon: Icon(Icons.password)
            ),
          ),
          const SizedBox(
            height: 26.0,
          ),
          Container(
            width:double.infinity,
            child: RawMaterialButton(
              fillColor: Colors.blue,
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              onPressed: () async {
                print(_emailController.text);
                User? user = await login(email: _emailController.text, password: _passwordController.text, context: context);
                print(user);
                if (user != null)
                {
                  Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => RecorderScreen()));
                }
              },
              child: Text("Login"),
              )
          )
        ],
      )
    )
    );
  }
}