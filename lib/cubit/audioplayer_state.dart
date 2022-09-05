part of 'audioplayer_cubit.dart';

class AudioplayerState extends Equatable {
  const AudioplayerState({
    this.source,
    this.duration,
  });

  final String? source;
  final int? duration;

  @override
  List<Object?> get props => [
    source,
    duration
  ];

  AudioplayerState copyWith({
    String? source,    
    int? duration,    
  }){
    return AudioplayerState(
      source: source ?? this.source,
      duration: duration ?? this.duration,
    );
  }
}

