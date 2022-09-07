import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:qronica_recorder/cubit/audioplayer_cubit.dart';
import 'package:qronica_recorder/pocketbase.dart';
import 'package:qronica_recorder/storage_service.dart';
import 'package:qronica_recorder/audio_player.dart';
import 'package:qronica_recorder/widgets/audiorecorder.dart';

class RecorderScreen extends StatefulWidget {
  RecorderScreen({Key? key}) : super(key: key);

  @override
  State<RecorderScreen> createState() => _RecorderScreenState();
}

class _RecorderScreenState extends State<RecorderScreen> {
  bool showPlayer = false;
  String audioPath = "";
  int durationTotal = 0;

  @override
  void initState() {
    showPlayer = false;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final StorageService storage = StorageService();
    return BlocProvider(
      create: (context) => AudioplayerCubit(),
      child: BlocBuilder<AudioplayerCubit, AudioplayerState>(
        builder: (context, state) {
          return Center(
            child: showPlayer
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                          padding: EdgeInsets.symmetric(horizontal: 25),
                          child: state.status == StatusAudioPlayer.ready ? Column(
                            children: [
                              Text("Audio: ${state.source}"),
                              Text("Duration: ${state.duration}"),
                              Text("New audio: ${state.newAudio}"),
                              AudioPlayer(
                                source: state.source!,
                                duration: state.duration!,
                                newAudio: state.newAudio!,
                                onDelete: () {
                                  setState(() => showPlayer = false);
                                },
                              ),
                            ],
                          ) : CircularProgressIndicator()
                          ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 25),
                        child: ElevatedButton(
                            onPressed: () async {
                              final path = audioPath;
                              var uri = Uri.dataFromString(audioPath);
                              final fileName = uri.pathSegments[3];
                              await storage.uploadAudio(
                                  path, fileName, durationTotal);
                              setState(() {
                                
                              });
                            },
                            child: const Text("Guardar audio")),
                      ),
                      const SizedBox(
                        height: 26.0,
                      ),
                      //StreamBuilder(
                      //  stream: storage.getRecord(),
                      //  builder: (context, snapshot) {
                      //  if (snapshot.connectionState == ConnectionState.done) {
                      //    var record = snapshot.data!; 
                      //    print('Snapshot: ${record}');
                      //    return Container();
                      //  } else {
                      //    return CircularProgressIndicator();
                      //  }
                      //  }
                      //),
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
                                      return Padding(
                                          padding: EdgeInsets.all(10),
                                          child: ElevatedButton(
                                            onPressed: () async {
                                              final url =
                                                  'http://127.0.0.1:8090/api/files/records/${snapshot.data!.elementAt(index).id}/${snapshot.data!.elementAt(index).data['audio']}';
                                              setState(() {
                                                audioPath = url;
                                                durationTotal = snapshot.data!
                                                    .elementAt(index)
                                                    .data['duration'];
                                              context.read<AudioplayerCubit>().update(audioPath, durationTotal, true);
                                              });
                                            },
                                            child: Text(snapshot.data!
                                                .elementAt(index)
                                                .id),
                                          ));
                                    },
                                  ));
                            }
                            if (snapshot.connectionState ==
                                    ConnectionState.waiting ||
                                !snapshot.hasData) {
                              return const CircularProgressIndicator();
                            }
                            return Container();
                          })
                    ],
                  )
                : AudioRecorder(
                    onStop: (path, duration) {
                      if (kDebugMode) print('Recorded file path: ');
                      setState(() {
                        audioPath = path;
                        showPlayer = true;
                        durationTotal = duration;
                        context.read<AudioplayerCubit>().update(audioPath, durationTotal, false);
                      });
                    },
                  ),
          );
        },
      ),
    );
  }
}

