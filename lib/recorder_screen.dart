import 'dart:convert';
import 'dart:math';

import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:custom_radio_grouped_button/custom_radio_grouped_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:qronica_recorder/cubit/audioplayer_cubit.dart';
import 'package:qronica_recorder/page_manager.dart';
import 'package:qronica_recorder/pocketbase.dart';
import 'package:qronica_recorder/storage_service.dart';
import 'package:qronica_recorder/audiorecorder.dart';

import 'notifiers/play_button_notifier.dart';
import 'notifiers/progress_notifier.dart';
import 'notifiers/repeat_button_notifier.dart';

class RecorderScreen extends StatefulWidget {
  RecorderScreen({Key? key}) : super(key: key);

  @override
  State<RecorderScreen> createState() => _RecorderScreenState();
}

late final PageManager _pageManager;


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
    _pageManager = PageManager();
  }
    @override
  void dispose() {
    _pageManager.dispose();
    super.dispose();
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
                          child: Column(
                            children: const [
                              //CurrentSongTitle(),
                              AudioProgressBar(),
                              AudioControlButtons(),
                            ],
                          )
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 25),
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
                                            ids.add(data.elementAt(i).id);
                                            return Column(
                                              children: [
                                                const Text(
                                                    "Opciones de guardado"),
                                                const Text(
                                                    "Seleccionar los proyectos a vincular:"),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          left: 500,
                                                          right: 500),
                                                  child:
                                                      CustomCheckBoxGroup(
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
                                                      print(values);
                                                    },
                                                    horizontal: true,
                                                    width: 50,
                                                    selectedColor:
                                                        Colors.blue,
                                                    padding: 5,
                                                    unSelectedColor:
                                                        Colors.white,
                                                  ),
                                                )
                                              ],
                                            );
                                          }
                                        }
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return const CircularProgressIndicator();
                                        }

                                        return Container();
                                      }
                                    ),
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
                          )
                        ),
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
                                                  onPressed: () async{
                                                    final url =
                                                        'http://127.0.0.1:8090/api/files/resources/${snapshot.data!.elementAt(index).id}/${snapshot.data!.elementAt(index).data['file']}';
                                                        const prefix = 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3';
                                                    _pageManager.addSong(url);
                                                    _pageManager.onNextSongButtonPressed;

                                                    //setState(() {
                                                    //  audioPath = url;
                                                    //  durationTotal = snapshot
                                                    //      .data!
                                                    //      .elementAt(index)
                                                    //      .data['duration'];
                                                    //  context
                                                    //      .read<
                                                    //          AudioplayerCubit>()
                                                    //      .notsaved(); //cambiar metodoo
                                                    //  context
                                                    //      .read<
                                                    //          AudioplayerCubit>()
                                                    //      .update(
                                                    //          audioPath,
                                                    //          snapshot.data!
                                                    //              .elementAt(
                                                    //                  index)
                                                    //              .id,
                                                    //          durationTotal,
                                                    //          true);
                                                    //});
                                                  },
                                                  style: ElevatedButton.styleFrom(
                                                      backgroundColor: state
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
                      print(path);
                      _pageManager.playSavedAudios(path, 3);
                      if (kDebugMode) print('Recorded file path: ');
                      setState(() {
                        audioPath = path;
                        showPlayer = true;
                        durationTotal = duration;
                        //context.read<AudioplayerCubit>().update(
                        //    audioPath, 'Audio Grabado', durationTotal, false);
                      });
                    },
                  ),
          );
        },
      ),
    );
  }
}

class CurrentSongTitle extends StatelessWidget {
  const CurrentSongTitle({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: _pageManager.currentSongTitleNotifier,
      builder: (_, title, __) {
        return Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(title, style: TextStyle(fontSize: 40)),
        );
      },
    );
  }
}

class AudioProgressBar extends StatelessWidget {
  const AudioProgressBar({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ProgressBarState>(
      valueListenable: _pageManager.progressNotifier,
      builder: (_, value, __) {
        return ProgressBar(
          progress: value.current,
          buffered: value.buffered,
          total: value.total,
          onSeek: _pageManager.seek,
        );
      },
    );
  }
}

class AudioControlButtons extends StatelessWidget {
  const AudioControlButtons({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          PlayButton(),
        ],
      ),
    );
  }
}

class PlayButton extends StatelessWidget {
  const PlayButton({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ButtonState>(
      valueListenable: _pageManager.playButtonNotifier,
      builder: (_, value, __) {
        switch (value) {
          case ButtonState.loading:
            return Container(
              margin: EdgeInsets.all(8.0),
              width: 32.0,
              height: 32.0,
              child: CircularProgressIndicator(),
            );
          case ButtonState.paused:
            return IconButton(
              icon: Icon(Icons.play_arrow),
              iconSize: 32.0,
              onPressed: _pageManager.play,
            );
          case ButtonState.playing:
            return IconButton(
              icon: Icon(Icons.pause),
              iconSize: 32.0,
              onPressed: _pageManager.pause,
            );
        }
      },
    );
  }
}