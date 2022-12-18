import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:qronica_recorder/audio_recorder.dart';
import 'package:qronica_recorder/cubit/login_cubit.dart';
import 'package:qronica_recorder/pocketbase.dart';
import 'package:qronica_recorder/storage_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);


   Widget build(BuildContext context) {
    return Container(
            width: 700,
            child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                      height: 77
                    ),
                    const Text(
                      "Grabaciones",
                      style: TextStyle(
                        color: Color(0XFF1E1E1E),
                        fontSize: 25.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(
                      height: 24.0,
                    ),
                    const Text(
                      "Para filtrar por proyecto, solo seleccione uno. ",
                      style: TextStyle(
                        color: Color(0XFF555555),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(
                      height: 24.0,
                    ),
                    Row(
                      children:[
                        const Padding(
                          padding: const EdgeInsets.only(right:30.0),
                          child: Icon(Icons.filter_list),
                        ),
                        Expanded(
                          child:DecoratedBox(
                        decoration: const BoxDecoration( 
                          color:Colors.white, //background color of dropdown button
                        ),
                        child: Padding(
                          padding: EdgeInsets.only(left:20, right:20),
                          child: DropdownButton<String>(
                            value: "Todos los proyectos",
                            isExpanded: true,
                            underline: Container(), //empty line
                            items: <String>["Todos los proyectos"].map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(
                                value,
                                style: const TextStyle(
                                  color: Color(0XFF555555),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              );
                            }).toList(),
                            onChanged: (_) {},
                          ),
                        )
                        )),
                      ]
                    ),
                    const SizedBox(
                      height: 44.0,
                    ),
                      Container(
                        padding: EdgeInsets.only(right:16, left:16),
                        height:340,
                        child: FutureBuilder(
                            future: StorageService().listFiles(),
                            builder: (BuildContext context,
                                AsyncSnapshot<List<RecordModel>> snapshot) {
                              if (snapshot.connectionState ==
                                      ConnectionState.done &&
                                  snapshot.hasData) {
                                return Container(
                                    height: 200,
                                    width: 400,
                                    child: ListView.builder(
                                      itemCount: snapshot.data!.length,
                                      itemBuilder:
                                        (BuildContext context, int index) {
                                        return Column(
                                          children: [
                                            Padding(
                                                padding: const EdgeInsets.all(10),
                                                child: ElevatedButton(
                                                  onPressed: () async {
                                                    final url =
                                                        '${PocketBaseSample.url}/api/files/resources/${snapshot.data!.elementAt(index).id}/${snapshot.data!.elementAt(index).data['file']}';
                                                  },
                                                  style: ElevatedButton.styleFrom(
                                                      primary: Colors.blue),
                                                  child: Text(snapshot.data!
                                                      .elementAt(index)
                                                      .id),
                                                ))
                                          ],
                                        );
                                      },
                                    ));
                              }
                              else if (snapshot.connectionState == ConnectionState.done &&
                              !snapshot.hasData){
                                  return Center(
                                    child: Column(
                                      children: const[
                                        Image(
                                          height:270,
                                          image: AssetImage("assets/images/headphones@4x.png"),
                                        ),
                                        SizedBox(
                                          height:30
                                        ),
                                        Text(
                                          "Aún no hay grabaciones. Crea una con el botón rojo de abajo para empezar a grabar.",
                                          style: TextStyle(
                                            color: Color(0XFF1E1E1E),
                                            fontSize: 14,
                                          ),
                                          textAlign: TextAlign.center,
                                        )
                                      ],
                                    ),
                                  );
                              }
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Center(child: const CircularProgressIndicator());
                              }
                              return Container();
                            }),
                      ),
                          Container(
                            child: AudioRecorder(
                              onStop: (path, audioPath) {
                              },
                            )
                          )
                  //  Container(
                  //      width: double.infinity,
                  //      child: RawMaterialButton(
                  //        fillColor: Colors.blue,
                  //        padding: const EdgeInsets.symmetric(vertical: 20.0),
                  //        shape: RoundedRectangleBorder(
                  //          borderRadius: BorderRadius.circular(12.0),
                  //        ),
                  //        onPressed: () {
                  //          Navigator.of(context).pushNamed("/recorderScreen");
                  //        },
                  //        child: const Text("Grabar nuevo audio",
                  //        style: TextStyle(
                  //          color: Colors.white,
                  //        ),),
                  //      )),
                  //  const SizedBox(
                  //    height: 26.0,
                  //  ),
                  //  Container(
                  //      width: double.infinity,
                  //      child: RawMaterialButton(
                  //        fillColor: Colors.blue,
                  //        padding: const EdgeInsets.symmetric(vertical: 20.0),
                  //        shape: RoundedRectangleBorder(
                  //          borderRadius: BorderRadius.circular(12.0),
                  //        ),
                  //        onPressed: () {
                  //          Navigator.of(context).pushNamed("/playerScreen");
                  //        },
                  //        child: const Text("Audios Grabados",
                  //          style: TextStyle(
                  //          color: Colors.white,
                  //        ),),
                  //      )
                  //      )
                  ],
                )));
  }

}

