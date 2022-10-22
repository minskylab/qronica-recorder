import 'dart:convert';
import 'dart:math';

import 'package:custom_radio_grouped_button/custom_radio_grouped_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:qronica_recorder/cubit/audioplayer_cubit.dart';
import 'package:qronica_recorder/pocketbase.dart';
import 'package:qronica_recorder/storage_service.dart';
import 'package:qronica_recorder/audio_player.dart';
import 'package:qronica_recorder/audiorecorder.dart';

class RecorderScreen extends StatefulWidget {
  RecorderScreen({Key? key}) : super(key: key);

  @override
  State<RecorderScreen> createState() => _RecorderScreenState();
}

class _RecorderScreenState extends State<RecorderScreen> {
  bool showPlayer = false;
  String audioPath = "";
  int durationTotal = 0;
  List<String> projectIds = [];
  final StorageService storage = StorageService();

  @override
  void initState() {
    showPlayer = false;
    super.initState();
  }

  Future<void> asyncUpload(BuildContext context, VoidCallback onSuccess) async {
    setState(() {
      context.read<AudioplayerCubit>().uploading();
    });
    final path = audioPath;
    var uri = Uri.dataFromString(audioPath);
    final fileName = uri.pathSegments[3];
    await storage.uploadAudio(path, fileName, durationTotal, projectIds);

    onSuccess.call();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AudioplayerCubit(),
      child: BlocBuilder<AudioplayerCubit, AudioplayerState>(
        builder: (context, state) {
          return Center(
            child: showPlayer
                ? ListView(children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 25, vertical: 15),
                            child:
                                BlocBuilder<AudioplayerCubit, AudioplayerState>(
                                    builder: ((context, state) {
                              if (state.status == StatusAudioPlayer.ready) {
                                if (state.uploaded == StatusAudioUpload.done ||
                                    state.uploaded ==
                                        StatusAudioUpload.unsaved) {
                                  return Column(
                                    children: [
                                      Text(
                                        "Reproduciendo audio: ${state.sourceName}",
                                        style:
                                            const TextStyle(height: 5, fontSize: 20),
                                      ),
                                      Text("Audio: ${state.source}"),
                                      Text("Duration: ${state.duration}"),
                                      Text("New audio: ${state.newAudio}"),
                                      AudioPlayer(
                                        source: state.source!,
                                        duration: state.duration!,
                                        newAudio: state.newAudio!,
                                        option: 'back',
                                        onDelete: () {
                                          setState(() {
                                            context
                                                .read<AudioplayerCubit>()
                                                .notUploaded();
                                            showPlayer = false;
                                          });
                                        },
                                      ),
                                    ],
                                  );
                                }
                                return Column(
                                  children: [
                                    Text(
                                      "Reproduciendo audio: ${state.sourceName}",
                                      style: const TextStyle(height: 5, fontSize: 20),
                                    ),
                                    Text("Audio: ${state.source}"),
                                    Text("Duration: ${state.duration}"),
                                    Text("New audio: ${state.newAudio}"),
                                    AudioPlayer(
                                      source: state.source!,
                                      duration: state.duration!,
                                      newAudio: state.newAudio!,
                                      option: 'new',
                                      onDelete: () {
                                        setState(() {
                                          context
                                              .read<AudioplayerCubit>()
                                              .notUploaded();
                                          showPlayer = false;
                                        });
                                      },
                                    ),
                                  ],
                                );
                              } else {
                                return const CircularProgressIndicator();
                              }
                            }))),
                        Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 60),
                            child:
                                BlocBuilder<AudioplayerCubit, AudioplayerState>(
                              builder: ((context, state) {
                                if (state.uploaded == StatusAudioUpload.yet) {
                                  return Column(
                                    children: [
                                      FutureBuilder(
                                          future: storage.listProjects(),
                                          builder: (BuildContext context,
                                              AsyncSnapshot<List<RecordModel>>
                                                  snapshot) {
                                            if (snapshot.connectionState ==
                                                    ConnectionState.done &&
                                                snapshot.hasData) {
                                              var data = snapshot.data;
                                              final names = <String>[];
                                              final ids = <String>[];
                                              for (int i = 0;
                                                  i < data!.length;
                                                  i++) {
                                                names.add(data
                                                    .elementAt(i)
                                                    .data['name']);
                                                ids.add(data.elementAt(i).id);}
                                                return Column(
                                                  children: [
                                                    const Text(
                                                        "Opciones de guardado"),
                                                    const Text(
                                                        "Seleccionar los proyectos a vincular:"),
                                                    Container(
                                                      width: 200,
                                                      child: Column(
                                                        children: [
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets.only(
                                                                    left: 5,
                                                                    right: 5),
                                                            child:
                                                              CustomCheckBoxGroup(
                                                              width: 10,
                                                              buttonLables: names,
                                                              buttonValuesList: ids,
                                                              checkBoxButtonValues:
                                                                  (values) {
                                                                for (int i = 0;
                                                                    i < values.length;
                                                                    i++) {
                                                                  projectIds.add(
                                                                      values[i]
                                                                          .toString());
                                                                }
                                                              },
                                                              horizontal: true,
                                                              selectedColor:
                                                                  Colors.blue,
                                                              padding: 5,
                                                              unSelectedColor:
                                                                  Colors.white,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    )
                                                  ],
                                                );
                                              
                                            }
                                            if (snapshot.connectionState ==
                                                ConnectionState.waiting) {
                                              return const CircularProgressIndicator();
                                            }

                                            return Container();
                                          }),
                                      const SizedBox(height:20.0),
                                      ElevatedButton(
                                          onPressed: () =>
                                              asyncUpload(context, () {
                                                context
                                                    .read<AudioplayerCubit>()
                                                    .uploaded();
                                              }),
                                          child: const Text("Guardar audio"))
                                    ],
                                  );
                                } else if (state.uploaded ==
                                    StatusAudioUpload.inProgress) {
                                  return const CircularProgressIndicator();
                                } else if (state.uploaded ==
                                    StatusAudioUpload.done) {
                                  return const Text("Guardado");
                                } else {
                                  return Container();
                                }
                              }),
                            )),
                        const SizedBox(
                          height: 26.0,
                        ),
                        //StreamBuilder(
                        //  stream: storage.getRecord(),
                        //  builder: (context, snapshot) {
                        //  if (snapshot.connectionState == ConnectionState.done) {
                        //    var record = snapshot.data!;
                        //    print('Snapshot: ');
                        //    return Container();
                        //  } else {
                        //    return CircularProgressIndicator();
                        //  }
                        //  }
                        //),
                        const Text(
                          "Audios guardados",
                          style: TextStyle(
                              height: 5, fontSize: 15),
                        ),
                        FutureBuilder(
                            future: storage.listFiles(),
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
                                                    setState(() {
                                                      audioPath = url;
                                                      durationTotal = snapshot
                                                          .data!
                                                          .elementAt(index)
                                                          .data['metadata']['duration'];
                                                      context
                                                          .read<
                                                              AudioplayerCubit>()
                                                          .notsaved(); //cambiar metodoo
                                                      context
                                                          .read<
                                                              AudioplayerCubit>()
                                                          .update(
                                                              audioPath,
                                                              snapshot.data!
                                                                  .elementAt(
                                                                      index)
                                                                  .id,
                                                              durationTotal,
                                                              true);
                                                    });
                                                  },
                                                  style: ElevatedButton.styleFrom(
                                                      primary: state
                                                                  .sourceName ==
                                                              snapshot.data!
                                                                  .elementAt(
                                                                      index)
                                                                  .id
                                                          ? Colors.green
                                                          : Colors.blue),
                                                  child: Text(snapshot.data!
                                                      .elementAt(index)
                                                      .id),
                                                ))
                                          ],
                                        );
                                      },
                                    ));
                              }
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const CircularProgressIndicator();
                              }

                              return Container();
                            })
                      ],
                    ),
                  ])
                : AudioRecorder(
                    onStop: (path, duration) {
                      if (kDebugMode) print('Recorded file path: ');
                      setState(() {
                        audioPath = path;
                        showPlayer = true;
                        durationTotal = duration;
                        context.read<AudioplayerCubit>().update(
                            audioPath, 'Audio Grabado', durationTotal, false);
                      });
                    },
                  ),
          );
        },
      ),
    );
  }
}
