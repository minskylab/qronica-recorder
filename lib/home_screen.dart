import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qronica_recorder/cubit/login_cubit.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);


   Widget build(BuildContext context) {
    return Container(
            width: 700,
            child: Padding(
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
                    Container(
                        width: double.infinity,
                        child: RawMaterialButton(
                          fillColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 20.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          onPressed: () {
                            Navigator.of(context).pushNamed("/recorderScreen");
                          },
                          child: const Text("Grabar nuevo audio",
                          style: TextStyle(
                            color: Colors.white,
                          ),),
                        )),
                    const SizedBox(
                      height: 26.0,
                    ),
                    Container(
                        width: double.infinity,
                        child: RawMaterialButton(
                          fillColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 20.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          onPressed: () {
                            Navigator.of(context).pushNamed("/playerScreen");
                          },
                          child: const Text("Audios Grabados",
                            style: TextStyle(
                            color: Colors.white,
                          ),),
                        ))
                  ],
                )));
  }

}

