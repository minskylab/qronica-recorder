part of 'audioplayer_cubit.dart';

enum StatusAudioPlayer { ready , loading , failed }


class AudioplayerState extends Equatable {
  const AudioplayerState({
    this.status = StatusAudioPlayer.ready,
    this.source,
    this.duration,
    this.newAudio = false,
  });

  final StatusAudioPlayer status;
  final String? source;
  final int? duration;
  final bool? newAudio;

  @override
  List<Object?> get props => [
    status,
    source,
    duration
  ];


  AudioplayerState copyWith({
    StatusAudioPlayer? status,
    String? source,    
    int? duration,
    bool? newAudio,    
  }){
    return AudioplayerState(
      status: status ?? this.status,
      source: source ?? this.source,
      duration: duration ?? this.duration,
      newAudio: newAudio ?? this.newAudio,
    );
  }
}

