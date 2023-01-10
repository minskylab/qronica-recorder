import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:qronica_recorder/audio_recorder.dart';
import 'package:qronica_recorder/cubit/audioplayer_cubit.dart';
import 'package:qronica_recorder/cubit/login_cubit.dart';
import 'package:qronica_recorder/player_route.dart';
import 'package:qronica_recorder/pocketbase.dart';
import 'package:qronica_recorder/session_storage.dart';
import 'package:qronica_recorder/storage_service.dart';

class HomeScreen extends StatefulWidget {

  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool showPlayer = false;
  bool saved = false;
    List<String> projectIds = [];
      String? durationTotal = "";

  final StorageService storage = StorageService();

  @override
  void initState() {
    showPlayer = false;
    saved = false;
    super.initState();
  }

  Future<void> asyncUpload(String? audioPath, String? duracion, String? name, BuildContext context, VoidCallback onSuccess) async {
    setState(() {
      saved = true;
      context.read<AudioplayerCubit>().uploading();
    });
    String path = "";
    if (!kIsWeb)
    {
      path = audioPath ?? '';
    }
    else{
     path = SessionStorageHelper.getValue(audioPath ?? '');
    }
    final fileName = name ?? '';
    await storage.uploadAudio(path, duracion ?? '00:00:00',fileName, projectIds);
    setState(() {
      saved = false;
    });
    onSuccess.call();
  }

    Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AudioplayerCubit(),
      child: BlocBuilder<AudioplayerCubit, AudioplayerState>(
        builder: (context, state) {
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
                        padding: EdgeInsets.only(right:30.0),
                        child: Icon(Icons.filter_list),
                      ),
                      Expanded(
                        child:DecoratedBox(
                        decoration: const BoxDecoration( 
                          color:Colors.white, //background color of dropdown button
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(left:20, right:20),
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
                    height: 20.0,
                  ),
                  Container(
                    width: double.infinity,
                    height:400,
                    child: FutureBuilder(
                      future: StorageService().listFiles(),
                      builder: (BuildContext context,
                        AsyncSnapshot<List<RecordModel>> snapshot) {
                          if (snapshot.connectionState == ConnectionState.done &&
                            snapshot.hasData) 
                            {
                              if(snapshot.data!.isEmpty)
                              {
                                return Center(
                                  child: Column(
                                    children: const[
                                      SizedBox(
                                        height: 40.0,
                                      ),
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
                              else
                              {
                                return ListView.builder(
                                  padding: EdgeInsets.zero,
                                  itemCount: snapshot.data!.length,
                                  itemBuilder:
                                    (BuildContext context, int index) {
                                      DateTime now = DateTime.now();
                                      String formattedDateNow = DateFormat('yyyy-MM-dd').format(now);
                                      DateTime recordDate =  DateTime.parse(snapshot.data!.elementAt(index).created);
                                      String formattedRecordDate = DateFormat('yyyy-MM-dd').format(recordDate);
                                      String time = DateFormat.Hm().format(recordDate);
                                      return InkWell(
                                        child: Container(
                                          padding: EdgeInsets.only(bottom: 20),
                                          width: double.infinity,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                snapshot
                                                  .data!
                                                  .elementAt(index)
                                                  .data['name'],
                                                style: Theme.of(context).textTheme.bodyText1?.merge(
                                                  const TextStyle(
                                                    fontWeight: FontWeight.w700, 
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ),
                                              Row(
                                                children: [
                                                  Text(
                                                    formattedDateNow == formattedRecordDate ?
                                                    "Hoy - $time" :
                                                    "$formattedRecordDate - $time",
                                                    style: Theme.of(context).textTheme.bodyText1?.merge(
                                                      const TextStyle(
                                                        fontWeight: FontWeight.w500, 
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ),
                                                  const Spacer(),
                                                  Text(
                                                    snapshot
                                                      .data!
                                                      .elementAt(index)
                                                      .data['metadata']['duration'],
                                                    style: Theme.of(context).textTheme.bodyText1?.merge(
                                                      const TextStyle(
                                                        fontWeight: FontWeight.w500, 
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  )
                                                ],
                                              ),
                                              Row(
                                                children: [
                                                  Text(
                                                    "",
                                                    style: Theme.of(context).textTheme.bodyText1?.merge(
                                                      const TextStyle(
                                                        fontWeight: FontWeight.w500, 
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ),
                                                  Spacer(),
                                                  Text(
                                                    "Titulo de proy.",
                                                    style: Theme.of(context).textTheme.bodyText1?.merge(
                                                      const TextStyle(
                                                        fontWeight: FontWeight.w500, 
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  )
                                                ],
                                              ),
                                            ],
                                          )
                                        ),
                                        onTap: () { 
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (context) => PlayerRoute(snapshot:snapshot
                                                  .data!
                                                  .elementAt(index))),
                                          ); 
                                        },
                                      );
                                  },
                                );
                              }
                        }
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: const CircularProgressIndicator());
                        }
                        return Container();
                      }
                    ),
                  ),
                  const SizedBox(
                    height:10
                  ),
                  Center(
                    child:  ClipOval(
                      child: Material(
                        color: Colors.black,
                        child:  TextButton(
                        onPressed: () {
                          showModalBottomSheet(
                              isScrollControlled: true,
                              context: context,
                              builder: (context) {
                                return Padding(
                                  padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom),
                                  child: Container(
                                    height:300,
                                    padding: EdgeInsets.all(30),
                                    child: BlocProvider(
                                      create: (context) => AudioplayerCubit(),
                                      child: 
                                        BlocBuilder<AudioplayerCubit, AudioplayerState>(
                                        builder: (context, state) {
                                          if (state.recorded == true) 
                                          {
                                            return Column(
                                              mainAxisSize: MainAxisSize.min,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: 
                                                [
                                                  Text(
                                                    "Guardar la grabación",
                                                    style: Theme.of(context).textTheme.bodyText1?.merge(
                                                      const TextStyle(
                                                        fontWeight: FontWeight.w700, 
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height:20),
                                                  Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [       
                                                      Text(
                                                        "Nombre de la grabación",
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
                                                          hintText: "Nombre", 
                                                        ),
                                                        onChanged: (val) {
                                                          context.read<AudioplayerCubit>().changeAudioName(val);
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                const SizedBox(
                                                  height: 30
                                                ),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Container(
                                                        child: RawMaterialButton(
                                                          fillColor: Color(0xffC4C4C4),
                                                          padding: const EdgeInsets.symmetric(vertical: 15.0),
                                                          onPressed: saved == false ? () {
                                                            Navigator.pop(context);
                                                          } : null,
                                                          child: const Text(
                                                            "Borrar",
                                                            style: TextStyle(
                                                                fontWeight: FontWeight.w500, 
                                                                fontSize: 14,
                                                            ),
                                                          ),
                                                        )
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                      width:100
                                                    ),
                                                    Expanded(
                                                      child: Container(
                                                        child: RawMaterialButton(
                                                          fillColor: Theme.of(context).primaryColor,
                                                          padding: const EdgeInsets.symmetric(vertical: 15.0),
                                                          onPressed: saved == false ? () =>
                                                            asyncUpload(state.source, state.duration ,state.sourceName ,context, () {
                                                            context
                                                              .read<AudioplayerCubit>()
                                                              .uploaded();
                                                            Navigator.pop(context);
                                                          }) : null,
                                                          child: const Text(
                                                            "Guardar",
                                                            style: TextStyle(
                                                                fontWeight: FontWeight.w500, 
                                                                fontSize: 14,
                                                              ),
                                                          ),
                                                        )
                                                      ),
                                                    )                                                  ],
                                                )
                                              ]
                                            ); 
                                          }
                                          else{
                                            return AudioRecorder(
                                              onStop: (path, audioPath, duration) {
                                                setState(() {
                                                durationTotal = duration;
                                                showPlayer = true;
                                                context.read<AudioplayerCubit>().recordComplete(audioPath ?? '');
                                                context.read<AudioplayerCubit>().update(
                                                  audioPath, 'Audio Grabado', durationTotal, false);
                                                });
                                              },
                                            );
                                          }
                                        }
                                      )
                                    )
                                  ),
                                );
                              },
                            );
                          },
                          //padding: EdgeInsets.all(8.0),
                          child: Ink(
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFFF5F5F5), width: 5),
                              color: const Color(0XFFFF463A),
                              borderRadius: BorderRadius.circular(40.0)
                            ),
                            child: const InkWell(
                              child: SizedBox(width: 50, height: 50),
                            ),
                          ),
                        ),
                      ),
                    ),
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
              )
            )
          );
        }
      ),
    );
  }
}

