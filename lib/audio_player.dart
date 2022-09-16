import 'dart:async';

import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:just_audio/just_audio.dart' as ja; 
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';


class AudioPlayer extends StatefulWidget {
  /// Path from where to play recorded audio
  late String source;
  late int duration;
  late bool newAudio;
  late String option;

  /// Callback when audio file should be removed
  /// Setting this to null hides the delete button
  final VoidCallback onDelete;

  AudioPlayer({
    Key? key,
    required this.source,
    required this.duration,
    required this.newAudio,
    required this.onDelete,
    required this.option,
  }) : super(key: key);

  @override
  AudioPlayerState createState() => AudioPlayerState();


}

class AudioPlayerState extends State<AudioPlayer> {
  final progressNotifier = ValueNotifier<ProgressBarState>(
    ProgressBarState(
      current: Duration.zero,
      buffered: Duration.zero,
      total: Duration.zero,
    ),
  );
  final buttonNotifier = ValueNotifier<ButtonState>(ButtonState.paused);
  final _audioPlayer = ja.AudioPlayer();                   // Create a player

  @override
  void initState() {
    super.initState();
    _init();

  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }


  void _init() async {
    print('llamando}');
    await _audioPlayer.setUrl(widget.source);
    _audioPlayer.playerStateStream.listen((playerState) {
      final isPlaying = playerState.playing;
      final processingState = playerState.processingState;
      if (processingState == ProcessingState.loading ||
          processingState == ProcessingState.buffering) {
        buttonNotifier.value = ButtonState.loading;
      } else if (!isPlaying) {
        buttonNotifier.value = ButtonState.paused;
      } else if (processingState != ProcessingState.completed) {
        buttonNotifier.value = ButtonState.playing;
      } else {
        _audioPlayer.seek(Duration.zero);
        _audioPlayer.pause();
      }
    });

    _audioPlayer.positionStream.listen((position) {
      final oldState = progressNotifier.value;
      progressNotifier.value = ProgressBarState(
        current: position,
        buffered: oldState.buffered,
        total: oldState.total,
      );
    });

    //_audioPlayer.bufferedPositionStream.listen((bufferedPosition) {
    //  final oldState = progressNotifier.value;
    //  progressNotifier.value = ProgressBarState(
    //    current: oldState.current,
    //    buffered: bufferedPosition,
    //    total: oldState.total,
    //  );
    //});

    _audioPlayer.durationStream.listen((totalDuration) {
      final oldState = progressNotifier.value;
      progressNotifier.value = ProgressBarState(
        current: oldState.current,
        buffered: oldState.buffered,
        total: Duration(milliseconds:widget.duration),
      );
    });
  }

  void play() async {
    print("widgets audio:${widget.newAudio}");
    print("widgets source:${widget.source}");
    if (widget.newAudio == true) {
    await _audioPlayer.setUrl(widget.source);
      widget.newAudio = false;
    }
    _audioPlayer.play();
  }

  void pause() {
    _audioPlayer.pause();
  }

  void seek(Duration position) {
    _audioPlayer.seek(position);
  }

    @override
  Widget build(BuildContext context) {
    return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              ValueListenableBuilder<ProgressBarState>(
                valueListenable: progressNotifier,
                builder: (_, value, __) {
                  return ProgressBar(
                    progress: value.current,
                    buffered: value.buffered,
                    total: value.total,
                    onSeek: seek,
                  );
                },
              ),
              ValueListenableBuilder<ButtonState>(
                valueListenable: buttonNotifier,
                builder: (_, value, __) {
                  switch (value) {
                    case ButtonState.loading:
                      return Container(
                        margin: const EdgeInsets.all(8.0),
                        width: 32.0,
                        height: 32.0,
                        child: const CircularProgressIndicator(),
                      );
                    case ButtonState.paused:
                      return IconButton(
                        icon: const Icon(Icons.play_arrow),
                        iconSize: 32.0,
                        onPressed: play,
                      );
                    case ButtonState.playing:
                      return IconButton(
                        icon: const Icon(Icons.pause),
                        iconSize: 32.0,
                        onPressed:pause,
                      );
                  }
                },
              ),
              IconButton(
              icon: Icon(
                widget.option == "back" ? Icons.arrow_back_ios_new_sharp:Icons.delete,
                  color: Color(0xFF73748D), size: 24),
              onPressed: () {
                pause();
                widget.onDelete();
              },
            ),
            ],
          ),
        );
  }
}

class ProgressBarState {
  ProgressBarState({
    required this.current,
    required this.buffered,
    required this.total,
  });
  final Duration current;
  final Duration buffered;
  final Duration total;
}

enum ButtonState { paused, playing, loading }