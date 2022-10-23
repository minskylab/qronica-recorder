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
    return Scaffold(
      appBar: AppBar(),
      body: BlocProvider(
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
                              child: Column(
                                children: [
                                  const Text(
                                    "Reproduciendo audio",
                                    style: TextStyle(height: 5, fontSize: 20),
                                  ),
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
                              )),
                          Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 60),
                              child: BlocBuilder<AudioplayerCubit,
                                  AudioplayerState>(
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
                                                  ids.add(data.elementAt(i).id);
                                                }
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
                                                                const EdgeInsets
                                                                        .only(
                                                                    left: 5,
                                                                    right: 5),
                                                            child:
                                                                CustomCheckBoxGroup(
                                                              width: 10,
                                                              buttonLables:
                                                                  names,
                                                              buttonValuesList:
                                                                  ids,
                                                              checkBoxButtonValues:
                                                                  (values) {
                                                                for (int i = 0;
                                                                    i <
                                                                        values
                                                                            .length;
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
                                        const SizedBox(height: 20.0),
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
                        ],
                      ),
                    ])
                  : AudioRecorder(),
            );
          },
        ),
      ),
    );

  }
}
