import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data' show Uint8List;

import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

const int tSAMPLERATE = 8000;

/// Sample rate used for Streams
const int tSTREAMSAMPLERATE = 44000; // 44100 does not work for recorder on iOS

const int tBLOCKSIZE = 4096;

enum Media {file, buffer, asset, stream,remoteExampleFile,}

enum AudioState { isPlaying, isPaused, isStopped, isRecording,isRecordingPaused,}


///
class AudioRecorder extends StatefulWidget {
  @override
  _AudioRecorderState createState() => _AudioRecorderState();
}

class _AudioRecorderState extends State<AudioRecorder> {
  bool _isRecording = false;
  final List<String?> _path = [
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
  ];


  StreamSubscription? _recorderSubscription;
  StreamSubscription? _playerSubscription;
  StreamSubscription? _recordingDataSubscription;

  FlutterSoundPlayer playerModule = FlutterSoundPlayer();
  FlutterSoundRecorder recorderModule = FlutterSoundRecorder();

  String _recorderTxt = '00:00:00';
  String _playerTxt = '00:00:00';
  double? _dbLevel;

  double sliderCurrentPosition = 0.0;
  double maxDuration = 1.0;
  Media? _media = Media.file;
  Codec _codec = Codec.aacMP4;

  bool? _encoderSupported = true; // Optimist
  bool _decoderSupported = true; // Optimist

  StreamController<Food>? recordingDataController;
  IOSink? sink;

  Future<void> _initializeExample() async {
    await playerModule.closePlayer();
    await playerModule.openPlayer();
    await playerModule.setSubscriptionDuration(Duration(milliseconds: 10));
    await recorderModule.setSubscriptionDuration(Duration(milliseconds: 10));
    await initializeDateFormatting();
    await setCodec(_codec);
  }

  Future<void> openTheRecorder() async {
    if (!kIsWeb) {
      var status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        throw RecordingPermissionException('Microphone permission not granted');
      }
    }
    await recorderModule.openRecorder();

    if (!await recorderModule.isEncoderSupported(_codec) && kIsWeb) {
      _codec = Codec.opusWebM;
    }
  }

  Future<void> init() async {
    await openTheRecorder();
    await _initializeExample();

    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
      avAudioSessionCategoryOptions:
          AVAudioSessionCategoryOptions.allowBluetooth |
              AVAudioSessionCategoryOptions.defaultToSpeaker,
      avAudioSessionMode: AVAudioSessionMode.spokenAudio,
      avAudioSessionRouteSharingPolicy:
          AVAudioSessionRouteSharingPolicy.defaultPolicy,
      avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
      androidAudioAttributes: const AndroidAudioAttributes(
        contentType: AndroidAudioContentType.speech,
        flags: AndroidAudioFlags.none,
        usage: AndroidAudioUsage.voiceCommunication,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      androidWillPauseWhenDucked: true,
    ));
  }


  @override
  void initState() {
    super.initState();
    init();
  }

  void cancelRecorderSubscriptions() {
    if (_recorderSubscription != null) {
      _recorderSubscription!.cancel();
      _recorderSubscription = null;
    }
  }

  void cancelPlayerSubscriptions() {
    if (_playerSubscription != null) {
      _playerSubscription!.cancel();
      _playerSubscription = null;
    }
  }

  void cancelRecordingDataSubscription() {
    if (_recordingDataSubscription != null) {
      _recordingDataSubscription!.cancel();
      _recordingDataSubscription = null;
    }
    recordingDataController = null;
    if (sink != null) {
      sink!.close();
      sink = null;
    }
  }

  @override
  void dispose() {
    super.dispose();
    cancelPlayerSubscriptions();
    cancelRecorderSubscriptions();
    cancelRecordingDataSubscription();
    releaseFlauto();
  }

  Future<void> releaseFlauto() async {
    try {
      await playerModule.closePlayer();
      await recorderModule.closeRecorder();
    } on Exception {
      playerModule.logger.e('Released unsuccessful');
    }
  }

  void startRecorder() async {
    try {
      // Request Microphone permission if needed
      if (!kIsWeb) {
        var status = await Permission.microphone.request();
        if (status != PermissionStatus.granted) {
          throw RecordingPermissionException(
              'Microphone permission not granted');
        }
      }
      var path = '';
      if (!kIsWeb) {
        var tempDir = await getTemporaryDirectory();
        path = '${tempDir.path}/flutter_sound${ext[_codec.index]}';
      } else {
        path = '_flutter_sound${ext[_codec.index]}';
      }

      if (_media == Media.stream) {
        assert(_codec == Codec.pcm16);
        if (!kIsWeb) {
          var outputFile = File(path);
          if (outputFile.existsSync()) {
            await outputFile.delete();
          }
          sink = outputFile.openWrite();
        } else {
          sink = null; // TODO
        }
        recordingDataController = StreamController<Food>();
        _recordingDataSubscription =
            recordingDataController!.stream.listen((buffer) {
          if (buffer is FoodData) {
            sink!.add(buffer.data!);
          }
        });
        await recorderModule.startRecorder(
          toStream: recordingDataController!.sink,

          codec: _codec,
          numChannels: 1,
          sampleRate: tSTREAMSAMPLERATE, //tSAMPLERATE,
        );
      } else {
        await recorderModule.startRecorder(
          toFile: path,
          codec: _codec,
          bitRate: 8000,
          numChannels: 1,
          sampleRate: (_codec == Codec.pcm16) ? tSTREAMSAMPLERATE : tSAMPLERATE,
        );
      }
      recorderModule.logger.d('startRecorder');

      _recorderSubscription = recorderModule.onProgress!.listen((e) {
        var date = DateTime.fromMillisecondsSinceEpoch(
            e.duration.inMilliseconds,
            isUtc: true);
        var txt = DateFormat('mm:ss:SS', 'en_GB').format(date);

        setState(() {
          _recorderTxt = txt.substring(0, 8);
          _dbLevel = e.decibels;
        });
      });

      setState(() {
        _isRecording = true;
        _path[_codec.index] = path;
      });
    } on Exception catch (err) {
      recorderModule.logger.e('startRecorder error: $err');
      setState(() {
        stopRecorder();
        _isRecording = false;
        cancelRecordingDataSubscription();
        cancelRecorderSubscriptions();
      });
    }
  }

  void stopRecorder() async {
    try {
      await recorderModule.stopRecorder();
      recorderModule.logger.d('stopRecorder');
      cancelRecorderSubscriptions();
      cancelRecordingDataSubscription();
    } on Exception catch (err) {
      recorderModule.logger.d('stopRecorder error: $err');
    }
    setState(() {
      _isRecording = false;
    });
  }

  Future<bool> fileExists(String path) async {
    return await File(path).exists();
  }


  void _addListeners() {
    cancelPlayerSubscriptions();
    _playerSubscription = playerModule.onProgress!.listen((e) {
      maxDuration = e.duration.inMilliseconds.toDouble();
      if (maxDuration <= 0) maxDuration = 0.0;

      sliderCurrentPosition =
          min(e.position.inMilliseconds.toDouble(), maxDuration);
      if (sliderCurrentPosition < 0.0) {
        sliderCurrentPosition = 0.0;
      }

      var date = DateTime.fromMillisecondsSinceEpoch(e.position.inMilliseconds,
          isUtc: true);
      var txt = DateFormat('mm:ss:SS', 'en_GB').format(date);
      setState(() {
        _playerTxt = txt.substring(0, 8);
      });
    });
  }

  Future<Uint8List> _readFileByte(String filePath) async {
    var myUri = Uri.parse(filePath);
    var audioFile = File.fromUri(myUri);
    Uint8List bytes;
    var b = await audioFile.readAsBytes();
    bytes = Uint8List.fromList(b);
    playerModule.logger.d('reading of bytes is completed');
    return bytes;
  }

  Future<Uint8List> getAssetData(String path) async {
    var asset = await rootBundle.load(path);
    return asset.buffer.asUint8List();
  }

  /*
  Future<void> feedHim(String path) async {
    var data = await _readFileByte(path);
    return await playerModule.feedFromStream(data);
  }
*/

  final int blockSize = 4096;
  Future<void> feedHim(String path) async {
    var buffer = await _readFileByte(path);
    //var buffer = await getAssetData('assets/samples/sample.pcm');

    var lnData = 0;
    var totalLength = buffer.length;
    while (totalLength > 0 && !playerModule.isStopped) {
      var bsize = totalLength > blockSize ? blockSize : totalLength;
      await playerModule
          .feedFromStream(buffer.sublist(lnData, lnData + bsize)); // await !!!!
      lnData += bsize;
      totalLength -= bsize;
    }
  }

  Future<void> startPlayer() async {
    try {
      Uint8List? dataBuffer;
      String? audioFilePath;
      var codec = _codec;
       if (_media == Media.file || _media == Media.stream) {
        // Do we want to play from buffer or from file ?
        if (kIsWeb || await fileExists(_path[codec.index]!)) {
          audioFilePath = _path[codec.index];
        }
      }

      if (_media == Media.stream) {
        await playerModule.startPlayerFromStream(
          codec: Codec.pcm16, //_codec,
          numChannels: 1,
          sampleRate: tSTREAMSAMPLERATE, //tSAMPLERATE,
        );
        _addListeners();
        setState(() {});
        await feedHim(audioFilePath!);
        //await finishPlayer();
        await stopPlayer();
        return;
      } else {
        if (audioFilePath != null) {
          await playerModule.startPlayer(
              fromURI: audioFilePath,
              codec: codec,
              sampleRate: tSTREAMSAMPLERATE,
              whenFinished: () {
                playerModule.logger.d('Play finished');
                setState(() {});
              });
        } else if (dataBuffer != null) {
          if (codec == Codec.pcm16) {
            dataBuffer = await flutterSoundHelper.pcmToWaveBuffer(
              inputBuffer: dataBuffer,
              numChannels: 1,
              sampleRate: (_codec == Codec.pcm16 && _media == Media.asset)
                  ? 48000
                  : tSAMPLERATE,
            );
            codec = Codec.pcm16WAV;
          }
          await playerModule.startPlayer(
              fromDataBuffer: dataBuffer,
              sampleRate: tSAMPLERATE,
              codec: codec,
              whenFinished: () {
                playerModule.logger.d('Play finished');
                setState(() {});
              });
        }
      }
      _addListeners();
      setState(() {});
      playerModule.logger.d('<--- startPlayer');
    } on Exception catch (err) {
      playerModule.logger.e('error: $err');
    }
  }

  Future<void> stopPlayer() async {
    try {
      await playerModule.stopPlayer();
      playerModule.logger.d('stopPlayer');
      if (_playerSubscription != null) {
        await _playerSubscription!.cancel();
        _playerSubscription = null;
      }
      sliderCurrentPosition = 0.0;
    } on Exception catch (err) {
      playerModule.logger.d('error: $err');
    }
    setState(() {});
  }

  void pauseResumePlayer() async {
    try {
      if (playerModule.isPlaying) {
        await playerModule.pausePlayer();
      } else {
        await playerModule.resumePlayer();
      }
    } on Exception catch (err) {
      playerModule.logger.e('error: $err');
    }
    setState(() {});
  }

  void pauseResumeRecorder() async {
    try {
      if (recorderModule.isPaused) {
        await recorderModule.resumeRecorder();
      } else {
        await recorderModule.pauseRecorder();
        assert(recorderModule.isPaused);
      }
    } on Exception catch (err) {
      recorderModule.logger.e('error: $err');
    }
    setState(() {});
  }

  Future<void> seekToPlayer(int milliSecs) async {
    //playerModule.logger.d('-->seekToPlayer');
    try {
      if (playerModule.isPlaying) {
        await playerModule.seekToPlayer(Duration(milliseconds: milliSecs));
      }
    } on Exception catch (err) {
      playerModule.logger.e('error: $err');
    }
    setState(() {});
    //playerModule.logger.d('<--seekToPlayer');
  }

  void Function()? onPauseResumePlayerPressed() {
    if (playerModule.isPaused || playerModule.isPlaying) {
      return pauseResumePlayer;
    }
    return null;
  }

  void Function()? onPauseResumeRecorderPressed() {
    if (recorderModule.isPaused || recorderModule.isRecording) {
      return pauseResumeRecorder;
    }
    return null;
  }

  void Function()? onStopPlayerPressed() {
    return (playerModule.isPlaying || playerModule.isPaused)
        ? stopPlayer
        : null;
  }

  void Function()? onStartPlayerPressed() {
    if (_media == Media.buffer && kIsWeb) {
      return null;
    }
    if (_media == Media.file ||
        _media == Media.stream ||
        _media == Media.buffer) // A file must be already recorded to play it
    {
      if (_path[_codec.index] == null) return null;
    }

    if (_media == Media.stream && _codec != Codec.pcm16) {
      return null;
    }

    // Disable the button if the selected codec is not supported
    if (!(_decoderSupported || _codec == Codec.pcm16)) {
      return null;
    }

    return (playerModule.isStopped) ? startPlayer : null;
  }

  void startStopRecorder() {
    if (recorderModule.isRecording || recorderModule.isPaused) {
      stopRecorder();
    } else {
      startRecorder();
    }
  }

  void Function()? onStartRecorderPressed() {
    // Disable the button if the selected codec is not supported
    if (!_encoderSupported!) return null;
    if (_media == Media.stream && _codec != Codec.pcm16) return null;
    return startStopRecorder;
  }

  Future<void> setCodec(Codec codec) async {
    _encoderSupported = await recorderModule.isEncoderSupported(codec);
    _decoderSupported = await playerModule.isDecoderSupported(codec);

    setState(() {
      _codec = codec;
    });
  }


    Widget _buildRecordStopControl() {
    late Icon icon;
    late Color color;

    if (recorderModule.isRecording || recorderModule.isPaused) {
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
        child:  TextButton(
          onPressed: onStartRecorderPressed(),
          //padding: EdgeInsets.all(8.0),
          child: InkWell(
          child: SizedBox(width: 60, height: 60, child: icon),
        ),
        ),
      ),
    );
  }

    Widget _buildPauseResumeControl() {
    if (!recorderModule.isRecording && !recorderModule.isPaused) {
      return const SizedBox.shrink();
    }

    late Icon icon;
    late Color color;

    if (!recorderModule.isPaused) {
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
        child: TextButton(
          onPressed: onPauseResumePlayerPressed(),
          //padding: EdgeInsets.all(8.0),
          child: InkWell(
          child: SizedBox(width: 60, height: 60, child: icon),
        ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {

    Widget recorderSection = Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            margin: EdgeInsets.only(top: 12.0, bottom: 16.0),
            child: Text(
              _recorderTxt,
              style: TextStyle(
                fontSize: 35.0,
                color: Colors.black,
              ),
            ),
          ),
          _isRecording
              ? LinearProgressIndicator(
                  value: 100.0 / 160.0 * (_dbLevel ?? 1) / 100,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  backgroundColor: Colors.red)
              : Container(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              _buildRecordStopControl(),
              _buildPauseResumeControl(),
            ],
          ),
        ]);

    Widget playerSection = Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(
          margin: EdgeInsets.only(top: 12.0, bottom: 16.0),
          child: Text(
            _playerTxt,
            style: TextStyle(
              fontSize: 35.0,
              color: Colors.black,
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 56.0,
              height: 50.0,
              child: IconButton(
                    icon: const Icon(Icons.play_arrow),
                    iconSize: 32.0,
                    onPressed: onStartPlayerPressed(),
                  ),
            ),
            Container(
              width: 56.0,
              height: 50.0,
              child:IconButton(
                    icon: const Icon(Icons.pause),
                    iconSize: 32.0,
                    onPressed: onPauseResumePlayerPressed(),
                  ),
            ),
            Container(
              width: 56.0,
              height: 50.0,
                  child:  IconButton(
                    icon: const Icon(Icons.stop),
                    iconSize: 32.0,
                    onPressed: onStopPlayerPressed(),

                  )
            ),
          ],
        ),
        Container(
            height: 30.0,
            child: Slider(
                value: min(sliderCurrentPosition, maxDuration),
                min: 0.0,
                max: maxDuration,
                onChanged: (value) async {
                  await seekToPlayer(value.toInt());
                },
                divisions: maxDuration == 0.0 ? 1 : maxDuration.toInt())),
      ],
    );

    return ListView(
        children: <Widget>[
          recorderSection,
          playerSection,
        ],
      );
  }
}
