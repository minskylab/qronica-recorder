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

class PlayerScreen extends StatefulWidget {
  PlayerScreen({Key? key}) : super(key: key);

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: BlocProvider(
        create: (context) => AudioplayerCubit(),
        child: BlocBuilder<AudioplayerCubit, AudioplayerState>(
          builder: (context, state) {
            return Center(
              child:
              ListView(children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 25, vertical: 15),
                            child:
                              Column(
                                  children: [
                                    Text(
                                      state.source == null
                                      ? "Seleccione el audio a reproducir"
                                      :"Reproduciendo audio: ${state.sourceName}",
                                      style: const TextStyle(height: 5, fontSize: 20),
                                    ),
                                    state.source == null
                                      ? Container()
                                      : Column(
                                        children: [
                                          Text("Audio: ${state.source}"),
                                          Text("Duration: ${state.duration}"),
                                          Text("New audio: ${state.newAudio}"),
                                        ],
                                      ),

                                    AudioPlayer(
                                      source: state.source,
                                      duration: state.duration,
                                      newAudio: state.newAudio,
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
                                )),
                        const SizedBox(
                          height: 26.0,
                        ),
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
                  ]),
            );
          },
        ),
      ),
    );

  }
}
