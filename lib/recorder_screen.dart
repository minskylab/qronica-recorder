import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:qronica_recorder/storage_service.dart';
import 'package:record/record.dart';

import 'package:qronica_recorder/audio_player.dart';



class AudioRecorder extends StatefulWidget {
  final void Function(String path, int duration) onStop;

  const AudioRecorder({
    Key? key,
    required this.onStop,
  }) : super(key: key);

  @override
  _AudioRecorderState createState() => _AudioRecorderState();
}

class _AudioRecorderState extends State<AudioRecorder> {
  bool _isRecording = false;
  bool _isPaused = false;
  int _recordDuration = 0;
  Timer? _timer;
  Timer? _ampTimer;
  final _audioRecorder = Record();
  Amplitude? _amplitude;
  DateTime? _inicio;
  DateTime? _final;

  @override
  void initState() {
    _isRecording = false;
    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ampTimer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                _buildRecordStopControl(),
                const SizedBox(width: 20),
                _buildPauseResumeControl(),
                const SizedBox(width: 20),
                _buildText(),
              ],
            ),
            if (_amplitude != null) ...[
              const SizedBox(height: 40),
              Text('Current: ${_amplitude?.current ?? 0.0}'),
              Text('Max: ${_amplitude?.max ?? 0.0}'),
            ],
          ],
        );
  }

  Widget _buildRecordStopControl() {
    late Icon icon;
    late Color color;

    if (_isRecording || _isPaused) {
      icon = const Icon(Icons.stop, color: Colors.red, size: 30);
      color = Colors.red.withOpacity(0.1);
    } else {
      final theme = Theme.of(context);
      icon = Icon(Icons.mic, color: theme.primaryColor, size: 30);
      color = theme.primaryColor.withOpacity(0.1);
    }

    return ClipOval(
      child: Material(
        color: color,
        child: InkWell(
          child: SizedBox(width: 56, height: 56, child: icon),
          onTap: () {
            _isRecording ? _stop() : _start();
          },
        ),
      ),
    );
  }

  Widget _buildPauseResumeControl() {
    if (!_isRecording && !_isPaused) {
      return const SizedBox.shrink();
    }

    late Icon icon;
    late Color color;

    if (!_isPaused) {
      icon = const Icon(Icons.pause, color: Colors.red, size: 30);
      color = Colors.red.withOpacity(0.1);
    } else {
      final theme = Theme.of(context);
      icon = const Icon(Icons.play_arrow, color: Colors.red, size: 30);
      color = theme.primaryColor.withOpacity(0.1);
    }

    return ClipOval(
      child: Material(
        color: color,
        child: InkWell(
          child: SizedBox(width: 56, height: 56, child: icon),
          onTap: () {
            _isPaused ? _resume() : _pause();
          },
        ),
      ),
    );
  }

  Widget _buildText() {
    if (_isRecording || _isPaused) {
      return _buildTimer();
    }

    return const Text("Waiting to record");
  }

  Widget _buildTimer() {
    final String minutes = _formatNumber(_recordDuration ~/ 60);
    final String seconds = _formatNumber(_recordDuration % 60);

    return Text(
      '$minutes : $seconds',
      style: const TextStyle(color: Colors.red),
    );
  }

  String _formatNumber(int number) {
    String numberStr = number.toString();
    if (number < 10) {
      numberStr = '0' + numberStr;
    }

    return numberStr;
  }

  Future<void> _start() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        // We don't do anything with this but printing
        final isSupported = await _audioRecorder.isEncoderSupported(
          AudioEncoder.aacLc,
        );
        if (kDebugMode) {
          print('${AudioEncoder.aacLc.name} supported: $isSupported');
        }

        await _audioRecorder.start(
            // encoder: AudioEncoder.wav
            );

        bool isRecording = await _audioRecorder.isRecording();
        setState(() {
          _isRecording = isRecording;
          _recordDuration = 0;
        });

        _startTimer();
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  Future<void> _stop() async {
    _timer?.cancel();
    _final = DateTime.now();
    _ampTimer?.cancel();
    final path = await _audioRecorder.stop();
    int mili = _final!.difference(_inicio!).inMilliseconds;
    print('miliiis:$mili');

    widget.onStop(path!, mili);

    setState(() => _isRecording = false);
  }

  Future<void> _pause() async {
    _timer?.cancel();
    _ampTimer?.cancel();
    await _audioRecorder.pause();

    setState(() => _isPaused = true);
  }

  Future<void> _resume() async {
    _startTimer();
    await _audioRecorder.resume();

    setState(() => _isPaused = false);
  }

  void _startTimer() {
    _inicio =  DateTime.now(); 

    _timer?.cancel();
    _ampTimer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      setState(() => _recordDuration++);
    });

    _ampTimer =
        Timer.periodic(const Duration(milliseconds: 200), (Timer t) async {
      _amplitude = await _audioRecorder.getAmplitude();
      setState(() {});
    });
  }
}



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
    return Center(
      child: showPlayer
          ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 25),
                child: AudioPlayer(
                  source: audioPath,
                  duration: durationTotal
,
                  onDelete: () {
                    setState(() => showPlayer = false);
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 25),
                child: ElevatedButton(
                  onPressed: () {
                    final path = audioPath;
                    var uri = Uri.dataFromString(audioPath);
                    final fileName = uri.pathSegments[3];                    
                    storage
                        .uploadAudio(path, fileName)
                        .then((value) => print('Done'));
                    setState(() {
                    });
                  },
                  child: const Text("Guardar audio")
                ),
              ),
              const SizedBox(
                height: 26.0,
              ),
              FutureBuilder(
                future: storage.listFiles(),
                builder: (
                  BuildContext context,
                  AsyncSnapshot<firebase_storage.ListResult> snapshot) {
                    if(snapshot.connectionState == ConnectionState.done && snapshot.hasData)
                    {
                      return Container(
                        height: 200,
                        width: 400,
                        child: ListView.builder(
                          itemCount: snapshot.data!.items.length,
                          itemBuilder: (BuildContext context, int index) {
                            return Padding(
                              padding: EdgeInsets.all(10),
                              child: ElevatedButton(
                              onPressed: () async {
                                final url = await storage.downloadUrl(snapshot.data!.items[index].name);
                                setState(() {
                                  audioPath = url;
                                });
                              }, 
                              child: Text(snapshot.data!.items[index].name),)
                              );
                          },
                          )
                      );
                    }
                    if (snapshot.connectionState == ConnectionState.waiting || !snapshot.hasData)
                    {
                      return const CircularProgressIndicator();
                    }
                    return Container();
                  }
              )

            ],
          )
          : AudioRecorder(
              onStop: (path,duration) {
                if (kDebugMode) print('Recorded file path: $path');
                setState(() {
                  audioPath = path;
                  showPlayer = true;
                  durationTotal = duration;

                  print("audio path: $audioPath");

                  // final data = File(audioPath).readAsBytesSync();

                  // print("data length: ${data.length}");
                });
              },
            ),
    );
  }
}