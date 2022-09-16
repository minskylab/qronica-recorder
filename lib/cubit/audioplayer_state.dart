part of 'audioplayer_cubit.dart';

enum StatusAudioPlayer { ready , loading , failed, changed}
enum StatusAudioUpload { yet, done, inProgress }


class AudioplayerState extends Equatable {
  const AudioplayerState({
    this.status = StatusAudioPlayer.ready,
    this.source,
    this.sourceName = "Audio Grabado",
    this.duration,
    this.newAudio = false,
    this.uploaded = StatusAudioUpload.yet,
  });

  final StatusAudioPlayer status;
  final String? source;
  final String? sourceName;
  final int? duration;
  final bool? newAudio;
  final StatusAudioUpload uploaded;

  @override
  List<Object?> get props => [
    status,
    source,
    sourceName,
    duration,
    uploaded
  ];


  AudioplayerState copyWith({
    StatusAudioPlayer? status,
    String? source,    
    String? sourceName,
    int? duration,
    bool? newAudio,    
    StatusAudioUpload? uploaded,
  }){
    return AudioplayerState(
      status: status ?? this.status,
      source: source ?? this.source,
      sourceName: sourceName ?? this.sourceName,
      duration: duration ?? this.duration,
      newAudio: newAudio ?? this.newAudio,
      uploaded: uploaded ?? this.uploaded,
    );
  }
}

